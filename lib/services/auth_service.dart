import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/user_model.dart';
import 'package:school_management/utils/device_info_helper.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'password': password,
        'rememberMe': rememberMe,
      };
      
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      if (deviceInfo.isNotEmpty) {
        requestBody['deviceInfo'] = deviceInfo;
      }
      
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      } else if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }
      
      print('Login request body: $requestBody');
      
      final response = await _api.post(ApiConfig.login, data: requestBody);
      print('Login response: ${response.data}');
      
      return response.data;
    } on DioException catch (e) {
      print('Login error: ${e.response?.data}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> registerParent(Map<String, dynamic> parentData) async {
    try {
      final response = await _api.post(ApiConfig.registerParent, data: parentData);
      return response.data;
    } on DioException catch (e) {
      print('Register Parent error: ${e.response?.data}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await _api.post(ApiConfig.logout);
      return response.data;
    } on DioException catch (e) {
      print('Logout error: ${e.message}');
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _api.get(ApiConfig.me);
      final userData = response.data['user'] ?? response.data;
      if (response.data['staff'] != null && response.data['staff']['_id'] != null) {
        userData['staffId'] = response.data['staff']['_id'];
      }
      return UserModel.fromJson(userData);
    } on DioException catch (e) {
      print('GetMe error: ${e.message}');
      throw Exception('Failed to get user info');
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _api.put(ApiConfig.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      print('Change password error: ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _api.post(ApiConfig.forgotPassword, data: {'email': email});
      return response.data;
    } on DioException catch (e) {
      print('Forgot password error: ${e.response?.data}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to send OTP');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _api.post(ApiConfig.resetPassword, data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      print('Reset password error: ${e.response?.data}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to reset password');
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
      if (deviceInfo.isNotEmpty) {
        data['deviceInfo'] = deviceInfo;
      }
      final response = await _api.put(ApiConfig.updateProfile, data: data);
      return response.data;
    } on DioException catch (e) {
      print('Update profile error: ${e.message}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Profile update failed');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkAppVersion({required String platform, required String version}) async {
    try {
      final response = await _api.get('${ApiConfig.appVersion}?platform=$platform&version=$version');
      print('Check app version response: ${response.data}');
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      print('Check app version error: ${e.response?.data ?? e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAppVersionConfig(Map<String, dynamic> data) async {
    try {
      final response = await _api.put(ApiConfig.appVersion, data: data);
      return response.data;
    } on DioException catch (e) {
      print('Update app version error: ${e.message}');
      if (e.response?.data != null) {
        throw Exception(e.response?.data['message'] ?? 'Failed to update app version config');
      }
      rethrow;
    }
  }
}