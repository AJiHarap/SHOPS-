import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_theme.dart';
import '../../../../features/messages/data/messages_repository.dart';
import '../../../../shared/models/message.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(title: const Text('Messages')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.warmGrey),
              const SizedBox(height: 12),
              Text('Could not load messages.', style: AppTypography.bodyMedium),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.mutedGrey),
                  const SizedBox(height: 16),
                  Text('No messages yet.', style: AppTypography.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Message a seller from any listing to start a conversation.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.warmGrey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) => _ConversationTile(conv: conversations[i]),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = conv.otherUser;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.parchment,
        backgroundImage: other?.avatarUrl?.isNotEmpty == true
            ? CachedNetworkImageProvider(other!.avatarUrl!)
            : null,
        child: other?.avatarUrl?.isNotEmpty != true
            ? Text(
                (other?.username ?? '?')[0].toUpperCase(),
                style: AppTypography.titleMedium,
              )
            : null,
      ),
      title: Text(other?.displayName ?? 'Unknown', style: AppTypography.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conv.listingTitle != null)
            Text(
              conv.listingTitle!,
              style: AppTypography.captionText.copyWith(color: AppColors.ember),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (conv.lastMessage != null)
            Text(
              conv.lastMessage!,
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: conv.lastMessageAt != null
          ? Text(timeago.format(conv.lastMessageAt!), style: AppTypography.captionText)
          : null,
      onTap: () => context.push(
        '/chat/${conv.id}?name=${Uri.encodeComponent(other?.displayName ?? 'User')}',
      ),
    );
  }
}
