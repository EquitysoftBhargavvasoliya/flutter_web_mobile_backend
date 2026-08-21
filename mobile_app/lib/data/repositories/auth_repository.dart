import 'package:get/get.dart' hide Response;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_service.dart';

class AuthRepository {
  final storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password, {String? fcmToken}) async {
    final Map<String, dynamic> body = {
      'email': email,
      'password': password,
      'platform': 'app',
    };
    if (fcmToken != null) body['fcm_token'] = fcmToken;

    final response = await apiService.post('/auth/login', body);
    final data = response.data;
    final token = data['token'];
    if (token == null) return false;

    await storage.write(key: 'jwt_token', value: token);
    await storage.write(key: 'user_role', value: data['user']['role'] ?? 'Buyer');
    await storage.write(key: 'user_id', value: data['user']['id'] ?? '');
    await storage.write(key: 'user_name', value: data['user']['name'] ?? '');
    return true;
  }

  Future<bool> register(String email, String password, String name, String role) async {
    await apiService.post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    });
    return true;
  }

  Future<String> requestPasswordResetOtp(String email) async {
    final response = await apiService.post('/auth/forgot-password', {'email': email});
    return response.data['otp'].toString();
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    await apiService.post('/auth/verify-otp', {'email': email, 'otp': otp});
    return true;
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    await apiService.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'new_password': newPassword,
    });
    return true;
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    Get.offAllNamed('/login');
  }
}
