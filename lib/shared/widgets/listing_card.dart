import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:reusehub/shared/models/listing.dart';
import 'package:reusehub/core/constants/app_theme.dart';
import 'package:reusehub/features/listings/data/listings_repository.dart';

class ListingCard extends ConsumerWidget {
  final Listing listing;

  const ListingCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdsProvider);
    final isFavorited = favoriteIds.contains(listing.id);

    return GestureDetector(
      onTap: () => context.push('/listings/${listing.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmWhite,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  listing.hasImages
                      ? CachedNetworkImage(
                          imageUrl: listing.firstImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => _buildImageShimmer(),
                          errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                  // Condition badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ConditionBadge(condition: listing.condition),
                  ),
                  // Favorite button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _FavoriteButton(
                      listingId: listing.id,
                      isFavorited: isFavorited,
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: AppTypography.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.formattedPrice,
                    style: AppTypography.priceText.copyWith(fontSize: 16),
                  ),
                  if (listing.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.warmGrey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            listing.location!,
                            style: AppTypography.captionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(listing.createdAt),
                    style: AppTypography.captionText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.parchment,
      child: const Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 36, color: AppColors.mutedGrey),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.parchment,
      highlightColor: AppColors.cream,
      child: Container(color: AppColors.parchment),
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final ListingCondition condition;

  const _ConditionBadge({required this.condition});

  Color get _backgroundColor {
    return switch (condition) {
      ListingCondition.newItem => AppColors.conditionNew,
      ListingCondition.likeNew => AppColors.conditionLikeNew,
      ListingCondition.good => AppColors.conditionGood,
      ListingCondition.fair => AppColors.conditionFair,
      ListingCondition.salvage => AppColors.conditionSalvage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Text(
        condition.label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.charcoal),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String listingId;
  final bool isFavorited;

  const _FavoriteButton({required this.listingId, required this.isFavorited});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(favoriteIdsProvider.notifier).toggle(listingId),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.warmWhite.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorited ? Icons.favorite : Icons.favorite_outline,
          size: 18,
          color: isFavorited ? AppColors.ember : AppColors.warmGrey,
        ),
      ),
    );
  }
}

// Shimmer placeholder for loading state
class ListingCardShimmer extends StatelessWidget {
  const ListingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.parchment,
      highlightColor: AppColors.cream,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.parchment,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
                aspectRatio: 1, child: Container(color: AppColors.parchment)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      width: double.infinity,
                      color: AppColors.parchment),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 80, color: AppColors.parchment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
