import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthMiddleware extends GetMiddleware {
  final storage = const FlutterSecureStorage();
  
  @override
  int? get priority => 1;

  bool isAuthenticated = false;

  AuthMiddleware() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await storage.read(key: 'jwt_token');
    isAuthenticated = token != null;
  }

  @override
  RouteSettings? redirect(String? route) {
    // If not authenticated and trying to access a protected route
    // Note: Since _checkAuth is async, you normally handle this via a splash screen / auth service.
    // For synchronous middleware, rely on a pre-loaded AuthController state:
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated.value) {
      return const RouteSettings(name: '/login');
    }
    return null; // Proceed
  }
}

class AuthController extends GetxController {
  var isAuthenticated = false.obs;
  var userRole = 'User'.obs;
  final storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _loadAuthStatus();
  }

  Future<void> _loadAuthStatus() async {
    final token = await storage.read(key: 'jwt_token');
    final role = await storage.read(key: 'user_role');
    if (token != null) {
      isAuthenticated.value = true;
      userRole.value = role ?? 'User';
    }
  }

  Future<void> login(String token, String role) async {
    await storage.write(key: 'jwt_token', value: token);
    await storage.write(key: 'user_role', value: role);
    isAuthenticated.value = true;
    userRole.value = role;
  }

  Future<void> logout() async {
    await storage.deleteAll();
    isAuthenticated.value = false;
    userRole.value = 'User';
    Get.offAllNamed('/login');
  }
}
