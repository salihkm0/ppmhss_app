import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/class_actions.dart';
import 'package:school_management/actions/student_actions.dart';
import 'package:school_management/models/class_model.dart';
import 'package:school_management/models/student_model.dart';
import 'package:school_management/models/user_model.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';
import 'package:school_management/screens/staff/staff_attendance_page.dart';
import 'package:school_management/screens/staff/staff_marks_entry.dart';
import 'package:school_management/screens/staff/staff_exams_page.dart';
import 'package:school_management/screens/classes/bulk_roll_number_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary    = Color(0xFF059669);
  static const secondary  = Color(0xFF34D399);
  static const success    = Color(0xFF22C55E);
  // ignore: unused_field
  static const warning    = Color(0xFFF59E0B);
  // ignore: unused_field
  static const error      = Color(0xFFEF4444);
  static const sky        = Color(0xFF0EA5E9);
  static const teal       = Color(0xFF14B8A6);
  static const bg         = Color(0xFFF8FAFC);
  static const surface    = Colors.white;
  static const text1      = Color(0xFF0F172A);
  static const text2      = Color(0xFF64748B);
  static const text3      = Color(0xFF94A3B8);
  static const divider    = Color(0xFFF1F5F9);
  static const indigo10   = Color(0xFFF0FDF4);
  static const purple10   = Color(0xFFF0FDFA);
  static const green10    = Color(0xFFF0FDF4);
  static const sky10      = Color(0xFFF0F9FF);
  static const teal10     = Color(0xFFF0FDFA);

  static List<BoxShadow> shadow([double b = 12, double o = 0.06]) => [
    BoxShadow(color: Colors.black.withOpacity(o), blurRadius: b, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> shadowSm() => shadow(8, 0.04);

  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const r24 = BorderRadius.all(Radius.circular(24));
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage>
    with SingleTickerProviderStateMixin {
  // State
  ClassModel? _activeClass;
  List<StudentModel> _students = [];
  String _searchTerm = '';
  late final TextEditingController _searchCtrl;
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchTeacherClassTeacherClassesThunk());
  }

  void _autoSelectFirstClass(List<ClassModel> classes) {
    if (_activeClass == null && classes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _activeClass = classes.first);
          _loadStudents(classes.first.id);
          _heroCtrl.forward(from: 0);
        }
      });
    }
  }

  Future<void> _loadStudents(String classId) async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(
      fetchStudentsByClassThunk(FetchStudentsByClassAction(classId: classId)),
    );
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  List<StudentModel> get _filtered {
    if (_searchTerm.isEmpty) return _students;
    final q = _searchTerm.toLowerCase();
    return _students.where((s) =>
      s.fullName.toLowerCase().contains(q) ||
      (s.rollNumber?.toLowerCase().contains(q) ?? false) ||
      (s.admissionNo?.toLowerCase().contains(q) ?? false) ||
      (s.studentCode.toLowerCase().contains(q))
    ).toList();
  }

  int get _boysCount   => _students.where((s) => s.gender?.toLowerCase() == 'male').length;
  int get _girlsCount  => _students.where((s) => s.gender?.toLowerCase() == 'female').length;

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goAttendance() {
    if (_activeClass == null) return;
    Navigator.push(context, _slide(StaffAttendancePage(
      classId: _activeClass!.id,
      className: _activeClass!.displayName ?? _activeClass!.name,
    )));
  }

  void _goExams() {
    if (_activeClass == null) return;
    Navigator.push(context, _slide(StaffExamsPage(
      classId: _activeClass!.id,
      className: _activeClass!.displayName ?? _activeClass!.name,
    )));
  }

  void _goMarks() {
    if (_activeClass == null) return;
    Navigator.push(context, _slide(StaffMarksEntryPage(
      classId: _activeClass!.id,
      className: _activeClass!.displayName ?? _activeClass!.name,
    )));
  }

  void _goStudentDetail(StudentModel s) {
    Navigator.pushNamed(context, '/students/detail', arguments: s.id);
  }

  void _goAttendanceHistory(StudentModel s) {
    Navigator.pushNamed(context, '/attendance/detail', arguments: {
      'studentId': s.id,
      'studentName': s.fullName,
    });
  }

  PageRouteBuilder _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
      child: child,
    ),
    transitionDuration: const Duration(milliseconds: 320),
  );

  // ── Bottom sheet ──────────────────────────────────────────────────────────
  void _showStudentSheet(StudentModel student) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentBottomSheet(
        student: student,
        onViewProfile: () {
          Navigator.pop(context);
          _goStudentDetail(student);
        },
        onAttendanceHistory: () {
          Navigator.pop(context);
          _goAttendanceHistory(student);
        },
      ),
    );
  }

  void _showBulkRollNumberUpdate(ClassModel classModel, List<StudentModel> students) {
    showDialog(
      context: context,
      builder: (context) => BulkRollNumberDialog(
        classModel: classModel,
        students: students,
        onSaved: () {
          _loadData();
          if (_activeClass != null) {
            _loadStudents(_activeClass!.id);
          }
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Class',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StoreConnector<AppState, _VM>(
        converter: (store) => _VM(
          classes: store.state.classes.teacherClassTeacherClasses,
          students: store.state.students.students,
          isLoadingClasses: store.state.classes.isLoading,
          isLoadingStudents: store.state.students.isLoading,
          classError: store.state.classes.error,
          user: store.state.auth.user,
        ),
        onWillChange: (_, next) {
          _students = next.students;
          _autoSelectFirstClass(next.classes);
        },
        builder: (context, vm) {
          _students = vm.students;
          _autoSelectFirstClass(vm.classes);

          // ── Loading ──
          if (vm.isLoadingClasses && vm.classes.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          // ── Error ──
          if (vm.classError != null && vm.classes.isEmpty) {
            return Center(
              child: CustomErrorWidget(message: vm.classError!, onRetry: _loadData),
            );
          }

          // ── No class assigned ──
          if (vm.classes.isEmpty) {
            return _NoClassState(user: vm.user);
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: _C.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Hero class card
                      if (_activeClass != null)
                        FadeTransition(
                          opacity: _heroFade,
                          child: _HeroClassCard(
                            classModel: _activeClass!,
                            studentCount: _students.length,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // 2. Quick actions
                      if (_activeClass != null) ...[
                        _SectionLabel(label: 'Quick Actions'),
                        const SizedBox(height: 12),
                        _QuickActionsRow(
                          onAttendance: _goAttendance,
                          onExams: _goExams,
                          onMarks: _goMarks,
                          onRollNo: () => _showBulkRollNumberUpdate(_activeClass!, _students),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 3. Students section
                      _SectionLabel(label: 'Students'),
                      const SizedBox(height: 12),

                      // Search bar
                      _SearchBar(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchTerm = v),
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() => _searchTerm = '');
                        },
                      ),
                      const SizedBox(height: 12),

                      // Students body
                      if (vm.isLoadingStudents && _students.isEmpty)
                        const _StudentsLoading()
                      else if (_students.isEmpty && _activeClass != null)
                        const _EmptyStudents()
                      else if (_students.isEmpty)
                        const _SelectClassPrompt()
                      else ...[
                        // Stats row
                        _StatsRow(
                          total: _students.length,
                          boys: _boysCount,
                          girls: _girlsCount,
                        ),
                        const SizedBox(height: 12),

                        // Search empty state
                        if (_filtered.isEmpty && _searchTerm.isNotEmpty)
                          _SearchEmpty(query: _searchTerm)
                        else
                          _StudentList(
                            students: _filtered,
                            onTap: _showStudentSheet,
                          ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Hero Class Card
// ─────────────────────────────────────────────────────────────────────────────
class _HeroClassCard extends StatelessWidget {
  final ClassModel classModel;
  final int studentCount;
  const _HeroClassCard({required this.classModel, required this.studentCount});

  @override
  Widget build(BuildContext context) {
    final section = classModel.section;
    final display = classModel.displayName ?? classModel.name;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _C.r24,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.32),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration icon
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              Icons.class_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 5),
                    const Text(
                      'Class Teacher',
                      style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Class name
              Text(
                display,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),

              if (section != null && section.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Section $section',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _HeroStat(
                    icon: Icons.people_rounded,
                    value: '$studentCount',
                    label: 'Students',
                  ),
                  const SizedBox(width: 28),
                  if (classModel.capacity != null)
                    _HeroStat(
                      icon: Icons.event_seat_rounded,
                      value: '${classModel.capacity}',
                      label: 'Capacity',
                    ),
                  if (classModel.subjects?.isNotEmpty ?? false) ...[
                    const SizedBox(width: 28),
                    _HeroStat(
                      icon: Icons.book_rounded,
                      value: '${classModel.subjects!.length}',
                      label: 'Subjects',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white60),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Quick Actions Row
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAttendance;
  final VoidCallback onExams;
  final VoidCallback onMarks;
  final VoidCallback onRollNo;
  const _QuickActionsRow({
    required this.onAttendance,
    required this.onExams,
    required this.onMarks,
    required this.onRollNo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionCard(
          icon: Icons.fact_check_rounded,
          title: 'Attendance',
          subtitle: 'Mark today',
          color: _C.primary,
          bg: _C.indigo10,
          onTap: onAttendance,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(
          icon: Icons.assignment_rounded,
          title: 'Exams',
          subtitle: 'Schedule',
          color: _C.secondary,
          bg: _C.purple10,
          onTap: onExams,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(
          icon: Icons.edit_note_rounded,
          title: 'Marks',
          subtitle: 'Enter marks',
          color: _C.teal,
          bg: _C.teal10,
          onTap: onMarks,
        )),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(
          icon: Icons.numbers_rounded,
          title: 'Roll No',
          subtitle: 'Update',
          color: _C.sky,
          bg: _C.sky10,
          onTap: onRollNo,
        )),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.bg,
            borderRadius: _C.r20,
            boxShadow: _C.shadowSm(),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.14),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _C.text1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 10, color: _C.text3),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r16,
        boxShadow: _C.shadowSm(),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: _C.text1),
        decoration: InputDecoration(
          hintText: 'Search by name, roll no, admission no...',
          hintStyle: const TextStyle(fontSize: 13, color: _C.text3),
          prefixIcon: const Icon(Icons.search_rounded, color: _C.text3, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _C.text3, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int total;
  final int boys;
  final int girls;
  const _StatsRow({required this.total, required this.boys, required this.girls});

  @override
  Widget build(BuildContext context) {
    final others = total - boys - girls;
    return Row(
      children: [
        _StatChip(label: 'Total', value: '$total', color: _C.primary, bg: _C.indigo10),
        const SizedBox(width: 8),
        _StatChip(label: 'Boys', value: '$boys', color: _C.sky, bg: _C.sky10),
        const SizedBox(width: 8),
        _StatChip(label: 'Girls', value: '$girls', color: _C.secondary, bg: _C.purple10),
        if (others > 0) ...[
          const SizedBox(width: 8),
          _StatChip(label: 'Other', value: '$others', color: _C.teal, bg: _C.teal10),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: _C.r12),
      child: Row(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: _C.text2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Student List
// ─────────────────────────────────────────────────────────────────────────────
class _StudentList extends StatelessWidget {
  final List<StudentModel> students;
  final ValueChanged<StudentModel> onTap;
  const _StudentList({required this.students, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: students.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < students.length - 1 ? 8 : 0),
          child: _StudentCard(student: e.value, index: e.key, onTap: () => onTap(e.value)),
        );
      }).toList(),
    );
  }
}

class _StudentCard extends StatefulWidget {
  final StudentModel student;
  final int index;
  final VoidCallback onTap;
  const _StudentCard({required this.student, required this.index, required this.onTap});

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  // Avatar colors rotate through palette
  static const _avatarColors = [
    Color(0xFF059669), Color(0xFF34D399), Color(0xFF0EA5E9),
    Color(0xFF14B8A6), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFF22C55E), Color(0xFFEC4899),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _initials {
    final parts = widget.student.fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Color get _avatarColor => _avatarColors[widget.index % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final roll = s.rollNumber?.isNotEmpty == true ? s.rollNumber! : '-';
    final admNo = s.admissionNo?.isNotEmpty == true ? s.admissionNo! : '-';

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: _C.r16,
            boxShadow: _C.shadowSm(),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _avatarColor.withOpacity(0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(14)),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.text1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.pin_outlined, size: 12, color: _C.text3),
                        const SizedBox(width: 3),
                        Text('Roll $roll', style: const TextStyle(fontSize: 11, color: _C.text2)),
                        const SizedBox(width: 10),
                        const Icon(Icons.badge_outlined, size: 12, color: _C.text3),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            admNo,
                            style: const TextStyle(fontSize: 11, color: _C.text2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron
              const Icon(Icons.chevron_right_rounded, size: 20, color: _C.text3),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Student Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _StudentBottomSheet extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onViewProfile;
  final VoidCallback onAttendanceHistory;

  const _StudentBottomSheet({
    required this.student,
    required this.onViewProfile,
    required this.onAttendanceHistory,
  });

  Future<void> _callParent(String phone, BuildContext ctx) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Could not launch phone app')),
          );
        }
      }
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  String get _initials {
    final parts = student.fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final phone = student.parentPhone?.isNotEmpty == true
        ? student.parentPhone
        : student.phoneNumber?.isNotEmpty == true
            ? student.phoneNumber
            : null;
    final parentName = student.parentName?.isNotEmpty == true
        ? student.parentName
        : student.fatherFullName?.isNotEmpty == true
            ? student.fatherFullName
            : student.guardian?.isNotEmpty == true
                ? student.guardian
                : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Student avatar + name header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _C.indigo10,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _C.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _C.text1)),
                      const SizedBox(height: 2),
                      Text(student.studentCode,
                          style: const TextStyle(fontSize: 12, color: _C.text3)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: _C.divider),

          // Student info
          _SheetSection(title: 'Student Information'),
          _InfoRow(icon: Icons.pin_rounded, label: 'Roll Number',    value: student.rollNumber?.isNotEmpty == true ? student.rollNumber! : '—'),
          _InfoRow(icon: Icons.badge_rounded, label: 'Admission No', value: student.admissionNo?.isNotEmpty == true ? student.admissionNo! : '—'),
          if (student.gender?.isNotEmpty == true)
            _InfoRow(icon: Icons.person_outline_rounded, label: 'Gender', value: _capitalize(student.gender!)),
          if (student.bloodGroup?.isNotEmpty == true)
            _InfoRow(icon: Icons.water_drop_outlined, label: 'Blood Group', value: student.bloodGroup!),

          const Divider(height: 1, color: _C.divider),

          // Parent info
          _SheetSection(title: 'Parent Information'),
          if (parentName != null)
            _InfoRow(icon: Icons.family_restroom_rounded, label: 'Parent Name', value: parentName),
          if (phone != null)
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
          if (parentName == null && phone == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text('No parent information available', style: TextStyle(fontSize: 13, color: _C.text3)),
            ),

          const Divider(height: 1, color: _C.divider),

          // Quick actions
          _SheetSection(title: 'Quick Actions'),
          if (phone != null)
            _SheetAction(
              icon: Icons.call_rounded,
              label: 'Call Parent',
              color: _C.success,
              bg: _C.green10,
              onTap: () => _callParent(phone, context),
            ),
          _SheetAction(
            icon: Icons.person_rounded,
            label: 'View Profile',
            color: _C.primary,
            bg: _C.indigo10,
            onTap: onViewProfile,
          ),
          _SheetAction(
            icon: Icons.calendar_today_rounded,
            label: 'Attendance History',
            color: _C.secondary,
            bg: _C.purple10,
            onTap: onAttendanceHistory,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

class _SheetSection extends StatelessWidget {
  final String title;
  const _SheetSection({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _C.text3,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.text3),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _C.text3)),
                const SizedBox(height: 1),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.text1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: bg, borderRadius: _C.r12),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.text1)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _C.text3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: _C.text1,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Loading States
// ─────────────────────────────────────────────────────────────────────────────
class _NoClassState extends StatelessWidget {
  final UserModel? user;
  const _NoClassState({this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _C.indigo10,
                borderRadius: const BorderRadius.all(Radius.circular(28)),
              ),
              child: const Icon(Icons.class_outlined, size: 44, color: _C.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Class Assigned',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.text1),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are not assigned as class teacher\nfor any class yet.',
              style: TextStyle(fontSize: 14, color: _C.text2, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStudents extends StatelessWidget {
  const _EmptyStudents();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r20,
        boxShadow: _C.shadowSm(),
      ),
      child: const Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 52, color: _C.text3),
          SizedBox(height: 14),
          Text('No Students Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.text1)),
          SizedBox(height: 6),
          Text('No students are enrolled in this class.',
              style: TextStyle(fontSize: 13, color: _C.text2), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SelectClassPrompt extends StatelessWidget {
  const _SelectClassPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(color: _C.surface, borderRadius: _C.r20, boxShadow: _C.shadowSm()),
      child: const Column(
        children: [
          Icon(Icons.touch_app_rounded, size: 52, color: _C.text3),
          SizedBox(height: 14),
          Text('Select a Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.text1)),
          SizedBox(height: 6),
          Text('Tap a class card to load students.',
              style: TextStyle(fontSize: 13, color: _C.text2), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  final String query;
  const _SearchEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(color: _C.surface, borderRadius: _C.r20, boxShadow: _C.shadowSm()),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 52, color: _C.text3),
          const SizedBox(height: 14),
          const Text('No Results Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _C.text1)),
          const SizedBox(height: 6),
          Text(
            'No student matches "$query".\nTry a different name or number.',
            style: const TextStyle(fontSize: 13, color: _C.text2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StudentsLoading extends StatelessWidget {
  const _StudentsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(child: LoadingWidget()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// View Model
// ─────────────────────────────────────────────────────────────────────────────
class _VM {
  final List<ClassModel> classes;
  final List<StudentModel> students;
  final bool isLoadingClasses;
  final bool isLoadingStudents;
  final String? classError;
  final UserModel? user;

  const _VM({
    required this.classes,
    required this.students,
    required this.isLoadingClasses,
    required this.isLoadingStudents,
    this.classError,
    this.user,
  });
}