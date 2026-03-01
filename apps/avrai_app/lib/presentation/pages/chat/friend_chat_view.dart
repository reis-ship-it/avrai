/// Friend Chat View
///
/// Individual 1-on-1 chat interface with a friend
/// - Encrypted messages
/// - Message history
/// - Read status tracking
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai_runtime_os/services/user/user_name_resolution_service.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/presentation/widgets/chat/typing_indicator.dart';
import 'package:avrai/presentation/widgets/chat/message_search_bar.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

class FriendChatView extends StatefulWidget {
  final String friendId;
  final String? friendName;
  final String? friendPhotoUrl;

  const FriendChatView({
    super.key,
    required this.friendId,
    this.friendName,
    this.friendPhotoUrl,
  });

  @override
  State<FriendChatView> createState() => _FriendChatViewState();
}

class _FriendChatViewState extends State<FriendChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = GetIt.instance<FriendChatService>();
  final _nameResolver = GetIt.instance<UserNameResolutionService>();
  StreamSubscription? _incomingSubscription;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isTyping = false; // Simulated typing indicator
  String? _userId;
  String? _friendDisplayName;
  String? _friendPhotoUrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _userId = authState.user.id;
      });

      // Resolve friend name and photo
      final displayName =
          await _nameResolver.getUserDisplayName(widget.friendId);
      final photoUrl = await _nameResolver.getUserPhotoUrl(widget.friendId);

      if (mounted) {
        setState(() {
          _friendDisplayName = displayName;
          _friendPhotoUrl = photoUrl;
        });
      }

      // Load history + start listening for incoming DMs once we have a user ID.
      await _loadConversationHistory();
      _startIncomingSubscription();
    }
  }

  void _startIncomingSubscription() {
    final userId = _userId;
    if (userId == null) return;

    _incomingSubscription?.cancel();
    _incomingSubscription = _chatService
        .subscribeToIncomingMessages(userId: userId, friendId: widget.friendId)
        .listen((storedMessage) async {
      try {
        final decrypted = await _chatService.getDecryptedMessage(
          storedMessage,
          userId,
          widget.friendId,
        );

        if (!mounted) return;
        setState(() {
          // De-dupe by message id
          if (_messages.any((m) => m['id'] == storedMessage.messageId)) {
            return;
          }
          _messages.add({
            'id': storedMessage.messageId,
            'content': decrypted,
            'isFromUser': false,
            'timestamp': storedMessage.timestamp,
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
      final history = await _chatService.getConversationHistory(
        _userId!,
        widget.friendId,
      );

      // Decrypt all messages
      final decryptedMessages = await Future.wait(
        history.map((msg) async {
          final decrypted = await _chatService.getDecryptedMessage(
            msg,
            _userId!,
            widget.friendId,
          );
          return {
            'id': msg.messageId,
            'content': decrypted,
            'isFromUser': msg.senderId == _userId,
            'timestamp': msg.timestamp,
          };
        }),
      );

      if (mounted) {
        setState(() {
          _messages = decryptedMessages;
          _filteredMessages = _applySearchFilter(_messages);
          _isLoading = false;
        });

        // Mark messages as read
        await _chatService.markAsRead(_userId!, widget.friendId);

        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _userId == null) {
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
      });
      _filteredMessages = _applySearchFilter(_messages);
      _isSending = true;
    });
    _scrollToBottom();

    // Simulate friend typing indicator
    setState(() {
      _isTyping = true;
    });

    // Hide typing indicator after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });

    try {
      // Store locally + send over realtime (Signal Protocol transport).
      //
      // If Signal is unavailable or recipient hasn't published a prekey bundle yet,
      // this will throw and the UI will show an error, while still keeping the local message.
      await _chatService.sendMessageOverNetwork(
          _userId!, widget.friendId, messageText);

      if (mounted) {
        setState(() {
          _isSending = false;
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
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
        title: 'Chat',
        showNavigationBar: false,
        constrainBody: false,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AdaptivePlatformPageScaffold(
      title: _friendDisplayName ?? widget.friendName ?? widget.friendId,
      constrainBody: false,
      titleWidget: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.grey300,
            backgroundImage: (_friendPhotoUrl ?? widget.friendPhotoUrl) != null
                ? NetworkImage(_friendPhotoUrl ?? widget.friendPhotoUrl!)
                : null,
            child: (_friendPhotoUrl ?? widget.friendPhotoUrl) == null
                ? const Icon(Icons.person, size: 16, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _friendDisplayName ?? widget.friendName ?? widget.friendId,
              overflow: TextOverflow.ellipsis,
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
                ? const Center(
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
                                  : Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No messages found'
                                  : 'No messages yet',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Start the conversation!',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            _filteredMessages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show typing indicator at the end
                          if (_isTyping && index == _filteredMessages.length) {
                            return TypingIndicator(
                              senderName:
                                  _friendDisplayName ?? widget.friendName,
                            );
                          }

                          final message = _filteredMessages[index];
                          return UnifiedChatMessage(
                            message: message['content'] as String,
                            isFromUser: message['isFromUser'] as bool,
                            timestamp: message['timestamp'] as DateTime,
                            chatType: ChatType.friend,
                            senderName: message['isFromUser'] as bool
                                ? null
                                : (_friendDisplayName ?? widget.friendName),
                            senderPhotoUrl: message['isFromUser'] as bool
                                ? null
                                : (_friendPhotoUrl ?? widget.friendPhotoUrl),
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                            horizontal: 16,
                            vertical: 12,
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
