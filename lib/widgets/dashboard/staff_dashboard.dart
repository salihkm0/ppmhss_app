import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/actions/dashboard_actions.dart';
import 'package:school_management/models/dashboard_model.dart';
import 'package:school_management/utils/formatters.dart';
import 'package:school_management/widgets/common/loading_widget.dart';
import 'package:school_management/widgets/common/error_widget.dart';
import 'package:school_management/services/socket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF5F7FA);
  static const surface   = Color(0xFFFFFFFF);
  static const accent    = Color(0xFF059669); // emerald
  static const accentSoft= Color(0xFFECFDF5);
  static const blue      = Color(0xFF3B82F6);
  static const blueSoft  = Color(0xFFEFF6FF);
  static const amber     = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFFFBEB);
  static const red       = Color(0xFFEF4444);
  static const redSoft   = Color(0xFFFEF2F2);
  static const t1        = Color(0xFF0F172A); // primary text
  static const t2        = Color(0xFF64748B); // secondary text
  static const t3        = Color(0xFFCBD5E1); // muted
  static const border    = Color(0xFFE8EDF2);

  static const r8  = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));

  static List<BoxShadow> shadow = [
    BoxShadow(color: Color(0xFF0F172A).withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class StaffDashboard extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const StaffDashboard({super.key, this.onSwitchTab});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _setupSocket();
  }

  Future<void> _load() async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(fetchStaffDashboardThunk());
  }

  void _setupSocket() {
    SocketService().addListener('dashboard:updated', (data) {
      if (mounted) _load();
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dayQuote() {
    const q = [
      'Ready to inspire young minds today?',
      'Every lesson changes a life.',
      'Your patience builds their future.',
      'Great teachers create great futures.',
      'Today is another chance to make a difference.',
    ];
    return q[DateTime.now().day % q.length];
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _VM>(
      converter: (s) => _VM(
        data: s.state.dashboard.staffData,
        isLoading: s.state.dashboard.isLoading,
        error: s.state.dashboard.error,
      ),
      builder: (context, vm) {
        if (vm.isLoading && vm.data == null) {
          return const Center(child: LoadingWidget());
        }
        if (vm.error != null && vm.data == null) {
          return Center(child: CustomErrorWidget(message: vm.error!, onRetry: _load));
        }
        if (vm.data == null) return const Center(child: LoadingWidget());

        final d = vm.data!;
        return RefreshIndicator(
          onRefresh: _load,
          color: _C.accent,
          backgroundColor: _C.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ── Greeting Banner ──────────────────────────────────────
                    _GreetingBanner(
                      name: d.staffInfo.name,
                      staffCode: d.staffInfo.staffCode,
                      role: d.staffInfo.role,
                      greeting: _greeting(),
                      quote: _dayQuote(),
                      academicYear: d.academicYear?.name,
                    ),
                    const SizedBox(height: 20),

                    // ── Class Teacher For ────────────────────────────────────
                    if (d.classTeacherInfo != null) ...[
                      _SectionTitle(title: 'Class Teacher For'),
                      const SizedBox(height: 10),
                      _ClassTeacherCard(info: d.classTeacherInfo!),
                      const SizedBox(height: 20),
                    ],

                    // ── Subjects Taught ──────────────────────────────────────
                    if ((d.subjectClasses ?? []).isNotEmpty) ...[
                      _SectionTitle(title: 'Subjects Taught'),
                      const SizedBox(height: 10),
                      _SubjectsSection(classes: d.subjectClasses!),
                      const SizedBox(height: 20),
                    ],

                    // ── Quick Actions ────────────────────────────────────────
                    _SectionTitle(title: 'Quick Actions'),
                    const SizedBox(height: 10),
                    _QuickActionsRow(
                      onAttendance: () => widget.onSwitchTab?.call(1),
                      onMarks: () => widget.onSwitchTab?.call(2),
                      onExams: () => widget.onSwitchTab?.call(2),
                      onDuties: () => widget.onSwitchTab?.call(3),
                    ),
                    const SizedBox(height: 20),

                    // ── Staff Information ────────────────────────────────────
                    _SectionTitle(title: 'Staff Information'),
                    const SizedBox(height: 10),
                    _StaffInfoCard(
                      info: d.staffInfo,
                      subjectsTaught: d.quickStats['subjectsTaught'],
                    ),
                    const SizedBox(height: 20),

                    // ── Recent Activities ────────────────────────────────────
                    if (d.recentActivities.isNotEmpty) ...[
                      _SectionTitle(title: 'Recent Activities'),
                      const SizedBox(height: 10),
                      _ActivitiesCard(activities: d.recentActivities),
                    ],

                    const SizedBox(height: 8),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Banner
// ─────────────────────────────────────────────────────────────────────────────
class _GreetingBanner extends StatelessWidget {
  final String name, staffCode, role, greeting, quote;
  final String? academicYear;

  const _GreetingBanner({
    required this.name,
    required this.staffCode,
    required this.role,
    required this.greeting,
    required this.quote,
    this.academicYear,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;
    final today = DateFormat('EEE, d MMM').format(DateTime.now());
    final roleLabel = role.isNotEmpty
        ? role[0].toUpperCase() + role.substring(1)
        : 'Staff';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _C.r20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: _C.r20,
            ),
            child: Text(
              today,
              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$greeting,',
            style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 2),
          Text(
            firstName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
          ),
          const SizedBox(height: 10),
          // Divider line
          Container(height: 1, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 10),
          Row(
            children: [
              _BannerChip(label: staffCode),
              const SizedBox(width: 8),
              _BannerChip(label: roleLabel),
              if (academicYear != null && academicYear!.isNotEmpty) ...[
                const SizedBox(width: 8),
                _BannerChip(label: academicYear!),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quote,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final String label;
  const _BannerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: _C.r8,
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _C.t2,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Class Teacher Card
// ─────────────────────────────────────────────────────────────────────────────
class _ClassTeacherCard extends StatelessWidget {
  final ClassTeacherInfo info;
  const _ClassTeacherCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final cls = info.classes.isNotEmpty ? info.classes.first : null;
    final avg = double.tryParse(info.averageAttendance) ?? 0.0;
    final attColor = avg >= 75 ? _C.accent : (avg >= 60 ? _C.amber : _C.red);

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r16,
        border: Border.all(color: _C.border),
        boxShadow: _C.shadow,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: _C.accentSoft, borderRadius: _C.r12),
                  child: const Icon(Icons.class_rounded, color: _C.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls?.name ?? 'No Class Assigned',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _C.t1),
                      ),
                      const SizedBox(height: 2),
                      Text('Class Teacher', style: const TextStyle(fontSize: 12, color: _C.t2)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _C.accentSoft, borderRadius: _C.r8),
                  child: Text(
                    '${cls?.studentCount ?? 0} students',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.accent),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(height: 1, color: _C.border),
          // Attendance row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text('Avg Attendance', style: TextStyle(fontSize: 12, color: _C.t2, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  '${avg.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: attColor),
                ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: _C.r8,
              child: LinearProgressIndicator(
                value: (avg / 100).clamp(0.0, 1.0),
                backgroundColor: _C.border,
                valueColor: AlwaysStoppedAnimation<Color>(attColor),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subjects Taught
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectsSection extends StatelessWidget {
  final List<SubjectClass> classes;
  const _SubjectsSection({required this.classes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r16,
        border: Border.all(color: _C.border),
        boxShadow: _C.shadow,
      ),
      child: Column(
        children: classes.asMap().entries.map((e) {
          final isLast = e.key == classes.length - 1;
          final cls = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class name pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _C.blueSoft, borderRadius: _C.r8),
                      child: Text(
                        cls.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _C.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Subject chips
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: cls.subjects.map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _C.bg,
                            borderRadius: _C.r8,
                            border: Border.all(color: _C.border),
                          ),
                          child: Text(s, style: const TextStyle(fontSize: 11, color: _C.t2, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: _C.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onAttendance, onMarks, onExams, onDuties;
  const _QuickActionsRow({
    required this.onAttendance,
    required this.onMarks,
    required this.onExams,
    required this.onDuties,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QA('Attendance', Icons.fact_check_outlined, _C.accent,  _C.accentSoft, onAttendance),
      _QA('Marks',      Icons.edit_outlined,        _C.blue,   _C.blueSoft,   onMarks),
      _QA('Exams',      Icons.assignment_outlined,  _C.amber,  _C.amberSoft,  onExams),
      _QA('Duties',     Icons.work_outline,         Color(0xFF8B5CF6), Color(0xFFF5F3FF), onDuties),
    ];

    return Row(
      children: actions.asMap().entries.map((e) {
        final qa = e.value;
        final isLast = e.key == actions.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: _QAButton(qa: qa),
          ),
        );
      }).toList(),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _QA(this.label, this.icon, this.color, this.bg, this.onTap);
}

class _QAButton extends StatefulWidget {
  final _QA qa;
  const _QAButton({required this.qa});

  @override
  State<_QAButton> createState() => _QAButtonState();
}

class _QAButtonState extends State<_QAButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.qa.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: _C.r16,
            border: Border.all(color: _C.border),
            boxShadow: _C.shadow,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: widget.qa.bg, borderRadius: _C.r12),
                child: Icon(widget.qa.icon, color: widget.qa.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                widget.qa.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.t1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff Information
// ─────────────────────────────────────────────────────────────────────────────
class _StaffInfoCard extends StatelessWidget {
  final StaffInfo info;
  final dynamic subjectsTaught;
  const _StaffInfoCard({required this.info, this.subjectsTaught});

  @override
  Widget build(BuildContext context) {
    final role = info.role.isNotEmpty
        ? info.role[0].toUpperCase() + info.role.substring(1)
        : '-';

    final rows = [
      ('Full Name',       info.name.isNotEmpty ? info.name : '-'),
      ('Staff Code',      info.staffCode.isNotEmpty ? info.staffCode : '-'),
      ('Role',            role),
      ('Email',           info.email ?? '-'),
      ('Phone',           info.phone ?? '-'),
      ('Subjects Taught', '${subjectsTaught ?? 0}'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r16,
        border: Border.all(color: _C.border),
        boxShadow: _C.shadow,
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final label = e.value.$1;
          final value = e.value.$2;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 115,
                      child: Text(label, style: const TextStyle(fontSize: 12, color: _C.t2, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.t1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: _C.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activities
// ─────────────────────────────────────────────────────────────────────────────
class _ActivitiesCard extends StatelessWidget {
  final List<RecentActivity> activities;
  const _ActivitiesCard({required this.activities});

  Color _dot(String severity) {
    switch (severity) {
      case 'success': return _C.accent;
      case 'warning': return _C.amber;
      case 'error':   return _C.red;
      default:        return _C.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = activities.take(6).toList();
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: _C.r16,
        border: Border.all(color: _C.border),
        boxShadow: _C.shadow,
      ),
      child: Column(
        children: visible.asMap().entries.map((e) {
          final isLast = e.key == visible.length - 1;
          final act = e.value;
          final dotColor = _dot(act.severity);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dot
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _C.t1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (act.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              act.description,
                              style: const TextStyle(fontSize: 12, color: _C.t2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatTimeAgo(act.timestamp),
                            style: const TextStyle(fontSize: 11, color: _C.t3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 35, color: _C.border),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────────
class _VM {
  final StaffDashboardData? data;
  final bool isLoading;
  final String? error;
  _VM({this.data, required this.isLoading, this.error});
}
