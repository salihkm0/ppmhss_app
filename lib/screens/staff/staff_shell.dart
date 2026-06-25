import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:school_management/widgets/dashboard/staff_dashboard.dart';
import 'package:school_management/screens/staff/my_classes_page.dart';
import 'package:school_management/screens/staff/my_duties_page.dart';
import 'package:school_management/screens/staff/staff_exams_page.dart';
import 'package:school_management/screens/notifications/notification_list_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,          label: 'Home'),
    _NavItem(icon: Icons.class_outlined,     activeIcon: Icons.class_rounded,         label: 'Classes'),
    _NavItem(icon: Icons.assignment_outlined,activeIcon: Icons.assignment_rounded,    label: 'Exams'),
    _NavItem(icon: Icons.work_outline,       activeIcon: Icons.work_rounded,          label: 'Duties'),
    _NavItem(icon: Icons.notifications_none, activeIcon: Icons.notifications_rounded, label: 'Alerts'),
  ];

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Each page owns its own Scaffold/AppBar — we just wrap them in IndexedStack
    // so state is preserved across tab switches.
    return Stack(
      children: [
        IndexedStack(
          index: _currentIndex,
          children: [
            _StaffHomePage(onSwitchTab: _onTabTapped),
            const MyClassesPage(),
            const StaffExamsPage(classId: '', className: ''),
            const MyDutiesPage(),
            const NotificationListScreen(),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomNav(),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: _items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final selected = _currentIndex == idx;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTapped(idx),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 22,
                          color: selected ? AppTheme.primaryColor : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primaryColor : Colors.grey[500],
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Thin wrapper that adds the staff-specific AppBar + dashboard body
class _StaffHomePage extends StatelessWidget {
  final void Function(int) onSwitchTab;
  const _StaffHomePage({required this.onSwitchTab});

  Future<void> _logout(BuildContext context) async {
    final store = StoreProvider.of<AppState>(context, listen: false);
    await store.dispatch(logoutThunk(LogoutAction()));
    if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String?>(
      converter: (s) => s.state.auth.user?.name,
      builder: (context, name) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          appBar: AppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greeting()}, ${(name ?? 'Staff').split(' ').first}!',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'PPMHSS · Staff',
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
                tooltip: 'Profile',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'settings') Navigator.pushNamed(context, '/settings');
                  if (v == 'help') Navigator.pushNamed(context, '/help-support');
                  if (v == 'logout') _logout(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(children: [
                      Icon(Icons.settings_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'help',
                    child: Row(children: [
                      Icon(Icons.help_outline, size: 18),
                      SizedBox(width: 10),
                      Text('Help & Support'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          body: StaffDashboard(
            onSwitchTab: onSwitchTab,
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
