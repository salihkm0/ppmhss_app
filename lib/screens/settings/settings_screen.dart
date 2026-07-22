import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:school_management/widgets/settings/academic_year_settings.dart';
import 'package:school_management/widgets/settings/system_settings.dart';
import 'package:school_management/store/app_state.dart';
import 'package:school_management/widgets/common/custom_appbar.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/actions/auth_actions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:school_management/screens/settings/privacy_policy_screen.dart';
import 'package:school_management/screens/settings/terms_and_conditions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedTab = 'preferences';
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

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
                if (isAdmin) ...[
                  _buildAdminTabs(),
                  const SizedBox(height: 24),
                ],
                
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
      {'id': 'preferences', 'name': 'Preferences', 'icon': Icons.tune, 'color': Colors.blue},
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

  Widget _buildAppPreferences() {
    return StoreConnector<AppState, AppState>(
      converter: (store) => store.state,
      builder: (context, state) {
        final user = state.auth.user;
        final preferences = user?.preferences ?? {};
        final bool notificationsEnabled = preferences['notificationsEnabled'] ?? true;
        final bool biometricEnabled = preferences['biometricEnabled'] ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'App Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Enable Notifications',
                    value: notificationsEnabled,
                    onChanged: (val) async {
                      try {
                        await AuthService().updateProfile({
                          'preferences': {'notificationsEnabled': val},
                        });
                        if (context.mounted) {
                          StoreProvider.of<AppState>(context).dispatch(getMeThunk(GetMeAction()));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _buildSwitchTile(
                    icon: Icons.fingerprint,
                    title: 'Enable Biometric Login',
                    value: biometricEnabled,
                    onChanged: (val) async {
                      try {
                        await AuthService().updateProfile({
                          'preferences': {'biometricEnabled': val},
                        });
                        if (context.mounted) {
                          StoreProvider.of<AppState>(context).dispatch(getMeThunk(GetMeAction()));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Support & About',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildActionTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Connect to Developer',
                    subtitle: 'WhatsApp support',
                    onTap: () async {
                      final uri = Uri.parse("https://wa.me/918157024638");
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  _buildActionTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                    ),
                    title: const Text('App Details', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      _packageInfo != null
                          ? 'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                          : 'Loading version...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[700], size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildContent(bool isAdmin) {
    if (isAdmin) {
      switch (_selectedTab) {
        case 'academic-years':
          return const AcademicYearSettings();
        case 'system':
          return const SystemSettings();
        case 'preferences':
        default:
          return _buildAppPreferences();
      }
    } else {
      return _buildAppPreferences();
    }
  }
}