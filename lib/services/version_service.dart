import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:school_management/config/api_config.dart';

enum VersionStatus {
  noUpdate,
  softUpdate,
  forceUpdate,
}

class VersionCheckResult {
  final VersionStatus status;
  final String playstoreUrl;
  final String appstoreUrl;
  final String updateMessage;

  VersionCheckResult({
    required this.status,
    required this.playstoreUrl,
    required this.appstoreUrl,
    required this.updateMessage,
  });

  bool get needsUpdate => status != VersionStatus.noUpdate;
}

class VersionService {
  final Dio _dio = Dio();

  /// Compares two semantic version strings (e.g., '1.0.0' and '1.0.1').
  /// Returns 1 if v1 > v2
  /// Returns -1 if v1 < v2
  /// Returns 0 if v1 == v2
  int _compareVersions(String v1, String v2) {
    List<String> v1Parts = v1.split('.');
    List<String> v2Parts = v2.split('.');

    for (int i = 0; i < 3; i++) {
      int p1 = i < v1Parts.length ? (int.tryParse(v1Parts[i]) ?? 0) : 0;
      int p2 = i < v2Parts.length ? (int.tryParse(v2Parts[i]) ?? 0) : 0;
      
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  Future<VersionCheckResult> checkVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentAppVersion = packageInfo.version; // e.g., '1.0.1'
      final platform = Platform.isIOS ? 'ios' : 'android';

      // 2. Fetch config from API
      final response = await _dio.get(
        '${ApiConfig.baseUrl}${ApiConfig.appVersion}',
        queryParameters: {
          'platform': platform,
          'version': currentAppVersion,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final String latestVersion = data['latestVersion'] ?? data['currentVersion'] ?? '1.0.0';
        final String minVersion = data['minVersion'] ?? '1.0.0';
        final bool forceUpdateFlag = data['forceUpdate'] ?? false;
        final String storeUrl = (data['storeUrl'] ?? data['playStoreUrl'] ?? data['playstoreUrl'] ?? data['appStoreUrl'] ?? data['appstoreUrl'] ?? '').toString();
        final String playstoreUrl = (data['playStoreUrl'] ?? data['playstoreUrl'] ?? storeUrl).toString();
        final String appstoreUrl = (data['appStoreUrl'] ?? data['appstoreUrl'] ?? storeUrl).toString();
        final String updateMessage = data['updateMessage'] ?? 'Please update to the latest version.';

        // 3. Determine if we are below the minimum required version (Forced Update)
        if (_compareVersions(currentAppVersion, minVersion) < 0) {
          return VersionCheckResult(
            status: VersionStatus.forceUpdate,
            playstoreUrl: playstoreUrl,
            appstoreUrl: appstoreUrl,
            updateMessage: updateMessage,
          );
        }

        // 4. Determine if we are below the latest version (Soft Update or Forced if forceUpdateFlag)
        if (_compareVersions(currentAppVersion, latestVersion) < 0) {
          return VersionCheckResult(
            status: forceUpdateFlag ? VersionStatus.forceUpdate : VersionStatus.softUpdate,
            playstoreUrl: playstoreUrl,
            appstoreUrl: appstoreUrl,
            updateMessage: updateMessage,
          );
        }

        // Otherwise, no update needed
        return VersionCheckResult(
          status: VersionStatus.noUpdate,
          playstoreUrl: playstoreUrl,
          appstoreUrl: appstoreUrl,
          updateMessage: updateMessage,
        );
      }
      
      // If API fails, fail gracefully (allow user to continue)
      return VersionCheckResult(
        status: VersionStatus.noUpdate,
        playstoreUrl: '',
        appstoreUrl: '',
        updateMessage: '',
      );
    } catch (e) {
      // Print error but don't block the user from using the app if the network fails
      print('Version Check Error: \$e');
      return VersionCheckResult(
        status: VersionStatus.noUpdate,
        playstoreUrl: '',
        appstoreUrl: '',
        updateMessage: '',
      );
    }
  }

  String getStoreUrl(VersionCheckResult result) {
    if (Platform.isIOS) {
      return result.appstoreUrl;
    } else {
      return result.playstoreUrl;
    }
  }
}
