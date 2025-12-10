// lib/models/user.dart

class UserData {
  final String name;
  final String email;

  /// App-level user id (GraphQL databaseId, Google id, etc.)
  final String userId;

  /// WooCommerce customer ID (numeric in WP, stored as string here)
  final String wooCustomerId;

  final DateTime joined;
  final String profilePicUrl;

  /// Optional phone for convenience
  final String phone;

  UserData({
    required this.name,
    required this.email,
    required this.userId,
    required this.joined,
    required this.profilePicUrl,
    this.phone = '',
    this.wooCustomerId = '', // default empty for old saved users
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',
      wooCustomerId: json['wooCustomerId'] ?? '',
      joined: DateTime.tryParse(json['joined'] ?? '') ?? DateTime.now(),
      profilePicUrl: json['profilePicUrl'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'userId': userId,
      'wooCustomerId': wooCustomerId,
      'joined': joined.toIso8601String(),
      'profilePicUrl': profilePicUrl,
      'phone': phone,
    };
  }

  UserData copyWith({
    String? name,
    String? email,
    String? userId,
    String? wooCustomerId,
    DateTime? joined,
    String? profilePicUrl,
    String? phone,
  }) {
    return UserData(
      name: name ?? this.name,
      email: email ?? this.email,
      userId: userId ?? this.userId,
      wooCustomerId: wooCustomerId ?? this.wooCustomerId,
      joined: joined ?? this.joined,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      phone: phone ?? this.phone,
    );
  }
}
