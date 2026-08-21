import 'package:api_client/api_client.dart';

class OrderRepository {
  Future<List<dynamic>> getOrders(String userId, {bool asSeller = false}) async {
    try {
      final response = await apiService.get('/orders', query: {
        'user_id': userId,
        'as_seller': asSeller.toString(),
      });
      return response.data as List<dynamic>;
    } catch (e) {
      logger.e('OrderRepository.getOrders failed: $e');
      return [];
    }
  }

  Future<bool> createOrder({
    required String buyerId,
    required String sellerId,
    required double totalPrice,
    required String productId,
    required int quantity,
  }) async {
    await apiService.post('/orders', {
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'total_price': totalPrice,
      'product_id': productId,
      'quantity': quantity,
      'status': 'COD', // Cash on Delivery
    });
    return true;
  }
}
