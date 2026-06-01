import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/subject_actions.dart';
import 'package:school_management/models/subject_model.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/modal.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/utils/theme.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final RefreshController _refreshController = RefreshController();
  final TextEditingController _searchController = TextEditingController();
  String _filterType = '';
  String? _deleteTargetId;
  List<SubjectModel> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    setState(() => _isLoading = true);
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchSubjectsThunk(FetchSubjectsAction(
      search: _searchController.text.isEmpty ? null : _searchController.text,
      type: _filterType.isEmpty ? null : _filterType,
      limit: 100,
    )));
  }

  void _confirmDelete(String id) {
    setState(() => _deleteTargetId = id);
  }

  void _deleteSubject() {
    if (_deleteTargetId != null) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(deleteSubjectThunk(DeleteSubjectAction(id: _deleteTargetId!)));
      PopupNotification.showSuccess(context, 'Subject deactivated successfully');
      setState(() => _deleteTargetId = null);
      _loadSubjects();
    }
  }

  String _getTypeColor(String type) {
    switch (type) {
      case 'core': return 'green';
      case 'elective': return 'blue';
      default: return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Subjects',
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
          if (next.subjects.isLoading == false && _isLoading) {
            setState(() => _isLoading = false);
            _refreshController.refreshCompleted();
          }
          if (next.subjects.subjects != previous?.subjects.subjects) {
            setState(() => _subjects = next.subjects.subjects);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or code...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _loadSubjects();
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
                  onChanged: (value) => _loadSubjects(),
                ),
              ),
              
              // Stats Row
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildStatCard('Total', _subjects.length.toString(), Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard('Core', 
                      _subjects.where((s) => s.type == 'core').length.toString(), 
                      Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard('Elective',
                      _subjects.where((s) => s.type == 'elective').length.toString(),
                      Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Subject List
              Expanded(
                child: state.subjects.isLoading && _subjects.isEmpty
                    ? const LoadingWidget()
                    : _subjects.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.book, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No subjects found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(context, '/subjects/add'),
                                  child: const Text('Add your first subject →'),
                                ),
                              ],
                            ),
                          )
                        : SmartRefresher(
                            controller: _refreshController,
                            onRefresh: _loadSubjects,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _subjects.length,
                              itemBuilder: (context, index) {
                                final subject = _subjects[index];
                                return _buildSubjectCard(subject);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/subjects/add'),
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

  Widget _buildSubjectCard(SubjectModel subject) {
    final typeColor = _getTypeColor(subject.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              child: const Icon(Icons.book, size: 28, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${subject.code}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor == 'green' 
                              ? Colors.green.withOpacity(0.1)
                              : typeColor == 'blue'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: typeColor == 'green'
                                ? Colors.green
                                : typeColor == 'blue'
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                        ),
                      ),
                      if (subject.creditHours != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${subject.creditHours} Credits',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
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
                  Navigator.pushNamed(context, '/subjects/edit', arguments: subject.id);
                } else if (value == 'delete') {
                  _confirmDelete(subject.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Subjects'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _filterType.isEmpty ? null : _filterType,
              decoration: const InputDecoration(labelText: 'Subject Type'),
              items: const [
                DropdownMenuItem(value: '', child: Text('All Types')),
                DropdownMenuItem(value: 'core', child: Text('Core')),
                DropdownMenuItem(value: 'elective', child: Text('Elective')),
                DropdownMenuItem(value: 'optional', child: Text('Optional')),
              ],
              onChanged: (value) {
                setState(() => _filterType = value ?? '');
                Navigator.pop(context);
                _loadSubjects();
              },
            ),
          ],
        ),
      ),
    );
  }
}