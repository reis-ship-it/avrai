import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/compatibility/transport_route_receipt_compatibility_translator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_producer_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';

class _MeshPlannedRoutes {
  const _MeshPlannedRoutes({
    required this.routes,
    required this.routeResolutionMode,
  });

  final List<TransportRouteCandidate> routes;
  final String routeResolutionMode;
}

class MeshGovernanceForwardPlan {
  const MeshGovernanceForwardPlan({
    required this.planningId,
    required this.routeReceipt,
    this.recordId,
  });

  final String planningId;
  final TransportRouteReceipt routeReceipt;
  final String? recordId;
}

class MeshGovernanceForwardOutcome {
  const MeshGovernanceForwardOutcome({
    required this.routeReceipt,
    this.recordId,
  });

  final TransportRouteReceipt routeReceipt;
  final String? recordId;
}

class MeshRuntimeGovernanceOrchestrationLane {
  const MeshRuntimeGovernanceOrchestrationLane._();

  static Future<MeshGovernanceForwardPlan> recordForwardPlan({
    required MeshForwardingContext context,
    required List<String> candidatePeerIds,
    required String senderNodeId,
    required String destinationId,
    required String payloadKind,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    String channel = 'mesh_ble_forward',
    String? geographicScope,
    Map<String, dynamic> payloadContext = const <String, dynamic>{},
  }) async {
    final now = DateTime.now().toUtc();
    final planningId = _idFor('mesh-plan');
    final knownRouteCount =
        context.routeLedger?.knownRouteCount(destinationId) ?? 0;
    final plannedRouteEnvelope = await _buildRouteCandidates(
      context: context,
      candidatePeerIds: candidatePeerIds,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      geographicScope: geographicScope,
      destinationId: destinationId,
    );
    final plannedRoutes = plannedRouteEnvelope.routes;
    final routeReceipt =
        TransportRouteReceiptCompatibilityTranslator.buildMeshPlan(
      receiptId: planningId,
      channel: channel,
      recordedAtUtc: now,
      plannedRoutes: plannedRoutes,
      destinationId: destinationId,
      senderNodeId: senderNodeId,
      payloadKind: payloadKind,
      knownRouteCount: knownRouteCount,
      storeCarryForwardAllowed: context.custodyOutbox != null,
      routeResolutionMode: plannedRouteEnvelope.routeResolutionMode,
      geographicScope: geographicScope,
      payloadContext: payloadContext,
    );

    final governanceBindingService = context.governanceBindingService;
    if (governanceBindingService == null) {
      return MeshGovernanceForwardPlan(
        planningId: planningId,
        routeReceipt: routeReceipt,
      );
    }

    final request = await governanceBindingService.buildMeshPlanningRequest(
      planningId: planningId,
      destinationId: destinationId,
      envelope: _buildEnvelope(
        eventType: 'mesh_forward_plan',
        actionType: 'forward',
        entityId: planningId,
        entityType: payloadKind,
        occurredAtUtc: now,
        routeReceipt: routeReceipt,
        senderNodeId: senderNodeId,
        context: context,
        payloadContext: payloadContext,
      ),
      routeReceipt: routeReceipt,
      storeCarryForwardAllowed: context.custodyOutbox != null,
      runtimeContext: <String, dynamic>{
        'mesh_channel': channel,
        'payload_kind': payloadKind,
        'mesh_route_resolution_mode': plannedRouteEnvelope.routeResolutionMode,
      },
      policyContext: <String, dynamic>{
        'payload_kind': payloadKind,
        'channel': channel,
      },
      predictedOutcome: plannedRoutes.isEmpty
          ? 'mesh_no_candidate_available'
          : 'mesh_forward_candidate_selected',
      predictedConfidence: _planningConfidence(plannedRoutes),
      coreSignals: <WhySignal>[
        WhySignal(
          label: 'candidate_count',
          weight: _candidateWeight(plannedRoutes.length),
          source: 'mesh_runtime',
          durable: true,
        ),
        WhySignal(
          label: 'best_route_confidence',
          weight: _planningConfidence(plannedRoutes),
          source: 'mesh_runtime',
        ),
      ],
      memoryContext: <String, dynamic>{
        'planned_route_ids':
            plannedRoutes.map((route) => route.routeId).toList(),
      },
      severity: plannedRoutes.isEmpty ? 'warning' : 'info',
    );

    final recordId = request.runtimeContext['governance_record_id']?.toString();
    final kernelPlan = context.meshKernel == null
        ? null
        : await context.meshKernel!.planTransport(request);
    if (recordId != null) {
      logger.debug(
        'Recorded governed mesh plan for $payloadKind: $recordId',
        tag: logName,
      );
    }

    return MeshGovernanceForwardPlan(
      planningId: planningId,
      routeReceipt: kernelPlan?.routeReceipt ?? routeReceipt,
      recordId: recordId,
    );
  }

  static Future<MeshGovernanceForwardOutcome> recordForwardOutcome({
    required MeshForwardingContext context,
    required MeshGovernanceForwardPlan plan,
    required String senderNodeId,
    required String destinationId,
    required String payloadKind,
    required List<String> forwardedPeerIds,
    required List<String> failedPeerIds,
    required AppLogger logger,
    required String logName,
    String channel = 'mesh_ble_forward',
    String? geographicScope,
    String? failureReason,
    bool deferredToCustody = false,
    String? custodyOutboxEntryId,
    Map<String, dynamic> payloadContext = const <String, dynamic>{},
  }) async {
    final now = DateTime.now().toUtc();
    final attemptedPeerIds = <String>{...forwardedPeerIds, ...failedPeerIds};
    final attemptedRoutes = plan.routeReceipt.plannedRoutes
        .where(
          (route) => attemptedPeerIds.contains(route.metadata['peer_id']),
        )
        .map(
          (route) => _copyRouteCandidate(
            route,
            metadata: <String, dynamic>{
              ...route.metadata,
              'attempt_status': forwardedPeerIds.contains(
                route.metadata['peer_id'],
              )
                  ? 'forwarded'
                  : 'failed',
            },
          ),
        )
        .toList();
    final winningRoute = attemptedRoutes.firstWhere(
      (route) => route.metadata['attempt_status'] == 'forwarded',
      orElse: () => const TransportRouteCandidate(
        routeId: '',
        mode: TransportMode.ble,
        confidence: 0.0,
        estimatedLatencyMs: 0,
      ),
    );
    final hasWinner = winningRoute.routeId.isNotEmpty;
    final deferred = !hasWinner && deferredToCustody;
    final deliveryStage =
        hasWinner ? 'custody_accepted' : (deferred ? 'queued' : 'failed');
    final outcomeReason = deferred
        ? 'mesh_deferred_to_custody'
        : (failureReason ?? 'mesh_forward_failed');
    final resolutionMode = deferred &&
            plan.routeReceipt.metadata['mesh_route_resolution_mode'] ==
                'cloud_custody'
        ? 'cloud_custody'
        : (plan.routeReceipt.metadata['mesh_route_resolution_mode']
                ?.toString() ??
            'historical_fallback_none');

    final routeReceipt =
        TransportRouteReceiptCompatibilityTranslator.buildMeshOutcome(
      receiptId: plan.routeReceipt.receiptId,
      channel: channel,
      recordedAtUtc: now,
      plannedRoutes: plan.routeReceipt.plannedRoutes,
      attemptedRoutes: attemptedRoutes,
      winningRoute: hasWinner ? winningRoute : null,
      queuedAtUtc: plan.routeReceipt.queuedAtUtc,
      payloadKind: payloadKind,
      routeResolutionMode: resolutionMode,
      forwardedPeerIds: forwardedPeerIds,
      failedPeerIds: failedPeerIds,
      attemptedPeerIds: attemptedPeerIds,
      deliveryStage: deliveryStage,
      custodyOutboxEntryId: custodyOutboxEntryId,
      geographicScope: geographicScope,
      priorMetadata: plan.routeReceipt.metadata,
      payloadContext: payloadContext,
      fallbackReason: hasWinner ? null : outcomeReason,
    );

    await context.routeLedger?.recordForwardOutcome(
      destinationId: destinationId,
      channel: channel,
      payloadKind: payloadKind,
      attemptedRoutes: attemptedRoutes,
      winningRoute: hasWinner ? winningRoute : null,
      occurredAtUtc: now,
      geographicScope: geographicScope,
    );
    if (hasWinner &&
        context.reticulumTransportControlPlaneEnabled &&
        context.announceLedger != null &&
        context.interfaceRegistry != null) {
      await _observeSuccessfulForwardOutcome(
        context: context,
        route: winningRoute,
        destinationId: destinationId,
        geographicScope: geographicScope,
        occurredAtUtc: now,
      );
    }

    final governanceBindingService = context.governanceBindingService;
    if (governanceBindingService == null) {
      return MeshGovernanceForwardOutcome(routeReceipt: routeReceipt);
    }

    final observation = await governanceBindingService.buildMeshObservation(
      observationId: _idFor('mesh-observation'),
      subjectId: plan.planningId,
      lifecycleState: hasWinner
          ? MeshLifecycleState.forwarded
          : (deferred ? MeshLifecycleState.queued : MeshLifecycleState.failed),
      observedAtUtc: now,
      envelope: _buildEnvelope(
        eventType: 'mesh_forward_observation',
        actionType: hasWinner ? 'forward' : (deferred ? 'queue' : 'fail'),
        entityId: plan.planningId,
        entityType: payloadKind,
        occurredAtUtc: now,
        routeReceipt: routeReceipt,
        senderNodeId: senderNodeId,
        context: context,
        payloadContext: <String, dynamic>{
          ...payloadContext,
          'forward_success_count': forwardedPeerIds.length,
          'forward_failure_count': failedPeerIds.length,
        },
      ),
      routeReceipt: routeReceipt,
      outcomeContext: <String, dynamic>{
        'mesh_channel': channel,
        'planned_governance_record_id': plan.recordId,
        if (custodyOutboxEntryId != null)
          'custody_outbox_entry_id': custodyOutboxEntryId,
      },
      actualOutcome: hasWinner ? 'mesh_forwarded' : outcomeReason,
      actualOutcomeScore: hasWinner
          ? _successRatio(
              successCount: forwardedPeerIds.length,
              failureCount: failedPeerIds.length,
            )
          : (deferred ? 0.35 : 0.0),
      coreSignals: <WhySignal>[
        WhySignal(
          label: 'forward_success_ratio',
          weight: _successRatio(
            successCount: forwardedPeerIds.length,
            failureCount: failedPeerIds.length,
          ),
          source: 'mesh_runtime',
          durable: true,
        ),
        WhySignal(
          label: 'attempted_route_count',
          weight: _candidateWeight(attemptedRoutes.length),
          source: 'mesh_runtime',
        ),
      ],
      memoryContext: <String, dynamic>{
        'forwarded_peer_ids': forwardedPeerIds,
        'failed_peer_ids': failedPeerIds,
        if (failureReason != null) 'failure_reason': failureReason,
        if (custodyOutboxEntryId != null)
          'custody_outbox_entry_id': custodyOutboxEntryId,
      },
      severity: hasWinner ? 'info' : (deferred ? 'info' : 'warning'),
    );
    final kernelObservation = context.meshKernel == null
        ? null
        : await context.meshKernel!.observeTransport(observation);

    final recordId =
        observation.outcomeContext['governance_record_id']?.toString();
    if (recordId != null) {
      logger.debug(
        'Recorded governed mesh outcome for $payloadKind: $recordId',
        tag: logName,
      );
    }

    return MeshGovernanceForwardOutcome(
      routeReceipt: kernelObservation?.routeReceipt ?? routeReceipt,
      recordId: recordId,
    );
  }

  static KernelEventEnvelope _buildEnvelope({
    required String eventType,
    required String actionType,
    required String entityId,
    required String entityType,
    required DateTime occurredAtUtc,
    required TransportRouteReceipt routeReceipt,
    required String senderNodeId,
    required MeshForwardingContext context,
    required Map<String, dynamic> payloadContext,
  }) {
    return KernelEventEnvelope(
      eventId: _idFor(eventType),
      occurredAtUtc: occurredAtUtc,
      userId: context.localUserId,
      agentId: context.localAgentId ?? senderNodeId,
      sourceSystem: 'mesh_runtime_governance_bridge',
      eventType: eventType,
      actionType: actionType,
      entityId: entityId,
      entityType: entityType,
      privacyMode: MeshTransportPrivacyMode.normalize(context.privacyMode),
      routeReceipt: routeReceipt,
      context: <String, dynamic>{
        'sender_node_id': senderNodeId,
        ...payloadContext,
      },
      runtimeContext: <String, dynamic>{
        'mesh_governed': true,
      },
    );
  }

  static Future<_MeshPlannedRoutes> _buildRouteCandidates({
    required MeshForwardingContext context,
    required List<String> candidatePeerIds,
    required Map<String, String> peerNodeIdByDeviceId,
    required String? geographicScope,
    required String destinationId,
  }) async {
    final selection = await MeshForwardingTargetSelector.selectWithContext(
      context: context,
      discoveredNodeIds: candidatePeerIds,
      destinationId: destinationId,
      geographicScope: geographicScope,
      maxCandidates: candidatePeerIds.length,
    );
    final routes = selection.candidates.map((selectionCandidate) {
      final peerId = selectionCandidate.peerId;
      final device = selectionCandidate.device;
      final routeEntry = context.routeLedger?.entryForPeer(
        destinationId: destinationId,
        peerId: peerId,
      );
      final announce = selectionCandidate.announce;
      final interfaceProfile = selectionCandidate.interfaceProfile;
      final recipientId = device == null
          ? peerNodeIdByDeviceId[peerId] ?? peerId
          : peerNodeIdByDeviceId[device.deviceId] ?? device.deviceId;
      return TransportRouteCandidate(
        routeId:
            '${interfaceProfile?.interfaceId ?? 'ble'}:$peerId:$recipientId',
        mode: _modeForInterface(interfaceProfile),
        confidence: selectionCandidate.score,
        estimatedLatencyMs: _latencyForDevice(device),
        localityFit: geographicScope == null ? 1.0 : 0.9,
        availabilityScore:
            (device?.isSpotsEnabled ?? (announce != null)) ? 1.0 : 0.5,
        rationale: announce == null
            ? 'historical mesh candidate selected'
            : 'destination announce selected via governed mesh control plane',
        metadata: <String, dynamic>{
          'peer_id': peerId,
          'recipient_id': recipientId,
          if (device != null) 'device_name': device.deviceName,
          if (routeEntry?.peerNodeId != null)
            'peer_node_id': routeEntry!.peerNodeId,
          if (selectionCandidate.historicalRouteScore != null)
            'historical_route_score': selectionCandidate.historicalRouteScore,
          if (routeEntry != null)
            'historical_success_rate': routeEntry.successRate,
          if (device?.signalStrength != null)
            'signal_strength_dbm': device!.signalStrength,
          'mesh_interface_id': interfaceProfile?.interfaceId,
          'mesh_interface_kind': interfaceProfile?.kind.name,
          'mesh_route_resolution_mode': selection.routeResolutionMode,
          if (announce != null) 'mesh_announce_id': announce.announceId,
          if (announce != null) 'mesh_hop_count': announce.hopCount,
          if (announce != null)
            'mesh_announce_expires_at_utc':
                announce.expiresAtUtc.toUtc().toIso8601String(),
        },
      );
    }).toList();
    return _MeshPlannedRoutes(
      routes: routes,
      routeResolutionMode: selection.routeResolutionMode,
    );
  }

  static int _latencyForDevice(DiscoveredDevice? device) {
    if (device == null) {
      return 220;
    }
    final signalStrength = device.signalStrength;
    if (signalStrength == null) {
      return 180;
    }
    return ((-signalStrength - 30) * 3).clamp(40, 800).toInt();
  }

  static double _planningConfidence(List<TransportRouteCandidate> routes) {
    if (routes.isEmpty) {
      return 0.0;
    }
    return routes
        .map((route) => route.confidence)
        .reduce((left, right) => left > right ? left : right)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  static double _candidateWeight(int count) {
    return (count / 3).clamp(0.0, 1.0).toDouble();
  }

  static double _successRatio({
    required int successCount,
    required int failureCount,
  }) {
    final attempts = successCount + failureCount;
    if (attempts == 0) {
      return 0.0;
    }
    return (successCount / attempts).clamp(0.0, 1.0).toDouble();
  }

  static TransportRouteCandidate _copyRouteCandidate(
    TransportRouteCandidate route, {
    Map<String, dynamic>? metadata,
  }) {
    return TransportRouteCandidate(
      routeId: route.routeId,
      mode: route.mode,
      confidence: route.confidence,
      estimatedLatencyMs: route.estimatedLatencyMs,
      expiryFit: route.expiryFit,
      localityFit: route.localityFit,
      availabilityScore: route.availabilityScore,
      rationale: route.rationale,
      metadata: metadata ?? route.metadata,
    );
  }

  static String _idFor(String prefix) =>
      '$prefix-${DateTime.now().toUtc().microsecondsSinceEpoch}';

  static TransportMode _modeForInterface(
      MeshInterfaceProfile? interfaceProfile) {
    return switch (interfaceProfile?.kind) {
      MeshInterfaceKind.federatedCloud => TransportMode.cloudAssist,
      MeshInterfaceKind.websocket => TransportMode.wormhole,
      MeshInterfaceKind.webrtc => TransportMode.nearbyRelay,
      MeshInterfaceKind.wifiDirect => TransportMode.localWifi,
      _ => TransportMode.ble,
    };
  }

  static Future<void> _observeSuccessfulForwardOutcome({
    required MeshForwardingContext context,
    required TransportRouteCandidate route,
    required String destinationId,
    required String? geographicScope,
    required DateTime occurredAtUtc,
  }) async {
    final announceLedger = context.announceLedger;
    final interfaceRegistry = context.interfaceRegistry;
    if (announceLedger == null || interfaceRegistry == null) {
      return;
    }
    final interfaceId =
        route.metadata['mesh_interface_id']?.toString() ?? 'unknown';
    final interfaceProfile = interfaceRegistry.resolveByInterfaceId(
      interfaceId,
      privacyMode: context.privacyMode,
    );
    await MeshAnnounceProducerLane.observeRelayRefresh(
      announceLedger: announceLedger,
      interfaceProfile: interfaceProfile,
      privacyMode: context.privacyMode,
      destinationId: destinationId,
      nextHopPeerId: route.metadata['peer_id']?.toString() ?? 'unknown_peer',
      nextHopNodeId: route.metadata['peer_node_id']?.toString(),
      geographicScope: geographicScope ?? 'mesh',
      confidence: route.confidence,
      supportsCustody: interfaceProfile.supportsCustody,
      hopCount: (route.metadata['mesh_hop_count'] as num?)?.toInt() ?? 1,
      observedAtUtc: occurredAtUtc,
      segmentProfileResolver: context.segmentProfileResolver,
      segmentCredentialFactory: context.segmentCredentialFactory,
      announceAttestationFactory: context.announceAttestationFactory,
      credentialRefreshService: context.segmentCredentialRefreshService,
      principalId: route.metadata['peer_node_id']?.toString() ??
          route.metadata['peer_id']?.toString() ??
          'unknown_peer',
      signerEntityId: route.metadata['peer_node_id']?.toString() ??
          route.metadata['peer_id']?.toString() ??
          'unknown_peer',
    );
  }
}
