import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/message.dart';
import '../../auth/data/auth_repository.dart';

class MessagesRepository {
  final SupabaseClient _client;

  MessagesRepository(this._client);

  Future<String> getOrCreateConversation({
    required String listingId,
    required String buyerId,
    required String sellerId,
  }) async {
    // Try to find existing
    final existing = await _client
        .from('conversations')
        .select('id')
        .eq('listing_id', listingId)
        .eq('buyer_id', buyerId)
        .eq('seller_id', sellerId)
        .maybeSingle();

    if (existing != null) return existing['id'] as String;

    // Create new
    final created = await _client
        .from('conversations')
        .insert({
          'listing_id': listingId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
        })
        .select('id')
        .single();

    return created['id'] as String;
  }

  Future<List<Conversation>> fetchConversations(String userId) async {
    final data = await _client
        .from('conversations')
        .select('''
          *,
          listings(title, images),
          buyer:buyer_id(id, username, avatar_url, created_at),
          seller:seller_id(id, username, avatar_url, created_at)
        ''')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false, nullsFirst: false);

    return (data as List)
        .map((e) => Conversation.fromMap(e, userId))
        .toList();
  }

  Future<List<Message>> fetchMessages(String conversationId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (data as List).map((e) => Message.fromMap(e)).toList();
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();

    return Message.fromMap(data);
  }

  Future<void> markConversationRead(String conversationId, String userId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId);
  }

  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => Message.fromMap(e)).toList());
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(supabaseClientProvider));
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(messagesRepositoryProvider).fetchConversations(user.id);
});
