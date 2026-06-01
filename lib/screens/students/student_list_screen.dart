import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/modal.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/utils/theme.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedClassId;
  String? _selectedAcademicYearId;
  String _selectedStatus = 'active';
  int _currentPage = 1;
  bool _isLoadingMore = false;
  String? _deleteTargetId;
  List<StudentModel> _students = [];
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadInitialData();
  }

  void _loadInitialData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchClassesThunk(FetchClassesAction(limit: 100)));
    store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
    _loadStudents();
  }

  void _loadStudents({bool refresh = true}) {
    if (refresh) {
      _currentPage = 1;
      setState(() => _isLoadingMore = false);
    }
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchStudentsThunk(FetchStudentsAction(
      page: _currentPage,
      limit: 20,
      search: _searchController.text.isEmpty ? null : _searchController.text,
      classId: _selectedClassId,
      academicYearId: _selectedAcademicYearId,
      status: _selectedStatus,
    )));
  }

  void _confirmDelete(String id) {
    setState(() => _deleteTargetId = id);
  }

  void _deleteStudent() {
    if (_deleteTargetId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(deleteStudentThunk(DeleteStudentAction(id: _deleteTargetId!)));
      setState(() => _deleteTargetId = null);
      PopupNotification.showSuccess(context, 'Student deleted successfully');
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedClassId = null;
      _selectedAcademicYearId = null;
      _selectedStatus = 'active';
      _currentPage = 1;
    });
    _loadStudents();
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'active': return 'green';
      case 'inactive': return 'grey';
      case 'discontinued': return 'red';
      case 'transferred': return 'orange';
      case 'completed': return 'blue';
      default: return 'grey';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'inactive': return 'Inactive';
      case 'discontinued': return 'Discontinued';
      case 'transferred': return 'Transferred';
      case 'completed': return 'Completed';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Students',
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
          if (next.students.isLoading == false && _isLoadingMore) {
            setState(() => _isLoadingMore = false);
            _refreshController.loadComplete();
          }
          if (next.students.isLoading == false && previous?.students.isLoading == true) {
            _refreshController.refreshCompleted();
          }
          
          // Update local state when students change
          if (next.students.students != previous?.students.students) {
            setState(() {
              _students = next.students.students;
              _total = next.students.total;
              _hasMore = next.students.hasMore;
            });
          }
        },
        builder: (context, state) {
          final store = StoreProvider.of<AppState>(context, listen: false);
          
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, admission no, or student code...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _loadStudents();
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
                  onChanged: (value) => _loadStudents(),
                ),
              ),
              // Stats Row
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total', _total.toString(), Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Active', state.students.students.where((s) => s.status == 'active').length.toString(), Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Inactive', state.students.students.where((s) => s.status == 'inactive').length.toString(), Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Student List
              Expanded(
                child: (state.students.isLoading && _students.isEmpty)
                    ? const LoadingWidget()
                    : _students.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No students found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/students/add'),
                                  child: const Text('Add your first student →'),
                                ),
                              ],
                            ),
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: () => _loadStudents(),
                            onLoading: () {
                              if (_hasMore && !_isLoadingMore) {
                                setState(() => _isLoadingMore = true);
                                _currentPage++;
                                _loadStudents(refresh: false);
                              }
                            },
                            enablePullUp: _hasMore,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _students.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _students.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: LoadingWidget(size: 32)),
                                  );
                                }
                                final student = _students[index];
                                return _buildStudentCard(student);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/students/add'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    final statusColor = _getStatusColor(student.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/students/detail', arguments: student.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    Formatters.getInitials(student.fullName),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Code: ${student.studentCode}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Class: ${student.className ?? 'N/A'}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (student.admissionNo != null)
                      Text(
                        'Admission: ${student.admissionNo}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(student.status) == 'green'
                      ? Colors.green.withOpacity(0.1)
                      : _getStatusColor(student.status) == 'red'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(student.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(student.status) == 'green'
                        ? Colors.green
                        : _getStatusColor(student.status) == 'red'
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(context, '/students/edit', arguments: student.id);
                  } else if (value == 'delete') {
                    _confirmDelete(student.id);
                  }
                },
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
        title: const Text('Filter Students'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'discontinued', child: Text('Discontinued')),
                DropdownMenuItem(value: 'transferred', child: Text('Transferred')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadStudents();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}