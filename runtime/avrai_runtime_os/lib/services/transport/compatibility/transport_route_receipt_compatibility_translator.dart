import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/messaging/bham_messaging_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:uuid/uuid.dart';

class TransportRouteReceiptCompatibilityTranslator {
  const TransportRouteReceiptCompatibilityTranslator._();

  static TransportRouteReceipt buildQueuedFallback({
    required String channel,
    DateTime? recordedAtUtc,
    String status = 'queued',
    bool localOnly = false,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final now = recordedAtUtc ?? DateTime.now().toUtc();
    return TransportRouteReceipt(
      receiptId: _receiptId(channel, now),
      channel: channel,
      status: status,
      recordedAtUtc: now,
      localOnly: localOnly,
      metadata: metadata,
    );
  }

  static TransportRouteReceipt buildLocalOnly({
    required String receiptId,
    required String channel,
    required String status,
    required DateTime recordedAtUtc,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return TransportRouteReceipt(
      receiptId: receiptId,
      channel: channel,
      status: status,
      recordedAtUtc: recordedAtUtc,
      localOnly: true,
      metadata: metadata,
    );
  }

  static TransportRouteReceipt buildQueuedFromRoutePlan({
    required TransportRoutePlan routePlan,
    required String channel,
    required DateTime expiresAtUtc,
    int? hopCount,
    String? fallbackReason,
    DateTime? recordedAtUtc,
  }) {
    final now = recordedAtUtc ?? DateTime.now().toUtc();
    return TransportRouteReceipt(
      receiptId: const Uuid().v4(),
      channel: channel,
      status: 'queued',
      recordedAtUtc: now,
      plannedRoutes: routePlan.candidateRoutes,
      attemptedRoutes: const <TransportRouteCandidate>[],
      queuedAtUtc: now,
      expiresAtUtc: expiresAtUtc,
      hopCount: hopCount,
      fallbackReason: fallbackReason,
      metadata: routePlan.metadata,
    );
  }

  static TransportRouteReceipt buildFieldValidation({
    required String receiptId,
    required String privacyMode,
    required String status,
    required String routeId,
    required String peerId,
    required String peerNodeId,
    required int hopCount,
    required DateTime recordedAtUtc,
    DateTime? queuedAtUtc,
    DateTime? deliveredAtUtc,
    DateTime? readAtUtc,
    String? readBy,
    DateTime? learningAppliedAtUtc,
    String? learningAppliedBy,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final route = TransportRouteCandidate(
      routeId: routeId,
      mode: routeId.startsWith('cloud')
          ? TransportMode.cloudAssist
          : TransportMode.ble,
      confidence: 0.88,
      estimatedLatencyMs: routeId.startsWith('cloud') ? 420 : 95,
      rationale: 'field_validation',
      metadata: <String, dynamic>{
        'peer_id': peerId,
        'peer_node_id': peerNodeId,
        'mesh_interface_id':
            routeId.startsWith('cloud') ? 'federated_cloud' : 'ble',
        'mesh_interface_kind': routeId.startsWith('cloud')
            ? MeshInterfaceKind.federatedCloud.name
            : MeshInterfaceKind.ble.name,
        'mesh_hop_count': hopCount,
      },
    );
    return TransportRouteReceipt(
      receiptId: receiptId,
      channel: routeId.startsWith('cloud')
          ? 'mesh_cloud_custody'
          : 'mesh_ble_forward',
      status: status,
      recordedAtUtc: recordedAtUtc,
      localOnly: privacyMode != MeshTransportPrivacyMode.federatedCloud,
      plannedRoutes: <TransportRouteCandidate>[route],
      attemptedRoutes: status == 'queued'
          ? const <TransportRouteCandidate>[]
          : <TransportRouteCandidate>[route],
      winningRoute: status == 'queued' ? null : route,
      hopCount: hopCount,
      queuedAtUtc: queuedAtUtc,
      custodyAcceptedAtUtc: status == 'queued'
          ? null
          : recordedAtUtc.add(const Duration(seconds: 1)),
      custodyAcceptedBy: status == 'queued' ? null : peerNodeId,
      deliveredAtUtc: deliveredAtUtc,
      readAtUtc: readAtUtc,
      readBy: readBy,
      learningAppliedAtUtc: learningAppliedAtUtc,
      learningAppliedBy: learningAppliedBy,
      metadata: <String, dynamic>{
        'destination_id': peerId,
        'peer_id': peerId,
        'privacy_mode': privacyMode,
        'mesh_route_resolution_mode':
            metadata['mesh_route_resolution_mode']?.toString() ?? 'announce',
        ...metadata,
      },
    );
  }

  static TransportRouteReceipt buildMeshPlan({
    required String receiptId,
    required String channel,
    required DateTime recordedAtUtc,
    required List<TransportRouteCandidate> plannedRoutes,
    required String destinationId,
    required String senderNodeId,
    required String payloadKind,
    required int knownRouteCount,
    required bool storeCarryForwardAllowed,
    required String routeResolutionMode,
    String? geographicScope,
    Map<String, dynamic> payloadContext = const <String, dynamic>{},
  }) {
    return TransportRouteReceipt(
      receiptId: receiptId,
      channel: channel,
      status: plannedRoutes.isEmpty ? 'no_candidate' : 'planned',
      recordedAtUtc: recordedAtUtc,
      plannedRoutes: plannedRoutes,
      queuedAtUtc: recordedAtUtc,
      metadata: <String, dynamic>{
        'destination_id': destinationId,
        'sender_node_id': senderNodeId,
        'payload_kind': payloadKind,
        'candidate_count': plannedRoutes.length,
        'known_route_count': knownRouteCount,
        'store_carry_forward_allowed': storeCarryForwardAllowed,
        'mesh_route_resolution_mode': routeResolutionMode,
        if (geographicScope != null) 'geographic_scope': geographicScope,
        if (plannedRoutes.isNotEmpty)
          'mesh_interface_id':
              plannedRoutes.first.metadata['mesh_interface_id']?.toString(),
        if (plannedRoutes.isNotEmpty)
          'mesh_interface_kind':
              plannedRoutes.first.metadata['mesh_interface_kind']?.toString(),
        if (plannedRoutes.isNotEmpty)
          'mesh_announce_id':
              plannedRoutes.first.metadata['mesh_announce_id']?.toString(),
        if (plannedRoutes.isNotEmpty)
          'mesh_hop_count': plannedRoutes.first.metadata['mesh_hop_count'],
        if (plannedRoutes.isNotEmpty)
          'mesh_announce_expires_at_utc': plannedRoutes
              .first.metadata['mesh_announce_expires_at_utc']
              ?.toString(),
        ...payloadContext,
      },
    );
  }

  static TransportRouteReceipt buildMeshOutcome({
    required String receiptId,
    required String channel,
    required DateTime recordedAtUtc,
    required List<TransportRouteCandidate> plannedRoutes,
    required List<TransportRouteCandidate> attemptedRoutes,
    required TransportRouteCandidate? winningRoute,
    required DateTime? queuedAtUtc,
    required String payloadKind,
    required String routeResolutionMode,
    required List<String> forwardedPeerIds,
    required List<String> failedPeerIds,
    required Iterable<String> attemptedPeerIds,
    required String deliveryStage,
    required String? custodyOutboxEntryId,
    required String? geographicScope,
    required Map<String, dynamic> priorMetadata,
    required Map<String, dynamic> payloadContext,
    required String? fallbackReason,
  }) {
    final hasWinner = winningRoute != null;
    final status = hasWinner
        ? 'forwarded'
        : ((fallbackReason == 'mesh_deferred_to_custody')
            ? 'queued'
            : 'failed');
    return TransportRouteReceipt(
      receiptId: receiptId,
      channel: channel,
      status: status,
      recordedAtUtc: recordedAtUtc,
      plannedRoutes: plannedRoutes,
      attemptedRoutes: attemptedRoutes,
      winningRoute: winningRoute,
      winningRouteReason:
          hasWinner ? 'ble mesh candidate accepted packet batch' : null,
      hopCount: 1,
      queuedAtUtc: queuedAtUtc,
      releasedAtUtc:
          hasWinner || attemptedRoutes.isNotEmpty ? recordedAtUtc : null,
      custodyAcceptedAtUtc: hasWinner ? recordedAtUtc : null,
      custodyAcceptedBy: hasWinner
          ? winningRoute.metadata['peer_node_id']?.toString() ??
              winningRoute.metadata['peer_id']?.toString()
          : null,
      fallbackReason: hasWinner ? null : fallbackReason,
      metadata: <String, dynamic>{
        ...priorMetadata,
        'payload_kind': payloadKind,
        'forward_success_count': forwardedPeerIds.length,
        'forward_failure_count': failedPeerIds.length,
        'attempted_peer_ids': attemptedPeerIds.toList(),
        'delivery_stage': deliveryStage,
        'mesh_route_resolution_mode': routeResolutionMode,
        'mesh_interface_id':
            _winningMetadataValue(winningRoute, 'mesh_interface_id'),
        'mesh_interface_kind':
            _winningMetadataValue(winningRoute, 'mesh_interface_kind'),
        'mesh_announce_id':
            _winningMetadataValue(winningRoute, 'mesh_announce_id'),
        'mesh_hop_count': _winningMetadataValue(winningRoute, 'mesh_hop_count'),
        'mesh_announce_expires_at_utc':
            _winningMetadataValue(winningRoute, 'mesh_announce_expires_at_utc'),
        if (custodyOutboxEntryId != null)
          'custody_outbox_entry_id': custodyOutboxEntryId,
        if (geographicScope != null) 'geographic_scope': geographicScope,
        ...payloadContext,
      },
    );
  }

  static String _receiptId(String channel, DateTime recordedAtUtc) =>
      '$channel:${recordedAtUtc.microsecondsSinceEpoch}';

  static Object? _winningMetadataValue(
    TransportRouteCandidate? route,
    String key,
  ) {
    return route?.metadata[key];
  }
}
