import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_management/utils/theme.dart';

class UpdateScreen extends StatelessWidget {
  final Map<String, dynamic> updateConfig;
  final VoidCallback? onSkip;

  const UpdateScreen({super.key, required this.updateConfig, this.onSkip});

  Future<void> _launchStore(BuildContext context) async {
    final url = updateConfig['storeUrl'];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store URL not available')),
      );
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store')),
        );
      }
    }
  }

  void _skipUpdate(BuildContext context) {
    if (onSkip != null) {
      onSkip!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForced = updateConfig['forceUpdate'] == true;
    final message = updateConfig['updateMessage'] ?? 'A new version of the app is available. Please update to continue.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.system_update,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Update Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _launchStore(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!isForced) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _skipUpdate(context),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (updateConfig['currentVersion'] != null)
                Text(
                  'v${updateConfig['currentVersion']}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
