import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthRepository {
  final ApiClient apiClient = Get.put(ApiClient());
  final storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password, {String? fcmToken}) async {
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'platform': 'web'
    };
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final response = await apiClient.post('/auth/login', body);

    if (response.isOk) {
      final data = response.body;
      final token = data['token'];
      if (token != null) {
        await storage.write(key: 'jwt_token', value: token);
        await storage.write(key: 'user_role', value: data['user']['role'] ?? 'Buyer');
        await storage.write(key: 'user_id', value: data['user']['id'] ?? '');
        await storage.write(key: 'user_name', value: data['user']['name'] ?? '');
        return true;
      }
    } else {
      String error = 'Invalid email or password';
      print('AuthRepository.login failed: status=${response.statusCode}, body=${response.body}');
      try {
        if (response.body != null) {
          final dynamic body = response.body;
          if (body is Map && body['error'] != null) {
            error = body['error'].toString();
          } else if (body is String) {
            final decoded = jsonDecode(body);
            if (decoded is Map && decoded['error'] != null) {
              error = decoded['error'].toString();
            }
          }
        } else if (response.bodyString != null) {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map && decoded['error'] != null) {
            error = decoded['error'].toString();
          }
        }
      } catch (e) {
        print('Error parsing response body: $e');
      }
      throw Exception(error);
    }
    return false;
  }

  Future<bool> register(String email, String password, String name, String role) async {
    final response = await apiClient.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'role': role
    });

    if (response.isOk) {
      return true;
    } else {
      String error = 'Registration failed. Email might be in use.';
      print('AuthRepository.register failed: status=${response.statusCode}, body=${response.body}');
      try {
        if (response.body != null) {
          final dynamic body = response.body;
          if (body is Map && body['error'] != null) {
            error = body['error'].toString();
          } else if (body is String) {
            final decoded = jsonDecode(body);
            if (decoded is Map && decoded['error'] != null) {
              error = decoded['error'].toString();
            }
          }
        } else if (response.bodyString != null) {
          final decoded = jsonDecode(response.bodyString!);
          if (decoded is Map && decoded['error'] != null) {
            error = decoded['error'].toString();
          }
        }
      } catch (e) {
        print('Error parsing response body: $e');
      }
      throw Exception(error);
    }
  }

  Future<String> requestPasswordResetOtp(String email) async {
    final response = await apiClient.post('/auth/forgot-password', {'email': email});
    if (response.isOk) {
      return response.body['otp'].toString();
    }
    throw Exception(_extractError(response, 'Could not send OTP. Check the email and try again.'));
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    final response = await apiClient.post('/auth/verify-otp', {'email': email, 'otp': otp});
    if (response.isOk) return true;
    throw Exception(_extractError(response, 'Invalid or expired OTP.'));
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final response = await apiClient.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
    if (response.isOk) return true;
    throw Exception(_extractError(response, 'Could not reset password.'));
  }

  String _extractError(Response response, String fallback) {
    try {
      final dynamic body = response.body;
      if (body is Map && body['error'] != null) return body['error'].toString();
      if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is Map && decoded['error'] != null) return decoded['error'].toString();
      } else if (response.bodyString != null) {
        final decoded = jsonDecode(response.bodyString!);
        if (decoded is Map && decoded['error'] != null) return decoded['error'].toString();
      }
    } catch (e) {
      print('Error parsing response body: $e');
    }
    return fallback;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    Get.offAllNamed('/login');
  }
}
