import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/message.dart';
import '../../auth/data/auth_repository.dart';

class RequestsRepository {
  final SupabaseClient _client;

  RequestsRepository(this._client);

  Future<void> createRequest({
    required String listingId,
    required String buyerId,
    required String sellerId,
    String? message,
    int quantity = 1,
  }) async {
    await _client.from('purchase_requests').insert({
      'listing_id': listingId,
      'buyer_id': buyerId,
      'seller_id': sellerId,
      'message': message,
      'quantity': quantity,
      'status': 'pending',
    });
  }

  Future<List<PurchaseRequest>> fetchMyRequests(String userId) async {
    final data = await _client
        .from('purchase_requests')
        .select('''
          *,
          listings(title, images, price),
          buyer:buyer_id(username, avatar_url)
        ''')
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('created_at', ascending: false);

    return (data as List).map((e) => PurchaseRequest.fromMap(e)).toList();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _client
        .from('purchase_requests')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
  }
}

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository(ref.watch(supabaseClientProvider));
});

final myRequestsProvider = FutureProvider.autoDispose<List<PurchaseRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(requestsRepositoryProvider).fetchMyRequests(user.id);
});
