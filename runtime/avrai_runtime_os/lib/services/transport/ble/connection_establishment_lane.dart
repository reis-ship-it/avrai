// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/transport/ble/braided_knot_connection_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_identity_binding_lane.dart';
import 'package:avrai_runtime_os/services/transport/ble/connection_request_encoding_lane.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_network/avra_network.dart';

class ConnectionEstablishmentLane {
  const ConnectionEstablishmentLane._();

  static Future<ConnectionMetrics?> establish({
    required AI2AIProtocol? protocol,
    required SignalKeyManager? signalKeyManager,
    required KnotWeavingService? knotWeavingService,
    required KnotStorageService? knotStorageService,
    required UserVibe localVibe,
    required AIPersonalityNode remoteNode,
    required VibeCompatibilityResult compatibility,
    required ConnectionMetrics initialMetrics,
    required String localAgentId,
    required String remoteAgentId,
    required AppLogger logger,
    required String logName,
  }) async {
    try {
      await ConnectionRequestEncodingLane.maybeEncode(
        protocol: protocol,
        localVibeArchetype: localVibe.getVibeArchetype(),
        remoteVibeArchetype: remoteNode.vibe.getVibeArchetype(),
        initialCompatibility: compatibility.basicCompatibility,
        connectionId: initialMetrics.connectionId,
        senderNodeId: initialMetrics.localAISignature,
        recipientNodeId: remoteNode.nodeId,
        logger: logger,
        logName: logName,
      );

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final initialInteraction = InteractionEvent.success(
        type: InteractionType.vibeExchange,
        data: <String, dynamic>{
          'local_vibe_archetype': localVibe.getVibeArchetype(),
          'remote_vibe_archetype': remoteNode.vibe.getVibeArchetype(),
          'initial_compatibility': compatibility.basicCompatibility,
        },
      );

      final braidedKnot = await BraidedKnotConnectionLane.maybeCreate(
        knotWeavingService: knotWeavingService,
        knotStorageService: knotStorageService,
        localAgentId: localAgentId,
        remoteAgentId: remoteAgentId,
        connectionId: initialMetrics.connectionId,
        logger: logger,
        logName: logName,
      );

      final identityBinding = await ConnectionIdentityBindingLane.collect(
        signalKeyManager: signalKeyManager,
        remoteAgentId: remoteAgentId,
        connectionId: initialMetrics.connectionId,
        logger: logger,
        logName: logName,
      );

      return initialMetrics.updateDuringInteraction(
        newInteraction: initialInteraction,
        additionalOutcomes: <String, dynamic>{
          'successful_exchanges': 1,
          if (braidedKnot != null) 'braided_knot_id': braidedKnot.id,
        },
        handshakeHash: identityBinding.handshakeHash,
        localAgentFingerprint: identityBinding.localAgentFingerprint,
        remoteAgentFingerprint: identityBinding.remoteAgentFingerprint,
      );
    } catch (e) {
      logger.error('Error in connection establishment', error: e, tag: logName);
      return null;
    }
  }
}
