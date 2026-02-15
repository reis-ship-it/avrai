/// Agent Chat View
///
/// Chat interface for Personality Agent (AI companion)
/// - Encrypted messages (agentId ↔ userId)
/// - Language learning enabled
/// - Search integration
/// - Personality profile integration
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/design/feedback_presenter.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/services/user/personality_agent_chat_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/services/recommendations/agent_happiness_service.dart';
import 'package:avrai/presentation/presentation_spacing.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

class AgentChatView extends StatefulWidget {
  const AgentChatView({super.key});

  @override
  State<AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends State<AgentChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = GetIt.instance<PersonalityAgentChatService>();
  final _agentIdService = GetIt.instance<AgentIdService>();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _userId;
  String? _agentId;
  SharedPreferencesCompat? _prefs;

  @override
  void initState() {
    super.initState();
    _loadUserAndAgent();
    _loadConversationHistory();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferencesCompat.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  Future<void> _loadUserAndAgent() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _userId = authState.user.id;
      });

      try {
        final agentId = await _agentIdService.getUserAgentId(_userId!);
        setState(() {
          _agentId = agentId;
        });
      } catch (e) {
        if (mounted) {
          context.showError('Error loading agent: $e');
        }
      }
    }
  }

  Future<void> _loadConversationHistory() async {
    if (_userId == null || _agentId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _chatService.getConversationHistory(_userId!);

      // Wait for all messages to decrypt
      final decryptedMessages = await Future.wait(
        history.map((msg) async {
          final decrypted = await _chatService.getDecryptedMessageAsync(
            msg,
            _agentId!,
            _userId!,
          );
          return {
            'id': msg.messageId,
            'content': decrypted,
            'isFromUser': msg.isFromUser,
            'timestamp': msg.timestamp,
          };
        }),
      );

      if (mounted) {
        setState(() {
          _messages = decryptedMessages;
          _isLoading = false;
        });
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
        _agentId == null) {
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
      _isSending = true;
    });
    _scrollToBottom();

    try {
      // Get current location if available
      Position? currentLocation;
      try {
        currentLocation = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        );
      } catch (e) {
        // Location not available, continue without it
      }

      // Send message and get agent response
      final response = await _chatService.chat(
        _userId!,
        messageText,
        currentLocation: currentLocation,
      );

      if (mounted) {
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': response,
            'isFromUser': false,
            'timestamp': DateTime.now(),
            'happinessRated': false,
          });
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

  Future<void> _rateLastAgentMessage({
    required String messageId,
    required double score,
  }) async {
    // Score is 0..1. This is stored locally and can later drive scheduled LoRA
    // training (charging/idle).
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final svc = AgentHappinessService(prefs: prefs);
      await svc.recordSignal(
        source: 'chat_rating',
        score: score,
        metadata: <String, dynamic>{
          'message_id': messageId,
        },
      );
    } catch (_) {
      // Ignore.
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        // Message list
        Expanded(
          child: _isLoading && _messages.isEmpty
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Start chatting with your AI companion',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Ask about spots, philosophy, or anything!',
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
                        final isFromUser = message['isFromUser'] as bool;
                        final msgId = message['id'] as String;
                        final rated =
                            (message['happinessRated'] as bool?) ?? false;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UnifiedChatMessage(
                              message: message['content'] as String,
                              isFromUser: isFromUser,
                              timestamp: message['timestamp'] as DateTime,
                              chatType: ChatType.agent,
                            ),
                            if (!isFromUser && !rated)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 56,
                                    right: kSpaceMd,
                                    bottom: kSpaceXs),
                                child: Row(
                                  children: [
                                    Text(
                                      'Was this helpful?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.thumb_up_outlined,
                                          size: 18),
                                      color: AppColors.success,
                                      onPressed: () async {
                                        setState(() {
                                          _messages[index]['happinessRated'] =
                                              true;
                                        });
                                        await _rateLastAgentMessage(
                                          messageId: msgId,
                                          score: 0.9,
                                        );
                                      },
                                      tooltip: 'Helpful',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.thumb_down_outlined,
                                          size: 18),
                                      color: AppColors.error,
                                      onPressed: () async {
                                        setState(() {
                                          _messages[index]['happinessRated'] =
                                              true;
                                        });
                                        await _rateLastAgentMessage(
                                          messageId: msgId,
                                          score: 0.1,
                                        );
                                      },
                                      tooltip: 'Not helpful',
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
        ),

        // Typing indicator
        if (_isSending)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kSpaceMd, vertical: kSpaceXs),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  'Agent is typing...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
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
                        hintText: 'Message your AI companion...',
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
    );
  }
}
