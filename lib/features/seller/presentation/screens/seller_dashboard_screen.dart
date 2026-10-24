import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final listingsAsync = ref.watch(sellerListingsProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        title: const Text('Seller dashboard'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/listings/create'),
        backgroundColor: AppColors.ember,
        foregroundColor: AppColors.warmWhite,
        icon: const Icon(Icons.add, size: 20),
        label: Text('New listing', style: AppTypography.labelLarge.copyWith(color: AppColors.warmWhite)),
        elevation: 2,
      ),
      body: listingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_outlined, size: 48, color: AppColors.mutedGrey),
                  const SizedBox(height: 16),
                  Text('No listings yet.', style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first listing to start selling.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Summary row
          final available = listings.where((l) => l.isAvailable).length;
          final sold = listings.length - available;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _StatCard(label: 'Active', value: available.toString()),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Sold/closed', value: sold.toString()),
                      const SizedBox(width: 12),
                      _StatCard(label: 'Total', value: listings.length.toString()),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ListingRow(listing: listings[index]),
                  childCount: listings.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.headlineMedium.copyWith(color: AppColors.ember)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ListingRow extends ConsumerStatefulWidget {
  final Listing listing;
  const _ListingRow({required this.listing});

  @override
  ConsumerState<_ListingRow> createState() => _ListingRowState();
}

class _ListingRowState extends ConsumerState<_ListingRow> {
  bool _isToggling = false;

  Future<void> _toggle() async {
    setState(() => _isToggling = true);
    try {
      await ref.read(listingsRepositoryProvider).toggleAvailability(
            widget.listing.id,
            !widget.listing.isAvailable,
          );
      ref.invalidate(sellerListingsProvider);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: AppRadius.sm,
          child: Container(
            width: 56,
            height: 56,
            color: AppColors.parchment,
            child: listing.hasImages
                ? Image.network(listing.firstImage, fit: BoxFit.cover)
                : const Icon(Icons.inventory_2_outlined, color: AppColors.mutedGrey),
          ),
        ),
        title: Text(
          listing.title,
          style: AppTypography.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          listing.formattedPrice,
          style: AppTypography.bodySmall.copyWith(color: AppColors.ember),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Available toggle
            _isToggling
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: listing.isAvailable,
                    onChanged: (_) => _toggle(),
                    activeThumbColor: AppColors.ember,
                  ),
            // Edit
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => context.push('/listings/${listing.id}/edit'),
              tooltip: 'Edit',
            ),
          ],
        ),
        onTap: () => context.push('/listings/${listing.id}'),
      ),
    );
  }
}
