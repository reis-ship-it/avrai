import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

enum ChatThreadKind {
  personalAgent,
  admin,
  matchedDirect,
  club,
  community,
  event,
  announcement,
}

enum ThreadVisibilityState { active, left, expired, quarantined }

enum NotificationClass {
  dailyDrop,
  contextNudge,
  ai2aiCompatibility,
  humanMessage,
}

class ChatParticipantPresentation {
  const ChatParticipantPresentation({
    required this.participantId,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
    this.pseudonymous = true,
    this.roleLabel,
  });

  final String participantId;
  final String displayName;
  final String initials;
  final String? avatarUrl;
  final bool pseudonymous;
  final String? roleLabel;
}

class ChatRetentionPolicy {
  const ChatRetentionPolicy({
    this.duration,
    this.untilContextReset = false,
    this.expiresAtEventEnd = false,
    this.allowPinnedSurvivor = false,
  });

  final Duration? duration;
  final bool untilContextReset;
  final bool expiresAtEventEnd;
  final bool allowPinnedSurvivor;
}

class ChatThreadSummary {
  const ChatThreadSummary({
    required this.threadId,
    required this.kind,
    required this.title,
    required this.lastActivityAtUtc,
    required this.visibilityState,
    this.subtitle,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.participants = const <ChatParticipantPresentation>[],
    this.routeReceipt,
    this.canPost = true,
    this.pinned = false,
    this.metadata = const <String, dynamic>{},
  });

  final String threadId;
  final ChatThreadKind kind;
  final String title;
  final String? subtitle;
  final String? lastMessagePreview;
  final DateTime lastActivityAtUtc;
  final int unreadCount;
  final List<ChatParticipantPresentation> participants;
  final ThreadVisibilityState visibilityState;
  final TransportRouteReceipt? routeReceipt;
  final bool canPost;
  final bool pinned;
  final Map<String, dynamic> metadata;
}

class NotificationBudgetPolicy {
  const NotificationBudgetPolicy({
    required this.quietHoursStartHour,
    required this.quietHoursEndHour,
    required this.cappedClasses,
    required this.maxPerDay,
  });

  final int quietHoursStartHour;
  final int quietHoursEndHour;
  final List<NotificationClass> cappedClasses;
  final int maxPerDay;
}

class QueuedTransportEnvelope {
  const QueuedTransportEnvelope({
    required this.envelopeId,
    required this.payloadType,
    required this.threadKind,
    required this.createdAtUtc,
    required this.expiresAtUtc,
    required this.routePlan,
    this.routeReceipt,
    this.priority = 0,
    this.syncState = 'queued',
    this.metadata = const <String, dynamic>{},
  });

  final String envelopeId;
  final String payloadType;
  final ChatThreadKind threadKind;
  final DateTime createdAtUtc;
  final DateTime expiresAtUtc;
  final TransportRoutePlan routePlan;
  final TransportRouteReceipt? routeReceipt;
  final int priority;
  final String syncState;
  final Map<String, dynamic> metadata;
}

class TransportRoutePlan {
  const TransportRoutePlan({
    required this.planId,
    required this.createdAtUtc,
    required this.candidateRoutes,
    this.exploratory = false,
    this.metadata = const <String, dynamic>{},
  });

  final String planId;
  final DateTime createdAtUtc;
  final List<TransportRouteCandidate> candidateRoutes;
  final bool exploratory;
  final Map<String, dynamic> metadata;
}

class RouteLearningSignal {
  const RouteLearningSignal({
    required this.messageId,
    required this.mode,
    required this.success,
    required this.observedAtUtc,
    this.latencyMs,
    this.locality,
    this.timeBucket,
    this.metadata = const <String, dynamic>{},
  });

  final String messageId;
  final TransportMode mode;
  final bool success;
  final DateTime observedAtUtc;
  final int? latencyMs;
  final String? locality;
  final String? timeBucket;
  final Map<String, dynamic> metadata;
}

class DirectMatchInvitation {
  const DirectMatchInvitation({
    required this.invitationId,
    required this.userAId,
    required this.userBId,
    required this.compatibilityScore,
    required this.createdAtUtc,
    this.status = 'pending',
  });

  final String invitationId;
  final String userAId;
  final String userBId;
  final double compatibilityScore;
  final DateTime createdAtUtc;
  final String status;
}

class DirectMatchDecision {
  const DirectMatchDecision({
    required this.invitationId,
    required this.userId,
    required this.accepted,
    required this.decidedAtUtc,
  });

  final String invitationId;
  final String userId;
  final bool accepted;
  final DateTime decidedAtUtc;
}

class DirectMatchResult {
  const DirectMatchResult({
    required this.invitation,
    required this.decisions,
    required this.chatOpened,
    this.chatThreadId,
    this.declineMessage,
  });

  final DirectMatchInvitation invitation;
  final List<DirectMatchDecision> decisions;
  final bool chatOpened;
  final String? chatThreadId;
  final String? declineMessage;
}

class AnnouncementMessage {
  const AnnouncementMessage({
    required this.threadId,
    required this.messageId,
    required this.title,
    required this.body,
    required this.createdAtUtc,
    this.senderRole = 'leader',
  });

  final String threadId;
  final String messageId;
  final String title;
  final String body;
  final DateTime createdAtUtc;
  final String senderRole;
}

class DeliveryFailureSummary {
  const DeliveryFailureSummary({
    required this.messageId,
    required this.threadId,
    required this.reason,
    required this.recordedAtUtc,
    this.routeReceipt,
  });

  final String messageId;
  final String threadId;
  final String reason;
  final DateTime recordedAtUtc;
  final TransportRouteReceipt? routeReceipt;
}

class AdminCommunicationSummary {
  const AdminCommunicationSummary({
    required this.threadId,
    required this.threadKind,
    required this.messageCount,
    required this.lastActivityAtUtc,
    this.lastMessagePreview,
    this.routeReceipt,
  });

  final String threadId;
  final ChatThreadKind threadKind;
  final int messageCount;
  final DateTime lastActivityAtUtc;
  final String? lastMessagePreview;
  final TransportRouteReceipt? routeReceipt;
}

class BhamThreadMessage {
  const BhamThreadMessage({
    required this.messageId,
    required this.threadId,
    required this.threadKind,
    required this.senderId,
    required this.body,
    required this.createdAtUtc,
    this.readOnly = false,
    this.pinned = false,
    this.routeReceipt,
    this.metadata = const <String, dynamic>{},
  });

  final String messageId;
  final String threadId;
  final ChatThreadKind threadKind;
  final String senderId;
  final String body;
  final DateTime createdAtUtc;
  final bool readOnly;
  final bool pinned;
  final TransportRouteReceipt? routeReceipt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'message_id': messageId,
        'thread_id': threadId,
        'thread_kind': threadKind.name,
        'sender_id': senderId,
        'body': body,
        'created_at_utc': createdAtUtc.toUtc().toIso8601String(),
        'read_only': readOnly,
        'pinned': pinned,
        if (routeReceipt != null) 'route_receipt': routeReceipt!.toJson(),
        'metadata': metadata,
      };

  factory BhamThreadMessage.fromJson(Map<String, dynamic> json) {
    return BhamThreadMessage(
      messageId: json['message_id'] as String? ?? 'unknown_message',
      threadId: json['thread_id'] as String? ?? 'unknown_thread',
      threadKind: ChatThreadKind.values.firstWhere(
        (kind) => kind.name == json['thread_kind'],
        orElse: () => ChatThreadKind.personalAgent,
      ),
      senderId: json['sender_id'] as String? ?? 'unknown_sender',
      body: json['body'] as String? ?? '',
      createdAtUtc:
          DateTime.tryParse(json['created_at_utc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      readOnly: json['read_only'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      routeReceipt: json['route_receipt'] is Map
          ? TransportRouteReceipt.fromJson(
              Map<String, dynamic>.from(json['route_receipt'] as Map),
            )
          : null,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
