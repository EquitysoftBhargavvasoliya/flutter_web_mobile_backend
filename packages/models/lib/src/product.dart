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
        stock: json['stock'] is int ? json['stock'] : int.parse(json['stock'].toString()),
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
