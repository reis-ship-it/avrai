/// Communities Chat List View
///
/// Displays list of community/club conversations
/// - Shows communities user is a member of
/// - Unread indicators
/// - Last message preview
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/community/community_chat_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/community/community.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CommunitiesChatListView extends StatefulWidget {
  const CommunitiesChatListView({super.key});

  @override
  State<CommunitiesChatListView> createState() =>
      _CommunitiesChatListViewState();
}

class _CommunitiesChatListViewState extends State<CommunitiesChatListView> {
  final _chatService = GetIt.instance<CommunityChatService>();
  List<CommunityChatPreview> _chatList = [];
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
      // Get user's communities
      // TODO: Get actual communities from user service
      // For now, getting all communities and filtering by membership
      // TODO: Get user's communities from user service
      // For now, using empty list - will be populated when communities are available
      final userCommunities = <Community>[];

      final chatList = await _chatService.getUserCommunitiesChatList(
        _userId!,
        userCommunities,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chats: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatList,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _chatList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No community chats yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Join communities to start chatting!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
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

  Widget _buildChatListItem(CommunityChatPreview chat) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          Icons.group,
          color: AppColors.white,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.communityName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // TODO: Add unread count when available in CommunityChatPreview
          // For now, unread count is not available in the preview model
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          if (chat.lastMessagePreview != null) ...[
            Text(
              chat.lastMessagePreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (chat.lastMessageTime != null)
            Text(
              _formatTimestamp(chat.lastMessageTime!),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to community chat view
        context.push('/chat/community/${chat.communityId}');
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
