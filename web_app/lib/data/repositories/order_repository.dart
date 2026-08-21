import 'package:get/get.dart';
import '../../core/network/api_client.dart';

class OrderRepository {
  final ApiClient apiClient = Get.find<ApiClient>();

  Future<List<dynamic>> getOrders(String userId, {bool asSeller = false}) async {
    final response = await apiClient.get('/orders?user_id=$userId&as_seller=$asSeller');
    if (response.isOk) {
      return response.body as List<dynamic>;
    }
    return [];
  }

  Future<bool> createOrder({
    required String buyerId,
    required String sellerId,
    required double totalPrice,
    required String productId,
    required int quantity,
  }) async {
    final response = await apiClient.post('/orders', {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_price': totalPrice,
      'product_id': productId,
      'quantity': quantity,
      'status': 'COD', // Cash on Delivery
    });
    if (!response.isOk) {
      final error = response.body != null && response.body is Map
          ? (response.body['error'] ?? 'Checkout failed')
          : 'Checkout failed';
      throw Exception(error);
    }
    return response.isOk;
  }
}
