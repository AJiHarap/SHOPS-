import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/models/listing.dart';
import '../../auth/data/auth_repository.dart';

class ListingsRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  ListingsRepository(this._client);

  Future<List<Listing>> fetchListings({
    String? category,
    String? query,
    String? condition,
    String sortBy = 'created_at',
    bool ascending = false,
    int page = 0,
    int pageSize = 20,
    String? excludeSellerId,
  }) async {
    var queryBuilder = _client
        .from('listings')
        .select('*, profiles:seller_id(username, avatar_url, seller_rating)')
        .eq('is_available', true);

    if (category != null && category.isNotEmpty) {
      queryBuilder = queryBuilder.eq('category', category);
    }
    if (condition != null && condition.isNotEmpty) {
      queryBuilder = queryBuilder.eq('condition', condition);
    }
    if (excludeSellerId != null) {
      queryBuilder = queryBuilder.neq('seller_id', excludeSellerId);
    }
    if (query != null && query.isNotEmpty) {
      queryBuilder = queryBuilder.textSearch(
        'title',
        query,
        config: 'english',
        type: TextSearchType.websearch,
      );
    }

    final data = await queryBuilder
        .order(sortBy, ascending: ascending)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return (data as List).map((e) => Listing.fromMap(e)).toList();
  }

  Future<Listing?> fetchListingById(String id) async {
    final data = await _client
        .from('listings')
        .select('*, profiles:seller_id(username, avatar_url, seller_rating, bio, location, is_seller, total_sales)')
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    await _client.rpc('increment_view_count', params: {'listing_id': id});
    return Listing.fromMap(data);
  }

  Future<List<Listing>> fetchSellerListings(String sellerId) async {
    final data = await _client
        .from('listings')
        .select('*, profiles:seller_id(username, avatar_url, seller_rating)')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Listing.fromMap(e)).toList();
  }

  Future<List<String>> uploadImages(List<XFile> files, String sellerId) async {
    final urls = <String>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final path = '$sellerId/${_uuid.v4()}.$ext';
      await _client.storage.from('listing-images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: false),
          );
      final url = _client.storage.from('listing-images').getPublicUrl(path);
      urls.add(url);
    }
    return urls;
  }

  Future<Listing> createListing(Listing listing) async {
    final data = await _client
        .from('listings')
        .insert(listing.toInsertMap())
        .select('*, profiles:seller_id(username, avatar_url, seller_rating)')
        .single();
    return Listing.fromMap(data);
  }

  Future<Listing> updateListing(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from('listings')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select('*, profiles:seller_id(username, avatar_url, seller_rating)')
        .single();
    return Listing.fromMap(data);
  }

  Future<void> deleteListing(String id) async {
    await _client.from('listings').delete().eq('id', id);
  }

  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await _client
        .from('listings')
        .update({'is_available': isAvailable, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<List<String>> fetchFavoriteIds(String userId) async {
    final data = await _client
        .from('favorites')
        .select('listing_id')
        .eq('user_id', userId);
    return (data as List).map((e) => e['listing_id'] as String).toList();
  }

  Future<List<Listing>> fetchFavoriteListings(String userId) async {
    final data = await _client
        .from('favorites')
        .select('listing_id, listings(*, profiles:seller_id(username, avatar_url, seller_rating))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Listing.fromMap(e['listings'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String userId, String listingId) async {
    await _client.from('favorites').insert({'user_id': userId, 'listing_id': listingId});
  }

  Future<void> removeFavorite(String userId, String listingId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(supabaseClientProvider));
});

final homeListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  return ref.watch(listingsRepositoryProvider).fetchListings(pageSize: 20);
});

final sellerListingsProvider = FutureProvider.autoDispose.family<List<Listing>, String>((ref, sellerId) async {
  return ref.watch(listingsRepositoryProvider).fetchSellerListings(sellerId);
});

final listingDetailProvider = FutureProvider.autoDispose.family<Listing?, String>((ref, id) async {
  return ref.watch(listingsRepositoryProvider).fetchListingById(id);
});

final favoriteListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(listingsRepositoryProvider).fetchFavoriteListings(user.id);
});

final favoriteIdsProvider = StateNotifierProvider.autoDispose<FavoriteIdsNotifier, Set<String>>((ref) {
  return FavoriteIdsNotifier(ref);
});

class FavoriteIdsNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;

  FavoriteIdsNotifier(this._ref) : super({}) {
    _load();
  }

  Future<void> _load() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final ids = await _ref.read(listingsRepositoryProvider).fetchFavoriteIds(user.id);
    state = ids.toSet();
  }

  Future<void> toggle(String listingId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final repo = _ref.read(listingsRepositoryProvider);

    if (state.contains(listingId)) {
      await repo.removeFavorite(user.id, listingId);
      state = {...state}..remove(listingId);
    } else {
      await repo.addFavorite(user.id, listingId);
      state = {...state, listingId};
    }
  }
}
