import 'package:avrai_runtime_os/config/bham_beta_defaults.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';

class BhamMessagingRetentionService {
  ChatRetentionPolicy retentionForThread(ChatThreadKind kind) {
    switch (kind) {
      case ChatThreadKind.personalAgent:
        return ChatRetentionPolicy(
          duration: BhamBetaDefaults.chatRetention.personalAi,
          untilContextReset: true,
        );
      case ChatThreadKind.admin:
        return ChatRetentionPolicy(
            duration: BhamBetaDefaults.chatRetention.admin);
      case ChatThreadKind.matchedDirect:
        return ChatRetentionPolicy(
          duration: BhamBetaDefaults.chatRetention.directMatched,
        );
      case ChatThreadKind.club:
      case ChatThreadKind.community:
        return ChatRetentionPolicy(
          duration: BhamBetaDefaults.chatRetention.group,
          allowPinnedSurvivor: true,
        );
      case ChatThreadKind.event:
        return const ChatRetentionPolicy(
          expiresAtEventEnd: true,
          allowPinnedSurvivor: true,
        );
      case ChatThreadKind.announcement:
        return const ChatRetentionPolicy(allowPinnedSurvivor: true);
    }
  }

  bool isExpired({
    required ChatThreadKind kind,
    required DateTime lastActivityAtUtc,
    DateTime? nowUtc,
    DateTime? eventEndsAtUtc,
    bool pinned = false,
    bool contextReset = false,
  }) {
    final now = nowUtc ?? DateTime.now().toUtc();
    final policy = retentionForThread(kind);
    if (policy.untilContextReset && contextReset) {
      return true;
    }
    if (policy.expiresAtEventEnd) {
      if (eventEndsAtUtc == null) {
        return false;
      }
      if (pinned && policy.allowPinnedSurvivor) {
        return now.isAfter(eventEndsAtUtc);
      }
      return !now.isBefore(eventEndsAtUtc);
    }
    if (policy.duration == null) {
      return false;
    }
    if (pinned && policy.allowPinnedSurvivor) {
      return false;
    }
    return now.difference(lastActivityAtUtc) > policy.duration!;
  }
}
