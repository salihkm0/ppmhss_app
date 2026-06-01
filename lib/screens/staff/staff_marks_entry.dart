import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';

class StaffMarksEntryPage extends StatefulWidget {
  final String classId;
  final String className;
  /// Optional: pre-selected exam (when navigating from StaffExamsPage)
  final String? examId;
  final String? examName;

  const StaffMarksEntryPage({
    super.key,
    required this.classId,
    required this.className,
    this.examId,
    this.examName,
  });

  @override
  State<StaffMarksEntryPage> createState() => _StaffMarksEntryPageState();
}

class _StaffMarksEntryPageState extends State<StaffMarksEntryPage> {
  List<StudentModel> _students = [];
  List<ExamModel> _exams = [];
  String? _selectedExamId;
  String _searchTerm = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // { studentId: { subjectId: { 'theoryScore': int, 'practicalScore': int, 'maxMarks': int } } }
  Map<String, Map<String, Map<String, dynamic>>> _marksData = {};

  // Subjects list from the selected exam's response
  // Each entry: { subjectId, subjectName, maxTheory, maxPractical }
  List<Map<String, dynamic>> _subjects = [];

  // Expanded state per student
  Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Pre-select exam if provided
    if (widget.examId != null && widget.examId!.isNotEmpty) {
      _selectedExamId = widget.examId;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final store = StoreProvider.of<AppState>(context, listen: false);
    try {
      await store.dispatch(
          fetchStudentsByClassThunk(FetchStudentsByClassAction(classId: widget.classId)));
      await store.dispatch(fetchTeacherExamsThunk());

      setState(() {
        _students = store.state.students.students;
        _exams = store.state.exams.exams;
      });

      // If exam was pre-selected, immediately load marks
      if (_selectedExamId != null) {
        await _loadMarks(_selectedExamId!);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMarks(String examId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final store = StoreProvider.of<AppState>(context, listen: false);

    try {
      await store.dispatch(
          fetchMarksForClassThunk(examId: examId, classId: widget.classId));

      final rawData = store.state.exams.classMarks;
      if (rawData != null) {
        _parseMarksResponse(rawData);
      }
    } catch (e) {
      // Non-fatal: marks may not exist yet — start with empty data
      setState(() {
        _subjects = _extractSubjectsFromExam(examId);
        _marksData = {};
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Extract subject info from the exam model if marks API returns nothing
  List<Map<String, dynamic>> _extractSubjectsFromExam(String examId) {
    final exam = _exams.firstWhere((e) => e.id == examId,
        orElse: () => ExamModel(
            id: '',
            name: '',
            examType: '',
            startDate: DateTime.now(),
            endDate: DateTime.now()));
    if (exam.subjects == null) return [];
    return exam.subjects!.map((s) {
      final sid = s['subjectId']?['_id'] ?? s['subjectId'] ?? s['_id'] ?? '';
      final name = s['subjectId']?['name'] ?? s['name'] ?? 'Subject';
      final maxT = (s['maxTheoryMarks'] as num?)?.toInt() ?? 100;
      final maxP = (s['maxPracticalMarks'] as num?)?.toInt() ?? 0;
      return {
        'subjectId': sid.toString(),
        'subjectName': name.toString(),
        'maxTheory': maxT,
        'maxPractical': maxP,
      };
    }).toList();
  }

  void _parseMarksResponse(Map<String, dynamic> raw) {
    // Subjects array from marks response
    final subjectsRaw = raw['subjects'] as List? ??
                        raw['data']?['subjects'] as List? ?? [];
    final subjects = subjectsRaw.map((s) {
      final sid = s['subjectId']?['_id'] ?? s['subjectId'] ?? s['_id'] ?? '';
      final name = s['subjectId']?['name'] ?? s['name'] ?? 'Subject';
      final maxT = (s['maxTheoryMarks'] as num?)?.toInt() ?? 100;
      final maxP = (s['maxPracticalMarks'] as num?)?.toInt() ?? 0;
      return {
        'subjectId': sid.toString(),
        'subjectName': name.toString(),
        'maxTheory': maxT,
        'maxPractical': maxP,
      };
    }).toList();

    // Marks array
    final marksRaw = raw['marks'] as List? ??
                     raw['data']?['marks'] as List? ?? [];
    final Map<String, Map<String, Map<String, dynamic>>> parsed = {};
    for (final m in marksRaw) {
      final sid = m['studentId']?['_id'] ?? m['studentId']?.toString() ?? '';
      final subId = m['subjectId']?['_id'] ?? m['subjectId']?.toString() ?? '';
      if (sid.isEmpty || subId.isEmpty) continue;
      parsed[sid] ??= {};
      parsed[sid]![subId] = {
        'theoryScore': (m['theoryScore'] as num?)?.toInt() ?? 0,
        'practicalScore': (m['practicalScore'] as num?)?.toInt() ?? 0,
        'totalScore': (m['totalScore'] as num?)?.toInt() ?? 0,
      };
    }

    setState(() {
      _subjects = subjects.cast<Map<String, dynamic>>();
      _marksData = parsed;
    });
  }

  void _updateMark(String studentId, String subjectId, String field, int value) {
    setState(() {
      _marksData[studentId] ??= {};
      _marksData[studentId]![subjectId] ??= {
        'theoryScore': 0,
        'practicalScore': 0,
        'totalScore': 0,
      };
      _marksData[studentId]![subjectId]![field] = value;
      final theory = _marksData[studentId]![subjectId]!['theoryScore'] as int? ?? 0;
      final practical = _marksData[studentId]![subjectId]!['practicalScore'] as int? ?? 0;
      _marksData[studentId]![subjectId]!['totalScore'] = theory + practical;
    });
  }

  double _studentPercentage(String studentId) {
    if (_subjects.isEmpty) return 0;
    int totalObtained = 0;
    int totalMax = 0;
    for (final sub in _subjects) {
      final sid = sub['subjectId'] as String;
      final maxT = sub['maxTheory'] as int;
      final maxP = sub['maxPractical'] as int;
      totalMax += maxT + maxP;
      totalObtained +=
          (_marksData[studentId]?[sid]?['theoryScore'] as int? ?? 0) +
              (_marksData[studentId]?[sid]?['practicalScore'] as int? ?? 0);
    }
    return totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
  }

  Future<void> _saveAllMarks() async {
    if (_selectedExamId == null) return;
    setState(() => _isSaving = true);

    final marksPayload = <Map<String, dynamic>>[];
    for (final student in _students) {
      for (final sub in _subjects) {
        final subId = sub['subjectId'] as String;
        final marks = _marksData[student.id]?[subId];
        marksPayload.add({
          'studentId': student.id,
          'subjectId': subId,
          'theoryScore': marks?['theoryScore'] ?? 0,
          'practicalScore': marks?['practicalScore'] ?? 0,
        });
      }
    }

    final store = StoreProvider.of<AppState>(context, listen: false);
    try {
      await store.dispatch(saveStudentMarksThunk(
        examId: _selectedExamId!,
        classId: widget.classId,
        marksData: marksPayload,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marks saved successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save marks: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  List<StudentModel> get _filteredStudents {
    if (_searchTerm.isEmpty) return _students;
    return _students
        .where((s) =>
            s.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
            (s.rollNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ??
                false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Marks Entry – ${widget.className}'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedExamId != null && _subjects.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveAllMarks,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text('Save All',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading && _students.isEmpty
          ? const Center(child: LoadingWidget())
          : _error != null && _students.isEmpty
              ? Center(
                  child: CustomErrorWidget(
                      message: _error!, onRetry: _loadData))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Exam Selector
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Exam',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedExamId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: 'Choose an exam',
                ),
                items: _exams.map((exam) {
                  return DropdownMenuItem(
                      value: exam.id,
                      child: Text(exam.displayName ?? exam.name));
                }).toList(),
                onChanged: (value) {
                  if (value == null || value == _selectedExamId) return;
                  setState(() {
                    _selectedExamId = value;
                    _marksData = {};
                    _subjects = [];
                  });
                  _loadMarks(value);
                },
              ),
            ],
          ),
        ),

        // Search bar
        if (_students.isNotEmpty && _selectedExamId != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number...',
                prefixIcon: Icon(Icons.search, size: 18),
                border: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchTerm = v),
            ),
          ),

        // No exam selected
        if (_selectedExamId == null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Select an exam above to start entering marks',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ),

        // Loading marks
        if (_isLoading && _selectedExamId != null && _subjects.isEmpty)
          const Expanded(child: Center(child: LoadingWidget())),

        // Students list
        if (!_isLoading && _selectedExamId != null)
          Expanded(
            child: _subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No subjects configured for this exam',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final isExpanded = _expanded[student.id] ?? false;
                      final pct = _studentPercentage(student.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            // Header
                            ListTile(
                              onTap: () => setState(
                                  () => _expanded[student.id] = !isExpanded),
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  student.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(student.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                  'Roll: ${student.rollNumber?.isEmpty ?? true ? '-' : student.rollNumber!}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${pct.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _pctColor(pct),
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text('Total',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                      isExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 20),
                                ],
                              ),
                            ),

                            // Expanded marks entry
                            if (isExpanded)
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12)),
                                ),
                                child: Column(
                                  children:
                                      _subjects.map((sub) {
                                    final subId =
                                        sub['subjectId'] as String;
                                    final subName =
                                        sub['subjectName'] as String;
                                    final maxT =
                                        sub['maxTheory'] as int;
                                    final maxP =
                                        sub['maxPractical'] as int;
                                    final currentT = _marksData[student
                                            .id]?[subId]?['theoryScore'] as int? ??
                                        0;
                                    final currentP = _marksData[student
                                            .id]?[subId]?['practicalScore'] as int? ??
                                        0;

                                    return Container(
                                      margin:
                                          const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(subName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 13)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              // Theory
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                        'Theory (/$maxT)',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600])),
                                                    const SizedBox(
                                                        height: 4),
                                                    TextFormField(
                                                      key: ValueKey(
                                                          'theory_${student.id}_$subId'),
                                                      initialValue:
                                                          currentT
                                                              .toString(),
                                                      keyboardType:
                                                          TextInputType
                                                              .number,
                                                      decoration:
                                                          const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                                horizontal:
                                                                    8,
                                                                vertical:
                                                                    8),
                                                        isDense: true,
                                                      ),
                                                      onChanged: (v) {
                                                        final val = int
                                                                .tryParse(
                                                                    v) ??
                                                            0;
                                                        _updateMark(
                                                            student.id,
                                                            subId,
                                                            'theoryScore',
                                                            val.clamp(
                                                                0,
                                                                maxT));
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (maxP > 0) ...[
                                                const SizedBox(width: 8),
                                                // Practical
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          'Practical (/$maxP)',
                                                          style: TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .grey[600])),
                                                      const SizedBox(
                                                          height: 4),
                                                      TextFormField(
                                                        key: ValueKey(
                                                            'practical_${student.id}_$subId'),
                                                        initialValue:
                                                            currentP
                                                                .toString(),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8,
                                                                  vertical:
                                                                      8),
                                                          isDense: true,
                                                        ),
                                                        onChanged: (v) {
                                                          final val =
                                                              int.tryParse(
                                                                      v) ??
                                                                  0;
                                                          _updateMark(
                                                              student.id,
                                                              subId,
                                                              'practicalScore',
                                                              val.clamp(
                                                                  0,
                                                                  maxP));
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              // Total
                                              Column(
                                                children: [
                                                  Text('Total',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey[600])),
                                                  const SizedBox(
                                                      height: 4),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 10),
                                                    decoration:
                                                        BoxDecoration(
                                                      color:
                                                          Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                    ),
                                                    child: Text(
                                                      '${(_marksData[student.id]?[subId]?['totalScore'] as int?) ?? (currentT + currentP)}/${maxT + maxP}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Color _pctColor(double pct) {
    if (pct >= 75) return Colors.green;
    if (pct >= 50) return Colors.orange;
    return Colors.red;
  }
}