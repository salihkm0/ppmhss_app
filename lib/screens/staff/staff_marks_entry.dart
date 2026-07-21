// lib/screens/staff/staff_marks_entry.dart
// Matches the React StaffMarksEntry page logic exactly:
//   GET  /marks/class/{examId}/{classId}       → subjects, students, subjectProgress
//   GET  /marks/permissions/{examId}/{classId} → permissions
//   POST /marks/bulk/{examId}/{classId}        → { studentsData }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_management/services/api_service.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:school_management/models/exam_model.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';

// ── Grade helpers ────────────────────────────────────────────────
Map<String, dynamic> _gradeInfo(int obtained, int max) {
  final pct = max > 0 ? (obtained / max) * 100 : 0.0;
  if (pct >= 90) return {'grade': 'A+', 'color': const Color(0xFF059669)};
  if (pct >= 80) return {'grade': 'A',  'color': const Color(0xFF16A34A)};
  if (pct >= 70) return {'grade': 'B+', 'color': const Color(0xFF2563EB)};
  if (pct >= 60) return {'grade': 'B',  'color': const Color(0xFF0891B2)};
  if (pct >= 50) return {'grade': 'C+', 'color': const Color(0xFFCA8A04)};
  if (pct >= 40) return {'grade': 'C',  'color': const Color(0xFFEA580C)};
  if (pct >= 30) return {'grade': 'D+', 'color': const Color(0xFFEF4444)};
  if (pct >= 20) return {'grade': 'D',  'color': const Color(0xFFDC2626)};
  return {'grade': 'E', 'color': const Color(0xFF9CA3AF)};
}

Color _pctColor(double pct) {
  if (pct >= 75) return const Color(0xFF16A34A);
  if (pct >= 50) return const Color(0xFFCA8A04);
  return const Color(0xFFEF4444);
}

// ── Mark Service (direct API calls, no Redux) ────────────────────
class _MarkService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getMarksheetsByClass(String examId, String classId) async {
    final res = await _api.get('/marks/class/$examId/$classId', noCache: true);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPermissions(String examId, String classId) async {
    final res = await _api.get('/marks/permissions/$examId/$classId', noCache: true);
    return res.data as Map<String, dynamic>;
  }

  Future<void> bulkUpdateMarks(String examId, String classId, List<Map<String, dynamic>> studentsData) async {
    _api.invalidateCache('/marks');
    await _api.post('/marks/bulk/$examId/$classId', data: {'studentsData': studentsData});
  }
}

// ── Main Widget ──────────────────────────────────────────────────
class StaffMarksEntryPage extends StatefulWidget {
  final String classId;
  final String className;
  final String? examId;
  final String? examName;

  const StaffMarksEntryPage({
    super.key,
    required this.classId,
    required this.className,
    this.examId,
    this.examName,
  });

  @override
  State<StaffMarksEntryPage> createState() => _StaffMarksEntryPageState();
}

class _StaffMarksEntryPageState extends State<StaffMarksEntryPage> {
  final _markService = _MarkService();
  final _examService = ExamService();

  // ── Selections ──
  List<ExamModel> _exams = [];
  String? _selectedExamId;
  String _searchTerm = '';

  // ── Data (mirrors React state) ──
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _permissions;
  List<Map<String, dynamic>> _examSubjects = [];
  List<Map<String, dynamic>> _subjectProgress = [];

  // tempMarks: { studentId: { examSubjectId: { theoryScore, practicalScore, ceMarks, isAbsent, isEntered } } }
  Map<String, Map<String, Map<String, dynamic>>> _tempMarks = {};

  // Dirty tracking — only send changed students on save
  final Set<String> _dirtyStudents = {};

  // ── Focus & Navigation ──
  final Map<String, ExpansionTileController> _tileControllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  // ── UI ──
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.examId != null && widget.examId!.isNotEmpty) {
      _selectedExamId = widget.examId;
    }
    _loadInitialData();
  }

  // ────────────────────────────────────────────────────────────────
  // Data Loading
  // ────────────────────────────────────────────────────────────────

  Future<void> _loadInitialData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final raw = await _examService.getExams(limit: 100);
      final list = raw['data'] as List? ?? [];
      _exams = list.map((j) => ExamModel.fromJson(j as Map<String, dynamic>)).toList();
      if (mounted) setState(() {});
      if (_selectedExamId != null) await _loadData();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    final examId = _selectedExamId;
    if (examId == null || examId.isEmpty) return;
    if (mounted) setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _markService.getPermissions(examId, widget.classId),
        _markService.getMarksheetsByClass(examId, widget.classId),
      ]);

      final permRes  = results[0] as Map<String, dynamic>;
      final markRes  = results[1] as Map<String, dynamic>;

      final markData = markRes['data'] as Map<String, dynamic>? ?? markRes;

      final subjects  = (markData['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
      final students  = (markData['students'] as List? ?? []).cast<Map<String, dynamic>>();
      final progress  = (markData['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();

      // Build tempMarks — same as React
      final Map<String, Map<String, Map<String, dynamic>>> initial = {};
      for (final student in students) {
        final sid = student['studentId']?.toString() ?? '';
        if (sid.isEmpty) continue;
        initial[sid] = {};
        final subjs = (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
        for (final subj in subjs) {
          final key = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
          if (key.isEmpty) continue;
          final isEntered = subj['isEntered'] == true ||
              (subj['theoryScore'] as num? ?? 0) > 0 ||
              (subj['practicalScore'] as num? ?? 0) > 0 ||
              (subj['ceScore'] as num? ?? subj['ceMarks'] as num? ?? 0) > 0 ||
              subj['isAbsent'] == true;
          initial[sid]![key] = {
            'theoryScore':    isEntered ? (subj['theoryScore']   ?? 0) : '',
            'practicalScore': isEntered ? (subj['practicalScore'] ?? 0) : '',
            'ceMarks':        isEntered ? (subj['ceScore'] ?? subj['ceMarks'] ?? 0) : '',
            'isAbsent':  subj['isAbsent'] ?? false,
            'isEntered': isEntered,
          };
        }
      }

      if (mounted) {
        setState(() {
          _permissions    = permRes['data'] as Map<String, dynamic>? ?? permRes;
          _examSubjects   = subjects;
          _students       = students;
          _subjectProgress = progress;
          _tempMarks      = initial;
          _dirtyStudents.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetData() {
    setState(() {
      _students = [];
      _permissions = null;
      _examSubjects = [];
      _subjectProgress = [];
      _tempMarks = {};
      _dirtyStudents.clear();
    });
  }

  // ────────────────────────────────────────────────────────────────
  // Permissions
  // ────────────────────────────────────────────────────────────────

  bool get _isAdmin => _permissions?['isAdmin'] == true;
  bool get _isClassTeacher => _permissions?['isClassTeacher'] == true;
  bool get _hasEditPermission =>
      _isAdmin ||
      ((_permissions?['allowedSubjects'] as List?)?.isNotEmpty ?? false);

  bool _canEditSubject(String examSubjectId) {
    if (_permissions == null) return false;
    if (_isAdmin) return true;
    final allowed = (_permissions!['allowedSubjects'] as List? ?? []);
    return allowed.any((s) =>
        s['subjectId']?.toString() == examSubjectId ||
        s['subjectId'] == examSubjectId);
  }

  bool get _allMarksEntered =>
      _subjectProgress.isNotEmpty &&
      _subjectProgress.every((sp) => (sp['percentage'] as num? ?? 0) == 100);

  // ────────────────────────────────────────────────────────────────
  // Mark Change Handlers
  // ────────────────────────────────────────────────────────────────

  void _handleMarkChange(String studentId, String examSubjectId, String field, dynamic value) {
    if (!_canEditSubject(examSubjectId)) {
      _showSnack("You don't have permission to edit this subject", isError: true);
      return;
    }
    final subj = _examSubjects.firstWhere(
      (s) => (s['examSubjectId']?.toString() ?? '') == examSubjectId,
      orElse: () => {},
    );

    int? parsed;
    if (value != '' && value != null) {
      parsed = int.tryParse(value.toString()) ?? 0;
      int max = 0;
      if (field == 'theoryScore')    max = (subj['theoryMaxMarks'] ?? subj['termMaxMarks'] ?? subj['maxMarks'] ?? 100) as int;
      if (field == 'practicalScore') max = (subj['practicalMaxMarks'] ?? 0) as int;
      if (field == 'ceMarks')        max = (subj['ceMaxMarks'] ?? 0) as int;
      parsed = parsed.clamp(0, max > 0 ? max : 9999);
    }

    _dirtyStudents.add(studentId);
    setState(() {
      _tempMarks[studentId] ??= {};
      final curr = Map<String, dynamic>.from(_tempMarks[studentId]![examSubjectId] ?? {
        'theoryScore': '', 'practicalScore': '', 'ceMarks': '', 'isAbsent': false, 'isEntered': false,
      });
      curr[field] = parsed ?? '';
      curr['isEntered'] = true;
      _tempMarks[studentId]![examSubjectId] = curr;
    });
  }

  void _handleAbsentToggle(String studentId, String examSubjectId) {
    if (!_canEditSubject(examSubjectId)) {
      _showSnack("You don't have permission to edit this subject", isError: true);
      return;
    }
    _dirtyStudents.add(studentId);
    setState(() {
      _tempMarks[studentId] ??= {};
      final curr = Map<String, dynamic>.from(_tempMarks[studentId]![examSubjectId] ?? {
        'theoryScore': 0, 'practicalScore': 0, 'ceMarks': 0, 'isAbsent': false,
      });
      final nowAbsent = !(curr['isAbsent'] as bool? ?? false);
      _tempMarks[studentId]![examSubjectId] = {
        ...curr,
        'isAbsent': nowAbsent,
        'theoryScore':    nowAbsent ? 0 : curr['theoryScore'],
        'practicalScore': nowAbsent ? 0 : curr['practicalScore'],
        'ceMarks':        nowAbsent ? 0 : curr['ceMarks'],
      };
    });
  }

  void _handleFieldSubmitted(String studentId, String examSubjectId, String fieldType) {
    final students = _filteredStudents;
    final sIdx = students.indexWhere((s) => s['studentId'].toString() == studentId);
    if (sIdx == -1) return;

    final subj = _examSubjects.firstWhere((s) => (s['examSubjectId']?.toString() ?? '') == examSubjectId, orElse: () => {});
    final hasPrac = subj['hasPractical'] == true && (subj['practicalMaxMarks'] as num? ?? 0) > 0;
    final hasCE = subj['ceEnabled'] == true && (subj['ceMaxMarks'] as num? ?? 0) > 0;

    String nextField = '';
    String nextStudentId = studentId;

    if (fieldType == 'ceMarks') {
      nextField = 'theoryScore';
    } else if (fieldType == 'theoryScore') {
      if (hasPrac) {
        nextField = 'practicalScore';
      } else {
        if (sIdx + 1 < students.length) {
          nextStudentId = students[sIdx + 1]['studentId'].toString();
          nextField = hasCE ? 'ceMarks' : 'theoryScore';
        }
      }
    } else if (fieldType == 'practicalScore') {
      if (sIdx + 1 < students.length) {
        nextStudentId = students[sIdx + 1]['studentId'].toString();
        nextField = hasCE ? 'ceMarks' : 'theoryScore';
      }
    }

    if (nextField.isNotEmpty) {
      if (nextStudentId != studentId) {
        _tileControllers[studentId]?.collapse();
        _tileControllers[nextStudentId]?.expand();
        // Wait for expansion animation to build fields
        Future.delayed(const Duration(milliseconds: 300), () {
          final nextKey = '${nextField}_${nextStudentId}_$examSubjectId';
          _focusNodes[nextKey]?.requestFocus();
        });
      } else {
        final nextKey = '${nextField}_${nextStudentId}_$examSubjectId';
        _focusNodes[nextKey]?.requestFocus();
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Save
  // ────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final examId = _selectedExamId;
    if (examId == null) return;

    final filtered = _filteredStudents;
    final targets = _dirtyStudents.isNotEmpty
        ? filtered.where((s) => _dirtyStudents.contains(s['studentId']?.toString())).toList()
        : filtered; // fallback

    if (targets.isEmpty) {
      _showSnack('No changes to save.');
      return;
    }

    int errorCount = 0;
    for (var student in targets) {
      final sid = student['studentId']?.toString() ?? '';
      final subjs = (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
      for (var subj in subjs) {
        final key = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
        final tm = _tempMarks[sid]?[key] ?? {};
        final isAbsent = tm['isAbsent'] ?? subj['isAbsent'] ?? false;
        if (isAbsent) continue;

        final maxTheory = ((subj['theoryMaxMarks'] ?? subj['termMaxMarks'] ?? 100) as num).toInt();
        final maxPrac   = ((subj['practicalMaxMarks'] ?? 0) as num).toInt();
        final maxCE     = ((subj['ceMaxMarks'] ?? 0) as num).toInt();

        final tVal = tm['theoryScore'] ?? subj['theoryScore'] ?? '';
        final pVal = tm['practicalScore'] ?? subj['practicalScore'] ?? '';
        final cVal = tm['ceMarks'] ?? subj['ceMarks'] ?? subj['ceScore'] ?? '';

        int tInt = tVal is int ? tVal : int.tryParse(tVal.toString()) ?? 0;
        int pInt = pVal is int ? pVal : int.tryParse(pVal.toString()) ?? 0;
        int cInt = cVal is int ? cVal : int.tryParse(cVal.toString()) ?? 0;

        if (tVal.toString().isNotEmpty && tInt > maxTheory) errorCount++;
        if (pVal.toString().isNotEmpty && pInt > maxPrac) errorCount++;
        if (cVal.toString().isNotEmpty && cInt > maxCE) errorCount++;
      }
    }

    if (errorCount > 0) {
      _showSnack('Please fix $errorCount invalid mark entries before saving.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final studentsData = targets.map((student) {
        final sid = student['studentId']?.toString() ?? '';
        final subjs = (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
        return {
          'studentId': sid,
          'subjects': subjs.map((subj) {
            final key = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
            final tm = _tempMarks[sid]?[key] ?? {};
            return {
              'examSubjectId': subj['examSubjectId'] ?? subj['subjectId'],
              'subjectId':     subj['actualSubjectId'] ?? subj['subjectId'],
              'theoryScore':    (tm['theoryScore'] == '' ? 0 : tm['theoryScore']) ?? subj['theoryScore'] ?? 0,
              'practicalScore': (tm['practicalScore'] == '' ? 0 : tm['practicalScore']) ?? subj['practicalScore'] ?? 0,
              'ceMarks':        (tm['ceMarks'] == '' ? 0 : tm['ceMarks']) ?? (subj['ceMarks'] ?? subj['ceScore']) ?? 0,
              'isAbsent': tm['isAbsent'] ?? subj['isAbsent'] ?? false,
              'remarks':  subj['remarks'] ?? '',
            };
          }).toList(),
          'remarks': student['remarks'] ?? '',
        };
      }).toList();

      await _markService.bulkUpdateMarks(examId, widget.classId, studentsData);
      if (mounted) setState(() => _isSaving = false);
      _showSnack('Saved marks for ${targets.length} student${targets.length != 1 ? 's' : ''}!');
      _dirtyStudents.clear();
      await _loadData(); // refresh
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
      _showSnack('Failed to save marks: $e', isError: true);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchTerm.isEmpty) return _students;
    final q = _searchTerm.toLowerCase();
    return _students.where((s) =>
        (s['studentName']?.toString().toLowerCase().contains(q) ?? false) ||
        (s['rollNumber']?.toString().toLowerCase().contains(q) ?? false) ||
        (s['admissionNo']?.toString().toLowerCase().contains(q) ?? false)).toList();
  }

  double _studentPercentage(String studentId, List<Map<String, dynamic>> subjs) {
    if (subjs.isEmpty) return 0;
    int obtained = 0, maxTotal = 0;
    for (final subj in subjs) {
      final key = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
      final tm = _tempMarks[studentId]?[key] ?? {};
      final theory    = (tm['theoryScore']    is int ? tm['theoryScore']    : int.tryParse(tm['theoryScore']?.toString() ?? '0') ?? 0) as int;
      final practical = (tm['practicalScore'] is int ? tm['practicalScore'] : int.tryParse(tm['practicalScore']?.toString() ?? '0') ?? 0) as int;
      final ce        = (tm['ceMarks']        is int ? tm['ceMarks']        : int.tryParse(tm['ceMarks']?.toString() ?? '0') ?? 0) as int;
      obtained += theory + practical + ce;
      maxTotal += ((subj['theoryMaxMarks'] ?? subj['termMaxMarks'] ?? 100) as num).toInt()
                + ((subj['practicalMaxMarks'] ?? 0) as num).toInt()
                + ((subj['ceMaxMarks'] ?? 0) as num).toInt();
    }
    return maxTotal > 0 ? (obtained / maxTotal) * 100 : 0;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : AppTheme.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        backgroundColor: const Color(0xFFF2F4F8),
        body: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [_buildAppBar()],
          body: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: _isLoading && _students.isEmpty && _examSubjects.isEmpty
                ? const Center(child: LoadingWidget())
                : _error != null && _students.isEmpty
                    ? Center(child: CustomErrorWidget(message: _error!, onRetry: _loadData))
                    : _buildBody(),
          ),
        ),
      ),
      // Saving overlay
      if (_isSaving) ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
      if (_isSaving)
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 3),
              const SizedBox(height: 16),
              const Text('Saving marks…', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      // Refetch overlay
      if (_isLoading && (_students.isNotEmpty || _examSubjects.isNotEmpty))
        ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.15)),
      if (_isLoading && (_students.isNotEmpty || _examSubjects.isNotEmpty))
        const Center(child: LoadingWidget()),
    ]);
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        const Text('Marks Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(widget.className, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w400)),
      ]),
      actions: [
        if (_hasEditPermission && _selectedExamId != null && _examSubjects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
              label: Text(_dirtyStudents.isNotEmpty
                  ? 'Save (${_dirtyStudents.length})'
                  : 'Save All',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(children: [
      _buildExamSelector(),
      if (_selectedExamId != null && _subjectProgress.isNotEmpty)
        _buildSubjectProgress(),
      if (_selectedExamId != null && _examSubjects.isNotEmpty)
        _buildSearchAndStats(),
      if (_selectedExamId == null)
        Expanded(child: _buildEmptyState(Icons.quiz_outlined, 'Select an exam to start entering marks')),
      if (_selectedExamId != null && _examSubjects.isEmpty && !_isLoading)
        Expanded(child: _buildEmptyState(Icons.lock_outline_rounded, 'No subjects available\nYou are not assigned to any subject for this class')),
      if (_selectedExamId != null && _examSubjects.isNotEmpty)
        Expanded(child: _buildStudentList()),
    ]);
  }

  // ── Exam Selector ────────────────────────────────────────────────
  Widget _buildExamSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_rounded, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          const Text('Select Exam', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedExamId,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: 'Choose an exam…',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          items: _exams.map((e) => DropdownMenuItem(
            value: e.id,
            child: Text(e.displayName ?? e.name, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (val) {
            if (val == null || val == _selectedExamId) return;
            setState(() { _selectedExamId = val; });
            _resetData();
            _loadData();
          },
        ),
      ]),
    );
  }

  // ── Subject Progress ─────────────────────────────────────────────
  Widget _buildSubjectProgress() {
    final doneCount = _subjectProgress.where((s) => (s['percentage'] as num? ?? 0) == 100).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text('Class Progress', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('$doneCount/${_subjectProgress.length} subjects complete',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subjectProgress.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final sp = _subjectProgress[i];
              final pct = (sp['percentage'] as num? ?? 0).toDouble();
              final done = pct == 100;
              return Container(
                width: 140,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(child: Text(sp['subjectName']?.toString() ?? '',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                    Icon(done ? Icons.verified_rounded : Icons.schedule_rounded,
                        size: 13, color: done ? const Color(0xFF059669) : const Color(0xFFF59E0B)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${sp['enteredCount'] ?? 0}/${sp['totalStudents'] ?? 0} students',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: const Color(0xFFF3F4F6),
                      color: done ? const Color(0xFF10B981) : pct > 0 ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                      minHeight: 5,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${pct.toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: done ? const Color(0xFF059669) : const Color(0xFFF59E0B))),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Search + stats bar ───────────────────────────────────────────
  Widget _buildSearchAndStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: const InputDecoration(
              hintText: 'Search student…',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (!_hasEditPermission)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF6B7280)),
              SizedBox(width: 4),
              Text('View Only', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ]),
          ),
      ]),
    );
  }

  // ── Student List ─────────────────────────────────────────────────
  Widget _buildStudentList() {
    final students = _filteredStudents;
    if (students.isEmpty) {
      return _buildEmptyState(Icons.person_search_rounded, 'No students found');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: students.length,
      itemBuilder: (ctx, i) => _buildStudentCard(students[i]),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final sid = student['studentId']?.toString() ?? '';
    final name = student['studentName']?.toString() ?? '';
    final roll = student['rollNumber']?.toString() ?? '';
    final admNo = student['admissionNo']?.toString() ?? '';
    final subjs = (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
    final pct = _studentPercentage(sid, subjs);
    final isDirty = _dirtyStudents.contains(sid);

    // Compute total obtained & max for this student
    int obtained = 0, maxTotal = 0;
    for (final subj in subjs) {
      final key = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
      final tm = _tempMarks[sid]?[key] ?? {};
      obtained += (tm['theoryScore']    is int ? tm['theoryScore']    as int : int.tryParse(tm['theoryScore']?.toString() ?? '0') ?? 0)
                + (tm['practicalScore'] is int ? tm['practicalScore'] as int : int.tryParse(tm['practicalScore']?.toString() ?? '0') ?? 0)
                + (tm['ceMarks']        is int ? tm['ceMarks']        as int : int.tryParse(tm['ceMarks']?.toString() ?? '0') ?? 0);
      maxTotal += ((subj['theoryMaxMarks'] ?? subj['termMaxMarks'] ?? 100) as num).toInt()
               + ((subj['practicalMaxMarks'] ?? 0) as num).toInt()
               + ((subj['ceMaxMarks'] ?? 0) as num).toInt();
    }
    final grade = _gradeInfo(obtained, maxTotal);
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      key: ValueKey('student_$sid'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDirty ? Border.all(color: AppTheme.primaryColor.withOpacity(0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          controller: _tileControllers.putIfAbsent(sid, () => ExpansionTileController()),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
            radius: 20,
            child: Text(initials, style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          title: Row(children: [
            Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            if (isDirty)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Edited', style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ),
          ]),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${roll.isNotEmpty ? "Roll: $roll  " : ""}${admNo.isNotEmpty ? "Adm: $admNo" : ""}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFF3F4F6),
                    color: _pctColor(pct),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _pctColor(pct))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (grade['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(grade['grade'] as String,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: grade['color'] as Color)),
              ),
            ]),
          ]),
          children: subjs.map((subj) => _buildSubjectRow(sid, subj)).toList(),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(String studentId, Map<String, dynamic> subj) {
    final key       = subj['examSubjectId']?.toString() ?? subj['subjectId']?.toString() ?? '';
    final name      = subj['displayName']?.toString() ?? subj['subjectName']?.toString() ?? 'Subject';
    final maxTheory = ((subj['theoryMaxMarks'] ?? subj['termMaxMarks'] ?? 100) as num).toInt();
    final maxPrac   = ((subj['practicalMaxMarks'] ?? 0) as num).toInt();
    final maxCE     = ((subj['ceMaxMarks'] ?? 0) as num).toInt();
    final hasPrac   = subj['hasPractical'] == true && maxPrac > 0;
    final hasCE     = subj['ceEnabled'] == true && maxCE > 0;
    final canEdit   = _hasEditPermission && _canEditSubject(key);

    final tm = _tempMarks[studentId]?[key] ?? {};
    final isAbsent = tm['isAbsent'] as bool? ?? false;
    final tVal = tm['theoryScore'];
    final pVal = tm['practicalScore'];
    final cVal = tm['ceMarks'];

    int tInt = tVal is int ? tVal : int.tryParse(tVal?.toString() ?? '') ?? 0;
    int pInt = pVal is int ? pVal : int.tryParse(pVal?.toString() ?? '') ?? 0;
    int cInt = cVal is int ? cVal : int.tryParse(cVal?.toString() ?? '') ?? 0;
    final total    = tInt + pInt + cInt;
    final maxTotal = maxTheory + maxPrac + maxCE;

    final bool teError = tVal != null && tVal.toString().isNotEmpty && tInt > maxTheory;
    final bool peError = pVal != null && pVal.toString().isNotEmpty && pInt > maxPrac;
    final bool ceError = cVal != null && cVal.toString().isNotEmpty && cInt > maxCE;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Subject header
        Row(children: [
          Expanded(
            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          if (!canEdit)
            const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
          // Absent toggle
          if (canEdit) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _handleAbsentToggle(studentId, key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAbsent ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isAbsent ? const Color(0xFFFCA5A5) : const Color(0xFFE5E7EB)),
                ),
                child: Text(isAbsent ? 'Absent' : 'Mark Absent',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isAbsent ? const Color(0xFFDC2626) : const Color(0xFF6B7280))),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        // Score inputs
        Row(children: [
          if (hasCE) ...[
            _scoreField(
              fieldKey: 'ceMarks_${studentId}_$key',
              label: 'CE /$maxCE',
              value: isAbsent ? '0' : (cVal?.toString() ?? ''),
              enabled: canEdit && !isAbsent,
              hasError: ceError,
              onChanged: (v) => _handleMarkChange(studentId, key, 'ceMarks', v),
              onSubmitted: (v) => _handleFieldSubmitted(studentId, key, 'ceMarks'),
            ),
            const SizedBox(width: 8),
          ],
          _scoreField(
            fieldKey: 'theoryScore_${studentId}_$key',
            label: 'TE /$maxTheory',
            value: isAbsent ? '0' : (tVal?.toString() ?? ''),
            enabled: canEdit && !isAbsent,
            hasError: teError,
            onChanged: (v) => _handleMarkChange(studentId, key, 'theoryScore', v),
            onSubmitted: (v) => _handleFieldSubmitted(studentId, key, 'theoryScore'),
          ),
          if (hasPrac) ...[
            const SizedBox(width: 8),
            _scoreField(
              fieldKey: 'practicalScore_${studentId}_$key',
              label: 'PE /$maxPrac',
              value: isAbsent ? '0' : (pVal?.toString() ?? ''),
              enabled: canEdit && !isAbsent,
              hasError: peError,
              onChanged: (v) => _handleMarkChange(studentId, key, 'practicalScore', v),
              onSubmitted: (v) => _handleFieldSubmitted(studentId, key, 'practicalScore'),
            ),
          ],
          const SizedBox(width: 8),
          // Total chip
          Column(children: [
            const Text('Total', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text('$total/$maxTotal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
      ]),
    );
  }

  Widget _scoreField({
    required String fieldKey,
    required String label,
    required String value,
    required bool enabled,
    bool hasError = false,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
  }) {
    _focusNodes.putIfAbsent(fieldKey, () => FocusNode());
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey(fieldKey),
          focusNode: _focusNodes[fieldKey],
          textInputAction: TextInputAction.next,
          initialValue: value,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: hasError ? Colors.red : Colors.black),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? Colors.red : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? Colors.red : AppTheme.primaryColor)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF3F4F6))),
            filled: true,
            fillColor: enabled ? (hasError ? Colors.red[50] : Colors.white) : const Color(0xFFF9FAFB),
          ),
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
        ),
      ]),
    );
  }

  Widget _buildEmptyState(IconData icon, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(msg, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5)),
        ]),
      ),
    );
  }
}