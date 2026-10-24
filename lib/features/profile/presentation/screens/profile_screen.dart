import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reusehub/core/constants/app_theme.dart';
import 'package:reusehub/features/auth/data/auth_repository.dart';
import 'package:reusehub/features/listings/data/listings_repository.dart';
import 'package:reusehub/shared/models/user_profile.dart';
import 'package:reusehub/shared/widgets/listing_card.dart';

final _profileByIdProvider =
    FutureProvider.autoDispose.family<UserProfile?, String>((ref, userId) async {
  return ref.watch(authRepositoryProvider).getProfile(userId);
});

class ProfileScreen extends ConsumerWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final targetId = userId ?? currentUser?.id;
    final isOwn = userId == null || userId == currentUser?.id;

    if (targetId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(_profileByIdProvider(targetId));
    final listingsAsync = ref.watch(sellerListingsProvider(targetId));

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.warmWhite,
            foregroundColor: AppColors.inkBlack,
            actions: [
              if (isOwn) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/profile/edit'),
                  tooltip: 'Edit profile',
                ),
                IconButton(
                  icon: const Icon(Icons.logout_outlined),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/auth/login');
                  },
                  tooltip: 'Sign out',
                ),
              ],
            ],
          ),
          profileAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SliverFillRemaining(
              child: Center(child: Text('Could not load profile.')),
            ),
            data: (profile) {
              if (profile == null) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Profile not found.')),
                );
              }
              return SliverToBoxAdapter(
                child: _ProfileHeader(profile: profile, isOwn: isOwn),
              );
            },
          ),
          listingsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ListingCardShimmer(),
                  childCount: 4,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Could not load listings.', style: AppTypography.bodyMedium),
              ),
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    child: Text(
                      'No listings yet.',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
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
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwn;

  const _ProfileHeader({required this.profile, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.parchment,
                    backgroundImage: profile.avatarUrl?.isNotEmpty == true
                        ? CachedNetworkImageProvider(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl?.isNotEmpty != true
                        ? Text(
                            profile.displayName[0].toUpperCase(),
                            style: AppTypography.headlineLarge,
                          )
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName, style: AppTypography.headlineSmall),
                        Text('@${profile.username}', style: AppTypography.bodySmall),
                        if (profile.isSeller) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined,
                                  size: 14, color: AppColors.ember),
                              const SizedBox(width: 4),
                              Text(
                                'Seller',
                                style: AppTypography.labelMedium
                                    .copyWith(color: AppColors.ember),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.bio?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(profile.bio!, style: AppTypography.bodyMedium),
              ],
              if (profile.location?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.warmGrey),
                    const SizedBox(width: 4),
                    Text(profile.location!, style: AppTypography.bodySmall),
                  ],
                ),
              ],
              if (isOwn) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/seller/dashboard'),
                        child: const Text('Seller dashboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/requests'),
                        child: const Text('My requests'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Listings', style: AppTypography.titleLarge),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
