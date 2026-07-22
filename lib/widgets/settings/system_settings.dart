import 'package:flutter/material.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/services/auth_service.dart';
import 'dart:io' show Platform;

class SystemSettings extends StatefulWidget {
  const SystemSettings({super.key});

  @override
  State<SystemSettings> createState() => _SystemSettingsState();
}

class _SystemSettingsState extends State<SystemSettings> {
  bool _maintenanceMode = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _gradingSystem = [
    {'grade': 'A+', 'min': 90, 'max': 100, 'color': Colors.green},
    {'grade': 'A', 'min': 80, 'max': 89, 'color': Colors.lightGreen},
    {'grade': 'B+', 'min': 70, 'max': 79, 'color': Colors.blue},
    {'grade': 'B', 'min': 60, 'max': 69, 'color': Colors.lightBlue},
    {'grade': 'C+', 'min': 50, 'max': 59, 'color': Colors.orange},
    {'grade': 'C', 'min': 40, 'max': 49, 'color': Colors.deepOrange},
    {'grade': 'D+', 'min': 30, 'max': 39, 'color': Colors.red},
    {'grade': 'D', 'min': 20, 'max': 29, 'color': Colors.redAccent},
    {'grade': 'E', 'min': 0, 'max': 19, 'color': Colors.grey},
  ];

  Future<void> _showAppUpdatesDialog() async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    Map<String, dynamic>? currentConfig;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );
      
      currentConfig = await AuthService().checkAppVersion(platform: platform, version: '0.0.0');
      
      if (!mounted) return;
      Navigator.pop(context); // close loading
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading
      _showMessage('Failed to load config: $e');
      return;
    }

    if (!mounted) return;

    final minController = TextEditingController(text: currentConfig['minVersion']);
    final latestController = TextEditingController(text: currentConfig['latestVersion']);
    final storeUrlController = TextEditingController(text: currentConfig['storeUrl']);
    
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('App Updates Config ($platform)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: latestController,
                  decoration: const InputDecoration(
                    labelText: 'Latest Version (e.g. 1.0.5)',
                    helperText: 'Soft update for older versions',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Required Version (e.g. 1.0.0)',
                    helperText: 'Forced update for older versions',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: storeUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Store URL',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await AuthService().updateAppVersionConfig({
                    'platform': platform,
                    'minVersion': minController.text,
                    'latestVersion': latestController.text,
                    'storeUrl': storeUrlController.text,
                  });
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Updates Config saved successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // General Settings
        _buildSection(
          title: 'General Settings',
          icon: Icons.settings_outlined,
          children: [
            _buildSwitchTile(
              title: 'Maintenance Mode',
              subtitle: 'Put the system in maintenance mode',
              value: _maintenanceMode,
              onChanged: (value) => setState(() => _maintenanceMode = value),
            ),
            _buildButtonTile(
              title: 'App Updates',
              subtitle: 'Configure forced & optional updates',
              buttonText: 'Configure',
              buttonColor: AppTheme.primaryColor,
              onPressed: _showAppUpdatesDialog,
            ),
            _buildButtonTile(
              title: 'Backup Database',
              subtitle: 'Create a backup of the database',
              buttonText: 'Backup Now',
              buttonColor: AppTheme.primaryColor,
              onPressed: () => _showMessage('Database backup started...'),
            ),
            _buildButtonTile(
              title: 'Clear Cache',
              subtitle: 'Clear application cache',
              buttonText: 'Clear Cache',
              buttonColor: Colors.orange,
              onPressed: () => _showMessage('Cache cleared successfully'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Grading System
        _buildSection(
          title: 'Grading System',
          icon: Icons.grade_outlined,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildGradeHeader(),
                  ..._gradingSystem.map((grade) => _buildGradeRow(grade)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => _showMessage('Edit grading system (coming soon)'),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit Grading System'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // System Info
        _buildSection(
          title: 'System Information',
          icon: Icons.info_outline,
          children: [
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Build Number', '100'),
            _buildInfoRow('Environment', 'Production'),
            _buildInfoRow('API Status', 'Connected'),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildGradeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('Percentage Range', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildGradeRow(Map<String, dynamic> grade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              grade['grade'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: grade['color'] as Color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('${grade['min']}% - ${grade['max']}%'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}