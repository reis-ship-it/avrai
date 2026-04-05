/// Unified Chat Page
///
/// Provides a unified interface for:
/// - Personality Agent Chat (AI companion)
/// - Friends Chats (1-on-1)
/// - Community/Club Chats (group)
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:avrai/theme/colors.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class UnifiedChatPage extends StatefulWidget {
  const UnifiedChatPage({super.key});

  @override
  State<UnifiedChatPage> createState() => _UnifiedChatPageState();
}

class _UnifiedChatPageState extends State<UnifiedChatPage> {
  final _messagingRuntimeService = GetIt.instance<MessagingRuntimeService>();
  final _directMatchService = GetIt.instance<DirectMatchService>();

  List<ChatThreadSummary> _threads = <ChatThreadSummary>[];
  List<DirectMatchResult> _pendingMatches = <DirectMatchResult>[];
  bool _isLoading = true;
  String? _userId;

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
    final threads = await _messagingRuntimeService.listThreadsForUser(userId);
    final allMatches = await _directMatchService.listActiveMatches(userId);
    if (!mounted) {
      return;
    }
    setState(() {
      _userId = userId;
      _threads = threads;
      _pendingMatches = allMatches
          .where((match) => !match.chatOpened && match.declineMessage == null)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _respondToMatch(
    DirectMatchResult result,
    bool accepted,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return;
    }
    await _directMatchService.respond(
      invitationId: result.invitation.invitationId,
      userId: userId,
      accepted: accepted,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Chat',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPrimaryAction(
                    icon: Icons.smart_toy,
                    title: 'Personal AI chat',
                    subtitle: 'Continue your local and online AI thread',
                    onTap: () => context.push('/chat/agent'),
                  ),
                  const SizedBox(height: 12),
                  _buildPrimaryAction(
                    icon: Icons.support_agent,
                    title: 'Admin support',
                    subtitle: 'Pseudonymous Birmingham beta support',
                    onTap: () => context.push('/chat/admin'),
                  ),
                  if (_pendingMatches.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Pending Matches',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._pendingMatches.map(_buildPendingMatchCard),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Threads',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_threads.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No messaging threads yet.'),
                      ),
                    )
                  else
                    ..._threads.map(_buildThreadCard),
                ],
              ),
            ),
    );
  }

  Widget _buildPrimaryAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPendingMatchCard(DirectMatchResult result) {
    final counterpartId = result.invitation.userAId == _userId
        ? result.invitation.userBId
        : result.invitation.userAId;
    final initials = counterpartId
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase()
        .padRight(2, 'X')
        .substring(0, 2);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'High-confidence match: $initials',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Compatibility ${(result.invitation.compatibilityScore * 100).toStringAsFixed(1)}% - both users must opt in before chat opens.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _respondToMatch(result, false),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _respondToMatch(result, true),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadCard(ChatThreadSummary thread) {
    return Card(
      child: ListTile(
        leading: Icon(_iconForKind(thread.kind)),
        title: Text(thread.title),
        subtitle: Text(thread.subtitle ?? thread.lastMessagePreview ?? ''),
        trailing: thread.unreadCount > 0
            ? CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.textPrimary,
                child: Text(
                  '${thread.unreadCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => _openThread(thread),
      ),
    );
  }

  IconData _iconForKind(ChatThreadKind kind) {
    switch (kind) {
      case ChatThreadKind.personalAgent:
        return Icons.smart_toy;
      case ChatThreadKind.admin:
        return Icons.support_agent;
      case ChatThreadKind.matchedDirect:
        return Icons.lock_outline;
      case ChatThreadKind.club:
        return Icons.groups_2_outlined;
      case ChatThreadKind.community:
        return Icons.group_outlined;
      case ChatThreadKind.event:
        return Icons.event_outlined;
      case ChatThreadKind.announcement:
        return Icons.campaign_outlined;
    }
  }

  void _openThread(ChatThreadSummary thread) {
    switch (thread.kind) {
      case ChatThreadKind.personalAgent:
        context.push('/chat/agent');
        break;
      case ChatThreadKind.admin:
        context.push('/chat/admin');
        break;
      case ChatThreadKind.matchedDirect:
        final counterpartId = thread.metadata['counterpart_id']?.toString();
        if (counterpartId != null) {
          context.push('/chat/friend/$counterpartId');
        }
        break;
      case ChatThreadKind.club:
      case ChatThreadKind.community:
        final communityId =
            thread.metadata['community_id']?.toString() ?? thread.threadId;
        context.push('/chat/community/$communityId');
        break;
      case ChatThreadKind.event:
        context.push(
            '/chat/event/${thread.threadId.split(':').last}?title=${Uri.encodeComponent(thread.title)}');
        break;
      case ChatThreadKind.announcement:
        final segments = thread.threadId.split(':');
        if (segments.length >= 3) {
          context.push(
            '/chat/announcement/${segments[1]}/${segments[2]}?title=${Uri.encodeComponent(thread.title)}',
          );
        }
        break;
    }
  }
}
