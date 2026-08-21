import 'package:get/get.dart' hide Response;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_service.dart';
import '../../core/network/logger.dart';
import '../../core/models/models.dart';

class AdminController extends GetxController {
  final storage = const FlutterSecureStorage();

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var adminName = ''.obs;

  // Sidebar navigation selection: 'dashboard', 'users', 'products', 'orders'
  var activeTab = 'dashboard'.obs;

  // Data lists
  var users = [].obs;
  var products = [].obs;
  var orders = [].obs;

  // Stats
  var totalSalesCount = 0.obs;
  var activeUsersCount = 0.obs;
  var totalRevenue = 0.0.obs;

  int get allProductsCount => products.length;
  int get activeProductsCount => products.where((p) => p['is_active'] ?? true).length;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final token = await storage.read(key: 'jwt_token');
    final role = await storage.read(key: 'user_role');
    final name = await storage.read(key: 'user_name');

    if (token != null && role == 'Admin') {
      isLoggedIn.value = true;
      adminName.value = name ?? 'Admin';
      fetchAdminData();
    } else {
      isLoggedIn.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      final user = User.fromJson(data['user']);
      if (user.role != 'Admin') {
        Get.snackbar('Access Denied', 'Only administrators are allowed to access this panel.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final token = data['token'];
      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'user_role', value: user.role);
      await storage.write(key: 'user_id', value: user.id);
      await storage.write(key: 'user_name', value: user.name);

      isLoggedIn.value = true;
      adminName.value = user.name;

      Get.offAllNamed('/dashboard');
      fetchAdminData();
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_name');
    isLoggedIn.value = false;
    Get.offAllNamed('/login');
  }

  Future<void> fetchAdminData() async {
    await fetchUsers();
    await fetchProducts();
    await fetchOrders();
    calculateStats();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await apiService.get('/users');
      users.value = response.data as List<dynamic>;
    } catch (e) {
      logger.e('AdminController.fetchUsers failed: $e');
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await apiService.get('/products', query: {'show_inactive': 'true'});
      products.value = response.data as List<dynamic>;
    } catch (e) {
      logger.e('AdminController.fetchProducts failed: $e');
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await apiService.get('/orders');
      orders.value = response.data as List<dynamic>;
    } catch (e) {
      logger.e('AdminController.fetchOrders failed: $e');
    }
  }

  void calculateStats() {
    activeUsersCount.value = users.length;
    totalSalesCount.value = orders.length;

    double revenueSum = 0.0;
    for (var o in orders) {
      revenueSum += double.tryParse(o['total_price'].toString()) ?? 0.0;
    }
    totalRevenue.value = revenueSum;
  }

  Future<void> toggleProductActive(String id, bool active, String title, String? desc, double price, int stock, String? imgUrl) async {
    try {
      await apiService.put('/products/$id', {
        'title': title,
        'description': desc,
        'price': price,
        'stock': stock,
        'image_url': imgUrl,
        'is_active': active,
      });
      fetchProducts();
      Get.snackbar('Success', 'Product visibility updated.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateProductDetail(String id, Map<String, dynamic> data) async {
    try {
      await apiService.put('/products/$id', data);
      fetchProducts();
      Get.snackbar('Success', 'Product updated successfully.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteProductDetail(String id) async {
    try {
      await apiService.delete('/products/$id');
      fetchProducts();
      Get.snackbar('Success', 'Product deleted successfully.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }
}
