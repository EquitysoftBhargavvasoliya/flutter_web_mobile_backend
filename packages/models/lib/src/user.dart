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
    required this.createdAt,
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
