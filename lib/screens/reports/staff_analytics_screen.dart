import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/services/analytics_service.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:school_management/services/class_service.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/widgets/common/loading_widget.dart';

class StaffAnalyticsScreen extends StatefulWidget {
  final String? initialExamId;
  final String? initialClassId;

  const StaffAnalyticsScreen({
    super.key,
    this.initialExamId,
    this.initialClassId,
  });

  @override
  State<StaffAnalyticsScreen> createState() => _StaffAnalyticsScreenState();
}

class _StaffAnalyticsScreenState extends State<StaffAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  final AnalyticsService _analyticsService = AnalyticsService();
  final ExamService _examService = ExamService();
  final ClassService _classService = ClassService();

  List<ExamModel> _exams = [];
  List<ClassModel> _classes = [];

  // Exam Analytics state
  String? _selectedExamId;
  String? _selectedClassId;
  bool _loadingFilters = true;
  bool _loadingData = false;
  String? _errorMessage;
  Map<String, dynamic>? _analyticsData;

  // Student Rank List state
  String _rankMode = 'TE'; // 'TE' (excl. WE/PE/Drawing) or 'TE_CE'
  String _rankSearchQuery = '';
  String _rankGradeFilter = 'ALL';
  String _rankMarkRangePreset = 'ALL'; // 'ALL', '<=150', '100-500', '150-300', '300-500', '>=450', 'CUSTOM'
  final TextEditingController _rankMinMarkController = TextEditingController();
  final TextEditingController _rankMaxMarkController = TextEditingController();
  int _rankDisplayLimit = 25;
  bool _isRankExporting = false;
  final TextEditingController _rankSearchController = TextEditingController();

  // Attendance Analytics state
  String? _selectedAttendanceClassId;
  int? _selectedAttendanceMonth; // null = all months
  bool _loadingAttendanceData = false;
  String? _attendanceErrorMessage;
  Map<String, dynamic>? _attendanceData;

  static const List<Map<String, dynamic>> _months = [
    {'name': 'All Months (Full Year)', 'value': null},
    {'name': 'June', 'value': 6},
    {'name': 'July', 'value': 7},
    {'name': 'August', 'value': 8},
    {'name': 'September', 'value': 9},
    {'name': 'October', 'value': 10},
    {'name': 'November', 'value': 11},
    {'name': 'December', 'value': 12},
    {'name': 'January', 'value': 1},
    {'name': 'February', 'value': 2},
    {'name': 'March', 'value': 3},
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      if (_mainTabController.indexIsChanging) return;
      if (_mainTabController.index == 1 && _attendanceData == null && !_loadingAttendanceData) {
        _fetchAttendanceAnalytics();
      }
    });

    _selectedExamId = widget.initialExamId;
    _selectedClassId = widget.initialClassId;
    _selectedAttendanceClassId = widget.initialClassId;
    _loadFilters();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _rankSearchController.dispose();
    _rankMinMarkController.dispose();
    _rankMaxMarkController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _loadingFilters = true;
      _errorMessage = null;
    });

    try {
      List<ExamModel> examsList = [];
      try {
        final examRes = await _examService.getExams(limit: 100, isStaff: true);
        if (examRes['data'] != null && examRes['data'] is List) {
          examsList = (examRes['data'] as List).map((e) => ExamModel.fromJson(e)).toList();
        }
      } catch (_) {}

      // Fallback to general exams list if staff exams list is empty
      if (examsList.isEmpty) {
        final allExamsRes = await _examService.getExams(limit: 100, isStaff: false);
        if (allExamsRes['data'] != null && allExamsRes['data'] is List) {
          examsList = (allExamsRes['data'] as List).map((e) => ExamModel.fromJson(e)).toList();
        }
      }

      List<ClassModel> classesList = [];
      final classRes = await _classService.getClasses(limit: 100);
      if (classRes['data'] != null && classRes['data'] is List) {
        classesList = (classRes['data'] as List).map((c) => ClassModel.fromJson(c)).toList();
      }

      if (!mounted) return;
      final store = StoreProvider.of<AppState>(context, listen: false);
      final user = store.state.auth.user;
      final isAdmin = user?.role == 'admin' || user?.role == 'superadmin';

      if (!isAdmin) {
        final teacherClasses = store.state.classes.teacherClasses;
        if (teacherClasses.isNotEmpty) {
          classesList = classesList.where((c) {
            return teacherClasses.any((tc) => tc.id == c.id);
          }).toList();
        }
      }

      // Deduplicate classes by ID
      final uniqueClassIds = <String>{};
      classesList = classesList.where((c) => uniqueClassIds.add(c.id)).toList();

      setState(() {
        _exams = examsList;
        _classes = classesList;
        _loadingFilters = false;

        if (_selectedExamId == null || !_exams.any((e) => e.id == _selectedExamId)) {
          _selectedExamId = _exams.isNotEmpty ? _exams.first.id : null;
        }

        if (!isAdmin && _classes.isNotEmpty && (_selectedClassId == null || !_classes.any((c) => c.id == _selectedClassId))) {
          _selectedClassId = _classes.first.id;
          _selectedAttendanceClassId = _classes.first.id;
        }
      });

      if (_selectedExamId != null) {
        _fetchAnalytics();
      }
      _fetchAttendanceAnalytics();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load filters: $e';
        _loadingFilters = false;
      });
    }
  }

  Future<void> _fetchAnalytics() async {
    if (_selectedExamId == null || _selectedExamId!.isEmpty) return;

    setState(() {
      _loadingData = true;
      _errorMessage = null;
    });

    try {
      final res = await _analyticsService.getGradeAnalysis(
        examId: _selectedExamId!,
        classId: _selectedClassId,
      );

      setState(() {
        _analyticsData = res['data'] ?? res;
        _loadingData = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch analytics: $e';
        _loadingData = false;
      });
    }
  }

  Future<void> _fetchAttendanceAnalytics() async {
    setState(() {
      _loadingAttendanceData = true;
      _attendanceErrorMessage = null;
    });

    try {
      final res = await _analyticsService.getAttendanceAnalytics(
        classId: _selectedAttendanceClassId,
        month: _selectedAttendanceMonth,
      );

      setState(() {
        _attendanceData = res['data'] ?? res;
        _loadingAttendanceData = false;
      });
    } catch (e) {
      setState(() {
        _attendanceErrorMessage = 'Failed to fetch attendance analytics: $e';
        _loadingAttendanceData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              if (_mainTabController.index == 0) {
                if (_selectedExamId != null) _fetchAnalytics();
              } else {
                _fetchAttendanceAnalytics();
              }
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _mainTabController,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF059669),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics_rounded, size: 18),
                  text: 'Exam Analytics',
                ),
                Tab(
                  icon: Icon(Icons.co_present_rounded, size: 18),
                  text: 'Attendance Analytics',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loadingFilters
          ? const Center(child: LoadingWidget())
          : TabBarView(
              controller: _mainTabController,
              children: [
                _buildExamAnalyticsTab(),
                _buildAttendanceAnalyticsTab(),
              ],
            ),
    );
  }

  // ===========================================================================
  // EXAM ANALYTICS TAB
  // ===========================================================================

  Widget _buildExamAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExamFilterCard(),
            const SizedBox(height: 16),

            if (_errorMessage != null) ...[
              _buildErrorBanner(_errorMessage!),
              const SizedBox(height: 16),
            ],

            if (_loadingData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: LoadingWidget()),
              )
            else if (_analyticsData != null) ...[
              _buildSummaryKpiGrid(),
              const SizedBox(height: 16),
              _buildOverallGradeDistributionCard(),
              const SizedBox(height: 16),
              _buildSubjectWiseGradeDistributionCard(),
              const SizedBox(height: 16),
              _buildStudentBreakdownTabs(),
              const SizedBox(height: 16),
              _buildStudentRankListCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExamFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Exam & Class',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          // Exam Dropdown
          DropdownButtonFormField<String>(
            value: _selectedExamId,
            decoration: InputDecoration(
              labelText: 'Exam *',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _exams.map((exam) {
              return DropdownMenuItem<String>(
                value: exam.id,
                child: Text(
                  (exam.displayName != null && exam.displayName!.isNotEmpty) ? exam.displayName! : exam.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedExamId = val);
                _fetchAnalytics();
              }
            },
          ),
          const SizedBox(height: 10),

          // Class Dropdown
          DropdownButtonFormField<String>(
            value: _selectedClassId,
            decoration: InputDecoration(
              labelText: 'Filter by Class (Optional)',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Classes', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              ...{for (var c in _classes) c.id: c}.values.map((cls) {
                return DropdownMenuItem<String>(
                  value: cls.id,
                  child: Text(
                    cls.displayName ?? cls.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }),
            ],
            onChanged: (val) {
              setState(() => _selectedClassId = val);
              _fetchAnalytics();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpiGrid() {
    final summary = _analyticsData?['summary'] ?? {};
    final totalStudents = _analyticsData?['totalStudents'] ?? 0;
    final fullAPlus = summary['fullAPlus'] ?? 0;
    final nearFullAPlus = summary['nineAPlus'] ?? 0;
    final passPercentage = (summary['passPercentage'] as num?)?.toDouble() ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _kpiTile('Full A+ Students', '$fullAPlus', Icons.workspace_premium_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
        _kpiTile('Total Students', '$totalStudents', Icons.school_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
        _kpiTile('Pass Percentage', '${passPercentage.toStringAsFixed(1)}%', Icons.analytics_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
        _kpiTile('Near Full A+', '$nearFullAPlus', Icons.stars_rounded, const Color(0xFF9333EA), const Color(0xFFF3E8FF)),
      ],
    );
  }

  Widget _buildOverallGradeDistributionCard() {
    final Map<String, dynamic> rawDist = _analyticsData?['gradeDistribution'] ?? {};
    final totalStudents = (_analyticsData?['totalStudents'] as num?)?.toInt() ?? 1;

    if (rawDist.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Grade Distribution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Student breakdown by overall grade',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          ...rawDist.entries.map((entry) {
            final grade = entry.key;
            final count = (entry.value as num?)?.toInt() ?? 0;
            final pct = totalStudents > 0 ? (count / totalStudents) * 100 : 0.0;
            final color = _getGradeColor(grade);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grade $grade', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('$count students (${pct.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectWiseGradeDistributionCard() {
    final Map<String, dynamic> subjectDist = _analyticsData?['subjectWiseGradeDistribution'] ?? {};
    if (subjectDist.isEmpty) return const SizedBox();

    final gradesList = ['A+', 'A', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'E', 'AB'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Subject-wise Grade List',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              Icon(Icons.table_chart_rounded, color: Color(0xFF059669), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Grade breakdown count for every subject',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowHeight: 44,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
              columns: [
                const DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ...gradesList.map((g) => DataColumn(
                      numeric: true,
                      label: Text(g, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _getGradeColor(g))),
                    )),
                const DataColumn(numeric: true, label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: subjectDist.entries.map((e) {
                final subjName = e.key;
                final Map<String, dynamic> counts = Map<String, dynamic>.from(e.value ?? {});
                final total = counts['total'] ?? 0;

                return DataRow(
                  cells: [
                    DataCell(Text(subjName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    ...gradesList.map((g) {
                      final c = counts[g] ?? 0;
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c > 0 ? _getGradeColor(g).withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$c',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: c > 0 ? FontWeight.bold : FontWeight.normal,
                              color: c > 0 ? _getGradeColor(g) : Colors.grey[400],
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(Text('$total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentBreakdownTabs() {
    final analysis = _analyticsData?['analysis'] ?? {};
    final List fullAPlusList = analysis['fullAPlus'] ?? [];
    final List nineAPlusList = analysis['nineAPlus'] ?? [];
    final List eightAPlusList = analysis['eightAPlus'] ?? [];
    final List sevenAPlusList = analysis['sevenAPlus'] ?? [];

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              indicatorColor: Colors.transparent,
              labelColor: const Color(0xFF059669),
              unselectedLabelColor: Colors.grey[700],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              isScrollable: true,
              tabs: [
                Tab(text: 'Full A+ (${fullAPlusList.length})'),
                Tab(text: '9 A+ (${nineAPlusList.length})'),
                Tab(text: '8 A+ (${eightAPlusList.length})'),
                Tab(text: '7 A+ (${sevenAPlusList.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _buildStudentList(fullAPlusList, categoryLabel: 'Full A+'),
                _buildStudentList(nineAPlusList, categoryLabel: '9 A+'),
                _buildStudentList(eightAPlusList, categoryLabel: '8 A+'),
                _buildStudentList(sevenAPlusList, categoryLabel: '7 A+'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List list, {required String categoryLabel}) {
    final isFullA = categoryLabel == 'Full A+';
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No $categoryLabel students',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final name = item['studentName'] ?? item['fullName'] ?? 'Student';
        final roll = item['rollNumber'] ?? '-';
        final cls = item['className'] ?? '-';
        final missingSub = item['missingSubject'];
        final missingGrade = item['missingSubjectGrade'];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isFullA ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                child: Text(
                  '$roll',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isFullA ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Class: $cls', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (!isFullA && missingSub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Missed A+ in $missingSub ($missingGrade)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFullA ? const Color(0xFF059669) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // STUDENT RANK LIST CARD
  // ===========================================================================

  List get _filteredRankStudents {
    final list = (_analyticsData?['studentResults'] as List? ?? []).toList();

    // Sort by selected rankMode
    list.sort((a, b) {
      if (_rankMode == 'TE') {
        final aR = (a['teRank'] as num?)?.toInt() ?? 999999;
        final bR = (b['teRank'] as num?)?.toInt() ?? 999999;
        if (aR != bR) return aR.compareTo(bR);
        final aPct = (a['rankTePercentage'] as num?)?.toDouble() ?? 0.0;
        final bPct = (b['rankTePercentage'] as num?)?.toDouble() ?? 0.0;
        return bPct.compareTo(aPct);
      } else {
        final aR = (a['teCeRank'] as num?)?.toInt() ?? (a['rank'] as num?)?.toInt() ?? 999999;
        final bR = (b['teCeRank'] as num?)?.toInt() ?? (b['rank'] as num?)?.toInt() ?? 999999;
        if (aR != bR) return aR.compareTo(bR);
        final aPct = (a['rankTotalPercentage'] as num?)?.toDouble() ?? (a['percentage'] as num?)?.toDouble() ?? 0.0;
        final bPct = (b['rankTotalPercentage'] as num?)?.toDouble() ?? (b['percentage'] as num?)?.toDouble() ?? 0.0;
        return bPct.compareTo(aPct);
      }
    });

    return list.where((student) {
      final name = (student['studentName'] ?? student['fullName'] ?? student['name'] ?? '').toString().toLowerCase();
      final roll = (student['rollNumber'] ?? student['rollNo'] ?? '').toString().toLowerCase();
      final adm = (student['admissionNumber'] ?? student['studentCode'] ?? student['admissionNo'] ?? '').toString().toLowerCase();
      final cls = (student['className'] ?? '').toString().toLowerCase();

      // Search query filter
      if (_rankSearchQuery.trim().isNotEmpty) {
        final q = _rankSearchQuery.trim().toLowerCase();
        if (!name.contains(q) && !roll.contains(q) && !adm.contains(q) && !cls.contains(q)) {
          return false;
        }
      }

      // Grade filter
      if (_rankGradeFilter != 'ALL') {
        final tePct = (student['rankTePercentage'] as num?)?.toDouble() ?? 0.0;
        final totalPct = (student['rankTotalPercentage'] as num?)?.toDouble() ?? (student['percentage'] as num?)?.toDouble() ?? 0.0;
        final gr = _getGradeFromPercentage(_rankMode == 'TE' ? tePct : totalPct);
        if (gr != _rankGradeFilter) {
          return false;
        }
      }

      // Mark range filter
      final teMarks = (student['rankTeTotal'] ?? student['totalTheoryMarks'] ?? 0) as num;
      final totalMarks = (student['rankTotalObtained'] ?? student['totalMarks'] ?? 0) as num;
      final activeMarks = _rankMode == 'TE' ? teMarks : totalMarks;

      if (_rankMarkRangePreset == '<=150' && activeMarks > 150) return false;
      if (_rankMarkRangePreset == '100-500' && (activeMarks < 100 || activeMarks > 500)) return false;
      if (_rankMarkRangePreset == '150-300' && (activeMarks < 150 || activeMarks > 300)) return false;
      if (_rankMarkRangePreset == '300-500' && (activeMarks < 300 || activeMarks > 500)) return false;
      if (_rankMarkRangePreset == '>=450' && activeMarks < 450) return false;
      if (_rankMarkRangePreset == 'CUSTOM') {
        final minTxt = _rankMinMarkController.text.trim();
        final maxTxt = _rankMaxMarkController.text.trim();
        if (minTxt.isNotEmpty) {
          final minVal = num.tryParse(minTxt);
          if (minVal != null && activeMarks < minVal) return false;
        }
        if (maxTxt.isNotEmpty) {
          final maxVal = num.tryParse(maxTxt);
          if (maxVal != null && activeMarks > maxVal) return false;
        }
      }

      return true;
    }).toList();
  }

  String _getGradeFromPercentage(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C+';
    if (pct >= 40) return 'C';
    if (pct >= 30) return 'D+';
    if (pct >= 20) return 'D';
    return 'E';
  }

  Future<void> _exportRankList({required bool isExcel}) async {
    final examId = _selectedExamId;
    final classId = _selectedClassId;
    if (examId == null || examId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an exam first'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specific class to export the rank list'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isRankExporting = true);
    try {
      final token = ApiService().getToken();
      final effectiveMode = isExcel ? 'both' : (_rankMode == 'TE' ? 'te' : 'total');
      final endpoint = isExcel
          ? '/pdf/report-card/class-marks/excel/$classId/$examId?mode=$effectiveMode&sortBy=rank'
          : '/pdf/report-card/class-marks/download/$classId/$examId?mode=$effectiveMode&sortBy=rank';

      final response = await Dio().get<List<int>>(
        '${ApiConfig.baseUrl}$endpoint',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw 'Empty file response received';
      }

      final bytes = Uint8List.fromList(response.data!);
      final ext = isExcel ? 'xlsx' : 'pdf';
      final fileName = 'Rank_List_${classId}_$examId.$ext';

      if (isExcel) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Student Rank List Excel (All Subjects CE & TE)');
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isRankExporting = false);
    }
  }

  Widget _buildStudentRankListCard() {
    final allStudents = (_analyticsData?['studentResults'] as List? ?? []);
    if (allStudents.isEmpty) return const SizedBox.shrink();

    final filtered = _filteredRankStudents;
    final isTE = _rankMode == 'TE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isTE
                        ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                        : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isTE ? const Color(0xFF2563EB) : const Color(0xFF0D9488)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Student Rank List',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isTE ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isTE ? const Color(0xFFBFDBFE) : const Color(0xFF99F6E4),
                            ),
                          ),
                          child: Text(
                            isTE ? 'TE Rank' : 'TE + CE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isTE ? const Color(0xFF1D4ED8) : const Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTE
                          ? 'Sorted by TE marks (excl. WE / PE / Drawing)'
                          : 'Sorted by TE + CE marks (excl. WE / PE / Drawing)',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rank Mode Selector Pills
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _rankMode = 'TE'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isTE ? const Color(0xFF2563EB) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isTE
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '🎯 TE Only Rank (Default)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isTE ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _rankMode = 'TE_CE'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !isTE ? const Color(0xFF0D9488) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !isTE
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0D9488).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '🏅 TE + CE Rank',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !isTE ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search & Filter Row
          Row(
            children: [
              // Search input
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _rankSearchController,
                    onChanged: (v) => setState(() => _rankSearchQuery = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search student, roll, adm...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: _rankSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _rankSearchController.clear();
                                setState(() => _rankSearchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Grade filter dropdown
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _rankGradeFilter,
                    icon: const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    onChanged: (v) => setState(() => _rankGradeFilter = v ?? 'ALL'),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Grades')),
                      DropdownMenuItem(value: 'A+', child: Text('A+ Only')),
                      DropdownMenuItem(value: 'A', child: Text('A Only')),
                      DropdownMenuItem(value: 'B+', child: Text('B+ Only')),
                      DropdownMenuItem(value: 'B', child: Text('B Only')),
                      DropdownMenuItem(value: 'C+', child: Text('C+ Only')),
                      DropdownMenuItem(value: 'C', child: Text('C Only')),
                      DropdownMenuItem(value: 'D+', child: Text('D+ Only')),
                      DropdownMenuItem(value: 'D', child: Text('D Only')),
                      DropdownMenuItem(value: 'E', child: Text('E Only')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mark Range Filter Row
          Row(
            children: [
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Marks: ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _rankMarkRangePreset,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                        onChanged: (v) => setState(() => _rankMarkRangePreset = v ?? 'ALL'),
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('All Marks')),
                          DropdownMenuItem(value: '<=150', child: Text('≤ 150 Marks')),
                          DropdownMenuItem(value: '100-500', child: Text('100 - 500 Marks')),
                          DropdownMenuItem(value: '150-300', child: Text('150 - 300 Marks')),
                          DropdownMenuItem(value: '300-500', child: Text('300 - 500 Marks')),
                          DropdownMenuItem(value: '>=450', child: Text('≥ 450 Marks')),
                          DropdownMenuItem(value: 'CUSTOM', child: Text('Custom Range...')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_rankMarkRangePreset == 'CUSTOM') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _rankMinMarkController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Min',
                        hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ),
                Expanded(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _rankMaxMarkController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Max',
                        hintStyle: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Count chips & Export buttons bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display limit selector
              Row(
                children: [
                  const Text('Show: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  ...[10, 25, 50, 999999].map((cnt) {
                    final isSel = _rankDisplayLimit == cnt;
                    final label = cnt == 999999 ? 'All' : '$cnt';
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: InkWell(
                        onTap: () => setState(() => _rankDisplayLimit = cnt),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              // Export Buttons (Excel & PDF)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isRankExporting ? null : () => _exportRankList(isExcel: true),
                    icon: const Icon(Icons.table_view_rounded, size: 14, color: Color(0xFF059669)),
                    label: const Text('Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 30),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _isRankExporting ? null : () => _exportRankList(isExcel: false),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFDC2626)),
                    label: const Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 30),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      backgroundColor: const Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Count summary indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.take(_rankDisplayLimit).length} of ${filtered.length} students',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              if (_isRankExporting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Students List
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No students match the selected filter', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.take(_rankDisplayLimit).length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final student = filtered[idx];
                return _buildRankStudentCard(student, idx);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRankStudentCard(dynamic student, int index) {
    final isTE = _rankMode == 'TE';
    final teRank = (student['teRank'] as num?)?.toInt() ?? (index + 1);
    final teCeRank = (student['teCeRank'] as num?)?.toInt() ?? (student['rank'] as num?)?.toInt() ?? (index + 1);
    final rank = isTE ? teRank : teCeRank;

    final name = (student['studentName'] ?? student['fullName'] ?? student['name'] ?? '-').toString();
    final roll = (student['rollNumber'] ?? student['rollNo'] ?? '-').toString();
    final adm = (student['admissionNumber'] ?? student['studentCode'] ?? student['admissionNo'] ?? '-').toString();
    final cls = (student['className'] ?? '').toString();

    final teMarks = student['rankTeTotal'] ?? student['totalTheoryMarks'] ?? 0;
    final teMax = student['rankTeMax'] ?? 0;
    final tePct = (student['rankTePercentage'] as num?)?.toDouble() ?? 0.0;

    final ceMarks = student['rankCeTotal'] ?? (
      student['rankTotalObtained'] != null && student['rankTeTotal'] != null
        ? (student['rankTotalObtained'] as num).toInt() - (student['rankTeTotal'] as num).toInt()
        : (student['totalCeMarks'] ?? 0)
    );

    final totalMarks = student['rankTotalObtained'] ?? student['totalMarks'] ?? 0;
    final totalMax = student['rankTotalMax'] ?? student['totalMaxMarks'] ?? 0;
    final totalPct = (student['rankTotalPercentage'] as num?)?.toDouble() ?? (student['percentage'] as num?)?.toDouble() ?? 0.0;

    final activePct = isTE ? tePct : totalPct;
    final activeGrade = _getGradeFromPercentage(activePct);
    final gradeColor = _getGradeColor(activeGrade);

    final aplus = student['academicAplusCount'] ?? student['aplusCount'] ?? 0;
    final totalSubs = student['academicTotalSubjects'] ?? student['totalSubjects'] ?? 0;
    final isPassed = activePct >= 40.0;

    // Rank badge decoration
    Color rankBg;
    Color rankFg;
    IconData? rankIcon;

    if (rank == 1) {
      rankBg = const Color(0xFFFEF3C7);
      rankFg = const Color(0xFFB45309);
      rankIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      rankBg = const Color(0xFFF1F5F9);
      rankFg = const Color(0xFF475569);
      rankIcon = Icons.military_tech_rounded;
    } else if (rank == 3) {
      rankBg = const Color(0xFFFFEDD5);
      rankFg = const Color(0xFFC2410C);
      rankIcon = Icons.workspace_premium_rounded;
    } else {
      rankBg = const Color(0xFFF8FAFC);
      rankFg = const Color(0xFF64748B);
      rankIcon = null;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank <= 3
              ? (rank == 1 ? const Color(0xFFFDE68A) : (rank == 2 ? const Color(0xFFCBD5E1) : const Color(0xFFFED7AA)))
              : const Color(0xFFE2E8F0),
          width: rank <= 3 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rankBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rankFg.withOpacity(0.3)),
                ),
                child: Center(
                  child: rankIcon != null
                      ? Icon(rankIcon, size: 20, color: rankFg)
                      : Text(
                          '#$rank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: rankFg,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),

              // Name & sub-info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rank <= 3) ...[
                          const SizedBox(width: 4),
                          Text(
                            '#$rank',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rankFg),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Roll: $roll  •  Adm: $adm${cls.isNotEmpty ? '  •  $cls' : ''}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Grade badge & Pass/Fail status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gradeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      activeGrade,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPassed ? 'Passed' : 'Failed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Marks strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF2F6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _rankMetric('TE Score', '$teMarks${teMax > 0 ? '/$teMax' : ''}', '${tePct.toStringAsFixed(1)}%'),
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                _rankMetric('CE Marks', '$ceMarks', 'Internal'),
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                _rankMetric('Total', '$totalMarks${totalMax > 0 ? '/$totalMax' : ''}', '${totalPct.toStringAsFixed(1)}%'),
                Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
                _rankMetric('A+ Count', '$aplus${totalSubs > 0 ? '/$totalSubs' : ''}', 'Academic'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankMetric(String label, String value, String sub) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        Text(sub, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
      ],
    );
  }

  // ===========================================================================
  // ATTENDANCE ANALYTICS TAB
  // ===========================================================================

  Widget _buildAttendanceAnalyticsTab() {
    return RefreshIndicator(
      onRefresh: _fetchAttendanceAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceFilterCard(),
            const SizedBox(height: 16),

            if (_attendanceErrorMessage != null) ...[
              _buildErrorBanner(_attendanceErrorMessage!),
              const SizedBox(height: 16),
            ],

            if (_loadingAttendanceData)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: LoadingWidget()),
              )
            else if (_attendanceData != null) ...[
              _buildAttendanceKpiGrid(),
              const SizedBox(height: 16),
              _buildAttendanceDistributionCard(),
              const SizedBox(height: 16),
              if ((_attendanceData!['monthlyTrends'] as List?)?.isNotEmpty ?? false) ...[
                _buildAttendanceMonthlyTrendsCard(),
                const SizedBox(height: 16),
              ],
              if ((_attendanceData!['classWiseComparison'] as List?)?.isNotEmpty ?? false) ...[
                _buildAttendanceClassComparisonCard(),
                const SizedBox(height: 16),
              ],
              _buildAttendanceBreakdownTabs(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Attendance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          // Class Dropdown
          DropdownButtonFormField<String>(
            value: _selectedAttendanceClassId,
            decoration: InputDecoration(
              labelText: 'Filter by Class',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Classes', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              ...{for (var c in _classes) c.id: c}.values.map((cls) {
                return DropdownMenuItem<String>(
                  value: cls.id,
                  child: Text(
                    cls.displayName ?? cls.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }),
            ],
            onChanged: (val) {
              setState(() => _selectedAttendanceClassId = val);
              _fetchAttendanceAnalytics();
            },
          ),
          const SizedBox(height: 10),

          // Month Dropdown
          DropdownButtonFormField<int?>(
            value: _selectedAttendanceMonth,
            decoration: InputDecoration(
              labelText: 'Month',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _months.map((m) {
              return DropdownMenuItem<int?>(
                value: m['value'] as int?,
                child: Text(
                  m['name'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedAttendanceMonth = val);
              _fetchAttendanceAnalytics();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceKpiGrid() {
    final summary = _attendanceData?['summary'] ?? {};
    final avgPct = (summary['averagePercentage'] as num?)?.toDouble() ?? 0.0;
    final totalStudents = summary['totalStudents'] ?? 0;
    final goodStanding = summary['goodStandingCount'] ?? 0;
    final goodPct = (summary['goodStandingPercentage'] as num?)?.toDouble() ?? 0.0;
    final needsAttention = summary['needsAttentionCount'] ?? 0;
    final needsAttentionPct = (summary['needsAttentionPercentage'] as num?)?.toDouble() ?? 0.0;
    final totalWorkingDays = summary['totalWorkingDays'] ?? 0;

    Color avgColor = const Color(0xFF059669);
    Color avgBg = const Color(0xFFECFDF5);
    if (avgPct < 75.0) {
      avgColor = const Color(0xFFDC2626);
      avgBg = const Color(0xFFFEF2F2);
    } else if (avgPct < 85.0) {
      avgColor = const Color(0xFFD97706);
      avgBg = const Color(0xFFFFFBEB);
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: [
        _kpiTile(
          'Average Attendance',
          '${avgPct.toStringAsFixed(1)}%',
          Icons.verified_rounded,
          avgColor,
          avgBg,
        ),
        _kpiTile(
          'Total Students ($totalWorkingDays Days)',
          '$totalStudents',
          Icons.groups_rounded,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        ),
        _kpiTile(
          'Good Standing (≥75%)',
          '$goodStanding (${goodPct.toStringAsFixed(0)}%)',
          Icons.check_circle_rounded,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
        ),
        _kpiTile(
          'Needs Attention (<75%)',
          '$needsAttention (${needsAttentionPct.toStringAsFixed(0)}%)',
          Icons.warning_amber_rounded,
          const Color(0xFFDC2626),
          const Color(0xFFFEF2F2),
        ),
      ],
    );
  }

  Widget _buildAttendanceDistributionCard() {
    final dist = _attendanceData?['distribution'] ?? {};
    final summary = _attendanceData?['summary'] ?? {};
    final totalStudents = (summary['totalStudents'] as num?)?.toInt() ?? 1;

    final categories = [
      {
        'key': 'excellent',
        'title': 'Excellent (≥90%)',
        'color': const Color(0xFF059669),
        'icon': Icons.sentiment_very_satisfied_rounded,
      },
      {
        'key': 'good',
        'title': 'Good (75% - 89%)',
        'color': const Color(0xFF2563EB),
        'icon': Icons.sentiment_satisfied_rounded,
      },
      {
        'key': 'average',
        'title': 'Average (60% - 74%)',
        'color': const Color(0xFFD97706),
        'icon': Icons.sentiment_neutral_rounded,
      },
      {
        'key': 'critical',
        'title': 'Critical (<60%)',
        'color': const Color(0xFFDC2626),
        'icon': Icons.warning_amber_rounded,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Attendance Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF059669), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Categorized by attendance percentage standing',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          ...categories.map((cat) {
            final catData = dist[cat['key']] ?? {};
            final count = (catData['count'] as num?)?.toInt() ?? 0;
            final pct = totalStudents > 0 ? (count / totalStudents) * 100 : 0.0;
            final color = cat['color'] as Color;
            final title = cat['title'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(cat['icon'] as IconData, size: 16, color: color),
                          const SizedBox(width: 6),
                          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '$count students (${pct.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalStudents > 0 ? count / totalStudents : 0.0,
                      minHeight: 8,
                      backgroundColor: color.withOpacity(0.12),
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceMonthlyTrendsCard() {
    final List trends = _attendanceData?['monthlyTrends'] ?? [];
    if (trends.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Monthly Attendance Trends',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              Icon(Icons.trending_up_rounded, color: Color(0xFF2563EB), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Month-by-month average attendance across the academic year',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          ...trends.map((t) {
            final monthName = t['monthName'] ?? 'Month ${t['month']}';
            final pct = (t['averagePercentage'] as num?)?.toDouble() ?? 0.0;
            final days = t['totalWorkingDays'] ?? 0;

            Color barColor = const Color(0xFF059669);
            if (pct < 75.0) {
              barColor = const Color(0xFFDC2626);
            } else if (pct < 85.0) {
              barColor = const Color(0xFFD97706);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$monthName ($days days)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: barColor)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      color: barColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAttendanceClassComparisonCard() {
    final List classes = _attendanceData?['classWiseComparison'] ?? [];
    if (classes.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Class-Wise Comparison',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
              Icon(Icons.leaderboard_rounded, color: Color(0xFFD97706), size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Attendance rate ranked by class',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(2.0),
                2: FlexColumnWidth(1.8),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Text('Avg %', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Text('Students', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Text('Good', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                      child: Text('Alert', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                    ),
                  ],
                ),
                ...classes.map((c) {
                  final name = c['className'] ?? '-';
                  final avg = (c['averagePercentage'] as num?)?.toDouble() ?? 0.0;
                  final total = c['totalStudents'] ?? 0;
                  final good = c['goodStandingCount'] ?? 0;
                  final alert = c['criticalCount'] ?? 0;

                  Color pctColor = const Color(0xFF059669);
                  if (avg < 75) {
                    pctColor = const Color(0xFFDC2626);
                  } else if (avg < 85) {
                    pctColor = const Color(0xFFD97706);
                  }

                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Text(
                          '${avg.toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: pctColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Text(
                          '$total',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Text(
                          '$good',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                        child: Text(
                          '$alert',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: alert > 0 ? FontWeight.bold : FontWeight.normal,
                            color: alert > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceBreakdownTabs() {
    final breakdown = _attendanceData?['breakdown'] ?? {};
    final List needsAttention = breakdown['needsAttention'] ?? [];
    final List perfectAttendance = breakdown['perfectAttendance'] ?? [];
    final List allStudents = breakdown['allStudents'] ?? [];

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const TabBar(
              indicatorColor: Colors.transparent,
              labelColor: Color(0xFF059669),
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(text: 'Needs Attention'),
                Tab(text: '100% Attendance'),
                Tab(text: 'All Students'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: TabBarView(
              children: [
                _buildAttendanceStudentList(needsAttention, type: 'attention'),
                _buildAttendanceStudentList(perfectAttendance, type: 'perfect'),
                _buildAttendanceStudentList(allStudents, type: 'all'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStudentList(List list, {required String type}) {
    if (list.isEmpty) {
      String emptyText = 'No students found';
      if (type == 'attention') emptyText = 'Great news! No students below 75% attendance.';
      if (type == 'perfect') emptyText = 'No students with 100% attendance in this period.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final name = item['studentName'] ?? 'Student';
        final roll = item['rollNumber'] ?? '-';
        final cls = item['className'] ?? '-';
        final present = item['presentDays'] ?? 0;
        final totalDays = item['totalWorkingDays'] ?? 0;
        final pct = (item['percentage'] as num?)?.toDouble() ?? 0.0;

        Color badgeColor = const Color(0xFF059669);
        Color badgeBg = const Color(0xFFECFDF5);
        if (pct < 60) {
          badgeColor = const Color(0xFFDC2626);
          badgeBg = const Color(0xFFFEF2F2);
        } else if (pct < 75) {
          badgeColor = const Color(0xFFD97706);
          badgeBg = const Color(0xFFFFFBEB);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: badgeBg,
                child: Text(
                  '$roll',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Class: $cls  •  $present/$totalDays days present',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type == 'perfect') ...[
                      const Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // COMMON HELPER WIDGETS
  // ===========================================================================

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
      ),
    );
  }

  Widget _kpiTile(String title, String value, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color.withOpacity(0.9)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
        return const Color(0xFF059669);
      case 'A':
        return const Color(0xFF16A34A);
      case 'B+':
        return const Color(0xFF2563EB);
      case 'B':
        return const Color(0xFF0891B2);
      case 'C+':
        return const Color(0xFFD97706);
      case 'C':
        return const Color(0xFFEA580C);
      case 'D+':
        return const Color(0xFFB45309);
      case 'D':
        return const Color(0xFFE11D48);
      case 'E':
        return const Color(0xFF64748B);
      case 'AB':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }
}
