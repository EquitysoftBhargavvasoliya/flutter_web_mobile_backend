import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class ProductRepository {
  final ApiClient apiClient = Get.find<ApiClient>();

  Future<List<dynamic>> getProducts({String? sellerId}) async {
    final path = sellerId != null ? '/products?seller_id=$sellerId' : '/products';
    final response = await apiClient.get(path);
    if (response.isOk) {
      return response.body as List<dynamic>;
    }
    return [];
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    final response = await apiClient.post('/products', data);
    if (!response.isOk) throw Exception(_extractError(response, 'Failed to add product'));
    return response.isOk;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await apiClient.put('/products/$id', data);
    if (!response.isOk) throw Exception(_extractError(response, 'Failed to update product'));
    return response.isOk;
  }

  Future<bool> deleteProduct(String id) async {
    final response = await apiClient.delete('/products/$id');
    if (!response.isOk) throw Exception(_extractError(response, 'Failed to delete product'));
    return response.isOk;
  }

  String _extractError(Response response, String fallback) {
    return response.body != null && response.body is Map
        ? (response.body['error'] ?? fallback)
        : fallback;
  }
}
