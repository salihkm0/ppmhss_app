import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/utils/theme.dart';
import 'package:dio/dio.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedYearId;
  String _filterStatus = 'all';
  String _filterType = 'all';
  String? _cloneTargetId;
  String? _cloneYearId;
  bool _isLoading = false;
  bool _showCloneModal = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _loadExams();
  }

  void _loadExams() {
    setState(() => _isLoading = true);
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchExamsThunk(FetchExamsAction(
      academicYearId: _selectedYearId,
      search: _searchController.text.isEmpty ? null : _searchController.text,
      limit: 100,
    )));
  }

  Future<void> _performDelete(ExamModel exam, {bool force = false}) async {
    try {
      final examService = ExamService();
      await examService.deleteExam(exam.id, force: force);
      if (mounted) {
        PopupNotification.showSuccess(
          context,
          force ? 'Exam and all its marks deleted successfully' : 'Exam deleted successfully',
        );
        _loadExams();
      }
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to delete exam';
      bool hasMarksError = false;
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['message'] != null) {
            msg = data['message'].toString();
          }
          if (data['hasMarks'] == true || msg.toLowerCase().contains('marks')) {
            hasMarksError = true;
          }
        }
      } else {
        msg = e.toString();
        if (msg.toLowerCase().contains('marks')) {
          hasMarksError = true;
        }
      }

      if (!force && hasMarksError) {
        _showForceDeletePrompt(exam, msg);
      } else {
        PopupNotification.showError(context, msg);
      }
    }
  }

  void _showForceDeletePrompt(ExamModel exam, String reason) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Force Delete Exam?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: const TextStyle(color: Colors.black87, fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                '⚠️ Force delete will permanently delete this exam AND all marks/results entered for all students in this exam. This cannot be undone.',
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performDelete(exam, force: true);
            },
            child: const Text('Force Delete All'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ExamModel exam) {
    bool forceDelete = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Exam'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${exam.displayName ?? exam.name}"?',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: forceDelete,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setDialogState(() {
                              forceDelete = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                forceDelete = !forceDelete;
                              });
                            },
                            child: const Text(
                              'Force delete (delete all marks too)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                      child: Text(
                        forceDelete
                            ? '⚠️ All entered student marks and calculated results for this exam will be permanently deleted.'
                            : 'Note: If marks have already been entered, standard deletion is blocked unless Force delete is checked.',
                        style: TextStyle(
                          fontSize: 11,
                          color: forceDelete ? Colors.red.shade800 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _performDelete(exam, force: forceDelete);
              },
              child: Text(forceDelete ? 'Force Delete' : 'Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _publishExam(String id) {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(publishExamThunk(PublishExamAction(id: id)));
    PopupNotification.showSuccess(context, 'Exam published successfully');
    _loadExams();
  }

  void _openCloneModal(ExamModel exam) {
    setState(() {
      _cloneTargetId = exam.id;
      _cloneYearId = null;
      _showCloneModal = true;
    });
  }

  void _cloneExam() {
    if (_cloneTargetId != null && _cloneYearId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(cloneExamThunk(CloneExamAction(
        id: _cloneTargetId!,
        newAcademicYearId: _cloneYearId!,
      )));
      PopupNotification.showSuccess(context, 'Exam cloned successfully');
      setState(() {
        _showCloneModal = false;
        _cloneTargetId = null;
        _cloneYearId = null;
      });
      _loadExams();
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft': return 'Draft';
      case 'submitted': return 'Submitted';
      case 'reviewed': return 'Reviewed';
      case 'published': return 'Published';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'submitted': return Colors.orange;
      case 'reviewed': return Colors.blue;
      case 'published': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'first': return 'First Term';
      case 'second': return 'Second Term';
      case 'final': return 'Final Exam';
      case 'mid': return 'Mid Term';
      case 'quarterly': return 'Quarterly';
      case 'half_yearly': return 'Half Yearly';
      case 'annual': return 'Annual';
      default: return type;
    }
  }

  int _getDraftCount(List<ExamModel> exams) => exams.where((e) => e.overallStatus == 'draft').length;
  int _getSubmittedCount(List<ExamModel> exams) => exams.where((e) => e.overallStatus == 'submitted').length;
  int _getReviewedCount(List<ExamModel> exams) => exams.where((e) => e.overallStatus == 'reviewed').length;
  int _getPublishedCount(List<ExamModel> exams) => exams.where((e) => e.overallStatus == 'published').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Examinations',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        onWillChange: (previous, next) {
          if (next.exams.isLoading == false && _isLoading) {
            setState(() => _isLoading = false);
            _refreshController.refreshCompleted();
          }
        },
        builder: (context, state) {
          final allExams = state.exams.exams;
          // Apply client-side filters
          final filteredExams = allExams.where((exam) {
            if (_filterStatus != 'all' && exam.overallStatus != _filterStatus) return false;
            if (_filterType != 'all' && exam.examType != _filterType) return false;
            return true;
          }).toList();
          
          return Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Academic Year Filter
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedYearId,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Select Academic Year'),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Years')),
                            ...state.academicYears.academicYears.map((year) => DropdownMenuItem(
                              value: year.id,
                              child: Text(year.name),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedYearId = value;
                              _loadExams();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by exam name or type...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadExams();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) => _loadExams(),
                    ),
                  ],
                ),
              ),
              
              // Stats Cards
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard('Total', allExams.length.toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Draft', _getDraftCount(allExams).toString(), Colors.grey),
                    const SizedBox(width: 8),
                    _buildStatCard('Submitted', _getSubmittedCount(allExams).toString(), Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Reviewed', _getReviewedCount(allExams).toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Published', _getPublishedCount(allExams).toString(), Colors.green),
                  ],
                ),
              ),
              
              // Exam List
              Expanded(
                child: state.exams.isLoading && allExams.isEmpty
                    ? const LoadingWidget()
                    : filteredExams.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No exams found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _loadExams,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredExams.length,
                              itemBuilder: (context, index) {
                                final exam = filteredExams[index];
                                return _buildExamCard(exam);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    final statusColor = _getStatusColor(exam.overallStatus);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/exams/detail', arguments: exam.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment, size: 24, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.displayName ?? exam.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getTypeLabel(exam.examType) != exam.examType
                                    ? Colors.purple.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getTypeLabel(exam.examType),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getTypeLabel(exam.examType) != exam.examType
                                      ? Colors.purple
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${exam.term?.toUpperCase()} Term',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(exam.overallStatus),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${Formatters.formatDate(exam.startDate)} - ${Formatters.formatDate(exam.endDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.class_, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${exam.classIds?.length ?? 0} Classes',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (exam.overallStatus != 'published' && exam.overallStatus != 'reviewed')
                    TextButton.icon(
                      onPressed: () => _publishExam(exam.id),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Publish'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/exams/edit', arguments: exam.id),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _openCloneModal(exam),
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Clone'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(exam),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Exams'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _filterStatus.isEmpty ? null : _filterStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Status')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value ?? 'all');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _filterType.isEmpty ? null : _filterType,
              decoration: const InputDecoration(labelText: 'Exam Type'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'first', child: Text('First Term')),
                DropdownMenuItem(value: 'second', child: Text('Second Term')),
                DropdownMenuItem(value: 'final', child: Text('Final')),
                DropdownMenuItem(value: 'mid', child: Text('Mid Term')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'half_yearly', child: Text('Half Yearly')),
                DropdownMenuItem(value: 'annual', child: Text('Annual')),
              ],
              onChanged: (value) {
                setState(() => _filterType = value ?? 'all');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}