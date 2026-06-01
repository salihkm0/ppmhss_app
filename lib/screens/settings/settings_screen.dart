import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/screens/profile/profile_screen.dart';
import 'package:school_management/widgets/settings/academic_year_settings.dart';
import 'package:school_management/widgets/settings/system_settings.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'profile';

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, String>(
      converter: (store) => store.state.auth.user?.role ?? 'parent',
      builder: (context, userRole) {
        final isAdmin = userRole == 'admin';
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: CustomAppBar(
            title: 'Settings',
            showBackButton: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your account preferences and system configurations',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                
                // Tabs
                if (isAdmin)
                  _buildAdminTabs()
                else
                  _buildUserTab(),
                
                const SizedBox(height: 24),
                
                // Content based on selected tab
                _buildContent(isAdmin),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminTabs() {
    final tabs = [
      {'id': 'profile', 'name': 'Profile', 'icon': Icons.person_outline, 'color': Colors.blue},
      {'id': 'academic-years', 'name': 'Academic Years', 'icon': Icons.calendar_today, 'color': Colors.green},
      {'id': 'system', 'name': 'System', 'icon': Icons.settings, 'color': Colors.purple},
    ];

    return Row(
      children: tabs.map((tab) {
        final isActive = _selectedTab == tab['id'];
        final color = tab['color'] as Color;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = tab['id'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 24,
                    color: isActive ? color : Colors.grey[500],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? color : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserTab() {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = 'profile'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 24,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profile Settings',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Text(
                    'Manage your personal information',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isAdmin) {
    if (isAdmin) {
      switch (_selectedTab) {
        case 'academic-years':
          return const AcademicYearSettings();
        case 'system':
          return const SystemSettings();
        default:
          return const ProfileScreen();
      }
    } else {
      return const ProfileScreen();
    }
  }
}