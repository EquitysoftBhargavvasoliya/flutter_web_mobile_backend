class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? fcmTokenWeb;
  final String? fcmTokenApp;
  final DateTime createdAt;

  User({
    required this.id, 
    required this.email, 
    required this.name, 
    required this.role, 
    this.fcmTokenWeb,
    this.fcmTokenApp,
    required this.createdAt
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    role: json['role'],
    fcmTokenWeb: json['fcm_token_web'],
    fcmTokenApp: json['fcm_token_app'],
    createdAt: json['created_at'] is DateTime ? json['created_at'] : DateTime.parse(json['created_at'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role,
    'fcm_token_web': fcmTokenWeb,
    'fcm_token_app': fcmTokenApp,
    'created_at': createdAt.toIso8601String(),
  };
}

class Category {
  final String id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

class Product {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;

  Product({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    sellerId: json['seller_id'],
    categoryId: json['category_id'],
    title: json['title'],
    description: json['description'],
    price: double.parse(json['price'].toString()),
    stock: json['stock'],
    imageUrl: json['image_url'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'seller_id': sellerId,
    'category_id': categoryId,
    'title': title,
    'description': description,
    'price': price,
    'stock': stock,
    'image_url': imageUrl,
    'is_active': isActive,
  };
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final double totalPrice;
  final String status;

  Order({required this.id, required this.buyerId, required this.sellerId, required this.totalPrice, required this.status});

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    buyerId: json['buyer_id'],
    sellerId: json['seller_id'],
    totalPrice: double.parse(json['total_price'].toString()),
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'buyer_id': buyerId,
    'seller_id': sellerId,
    'total_price': totalPrice,
    'status': status,
  };
}
