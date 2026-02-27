import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/routing/learning_insight_mesh_forwarder.dart';
import 'package:avrai/core/ai2ai/routing/mesh_forwarding_context.dart';
import 'package:avrai/core/ai2ai/routing/mesh_forwarding_target_selector.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';

class PrekeyBundleMeshForwardingLane {
  const PrekeyBundleMeshForwardingLane._();

  static Future<void> forward({
    required SignalPreKeyBundle bundle,
    required String recipientId,
    required Iterable<String> discoveredNodeIds,
    required MeshForwardingContext context,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required AppLogger logger,
    required String logName,
    int maxCandidates = 2,
  }) async {
    try {
      if (adaptiveMeshService == null) {
        return;
      }

      if (!adaptiveMeshService.shouldForwardMessage(
        currentHop: 0,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.learningInsight,
        geographicScope: 'locality',
      )) {
        return;
      }

      final candidates = MeshForwardingTargetSelector.excludingRecipientAndLocalNode(
        discoveredNodeIds: discoveredNodeIds,
        recipientId: recipientId,
        localNodeId: localNodeId,
        maxCandidates: maxCandidates,
      );

      if (candidates.isEmpty) {
        return;
      }

      final forwardPayload = <String, dynamic>{
        'kind': 'prekey_bundle_forward',
        'recipient_id': recipientId,
        'prekey_bundle': bundle.toJson(),
        'hop': 1,
        'origin_id': recipientId,
        'scope': 'locality',
      };

      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: forwardPayload,
        geographicScope: 'locality',
        fireAndForgetSend: true,
        onForwarded: (_, peerRecipientId) {
          logger.debug(
            'Forwarded prekey bundle through mesh: $recipientId → $peerRecipientId',
            tag: logName,
          );
        },
        onForwardFailed: (_, peerRecipientId, error) {
          logger.debug(
            'Failed to forward prekey bundle to $peerRecipientId: $error',
            tag: logName,
          );
        },
      );
    } catch (e) {
      logger.debug('Error forwarding prekey bundle through mesh: $e',
          tag: logName);
    }
  }
}
