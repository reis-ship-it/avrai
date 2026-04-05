// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/discovery/event_mode_candidate.dart';
import 'package:avrai_runtime_os/services/transport/ble/event_mode_initiator_policy.dart';

class EventModeTargetSelector {
  const EventModeTargetSelector._();

  static EventModeCandidate? select({
    required List<EventModeCandidate> candidates,
    required int nowMs,
    required int epoch,
    required String localNodeTagKey,
    required Map<String, int> lastDeepSyncAtMsByNodeTag,
    required Map<String, int> familiarityByNodeTag,
    required int perNodeDeepSyncCooldownMs,
  }) {
    final eligible = candidates
        .where((candidate) => candidate.remoteConnectOk)
        .where((candidate) => EventModeInitiatorPolicy.isTieBreakInitiator(
              localNodeTagKey: localNodeTagKey,
              remoteNodeTagKey: candidate.nodeTagKey,
              epoch: epoch,
            ))
        .where((candidate) {
      final last = lastDeepSyncAtMsByNodeTag[candidate.nodeTagKey];
      if (last == null) return true;
      return (nowMs - last) >= perNodeDeepSyncCooldownMs;
    }).toList();
    if (eligible.isEmpty) return null;

    eligible.sort((a, b) {
      final familiarityA = familiarityByNodeTag[a.nodeTagKey] ?? 0;
      final familiarityB = familiarityByNodeTag[b.nodeTagKey] ?? 0;
      return familiarityB.compareTo(familiarityA);
    });

    return eligible.first;
  }
}
