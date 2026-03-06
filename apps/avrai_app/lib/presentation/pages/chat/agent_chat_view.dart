/// Agent Chat View
///
/// Human-facing AI chat surface for the user's personality agent.
library;

import 'dart:async';

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/controllers/human_chat_controller.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AgentChatView extends StatefulWidget {
  final String? draftMessage;
  final VoidCallback? onDraftConsumed;

  const AgentChatView({
    super.key,
    this.draftMessage,
    this.onDraftConsumed,
  });

  @override
  State<AgentChatView> createState() => _AgentChatViewState();
}

class _AgentChatViewState extends State<AgentChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  late final HumanChatController _controller;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = HumanChatController()..addListener(_handleControllerUpdate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated && _controller.userId != authState.user.id) {
      unawaited(_initializeController(authState.user.id));
    }
  }

  @override
  void didUpdateWidget(covariant AgentChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextDraft = widget.draftMessage?.trim();
    final previousDraft = oldWidget.draftMessage?.trim();
    if (nextDraft != null &&
        nextDraft.isNotEmpty &&
        nextDraft != previousDraft) {
      _messageController
        ..text = nextDraft
        ..selection = TextSelection.collapsed(offset: nextDraft.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _inputFocusNode.requestFocus();
          widget.onDraftConsumed?.call();
        }
      });
    }
  }

  Future<void> _initializeController(String userId) async {
    try {
      await _controller.initialize(userId: userId);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading agent: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }

    final messageCount = _controller.messages.length;
    if (messageCount != _lastMessageCount) {
      _lastMessageCount = messageCount;
      _scrollToBottom();
    }

    setState(() {});
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || !_controller.isReady) {
      return;
    }

    _messageController.clear();

    try {
      await _controller.sendMessage(messageText);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _applyPromptSuggestion(String prompt) {
    unawaited(_controller.recordPromptSuggestion(prompt));
    _messageController
      ..text = prompt
      ..selection = TextSelection.collapsed(offset: prompt.length);
    _inputFocusNode.requestFocus();
  }

  Future<void> _rateLastAgentMessage({
    required String messageId,
    required double score,
  }) async {
    await _controller.rateMessage(
      messageId: messageId,
      score: score,
    );
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
    _controller
      ..removeListener(_handleControllerUpdate)
      ..dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.userId == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              _controller.isLoading && _controller.messages.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _controller.messages.isEmpty
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
                                'Start with what fits your life right now',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                width: 280,
                                child: Text(
                                  'Ask what fits tonight, why something is a match, or tell your agent what matters to you.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if ((_controller.signatureSummary ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _controller.signatureSummary!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _controller.messages.length,
                          itemBuilder: (context, index) {
                            final message = _controller.messages[index];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                UnifiedChatMessage(
                                  message: message.content,
                                  isFromUser: message.isFromUser,
                                  timestamp: message.timestamp,
                                  chatType: ChatType.agent,
                                ),
                                if (!message.isFromUser &&
                                    !message.happinessRated)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 56,
                                      right: 16,
                                      bottom: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'Was this helpful?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_up_outlined,
                                            size: 18,
                                          ),
                                          color: AppColors.success,
                                          onPressed: () async {
                                            await _rateLastAgentMessage(
                                              messageId: message.id,
                                              score: 0.9,
                                            );
                                          },
                                          tooltip: 'Helpful',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.thumb_down_outlined,
                                            size: 18,
                                          ),
                                          color: AppColors.error,
                                          onPressed: () async {
                                            await _rateLastAgentMessage(
                                              messageId: message.id,
                                              score: 0.1,
                                            );
                                          },
                                          tooltip: 'Not helpful',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
              if (_controller.recentDNAOverlay != null)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, val, child) {
                        return Opacity(
                          opacity: val,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - val)),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.black,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'DNA Evolving',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ..._controller.recentDNAOverlay!.entries
                                      .map((e) {
                                    final isPositive = e.value >= 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            e.key.replaceAll('_', ' '),
                                            style: const TextStyle(
                                              color: AppColors.grey300,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${isPositive ? '+' : ''}${e.value.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: isPositive
                                                  ? AppColors.success
                                                  : AppColors.error,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_controller.isSending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  'Agent is typing...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        if (_controller.lastError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _controller.lastError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          label: 'Chat privacy notice',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Private chat for guidance and reflection, not hidden app actions.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Messages are encrypted in transit. If something fails, we show it instead of quietly switching behavior. Avoid sharing highly sensitive personal details.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_controller.signaturePrompts.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _controller.signaturePrompts
                            .map(
                              (prompt) => ActionChip(
                                label: Text(prompt),
                                onPressed: () => _applyPromptSuggestion(prompt),
                                backgroundColor: AppColors.grey100,
                                side:
                                    const BorderSide(color: AppColors.grey300),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _inputFocusNode,
                          decoration: InputDecoration(
                            hintText:
                                'Ask what fits, why it fits, or what your agent should remember...',
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
                      Semantics(
                        label: 'Send message',
                        hint: 'Sends your message to your AI companion',
                        button: true,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: AppTheme.primaryColor,
                          ),
                          tooltip: 'Send message',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed:
                              _controller.isSending ? null : _sendMessage,
                        ),
                      ),
                    ],
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
