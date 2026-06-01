import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/staff_actions.dart';
import 'package:school_management/actions/attendance_actions.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/actions/academic_year_actions.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/models/user_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';

class StaffAttendancePage extends StatefulWidget {
  final String classId;
  final String className;

  const StaffAttendancePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<StaffAttendancePage> createState() => _StaffAttendancePageState();
}

class _StaffAttendancePageState extends State<StaffAttendancePage> {
  List<StudentModel> _students = [];
  Map<String, Map<String, dynamic>> _attendanceData = {};
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _workingDays = 0;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final store = StoreProvider.of<AppState>(context, listen: false);
    try {
      await store.dispatch(fetchStudentsByClassThunk(FetchStudentsByClassAction(classId: widget.classId)));
      await store.dispatch(fetchAttendanceByClassThunk(FetchAttendanceByClassAction(
        classId: widget.classId,
        month: _selectedMonth,
        year: _selectedYear,
      )));
      await store.dispatch(fetchAcademicYearsThunk(FetchAcademicYearsAction(limit: 100)));

      final classAttendance = store.state.attendance.classAttendance;

      // Parse working days from the response
      int workingDays = 25; // sensible default
      if (classAttendance != null) {
        final wd = classAttendance['workingDays'] ??
                   classAttendance['summary']?['workingDays'] ??
                   classAttendance['data']?['workingDays'];
        if (wd != null) {
          if (wd is num) {
            workingDays = wd.toInt();
          } else if (wd is String) {
            workingDays = int.tryParse(wd) ?? 25;
          }
        }
      }

      // Build attendanceData map from the response's attendance list or studentDetails array
      final Map<String, Map<String, dynamic>> attendanceData = {};
      if (classAttendance != null) {
        final details = classAttendance['attendance'] as List? ??
                        classAttendance['studentDetails'] as List? ??
                        classAttendance['data']?['studentDetails'] as List? ??
                        classAttendance['data']?['attendance'] as List? ??
                        [];
        for (final item in details) {
          final studentIdField = item['studentId'];
          String sid = '';
          if (studentIdField is Map) {
            sid = studentIdField['_id']?.toString() ?? '';
          } else if (studentIdField != null) {
            sid = studentIdField.toString();
          }

          if (sid.isNotEmpty) {
            final isNotEntered = item['isNotEntered'] == true || 
                                 item['isNewRecord'] == true ||
                                 ((item['presentDays'] ?? 0) == 0 && (item['absentDays'] ?? 0) == 0);
            final present = isNotEntered ? workingDays : ((item['presentDays'] as num?)?.toInt() ?? workingDays);
            final absent  = isNotEntered ? 0 : ((item['absentDays']  as num?)?.toInt() ?? 0);
            attendanceData[sid] = {
              'absentDays': absent,
              'presentDays': present,
            };
          }
        }
      }

      setState(() {
        _students = store.state.students.students;
        _workingDays = workingDays;
        _attendanceData = attendanceData;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    final store = StoreProvider.of<AppState>(context, listen: false);
    final currentAcademicYear = store.state.academicYears.currentAcademicYear;

    if (currentAcademicYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Academic year not found. Please try again.'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
      return;
    }

    final attendanceList = _students.map((student) {
      final data = _attendanceData[student.id] ?? {'absentDays': 0, 'presentDays': _workingDays};
      return {
        'studentId': student.id,
        'studentName': student.fullName,
        'classId': widget.classId,
        'academicYearId': currentAcademicYear.id,
        'year': _selectedYear,
        'month': _selectedMonth,
        'totalWorkingDays': _workingDays,
        'absentDays': data['absentDays'],
        'presentDays': data['presentDays'],
      };
    }).toList();

    try {
      await store.dispatch(bulkCreateAttendanceThunk(BulkCreateAttendanceAction(attendanceList: attendanceList)));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully'), backgroundColor: Colors.green),
      );
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateAbsentDays(String studentId, int value) {
    setState(() {
      final data = _attendanceData[studentId] ?? {'absentDays': 0, 'presentDays': _workingDays};
      final absentDays = value.clamp(0, _workingDays);
      data['absentDays'] = absentDays;
      data['presentDays'] = _workingDays - absentDays;
      _attendanceData[studentId] = data;
    });
  }

  void _setAllAbsentDays(int days) {
    final absentDays = days.clamp(0, _workingDays);
    final presentDays = _workingDays - absentDays;
    for (var student in _students) {
      _attendanceData[student.id] = {'absentDays': absentDays, 'presentDays': presentDays};
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Attendance - ${widget.className}'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Attendance',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryColor,
        child: _isLoading && _students.isEmpty
            ? const Center(child: LoadingWidget())
            : _error != null
                ? Center(child: CustomErrorWidget(message: _error!, onRetry: _loadData))
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Filters
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month', border: InputBorder.none),
                  items: List.generate(12, (i) => i + 1).map((month) {
                    return DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MMMM').format(DateTime(2000, month))),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMonth = value);
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(labelText: 'Year', border: InputBorder.none),
                  items: List.generate(5, (i) => DateTime.now().year - 2 + i).map((year) {
                    return DropdownMenuItem(value: year, child: Text(year.toString()));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedYear = value);
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text('Working Days', style: TextStyle(fontSize: 11)),
                    Text('$_workingDays', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick Actions (when editing)
        if (_isEditing && _students.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickAction('All Present', 0),
                    _buildQuickAction('2 Days Absent', 2),
                    _buildQuickAction('5 Days Absent', 5),
                    _buildQuickAction('All Absent', _workingDays),
                  ],
                ),
              ],
            ),
          ),

        // Students Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _students.isEmpty
                ? const Center(child: Text('No students in this class'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      headingRowColor: WidgetStateProperty.resolveWith((_) => Colors.grey[50]),
                      columns: const [
                        DataColumn(label: Text('#')),
                        DataColumn(label: Text('Student Name')),
                        DataColumn(label: Text('Roll No')),
                        DataColumn(label: Text('Present')),
                        DataColumn(label: Text('Absent')),
                        DataColumn(label: Text('%')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _students.asMap().entries.map((entry) {
                        final index = entry.key;
                        final student = entry.value;
                        final data = _attendanceData[student.id] ?? {'absentDays': 0, 'presentDays': _workingDays};
                        final presentDays = data['presentDays'] as int;
                        final absentDays = data['absentDays'] as int;
                        final percentage = _workingDays > 0 ? (presentDays / _workingDays) * 100 : 0;
                        final status = percentage >= 75 ? 'Good' : (percentage >= 60 ? 'Average' : 'Poor');
                        final statusColor = percentage >= 75 ? Colors.green : (percentage >= 60 ? Colors.orange : Colors.red);

                        return DataRow(
                          cells: [
                            DataCell(Text((index + 1).toString())),
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
                            DataCell(Text(presentDays.toString(), style: const TextStyle(color: Colors.green))),
                            DataCell(
                              _isEditing
                                  ? SizedBox(
                                      width: 70,
                                      child: TextFormField(
                                        initialValue: absentDays.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                        style: const TextStyle(fontSize: 12),
                                        onChanged: (value) {
                                          final days = int.tryParse(value) ?? 0;
                                          _updateAbsentDays(student.id, days);
                                        },
                                      ),
                                    )
                                  : Text(absentDays.toString(), style: const TextStyle(color: Colors.red)),
                            ),
                            DataCell(Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: statusColor))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(status, style: TextStyle(fontSize: 11, color: statusColor)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),

        // Save Button (when editing)
        if (_isEditing)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAttendance,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickAction(String label, int absentDays) {
    return OutlinedButton(
      onPressed: () => _setAllAbsentDays(absentDays),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}