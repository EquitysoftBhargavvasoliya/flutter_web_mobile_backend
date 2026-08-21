class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final double totalPrice;
  final String status;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.totalPrice,
    required this.status,
  });

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
