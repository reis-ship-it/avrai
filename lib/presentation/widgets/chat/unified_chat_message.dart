/// Unified Chat Message Widget
/// 
/// Displays messages for all chat types:
/// - Agent chat messages
/// - Friend chat messages
/// - Community/group chat messages
/// 
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';

enum ChatType {
  agent,
  friend,
  community,
}

class UnifiedChatMessage extends StatelessWidget {
  final String message;
  final bool isFromUser;
  final DateTime timestamp;
  final ChatType chatType;
  final String? senderName; // For group chats
  final String? senderPhotoUrl; // For group chats

  const UnifiedChatMessage({
    super.key,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    required this.chatType,
    this.senderName,
    this.senderPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromUser
                    ? AppTheme.primaryColor
                    : Theme.of(context).brightness == Brightness.light
                        ? AppColors.grey200
                        : AppColors.grey700,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (!isFromUser && chatType == ChatType.community && senderName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isFromUser ? AppColors.white : null,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: isFromUser
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            _buildUserAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    switch (chatType) {
      case ChatType.agent:
        return const CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primaryColor,
          child: Icon(
            Icons.smart_toy,
            size: 16,
            color: AppColors.white,
          ),
        );
      case ChatType.friend:
        return CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.grey300,
          backgroundImage: senderPhotoUrl != null
              ? NetworkImage(senderPhotoUrl!)
              : null,
          child: senderPhotoUrl == null
              ? const Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.white,
                )
              : null,
        );
      case ChatType.community:
        return CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.grey300,
          backgroundImage: senderPhotoUrl != null
              ? NetworkImage(senderPhotoUrl!)
              : null,
          child: senderPhotoUrl == null
              ? const Icon(
                  Icons.group,
                  size: 16,
                  color: AppColors.white,
                )
              : null,
        );
    }
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.grey300,
      child: Icon(
        Icons.person,
        size: 16,
        color: AppColors.white,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

