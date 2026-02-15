/// Community Chat View
///
/// Group chat interface for communities/clubs
/// - Encrypted group messages
/// - Member list display
/// - Message history
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'dart:async';
import 'package:avrai/presentation/presentation_spacing.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/community/community_chat_service.dart';
import 'package:avrai/core/services/community/community_service.dart';
import 'package:avrai/core/services/user/user_name_resolution_service.dart';
import 'package:avrai/core/models/community/community.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/presentation/widgets/chat/message_search_bar.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

class CommunityChatView extends StatefulWidget {
  final String communityId;
  final Community? community;

  const CommunityChatView({
    super.key,
    required this.communityId,
    this.community,
  });

  @override
  State<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = GetIt.instance<CommunityChatService>();
  final _communityService = GetIt.instance<CommunityService>();
  final _nameResolver = GetIt.instance<UserNameResolutionService>();
  StreamSubscription? _incomingSubscription;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _userId;
  Community? _community;
  final Map<String, String> _senderNames = {}; // Cache sender names
  final Map<String, String?> _senderPhotoUrls = {}; // Cache sender photo URLs
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCommunity();
  }

  Future<void> _loadUser() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _userId = authState.user.id;
      });
      await _loadConversationHistory();
      _startIncomingSubscription();
    }
  }

  Future<void> _loadCommunity() async {
    // If community not provided, try to load it
    if (widget.community != null) {
      setState(() {
        _community = widget.community;
      });
    } else {
      // Load community from service
      try {
        final community =
            await _communityService.getCommunityById(widget.communityId);
        if (mounted) {
          setState(() {
            _community = community;
          });
        }
      } catch (e) {
        // Community not found, continue without it
      }
    }
  }

  void _startIncomingSubscription() {
    final userId = _userId;
    if (userId == null) return;

    _incomingSubscription?.cancel();
    _incomingSubscription = _chatService
        .subscribeToIncomingCommunityMessages(
      userId: userId,
      communityId: widget.communityId,
    )
        .listen((storedMessage) async {
      try {
        final decrypted = await _chatService.getDecryptedMessage(
            storedMessage, widget.communityId);
        if (!mounted) return;

        setState(() {
          if (_messages.any((m) => m['id'] == storedMessage.messageId)) return;
          _messages.add({
            'id': storedMessage.messageId,
            'content': decrypted,
            'isFromUser': storedMessage.senderId == userId,
            'timestamp': storedMessage.timestamp,
            'senderId': storedMessage.senderId,
          });
          _filteredMessages = _applySearchFilter(_messages);
        });
        _scrollToBottom();
      } catch (_) {
        // Best-effort; failures are logged in service layer.
      }
    });
  }

  Future<void> _loadConversationHistory() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history =
          await _chatService.getGroupChatHistory(widget.communityId);

      // Get unique sender IDs
      final senderIds = history.map((msg) => msg.senderId).toSet().toList();

      // Resolve all sender names and photos
      final usersInfo = await _nameResolver.getUsersInfo(senderIds);
      for (final entry in usersInfo.entries) {
        _senderNames[entry.key] = entry.value.displayName;
        _senderPhotoUrls[entry.key] = entry.value.photoUrl;
      }

      // Decrypt all messages
      final decryptedMessages = await Future.wait(
        history.map((msg) async {
          final decrypted = await _chatService.getDecryptedMessage(
            msg,
            widget.communityId,
          );
          return {
            'id': msg.messageId,
            'content': decrypted,
            'isFromUser': msg.senderId == _userId,
            'timestamp': msg.timestamp,
            'senderId': msg.senderId,
          };
        }),
      );

      if (mounted) {
        setState(() {
          _messages = decryptedMessages;
          _filteredMessages = _applySearchFilter(_messages);
          _isLoading = false;
        });

        // TODO: Mark messages as read when method is available
        // await _chatService.markAsRead(widget.communityId, _userId!);

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        context.showError('Error loading history: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _userId == null ||
        _community == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Add user message to UI immediately
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': messageText,
        'isFromUser': true,
        'timestamp': DateTime.now(),
        'senderId': _userId!,
      });
      _filteredMessages = _applySearchFilter(_messages);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Store locally + send over realtime (Signal Protocol transport, fanout).
      await _chatService.sendGroupMessageOverNetwork(
        userId: _userId!,
        communityId: widget.communityId,
        message: messageText,
        community: _community!,
      );

      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        context.showError('Error sending message: $e');
      }
    }
  }

  List<Map<String, dynamic>> _applySearchFilter(
      List<Map<String, dynamic>> messages) {
    if (_searchQuery.isEmpty) {
      return messages;
    }

    final query = _searchQuery.toLowerCase();
    return messages.where((msg) {
      final content = (msg['content'] as String).toLowerCase();
      return content.contains(query);
    }).toList();
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredMessages = _applySearchFilter(_messages);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMemberList(BuildContext context) {
    if (_community == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members (${_community!.memberCount})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _community!.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = _community!.memberIds[index];
                  return FutureBuilder<String>(
                    future: _nameResolver.getUserDisplayName(memberId),
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.grey300,
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          snapshot.data ?? memberId,
                        ),
                        subtitle: memberId == _community!.founderId
                            ? Text('Founder')
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const AdaptivePlatformPageScaffold(
        title: 'Community Chat',
        showNavigationBar: false,
        constrainBody: false,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final communityName = _community?.name ?? widget.communityId;

    return AdaptivePlatformPageScaffold(
      title: communityName,
      constrainBody: false,
      titleWidget: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: Icon(
              Icons.group,
              size: 16,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  communityName,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_community != null)
                  GestureDetector(
                    onTap: () => _showMemberList(context),
                    child: Text(
                      '${_community!.memberCount} members',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.normal,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          MessageSearchBar(
            onSearch: _handleSearch,
            onClear: () {
              setState(() {
                _filteredMessages = _messages;
              });
            },
          ),
          // Message list
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.group_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No messages found'
                                  : 'No messages yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(kSpaceMd),
                        itemCount: _filteredMessages.length,
                        itemBuilder: (context, index) {
                          final message = _filteredMessages[index];
                          final senderId = message['senderId'] as String;
                          final senderName = _senderNames[senderId] ?? senderId;
                          final senderPhotoUrl = _senderPhotoUrls[senderId];
                          return UnifiedChatMessage(
                            message: message['content'] as String,
                            isFromUser: message['isFromUser'] as bool,
                            timestamp: message['timestamp'] as DateTime,
                            chatType: ChatType.community,
                            senderName: message['isFromUser'] as bool
                                ? null
                                : senderName,
                            senderPhotoUrl: message['isFromUser'] as bool
                                ? null
                                : senderPhotoUrl,
                          );
                        },
                      ),
          ),

          // Input bar
          Material(
            color: AppColors.white,
            elevation: 4,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(kSpaceXs),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppColors.grey300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: kSpaceMd,
                            vertical: kSpaceSm,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
