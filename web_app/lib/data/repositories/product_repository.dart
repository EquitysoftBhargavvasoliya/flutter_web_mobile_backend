import 'package:api_client/api_client.dart';

class ProductRepository {
  Future<List<dynamic>> getProducts({String? sellerId}) async {
    try {
      final query = sellerId != null ? {'seller_id': sellerId} : null;
      final response = await apiService.get('/products', query: query);
      return response.data as List<dynamic>;
    } catch (e) {
      logger.e('ProductRepository.getProducts failed: $e');
      return [];
    }
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    await apiService.post('/products', data);
    return true;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    await apiService.put('/products/$id', data);
    return true;
  }

  Future<bool> deleteProduct(String id) async {
    await apiService.delete('/products/$id');
    return true;
  }
}
