// lib/screens/staff/class_marks_overview.dart
// Class teacher / admin view: see all student marks per exam for a class
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:school_management/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/services/api_service.dart';
import 'package:school_management/services/exam_service.dart';
import 'package:school_management/store/app_state.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
class _C {
  static const primary = Color(0xFF059669);
  static const bg = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const text1 = Color(0xFF0F172A);
  static const text2 = Color(0xFF64748B);
  static const text3 = Color(0xFF94A3B8);

  static List<BoxShadow> shadow([double b = 8, double o = 0.06]) => [
        BoxShadow(
            color: Colors.black.withOpacity(o),
            blurRadius: b,
            offset: const Offset(0, 3)),
      ];
}

// ─── Grade helper ─────────────────────────────────────────────────────────────
Map<String, dynamic> _gradeInfo(int obtained, int max) {
  if (max <= 0)
    return {'grade': '-', 'bg': Colors.grey.shade100, 'fg': Colors.grey};
  final pct = (obtained / max) * 100;
  if (pct >= 90)
    return {
      'grade': 'A+',
      'bg': const Color(0xFFD1FAE5),
      'fg': const Color(0xFF065F46)
    };
  if (pct >= 80)
    return {
      'grade': 'A',
      'bg': const Color(0xFFDCFCE7),
      'fg': const Color(0xFF166534)
    };
  if (pct >= 70)
    return {
      'grade': 'B+',
      'bg': const Color(0xFFDBEAFE),
      'fg': const Color(0xFF1E40AF)
    };
  if (pct >= 60)
    return {
      'grade': 'B',
      'bg': const Color(0xFFCFFAFE),
      'fg': const Color(0xFF155E75)
    };
  if (pct >= 50)
    return {
      'grade': 'C+',
      'bg': const Color(0xFFFEF3C7),
      'fg': const Color(0xFF92400E)
    };
  if (pct >= 40)
    return {
      'grade': 'C',
      'bg': const Color(0xFFFFEDD5),
      'fg': const Color(0xFF9A3412)
    };
  if (pct >= 30)
    return {
      'grade': 'D+',
      'bg': const Color(0xFFFEF3C7),
      'fg': const Color(0xFFB45309)
    };
  if (pct >= 20)
    return {
      'grade': 'D',
      'bg': const Color(0xFFFEE2E2),
      'fg': const Color(0xFFB91C1C)
    };
  return {'grade': 'E', 'bg': Colors.grey.shade100, 'fg': Colors.grey.shade700};
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ClassMarksOverviewPage extends StatefulWidget {
  final String? classId;
  final String? className;
  final String? examId;

  const ClassMarksOverviewPage({super.key, this.classId, this.className, this.examId});

  @override
  State<ClassMarksOverviewPage> createState() => _ClassMarksOverviewPageState();
}

class _ClassMarksOverviewPageState extends State<ClassMarksOverviewPage> {
  final _api = ApiService();
  final _examService = ExamService();

  List<Map<String, dynamic>> _exams = [];
  String? _selectedExamId;
  String? _selectedClassId;
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _examsLoading = true;
  bool _isCardView = false;
  String _search = '';
  final _searchCtrl = TextEditingController();
  String _marksMode = 'total'; // 'total' | 'te' | 'both'
  String _sortBy = 'rollNo'; // 'rollNo' | 'rank' | 'name' | 'percentage'
  String? _downloadingStudentId;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.classId;
    _selectedExamId = widget.examId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExams());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    final isStaff = store.state.auth.user?.role == 'staff';
    final currentYearId = store.state.academicYears.currentAcademicYear?.id;

    setState(() => _examsLoading = true);
    try {
      String? ayId = currentYearId;
      if (ayId == null && isStaff) {
        final ayResp = await _api.get('/academic-years', params: {'limit': 10});
        final ays = (ayResp.data?['data'] ?? ayResp.data?['academicYears'] ?? []) as List;
        final current = ays.firstWhere((y) => y['isCurrent'] == true, orElse: () => null);
        if (current != null) ayId = current['_id'];
      }

      final resp = await _examService.getExams(limit: 100, isStaff: isStaff, academicYearId: ayId);
      List dynamicList = [];
      if (resp['data'] is List) {
        dynamicList = resp['data'] as List;
      } else if (resp['data'] is Map && resp['data']['exams'] is List) {
        dynamicList = resp['data']['exams'] as List;
      } else if (resp['exams'] is List) {
        dynamicList = resp['exams'] as List;
      }
      setState(() {
        _exams = dynamicList.cast<Map<String, dynamic>>();
        if (_selectedExamId != null) {
          final exam = _exams.firstWhere((e) => e['_id'] == _selectedExamId, orElse: () => <String, dynamic>{});
          if (exam.isEmpty) {
            _selectedExamId = null;
            _selectedClassId = null;
          } else if (_selectedClassId != null && exam['classIds'] != null) {
            var classes = (exam['classIds'] as List).cast<Map<String, dynamic>>();
            if (!isStaff) {
               // admin, keep all
            } else {
               final store = StoreProvider.of<AppState>(context, listen: false);
               final teacherClasses = store.state.classes.teacherClasses;
               classes = classes.where((ec) => teacherClasses.any((c) => c.id == ec['_id'])).toList();
            }
            final foundCls = classes.any((c) => c['_id'] == _selectedClassId);
            if (!foundCls) _selectedClassId = null;
          }
        }
      });
      if (_selectedExamId != null && _selectedClassId != null) {
        _loadMarks();
      }
    } catch (_) {}
    setState(() => _examsLoading = false);
  }

  Future<void> _loadMarks() async {
    final examId = _selectedExamId;
    final classId = _selectedClassId;
    if (examId == null || classId == null) return;
    setState(() {
      _loading = true;
      _data = null;
    });
    try {
      final resp =
          await _api.get('/marks/class/$examId/$classId', noCache: true);
      setState(() => _data = resp.data?['data'] ?? resp.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load marks: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _subjects {
    return (_data?['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  int _getSubjectTeMax(Map<String, dynamic> subj) {
    final termMax = (subj['termMaxMarks'] as num?)?.toInt();
    if (termMax != null && termMax > 0) return termMax;
    final theoryMax = (subj['theoryMaxMarks'] as num?)?.toInt();
    if (theoryMax != null && theoryMax > 0) return theoryMax;
    final ceMax = (subj['ceMaxMarks'] as num?)?.toInt();
    final max = (subj['maxMarks'] as num?)?.toInt();
    if (ceMax != null && max != null && max > ceMax) {
      return max - ceMax;
    }
    return max ?? 100;
  }

  int _getSubjectTotalMax(Map<String, dynamic> subj) {
    final max = (subj['maxMarks'] as num?)?.toInt();
    if (max != null && max > 0) return max;
    final ceMax = (subj['ceMaxMarks'] as num?)?.toInt() ?? 0;
    return _getSubjectTeMax(subj) + ceMax;
  }

  dynamic _getRollNum(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return 999999;
    final parsed = int.tryParse(raw.toString().trim());
    return parsed ?? raw.toString().trim();
  }

  List<Map<String, dynamic>> get _studentRows {
    final students =
        (_data?['students'] as List? ?? []).cast<Map<String, dynamic>>();
    final rows = students.map((student) {
      int totalObtained = 0;
      int totalMax = 0;
      int teTotalObtained = 0;
      int teTotalMax = 0;

      final subjectMarks = _subjects.map((subj) {
        final key = subj['examSubjectId']?.toString() ?? '';
        final sList =
            (student['subjects'] as List? ?? []).cast<Map<String, dynamic>>();
        final sm = sList.firstWhere(
          (s) =>
              (s['examSubjectId']?.toString() ??
                  s['subjectId']?.toString() ??
                  '') ==
              key,
          orElse: () => {},
        );
        final isAbsent = sm['isAbsent'] == true;
        final theory = isAbsent ? 0 : ((sm['theoryScore'] as num?)?.toInt() ?? 0);
        final practical = (sm['practicalScore'] as num?)?.toInt() ?? 0;
        final ce = ((sm['ceMarks'] ?? sm['ceScore']) as num?)?.toInt() ?? 0;
        final isEntered = isAbsent ||
            (sm['isEnteredExplicitly'] == true) ||
            (sm['isEntered'] == true) ||
            (sm['theoryScore'] != null && (sm['theoryScore'] as num) > 0) ||
            (sm['ceMarks'] != null && (sm['ceMarks'] as num) > 0) ||
            (sm['ceScore'] != null && (sm['ceScore'] as num) > 0);

        final totalScore = (sm['totalScore'] as num?)?.toInt();
        final total = isEntered
            ? (totalScore != null && totalScore > 0 ? totalScore : (isAbsent ? ce : theory + practical + ce))
            : (isAbsent ? ce : 0);

        final int teMax = ((sm['termMaxMarks'] ?? sm['theoryMaxMarks']) as num?)?.toInt() ?? _getSubjectTeMax(subj);
        final int max = (sm['maxMarks'] as num?)?.toInt() ?? _getSubjectTotalMax(subj);

        if (isEntered || (isAbsent && ce > 0)) {
          totalObtained += total;
          totalMax += max;
          teTotalObtained += theory;
          teTotalMax += teMax;
        }

        final teGradeInfo = _gradeInfo(theory, teMax);
        final totalGradeInfo = _gradeInfo(total, max);
        final isTeWarning = teMax > 0 && ((theory / teMax) * 100 < 30);

        return {
          'examSubjectId': key,
          'name': subj['displayName'] ?? subj['subjectName'] ?? '',
          'total': total,
          'max': max,
          'theory': theory,
          'teMax': teMax,
          'ce': ce,
          'isAbsent': isAbsent,
          'isEntered': isEntered,
          'teGradeInfo': teGradeInfo,
          'totalGradeInfo': totalGradeInfo,
          'isTeWarning': isTeWarning,
        };
      }).toList();

      final pct = totalMax > 0 ? (totalObtained / totalMax) * 100 : 0.0;
      final tePct = teTotalMax > 0 ? (teTotalObtained / teTotalMax) * 100 : 0.0;

      return {
        'studentId': student['studentId'] ?? student['_id'],
        'name': student['studentName'] ?? '',
        'admissionNo': student['admissionNo'] ?? student['studentCode'] ?? '-',
        'rollNumber': student['rollNumber'] ?? student['rollNo'] ?? student['slNo'],
        'subjectMarks': subjectMarks,
        'totalObtained': totalObtained,
        'totalMax': totalMax,
        'percentage': pct,
        'gradeInfo': _gradeInfo(totalObtained, totalMax),
        'teTotalObtained': teTotalObtained,
        'teTotalMax': teTotalMax,
        'tePercentage': tePct,
        'teGradeInfo': _gradeInfo(teTotalObtained, teTotalMax),
      };
    }).toList();

    // 1. Calculate rank based on active marksMode percentage
    rows.sort((a, b) {
      final aPct = _marksMode == 'te' ? (a['tePercentage'] as double) : (a['percentage'] as double);
      final bPct = _marksMode == 'te' ? (b['tePercentage'] as double) : (b['percentage'] as double);
      return bPct.compareTo(aPct);
    });
    for (int i = 0; i < rows.length; i++) {
      rows[i] = {...rows[i], 'rank': i + 1};
    }

    // 2. Sort display order based on _sortBy
    rows.sort((a, b) {
      if (_sortBy == 'name') {
        return (a['name'] as String).compareTo(b['name'] as String);
      }
      if (_sortBy == 'percentage') {
        final aPct = _marksMode == 'te' ? (a['tePercentage'] as double) : (a['percentage'] as double);
        final bPct = _marksMode == 'te' ? (b['tePercentage'] as double) : (b['percentage'] as double);
        return bPct.compareTo(aPct);
      }
      if (_sortBy == 'rank') {
        return (a['rank'] as int).compareTo(b['rank'] as int);
      }
      // default 'rollNo'
      final rA = _getRollNum(a['rollNumber']);
      final rB = _getRollNum(b['rollNumber']);
      if (rA != rB) {
        if (rA is int && rB is int) return rA.compareTo(rB);
        return rA.toString().compareTo(rB.toString());
      }
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return rows;
  }

  String _formatExamTitle(dynamic e) {
    if (e == null) return '';
    if (e is Map) {
      final displayName = e['displayName']?.toString();
      if (displayName != null && displayName.isNotEmpty) return displayName;
      final title = e['title']?.toString();
      if (title != null && title.isNotEmpty && !title.contains('_')) return title;
      final name = e['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        if (!name.contains('_')) return name;
        return name
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
      }
    }
    final str = e.toString();
    if (str.contains('_')) {
      return str
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }
    return str;
  }

  bool _isDownloading = false;

  Future<void> _downloadClassMarks({required bool isExcel}) async {
    final classId = _selectedClassId;
    final examId = _selectedExamId;
    if (classId == null || examId == null) return;

    if (mounted) setState(() => _isDownloading = true);
    try {
      final token = ApiService().getToken();
      final endpoint = isExcel
          ? '/pdf/report-card/class-marks/excel/$classId/$examId?mode=$_marksMode&sortBy=$_sortBy'
          : '/pdf/report-card/class-marks/download/$classId/$examId?mode=$_marksMode&sortBy=$_sortBy';

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
      final modeSuffix = _marksMode == 'te' ? '_TE' : (_marksMode == 'both' ? '_Both' : '_Total');
      final fileName = 'Class_Marks_${classId}_$examId$modeSuffix.$ext';

      if (isExcel) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Class Marks Overview Excel');
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadClassReportCards() async {
    final classId = _selectedClassId;
    final examId = _selectedExamId;
    if (classId == null || examId == null) return;

    if (mounted) setState(() => _isDownloading = true);
    try {
      final token = ApiService().getToken();
      final endpoint = '/pdf/report-card/class/download/$classId/$examId';

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
      final fileName = 'Class_ReportCards_${classId}_$examId.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        String msg = '$e';
        if (e is DioException && e.response?.data != null) {
          try {
            final body = String.fromCharCodes(e.response!.data as List<int>);
            msg = body;
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report cards: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadStudentMarklist(String studentId, String studentName) async {
    final examId = _selectedExamId;
    if (examId == null) return;

    setState(() => _downloadingStudentId = studentId);
    try {
      final token = ApiService().getToken();
      final endpoint = '/pdf/marklist/download/$studentId/$examId?mode=$_marksMode';

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
      final modeSuffix = _marksMode == 'te' ? '_TE' : (_marksMode == 'both' ? '_Both' : '');
      final cleanName = studentName.replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'Marklist_$cleanName$modeSuffix.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download marklist: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingStudentId = null);
    }
  }

  Future<void> _downloadStudentReportCard(String studentId, String studentName) async {
    final examId = _selectedExamId;
    if (examId == null) return;

    setState(() => _downloadingStudentId = studentId);
    try {
      final token = ApiService().getToken();
      final endpoint = '/pdf/report-card/download/$studentId/$examId';

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
      final cleanName = studentName.replaceAll(RegExp(r'\s+'), '_');
      final fileName = 'ReportCard_$cleanName.pdf';

      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download report card: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingStudentId = null);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.toLowerCase();
    return _studentRows
        .where((s) =>
            (s['name'] as String).toLowerCase().contains(q) ||
            (s['admissionNo'] as String).toLowerCase().contains(q) ||
            (s['rollNumber'] != null && s['rollNumber'].toString().toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.auth.user?.role ?? 'staff',
      builder: (context, role) {
        final isAdmin = role == 'admin';

        return Scaffold(
          backgroundColor: _C.bg,
          appBar: AppBar(
            backgroundColor: _C.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class Marks Overview',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                if (widget.className != null)
                  Text(widget.className!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_isCardView
                    ? Icons.table_chart_outlined
                    : Icons.view_module_outlined),
                tooltip: _isCardView ? 'Switch to Table' : 'Switch to Cards',
                onPressed: () => setState(() => _isCardView = !_isCardView),
              ),
              if (_selectedExamId != null && _selectedClassId != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadMarks,
                ),
            ],
          ),
          body: Column(
            children: [
              if (!isAdmin && _exams.isEmpty && !_examsLoading && widget.classId == null)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.class_outlined,
                            size: 60, color: _C.primary),
                        SizedBox(height: 16),
                        Text('No Exams Assigned',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _C.text1)),
                        SizedBox(height: 8),
                        Text(
                            'You do not have any exams assigned\nto your classes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _C.text2)),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildSelectors(isAdmin),
                if (_loading)
                  const Expanded(
                      child: Center(
                          child: CircularProgressIndicator(color: _C.primary))),
                if (!_loading && _data == null)
                  Expanded(
                      child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.bar_chart_outlined,
                          size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                          'Select an exam${isAdmin ? " and class" : ""} to view marks',
                          style: TextStyle(color: _C.text3, fontSize: 14)),
                    ]),
                  )),
                if (!_loading && _data != null)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final rows = _studentRows;
                        final spList = (_data?['subjectProgress'] as List? ?? []).cast<Map<String, dynamic>>();
                        final completedSubjects = spList.isNotEmpty 
                            ? spList.where((sp) => (sp['percentage'] as num? ?? 0) == 100).length
                            : _subjects.where((subj) {
                                final key = subj['examSubjectId']?.toString() ?? '';
                                return rows.every((s) => (s['subjectMarks'] as List)
                                    .any((sm) => sm['examSubjectId'] == key && sm['isEntered'] == true));
                              }).length;

                        if (!isAdmin && completedSubjects < _subjects.length) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, size: 60, color: Colors.orange),
                                const SizedBox(height: 12),
                                const Text('Marks Pending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.text1)),
                                const SizedBox(height: 8),
                                Text('The class marks overview will be available once marks\nfor all subjects have been submitted.\nCurrently, $completedSubjects out of ${_subjects.length} subjects are completed.',
                                    textAlign: TextAlign.center, style: const TextStyle(color: _C.text3, fontSize: 14)),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: [
                            _buildSummaryRow(),
                            _buildExportBar(),
                            _buildControlsBar(),
                            Expanded(child: _isCardView ? _buildCardView() : _buildTableView()),
                          ],
                        );
                      }
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectors(bool isAdmin) {
    List<Map<String, dynamic>> availableClasses = [];
    if (_selectedExamId != null) {
      final exam = _exams.firstWhere((e) => e['_id'] == _selectedExamId, orElse: () => <String, dynamic>{});
      if (exam.isNotEmpty && exam['classIds'] != null) {
         availableClasses = (exam['classIds'] as List).cast<Map<String, dynamic>>();
         if (!isAdmin) {
           final store = StoreProvider.of<AppState>(context, listen: false);
           final teacherClasses = store.state.classes.teacherClasses;
           availableClasses = availableClasses.where((ec) {
             return teacherClasses.any((c) => c.id == ec['_id']);
           }).toList();
         }
         
         // Deduplicate to avoid DropdownMenuItem assertion errors
         final uniqueIds = <String>{};
         availableClasses = availableClasses.where((ec) {
           return uniqueIds.add(ec['_id'].toString());
         }).toList();
      }
    }

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _examsLoading
              ? const Text('Loading exams…',
                  style: TextStyle(color: _C.text3, fontSize: 13))
              : _buildDropdown(
                  label: 'Select Exam',
                  hint: '— Choose Exam —',
                  value: _selectedExamId,
                  items: _exams
                      .map((e) => DropdownMenuItem(
                            value: e['_id'] as String?,
                            child: Text(_formatExamTitle(e),
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedExamId = v;
                      _selectedClassId = null; // Reset class selection
                      _data = null;
                    });
                  },
                ),
          const SizedBox(height: 10),
          if (_selectedExamId != null)
            _buildDropdown(
              label: 'Select Class',
              hint: '— Choose Class —',
              value: _selectedClassId,
              items: availableClasses.map((c) {
                final name = c['displayName'] ??
                    '${c['name']}${c['section'] != null ? "-${c['section']}" : ""}';
                return DropdownMenuItem(
                    value: c['_id'] as String?,
                    child: Text(name, style: const TextStyle(fontSize: 13)));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedClassId = v;
                  _data = null;
                });
                if (_selectedClassId != null && _selectedExamId != null) {
                  _loadMarks();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required ValueChanged<String?> onChanged,
  }) {
    // Deduplicate items and ensure exactly one null-value item exists
    final cleanItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(hint, style: const TextStyle(color: _C.text3, fontSize: 13)),
      ),
    ];

    final seenValues = <String>{};
    for (final item in items) {
      final val = item.value;
      if (val != null && val.isNotEmpty && seenValues.add(val)) {
        cleanItems.add(item);
      }
    }

    final String? selectedValue = (value != null && seenValues.contains(value)) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _C.text2)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
            color: _C.surface,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: selectedValue,
              isExpanded: true,
              items: cleanItems,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    final rows = _studentRows;
    if (rows.isEmpty) return const SizedBox();
    final isTe = _marksMode == 'te';
    final avg = rows.fold(0.0, (s, r) => s + (isTe ? (r['tePercentage'] as double) : (r['percentage'] as double))) / rows.length;
    final pass = rows.where((r) => (isTe ? (r['tePercentage'] as double) : (r['percentage'] as double)) >= 40).length;
    final completedSubjects = _subjects.where((subj) {
      final key = subj['examSubjectId']?.toString() ?? '';
      return rows.every((s) => (s['subjectMarks'] as List)
          .any((sm) => sm['examSubjectId'] == key && sm['isEntered'] == true));
    }).length;

    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _statChip('Students', rows.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          _statChip('Avg %', '${avg.toStringAsFixed(1)}%', _C.primary),
          const SizedBox(width: 8),
          _statChip('Pass', '$pass/${rows.length}', Colors.green),
          const SizedBox(width: 8),
          _statChip('Subjects Done', '$completedSubjects/${_subjects.length}',
              Colors.amber.shade700),
        ],
      ),
    );
  }

  Widget _buildExportBar() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: _isDownloading ? null : () => _downloadClassMarks(isExcel: false),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Colors.redAccent),
              label: Text(
                _isDownloading ? 'Downloading…' : 'Class Marks (PDF)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _isDownloading ? null : _downloadClassReportCards,
              icon: const Icon(Icons.badge_outlined, size: 15, color: Color(0xFF4F46E5)),
              label: const Text(
                'Report Cards (PDF)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4F46E5)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : () => _downloadClassMarks(isExcel: true),
              icon: const Icon(Icons.table_chart_rounded, size: 15),
              label: Text(
                _isDownloading ? 'Exporting…' : 'Excel (XLS)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      color: _C.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // View Mode Toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _modeButton('te', 'TE Marks & Grade'),
                _modeButton('total', 'TE + CE (Total)'),
                _modeButton('both', 'Both'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search & Sort Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search student…',
                    hintStyle: const TextStyle(color: _C.text3, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: _C.text3, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _C.primary)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.swap_vert, size: 18, color: _C.text2),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _C.text1),
                    onChanged: (v) {
                      if (v != null) setState(() => _sortBy = v);
                    },
                    items: const [
                      DropdownMenuItem(value: 'rollNo', child: Text('Sort by Roll No')),
                      DropdownMenuItem(value: 'rank', child: Text('Sort by Rank')),
                      DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      DropdownMenuItem(value: 'percentage', child: Text('Sort by %')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String mode, String label) {
    final isSelected = _marksMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _marksMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _C.primary : _C.text2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // ── TABLE VIEW ──────────────────────────────────────────────────────────────
  Widget _buildTableView() {
    final rows = _filtered;
    final subjects = _subjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 42,
          dataRowMaxHeight: 52,
          columnSpacing: 16,
          columns: [
            const DataColumn(
              label: Text('Roll No',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            const DataColumn(
              label: Text('Student',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
            ...subjects.map((s) {
              final teMax = _getSubjectTeMax(s);
              final totalMax = _getSubjectTotalMax(s);
              String subHeader = '/$totalMax';
              if (_marksMode == 'te') {
                subHeader = 'TE /$teMax';
              } else if (_marksMode == 'both') {
                subHeader = 'TE:/$teMax | Tot:/$totalMax';
              }
              return DataColumn(
                label: SizedBox(
                  width: _marksMode == 'both' ? 105 : 75,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s['displayName'] ?? s['subjectName'] ?? '',
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subHeader,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: _marksMode == 'te' ? FontWeight.bold : FontWeight.normal,
                          color: _marksMode == 'te' ? _C.primary : _C.text3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
            DataColumn(
              label: Text(
                _marksMode == 'te'
                    ? 'TE Total'
                    : (_marksMode == 'both' ? 'Total (TE/Tot)' : 'Total'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            DataColumn(
              label: Text(
                _marksMode == 'te' ? 'TE %' : '%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
            const DataColumn(
              label: Text('Actions',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
          rows: rows.map((student) {
            final roll = student['rollNumber'] ?? student['rollNo'] ?? student['slNo'] ?? '-';
            final teObt = student['teTotalObtained'];
            final teMax = student['teTotalMax'];
            final totObt = student['totalObtained'];
            final totMax = student['totalMax'];
            final pct = (_marksMode == 'te' ? student['tePercentage'] : student['percentage']) as double;
            final isDownloadingThis = _downloadingStudentId == student['studentId'];

            return DataRow(cells: [
              // Roll No
              DataCell(
                Center(
                  child: Text('$roll',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.text1)),
                ),
              ),
              // Student name & Admission No
              DataCell(SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(student['name'] as String,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _C.text1),
                        overflow: TextOverflow.ellipsis),
                    Text(student['admissionNo'] as String,
                        style: const TextStyle(fontSize: 9, color: _C.text3)),
                  ],
                ),
              )),
              // Subject marks
              ...(student['subjectMarks'] as List).map((sm) {
                final isAbsent = sm['isAbsent'] == true;
                final isEntered = sm['isEntered'] == true;
                final theory = sm['theory'] as int;
                final teMax = sm['teMax'] as int;
                final total = sm['total'] as int;
                final max = sm['max'] as int;
                final teGrade = sm['teGradeInfo']?['grade'] as String? ?? '-';
                final totalGrade = sm['totalGradeInfo']?['grade'] as String? ?? '-';
                final isTeWarning = sm['isTeWarning'] == true;

                if (isAbsent && total == 0) {
                  return const DataCell(
                    Center(
                      child: Text('AB',
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w800)),
                    ),
                  );
                }
                if (!isEntered && !isAbsent) {
                  return const DataCell(
                    Center(
                      child: Text('—', style: TextStyle(color: _C.text3, fontSize: 11)),
                    ),
                  );
                }

                if (_marksMode == 'te') {
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$theory/$teMax',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isTeWarning ? FontWeight.w800 : FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isTeWarning ? Colors.red.shade600 : _C.text1,
                            ),
                          ),
                          Text(
                            '$teGrade${isTeWarning ? "*" : ""}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isTeWarning ? Colors.red.shade600 : _C.text1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (_marksMode == 'both') {
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('TE: ', style: TextStyle(fontSize: 9, color: _C.text3)),
                              if (isAbsent)
                                const Text('AB', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w800))
                              else
                                Text(
                                  '$theory ($teGrade)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isTeWarning ? FontWeight.w800 : FontWeight.w600,
                                    fontFamily: 'monospace',
                                    color: isTeWarning ? Colors.red.shade600 : _C.text2,
                                  ),
                                ),
                            ],
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Tot: ', style: TextStyle(fontSize: 9, color: _C.text3)),
                                Text(
                                  '$total ($totalGrade)',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                    color: _C.text1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // total mode
                  return DataCell(
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$total/$max',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: _C.text1),
                          ),
                          Text(
                            totalGrade,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _C.text1),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }),
              // Total
              DataCell(
                Center(
                  child: _marksMode == 'te'
                      ? Text('$teObt/$teMax', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'))
                      : (_marksMode == 'both'
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('TE: $teObt/$teMax', style: const TextStyle(fontSize: 10, color: _C.text2, fontFamily: 'monospace')),
                                Text('Tot: $totObt/$totMax', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                              ],
                            )
                          : Text('$totObt/$totMax', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                ),
              ),
              // Percentage (plain text, no badge)
              DataCell(
                Center(
                  child: Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.text1),
                  ),
                ),
              ),
              // Actions (Marklist & Report Card PDF download)
              DataCell(
                Center(
                  child: isDownloadingThis
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary))
                      : PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Download PDFs',
                          icon: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_outlined, size: 14, color: _C.primary),
                              SizedBox(width: 2),
                              Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.primary)),
                              Icon(Icons.arrow_drop_down, size: 14, color: _C.primary),
                            ],
                          ),
                          onSelected: (val) {
                            final sid = student['studentId'].toString();
                            final sname = student['name'].toString();
                            if (val == 'marklist') {
                              _downloadStudentMarklist(sid, sname);
                            } else if (val == 'report_card') {
                              _downloadStudentReportCard(sid, sname);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'marklist',
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, size: 16, color: _C.primary),
                                  const SizedBox(width: 8),
                                  Text('Marklist ($_marksMode)', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'report_card',
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 16, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 8),
                                  Text('Report Card', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ── CARD VIEW ───────────────────────────────────────────────────────────────
  Widget _buildCardView() {
    final rows = _filtered;
    if (rows.isEmpty) {
      return const Center(
          child: Text('No students found', style: TextStyle(color: _C.text3)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) => _buildStudentCard(rows[idx]),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final activeGradeInfo = _marksMode == 'te' ? student['teGradeInfo'] : student['gradeInfo'];
    final pct = (_marksMode == 'te' ? student['tePercentage'] : student['percentage']) as double;
    final subjectMarks = (student['subjectMarks'] as List).cast<Map<String, dynamic>>();
    final isDownloadingThis = _downloadingStudentId == student['studentId'];

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _C.shadow(),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _C.primary.withOpacity(0.08),
              const Color(0xFFD1FAE5),
            ]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _C.primary,
              child: Text(
                (student['name'] as String).isNotEmpty
                    ? (student['name'] as String)[0]
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _C.text1)),
                  Text(
                    '${student['admissionNo']} • Roll: ${student['rollNumber'] ?? "-"}',
                    style: const TextStyle(fontSize: 11, color: _C.text3),
                  ),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: activeGradeInfo['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  activeGradeInfo['grade'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: activeGradeInfo['fg'] as Color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((student['rank'] as int) <= 3) ...[
                    Icon(
                      Icons.emoji_events,
                      size: 14,
                      color: student['rank'] == 1
                          ? Colors.amber.shade700
                          : (student['rank'] == 2 ? Colors.blueGrey : Colors.brown),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Text('#${student['rank']}  ${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11, color: _C.text3)),
                ],
              ),
            ]),
          ]),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(pct >= 60
                  ? _C.primary
                  : pct >= 40
                      ? Colors.amber
                      : Colors.red),
            ),
          ),
        ),
        // Subject list
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(
            children: subjectMarks.map((sm) {
              final isAbsent = sm['isAbsent'] == true;
              final isEntered = sm['isEntered'] == true;
              final theory = sm['theory'] as int;
              final teMax = sm['teMax'] as int;
              final total = sm['total'] as int;
              final max = sm['max'] as int;
              final teGrade = sm['teGradeInfo']?['grade'] as String? ?? '-';
              final totalGrade = sm['totalGradeInfo']?['grade'] as String? ?? '-';
              final isTeWarning = sm['isTeWarning'] == true;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        sm['name'] as String,
                        style: const TextStyle(fontSize: 12, color: _C.text2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAbsent && total == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('AB', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w700)),
                      )
                    else if (!isEntered && !isAbsent)
                      const Text('—', style: TextStyle(color: _C.text3, fontSize: 12))
                    else if (_marksMode == 'te')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$theory/$teMax',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isTeWarning ? FontWeight.w800 : FontWeight.w600,
                              fontFamily: 'monospace',
                              color: isTeWarning ? Colors.red.shade600 : _C.text1,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$teGrade${isTeWarning ? "*" : ""}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isTeWarning ? Colors.red.shade600 : _C.text1,
                            ),
                          ),
                        ],
                      )
                    else if (_marksMode == 'both')
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isAbsent ? 'AB' : '$theory ($teGrade)',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: isTeWarning ? Colors.red.shade600 : _C.text2,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('|', style: TextStyle(fontSize: 10, color: _C.text3)),
                          ),
                          Text(
                            '$total ($totalGrade)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: _C.text1),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total/$max',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace', color: _C.text1),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            totalGrade,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _C.text1),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        // Footer total & Marklist download
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _marksMode == 'te' ? 'TE Total' : (_marksMode == 'both' ? 'Tot (TE|Tot)' : 'Total'),
                    style: const TextStyle(fontSize: 10, color: _C.text3),
                  ),
                  Text(
                    _marksMode == 'te'
                        ? '${student['teTotalObtained']}/${student['teTotalMax']}'
                        : (_marksMode == 'both'
                            ? '${student['teTotalObtained']}/${student['teTotalMax']} | ${student['totalObtained']}/${student['totalMax']}'
                            : '${student['totalObtained']}/${student['totalMax']}'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: _C.text1),
                  ),
                ],
              ),
              isDownloadingThis
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _C.primary))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _downloadStudentMarklist(student['studentId'].toString(), student['name'].toString()),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.picture_as_pdf_outlined, size: 14, color: _C.primary),
                                SizedBox(width: 3),
                                Text('Marklist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.primary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _downloadStudentReportCard(student['studentId'].toString(), student['name'].toString()),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_outlined, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 3),
                                Text('Report Card', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ]),
    );
  }
}
