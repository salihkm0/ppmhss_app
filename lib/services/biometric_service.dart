import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const String _keyEmail = 'bio_email';
  static const String _keyPassword = 'bio_password';
  static const String _keyEnabled = 'bio_enabled';

  static Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to securely log in',
      );
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  static Future<void> enableBiometrics() async {
    await _storage.write(key: _keyEnabled, value: 'true');
  }

  static Future<void> disableBiometrics() async {
    await _storage.delete(key: _keyEnabled);
    await _storage.delete(key: _keyEmail);
    await _storage.delete(key: _keyPassword);
  }

  static Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _keyEnabled);
    return enabled == 'true';
  }

  static Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);
    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
