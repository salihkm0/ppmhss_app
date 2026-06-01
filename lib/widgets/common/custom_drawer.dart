import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/utils/theme.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        final user = state.auth.user;
        final role = user?.role ?? 'parent';

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.8,
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              children: [
                // Modern Header with School and User Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // School Logo and Name
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                'https://res.cloudinary.com/dmjqgjcut/image/upload/v1777479500/school_logo-Photoroom_xcljv5.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.school, color: AppTheme.primaryColor, size: 28),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'PPM HSS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'KOTTUKKARA',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // User Profile Section
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Dashboard
                      _buildModernMenuItem(
                        context: context,
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        },
                      ),
                      
                      const Divider(height: 20, thickness: 1, indent: 16, endIndent: 16),
                      
                      // ==================== ADMIN MENU ====================
                      if (role == 'admin') ...[
                        _buildSectionHeader('MANAGEMENT', Icons.business_center_outlined),
                        
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.people_outline,
                          title: 'Students',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/students');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.person_outline,
                          title: 'Staff',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.class_outlined,
                          title: 'Classes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/classes');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.book_outlined,
                          title: 'Subjects',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/subjects');
                          },
                        ),
                        
                        const SizedBox(height: 8),
                        _buildSectionHeader('ACADEMICS', Icons.school_outlined),
                        
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Attendance',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/attendance');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.assignment_outlined,
                          title: 'Exams',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/exams');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.edit_note_outlined,
                          title: 'Marks Entry',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/marks/entry');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.work_outline,
                          title: 'Duties',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/duties');
                          },
                        ),
                      ],
                      
                      // ==================== STAFF MENU ====================
                      if (role == 'staff') ...[
                        _buildSectionHeader('MY WORK', Icons.work_outline),
                        
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.class_outlined,
                          title: 'My Classes',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff/my-classes');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Attendance',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff/attendance');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.assignment_outlined,
                          title: 'Exams',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff/exams');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.edit_note_outlined,
                          title: 'Marks Entry',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff/mark');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.work_outline,
                          title: 'My Duties',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/staff/my-duties');
                          },
                        ),
                      ],
                      
                      // ==================== PARENT MENU ====================
                      if (role == 'parent') ...[
                        _buildSectionHeader('MY CHILDREN', Icons.family_restroom_outlined),
                        
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.people_outline,
                          title: 'My Children',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/my-children');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Attendance',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/my-child-attendance');
                          },
                        ),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.grade_outlined,
                          title: 'Results',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/my-child-results');
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      _buildSectionHeader('GENERAL', Icons.settings_outlined),
                      
                      // Common for all roles
                      _buildModernMenuItem(
                        context: context,
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        badge: _getUnreadCount(state),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                      _buildModernMenuItem(
                        context: context,
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                      _buildModernMenuItem(
                        context: context,
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/help-support');
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                      
                      // Logout
                      _buildLogoutButton(context),
                      
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                
                // Version Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copyright,
                        size: 10,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '2024 PPM HSS',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    int badge = 0,
  }) {
    final color = isActive ? AppTheme.primaryColor : Colors.grey[700];
    final backgroundColor = isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppTheme.primaryColor.withOpacity(0.12)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? AppTheme.primaryColor : Colors.grey[800],
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (!isActive)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onLogout();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getUnreadCount(AppState state) {
    return state.notifications.unreadCount;
  }
}