import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/custom_button.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/exam_service.dart';

class MarksEntryScreen extends StatefulWidget {
  final String? examId;
  final String? classId;
  
  const MarksEntryScreen({super.key, this.examId, this.classId});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  String? _selectedExamId;
  String? _selectedClassId;
  
  List<dynamic> _students = [];
  List<dynamic> _examSubjects = [];
  List<dynamic> _subjectProgress = [];
  Map<String, dynamic> _permissions = {};
  Map<String, dynamic> _languageMapping = {};
  
  // Marks state: studentId -> subjectId -> {theoryScore, practicalScore, ceMarks, isAbsent}
  Map<String, Map<String, Map<String, dynamic>>> _marks = {};
  
  bool _isLoading = false;
  bool _isSaving = false;

  final ExamService _examService = ExamService();

  @override
  void initState() {
    super.initState();
    _selectedExamId = widget.examId;
    _selectedClassId = widget.classId;
    _loadInitialData();
  }

  void _loadInitialData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    if (store.state.exams.exams.isEmpty) {
      store.dispatch(fetchExamsThunk(FetchExamsAction(limit: 100)));
    }
    if (store.state.classes.classes.isEmpty) {
      store.dispatch(fetchClassesThunk(FetchClassesAction(limit: 100)));
    }
    
    if (_selectedExamId != null && _selectedClassId != null) {
      _loadMarks();
    }
  }

  Future<void> _loadMarks() async {
    if (_selectedExamId == null || _selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final permFuture = _examService.getTeacherPermissions(
        examId: _selectedExamId!,
        classId: _selectedClassId!,
      );
      final marksFuture = _examService.getMarksForClass(
        examId: _selectedExamId!,
        classId: _selectedClassId!,
      );

      final results = await Future.wait([permFuture, marksFuture]);
      final permRes = results[0];
      final marksRes = results[1];

      setState(() {
        _permissions = permRes['data'] ?? {};
        
        final data = marksRes['data'] ?? {};
        _examSubjects = data['subjects'] ?? [];
        _students = data['students'] ?? [];
        _subjectProgress = data['subjectProgress'] ?? [];
        _languageMapping = data['languageMapping'] ?? {};
        
        // Initialize _marks
        _marks = {};
        for (var student in _students) {
          final studentId = student['studentId'];
          _marks[studentId] = {};
          
          for (var subject in (student['subjects'] ?? [])) {
            final key = subject['examSubjectId'] ?? subject['subjectId'];
            final isActuallyEntered = subject['isEntered'] == true || 
                (subject['theoryScore'] ?? 0) > 0 || 
                (subject['practicalScore'] ?? 0) > 0 || 
                ((subject['ceScore'] ?? subject['ceMarks']) ?? 0) > 0 || 
                subject['isAbsent'] == true;
                
            _marks[studentId]![key] = {
              'theoryScore': isActuallyEntered ? (subject['theoryScore'] ?? 0).toString() : '',
              'practicalScore': isActuallyEntered ? (subject['practicalScore'] ?? 0).toString() : '',
              'ceMarks': isActuallyEntered ? ((subject['ceScore'] ?? subject['ceMarks']) ?? 0).toString() : '',
              'isAbsent': subject['isAbsent'] == true,
            };
          }
        }
      });
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Failed to load marks: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMark(String studentId, String subjectId, String field, dynamic value) {
    setState(() {
      if (_marks[studentId] == null) _marks[studentId] = {};
      if (_marks[studentId]![subjectId] == null) _marks[studentId]![subjectId] = {};
      
      _marks[studentId]![subjectId]![field] = value;
      
      if (field == 'isAbsent' && value == true) {
        _marks[studentId]![subjectId]!['theoryScore'] = '0';
        _marks[studentId]![subjectId]!['practicalScore'] = '0';
        _marks[studentId]![subjectId]!['ceMarks'] = '0';
      }
    });
  }

  Future<void> _saveMarks() async {
    if (_selectedExamId == null || _selectedClassId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      List<Map<String, dynamic>> payload = [];
      
      for (var student in _students) {
        final studentId = student['studentId'];
        List<Map<String, dynamic>> subjectMarks = [];
        
        for (var subject in _examSubjects) {
          final subjId = subject['_id'] ?? subject['id'];
          final isSecondLanguage = subject['isSecondLanguage'] == true;
          final studentSubjectId = isSecondLanguage 
              ? (_languageMapping[studentId] ?? subjId) 
              : subjId;
              
          final marks = _marks[studentId]?[studentSubjectId];
          if (marks != null) {
            final tStr = marks['theoryScore']?.toString() ?? '';
            final pStr = marks['practicalScore']?.toString() ?? '';
            final cStr = marks['ceMarks']?.toString() ?? '';
            final isAbsent = marks['isAbsent'] == true;
            
            if (tStr.isNotEmpty || pStr.isNotEmpty || cStr.isNotEmpty || isAbsent) {
              subjectMarks.add({
                'examSubjectId': subjId,
                'subjectId': studentSubjectId,
                'theoryScore': isAbsent ? 0 : (double.tryParse(tStr) ?? 0),
                'practicalScore': isAbsent ? 0 : (double.tryParse(pStr) ?? 0),
                'ceMarks': isAbsent ? 0 : (double.tryParse(cStr) ?? 0),
                'isAbsent': isAbsent,
              });
            }
          }
        }
        
        if (subjectMarks.isNotEmpty) {
          payload.add({
            'studentId': studentId,
            'subjects': subjectMarks,
          });
        }
      }
      
      if (payload.isEmpty) {
        PopupNotification.showWarning(context, 'No changes to save.');
        setState(() => _isSaving = false);
        return;
      }
      
      await _examService.saveMarksForClass(
        examId: _selectedExamId!,
        classId: _selectedClassId!,
        marksData: payload,
      );
      
      if (mounted) {
        PopupNotification.showSuccess(context, 'Marks saved successfully');
        _loadMarks(); // reload to get updated calculations & status
      }
    } catch (e) {
      if (mounted) {
        PopupNotification.showError(context, 'Failed to save marks: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Map<String, dynamic> _getGradeInfo(double obtained, double max) {
    final pct = max > 0 ? (obtained / max) * 100 : 0;
    if (pct >= 90) return {'grade': 'A+', 'color': Colors.green[700]!, 'bg': Colors.green[50]!};
    if (pct >= 80) return {'grade': 'A', 'color': Colors.green, 'bg': Colors.green[50]!};
    if (pct >= 70) return {'grade': 'B+', 'color': Colors.blue[600]!, 'bg': Colors.blue[50]!};
    if (pct >= 60) return {'grade': 'B', 'color': Colors.cyan[600]!, 'bg': Colors.cyan[50]!};
    if (pct >= 50) return {'grade': 'C+', 'color': Colors.orange[600]!, 'bg': Colors.orange[50]!};
    if (pct >= 40) return {'grade': 'C', 'color': Colors.orange, 'bg': Colors.orange[50]!};
    if (pct >= 30) return {'grade': 'D+', 'color': Colors.red[400]!, 'bg': Colors.red[50]!};
    if (pct >= 20) return {'grade': 'D', 'color': Colors.red, 'bg': Colors.red[50]!};
    return {'grade': 'E', 'color': Colors.grey[600]!, 'bg': Colors.grey[100]!};
  }

  bool _hasPermissionForSubject(String subjectId) {
    // If user is class teacher or admin, they might have broad permissions
    if (_permissions['isClassTeacher'] == true) return true;
    
    final allowedSubjects = _permissions['allowedSubjects'] as List?;
    if (allowedSubjects == null) return false;
    
    return allowedSubjects.contains(subjectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Marks Entry Grid',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        builder: (context, state) {
          return Column(
            children: [
              // Selection Row
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedExamId,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Select Exam'),
                            ),
                            isExpanded: true,
                            items: state.exams.exams.where((exam) {
                              if (_selectedClassId == null) return true;
                              return exam.classIds?.any((c) {
                                final cId = (c is Map) ? (c['_id'] ?? c['id']) : c.toString();
                                return cId == _selectedClassId;
                              }) ?? false;
                            }).map((exam) {
                              return DropdownMenuItem(
                                value: exam.id,
                                child: Text(exam.displayName ?? exam.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedExamId = value);
                              if (value != null && _selectedClassId != null) {
                                _loadMarks();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedClassId,
                            hint: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Select Class'),
                            ),
                            isExpanded: true,
                            items: state.classes.classes.where((cls) {
                              if (_selectedExamId == null) return true;
                              final examList = state.exams.exams.where((e) => e.id == _selectedExamId).toList();
                              if (examList.isEmpty) return true;
                              final exam = examList.first;
                              return exam.classIds?.any((c) {
                                final cId = (c is Map) ? (c['_id'] ?? c['id']) : c.toString();
                                return cId == cls.id;
                              }) ?? false;
                            }).map((classObj) {
                              return DropdownMenuItem(
                                value: classObj.id,
                                child: Text(classObj.displayName ?? classObj.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedClassId = value);
                              if (value != null && _selectedExamId != null) {
                                _loadMarks();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Subject Progress Cards
              if (_subjectProgress.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[50],
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _subjectProgress.map((subject) {
                        final pct = (subject['percentage'] ?? 0).toDouble();
                        final done = pct == 100;
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      subject['subjectName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    done ? Icons.check_circle : Icons.access_time_filled,
                                    color: done ? Colors.green : Colors.orange,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${subject['enteredCount']}/${subject['totalStudents']} students',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: pct / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  done ? Colors.green : (pct > 0 ? Colors.orange : Colors.grey),
                                ),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              
              // Marks Table (Web-like Grid)
              Expanded(
                child: _isLoading
                    ? const LoadingWidget()
                    : _students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.table_chart, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedExamId != null && _selectedClassId != null
                                      ? 'No students found'
                                      : 'Select exam and class to enter marks',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          )
                        : _buildWebLikeTable(),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: (_selectedExamId != null && _selectedClassId != null && _students.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: 'Save Marks',
                  onPressed: _saveMarks,
                  isLoading: _isSaving,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildWebLikeTable() {
    List<DataColumn> columns = [
      const DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
    ];

    for (var subj in _examSubjects) {
      final subjName = subj['displayName'] ?? subj['subjectName'] ?? 'Unknown';
      final hasPrac = subj['hasPractical'] == true && (subj['practicalMaxMarks'] ?? 0) > 0;
      final hasCE = subj['ceEnabled'] == true && (subj['ceMaxMarks'] ?? 0) > 0;
      
      if (hasCE) {
        columns.add(DataColumn(label: Text('$subjName CE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
      }
      columns.add(DataColumn(label: Text('$subjName TE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
      if (hasPrac) {
        columns.add(DataColumn(label: Text('$subjName PR', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
      }
      columns.add(DataColumn(label: Text('$subjName Total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
      columns.add(DataColumn(label: Text('$subjName Grade', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
      columns.add(DataColumn(label: Text('$subjName Absent', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))));
    }

    List<DataRow> rows = _students.map((student) {
      final studentId = student['studentId'];
      
      List<DataCell> cells = [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                student['studentName'] ?? 'Unknown', 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
              ),
              Text(
                'Roll: ${student['rollNumber'] ?? 'N/A'}', 
                style: const TextStyle(color: Colors.grey, fontSize: 11)
              ),
            ],
          ),
        ),
      ];

      for (var subject in _examSubjects) {
        final subjId = subject['_id'] ?? subject['id'];
        final isSecondLanguage = subject['isSecondLanguage'] == true;
        final studentSubjectId = isSecondLanguage 
            ? (_languageMapping[studentId] ?? subjId) 
            : subjId;
            
        final hasPermission = _hasPermissionForSubject(studentSubjectId) || _hasPermissionForSubject(subjId);
        final marks = _marks[studentId]?[studentSubjectId] ?? {};
        final isAbsent = marks['isAbsent'] == true;
        
        final hasPrac = subject['hasPractical'] == true && (subject['practicalMaxMarks'] ?? 0) > 0;
        final hasCE = subject['ceEnabled'] == true && (subject['ceMaxMarks'] ?? 0) > 0;

        final t = double.tryParse(marks['theoryScore']?.toString() ?? '') ?? 0;
        final p = double.tryParse(marks['practicalScore']?.toString() ?? '') ?? 0;
        final c = double.tryParse(marks['ceMarks']?.toString() ?? '') ?? 0;
        final subjectTotal = t + p + c;
        final subjectMax = (subject['maxMarks'] ?? 0) + (subject['practicalMaxMarks'] ?? 0) + (subject['ceMaxMarks'] ?? 0);
        final sGrade = _getGradeInfo(subjectTotal, subjectMax.toDouble());

        // CE Cell
        if (hasCE) {
          cells.add(DataCell(_buildGridInput(
            value: marks['ceMarks']?.toString() ?? '',
            enabled: hasPermission && !isAbsent,
            onChanged: (v) => _updateMark(studentId, studentSubjectId, 'ceMarks', v),
            isAbsent: isAbsent,
          )));
        }

        // TE Cell
        cells.add(DataCell(_buildGridInput(
          value: marks['theoryScore']?.toString() ?? '',
          enabled: hasPermission && !isAbsent,
          onChanged: (v) => _updateMark(studentId, studentSubjectId, 'theoryScore', v),
          isAbsent: isAbsent,
        )));

        // PR Cell
        if (hasPrac) {
          cells.add(DataCell(_buildGridInput(
            value: marks['practicalScore']?.toString() ?? '',
            enabled: hasPermission && !isAbsent,
            onChanged: (v) => _updateMark(studentId, studentSubjectId, 'practicalScore', v),
            isAbsent: isAbsent,
          )));
        }

        // Total Cell
        cells.add(DataCell(
          Center(child: Text('$subjectTotal / $subjectMax', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ));

        // Grade Cell
        cells.add(DataCell(
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: sGrade['bg'] as Color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sGrade['grade'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sGrade['color'] as Color,
                ),
              ),
            ),
          )
        ));

        // Absent Cell
        cells.add(DataCell(
          Center(
            child: InkWell(
              onTap: hasPermission ? () {
                _updateMark(studentId, studentSubjectId, 'isAbsent', !isAbsent);
              } : null,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isAbsent ? Colors.red : Colors.white,
                  border: Border.all(color: isAbsent ? Colors.red : Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isAbsent 
                  ? const Icon(Icons.close, size: 18, color: Colors.white) 
                  : null,
              ),
            ),
          )
        ));
      }

      return DataRow(cells: cells);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columnSpacing: 20,
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildGridInput({
    required String value,
    required bool enabled,
    required bool isAbsent,
    required Function(String) onChanged,
  }) {
    return Container(
      width: 60,
      height: 40,
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: enabled,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: enabled ? Colors.black : Colors.grey, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          filled: !enabled,
          fillColor: isAbsent ? Colors.red[50] : (enabled ? Colors.white : Colors.grey[100]),
        ),
        onChanged: onChanged,
      ),
    );
  }
}