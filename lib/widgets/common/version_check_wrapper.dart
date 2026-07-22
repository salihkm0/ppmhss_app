import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:school_management/services/version_service.dart';
import 'package:school_management/utils/theme.dart';
import 'package:school_management/widgets/common/loading_widget.dart';

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  const VersionCheckWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  final VersionService _versionService = VersionService();
  bool _isLoading = true;
  VersionCheckResult? _result;
  bool _dismissedSoftUpdate = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final result = await _versionService.checkVersion();
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (e) {
      print('Failed to get app version: $e');
    }
    setState(() {
      _result = result;
      _isLoading = false;
    });
  }

  Future<void> _launchStore() async {
    if (_result == null) return;
    final urlStr = _versionService.getStoreUrl(_result!);
    if (urlStr.isEmpty) return;

    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback or error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the store link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LoadingWidget(),
        ),
      );
    }

    if (_result != null && _result!.status == VersionStatus.forceUpdate) {
      return _buildForceUpdateScreen();
    }

    // For soft updates, show a dialog ON TOP of the child if not dismissed yet
    // Since we are wrapping the app root, we can use a Stack to overlay the dialog 
    // or just let the app render and show the dialog using WidgetsBinding.
    
    if (_result != null && _result!.status == VersionStatus.softUpdate && !_dismissedSoftUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSoftUpdateDialog();
      });
    }

    return widget.child;
  }

  Widget _buildForceUpdateScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.system_update_rounded,
                size: 100,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 32),
              const Text(
                'Update Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _result?.updateMessage ?? 'A new version of the app is available. Please update to continue using the app.',
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
                child: ElevatedButton(
                  onPressed: _launchStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              if (_appVersion.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'v$_appVersion',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSoftUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Update Available'),
          content: Text(_result?.updateMessage ?? 'A new version of the app is available. Would you like to update now?'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _dismissedSoftUpdate = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Later', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _dismissedSoftUpdate = true;
                });
                Navigator.of(context).pop();
                _launchStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}
