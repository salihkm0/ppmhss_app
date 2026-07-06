import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/attendance_actions.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/popup_notification.dart';
import 'package:school_management/services/attendance_service.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedClassId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _currentPage = 1;
  String _searchTerm = '';
  final int _itemsPerPage = 20;
  List<Map<String, dynamic>> _studentDetails = [];
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _template;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadClasses() {
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(fetchClassesThunk(FetchClassesAction(limit: 100)));
  }

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = AttendanceService();
      
      final summaryResponse = await service.getAttendanceSummary(
        classId: _selectedClassId!,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      setState(() {
        _summary = {
          'totalStudents': summaryResponse.totalStudents,
          'averageAttendance': summaryResponse.averageAttendance,
          'goodStanding': summaryResponse.goodStanding,
          'needsAttention': summaryResponse.needsAttention,
          'workingDays': summaryResponse.workingDays,
        };
        _template = summaryResponse.template;
        _studentDetails = List<Map<String, dynamic>>.from(summaryResponse.studentDetails);
        _currentPage = 1;
        _searchTerm = '';
      });
      
    } catch (e) {
      PopupNotification.showError(context, 'Failed to load attendance data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'List View'),
                Tab(text: 'Bulk Entry'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceList(),
          const BulkAttendanceWidget(),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        final filteredStudents = _studentDetails.where((student) {
          final name = student['studentName']?.toLowerCase() ?? '';
          final rollNo = student['rollNumber']?.toLowerCase() ?? '';
          final admissionNo = student['admissionNo']?.toLowerCase() ?? '';
          final search = _searchTerm.toLowerCase();
          return name.contains(search) || rollNo.contains(search) || admissionNo.contains(search);
        }).toList();
        
        final totalPages = filteredStudents.isEmpty ? 1 : (filteredStudents.length / _itemsPerPage).ceil();
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;
        final List<Map<String, dynamic>> paginatedStudents = filteredStudents.isEmpty 
            ? [] 
            : filteredStudents.sublist(
                startIndex,
                endIndex > filteredStudents.length ? filteredStudents.length : endIndex,
              ).cast<Map<String, dynamic>>();
        
        return Column(
          children: [
            _buildFilterBar(state),
            if (_summary != null && !_isLoading && _studentDetails.isNotEmpty)
              _buildStatsGrid(),
            if (_template != null && !_isLoading)
              _buildTemplateCard(),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _selectedClassId == null
                      ? _buildEmptyState('Select a class to view attendance')
                      : _studentDetails.isEmpty
                          ? _buildEmptyState('No students found in this class')
                          : _buildStudentList(paginatedStudents, _summary?['workingDays'] ?? 25, filteredStudents.length, totalPages),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(AppState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedClassId,
                  hint: 'Select Class',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Class')),
                    ...state.classes.classes.map((classObj) => DropdownMenuItem(
                      value: classObj.id,
                      child: Text(classObj.displayName ?? classObj.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                      _studentDetails = [];
                      _summary = null;
                      _template = null;
                      _currentPage = 1;
                      if (value != null) {
                        _loadAttendance();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedMonth,
                  hint: 'Month',
                  items: List.generate(12, (i) => i + 1).map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MMMM').format(DateTime(2000, month))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                      if (_selectedClassId != null) _loadAttendance();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedYear,
                  hint: 'Year',
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((year) {
                    return DropdownMenuItem(value: year, child: Text(year.toString()));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      if (_selectedClassId != null) _loadAttendance();
                    });
                  },
                ),
              ),
            ],
          ),
          if (_studentDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSearchField(),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, roll number, or admission number...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                  onPressed: () => setState(() => _searchTerm = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() {
          _searchTerm = value;
          _currentPage = 1;
        }),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Total Students',
            _summary?['totalStudents']?.toString() ?? '0',
            Icons.people_outline,
            Colors.blue,
          ),
          _buildStatCard(
            'Average',
            '${_summary?['averageAttendance']?.toStringAsFixed(1) ?? '0'}%',
            Icons.trending_up,
            Colors.green,
          ),
          _buildStatCard(
            'Good Standing',
            _summary?['goodStanding']?.toString() ?? '0',
            Icons.verified_outlined,
            Colors.green,
          ),
          _buildStatCard(
            'Needs Attention',
            _summary?['needsAttention']?.toString() ?? '0',
            Icons.warning_amber_rounded,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_template?['name']} • ${_template?['totalWorkingDays']} Working Days • ${(_template?['holidays'] as List?)?.length ?? 0} Holidays',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students, int workingDays, int totalStudents, int totalPages) {
    if (students.isEmpty && _searchTerm.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No students match your search',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              
              // Check if attendance data exists
              final isNotRecorded = student['status'] == 'Not Recorded';
              final hasPresentData = student.containsKey('presentDays') && student['presentDays'] != null;
              final hasAbsentData = student.containsKey('absentDays') && student['absentDays'] != null;
              final presentDaysRaw = (student['presentDays'] ?? 0).toInt();
              final absentDaysRaw = (student['absentDays'] ?? 0).toInt();
              
              // If no attendance data, set present = workingDays, absent = 0
              final presentDays = isNotRecorded
                  ? 0
                  : (((!hasPresentData && !hasAbsentData) || (presentDaysRaw == 0 && absentDaysRaw == 0)) 
                      ? workingDays 
                      : presentDaysRaw);
              final absentDays = isNotRecorded
                  ? 0
                  : (((!hasPresentData && !hasAbsentData) || (presentDaysRaw == 0 && absentDaysRaw == 0)) 
                      ? 0 
                      : absentDaysRaw);
              
              final percentage = isNotRecorded ? 0.0 : (workingDays > 0 ? (presentDays / workingDays) * 100 : 0.0);
              final status = isNotRecorded ? 'Not Recorded' : (percentage >= 75 ? 'Good' : (percentage >= 60 ? 'Average' : 'Poor'));
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.primaryColor,
                                      AppTheme.primaryColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    student['studentName']?.substring(0, 1).toUpperCase() ?? '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student['studentName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Roll No: ${student['rollNumber'] ?? '-'} • Admission: ${student['admissionNo'] ?? '-'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(percentage).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(percentage),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey[100], height: 1),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildAttendanceBadge('Present', presentDays, Colors.green),
                              const SizedBox(width: 16),
                              _buildAttendanceBadge('Absent', absentDays, Colors.red),
                              const Spacer(),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(percentage),
                                ),
                              ),
                            ],
                          ),
                          if (isNotRecorded || (!hasPresentData && !hasAbsentData) || (presentDaysRaw == 0 && absentDaysRaw == 0))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                isNotRecorded 
                                    ? 'No attendance records' 
                                    : 'No attendance records • Defaulted to full attendance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (totalPages > 1)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_currentPage / $totalPages',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttendanceBadge(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          '$value',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage > 0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (_selectedClassId != null && !_isLoading)
            TextButton(
              onPressed: _loadAttendance,
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }
}

// Bulk Attendance Widget
class BulkAttendanceWidget extends StatefulWidget {
  const BulkAttendanceWidget({super.key});

  @override
  State<BulkAttendanceWidget> createState() => _BulkAttendanceWidgetState();
}

class _BulkAttendanceWidgetState extends State<BulkAttendanceWidget> {
  String? _selectedClassId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _totalWorkingDays = 25;
  Map<String, int> _absentDays = {};
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _students = [];
  String _searchTerm = '';
  Map<String, dynamic>? _template;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        return Column(
          children: [
            _buildFilterBar(state),
            if (_template != null)
              _buildTemplateCard(),
            if (_students.isNotEmpty)
              _buildStatsBar(),
            if (_students.isNotEmpty)
              _buildQuickActions(),
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _selectedClassId == null
                      ? _buildEmptyState('Select a class to manage attendance')
                      : _students.isEmpty
                          ? _buildEmptyState('No students found')
                          : _buildStudentList(),
            ),
            if (_students.isNotEmpty)
              _buildSaveButton(),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(AppState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedClassId,
                  hint: 'Select Class',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Class')),
                    ...state.classes.classes.map((classObj) => DropdownMenuItem(
                      value: classObj.id,
                      child: Text(classObj.displayName ?? classObj.name),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedClassId = value;
                      _students = [];
                      _absentDays = {};
                      _template = null;
                      if (value != null) _loadAttendance();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedMonth,
                  hint: 'Month',
                  items: List.generate(12, (i) => i + 1).map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MMMM').format(DateTime(2000, month))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value!;
                      if (_selectedClassId != null) _loadAttendance();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  value: _selectedYear,
                  hint: 'Year',
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((year) {
                    return DropdownMenuItem(value: year, child: Text(year.toString()));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      if (_selectedClassId != null) _loadAttendance();
                    });
                  },
                ),
              ),
            ],
          ),
          if (_students.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSearchField(),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or roll number...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey[500]),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                  onPressed: () => setState(() => _searchTerm = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchTerm = value),
      ),
    );
  }

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final service = AttendanceService();
      final summaryResponse = await service.getAttendanceSummary(
        classId: _selectedClassId!,
        year: _selectedYear,
        month: _selectedMonth,
      );
      
      setState(() {
        _template = summaryResponse.template;
        _totalWorkingDays = summaryResponse.workingDays;
        _students = List<Map<String, dynamic>>.from(summaryResponse.studentDetails);
        
        // Initialize absent days for each student
        for (var student in summaryResponse.studentDetails) {
          final studentId = student['studentId'];
          final presentDays = (student['presentDays'] ?? 0).toInt();
          final absentDaysRaw = (student['absentDays'] ?? 0).toInt();
          
          // Check if attendance data exists
          final isNotRecorded = student['status'] == 'Not Recorded';
          final hasPresentData = student.containsKey('presentDays') && student['presentDays'] != null;
          final hasAbsentData = student.containsKey('absentDays') && student['absentDays'] != null;
          
          // If no data exists or both are zero, or if it is Not Recorded, set absent = 0
          final shouldSetDefault = isNotRecorded || (!hasPresentData && !hasAbsentData) || (presentDays == 0 && absentDaysRaw == 0);
          
          _absentDays[studentId] = shouldSetDefault ? 0 : absentDaysRaw;
        }
      });
    } catch (e) {
      print('❌ Error loading attendance: $e');
      PopupNotification.showError(context, 'Failed to load attendance data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTemplateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_template?['name']} • ${_template?['totalWorkingDays']} Working Days',
              style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    final studentsWithData = _absentDays.keys.where((id) => _absentDays[id] != 0).length;
    final totalPresent = _absentDays.values.fold(0, (sum, absent) => sum + (_totalWorkingDays - absent));
    final totalStudents = _students.length;
    final avgAttendance = totalStudents > 0 && _totalWorkingDays > 0 
        ? (totalPresent / (totalStudents * _totalWorkingDays)) * 100 
        : 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStat('Students', totalStudents.toString(), Icons.people_outline, Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactStat('With Data', studentsWithData.toString(), Icons.check_circle_outline, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCompactStat('Avg ${avgAttendance.toStringAsFixed(0)}%', '', Icons.trending_up, Colors.purple),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildActionChip('All Present', Colors.green, () => _setAllAbsent(0)),
          _buildActionChip('2 Days Absent', Colors.orange, () => _setAllAbsent(2)),
          _buildActionChip('5 Days Absent', Colors.red, () => _setAllAbsent(5)),
          _buildActionChip('All Absent', Colors.red, () => _setAllAbsent(_totalWorkingDays)),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label, Color color, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onPressed,
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _setAllAbsent(int days) {
    setState(() {
      for (var student in _students) {
        final studentId = student['studentId'];
        if (studentId != null) {
          _absentDays[studentId] = days.clamp(0, _totalWorkingDays);
        }
      }
    });
    PopupNotification.showSuccess(context, 'Updated all students');
  }

  Widget _buildStudentList() {
    final filteredStudents = _students.where((student) {
      final name = student['studentName']?.toLowerCase() ?? '';
      final rollNo = student['rollNumber']?.toString().toLowerCase() ?? '';
      final search = _searchTerm.toLowerCase();
      return name.contains(search) || rollNo.contains(search);
    }).toList();
    
    if (filteredStudents.isEmpty && _searchTerm.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No students match your search', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final student = filteredStudents[index];
        final studentId = student['studentId'];
        final absent = _absentDays[studentId] ?? 0;
        final present = _totalWorkingDays - absent;
        final percentage = _totalWorkingDays > 0 ? (present / _totalWorkingDays) * 100 : 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      student['studentName']?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['studentName'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Roll No: ${student['rollNumber'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: absent.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Absent Days',
                      labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) {
                      final days = int.tryParse(value) ?? 0;
                      setState(() {
                        _absentDays[studentId] = days.clamp(0, _totalWorkingDays);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          if (_selectedClassId != null && !_isLoading)
            TextButton(
              onPressed: _loadAttendance,
              child: const Text('Try Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Save All Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    if (_selectedClassId == null) {
      PopupNotification.showError(context, 'Please select a class');
      return;
    }
    
    setState(() => _isSaving = true);
    
    final store = StoreProvider.of<AppState>(context, listen: false);
    final state = store.state;
    final currentAcademicYear = state.academicYears.currentAcademicYear;
    
    if (currentAcademicYear == null) {
      PopupNotification.showError(context, 'Academic year not found');
      setState(() => _isSaving = false);
      return;
    }
    
    final attendanceList = _students.map((student) {
      final studentId = student['studentId'];
      final absentDays = _absentDays[studentId] ?? 0;
      return {
        'studentId': studentId,
        'studentName': student['studentName'],
        'classId': _selectedClassId,
        'academicYearId': currentAcademicYear.id,
        'year': _selectedYear,
        'month': _selectedMonth,
        'totalWorkingDays': _totalWorkingDays,
        'absentDays': absentDays,
        'presentDays': _totalWorkingDays - absentDays,
      };
    }).toList();
    
    try {
      final service = AttendanceService();
      await service.bulkCreateAttendance(attendanceList);
      PopupNotification.showSuccess(context, 'Attendance saved successfully');
      await _loadAttendance();
    } catch (e) {
      PopupNotification.showError(context, 'Failed to save attendance');
    } finally {
      setState(() => _isSaving = false);
    }
  }
}