class UserProfileModel {
  final int id;
  final String userId;
  final String? fullName;
  final String? username;
  final String email;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? avatarUrl;
  final DateTime createdAt;

  UserProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.username,
    required this.email,
    this.phoneNumber,
    this.address,
    this.city,
    this.postalCode,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'],
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
