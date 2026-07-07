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
import 'package:school_management/models/exam_model.dart';

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
  List<dynamic> _subjects = [];
  Map<String, Map<String, Map<String, dynamic>>> _marks = {};
  bool _isLoading = false;
  bool _isSaving = false;
  Set<String> _expandedStudents = {};

  @override
  void initState() {
    super.initState();
    _selectedExamId = widget.examId;
    _selectedClassId = widget.classId;
    _loadData();
  }

  void _loadData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchExamsThunk(FetchExamsAction(limit: 100)));
    store.dispatch(fetchClassesThunk(FetchClassesAction(limit: 100)));
    
    if (_selectedExamId != null && _selectedClassId != null) {
      _loadMarks();
    }
  }

  void _loadMarks() {
    // This would call the marks API
    setState(() => _isLoading = true);
    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _students = [
          {'studentId': '1', 'studentName': 'John Doe', 'rollNumber': '1', 'admissionNo': '2024001'},
          {'studentId': '2', 'studentName': 'Jane Smith', 'rollNumber': '2', 'admissionNo': '2024002'},
          {'studentId': '3', 'studentName': 'Michael Johnson', 'rollNumber': '3', 'admissionNo': '2024003'},
        ];
        _subjects = [
          {'subjectId': 's1', 'subjectName': 'Mathematics', 'maxMarks': 100},
          {'subjectId': 's2', 'subjectName': 'Science', 'maxMarks': 100},
          {'subjectId': 's3', 'subjectName': 'English', 'maxMarks': 100},
        ];
        
        // Initialize marks
        for (var student in _students) {
          _marks[student['studentId']] = {};
          for (var subject in _subjects) {
            _marks[student['studentId']]![subject['subjectId']] = {
              'theoryScore': 0,
              'practicalScore': 0,
              'totalScore': 0,
            };
          }
        }
        _isLoading = false;
      });
    });
  }

  void _updateMark(String studentId, String subjectId, String field, int value) {
    setState(() {
      _marks[studentId]![subjectId]![field] = value;
      final theory = _marks[studentId]![subjectId]!['theoryScore'] ?? 0;
      final practical = _marks[studentId]![subjectId]!['practicalScore'] ?? 0;
      _marks[studentId]![subjectId]!['totalScore'] = theory + practical;
    });
  }

  void _saveMarks() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));
    PopupNotification.showSuccess(context, 'Marks saved successfully');
    setState(() => _isSaving = false);
  }

  void _toggleExpand(String studentId) {
    setState(() {
      if (_expandedStudents.contains(studentId)) {
        _expandedStudents.remove(studentId);
      } else {
        _expandedStudents.add(studentId);
      }
    });
  }

  double _getStudentPercentage(Map<String, dynamic> student) {
    double totalObtained = 0;
    double totalMax = 0;
    for (var subject in _subjects) {
      final marks = _marks[student['studentId']]?[subject['subjectId']];
      totalObtained += marks?['totalScore'] ?? 0;
      totalMax += subject['maxMarks'];
    }
    return totalMax > 0 ? (totalObtained / totalMax) * 100 : 0;
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    if (percentage >= 33) return 'D';
    return 'F';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Marks Entry',
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
              
              // Subjects Row
              if (_subjects.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[50],
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _subjects.map((subject) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          subject['subjectName'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              
              // Marks Table
              Expanded(
                child: _isLoading
                    ? const LoadingWidget()
                    : _students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Select exam and class to enter marks',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final percentage = _getStudentPercentage(student);
                              final grade = _getGrade(percentage);
                              final isExpanded = _expandedStudents.contains(student['studentId']);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  children: [
                                    // Student Header
                                    ListTile(
                                      onTap: () => _toggleExpand(student['studentId']),
                                      leading: CircleAvatar(
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        child: Text(
                                          student['studentName'][0],
                                          style: TextStyle(color: AppTheme.primaryColor),
                                        ),
                                      ),
                                      title: Text(
                                        student['studentName'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text('Roll No: ${student['rollNumber']}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: _getGradeColor(percentage),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _getGradeColor(percentage).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  grade,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: _getGradeColor(percentage),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Marks Entry (Expanded)
                                    if (isExpanded)
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: _subjects.map((subject) {
                                            final marks = _marks[student['studentId']]?[subject['subjectId']];
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    subject['subjectName'],
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextFormField(
                                                          initialValue: marks?['theoryScore'].toString() ?? '0',
                                                          keyboardType: TextInputType.number,
                                                          decoration: const InputDecoration(
                                                            labelText: 'Theory Marks',
                                                            border: OutlineInputBorder(),
                                                          ),
                                                          onChanged: (value) {
                                                            _updateMark(
                                                              student['studentId'],
                                                              subject['subjectId'],
                                                              'theoryScore',
                                                              int.tryParse(value) ?? 0,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: TextFormField(
                                                          initialValue: marks?['practicalScore'].toString() ?? '0',
                                                          keyboardType: TextInputType.number,
                                                          decoration: const InputDecoration(
                                                            labelText: 'Practical Marks',
                                                            border: OutlineInputBorder(),
                                                          ),
                                                          onChanged: (value) {
                                                            _updateMark(
                                                              student['studentId'],
                                                              subject['subjectId'],
                                                              'practicalScore',
                                                              int.tryParse(value) ?? 0,
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Total: ${marks?['totalScore'] ?? 0} / ${subject['maxMarks']}',
                                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                                      ),
                                                      Text(
                                                        '${((marks?['totalScore'] ?? 0) / subject['maxMarks'] * 100).toStringAsFixed(1)}%',
                                                        style: TextStyle(color: Colors.grey[600]),
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
              child: CustomButton(
                text: 'Save All Marks',
                onPressed: _saveMarks,
                isLoading: _isSaving,
              ),
            )
          : null,
    );
  }
}