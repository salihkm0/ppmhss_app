import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/attendance_service.dart';
import 'package:school_management/services/student_service.dart';
import 'package:school_management/services/academic_year_service.dart';
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

class _StaffAttendancePageState extends State<StaffAttendancePage>
    with SingleTickerProviderStateMixin {
  List<StudentModel> _students = [];
  Map<String, Map<String, dynamic>> _attendanceData = {};
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _workingDays = 0;
  String? _academicYearId; // cached locally — no Redux needed
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  String _searchQuery = '';
  late AnimationController _fabAnimCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fabScale = CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.easeOutBack);
    _loadData();
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      // Fetch students and attendance concurrently, both directly from services
      final studentService = StudentService();
      final attendanceService = AttendanceService();

      final results = await Future.wait([
        studentService.getStudentsByClass(widget.classId),
        attendanceService.getAttendanceByClass(
          classId: widget.classId,
          month: _selectedMonth,
          year: _selectedYear,
        ),
        AcademicYearService().getCurrentAcademicYear(),
      ]);

      final freshStudents = results[0] as List<StudentModel>;
      final rawResponse   = results[1] as Map<String, dynamic>;
      final academicYear  = results[2];

      // Parse working days
      int workingDays = 25;
      final wd = rawResponse['workingDays'] ?? rawResponse['data']?['workingDays'];
      if (wd != null) {
        workingDays = wd is num ? wd.toInt() : (int.tryParse(wd.toString()) ?? 25);
      }

      // Parse attendance records into a map keyed by studentId
      final Map<String, Map<String, dynamic>> attendanceData = {};
      final details = (rawResponse['attendance'] as List? ?? []);
      for (final item in details) {
        final studentIdField = item['studentId'];
        final String sid = studentIdField is Map
            ? (studentIdField['_id']?.toString() ?? '')
            : (studentIdField?.toString() ?? '');
        if (sid.isEmpty) continue;

        final presentVal = item['presentDays'];
        final absentVal  = item['absentDays'];
        final isNotEntered = item['isNotEntered'] == true ||
            item['isNewRecord'] == true ||
            (presentVal == null && absentVal == null);
        attendanceData[sid] = {
          'presentDays': isNotEntered ? workingDays : ((presentVal as num?)?.toInt() ?? workingDays),
          'absentDays':  isNotEntered ? 0           : ((absentVal  as num?)?.toInt() ?? 0),
        };
      }

      if (mounted) {
        setState(() {
          if (freshStudents.isNotEmpty) _students = freshStudents;
          _workingDays    = workingDays;
          _attendanceData = Map<String, Map<String, dynamic>>.from(attendanceData);
          // Cache academic year ID for save
          final ay = academicYear;
          if (ay != null) _academicYearId = (ay as dynamic).id?.toString();
        });
      }
    } catch (e, st) {
      print('❌ _loadData error: $e\n$st');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    // Use cached academic year ID; if missing, fetch it now
    String? ayId = _academicYearId;
    if (ayId == null) {
      try {
        final ay = await AcademicYearService().getCurrentAcademicYear();
        ayId = ay.id;
        _academicYearId = ayId;
      } catch (_) {}
    }

    if (ayId == null || ayId.isEmpty) {
      _showSnack('Academic year not found. Please try again.', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    // Save ALL students with their current attendance data
    final attendanceList = _students.map((student) {
      final data = _attendanceData[student.id] ?? {'absentDays': 0, 'presentDays': _workingDays};
      return {
        'studentId': student.id,
        'studentName': student.fullName,
        'classId': widget.classId,
        'academicYearId': ayId,
        'year': _selectedYear,
        'month': _selectedMonth,
        'totalWorkingDays': _workingDays,
        'absentDays': data['absentDays'],
        'presentDays': data['presentDays'],
      };
    }).toList();
    print('💾 Saving ${attendanceList.length} students');

    bool savedOk = false;
    try {
      final service = AttendanceService();
      await service.bulkCreateAttendance(attendanceList);
      savedOk = true;
      print('✅ Attendance saved successfully, now reloading...');
    } catch (e) {
      print('❌ Save error: $e');
      _showSnack('Failed to save: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }

    if (savedOk) {
      // Load fresh data FIRST, then exit editing mode — both merge in one rebuild
      await _loadData();
      _setEditing(false);
      _showSnack('Attendance saved successfully');
    }
  }

  void _setEditing(bool value) {
    setState(() => _isEditing = value);
    if (value) {
      _fabAnimCtrl.forward();
    } else {
      _fabAnimCtrl.reverse();
    }
  }

  void _updateAbsentDays(String studentId, int value) {
    HapticFeedback.lightImpact();
    setState(() {
      final data =
          _attendanceData[studentId] ?? {'absentDays': 0, 'presentDays': _workingDays};
      final absent = value.clamp(0, _workingDays);
      data['absentDays'] = absent;
      data['presentDays'] = _workingDays - absent;
      _attendanceData[studentId] = data;
    });
  }

  void _setAllAbsentDays(int days) {
    HapticFeedback.mediumImpact();
    final absent = days.clamp(0, _workingDays);
    final present = _workingDays - absent;
    for (var s in _students) {
      _attendanceData[s.id] = {'absentDays': absent, 'presentDays': present};
    }
    setState(() {});
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<StudentModel> get _filtered {
    if (_searchQuery.isEmpty) return _students;
    final q = _searchQuery.toLowerCase();
    return _students.where((s) =>
        s.fullName.toLowerCase().contains(q) ||
        (s.rollNumber?.toLowerCase().contains(q) ?? false) ||
        s.studentCode.toLowerCase().contains(q)).toList();
  }

  int get _totalPresent =>
      _students.fold(0, (sum, s) =>
          sum + ((_attendanceData[s.id]?['presentDays'] ?? _workingDays) as int));

  // ───────────────────────────── UI ──────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: NestedScrollView(
            headerSliverBuilder: (ctx, scrolled) => [_buildSliverAppBar(scrolled)],
            body: RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primaryColor,
              child: _isLoading && _students.isEmpty
                  ? const Center(child: LoadingWidget())
                  : _error != null
                      ? Center(child: CustomErrorWidget(message: _error!, onRetry: _loadData))
                      : _buildBody(),
            ),
          ),
          floatingActionButton: _isEditing ? _buildFAB() : null,
        ),
        // ── Saving overlay ─────────────────────────────────────────
        if (_isSaving)
          ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.45)),
        if (_isSaving)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
                  const SizedBox(height: 16),
                  const Text('Saving attendance…',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                ],
              ),
            ),
          ),
        // ── Refetch overlay (students already loaded) ───────────────
        if (_isLoading && _students.isNotEmpty)
          ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.2)),
        if (_isLoading && _students.isNotEmpty)
          const Center(child: LoadingWidget()),
      ],
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────

  Widget _buildSliverAppBar(bool scrolled) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      floating: false,
      elevation: scrolled ? 4 : 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(widget.className,
              style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w400)),
        ],
      ),
      actions: [
        if (!_isEditing)
          _pill(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onTap: () => _setEditing(true),
            color: Colors.white,
            bg: Colors.white.withOpacity(0.18),
          )
        else
          _pill(
            label: 'Cancel',
            icon: Icons.close,
            onTap: () => _setEditing(false),
            color: Colors.white70,
            bg: Colors.transparent,
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bg,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final avgPct = _students.isNotEmpty && _workingDays > 0
        ? (_totalPresent / (_students.length * _workingDays)) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 72, 20, 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month / Year selectors
              Row(
                children: [
                  _dropdownPill(
                    icon: Icons.calendar_month_outlined,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        dropdownColor: AppTheme.primaryColor,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        iconEnabledColor: Colors.white70,
                        isDense: true,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(DateFormat('MMMM').format(DateTime(2000, m)))))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedMonth = v);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _dropdownPill(
                    icon: Icons.today_outlined,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        dropdownColor: AppTheme.primaryColor,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        iconEnabledColor: Colors.white70,
                        isDense: true,
                        items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text(y.toString())))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedYear = v);
                            _loadData();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stats chips
              Wrap(
                spacing: 8,
                children: [
                  _statChip(Icons.people_alt_outlined, '${_students.length}', 'Students', Colors.white),
                  _statChip(Icons.trending_up_rounded, '${avgPct.toStringAsFixed(0)}%', 'Avg Attendance', Colors.greenAccent),
                  _statChip(Icons.work_history_outlined, '$_workingDays', 'Working Days', Colors.amberAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownPill({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          child,
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String val, String label, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────

  Widget _buildBody() {
    return Column(
      children: [
        if (_isEditing) _editingBanner(),
        if (_students.isNotEmpty) _searchBar(),
        if (_isEditing && _students.isNotEmpty) _quickActions(),
        Expanded(
          child: _students.isEmpty
              ? _emptyState()
              : _filtered.isEmpty
                  ? _noResults()
                  : ListView.builder(
                      key: ValueKey('list_${_attendanceData.hashCode}'),
                      padding:
                          EdgeInsets.fromLTRB(16, 8, 16, _isEditing ? 110 : 24),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => _studentCard(_filtered[i], i),
                    ),
        ),
      ],
    );
  }

  Widget _editingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.amber.shade50,
      child: Row(
        children: [
          Icon(Icons.edit_note_rounded, size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing mode — use + / − to adjust absent days, then save.',
              style: TextStyle(
                  fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search student by name or roll…',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey[400]),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BULK SET',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[500],
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _quickChip('All Present', Icons.check_circle_outline, Colors.green, 0),
                _quickChip('2 Absent', Icons.remove_circle_outline, Colors.orange, 2),
                _quickChip('5 Absent', Icons.remove_circle_outline, Colors.deepOrange, 5),
                _quickChip('All Absent', Icons.cancel_outlined, Colors.red, _workingDays),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickChip(String label, IconData icon, Color color, int days) {
    return GestureDetector(
      onTap: () => _setAllAbsentDays(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── Student Card ──────────────────────────────────────────────

  Widget _studentCard(StudentModel student, int index) {
    final data = _attendanceData[student.id] ??
        {'absentDays': 0, 'presentDays': _workingDays};
    final present = (data['presentDays'] as int?) ?? _workingDays;
    final absent = (data['absentDays'] as int?) ?? 0;
    final pct = _workingDays > 0 ? (present / _workingDays) * 100 : 0.0;

    final Color statusColor;
    final String statusLabel;
    if (pct >= 75) {
      statusColor = Colors.green;
      statusLabel = 'Good';
    } else if (pct >= 60) {
      statusColor = Colors.orange;
      statusLabel = 'Average';
    } else {
      statusColor = Colors.red;
      statusLabel = 'Poor';
    }

    final initials = student.fullName.isNotEmpty
        ? student.fullName.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return AnimatedContainer(
      key: ValueKey('${student.id}_${present}_$absent'),
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        border: _isEditing
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1.5)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Avatar + Name + Badge ─────────────────────
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.7),
                        AppTheme.primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (student.rollNumber != null &&
                              student.rollNumber!.isNotEmpty) ...[
                            _tag('Roll: ${student.rollNumber}'),
                            const SizedBox(width: 6),
                          ],
                          _tag(student.studentCode, subtle: true),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor)),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 14),

            // ── Row 2: Present | Progress | Absent ───────────────
            Row(
              children: [
                // Present stat
                _dayStat('Present', present, Colors.green, Icons.check_circle_rounded),
                // Progress + pct
                Expanded(
                  child: Column(
                    children: [
                      Text('${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _workingDays > 0 ? present / _workingDays : 0,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                // Absent stat
                _dayStat('Absent', absent, Colors.red, Icons.cancel_rounded, right: true),
              ],
            ),

            // ── Stepper (editing only) ────────────────────────────
            if (_isEditing) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Absent Days',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                        Text('Max: $_workingDays days',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                    Row(
                      children: [
                        _stepBtn(
                          icon: Icons.remove_rounded,
                          color: Colors.red.shade400,
                          enabled: absent > 0,
                          onTap: () => _updateAbsentDays(student.id, absent - 1),
                        ),
                        SizedBox(
                          width: 52,
                          child: Center(
                            child: Text('$absent',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E))),
                          ),
                        ),
                        _stepBtn(
                          icon: Icons.add_rounded,
                          color: AppTheme.primaryColor,
                          enabled: absent < _workingDays,
                          onTap: () => _updateAbsentDays(student.id, absent + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {bool subtle = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: subtle ? Colors.grey.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: subtle ? Colors.grey.shade400 : Colors.grey.shade600)),
    );
  }

  Widget _dayStat(String label, int value, Color color, IconData icon,
      {bool right = false}) {
    return SizedBox(
      width: 64,
      child: Column(
        crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: right
                ? [
                    Text('$value',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(width: 4),
                    Icon(icon, size: 15, color: color),
                  ]
                : [
                    Icon(icon, size: 15, color: color),
                    const SizedBox(width: 4),
                    Text('$value',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ],
          ),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? color.withOpacity(0.1) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 20, color: enabled ? color : Colors.grey.shade400),
        ),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────

  Widget _buildFAB() {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveAttendance,
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.save_alt_rounded, color: Colors.white),
        label: Text(
          _isSaving ? 'Saving…' : 'Save Attendance',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  // ── Empty / No-results states ─────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.people_outline, size: 40, color: Colors.grey[350]),
          ),
          const SizedBox(height: 16),
          Text('No students in this class',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Enrolled students will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _noResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No match for "$_searchQuery"',
              style: TextStyle(fontSize: 15, color: Colors.grey[500])),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _searchQuery = ''),
            child: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}
