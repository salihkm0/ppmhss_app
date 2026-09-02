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

class _StaffAnalyticsScreenState extends State<StaffAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ExamService _examService = ExamService();
  final ClassService _classService = ClassService();

  List<ExamModel> _exams = [];
  List<ClassModel> _classes = [];

  String? _selectedExamId;
  String? _selectedClassId;

  bool _loadingFilters = true;
  bool _loadingData = false;
  String? _errorMessage;

  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _selectedExamId = widget.initialExamId;
    _selectedClassId = widget.initialClassId;
    _loadFilters();
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
        }
      });

      if (_selectedExamId != null) {
        _fetchAnalytics();
      }
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _selectedExamId != null ? _fetchAnalytics : null,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _loadingFilters
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Filters Card ───────────────────────────────────────────
                    _buildFilterCard(),
                    const SizedBox(height: 16),

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_loadingData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(child: LoadingWidget()),
                      )
                    else if (_analyticsData != null) ...[
                      // ── KPI Cards ───────────────────────────────────────────
                      _buildSummaryKpiGrid(),
                      const SizedBox(height: 16),

                      // ── Overall Grade Distribution ─────────────────────────
                      _buildOverallGradeDistributionCard(),
                      const SizedBox(height: 16),

                      // ── Subject-Wise Grade Distribution ────────────────────
                      _buildSubjectWiseGradeDistributionCard(),
                      const SizedBox(height: 16),

                      // ── Full A+ & Near Full A+ Lists ───────────────────────
                      _buildStudentBreakdownTabs(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterCard() {
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
            'Select Filters',
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
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
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

          // Scrollable Matrix Table
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

    return DefaultTabController(
      length: 2,
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
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Full A+ Students'),
                Tab(text: 'Near Full A+'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _buildStudentList(fullAPlusList, isFullA: true),
                _buildStudentList(nineAPlusList, isFullA: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(List list, {required bool isFullA}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isFullA ? 'No Full A+ students' : 'No Near Full A+ students',
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
                  isFullA ? 'Full A+' : '9 A+',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
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
