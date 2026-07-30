import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      deviceData['appVersion'] = '${packageInfo.version}+${packageInfo.buildNumber}';

      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        deviceData['deviceName'] = webInfo.browserName.name;
        deviceData['osVersion'] = webInfo.appVersion;
        deviceData['platform'] = 'web';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        deviceData['deviceName'] = '${androidInfo.brand} ${androidInfo.model}';
        deviceData['osVersion'] = 'Android ${androidInfo.version.release}';
        deviceData['platform'] = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceData['deviceName'] = iosInfo.name;
        deviceData['osVersion'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        deviceData['platform'] = 'ios';
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }

    return deviceData;
  }
}
