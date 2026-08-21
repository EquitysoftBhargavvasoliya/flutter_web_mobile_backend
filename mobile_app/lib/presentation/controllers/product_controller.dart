import 'package:get/get.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../core/utils/ui_utils.dart';

class ProductController extends GetxController {
  final ProductRepository repo = Get.put(ProductRepository());
  final OrderRepository orderRepo = Get.put(OrderRepository());
  
  var isLoading = false.obs;
  var products = [].obs;
  var myProducts = [].obs;
  var myOrders = [].obs;
  var receivedOrders = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      products.value = await repo.getProducts();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyProducts(String sellerId) async {
    isLoading.value = true;
    try {
      myProducts.value = await repo.getProducts(sellerId: sellerId);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMyOrders(String userId) async {
    isLoading.value = true;
    try {
      myOrders.value = await orderRepo.getOrders(userId, asSeller: false);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchReceivedOrders(String userId) async {
    isLoading.value = true;
    try {
      receivedOrders.value = await orderRepo.getOrders(userId, asSeller: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Map<String, dynamic> data, [String? sellerId]) async {
    isLoading.value = true;
    try {
      final success = await repo.createProduct(data);
      if (success) {
        UiUtils.showToast('Product added successfully');
        await fetchProducts();
        if (sellerId != null) {
          await fetchMyProducts(sellerId);
        }
      }
    } catch (e) {
      UiUtils.showToast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data, [String? sellerId]) async {
    isLoading.value = true;
    try {
      final success = await repo.updateProduct(id, data);
      if (success) {
        UiUtils.showToast('Product updated successfully');
        await fetchProducts();
        if (sellerId != null) {
          await fetchMyProducts(sellerId);
        }
      }
    } catch (e) {
      UiUtils.showToast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id, [String? sellerId]) async {
    isLoading.value = true;
    try {
      final success = await repo.deleteProduct(id);
      if (success) {
        UiUtils.showToast('Product deleted successfully');
        await fetchProducts();
        if (sellerId != null) {
          await fetchMyProducts(sellerId);
        }
      }
    } catch (e) {
      UiUtils.showToast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buyProduct({
    required String buyerId,
    required String sellerId,
    required double price,
    required String productId,
    required int quantity,
  }) async {
    isLoading.value = true;
    try {
      final success = await orderRepo.createOrder(
        buyerId: buyerId,
        sellerId: sellerId,
        totalPrice: price * quantity,
        productId: productId,
        quantity: quantity,
      );
      if (success) {
        UiUtils.showToast('Purchase successful (Cash on Delivery)!');
        await fetchProducts();
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      UiUtils.showToast(msg);
    } finally {
      isLoading.value = false;
    }
  }
}
