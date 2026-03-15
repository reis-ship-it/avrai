import 'package:avrai_core/models/business/business_business_message.dart';
import 'package:avrai_core/models/business/business_expert_message.dart';
import 'package:avrai_runtime_os/ai2ai/models/community_chat_message.dart';
import 'package:avrai_runtime_os/ai2ai/models/friend_chat_message.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';

enum HumanChatProjectionStatus {
  sending,
  delivered,
  read,
  aiLearningUpdated,
}

class HumanChatReadModel {
  const HumanChatReadModel({
    required this.messageId,
    required this.occurredAtUtc,
    required this.status,
    this.routeReceipt,
    this.readAtUtc,
    this.aiLearningUpdatedAtUtc,
    this.metadata = const <String, dynamic>{},
  });

  final String messageId;
  final DateTime occurredAtUtc;
  final HumanChatProjectionStatus status;
  final TransportRouteReceipt? routeReceipt;
  final DateTime? readAtUtc;
  final DateTime? aiLearningUpdatedAtUtc;
  final Map<String, dynamic> metadata;
}

class HumanChatProjectionLayer {
  const HumanChatProjectionLayer();

  static const String routeReceiptMetadataKey = 'transport_route_receipt';

  HumanChatReadModel project({
    required String messageId,
    required DateTime occurredAtUtc,
    required Map<String, dynamic>? metadata,
    bool isRead = false,
    DateTime? explicitReadAtUtc,
  }) {
    final routeReceipt = routeReceiptFromMetadata(metadata);
    final readAtUtc =
        explicitReadAtUtc ?? routeReceipt?.readAtUtc ?? (isRead ? occurredAtUtc : null);
    final learningAtUtc = routeReceipt?.learningAppliedAtUtc;
    final status = learningAtUtc != null
        ? HumanChatProjectionStatus.aiLearningUpdated
        : readAtUtc != null
            ? HumanChatProjectionStatus.read
            : routeReceipt?.deliveredAtUtc != null
                ? HumanChatProjectionStatus.delivered
                : HumanChatProjectionStatus.sending;
    return HumanChatReadModel(
      messageId: messageId,
      occurredAtUtc: occurredAtUtc.toUtc(),
      status: status,
      routeReceipt: routeReceipt,
      readAtUtc: readAtUtc?.toUtc(),
      aiLearningUpdatedAtUtc: learningAtUtc?.toUtc(),
      metadata: Map<String, dynamic>.from(metadata ?? const <String, dynamic>{}),
    );
  }

  HumanChatReadModel fromFriendMessage(FriendChatMessage message) {
    return project(
      messageId: message.messageId,
      occurredAtUtc: message.timestamp,
      metadata: message.metadata,
      isRead: message.isRead,
    );
  }

  HumanChatReadModel fromCommunityMessage(CommunityChatMessage message) {
    return project(
      messageId: message.messageId,
      occurredAtUtc: message.timestamp,
      metadata: message.metadata,
    );
  }

  HumanChatReadModel fromBusinessExpertMessage(BusinessExpertMessage message) {
    return project(
      messageId: message.id,
      occurredAtUtc: message.createdAt,
      metadata: message.metadata,
      isRead: message.isRead,
      explicitReadAtUtc: message.readAt,
    );
  }

  HumanChatReadModel fromBusinessBusinessMessage(
    BusinessBusinessMessage message,
  ) {
    return project(
      messageId: message.id,
      occurredAtUtc: message.createdAt,
      metadata: message.metadata,
      isRead: message.isRead,
      explicitReadAtUtc: message.readAt,
    );
  }

  static TransportRouteReceipt? routeReceiptFromMetadata(
    Map<String, dynamic>? metadata,
  ) {
    if (metadata == null) {
      return null;
    }
    final raw = metadata[routeReceiptMetadataKey];
    if (raw is Map<String, dynamic>) {
      return TransportRouteReceipt.fromJson(raw);
    }
    if (raw is Map) {
      return TransportRouteReceipt.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
