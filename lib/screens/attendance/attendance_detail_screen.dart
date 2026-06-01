import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/actions/attendance_actions.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/utils/theme.dart';
import 'package:intl/intl.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  
  const AttendanceDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  int _selectedYear = DateTime.now().year;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  void _loadAttendance() {
    final store = StoreProvider.of<AppState>(context);
    store.dispatch(FetchStudentAttendanceAction(studentId: widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance - ${widget.studentName}',
        showBackButton: true,
      ),
      body: StoreConnector<AppState, AppState>(
        converter: (store) => store.state,
        onWillChange: (previous, next) {
          if (next.attendance.studentAttendance.isNotEmpty && _availableYears.isEmpty) {
            final years = next.attendance.studentAttendance
                .map((a) => a.year)
                .toSet()
                .toList();
            setState(() {
              _availableYears = years..sort((a, b) => b.compareTo(a));
              if (years.isNotEmpty && !years.contains(_selectedYear)) {
                _selectedYear = years.first;
              }
            });
          }
        },
        builder: (context, state) {
          final attendanceRecords = state.attendance.studentAttendance
              .where((a) => a.year == _selectedYear)
              .toList()
            ..sort((a, b) => b.month.compareTo(a.month));
          
          if (state.attendance.isLoading && attendanceRecords.isEmpty) {
            return const LoadingWidget();
          }
          
          if (attendanceRecords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          
          final totalDays = attendanceRecords.fold<int>(0, (sum, r) => sum + r.totalWorkingDays);
          final totalPresent = attendanceRecords.fold<int>(0, (sum, r) => sum + r.presentDays);
          final overallPercentage = totalDays > 0 ? (totalPresent / totalDays) * 100 : 0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Present Days',
                        totalPresent.toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        'Absent Days',
                        (totalDays - totalPresent).toString(),
                        Colors.red,
                        Icons.cancel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSummaryCard(
                  'Overall Attendance',
                  '${overallPercentage.toStringAsFixed(1)}%',
                  AppTheme.primaryColor,
                  Icons.trending_up,
                ),
                const SizedBox(height: 20),
                // Year Filter
                if (_availableYears.length > 1)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Text('Select Year: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedYear,
                              isExpanded: true,
                              items: _availableYears.map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedYear = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Monthly Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            Expanded(child: Text('Month', style: TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 60, child: Text('WD', textAlign: TextAlign.center)),
                            SizedBox(width: 60, child: Text('Present', textAlign: TextAlign.center)),
                            SizedBox(width: 60, child: Text('Absent', textAlign: TextAlign.center)),
                            SizedBox(width: 70, child: Text('Percentage', textAlign: TextAlign.center)),
                          ],
                        ),
                      ),
                      // Rows
                      ...attendanceRecords.map((record) => _buildAttendanceRow(record)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: color, fontSize: 12)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(dynamic record) {
    final percentage = record.percentage;
    final monthName = DateFormat('MMMM').format(DateTime(record.year, record.month));
    final color = percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(monthName)),
          SizedBox(width: 60, child: Text('${record.totalWorkingDays}', textAlign: TextAlign.center)),
          SizedBox(width: 60, child: Text('${record.presentDays}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.green))),
          SizedBox(width: 60, child: Text('${record.absentDays}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))),
          SizedBox(
            width: 70,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}