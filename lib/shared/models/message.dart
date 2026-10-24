import 'package:equatable/equatable.dart';
import 'user_profile.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, content, createdAt];
}

class Conversation extends Equatable {
  final String id;
  final String? listingId;
  final String buyerId;
  final String sellerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  // Joined
  final String? listingTitle;
  final String? listingImage;
  final UserProfile? otherUser;

  const Conversation({
    required this.id,
    this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.listingTitle,
    this.listingImage,
    this.otherUser,
  });

  factory Conversation.fromMap(Map<String, dynamic> map, String currentUserId) {
    final listingData = map['listings'] as Map<String, dynamic>?;
    final buyerData = map['buyer'] as Map<String, dynamic>?;
    final sellerData = map['seller'] as Map<String, dynamic>?;

    UserProfile? otherUser;
    if (currentUserId == map['buyer_id']) {
      if (sellerData != null) {
        otherUser = UserProfile.fromMap({
          ...sellerData,
          'created_at': sellerData['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    } else {
      if (buyerData != null) {
        otherUser = UserProfile.fromMap({
          ...buyerData,
          'created_at': buyerData['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    }

    return Conversation(
      id: map['id'] as String,
      listingId: map['listing_id'] as String?,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      listingTitle: listingData?['title'] as String?,
      listingImage: (listingData?['images'] as List?)?.firstOrNull as String?,
      otherUser: otherUser,
    );
  }

  @override
  List<Object?> get props => [id, buyerId, sellerId, lastMessage, lastMessageAt];
}

class PurchaseRequest extends Equatable {
  final String id;
  final String listingId;
  final String buyerId;
  final String sellerId;
  final String? message;
  final int quantity;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? listingTitle;
  final String? listingImage;
  final double? listingPrice;
  final String? buyerUsername;
  final String? buyerAvatarUrl;

  const PurchaseRequest({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.message,
    this.quantity = 1,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.listingImage,
    this.listingPrice,
    this.buyerUsername,
    this.buyerAvatarUrl,
  });

  factory PurchaseRequest.fromMap(Map<String, dynamic> map) {
    final listingData = map['listings'] as Map<String, dynamic>?;
    final buyerData = map['buyer'] as Map<String, dynamic>?;

    return PurchaseRequest(
      id: map['id'] as String,
      listingId: map['listing_id'] as String,
      buyerId: map['buyer_id'] as String,
      sellerId: map['seller_id'] as String,
      message: map['message'] as String?,
      quantity: map['quantity'] as int? ?? 1,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      listingTitle: listingData?['title'] as String?,
      listingImage: (listingData?['images'] as List?)?.firstOrNull as String?,
      listingPrice: (listingData?['price'] as num?)?.toDouble(),
      buyerUsername: buyerData?['username'] as String?,
      buyerAvatarUrl: buyerData?['avatar_url'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCompleted => status == 'completed';

  @override
  List<Object?> get props => [id, listingId, buyerId, status];
}
