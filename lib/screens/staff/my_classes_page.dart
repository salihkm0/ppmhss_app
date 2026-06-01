import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/staff_actions.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/models/staff_model.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/models/user_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';
import 'package:school_management/screens/staff/staff_attendance_page.dart';
import 'package:school_management/screens/staff/staff_marks_entry.dart';
import 'package:school_management/screens/staff/staff_exams_page.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  ClassModel? _selectedClass;
  List<StudentModel> _students = [];
  String _searchTerm = '';
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchTeacherClassTeacherClassesThunk());
  }

  Future<void> _loadStudents(String classId) async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchStudentsByClassThunk(FetchStudentsByClassAction(classId: classId)));
  }

  void _handleClassSelect(ClassModel classItem) {
    setState(() {
      _selectedClass = classItem;
      _searchTerm = '';
      _currentPage = 1;
    });
    _loadStudents(classItem.id);
  }

  List<StudentModel> get _filteredStudents {
    if (_searchTerm.isEmpty) return _students;
    return _students.where((student) =>
      student.fullName.toLowerCase().contains(_searchTerm.toLowerCase()) ||
      (student.rollNumber?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
      (student.admissionNo?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false)
    ).toList();
  }

  List<StudentModel> get _currentStudents {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _filteredStudents.length > start 
        ? _filteredStudents.sublist(start, end > _filteredStudents.length ? _filteredStudents.length : end)
        : [];
  }

  int get _totalPages => (_filteredStudents.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Classes'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StoreConnector<AppState, _MyClassesViewModel>(
        converter: (store) => _MyClassesViewModel(
          myClasses: store.state.classes.teacherClassTeacherClasses,
          isLoading: store.state.classes.isLoading,
          error: store.state.classes.error,
          user: store.state.auth.user,
        ),
        builder: (context, vm) {
          if (vm.isLoading && vm.myClasses.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          if (vm.error != null && vm.myClasses.isEmpty) {
            return Center(
              child: CustomErrorWidget(
                message: vm.error!,
                onRetry: _loadData,
              ),
            );
          }

          if (vm.myClasses.isEmpty) {
            return _buildEmptyState(vm.user);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Selection
                  _buildClassSelector(vm.myClasses),
                  const SizedBox(height: 20),

                  // Selected Class Info
                  if (_selectedClass != null) ...[
                    _buildClassInfoCard(_selectedClass!),
                    const SizedBox(height: 16),

                    // Search Bar
                    if (_students.isNotEmpty)
                      _buildSearchBar(),

                    const SizedBox(height: 16),

                    // Students Table
                    StoreConnector<AppState, _StudentsTableViewModel>(
                      converter: (store) => _StudentsTableViewModel(
                        students: store.state.students.students,
                        isLoading: store.state.students.isLoading,
                      ),
                      builder: (context, studentVm) {
                        _students = studentVm.students;
                        if (studentVm.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: LoadingWidget(),
                            ),
                          );
                        }
                        if (studentVm.students.isEmpty) {
                          return _buildEmptyStudentsState();
                        }
                        return Column(
                          children: [
                            _buildStudentsTable(),
                            if (_totalPages > 1) _buildPagination(),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(UserModel? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.class_outlined, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Class Assigned',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'You are not assigned as a class teacher for any class.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassSelector(List<ClassModel> classes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Class', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: classes.map((classItem) {
              final isSelected = _selectedClass?.id == classItem.id;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(classItem.displayName ?? classItem.name),
                  selected: isSelected,
                  onSelected: (_) => _handleClassSelect(classItem),
                  backgroundColor: Colors.white,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildClassInfoCard(ClassModel classItem) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classItem.displayName ?? classItem.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Students: ${_students.length}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            children: [
              _buildActionButton(
                label: 'Attendance',
                icon: Icons.calendar_today,
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffAttendancePage(
                        classId: classItem.id,
                        className: classItem.displayName ?? classItem.name,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                label: 'Exams',
                icon: Icons.quiz,
                color: Colors.purple,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffExamsPage(
                        classId: classItem.id,
                        className: classItem.displayName ?? classItem.name,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                label: 'Marks',
                icon: Icons.grade,
                color: Colors.green,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StaffMarksEntryPage(
                        classId: classItem.id,
                        className: classItem.displayName ?? classItem.name,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, roll number...',
          prefixIcon: const Icon(Icons.search, size: 18),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (value) => setState(() {
          _searchTerm = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('No Students Enrolled', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('No students are enrolled in this class.', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildStudentsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.grey[50]),
          headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          dataTextStyle: const TextStyle(fontSize: 13),
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('Student Name')),
            DataColumn(label: Text('Roll No')),
            DataColumn(label: Text('Admission No')),
            DataColumn(label: Text('Parent Contact')),
          ],
          rows: _currentStudents.asMap().entries.map((entry) {
            final index = entry.key;
            final student = entry.value;
            final serial = (_currentPage - 1) * _itemsPerPage + index + 1;
            return DataRow(
              cells: [
                DataCell(Text(serial.toString())),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(student.studentCode, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                DataCell(Text(student.rollNumber?.isEmpty ?? true ? '-' : student.rollNumber!)),
                DataCell(Text(student.admissionNo?.isEmpty ?? true ? '-' : student.admissionNo!)),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (student.parentName?.isNotEmpty ?? false)
                        Text(student.parentName!, style: const TextStyle(fontSize: 12)),
                      if (student.phoneNumber?.isNotEmpty ?? false)
                        Text(student.phoneNumber!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${((_currentPage - 1) * _itemsPerPage) + 1} to ${(_currentPage * _itemsPerPage).clamp(0, _filteredStudents.length)} of ${_filteredStudents.length} students',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Text('Page $_currentPage of $_totalPages', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyClassesViewModel {
  final List<ClassModel> myClasses;
  final bool isLoading;
  final String? error;
  final UserModel? user;

  _MyClassesViewModel({
    required this.myClasses,
    required this.isLoading,
    this.error,
    this.user,
  });
}

class _StudentsTableViewModel {
  final List<StudentModel> students;
  final bool isLoading;

  _StudentsTableViewModel({
    required this.students,
    required this.isLoading,
  });
}