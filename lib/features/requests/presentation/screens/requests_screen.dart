import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../features/requests/data/requests_repository.dart';
import '../../../../shared/models/message.dart';
import '../../../../shared/widgets/app_snackbar.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(myRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: AppBar(
          title: const Text('Purchase requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
            labelColor: AppColors.ember,
            unselectedLabelColor: AppColors.warmGrey,
            indicatorColor: AppColors.ember,
            dividerColor: AppColors.borderLight,
          ),
        ),
        body: requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Could not load requests: $e', style: AppTypography.bodyMedium),
          ),
          data: (requests) {
            final received = requests.where((r) => r.sellerId == currentUser?.id).toList();
            final sent = requests.where((r) => r.buyerId == currentUser?.id).toList();

            return TabBarView(
              children: [
                _RequestsList(
                  requests: received,
                  isSeller: true,
                  emptyMessage: 'No requests received yet.\nBuyers will appear here when they request your items.',
                ),
                _RequestsList(
                  requests: sent,
                  isSeller: false,
                  emptyMessage: 'You have not sent any requests yet.\nBrowse listings and request items.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<PurchaseRequest> requests;
  final bool isSeller;
  final String emptyMessage;

  const _RequestsList({
    required this.requests,
    required this.isSeller,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 48, color: AppColors.mutedGrey),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _RequestCard(request: requests[i], isSeller: isSeller),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final PurchaseRequest request;
  final bool isSeller;

  const _RequestCard({required this.request, required this.isSeller});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(requestsRepositoryProvider).updateRequestStatus(widget.request.id, status);
      ref.invalidate(myRequestsProvider);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Color get _statusColor {
    return switch (widget.request.status) {
      'accepted' => AppColors.success,
      'declined' => AppColors.error,
      'completed' => AppColors.ember,
      _ => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  req.listingTitle ?? 'Unknown listing',
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.sm,
                ),
                child: Text(
                  req.status.replaceAll('_', ' '),
                  style: AppTypography.labelSmall.copyWith(color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (req.listingPrice != null)
            Text(
              'Rp ${req.listingPrice!.toStringAsFixed(0)} x ${req.quantity}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.ember),
            ),
          if (req.message?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(req.message!, style: AppTypography.bodySmall),
          ],
          if (widget.isSeller && req.buyerUsername != null) ...[
            const SizedBox(height: 6),
            Text(
              'From: @${req.buyerUsername}',
              style: AppTypography.captionText,
            ),
          ],
          if (widget.isSeller && req.isPending) ...[
            const SizedBox(height: 12),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateStatus('declined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size(0, 38),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateStatus('accepted'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 38),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
          ],
          if (widget.isSeller && req.isAccepted) ...[
            const SizedBox(height: 12),
            _isUpdating
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _updateStatus('completed'),
                      child: const Text('Mark as completed'),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
