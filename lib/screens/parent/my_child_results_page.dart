// lib/screens/parent/my_child_results_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/parent_actions.dart';
import 'package:school_management/models/parent_models.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/services/api_service.dart';

class MyChildResultsPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final ExamPerformanceData? examPerformance;

  const MyChildResultsPage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.examPerformance,
  });

  @override
  State<MyChildResultsPage> createState() => _MyChildResultsPageState();
}

class _MyChildResultsPageState extends State<MyChildResultsPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  // Children
  List<StudentChild> _children = [];
  StudentChild? _selectedChild;
  bool _childrenLoading = true;
  
  // Results
  List<ExamResult> _results = [];
  bool _isLoading = false;
  String? _error;
  String? _expandedExamId;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => _childrenLoading = true);

    try {
      final store = StoreProvider.of<AppState>(context, listen: false);
      final existingChildren = store.state.parents.myChildren;
      
      if (existingChildren.isNotEmpty) {
        setState(() {
          _children = existingChildren;
          _childrenLoading = false;
        });
        _selectInitialChild();
        return;
      }

      await store.dispatch(fetchMyChildrenThunk());
      final children = store.state.parents.myChildren;

      setState(() {
        _children = children;
        _childrenLoading = false;
      });
      _selectInitialChild();
    } catch (e) {
      print('❌ Failed to load children: $e');
      setState(() => _childrenLoading = false);
    }
  }

  void _selectInitialChild() {
    if (_children.isEmpty) return;

    final match = _children.where((c) => c.id == widget.studentId).toList();
    final child = match.isNotEmpty ? match.first : _children.first;

    setState(() => _selectedChild = child);
    _loadResults(child.id);
  }

  void _handleChildSelect(StudentChild child) {
    if (_isLoading) return;
    if (_selectedChild?.id == child.id) return;

    setState(() {
      _selectedChild = child;
      _results = [];
      _expandedExamId = null;
    });
    _loadResults(child.id);
  }

  Future<void> _loadResults(String studentId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch published exams
      List<dynamic> publishedExams = [];

      try {
        final examsResponse = await _api.get('/exams?limit=100');
        final examsData = examsResponse.data['data'] ?? [];
        publishedExams = (examsData as List).where((e) => e['overallStatus'] == 'published').toList();
      } catch (e) {
        print('⚠️ Could not fetch exams list: $e');
        setState(() {
          _error = 'Exam results are not available at this time.';
          _isLoading = false;
        });
        return;
      }

      List<ExamResult> resultsList = [];

      for (var exam in publishedExams) {
        try {
          final marksResponse = await _api.get('/marks/result/${exam['_id']}/$studentId');
          final marksData = marksResponse.data['data'];

          if (marksData != null && marksData['subjects'] != null && (marksData['subjects'] as List).isNotEmpty) {
            double totalMarks = 0;
            double totalMaxMarks = 0;
            List<SubjectResult> subjects = [];

            for (var subject in marksData['subjects']) {
              final theoryScore = _parseDouble(subject['theoryScore']);
              final practicalScore = _parseDouble(subject['practicalScore']);
              final totalScore = _parseDouble(subject['totalScore']);
              final maxMarks = _parseDouble(subject['maxMarks']);

              totalMarks += totalScore;
              totalMaxMarks += maxMarks;

              subjects.add(SubjectResult(
                subjectName: subject['subjectName']?.toString() ?? '',
                maxMarks: maxMarks,
                theoryScore: theoryScore,
                practicalScore: practicalScore,
                obtainedMarks: totalScore,
                percentage: _parseDouble(subject['percentage']) ?? (maxMarks > 0 ? (totalScore / maxMarks) * 100.0 : 0.0),
                grade: subject['grade']?.toString() ?? _calculateGrade(_parseDouble(subject['percentage'])),
              ));
            }

            final overallPercentage = totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100.0 : 0.0;

            DateTime examDate;
            try {
              examDate = DateTime.parse(exam['startDate'] ?? exam['createdAt'] ?? DateTime.now().toIso8601String());
            } catch (_) {
              examDate = DateTime.now();
            }

            resultsList.add(ExamResult(
              examId: exam['_id']?.toString() ?? '',
              examName: exam['displayName']?.toString() ?? exam['name']?.toString() ?? 'Exam',
              examType: exam['examType']?.toString() ?? '',
              term: exam['term']?.toString() ?? '',
              date: examDate,
              totalMarks: totalMarks,
              totalMaxMarks: totalMaxMarks,
              percentage: overallPercentage,
              grade: _calculateGrade(overallPercentage),
              subjectResults: subjects,
            ));
          }
        } catch (e) {
          print('Skipped exam ${exam['_id']}: $e');
        }
      }

      resultsList.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _results = resultsList;
        if (_results.isNotEmpty && _expandedExamId == null) {
          _expandedExamId = _results.first.examId;
        }
      });
    } catch (e) {
      print('❌ Error loading results: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    if (percentage >= 33) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+': return Colors.green.shade700;
      case 'A': return Colors.green.shade600;
      case 'B+': return Colors.teal.shade600;
      case 'B': return Colors.blue.shade600;
      case 'C+': return Colors.orange.shade600;
      case 'C': return Colors.deepOrange.shade600;
      default: return Colors.red.shade600;
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Exam Results'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _childrenLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: () async {
                if (_selectedChild != null) {
                  await _loadResults(_selectedChild!.id);
                }
              },
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Selector
                    if (_children.length > 1) ...[
                      _buildStudentSelector(),
                      const SizedBox(height: 16),
                    ],

                    // Student Info
                    if (_selectedChild != null) ...[
                      _buildStudentInfo(_selectedChild!),
                      const SizedBox(height: 16),
                    ],

                    // Content
                    _buildContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStudentSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Student',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                final isSelected = _selectedChild?.id == child.id;
                final isLoadingThis = _isLoading && _selectedChild?.id == child.id;

                return GestureDetector(
                  onTap: () => _handleChildSelect(child),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: isSelected 
                          ? null 
                          : Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoadingThis)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected ? Colors.white : AppTheme.primaryColor,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                Formatters.getInitials(child.fullName).substring(0, 1),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          child.fullName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(StudentChild child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                Formatters.getInitials(child.fullName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        child.className,
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Roll: ${child.rollNumber}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading results...',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                if (_selectedChild != null) _loadResults(_selectedChild!.id);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No Results Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'No exam results have been published yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildExamCard(_results[index]),
    );
  }

  Widget _buildExamCard(ExamResult exam) {
    final isExpanded = _expandedExamId == exam.examId;
    final gradeColor = _getGradeColor(exam.grade);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Exam header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedExamId = isExpanded ? null : exam.examId;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.assignment, size: 24, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.examName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${exam.term} Term • ${DateFormat('MMM d, yyyy').format(exam.date)}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${exam.percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: gradeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            exam.grade,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Expanded subject details
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[100]),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school, size: 14, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'Subject-wise Performance',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subjects List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exam.subjectResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final subject = exam.subjectResults[index];
                      final percentageColor = _getPercentageColor(subject.percentage);
                      final gradeColor = _getGradeColor(subject.grade);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    subject.subjectName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: gradeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    subject.grade,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: gradeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Marks row
                            Row(
                              children: [
                                _buildMarksChip('Theory', subject.theoryScore),
                                const SizedBox(width: 8),
                                _buildMarksChip('Practical', subject.practicalScore),
                                const SizedBox(width: 8),
                                _buildMarksChip('Total', subject.obtainedMarks, isBold: true),
                                const SizedBox(width: 8),
                                _buildMarksChip('Max', subject.maxMarks),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Progress bar
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Score',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      '${subject.percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: percentageColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: (subject.percentage / 100).clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(percentageColor),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Overall summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Total Marks',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exam.totalMarks.toStringAsFixed(0)} / ${exam.totalMaxMarks.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Overall',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${exam.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getPercentageColor(exam.percentage),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey[200]),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Grade',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gradeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  exam.grade,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: gradeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksChip(String label, double value, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black87 : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

// Models
class ExamResult {
  final String examId;
  final String examName;
  final String examType;
  final String term;
  final DateTime date;
  final double totalMarks;
  final double totalMaxMarks;
  final double percentage;
  final String grade;
  final List<SubjectResult> subjectResults;

  ExamResult({
    required this.examId,
    required this.examName,
    required this.examType,
    required this.term,
    required this.date,
    required this.totalMarks,
    required this.totalMaxMarks,
    required this.percentage,
    required this.grade,
    required this.subjectResults,
  });
}

class SubjectResult {
  final String subjectName;
  final double maxMarks;
  final double theoryScore;
  final double practicalScore;
  final double obtainedMarks;
  final double percentage;
  final String grade;

  SubjectResult({
    required this.subjectName,
    required this.maxMarks,
    required this.theoryScore,
    required this.practicalScore,
    required this.obtainedMarks,
    required this.percentage,
    required this.grade,
  });
}