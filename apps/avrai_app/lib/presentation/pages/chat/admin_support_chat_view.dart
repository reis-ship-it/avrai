library;

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/widgets/chat/unified_chat_message.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai_runtime_os/services/messaging/admin_support_chat_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class AdminSupportChatView extends StatefulWidget {
  const AdminSupportChatView({super.key});

  @override
  State<AdminSupportChatView> createState() => _AdminSupportChatViewState();
}

class _AdminSupportChatViewState extends State<AdminSupportChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = GetIt.instance<AdminSupportChatService>();

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
    final userId = authState.user.id;
    final history = await _chatService.getConversationHistory(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _userId = userId;
      _messages = history;
    });
  }

  Future<void> _send() async {
    final userId = _userId;
    final body = _messageController.text.trim();
    if (userId == null || body.isEmpty) {
      return;
    }
    _messageController.clear();
    setState(() {
      _isSending = true;
    });
    final message = await _chatService.sendMessage(userId: userId, body: body);
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
      title: 'Admin Support',
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.grey100,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Pseudonymous support thread for the Birmingham beta.',
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return UnifiedChatMessage(
                  message: message.body,
                  isFromUser: message.senderId == _userId,
                  timestamp: message.createdAtUtc.toLocal(),
                  chatType: ChatType.friend,
                  senderName: message.senderId == 'admin' ? 'Admin' : null,
                );
              },
            ),
          ),
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
                        hintText: 'Send a support update',
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
