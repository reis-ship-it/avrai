import 'package:avrai_core/models/community/community.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_chat_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/messaging/admin_support_chat_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/messaging/direct_match_service.dart';
import 'package:avrai_runtime_os/services/messaging/event_chat_service.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_retention_service.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';

class MessagingRuntimeService {
  MessagingRuntimeService({
    required PersonalityAgentChatService personalityAgentChatService,
    required FriendChatService friendChatService,
    required CommunityChatService communityChatService,
    required CommunityService communityService,
    required ClubService clubService,
    required AdminSupportChatService adminSupportChatService,
    required EventChatService eventChatService,
    required DirectMatchService directMatchService,
    BhamMessagingRetentionService? retentionService,
  })  : _personalityAgentChatService = personalityAgentChatService,
        _friendChatService = friendChatService,
        _communityChatService = communityChatService,
        _communityService = communityService,
        _clubService = clubService,
        _adminSupportChatService = adminSupportChatService,
        _eventChatService = eventChatService,
        _directMatchService = directMatchService,
        _retentionService = retentionService ?? BhamMessagingRetentionService();

  final PersonalityAgentChatService _personalityAgentChatService;
  final FriendChatService _friendChatService;
  final CommunityChatService _communityChatService;
  final CommunityService _communityService;
  final ClubService _clubService;
  final AdminSupportChatService _adminSupportChatService;
  final EventChatService _eventChatService;
  final DirectMatchService _directMatchService;
  final BhamMessagingRetentionService _retentionService;

  Future<List<ChatThreadSummary>> listThreadsForUser(String userId) async {
    final summaries = <ChatThreadSummary>[
      await _agentSummary(userId),
      await _adminSupportChatService.getThreadSummary(userId),
      ...await _matchedDirectSummaries(userId),
      ...await _groupSummaries(userId),
      ...await _eventChatService.listThreadsForUser(userId),
    ];
    return summaries.where((summary) => !_isExpired(summary)).toList()
      ..sort((a, b) => b.lastActivityAtUtc.compareTo(a.lastActivityAtUtc));
  }

  Future<ChatThreadSummary> _agentSummary(String userId) async {
    final history =
        await _personalityAgentChatService.getConversationHistory(userId);
    final last = history.isEmpty ? null : history.first;
    return ChatThreadSummary(
      threadId: 'personal_agent:$userId',
      kind: ChatThreadKind.personalAgent,
      title: 'Your AI',
      subtitle: 'Personal AI chat',
      lastActivityAtUtc: last?.timestamp.toUtc() ?? DateTime.now().toUtc(),
      lastMessagePreview: last == null ? null : 'Recent AI conversation',
      visibilityState: ThreadVisibilityState.active,
    );
  }

  Future<List<ChatThreadSummary>> _matchedDirectSummaries(String userId) async {
    final results = await _directMatchService.listActiveMatches(userId);
    final summaries = <ChatThreadSummary>[];
    for (final result in results.where((entry) => entry.chatOpened)) {
      final counterpartId = result.invitation.userAId == userId
          ? result.invitation.userBId
          : result.invitation.userAId;
      final previews = await _friendChatService.getFriendsChatList(
        userId,
        <String>[counterpartId],
        friendNames: <String, String>{
          counterpartId: _privacyPreservingName(counterpartId),
        },
      );
      final preview = previews.isEmpty ? null : previews.first;
      summaries.add(
        ChatThreadSummary(
          threadId: result.chatThreadId ?? 'matched_direct:$counterpartId',
          kind: ChatThreadKind.matchedDirect,
          title: preview?.friendName ?? _privacyPreservingName(counterpartId),
          subtitle: 'Mutual high-confidence match',
          lastActivityAtUtc: preview?.lastMessageTime?.toUtc() ??
              result.invitation.createdAtUtc,
          lastMessagePreview: preview?.lastMessagePreview,
          unreadCount: preview?.unreadCount ?? 0,
          visibilityState: ThreadVisibilityState.active,
          participants: <ChatParticipantPresentation>[
            ChatParticipantPresentation(
              participantId: counterpartId,
              displayName: _privacyPreservingName(counterpartId),
              initials: _privacyPreservingName(counterpartId),
            ),
          ],
          metadata: <String, dynamic>{
            'counterpart_id': counterpartId,
            'invitation_id': result.invitation.invitationId,
          },
        ),
      );
    }
    return summaries;
  }

  Future<List<ChatThreadSummary>> _groupSummaries(String userId) async {
    final communities = await _communityService.getAllCommunities();
    final clubs = await _clubService.getAllClubs();
    final joinedCommunities = communities.where((community) {
      return community.memberIds.contains(userId);
    }).toList();
    final joinedClubs =
        clubs.where((club) => club.memberIds.contains(userId)).toList();
    final communityPreviews =
        await _communityChatService.getUserCommunitiesChatList(
      userId,
      <Community>[...joinedCommunities, ...joinedClubs.cast<Community>()],
    );

    return communityPreviews.map((preview) {
      final kind = joinedClubs.any((club) => club.id == preview.communityId)
          ? ChatThreadKind.club
          : ChatThreadKind.community;
      return ChatThreadSummary(
        threadId: preview.communityId,
        kind: kind,
        title: preview.communityName,
        subtitle: kind == ChatThreadKind.club ? 'Club chat' : 'Community chat',
        lastActivityAtUtc:
            preview.lastMessageTime?.toUtc() ?? DateTime.now().toUtc(),
        lastMessagePreview: preview.lastMessagePreview,
        visibilityState: ThreadVisibilityState.active,
        metadata: <String, dynamic>{'community_id': preview.communityId},
      );
    }).toList();
  }

  bool _isExpired(ChatThreadSummary summary) {
    return _retentionService.isExpired(
      kind: summary.kind,
      lastActivityAtUtc: summary.lastActivityAtUtc,
      pinned: summary.pinned,
    );
  }

  String _privacyPreservingName(String userId) {
    final sanitized =
        userId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (sanitized.length >= 2) {
      return sanitized.substring(0, 2);
    }
    return sanitized.isEmpty ? 'AN' : '${sanitized}X';
  }
}
