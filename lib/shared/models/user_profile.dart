import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final bool isSeller;
  final double sellerRating;
  final int totalSales;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.location,
    this.isSeller = false,
    this.sellerRating = 0,
    this.totalSales = 0,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      isSeller: map['is_seller'] as bool? ?? false,
      sellerRating: (map['seller_rating'] as num?)?.toDouble() ?? 0,
      totalSales: map['total_sales'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'is_seller': isSeller,
    };
  }

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? location,
    bool? isSeller,
    double? sellerRating,
    int? totalSales,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      isSeller: isSeller ?? this.isSeller,
      sellerRating: sellerRating ?? this.sellerRating,
      totalSales: totalSales ?? this.totalSales,
      createdAt: createdAt,
    );
  }

  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  @override
  List<Object?> get props => [id, username, fullName, avatarUrl, bio, location, isSeller];
}
