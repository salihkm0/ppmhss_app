// lib/screens/staff/class_marks_overview.dart
// Class teacher / admin view: see all student marks per exam for a class
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/services/api_service.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF059669);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const text1 = Color(0xFF0F172A);
  static const text2 = Color(0xFF64748B);
  static const text3 = Color(0xFF94A3B8);
  static const divider = Color(0xFFF1F5F9);

  static List<BoxShadow> shadow([double b = 8, double o = 0.06]) => [
        BoxShadow(
            color: Colors.black.withOpacity(o),
            blurRadius: b,
            offset: const Offset(0, 3)),
      ];
}

// ─── Grade helper ─────────────────────────────────────────────────────────────
Map<String, dynamic> _gradeInfo(int obtained, int max) {
  if (max <= 0)
    return {'grade': '-', 'bg': Colors.grey.shade100, 'fg': Colors.grey};
  final pct = (obtained / max) * 100;
  if (pct >= 90)
    return {
      'grade': 'A+',
      'bg': const Color(0xFFD1FAE5),
      'fg': const Color(0xFF065F46)
    };
  if (pct >= 80)
    return {
      'grade': 'A',
      'bg': const Color(0xFFDCFCE7),
      'fg': const Color(0xFF166534)
    };
  if (pct >= 70)
    return {
      'grade': 'B+',
      'bg': const Color(0xFFDBEAFE),
      'fg': const Color(0xFF1E40AF)
    };
  if (pct >= 60)
    return {
      'grade': 'B',
      'bg': const Color(0xFFCFFAFE),
      'fg': const Color(0xFF155E75)
    };
  if (pct >= 50)
    return {
      'grade': 'C+',
      'bg': const Color(0xFFFEF3C7),
      'fg': const Color(0xFF92400E)
    };
  if (pct >= 40)
    return {
      'grade': 'C',
      'bg': const Color(0xFFFFEDD5),
      'fg': const Color(0xFF9A3412)
    };
  if (pct >= 30)
    return {
      'grade': 'D+',
      'bg': const Color(0xFFFEF3C7),
      'fg': const Color(0xFFB45309)
    };
  if (pct >= 20)
    return {
      'grade': 'D',
      'bg': const Color(0xFFFEE2E2),
      'fg': const Color(0xFFB91C1C)
    };
  return {'grade': 'E', 'bg': Colors.grey.shade100, 'fg': Colors.grey.shade700};
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ClassMarksOverviewPage extends StatefulWidget {
  final String? classId;
  final String? className;
  final String? examId;

  const ClassMarksOverviewPage({super.key, this.classId, this.className, this.examId});

  @override
  State<ClassMarksOverviewPage> createState() => _ClassMarksOverviewPageState();
}

class _ClassMarksOverviewPageState extends State<ClassMarksOverviewPage> {
  final _api = ApiService();
  final _examService = ExamService();

  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _classes = [];
  String? _selectedExamId;
  String? _selectedClassId;
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _examsLoading = true;
  bool _isCardView = false;
  String _search = '';
  final _searchCtrl = TextEditingController();

  bool get _isAdmin {
    // Check role from store
    return false; // Will be set properly in build via ViewModel
  }

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    _selectedExamId = widget.examId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExams());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final isStaff = store.state.auth.user?.role == 'staff';
    final currentYearId = store.state.academicYears.currentAcademicYear?.id;

    setState(() => _examsLoading = true);
    try {
      String? ayId = currentYearId;
      if (ayId == null && isStaff) {
        final ayResp = await _api.get('/academic-years', params: {'limit': 10});
        final ays = (ayResp.data?['data'] ?? ayResp.data?['academicYears'] ?? []) as List;
        final current = ays.firstWhere((y) => y['isCurrent'] == true, orElse: () => null);
        if (current != null) ayId = current['_id'];
      }

      final resp = await _examService.getExams(limit: 100, isStaff: isStaff, academicYearId: ayId);
      List dynamicList = [];
      if (resp['data'] is List) {
        dynamicList = resp['data'] as List;
      } else if (resp['data'] is Map && resp['data']['exams'] is List) {
        dynamicList = resp['data']['exams'] as List;
      } else if (resp['exams'] is List) {
        dynamicList = resp['exams'] as List;
      }
      setState(() {
        _exams = dynamicList.cast<Map<String, dynamic>>();
        if (_selectedExamId != null) {
          final exam = _exams.firstWhere((e) => e['_id'] == _selectedExamId, orElse: () => <String, dynamic>{});
          if (exam.isEmpty) {
            _selectedExamId = null;
            _selectedClassId = null;
          } else if (_selectedClassId != null && exam['classIds'] != null) {
            var classes = (exam['classIds'] as List).cast<Map<String, dynamic>>();
            if (!isStaff) {
               // admin, keep all
            } else {
               final store = StoreProvider.of<AppState>(context, listen: false);
               final teacherClasses = store.state.classes.teacherClasses;
               classes = classes.where((ec) => teacherClasses.any((c) => c.id == ec['_id'])).toList();
            }
            final foundCls = classes.any((c) => c['_id'] == _selectedClassId);
            if (!foundCls) _selectedClassId = null;
          }
        }
      });
      if (_selectedExamId != null && _selectedClassId != null) {
        _loadMarks();
      }
    } catch (_) {}
    setState(() => _examsLoading = false);
  }

  Future<void> _loadMarks() async {
    final examId = _selectedExamId;
    final classId = _selectedClassId;
    if (examId == null || classId == null) return;
    setState(() {
      _loading = true;
      _data = null;
    });
    try {
      final resp =
          await _api.get('/marks/class/$examId/$classId', noCache: true);
      setState(() => _data = resp.data?['data'] ?? resp.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load marks: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _subjects {
    return (_data?['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> get _studentRows {
    final students =
        (_data?['students'] as List? ?? []).cast<Map<String, dynamic>>();
    final rows = students.map((student) {
      int totalObtained = 0;
      int totalMax = 0;
      final subjectMarks = _subjects.map((subj) {
        final key = subj['examSubjectId']?.toString() ?? '';
        final sList =
            (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
        final sm = sList.firstWhere(
          (s) =>
              (s['examSubjectId']?.toString() ??
                  s['subjectId']?.toString() ??
                  '') ==
              key,
          orElse: () => {},
        );
        final theory = (sm['theoryScore'] as num? ?? 0).toInt();
        final practical = (sm['practicalScore'] as num? ?? 0).toInt();
        final ce =
            (sm['ceMarks'] as num? ?? sm['ceScore'] as num? ?? 0).toInt();
        final isAbsent = sm['isAbsent'] == true;
        final total = isAbsent ? 0 : theory + practical + ce;
        final max = (subj['maxMarks'] as num? ?? 100).toInt();
        if (!isAbsent) {
          totalObtained += total;
          totalMax += max;
        }
        return {
          'examSubjectId': key,
          'name': subj['displayName'] ?? subj['subjectName'] ?? '',
          'total': total,
          'max': max,
          'isAbsent': isAbsent,
          'isEntered': sm['isEntered'] ?? false,
        };
      }).toList();

      final pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      return {
        'studentId': student['studentId'],
        'name': student['studentName'] ?? '',
        'admissionNo': student['admissionNo'] ?? student['studentCode'] ?? '-',
        'subjectMarks': subjectMarks,
        'totalObtained': totalObtained,
        'totalMax': totalMax,
        'percentage': pct,
        'gradeInfo': _gradeInfo(totalObtained, totalMax),
      };
    }).toList();

    // Sort by percentage desc → assign rank
    rows.sort((a, b) =>
        (b['percentage'] as double).compareTo(a['percentage'] as double));
    for (int i = 0; i < rows.length; i++) {
      rows[i] = {...rows[i], 'rank': i + 1};
    }
    return rows;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return _studentRows
        .where((s) =>
            (s['name'] as String).toLowerCase().contains(q) ||
            (s['admissionNo'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.auth.user?.role ?? 'staff',
      builder: (context, role) {
        final isAdmin = role == 'admin';

        return Scaffold(
          backgroundColor: _C.bg,
          appBar: AppBar(
            backgroundColor: _C.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class Marks Overview',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (widget.className != null)
                  Text(widget.className!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_isCardView
                    ? Icons.table_chart_outlined
                    : Icons.view_module_outlined),
                tooltip: _isCardView ? 'Switch to Table' : 'Switch to Cards',
                onPressed: () => setState(() => _isCardView = !_isCardView),
              ),
              if (_selectedExamId != null && _selectedClassId != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMarks,
                ),
            ],
          ),
          body: Column(
            children: [
              if (!isAdmin && _exams.isEmpty && !_examsLoading && widget.classId == null)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.class_outlined,
                            size: 60, color: _C.primary),
                        SizedBox(height: 16),
                        Text('No Exams Assigned',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _C.text1)),
                        SizedBox(height: 8),
                        Text(
                            'You do not have any exams assigned\nto your classes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _C.text2)),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildSelectors(isAdmin),
                if (_loading)
                  const Expanded(
                      child: Center(
                          child: CircularProgressIndicator(color: _C.primary))),
                if (!_loading && _data == null)
                  Expanded(
                      child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                          'Select an exam${isAdmin ? " and class" : ""} to view marks',
                          style: TextStyle(color: _C.text3, fontSize: 14)),
                    ]),
                  )),
                if (!_loading && _data != null)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final rows = _studentRows;
                        final spList = (_data?['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();
                        final completedSubjects = spList.isNotEmpty 
                            ? spList.where((sp) => (sp['percentage'] as num? ?? 0) == 100).length
                            : _subjects.where((subj) {
                                final key = subj['examSubjectId']?.toString() ?? '';
                                return rows.every((s) => (s['subjectMarks'] as List)
                                    .any((sm) => sm['examSubjectId'] == key && sm['isEntered'] == true));
                              }).length;

                        if (!isAdmin && completedSubjects < _subjects.length) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, size: 60, color: Colors.orange),
                                const SizedBox(height: 12),
                                const Text('Marks Pending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.text1)),
                                const SizedBox(height: 8),
                                Text('The class marks overview will be available once marks\nfor all subjects have been submitted.\nCurrently, $completedSubjects out of ${_subjects.length} subjects are completed.',
                                    textAlign: TextAlign.center, style: const TextStyle(color: _C.text3, fontSize: 14)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            _buildSummaryRow(),
                            _buildSearchBar(),
                            Expanded(child: _isCardView ? _buildCardView() : _buildTableView()),
                          ],
                        );
                      }
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectors(bool isAdmin) {
    List<Map<String, dynamic>> availableClasses = [];
    if (_selectedExamId != null) {
      final exam = _exams.firstWhere((e) => e['_id'] == _selectedExamId, orElse: () => <String, dynamic>{});
      if (exam.isNotEmpty && exam['classIds'] != null) {
         availableClasses = (exam['classIds'] as List).cast<Map<String, dynamic>>();
         if (!isAdmin) {
           final store = StoreProvider.of<AppState>(context, listen: false);
           final teacherClasses = store.state.classes.teacherClasses;
           availableClasses = availableClasses.where((ec) {
             return teacherClasses.any((c) => c.id == ec['_id']);
           }).toList();
         }
         
         // Deduplicate to avoid DropdownMenuItem assertion errors
         final uniqueIds = <String>{};
         availableClasses = availableClasses.where((ec) {
           return uniqueIds.add(ec['_id'].toString());
         }).toList();
      }
    }

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _examsLoading
              ? const Text('Loading exams…',
                  style: TextStyle(color: _C.text3, fontSize: 13))
              : _buildDropdown(
                  label: 'Select Exam',
                  hint: '— Choose Exam —',
                  value: _selectedExamId,
                  items: _exams
                      .map((e) => DropdownMenuItem(
                            value: e['_id'] as String?,
                            child: Text(e['name'] ?? '',
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedExamId = v;
                      _selectedClassId = null; // Reset class selection
                      _data = null;
                    });
                  },
                ),
          const SizedBox(height: 10),
          if (_selectedExamId != null)
            _buildDropdown(
              label: 'Select Class',
              hint: '— Choose Class —',
              value: _selectedClassId,
              items: availableClasses.map((c) {
                final name = c['displayName'] ??
                    '${c['name']}${c['section'] != null ? "-${c['section']}" : ""}';
                return DropdownMenuItem(
                    value: c['_id'] as String?,
                    child: Text(name, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedClassId = v;
                  _data = null;
                });
                if (_selectedClassId != null && _selectedExamId != null) {
                  _loadMarks();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _C.text2)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
            color: _C.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              hint: Text(hint,
                  style: const TextStyle(color: _C.text3, fontSize: 13)),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                    value: null,
                    child: Text(hint,
                        style: const TextStyle(color: _C.text3, fontSize: 13))),
                ...items
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final rows = _studentRows;
    if (rows.isEmpty) return const SizedBox();
    final avg =
        rows.fold(0.0, (s, r) => s + (r['percentage'] as double)) / rows.length;
    final pass = rows.where((r) => (r['percentage'] as double) >= 40).length;
    final completedSubjects = _subjects.where((subj) {
      final key = subj['examSubjectId']?.toString() ?? '';
      return rows.every((s) => (s['subjectMarks'] as List)
          .any((sm) => sm['examSubjectId'] == key && sm['isEntered'] == true));
    }).length;

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _statChip('Students', rows.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          _statChip('Avg %', '${avg.toStringAsFixed(1)}%', _C.primary),
          const SizedBox(width: 8),
          _statChip('Pass', '$pass/${rows.length}', Colors.green),
          const SizedBox(width: 8),
          _statChip('Subjects Done', '$completedSubjects/${_subjects.length}',
              Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search student…',
          hintStyle: const TextStyle(color: _C.text3, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _C.text3, size: 18),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _search = '');
                  })
              : null,
          filled: true,
          fillColor: _C.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _C.primary)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  // ── TABLE VIEW ──────────────────────────────────────────────────────────────
  Widget _buildTableView() {
    final rows = _filtered;
    final subjects = _subjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 42,
          dataRowMaxHeight: 52,
          columnSpacing: 16,
          columns: [
            const DataColumn(
                label: Text('#',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(
                label: Text('Student',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            ...subjects.map((s) => DataColumn(
                  label: SizedBox(
                    width: 70,
                    child: Text(
                      s['displayName'] ?? s['subjectName'] ?? '',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
            const DataColumn(
                label: Text('Total',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(
                label: Text('%',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(
                label: Text('Grade',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          ],
          rows: rows.map((student) {
            final g = student['gradeInfo'] as Map<String, dynamic>;
            return DataRow(cells: [
              // Rank
              DataCell(Text('${student['rank']}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600))),
              // Student name
              DataCell(SizedBox(
                width: 110,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(student['name'] as String,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _C.text1),
                          overflow: TextOverflow.ellipsis),
                      Text(student['admissionNo'] as String,
                          style: const TextStyle(fontSize: 9, color: _C.text3)),
                    ]),
              )),
              // Subject marks
              ...(student['subjectMarks'] as List).map((sm) => DataCell(
                    sm['isAbsent'] == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6)),
                            child: const Text('AB',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700)))
                        : sm['isEntered'] == false
                            ? const Text('—',
                                style: TextStyle(color: _C.text3, fontSize: 11))
                            : Text('${sm['total']}/${sm['max']}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace')),
                  )),
              // Total
              DataCell(Text(
                  '${student['totalObtained']}/${student['totalMax']}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700))),
              // Percentage
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: _C.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    '${(student['percentage'] as double).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.primary)),
              )),
              // Grade
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: g['bg'] as Color,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(g['grade'] as String,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: g['fg'] as Color)),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ── CARD VIEW ───────────────────────────────────────────────────────────────
  Widget _buildCardView() {
    final rows = _filtered;
    if (rows.isEmpty) {
      return const Center(
          child: Text('No students found', style: TextStyle(color: _C.text3)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) => _buildStudentCard(rows[idx]),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final g = student['gradeInfo'] as Map<String, dynamic>;
    final pct = student['percentage'] as double;
    final subjectMarks =
        (student['subjectMarks'] as List).cast<Map<String, dynamic>>();

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _C.shadow(),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _C.primary.withOpacity(0.08),
              const Color(0xFFD1FAE5)
            ]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _C.primary,
              child: Text(
                (student['name'] as String).isNotEmpty
                    ? (student['name'] as String)[0]
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(student['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _C.text1)),
                  Text(student['admissionNo'] as String,
                      style: const TextStyle(fontSize: 11, color: _C.text3)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: g['bg'] as Color,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(g['grade'] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: g['fg'] as Color)),
              ),
              const SizedBox(height: 4),
              Text('#${student['rank']}  ${pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: _C.text3)),
            ]),
          ]),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(pct >= 60
                  ? _C.primary
                  : pct >= 40
                      ? Colors.amber
                      : Colors.red),
            ),
          ),
        ),
        // Subject list
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
              children: subjectMarks.map((sm) {
            final sg = _gradeInfo(sm['total'] as int, sm['max'] as int);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(
                    child: Text(sm['name'] as String,
                        style: const TextStyle(fontSize: 12, color: _C.text2),
                        overflow: TextOverflow.ellipsis)),
                sm['isAbsent'] == true
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('AB',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.w700)))
                    : sm['isEntered'] == false
                        ? const Text('—',
                            style: TextStyle(color: _C.text3, fontSize: 12))
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('${sm['total']}/${sm['max']}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _C.text1)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: sg['bg'] as Color,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(sg['grade'] as String,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: sg['fg'] as Color)),
                            ),
                          ]),
              ]),
            );
          }).toList()),
        ),
        // Footer total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total',
                style: TextStyle(fontSize: 12, color: _C.text2)),
            Text('${student['totalObtained']}/${student['totalMax']}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.text1)),
          ]),
        ),
      ]),
    );
  }
}
