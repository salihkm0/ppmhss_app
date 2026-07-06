import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/exam_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/modal.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/utils/theme.dart';
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
  String? _deleteTargetId;
  String? _cloneTargetId;
  String? _cloneYearId;
  List<ExamModel> _exams = [];
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

  void _confirmDelete(String id) {
    setState(() => _deleteTargetId = id);
  }

  void _deleteExam() {
    if (_deleteTargetId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(deleteExamThunk(DeleteExamAction(id: _deleteTargetId!)));
      PopupNotification.showSuccess(context, 'Exam deleted successfully');
      setState(() => _deleteTargetId = null);
      _loadExams();
    }
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

  int _getDraftCount() => _exams.where((e) => e.overallStatus == 'draft').length;
  int _getSubmittedCount() => _exams.where((e) => e.overallStatus == 'submitted').length;
  int _getReviewedCount() => _exams.where((e) => e.overallStatus == 'reviewed').length;
  int _getPublishedCount() => _exams.where((e) => e.overallStatus == 'published').length;

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
          if (next.exams.exams != previous?.exams.exams) {
            setState(() => _exams = next.exams.exams);
          }
        },
        builder: (context, state) {
          // Apply client-side filters
          final filteredExams = _exams.where((exam) {
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
                    _buildStatCard('Total', _exams.length.toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Draft', _getDraftCount().toString(), Colors.grey),
                    const SizedBox(width: 8),
                    _buildStatCard('Submitted', _getSubmittedCount().toString(), Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Reviewed', _getReviewedCount().toString(), Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatCard('Published', _getPublishedCount().toString(), Colors.green),
                  ],
                ),
              ),
              
              // Exam List
              Expanded(
                child: state.exams.isLoading && _exams.isEmpty
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
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/exams/add'),
                                  child: const Text('Create your first exam →'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/exams/add'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
                    onPressed: () => _confirmDelete(exam.id),
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