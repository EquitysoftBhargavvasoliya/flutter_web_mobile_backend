import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../../data/repositories/repository.dart';
import '../../domain/entities/models.dart';
import '../../core/network/middleware.dart';

class ApiController {
  final BackendRepository repo = BackendRepository();

  Router get router {
    final r = Router();

    // -- Auth --
    r.post('/auth/register', _register);
    r.post('/auth/login', _login);
    r.post('/auth/forgot-password', _forgotPassword);
    r.post('/auth/verify-otp', _verifyOtp);
    r.post('/auth/reset-password', _resetPassword);

    // -- Categories --
    r.get('/categories', _getCategories);
    r.post('/categories', _createCategory);

    // -- Products --
    r.get('/products', _getProducts);
    
    // Protected Product Routes
    final protectedProducts = Router();
    protectedProducts.post('/', _createProduct);
    protectedProducts.put('/<id>', _updateProduct);
    protectedProducts.delete('/<id>', _deleteProduct);
    r.mount('/products', Pipeline().addMiddleware(ApiMiddleware.authMiddleware()).addHandler(protectedProducts.call));

    // -- Orders --
    r.get('/orders', _getOrders);
    r.post('/orders', _createOrder);

    // -- Users (Admin only) --
    r.get('/users', Pipeline().addMiddleware(ApiMiddleware.authMiddleware()).addHandler(_getUsers).call);

    return r;
  }

  Future<Response> _register(Request req) async {
    final body = jsonDecode(await req.readAsString());
    try {
      final user = await repo.createUser(
        body['email'], 
        body['password'], 
        body['name'], 
        role: body['role'] ?? 'Buyer'
      );
      return Response.ok(jsonEncode(user.toJson()), headers: {'content-type': 'application/json'});
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('23505') || errorStr.contains('unique constraint') || errorStr.contains('already exists')) {
        return Response.forbidden(
          jsonEncode({'error': 'this email already exist'}),
          headers: {'content-type': 'application/json'},
        );
      }
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _login(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final email = body['email'];
    
    var user = await repo.getUserByEmail(email);
    if (user == null) {
      return Response.forbidden(jsonEncode({'error': 'this email is not register'}), headers: {'content-type': 'application/json'});
    }

    final valid = await repo.verifyUser(email, body['password']);
    if (!valid) return Response.forbidden(jsonEncode({'error': 'Invalid credentials'}), headers: {'content-type': 'application/json'});
    
    // Save FCM token if provided
    final fcmToken = body['fcm_token'];
    final platform = body['platform'];
    if (fcmToken != null && platform != null && (platform == 'web' || platform == 'app')) {
      await repo.updateUserFcmToken(email, platform, fcmToken);
      // Fetch updated user to include the new token in the response
      user = await repo.getUserByEmail(email);
    }

    final token = ApiMiddleware.generateToken({'id': user!.id, 'role': user.role});
    return Response.ok(jsonEncode({'token': token, 'user': user.toJson()}), headers: {'content-type': 'application/json'});
  }

  Future<Response> _forgotPassword(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final email = body['email'];

    final otp = await repo.createPasswordResetOtp(email);
    if (otp == null) {
      return Response.forbidden(jsonEncode({'error': 'this email is not register'}), headers: {'content-type': 'application/json'});
    }

    // Dev mode: OTP is returned directly in the response since no email/SMS
    // provider is configured. Replace with an actual email/SMS send before
    // shipping this to production.
    return Response.ok(
      jsonEncode({'message': 'OTP generated', 'otp': otp}),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _verifyOtp(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final valid = await repo.verifyPasswordResetOtp(body['email'], body['otp']);
    if (!valid) {
      return Response.forbidden(jsonEncode({'error': 'Invalid or expired OTP'}), headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode({'valid': true}), headers: {'content-type': 'application/json'});
  }

  Future<Response> _resetPassword(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final success = await repo.resetPasswordWithOtp(body['email'], body['otp'], body['new_password']);
    if (!success) {
      return Response.forbidden(jsonEncode({'error': 'Invalid or expired OTP'}), headers: {'content-type': 'application/json'});
    }
    return Response.ok(jsonEncode({'message': 'Password reset successfully'}), headers: {'content-type': 'application/json'});
  }

  Future<Response> _getCategories(Request req) async {
    final cats = await repo.getCategories();
    return Response.ok(jsonEncode(cats.map((e) => e.toJson()).toList()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _createCategory(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final cat = await repo.createCategory(body['name'], body['description']);
    return Response.ok(jsonEncode(cat.toJson()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _getProducts(Request req) async {
    final categoryId = req.url.queryParameters['category_id'];
    final sellerId = req.url.queryParameters['seller_id'];
    final showInactive = req.url.queryParameters['show_inactive'] == 'true';
    final prods = await repo.getProducts(categoryId: categoryId, sellerId: sellerId, showInactive: showInactive);
    return Response.ok(jsonEncode(prods.map((e) => e.toJson()).toList()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _createProduct(Request req) async {
    final user = req.context['user'] as Map<String, dynamic>; // from auth middleware
    if (user['role'] == 'Buyer') {
      return Response.forbidden(jsonEncode({'error': 'Buyers are not allowed to sell products.'}), headers: {'content-type': 'application/json'});
    }
    
    final body = jsonDecode(await req.readAsString());
    final p = Product(
      id: '', 
      sellerId: user['id'], 
      categoryId: body['category_id'], 
      title: body['title'], 
      description: body['description'], 
      price: (body['price'] as num).toDouble(), 
      stock: body['stock'] ?? 0,
      imageUrl: body['image_url']
    );
    final res = await repo.createProduct(p);
    return Response.ok(jsonEncode(res.toJson()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _updateProduct(Request req, String id) async {
    final body = jsonDecode(await req.readAsString());
    final user = req.context['user'] as Map<String, dynamic>;
    
    final prod = await repo.getProduct(id);
    if (prod == null) return Response.notFound(jsonEncode({'error': 'Product not found'}), headers: {'content-type': 'application/json'});
    if (prod.sellerId != user['id'] && user['role'] != 'Admin') {
      return Response.forbidden(jsonEncode({'error': 'Not authorized to update this product'}), headers: {'content-type': 'application/json'});
    }

    final updated = await repo.updateProduct(id, body);
    return Response.ok(jsonEncode(updated?.toJson()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _deleteProduct(Request req, String id) async {
    final user = req.context['user'] as Map<String, dynamic>;
    
    final prod = await repo.getProduct(id);
    if (prod == null) return Response.notFound(jsonEncode({'error': 'Product not found'}), headers: {'content-type': 'application/json'});
    if (prod.sellerId != user['id'] && user['role'] != 'Admin') {
      return Response.forbidden(jsonEncode({'error': 'Not authorized to delete this product'}), headers: {'content-type': 'application/json'});
    }

    final success = await repo.deleteProduct(id);
    if (success) return Response.ok(jsonEncode({'message': 'Deleted successfully'}), headers: {'content-type': 'application/json'});
    return Response.internalServerError(body: jsonEncode({'error': 'Failed to delete'}), headers: {'content-type': 'application/json'});
  }

  Future<Response> _getOrders(Request req) async {
    final userId = req.url.queryParameters['user_id'] ?? '';
    final asSeller = req.url.queryParameters['as_seller'] == 'true';
    final orders = await repo.getOrders(userId, asSeller: asSeller);
    return Response.ok(jsonEncode(orders.map((e) => e.toJson()).toList()), headers: {'content-type': 'application/json'});
  }

  Future<Response> _createOrder(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final status = body['status'] ?? 'Pending';
    final o = Order(
      id: '', 
      buyerId: body['buyer_id'], 
      sellerId: body['seller_id'], 
      totalPrice: (body['total_price'] as num).toDouble(), 
      status: status
    );
    try {
      final res = await repo.createOrder(o, productId: body['product_id'], quantity: body['quantity'] ?? 1);
      return Response.ok(jsonEncode(res.toJson()), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString().replaceFirst('Exception: ', '')}), headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _getUsers(Request req) async {
    final user = req.context['user'] as Map<String, dynamic>;
    if (user['role'] != 'Admin') {
      return Response.forbidden(jsonEncode({'error': 'Not authorized'}), headers: {'content-type': 'application/json'});
    }
    final users = await repo.getUsers();
    return Response.ok(jsonEncode(users.map((e) => e.toJson()).toList()), headers: {'content-type': 'application/json'});
  }
}
