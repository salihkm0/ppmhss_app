import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/modal.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/utils/theme.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedYearId;
  String? _deleteTargetId;
  List<ClassModel> _classes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));
    _loadClasses();
  }

  void _loadClasses() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchClassesThunk(FetchClassesAction(
      academicYearId: _selectedYearId,
      limit: 100,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    )));
  }

  void _confirmDelete(String id) {
    setState(() => _deleteTargetId = id);
  }

  void _deleteClass() {
    if (_deleteTargetId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(deleteClassThunk(DeleteClassAction(id: _deleteTargetId!)));
      PopupNotification.showSuccess(context, 'Class deleted successfully');
      setState(() => _deleteTargetId = null);
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Classes',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        onWillChange: (previous, next) {
          if (next.classes.isLoading == false && _isLoading) {
            setState(() => _isLoading = false);
            _refreshController.refreshCompleted();
          }
          if (next.classes.classes != previous?.classes.classes) {
            setState(() => _classes = next.classes.classes);
          }
        },
        builder: (context, state) {
          final store = StoreProvider.of<AppState>(context, listen: false);
          
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
                              _loadClasses();
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
                        hintText: 'Search by class name or teacher...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadClasses();
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
                      onChanged: (value) => _loadClasses(),
                    ),
                  ],
                ),
              ),
              
              // Stats Cards
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatCard('Total Classes', _classes.length.toString(), Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Total Students', 
                      _classes.fold(0, (sum, c) => sum + (c.studentCount ?? 0)).toString(), 
                      Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Total Subjects',
                      _classes.fold(0, (sum, c) => sum + (c.subjects?.length ?? 0)).toString(),
                      Colors.orange),
                  ],
                ),
              ),
              
              // Class List
              Expanded(
                child: state.classes.isLoading && _classes.isEmpty
                    ? const LoadingWidget()
                    : _classes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.class_, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No classes found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/classes/add'),
                                  child: const Text('Add your first class →'),
                                ),
                              ],
                            ),
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _loadClasses,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _classes.length,
                              itemBuilder: (context, index) {
                                final classObj = _classes[index];
                                return _buildClassCard(classObj);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/classes/add'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(ClassModel classObj) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/classes/detail', arguments: classObj.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_, size: 28, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classObj.displayName ?? classObj.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${classObj.studentCount ?? 0} Students',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.book, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${classObj.subjects?.length ?? 0} Subjects',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    if (classObj.classTeacherName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 12, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              'Teacher: ${classObj.classTeacherName}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(context, '/classes/edit', arguments: classObj.id);
                  } else if (value == 'delete') {
                    _confirmDelete(classObj.id);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}