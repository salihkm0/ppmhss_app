// lib/screens/parent/my_child_attendance_page.dart
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

class MyChildAttendancePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final AttendanceData? attendanceData;

  const MyChildAttendancePage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.attendanceData,
  });

  @override
  State<MyChildAttendancePage> createState() => _MyChildAttendancePageState();
}

class _MyChildAttendancePageState extends State<MyChildAttendancePage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  
  // Children
  List<StudentChild> _children = [];
  StudentChild? _selectedChild;
  bool _childrenLoading = true;
  
  // Attendance
  List<AttendanceRecord> _attendanceData = [];
  bool _isLoading = false;
  String? _error;
  int _selectedYear = DateTime.now().year;
  AttendanceSummary? _summary;

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
    _loadAttendance(child.id);
  }

  void _handleChildSelect(StudentChild child) {
    if (_isLoading) return;
    if (_selectedChild?.id == child.id) return;
    
    setState(() {
      _selectedChild = child;
      _attendanceData = [];
      _summary = null;
      _error = null;
    });
    _loadAttendance(child.id);
  }

  Future<void> _loadAttendance(String studentId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get('/attendance/student/$studentId');

      List<dynamic> data;
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        data = (response.data['data'] is List) ? response.data['data'] : [];
      } else {
        data = [];
      }

      final records = data
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _attendanceData = records;
        if (records.isNotEmpty) {
          final years = records.map((r) => r.year).toSet().toList()
            ..sort((a, b) => b.compareTo(a));
          _selectedYear = years.first;
        }
        _calculateSummary();
      });
    } catch (e) {
      print('❌ Attendance load error: $e');
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateSummary() {
    int totalDays = 0;
    int totalPresent = 0;

    for (var record in _attendanceData) {
      totalDays += record.totalWorkingDays;
      totalPresent += record.presentDays;
    }

    final overallPercentage = totalDays > 0 ? (totalPresent / totalDays) * 100.0 : 0.0;

    _summary = AttendanceSummary(
      totalDays: totalDays,
      totalPresent: totalPresent,
      totalAbsent: totalDays - totalPresent,
      overallPercentage: overallPercentage,
    );
  }

  List<int> get _availableYears {
    final years = _attendanceData.map((r) => r.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (years.isNotEmpty && !years.contains(_selectedYear)) {
      _selectedYear = years.first;
    }
    return years;
  }

  List<AttendanceRecord> get _filteredAttendance {
    return _attendanceData.where((r) => r.year == _selectedYear).toList()
      ..sort((a, b) => b.month.compareTo(a.month));
  }

  String _getMonthName(int month) {
    return DateFormat('MMMM').format(DateTime(2024, month));
  }

  (Color color, String label, IconData icon) _getStatusBadge(double percentage) {
    if (percentage >= 75) return (Colors.green, 'Excellent', Icons.emoji_events);
    if (percentage >= 60) return (Colors.orange, 'Average', Icons.trending_up);
    if (percentage >= 40) return (Colors.deepOrange, 'Needs Attention', Icons.warning);
    return (Colors.red, 'Poor', Icons.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance Record'),
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
                  await _loadAttendance(_selectedChild!.id);
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
                      const SizedBox(height: 20),
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
              'Loading attendance records...',
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
              'Failed to load attendance',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                if (_selectedChild != null) _loadAttendance(_selectedChild!.id);
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

    if (_attendanceData.isEmpty) {
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
            Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No Attendance Records',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'No attendance records found for this student',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_summary != null) ...[
          _buildSummaryCards(_summary!),
          const SizedBox(height: 20),
        ],
        if (_availableYears.isNotEmpty) ...[
          _buildYearFilter(),
          const SizedBox(height: 16),
        ],
        _buildAttendanceTable(),
        const SizedBox(height: 16),
        if (_summary != null) _buildProgressBar(_summary!),
      ],
    );
  }

  Widget _buildSummaryCards(AttendanceSummary summary) {
    final status = _getStatusBadge(summary.overallPercentage);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildSummaryCard('Working Days', summary.totalDays.toString(), Icons.calendar_today, Colors.grey[700]!),
        _buildSummaryCard('Present', summary.totalPresent.toString(), Icons.check_circle, Colors.green),
        _buildSummaryCard('Absent', summary.totalAbsent.toString(), Icons.cancel, Colors.red),
        _buildSummaryCard(
          'Overall',
          '${summary.overallPercentage.toStringAsFixed(1)}%',
          status.$3,
          status.$1,
          subtitle: status.$2,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color.withOpacity(0.7)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    final years = _availableYears;
    if (years.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text('Year:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700])),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                items: years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedYear = value);
                },
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: AppTheme.primaryColor),
            onPressed: () {
              if (_selectedChild != null) _loadAttendance(_selectedChild!.id);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTable() {
    final records = _filteredAttendance;

    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No records for $_selectedYear', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.grey[50]),
            headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            dataTextStyle: const TextStyle(fontSize: 13),
            columns: const [
              DataColumn(label: Text('Month')),
              DataColumn(label: Text('Days')),
              DataColumn(label: Text('Present')),
              DataColumn(label: Text('Absent')),
              DataColumn(label: Text('%')),
              DataColumn(label: Text('Status')),
            ],
            rows: records.map((record) {
              final percentage = record.percentage;
              final status = _getStatusBadge(percentage);

              return DataRow(
                cells: [
                  DataCell(Text('${_getMonthName(record.month)} ${record.year}')),
                  DataCell(Text(record.totalWorkingDays.toString())),
                  DataCell(
                    Text(record.presentDays.toString(), 
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                  ),
                  DataCell(Text(record.absentDays.toString(), style: const TextStyle(color: Colors.red))),
                  DataCell(
                    Text('${percentage.toStringAsFixed(1)}%', 
                      style: TextStyle(color: status.$1, fontWeight: FontWeight.w500)),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status.$1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.$3, size: 12, color: status.$1),
                          const SizedBox(width: 4),
                          Text(status.$2, style: TextStyle(fontSize: 10, color: status.$1, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(AttendanceSummary summary) {
    final status = _getStatusBadge(summary.overallPercentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(status.$3, size: 18, color: status.$1),
                  const SizedBox(width: 8),
                  Text('Overall Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.$1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.overallPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: status.$1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.overallPercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(status.$1),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${summary.totalPresent} days present', style: TextStyle(fontSize: 11, color: Colors.green)),
              Text('${summary.totalAbsent} days absent', style: TextStyle(fontSize: 11, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

// Models
class AttendanceRecord {
  final int year;
  final int month;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final double percentage;

  AttendanceRecord({
    required this.year,
    required this.month,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.percentage,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    int _parseInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
    double _parseDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

    final workingDays = _parseInt(json['totalWorkingDays']);
    final present = _parseInt(json['presentDays']);
    final percentage = _parseDouble(json['percentage']);

    return AttendanceRecord(
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      totalWorkingDays: workingDays,
      presentDays: present,
      absentDays: _parseInt(json['absentDays']),
      percentage: percentage > 0 ? percentage : (workingDays > 0 ? (present / workingDays) * 100.0 : 0.0),
    );
  }
}

class AttendanceSummary {
  final int totalDays;
  final int totalPresent;
  final int totalAbsent;
  final double overallPercentage;

  AttendanceSummary({
    required this.totalDays,
    required this.totalPresent,
    required this.totalAbsent,
    required this.overallPercentage,
  });
}