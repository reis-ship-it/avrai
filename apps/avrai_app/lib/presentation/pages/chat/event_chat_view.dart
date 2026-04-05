library;

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/event_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class EventChatView extends StatefulWidget {
  const EventChatView({
    super.key,
    required this.threadId,
    required this.title,
    this.readOnly = false,
  });

  final String threadId;
  final String title;
  final bool readOnly;

  @override
  State<EventChatView> createState() => _EventChatViewState();
}

class _EventChatViewState extends State<EventChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _eventChatService = GetIt.instance<EventChatService>();

  List<BhamThreadMessage> _messages = <BhamThreadMessage>[];
  String? _userId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return;
    }
    final history = await _eventChatService.getThreadHistory(widget.threadId);
    if (!mounted) {
      return;
    }
    setState(() {
      _userId = authState.user.id;
      _messages = history;
    });
  }

  Future<void> _send() async {
    if (widget.readOnly || _userId == null) {
      return;
    }
    final body = _messageController.text.trim();
    if (body.isEmpty) {
      return;
    }
    _messageController.clear();
    setState(() {
      _isSending = true;
    });
    final eventId = widget.threadId.split(':').last;
    final message = await _eventChatService.sendEventMessage(
      userId: _userId!,
      eventId: eventId,
      body: body,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSending = false;
      _messages = <BhamThreadMessage>[..._messages, message];
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: widget.title,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final senderLabel = message.metadata['sender_role']?.toString();
                return UnifiedChatMessage(
                  message: message.body,
                  isFromUser: message.senderId == _userId,
                  timestamp: message.createdAtUtc.toLocal(),
                  chatType: ChatType.community,
                  senderName: message.senderId == _userId ? null : senderLabel,
                );
              },
            ),
          ),
          if (!widget.readOnly)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Send a message',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSending ? null : _send,
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
