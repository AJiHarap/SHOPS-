import 'package:equatable/equatable.dart';

enum ListingCondition {
  newItem('new', 'New'),
  likeNew('like_new', 'Like New'),
  good('good', 'Good'),
  fair('fair', 'Fair'),
  salvage('salvage', 'Salvage');

  final String value;
  final String label;
  const ListingCondition(this.value, this.label);

  static ListingCondition fromValue(String value) {
    return ListingCondition.values.firstWhere(
      (c) => c.value == value,
      orElse: () => ListingCondition.good,
    );
  }
}

class Listing extends Equatable {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final ListingCondition condition;
  final List<String> images;
  final String? location;
  final int quantity;
  final String unit;
  final bool isAvailable;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined from profiles
  final String? sellerUsername;
  final String? sellerAvatarUrl;
  final double? sellerRating;

  // Computed
  final bool? isFavorited;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    this.location,
    this.quantity = 1,
    this.unit = 'piece',
    this.isAvailable = true,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.sellerUsername,
    this.sellerAvatarUrl,
    this.sellerRating,
    this.isFavorited,
  });

  factory Listing.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    List<String> imageList = [];
    if (rawImages is List) {
      imageList = rawImages.cast<String>();
    }

    return Listing(
      id: map['id'] as String,
      sellerId: map['seller_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      category: map['category'] as String,
      condition: ListingCondition.fromValue(map['condition'] as String),
      images: imageList,
      location: map['location'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      unit: map['unit'] as String? ?? 'piece',
      isAvailable: map['is_available'] as bool? ?? true,
      viewCount: map['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      sellerUsername: map['profiles']?['username'] as String?,
      sellerAvatarUrl: map['profiles']?['avatar_url'] as String?,
      sellerRating: (map['profiles']?['seller_rating'] as num?)?.toDouble(),
      isFavorited: map['is_favorited'] as bool?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'seller_id': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition.value,
      'images': images,
      'location': location,
      'quantity': quantity,
      'unit': unit,
      'is_available': isAvailable,
    };
  }

  String get firstImage => images.isNotEmpty ? images.first : '';
  bool get hasImages => images.isNotEmpty;

  String get formattedPrice {
    if (price == 0) return 'Free';
    final amount = price.toStringAsFixed(0);
    // Simple thousand separator
    final buffer = StringBuffer();
    final reversed = amount.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write('.');
      buffer.write(reversed[i]);
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  Listing copyWith({
    String? title,
    String? description,
    double? price,
    String? category,
    ListingCondition? condition,
    List<String>? images,
    String? location,
    int? quantity,
    String? unit,
    bool? isAvailable,
    bool? isFavorited,
  }) {
    return Listing(
      id: id,
      sellerId: sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      images: images ?? this.images,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isAvailable: isAvailable ?? this.isAvailable,
      viewCount: viewCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sellerUsername: sellerUsername,
      sellerAvatarUrl: sellerAvatarUrl,
      sellerRating: sellerRating,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  @override
  List<Object?> get props => [id, title, price, condition, isAvailable];
}
