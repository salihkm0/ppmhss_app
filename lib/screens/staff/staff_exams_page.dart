import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';
import 'package:school_management/screens/staff/staff_marks_entry.dart';
import 'package:school_management/screens/staff/staff_exam_form.dart';

class StaffExamsPage extends StatefulWidget {
  final String classId;
  final String className;

  const StaffExamsPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StaffExamsPage> createState() => _StaffExamsPageState();
}

class _StaffExamsPageState extends State<StaffExamsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchTeacherExamsThunk());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.className.isNotEmpty
            ? 'Exams - ${widget.className}'
            : 'Exams'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffExamFormPage(
                    classId: widget.classId,
                    className: widget.className,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StoreConnector<AppState, _ExamViewModel>(
        converter: (store) {
          final allExams = store.state.exams.exams;
          final filteredExams = widget.classId.isNotEmpty 
              ? allExams.where((exam) {
                  return exam.classIds?.any((c) {
                    final cId = (c is Map) ? (c['_id'] ?? c['id']) : c.toString();
                    return cId == widget.classId;
                  }) ?? false;
                }).toList()
              : allExams;
              
          return _ExamViewModel(
            exams: filteredExams,
            isLoading: store.state.exams.isLoading,
            error: store.state.exams.error,
          );
        },
        builder: (context, vm) {
          if (vm.isLoading && vm.exams.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (vm.error != null && vm.exams.isEmpty) {
            return Center(
              child: CustomErrorWidget(
                  message: vm.error!, onRetry: _loadData),
            );
          }

          if (vm.exams.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.exams.length,
              itemBuilder: (context, index) =>
                  _buildExamCard(vm.exams[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    final statusColor = _statusColor(exam.overallStatus);
    final dateRange =
        '${DateFormat('d MMM').format(exam.startDate)} – ${DateFormat('d MMM yyyy').format(exam.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.quiz_outlined,
                      color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.displayName ?? exam.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateRange,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(exam.overallStatus),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[100]),
            const SizedBox(height: 8),
            // Metadata row
            Row(
              children: [
                _buildMeta(Icons.category_outlined,
                    exam.examType.toUpperCase()),
                const SizedBox(width: 16),
                _buildMeta(Icons.school_outlined, exam.term.toUpperCase()),
              ],
            ),
            const SizedBox(height: 12),
            // Action button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffMarksEntryPage(
                            classId: widget.classId,
                            className: widget.className,
                            examId: exam.id,
                            examName: exam.displayName ?? exam.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Enter Marks'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffExamFormPage(
                            classId: widget.classId,
                            className: widget.className,
                            existingExam: exam,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Exam'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No Exams Found',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'No exams have been scheduled yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'published':
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'draft':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}

class _ExamViewModel {
  final List<ExamModel> exams;
  final bool isLoading;
  final String? error;

  _ExamViewModel({
    required this.exams,
    required this.isLoading,
    this.error,
  });
}
