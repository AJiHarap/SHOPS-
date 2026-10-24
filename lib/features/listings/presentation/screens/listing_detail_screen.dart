import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_theme.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../features/messages/data/messages_repository.dart';
import '../../../../features/requests/data/requests_repository.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class ListingDetailScreen extends ConsumerWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(listingId));

    return listingAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.warmGrey),
              const SizedBox(height: 12),
              Text('Could not load listing.', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Listing not found.')),
          );
        }
        return _ListingDetailView(listing: listing);
      },
    );
  }
}

class _ListingDetailView extends ConsumerStatefulWidget {
  final Listing listing;
  const _ListingDetailView({required this.listing});

  @override
  ConsumerState<_ListingDetailView> createState() => _ListingDetailViewState();
}

class _ListingDetailViewState extends ConsumerState<_ListingDetailView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final currentUser = ref.watch(currentUserProvider);
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final isFavorited = favoriteIds.contains(listing.id);
    final isOwner = currentUser?.id == listing.sellerId;

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(listing, isFavorited, isOwner),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image gallery
                if (listing.hasImages)
                  _ImageGallery(
                    images: listing.images,
                    currentIndex: _currentImageIndex,
                    onPageChanged: (i) => setState(() => _currentImageIndex = i),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + condition row
                      Row(
                        children: [
                          _TagChip(listing.category),
                          const SizedBox(width: 8),
                          _ConditionChip(listing.condition),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Text(listing.title, style: AppTypography.headlineLarge),
                      const SizedBox(height: 8),
                      // Price + quantity
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(listing.formattedPrice, style: AppTypography.priceText),
                          if (listing.quantity > 1) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${listing.quantity} ${listing.unit}s available',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Location + time
                      Row(
                        children: [
                          if (listing.location != null) ...[
                            const Icon(Icons.location_on_outlined, size: 14, color: AppColors.warmGrey),
                            const SizedBox(width: 4),
                            Text(listing.location!, style: AppTypography.bodySmall),
                            const SizedBox(width: 16),
                          ],
                          const Icon(Icons.access_time_outlined, size: 14, color: AppColors.warmGrey),
                          const SizedBox(width: 4),
                          Text(timeago.format(listing.createdAt), style: AppTypography.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),
                      // Description
                      Text('About this item', style: AppTypography.titleLarge),
                      const SizedBox(height: 8),
                      Text(listing.description, style: AppTypography.bodyMedium),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),
                      // Seller info
                      if (listing.sellerUsername != null)
                        _SellerSection(listing: listing),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? _OwnerActions(listing: listing)
          : _BuyerActions(listing: listing),
    );
  }

  SliverAppBar _buildAppBar(Listing listing, bool isFavorited, bool isOwner) {
    return SliverAppBar(
      backgroundColor: AppColors.warmWhite,
      foregroundColor: AppColors.inkBlack,
      floating: true,
      snap: true,
      elevation: 0,
      actions: [
        if (!isOwner)
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_outline,
              color: isFavorited ? AppColors.ember : AppColors.inkBlack,
            ),
            onPressed: () => ref.read(favoriteIdsProvider.notifier).toggle(listing.id),
          ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, __) => Container(color: AppColors.parchment),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.parchment,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.mutedGrey),
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex ? AppColors.ember : AppColors.warmWhite.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(label, style: AppTypography.labelMedium),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final ListingCondition condition;
  const _ConditionChip(this.condition);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.parchment,
        borderRadius: AppRadius.sm,
      ),
      child: Text(condition.label, style: AppTypography.labelMedium),
    );
  }
}

class _SellerSection extends ConsumerWidget {
  final Listing listing;
  const _SellerSection({required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Seller', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/profile/${listing.sellerId}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.parchment,
                backgroundImage: listing.sellerAvatarUrl?.isNotEmpty == true
                    ? CachedNetworkImageProvider(listing.sellerAvatarUrl!)
                    : null,
                child: listing.sellerAvatarUrl?.isNotEmpty != true
                    ? Text(
                        listing.sellerUsername![0].toUpperCase(),
                        style: AppTypography.titleMedium,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.sellerUsername!, style: AppTypography.titleMedium),
                    if (listing.sellerRating != null && listing.sellerRating! > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text(
                            listing.sellerRating!.toStringAsFixed(1),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.warmGrey),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
      ],
    );
  }
}

class _BuyerActions extends ConsumerStatefulWidget {
  final Listing listing;
  const _BuyerActions({required this.listing});

  @override
  ConsumerState<_BuyerActions> createState() => _BuyerActionsState();
}

class _BuyerActionsState extends ConsumerState<_BuyerActions> {
  bool _isSendingRequest = false;

  Future<void> _sendRequest() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      AppSnackbar.error(context, 'Sign in to send a request.');
      return;
    }

    setState(() => _isSendingRequest = true);
    try {
      await ref.read(requestsRepositoryProvider).createRequest(
            listingId: widget.listing.id,
            buyerId: currentUser.id,
            sellerId: widget.listing.sellerId,
            message: 'I am interested in this item.',
          );
      if (mounted) AppSnackbar.success(context, 'Request sent to seller.');
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not send request: $e');
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  Future<void> _startChat() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      AppSnackbar.error(context, 'Sign in to message the seller.');
      return;
    }

    try {
      final convId = await ref.read(messagesRepositoryProvider).getOrCreateConversation(
            listingId: widget.listing.id,
            buyerId: currentUser.id,
            sellerId: widget.listing.sellerId,
          );
      if (mounted) {
        context.push(
          '/chat/$convId?name=${Uri.encodeComponent(widget.listing.sellerUsername ?? 'Seller')}',
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not open chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.listing.isAvailable) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.warmWhite,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.parchment,
            borderRadius: AppRadius.sm,
          ),
          child: Text('This item is no longer available', style: AppTypography.bodyMedium),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Message seller',
              onPressed: _startChat,
              isLoading: false,
              variant: AppButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Request to buy',
              onPressed: _sendRequest,
              isLoading: _isSendingRequest,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerActions extends ConsumerStatefulWidget {
  final Listing listing;
  const _OwnerActions({required this.listing});

  @override
  ConsumerState<_OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends ConsumerState<_OwnerActions> {
  bool _isToggling = false;

  Future<void> _toggleAvailability() async {
    setState(() => _isToggling = true);
    try {
      await ref.read(listingsRepositoryProvider).toggleAvailability(
            widget.listing.id,
            !widget.listing.isAvailable,
          );
      ref.invalidate(listingDetailProvider(widget.listing.id));
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.warmWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: widget.listing.isAvailable ? 'Mark as sold' : 'Mark as available',
              onPressed: _toggleAvailability,
              isLoading: _isToggling,
              variant: AppButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              label: 'Edit listing',
              onPressed: () => context.push('/listings/${widget.listing.id}/edit'),
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }
}
