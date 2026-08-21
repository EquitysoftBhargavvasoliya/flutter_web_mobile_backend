import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/api_client.dart';

class AdminController extends GetxController {
  final ApiClient apiClient = Get.put(ApiClient());
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
      final response = await apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.isOk && response.body != null) {
        final data = response.body as Map<String, dynamic>;
        final role = data['user']['role'];
        if (role != 'Admin') {
          Get.snackbar('Access Denied', 'Only administrators are allowed to access this panel.', snackPosition: SnackPosition.BOTTOM);
          return;
        }

        final token = data['token'];
        await storage.write(key: 'jwt_token', value: token);
        await storage.write(key: 'user_role', value: role);
        await storage.write(key: 'user_id', value: data['user']['id']);
        await storage.write(key: 'user_name', value: data['user']['name']);

        isLoggedIn.value = true;
        adminName.value = data['user']['name'] ?? 'Admin';
        
        Get.offAllNamed('/dashboard');
        fetchAdminData();
      } else {
        final error = response.body != null && response.body is Map && response.body['error'] != null
            ? response.body['error']
            : 'Invalid credentials or connection failed.';
        Get.snackbar('Login Failed', error.toString(), snackPosition: SnackPosition.BOTTOM);
      }
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
    final response = await apiClient.get('/users');
    if (response.isOk && response.body != null) {
      users.value = response.body as List<dynamic>;
    }
  }

  Future<void> fetchProducts() async {
    final response = await apiClient.get('/products?show_inactive=true');
    if (response.isOk && response.body != null) {
      products.value = response.body as List<dynamic>;
    }
  }

  Future<void> fetchOrders() async {
    final response = await apiClient.get('/orders');
    if (response.isOk && response.body != null) {
      orders.value = response.body as List<dynamic>;
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
    final response = await apiClient.put('/products/$id', {
      'title': title,
      'description': desc,
      'price': price,
      'stock': stock,
      'image_url': imgUrl,
      'is_active': active,
    });
    if (response.isOk) {
      fetchProducts();
      Get.snackbar('Success', 'Product visibility updated.', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', _extractError(response, 'Failed to update visibility.'), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateProductDetail(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/products/$id', data);
    if (response.isOk) {
      fetchProducts();
      Get.snackbar('Success', 'Product updated successfully.', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', _extractError(response, 'Failed to update product details.'), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteProductDetail(String id) async {
    final response = await apiClient.delete('/products/$id');
    if (response.isOk) {
      fetchProducts();
      Get.snackbar('Success', 'Product deleted successfully.', snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', _extractError(response, 'Failed to delete product.'), snackPosition: SnackPosition.BOTTOM);
    }
  }

  String _extractError(Response response, String fallback) {
    return response.body != null && response.body is Map && response.body['error'] != null
        ? response.body['error'].toString()
        : fallback;
  }
}
