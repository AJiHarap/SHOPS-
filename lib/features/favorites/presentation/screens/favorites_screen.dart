import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../shared/widgets/listing_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(title: const Text('Saved items')),
      body: favoritesAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4,
          itemBuilder: (_, __) => const ListingCardShimmer(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.warmGrey),
              const SizedBox(height: 12),
              Text('Could not load saved items.', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_outline, size: 48, color: AppColors.mutedGrey),
                  const SizedBox(height: 16),
                  Text('No saved items yet.', style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart on any listing to save it here.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) => ListingCard(listing: favorites[index]),
          );
        },
      ),
    );
  }
}
