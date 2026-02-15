import 'package:flutter/material.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai/core/models/business/business_expert_message.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';
import 'package:avrai/presentation/widgets/portal/portal_surface.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Business-Expert Chat Page
///
/// Chat interface for messaging between businesses and experts.
/// Messages routed through ai2ai network, stored locally.
class BusinessExpertChatPage extends StatefulWidget {
  final String businessId;
  final String expertId;
  final String? businessName;
  final String? expertName;

  const BusinessExpertChatPage({
    super.key,
    required this.businessId,
    required this.expertId,
    this.businessName,
    this.expertName,
  });

  @override
  State<BusinessExpertChatPage> createState() => _BusinessExpertChatPageState();
}

class _BusinessExpertChatPageState extends State<BusinessExpertChatPage> {
  final _chatService = GetIt.instance<BusinessExpertChatServiceAI2AI>();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<BusinessExpertMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  StreamSubscription<BusinessExpertMessage>? _messageSubscription;
  String? _conversationId;
  String? _businessName;
  String? _expertName;
  final MessageSenderType _senderType =
      MessageSenderType.business; // TODO: Determine from auth state

  @override
  void initState() {
    super.initState();
    _businessName = widget.businessName;
    _expertName = widget.expertName;
    _loadConversation();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    try {
      final conversation = await _chatService.getConversation(
        widget.businessId,
        widget.expertId,
      );

      if (conversation != null) {
        setState(() {
          _conversationId = conversation['id'] as String?;
          _businessName ??= conversation['business_name'] as String?;
          _expertName ??= conversation['expert_name'] as String?;
        });

        // Subscribe to real-time messages
        if (_conversationId != null) {
          _messageSubscription = _chatService
              .subscribeToMessages(_conversationId!)
              .listen((message) {
            setState(() {
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
                _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                _scrollToBottom();
              }
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading conversation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final conversation = await _chatService.getConversation(
        widget.businessId,
        widget.expertId,
      );

      if (conversation != null) {
        final conversationId = conversation['id'] as String;
        final messages = await _chatService.getMessageHistory(conversationId);

        setState(() {
          _messages = messages;
          _conversationId = conversationId;
          _isLoading = false;
        });

        _scrollToBottom();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        businessId: widget.businessId,
        expertId: widget.expertId,
        content: content,
        senderType: _senderType,
        messageType: MessageType.text,
      );

      _messageController.clear();
      await _loadMessages(); // Reload to get the new message
    } catch (e) {
      if (!mounted) return;
      context.showError('Error sending message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
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
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: '',
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _senderType == MessageSenderType.business
                ? (_expertName ?? 'Expert')
                : (_businessName ?? 'Business'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_senderType == MessageSenderType.business && _expertName != null)
            Text(
              _expertName!,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (_businessName != null)
            Text(
              _businessName!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(kSpaceLg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadMessages,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64, color: AppColors.textSecondary),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                SizedBox(height: 8),
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
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(kSpaceMd),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isFromMe =
                                  message.senderType == _senderType;
                              return _buildMessageBubble(message, isFromMe);
                            },
                          ),
          ),

          // Input area
          PortalSurface(
            color: AppColors.white,
            radius: 0,
            elevation: 0.2,
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
                      onPressed: _isSending ? null : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.send,
                              color: AppTheme.primaryColor,
                            ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(kSpaceSm),
                      ),
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

  Widget _buildMessageBubble(
    BusinessExpertMessage message,
    bool isFromMe,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSpaceXxs),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Icon(
                message.senderType == MessageSenderType.business
                    ? Icons.business
                    : Icons.person,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: PortalSurface(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceMd, vertical: kSpaceSmTight),
              color: isFromMe ? AppTheme.primaryColor : AppColors.white,
              borderColor: isFromMe
                  ? AppTheme.primaryColor.withValues(alpha: 0.5)
                  : AppColors.grey300,
              radius: 16,
              elevation: 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromMe
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isFromMe
                              ? AppColors.white.withValues(alpha: 0.7)
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Icon(
                _senderType == MessageSenderType.business
                    ? Icons.business
                    : Icons.person,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
