// lib/models/user.dart
class UserData {
  final String name;
  final String email;
  final String userId;
  final DateTime joined;
  final String profilePicUrl;

  UserData({
    required this.name,
    required this.email,
    required this.userId,
    required this.joined,
    required this.profilePicUrl,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userId: json['userId'] ?? '',
      joined: DateTime.parse(json['joined'] as String),
      profilePicUrl: json['profilePicUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'userId': userId,
      'joined': joined.toIso8601String(),
      'profilePicUrl': profilePicUrl,
    };
  }
}
