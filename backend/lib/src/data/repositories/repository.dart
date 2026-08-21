import 'dart:math';
import 'package:postgres/postgres.dart';
import '../../core/network/database.dart';
import '../../domain/entities/models.dart';
import 'package:crypt/crypt.dart';

class BackendRepository {
  Pool get _pool => Database.pool;

  // -- Users --
  Future<User?> getUserByEmail(String email) async {
    final res = await _pool.execute(Sql.named('SELECT * FROM users WHERE email = @email'), parameters: {'email': email});
    if (res.isEmpty) return null;
    final row = res.first.toColumnMap();
    return User.fromJson(row);
  }

  Future<User?> getUserById(String id) async {
    final res = await _pool.execute(Sql.named('SELECT * FROM users WHERE id = @id'), parameters: {'id': id});
    if (res.isEmpty) return null;
    return User.fromJson(res.first.toColumnMap());
  }

  Future<List<User>> getUsers() async {
    final res = await _pool.execute('SELECT * FROM users');
    return res.map((e) => User.fromJson(e.toColumnMap())).toList();
  }

  Future<User> createUser(String email, String password, String name, {String role = 'Buyer'}) async {
    final hash = Crypt.sha256(password).toString();
    final res = await _pool.execute(Sql.named('''
      INSERT INTO users (email, password_hash, name, role) 
      VALUES (@email, @hash, @name, @role) RETURNING *
    '''), parameters: {'email': email, 'hash': hash, 'name': name, 'role': role});
    return User.fromJson(res.first.toColumnMap());
  }

  Future<bool> verifyUser(String email, String password) async {
    final res = await _pool.execute(Sql.named('SELECT password_hash FROM users WHERE email = @email'), parameters: {'email': email});
    if (res.isEmpty) return false;
    final hash = res.first.toColumnMap()['password_hash'] as String;
    return Crypt(hash).match(password);
  }

  Future<String?> createPasswordResetOtp(String email) async {
    final user = await getUserByEmail(email);
    if (user == null) return null;

    final otp = (100000 + Random.secure().nextInt(900000)).toString();
    final otpHash = Crypt.sha256(otp).toString();
    final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10));

    await _pool.execute(Sql.named('''
      UPDATE users SET reset_otp_hash = @hash, reset_otp_expires_at = @expires WHERE email = @email
    '''), parameters: {'hash': otpHash, 'expires': expiresAt, 'email': email});

    return otp;
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    final res = await _pool.execute(Sql.named('''
      SELECT reset_otp_hash, reset_otp_expires_at FROM users WHERE email = @email
    '''), parameters: {'email': email});
    if (res.isEmpty) return false;

    final row = res.first.toColumnMap();
    final otpHash = row['reset_otp_hash'] as String?;
    final expiresAt = row['reset_otp_expires_at'] as DateTime?;
    if (otpHash == null || expiresAt == null) return false;
    if (DateTime.now().toUtc().isAfter(expiresAt)) return false;

    return Crypt(otpHash).match(otp);
  }

  Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    final valid = await verifyPasswordResetOtp(email, otp);
    if (!valid) return false;

    final hash = Crypt.sha256(newPassword).toString();
    await _pool.execute(Sql.named('''
      UPDATE users SET password_hash = @hash, reset_otp_hash = NULL, reset_otp_expires_at = NULL WHERE email = @email
    '''), parameters: {'hash': hash, 'email': email});

    return true;
  }

  Future<void> updateUserFcmToken(String email, String platform, String token) async {
    final col = platform == 'web' ? 'fcm_token_web' : 'fcm_token_app';
    await _pool.execute(Sql.named('UPDATE users SET $col = @token WHERE email = @email'), parameters: {'token': token, 'email': email});
  }

  Future<List<String>> getAllFcmTokens() async {
    final res = await _pool.execute('SELECT fcm_token_app, fcm_token_web FROM users');
    final tokens = <String>{};
    for (var row in res) {
      final map = row.toColumnMap();
      final appToken = map['fcm_token_app'] as String?;
      final webToken = map['fcm_token_web'] as String?;
      if (appToken != null && appToken.isNotEmpty && appToken != 'dummy_token_because_firebase_failed_to_initialize' && appToken != 'fallback_token_since_get_token_returned_null') {
        tokens.add(appToken);
      }
      if (webToken != null && webToken.isNotEmpty && webToken != 'dummy_token_because_firebase_failed_to_initialize' && webToken != 'fallback_token_since_get_token_returned_null') {
        tokens.add(webToken);
      }
    }
    return tokens.toList();
  }

  // -- Categories --
  Future<List<Category>> getCategories() async {
    final res = await _pool.execute('SELECT * FROM categories');
    return res.map((e) => Category.fromJson(e.toColumnMap())).toList();
  }

  Future<Category> createCategory(String name, String? description) async {
    final res = await _pool.execute(Sql.named('''
      INSERT INTO categories (name, description) VALUES (@name, @desc) RETURNING *
    '''), parameters: {'name': name, 'desc': description});
    return Category.fromJson(res.first.toColumnMap());
  }

  // -- Products --
  Future<List<Product>> getProducts({String? categoryId, String? sellerId, bool showInactive = false}) async {
    if (sellerId != null) {
      final res = await _pool.execute(Sql.named('SELECT * FROM products WHERE seller_id = @seller'), parameters: {'seller': sellerId});
      return res.map((e) => Product.fromJson(e.toColumnMap())).toList();
    }
    if (categoryId != null) {
      final cond = showInactive ? '' : ' AND is_active = true';
      final res = await _pool.execute(Sql.named('SELECT * FROM products WHERE category_id = @cat$cond'), parameters: {'cat': categoryId});
      return res.map((e) => Product.fromJson(e.toColumnMap())).toList();
    }
    final cond = showInactive ? '' : ' WHERE is_active = true';
    final res = await _pool.execute('SELECT * FROM products$cond');
    return res.map((e) => Product.fromJson(e.toColumnMap())).toList();
  }

  Future<Product?> getProduct(String id) async {
    final res = await _pool.execute(Sql.named('SELECT * FROM products WHERE id = @id'), parameters: {'id': id});
    if (res.isEmpty) return null;
    return Product.fromJson(res.first.toColumnMap());
  }

  Future<Product> createProduct(Product p) async {
    final res = await _pool.execute(Sql.named('''
      INSERT INTO products (seller_id, category_id, title, description, price, stock, image_url, is_active)
      VALUES (@s, @c, @t, @d, @p, @st, @img, @active) RETURNING *
    '''), parameters: {
      's': p.sellerId, 'c': p.categoryId, 't': p.title, 'd': p.description, 'p': p.price, 'st': p.stock, 'img': p.imageUrl, 'active': p.isActive
    });
    return Product.fromJson(res.first.toColumnMap());
  }

  Future<Product?> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await _pool.execute(Sql.named('''
      UPDATE products 
      SET title = COALESCE(@t, title),
          description = COALESCE(@d, description),
          price = COALESCE(@p, price),
          stock = COALESCE(@st, stock),
          image_url = COALESCE(@img, image_url),
          is_active = COALESCE(@active, is_active),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id RETURNING *
    '''), parameters: {
      'id': id,
      't': data['title'],
      'd': data['description'],
      'p': data['price'] != null ? (data['price'] as num).toDouble() : null,
      'st': data['stock'],
      'img': data['image_url'],
      'active': data['is_active']
    });
    if (res.isEmpty) return null;
    return Product.fromJson(res.first.toColumnMap());
  }

  Future<bool> deleteProduct(String id) async {
    final res = await _pool.execute(Sql.named('DELETE FROM products WHERE id = @id RETURNING id'), parameters: {'id': id});
    return res.isNotEmpty;
  }

  // -- Orders --
  Future<Order> createOrder(Order o, {String? productId, int quantity = 1}) async {
    if (productId != null) {
      final prodRes = await _pool.execute(Sql.named('SELECT stock FROM products WHERE id = @id'), parameters: {'id': productId});
      if (prodRes.isEmpty) {
        throw Exception('Product not found.');
      }
      final stock = prodRes.first.toColumnMap()['stock'] as int;
      if (stock < quantity) {
        throw Exception('Product is out of stock.');
      }
    }

    final res = await _pool.execute(Sql.named('''
      INSERT INTO orders (buyer_id, seller_id, total_price, status)
      VALUES (@b, @s, @p, @status) RETURNING *
    '''), parameters: {
      'b': o.buyerId, 's': o.sellerId, 'p': o.totalPrice, 'status': o.status
    });
    final order = Order.fromJson(res.first.toColumnMap());

    if (productId != null) {
      final priceRes = await _pool.execute(Sql.named('SELECT price FROM products WHERE id = @id'), parameters: {'id': productId});
      final price = double.parse(priceRes.first.toColumnMap()['price'].toString());

      await _pool.execute(Sql.named('''
        INSERT INTO order_items (order_id, product_id, quantity, price_at_purchase)
        VALUES (@orderId, @productId, @qty, @price)
      '''), parameters: {
        'orderId': order.id,
        'productId': productId,
        'qty': quantity,
        'price': price
      });

      await _pool.execute(Sql.named('''
        UPDATE products SET stock = stock - @qty WHERE id = @productId
      '''), parameters: {
        'qty': quantity,
        'productId': productId
      });
    }

    return order;
  }

  Future<List<Order>> getOrders(String userId, {bool asSeller = false}) async {
    if (userId.isEmpty) {
      final res = await _pool.execute('SELECT * FROM orders');
      return res.map((e) => Order.fromJson(e.toColumnMap())).toList();
    }
    final col = asSeller ? 'seller_id' : 'buyer_id';
    final res = await _pool.execute(Sql.named('SELECT * FROM orders WHERE $col = @u'), parameters: {'u': userId});
    return res.map((e) => Order.fromJson(e.toColumnMap())).toList();
  }
}
