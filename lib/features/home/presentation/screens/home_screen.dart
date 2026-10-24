import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/listing_card.dart';



final _selectedCategoryProvider = StateProvider.autoDispose<String?>((ref) => null);

final _filteredListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  final category = ref.watch(_selectedCategoryProvider);
  return ref.watch(listingsRepositoryProvider).fetchListings(
        category: category,
        pageSize: 20,
      );
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final listingsAsync = ref.watch(_filteredListingsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: CustomScrollView(
        slivers: [
          _HomeAppBar(),
          _SearchBar(),
          _CategoryRow(selectedCategory: selectedCategory),
          _ListingGrid(listingsAsync: listingsAsync),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/create'),
        backgroundColor: AppColors.ember,
        foregroundColor: AppColors.warmWhite,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'List item',
          style: AppTypography.labelLarge.copyWith(color: AppColors.warmWhite),
        ),
        elevation: 2,
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: AppColors.warmWhite,
      elevation: 0,
      titleSpacing: 20,
      title: Text(
        'ReUseHub',
        style: AppTypography.headlineMedium.copyWith(color: AppColors.ember),
      ),
      actions: const [
        SizedBox(width: 16),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: AppRadius.sm,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.warmGrey),
                const SizedBox(width: 10),
                Text(
                  'Search wood, metal, fabric...',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  final String? selectedCategory;
  const _CategoryRow({required this.selectedCategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: AppConstants.categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CategoryChip(
                label: 'All',
                isSelected: selectedCategory == null,
                onTap: () => ref.read(_selectedCategoryProvider.notifier).state = null,
              );
            }
            final cat = AppConstants.categories[index - 1];
            return _CategoryChip(
              label: cat,
              isSelected: selectedCategory == cat,
              onTap: () => ref.read(_selectedCategoryProvider.notifier).state =
                  selectedCategory == cat ? null : cat,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ember : AppColors.cream,
          borderRadius: AppRadius.sm,
          border: Border.all(color: isSelected ? AppColors.ember : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.warmWhite : AppColors.charcoal,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ListingGrid extends StatelessWidget {
  final AsyncValue<List<Listing>> listingsAsync;
  const _ListingGrid({required this.listingsAsync});

  @override
  Widget build(BuildContext context) {
    return listingsAsync.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ListingCardShimmer(),
            childCount: 6,
          ),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: AppColors.warmGrey),
                const SizedBox(height: 12),
                Text('Could not load listings.', style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.mutedGrey),
                    const SizedBox(height: 16),
                    Text('Nothing listed yet.', style: AppTypography.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to list a material in this category.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListingCard(listing: listings[index]),
              childCount: listings.length,
            ),
          ),
        );
      },
    );
  }
}
