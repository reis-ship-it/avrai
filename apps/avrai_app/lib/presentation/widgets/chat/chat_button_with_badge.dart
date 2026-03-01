/// Chat Button with Badge Widget
///
/// AppBar action button for chat with unread message badge
/// Shows total unread count across all chat types
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChatButtonWithBadge extends StatefulWidget {
  const ChatButtonWithBadge({super.key});

  @override
  State<ChatButtonWithBadge> createState() => _ChatButtonWithBadgeState();
}

class _ChatButtonWithBadgeState extends State<ChatButtonWithBadge> {
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }

    try {
      final userId = authState.user.id;
      final friendChatService = GetIt.instance<FriendChatService>();

      // Get friend unread count
      // TODO: Get actual friend list from user service
      final friendIds = <String>[]; // Get from user.friends
      final friendUnread = await friendChatService.getTotalUnreadCount(
        userId,
        friendIds,
      );

      // TODO: Get community unread count when method is available
      // For now, only counting friend unread messages
      const communityUnread = 0;

      if (mounted) {
        setState(() {
          _totalUnreadCount = friendUnread + communityUnread;
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline),
          if (_totalUnreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _totalUnreadCount > 99 ? '99+' : '$_totalUnreadCount',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        context.push('/chat');
      },
      tooltip: 'Chat',
    );
  }
}
