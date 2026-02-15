/// Friends Chat List View
///
/// Displays list of friend conversations
/// - Shows recent conversations
/// - Unread indicators
/// - Last message preview
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/chat/friend_chat_service.dart';
import 'package:avrai_ai/models/friend_chat_message.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class FriendsChatListView extends StatefulWidget {
  const FriendsChatListView({super.key});

  @override
  State<FriendsChatListView> createState() => _FriendsChatListViewState();
}

class _FriendsChatListViewState extends State<FriendsChatListView> {
  final _chatService = GetIt.instance<FriendChatService>();
  List<FriendChatPreview> _chatList = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndChatList();
  }

  Future<void> _loadUserAndChatList() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _userId = authState.user.id;
      });

      await _loadChatList();
    }
  }

  Future<void> _loadChatList() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Get actual friend list from user service
      // For now, using empty list - will be populated when friends are available
      final friendIds = <String>[]; // Get from user.friends
      final friendNames = <String, String>{};
      final friendPhotoUrls = <String, String>{};

      final chatList = await _chatService.getFriendsChatList(
        _userId!,
        friendIds,
        friendNames: friendNames,
        friendPhotoUrls: friendPhotoUrls,
      );

      if (mounted) {
        setState(() {
          _chatList = chatList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        context.showError('Error loading chats: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatList,
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _chatList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No conversations yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start chatting with your friends!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _chatList.length,
                  itemBuilder: (context, index) {
                    final chat = _chatList[index];
                    return _buildChatListItem(chat);
                  },
                ),
    );
  }

  Widget _buildChatListItem(FriendChatPreview chat) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.grey300,
        backgroundImage: chat.friendPhotoUrl != null
            ? NetworkImage(chat.friendPhotoUrl!)
            : null,
        child: chat.friendPhotoUrl == null
            ? const Icon(Icons.person, color: AppColors.white)
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.friendName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (chat.unreadCount > 0)
            Chip(
              side: BorderSide.none,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(
                horizontal: -4,
                vertical: -4,
              ),
              backgroundColor: AppTheme.primaryColor,
              label: Text(
                '${chat.unreadCount}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            chat.lastMessagePreview ?? 'No messages',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            chat.lastMessageTime != null
                ? _formatTimestamp(chat.lastMessageTime!)
                : '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to friend chat view
        context.push('/chat/friend/${chat.friendId}');
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
