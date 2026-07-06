import 'package:school_management/services/api_service.dart';
import 'package:school_management/config/api_config.dart';
import 'package:school_management/models/user_model.dart';
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
      final response = await _api.post(ApiConfig.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      print('Change password error: ${e.message}');
      rethrow;
    }
  }
}