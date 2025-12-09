// lib/models/user.dart

class UserData {
  final String name;
  final String email;
  final String userId;
  final DateTime joined;
  final String profilePicUrl;

  /// NEW FIELD (optional for backward compatibility)
  final String phone;

  UserData({
    required this.name,
    required this.email,
    required this.userId,
    required this.joined,
    required this.profilePicUrl,
    this.phone = '', // default empty to avoid breaking old accounts
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',
      joined: DateTime.tryParse(json['joined'] ?? '') ?? DateTime.now(),
      profilePicUrl: json['profilePicUrl'] ?? '',

      /// NEW FIELD — safely read phone from JSON if present
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'userId': userId,
      'joined': joined.toIso8601String(),
      'profilePicUrl': profilePicUrl,

      /// NEW FIELD
      'phone': phone,
    };
  }
}
