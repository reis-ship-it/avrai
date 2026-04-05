// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/learning_insight_mesh_forwarder.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_producer_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_target_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_governance_orchestration_lane.dart';

class MeshCustodyReplayLane {
  const MeshCustodyReplayLane._();

  static final Map<String, DateTime> _lastTriggeredReplayAtByDestination =
      <String, DateTime>{};

  static const Map<MeshAnnounceSourceType, String> _announceSourceKeys =
      <MeshAnnounceSourceType, String>{
    MeshAnnounceSourceType.directDiscovery: 'direct_discovery',
    MeshAnnounceSourceType.forwardSuccess: 'forward_success',
    MeshAnnounceSourceType.heardForward: 'heard_forward',
    MeshAnnounceSourceType.cloudAvailable: 'cloud_available',
  };

  static Future<int> replayDueEntries({
    required MeshForwardingContext context,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    int maxEntries = 4,
    int maxCandidates = 2,
  }) async {
    final outbox = context.custodyOutbox;
    if (outbox == null) {
      return 0;
    }

    final dueEntries = outbox.dueEntries(limit: maxEntries);
    if (dueEntries.isEmpty) {
      return 0;
    }

    var releasedCount = 0;
    for (final entry in dueEntries) {
      releasedCount += await _replayEntry(
        entry: entry,
        context: context,
        discoveredNodeIds: discoveredNodeIds,
        localNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        logger: logger,
        logName: logName,
        maxCandidates: maxCandidates,
        replayTrigger: 'scheduled_retry',
      );
    }
    return releasedCount;
  }

  static Future<int> replayForRecoveredReachability({
    required MeshForwardingContext context,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    int maxEntriesPerDestination = 3,
    int maxEntriesPerCycle = 8,
    int maxCandidates = 2,
  }) async {
    if (!context.reticulumTransportControlPlaneEnabled ||
        context.announceLedger == null ||
        context.interfaceRegistry == null ||
        context.custodyOutbox == null) {
      return 0;
    }

    final pendingEntries = context.custodyOutbox!.allEntries();
    if (pendingEntries.isEmpty) {
      return 0;
    }

    final updates = await MeshAnnounceProducerLane.syncReachablePeers(
      announceLedger: context.announceLedger!,
      reachablePeerIds: discoveredNodeIds,
      discovery: context.discovery,
      interfaceRegistry: context.interfaceRegistry!,
      privacyMode: context.privacyMode,
      segmentProfileResolver: context.segmentProfileResolver,
      segmentCredentialFactory: context.segmentCredentialFactory,
      announceAttestationFactory: context.announceAttestationFactory,
      credentialRefreshService: context.segmentCredentialRefreshService,
      routeLedger: context.routeLedger,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
    );
    if (context.privacyMode == MeshTransportPrivacyMode.federatedCloud ||
        context.privacyMode == MeshTransportPrivacyMode.multiMode) {
      updates.addAll(
        await MeshAnnounceProducerLane.seedCloudAvailability(
          announceLedger: context.announceLedger!,
          destinationIds: pendingEntries.map((entry) => entry.destinationId),
          interfaceRegistry: context.interfaceRegistry!,
          privacyMode: context.privacyMode,
          segmentProfileResolver: context.segmentProfileResolver,
          segmentCredentialFactory: context.segmentCredentialFactory,
          announceAttestationFactory: context.announceAttestationFactory,
          credentialRefreshService: context.segmentCredentialRefreshService,
        ),
      );
    }

    final triggerByDestination = <String, _ReplayTriggerContext>{};
    for (final update in updates) {
      final destinationId = update.record.destinationId;
      final reason = update.triggerReason;
      if (reason == null ||
          context.custodyOutbox!.pendingCount(destinationId: destinationId) ==
              0) {
        continue;
      }
      triggerByDestination[destinationId] = _preferTrigger(
        triggerByDestination[destinationId],
        _ReplayTriggerContext(
          reason: reason,
          sourceKey: _announceSourceKeys[update.record.sourceType],
        ),
      );
    }

    if (triggerByDestination.isEmpty) {
      return 0;
    }

    var releasedCount = 0;
    var remainingEntries = maxEntriesPerCycle;
    final now = DateTime.now().toUtc();
    for (final destinationId in triggerByDestination.keys.toList()..sort()) {
      if (remainingEntries <= 0) {
        break;
      }
      final lastTrigger = _lastTriggeredReplayAtByDestination[destinationId];
      if (lastTrigger != null &&
          now.difference(lastTrigger) < const Duration(seconds: 2)) {
        continue;
      }
      final trigger = triggerByDestination[destinationId]!;
      final replayTrigger = trigger.reason;
      final processedCount = maxEntriesPerDestination < remainingEntries
          ? maxEntriesPerDestination
          : remainingEntries;
      _lastTriggeredReplayAtByDestination[destinationId] = now;
      await context.announceLedger!.recordReplayTrigger(
        replayTrigger,
        trusted: context.trustedAnnounceEnforcementEnabled,
        sourceKey: trigger.sourceKey,
      );
      releasedCount += await replayForDestination(
        context: context,
        destinationId: destinationId,
        discoveredNodeIds: discoveredNodeIds,
        localNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        logger: logger,
        logName: logName,
        maxEntries: processedCount,
        maxCandidates: maxCandidates,
        replayTrigger: replayTrigger,
      );
      remainingEntries -= processedCount;
    }
    return releasedCount;
  }

  static Future<int> replayForDestination({
    required MeshForwardingContext context,
    required String destinationId,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    required String replayTrigger,
    int maxEntries = 3,
    int maxCandidates = 2,
  }) async {
    final outbox = context.custodyOutbox;
    if (outbox == null) {
      return 0;
    }
    final entries = outbox
        .allEntries()
        .where((entry) => entry.destinationId == destinationId)
        .toList()
      ..sort((left, right) => left.queuedAtUtc.compareTo(right.queuedAtUtc));
    if (entries.isEmpty) {
      return 0;
    }

    var releasedCount = 0;
    for (final entry in entries.take(maxEntries)) {
      releasedCount += await _replayEntry(
        entry: entry,
        context: context,
        discoveredNodeIds: discoveredNodeIds,
        localNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        logger: logger,
        logName: logName,
        maxCandidates: maxCandidates,
        replayTrigger: replayTrigger,
      );
    }
    return releasedCount;
  }

  static Future<int> _replayEntry({
    required MeshCustodyOutboxEntry entry,
    required MeshForwardingContext context,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required Map<String, String> peerNodeIdByDeviceId,
    required AppLogger logger,
    required String logName,
    required int maxCandidates,
    required String replayTrigger,
  }) async {
    MeshCustodyMaterializedEntry materializedEntry;
    try {
      materializedEntry = await context.custodyOutbox!.materialize(entry);
    } catch (e) {
      await context.custodyOutbox?.markRetry(
        entryId: entry.entryId,
        reason: 'mesh_custody_payload_unavailable',
      );
      final failedReplayPlan =
          await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
        context: context,
        candidatePeerIds: const <String>[],
        senderNodeId: localNodeId,
        destinationId: entry.destinationId,
        payloadKind: entry.payloadKind,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        geographicScope: entry.geographicScope,
        payloadContext: <String, dynamic>{
          ...(entry.payloadContext ?? const <String, dynamic>{}),
          'replay_receipt_id': entry.receiptId,
          'custody_outbox_entry_id': entry.entryId,
          'replay_attempt': entry.attemptCount + 1,
          'payload_materialization_failed': true,
          'mesh_replay_trigger': replayTrigger,
        },
        logger: logger,
        logName: logName,
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: failedReplayPlan,
        senderNodeId: localNodeId,
        destinationId: entry.destinationId,
        payloadKind: entry.payloadKind,
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: 'mesh_custody_payload_unavailable',
        deferredToCustody: true,
        custodyOutboxEntryId: entry.entryId,
        geographicScope: entry.geographicScope,
        payloadContext: <String, dynamic>{
          ...(entry.payloadContext ?? const <String, dynamic>{}),
          'replay_receipt_id': entry.receiptId,
          'replay_attempt': entry.attemptCount + 1,
          'mesh_replay_trigger': replayTrigger,
        },
        logger: logger,
        logName: logName,
      );
      logger.debug(
        'Mesh custody replay skipped for ${entry.payloadKind}: $e',
        tag: logName,
      );
      return 0;
    }

    final geographicScope = entry.geographicScope ??
        materializedEntry.payload['scope']?.toString() ??
        materializedEntry.payload['geographic_scope']?.toString();
    final candidates = await _selectCandidates(
      entry: entry,
      payload: materializedEntry.payload,
      payloadContext: materializedEntry.payloadContext,
      context: context,
      discoveredNodeIds: discoveredNodeIds,
      localNodeId: localNodeId,
      geographicScope: geographicScope,
      maxCandidates: maxCandidates,
    );

    final governancePlan =
        await MeshRuntimeGovernanceOrchestrationLane.recordForwardPlan(
      context: context,
      candidatePeerIds: candidates,
      senderNodeId: localNodeId,
      destinationId: entry.destinationId,
      payloadKind: entry.payloadKind,
      peerNodeIdByDeviceId: peerNodeIdByDeviceId,
      geographicScope: geographicScope,
      payloadContext: <String, dynamic>{
        ...materializedEntry.payloadContext,
        'replay_receipt_id': entry.receiptId,
        'custody_outbox_entry_id': entry.entryId,
        'replay_attempt': entry.attemptCount + 1,
        'mesh_replay_trigger': replayTrigger,
      },
      logger: logger,
      logName: logName,
    );

    if (candidates.isEmpty) {
      await context.custodyOutbox?.markRetry(
        entryId: entry.entryId,
        reason: 'no_mesh_candidates_available',
      );
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: entry.destinationId,
        payloadKind: entry.payloadKind,
        forwardedPeerIds: const <String>[],
        failedPeerIds: const <String>[],
        failureReason: 'waiting_for_viable_route',
        deferredToCustody: true,
        custodyOutboxEntryId: entry.entryId,
        geographicScope: geographicScope,
        payloadContext: <String, dynamic>{
          ...materializedEntry.payloadContext,
          'replay_receipt_id': entry.receiptId,
          'replay_attempt': entry.attemptCount + 1,
          'mesh_replay_trigger': replayTrigger,
        },
        logger: logger,
        logName: logName,
      );
      return 0;
    }

    final forwardedPeerIds = <String>[];
    final failedPeerIds = <String>[];

    try {
      await LearningInsightMeshForwarder.forward(
        candidatePeerIds: candidates,
        context: context,
        senderNodeId: localNodeId,
        peerNodeIdByDeviceId: peerNodeIdByDeviceId,
        payload: materializedEntry.payload,
        geographicScope: geographicScope,
        onForwarded: (peerId, _) {
          forwardedPeerIds.add(peerId);
        },
        onForwardFailed: (peerId, _, __) {
          failedPeerIds.add(peerId);
        },
      );
    } catch (e) {
      failedPeerIds.addAll(
        candidates.where((peerId) => !failedPeerIds.contains(peerId)),
      );
      logger.debug(
        'Mesh custody replay failed for ${entry.payloadKind}: $e',
        tag: logName,
      );
    }

    if (forwardedPeerIds.isNotEmpty) {
      await context.custodyOutbox?.markReleased(entry.entryId);
      await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
        context: context,
        plan: governancePlan,
        senderNodeId: localNodeId,
        destinationId: entry.destinationId,
        payloadKind: entry.payloadKind,
        forwardedPeerIds: forwardedPeerIds,
        failedPeerIds: failedPeerIds,
        geographicScope: geographicScope,
        payloadContext: <String, dynamic>{
          ...materializedEntry.payloadContext,
          'replay_receipt_id': entry.receiptId,
          'replay_attempt': entry.attemptCount + 1,
          'mesh_replay_trigger': replayTrigger,
        },
        logger: logger,
        logName: logName,
      );
      return 1;
    }

    await context.custodyOutbox?.markRetry(
      entryId: entry.entryId,
      reason: 'all_mesh_candidates_failed',
    );
    await MeshRuntimeGovernanceOrchestrationLane.recordForwardOutcome(
      context: context,
      plan: governancePlan,
      senderNodeId: localNodeId,
      destinationId: entry.destinationId,
      payloadKind: entry.payloadKind,
      forwardedPeerIds: const <String>[],
      failedPeerIds: failedPeerIds.isEmpty ? candidates : failedPeerIds,
      failureReason: 'all_mesh_candidates_failed',
      deferredToCustody: true,
      custodyOutboxEntryId: entry.entryId,
      geographicScope: geographicScope,
      payloadContext: <String, dynamic>{
        ...materializedEntry.payloadContext,
        'replay_receipt_id': entry.receiptId,
        'replay_attempt': entry.attemptCount + 1,
        'mesh_replay_trigger': replayTrigger,
      },
      logger: logger,
      logName: logName,
    );
    return 0;
  }

  static Future<List<String>> _selectCandidates({
    required MeshCustodyOutboxEntry entry,
    required Map<String, dynamic> payload,
    required Map<String, dynamic> payloadContext,
    required MeshForwardingContext context,
    required Iterable<String> discoveredNodeIds,
    required String localNodeId,
    required String? geographicScope,
    required int maxCandidates,
  }) async {
    switch (entry.payloadKind) {
      case 'prekey_bundle_forward':
        return MeshForwardingTargetSelector.excludingRecipientAndLocalNode(
          discoveredNodeIds: discoveredNodeIds,
          recipientId: entry.destinationId,
          localNodeId: localNodeId,
          context: context,
          geographicScope: geographicScope,
          maxCandidates: maxCandidates,
        );
      case 'learning_insight_gossip':
        final receivedFromDeviceId =
            payloadContext['received_from_device_id']?.toString();
        if (receivedFromDeviceId != null && receivedFromDeviceId.isNotEmpty) {
          return MeshForwardingTargetSelector.excludingReceivedFromAndOrigin(
            discoveredNodeIds: discoveredNodeIds,
            receivedFromDeviceId: receivedFromDeviceId,
            originId: entry.destinationId,
            context: context,
            geographicScope: geographicScope,
            maxCandidates: maxCandidates,
          );
        }
        return MeshForwardingTargetSelector.excludingOptionalOrigin(
          discoveredNodeIds: discoveredNodeIds,
          originId: payloadContext['origin_id']?.toString(),
          destinationId: entry.destinationId,
          context: context,
          geographicScope: geographicScope,
          maxCandidates: maxCandidates,
        );
      case 'locality_agent_update':
        return MeshForwardingTargetSelector.excludingOptionalOrigin(
          discoveredNodeIds: discoveredNodeIds,
          originId: payloadContext['origin_id']?.toString(),
          destinationId: entry.destinationId,
          context: context,
          geographicScope: geographicScope,
          maxCandidates: maxCandidates,
        );
      case 'organic_spot_discovery':
      default:
        final selection = await MeshForwardingTargetSelector.selectWithContext(
          context: context,
          discoveredNodeIds: discoveredNodeIds,
          destinationId: payload['geohash']?.toString() ?? entry.destinationId,
          geographicScope: geographicScope,
          maxCandidates: maxCandidates,
        );
        return selection.peerIds;
    }
  }

  static _ReplayTriggerContext _preferTrigger(
    _ReplayTriggerContext? current,
    _ReplayTriggerContext incoming,
  ) {
    const priorities = <String, int>{
      'interface_recovered': 3,
      'announce_arrival': 2,
      'announce_refresh': 1,
    };
    final currentPriority = priorities[current?.reason] ?? 0;
    final incomingPriority = priorities[incoming.reason] ?? 0;
    if (incomingPriority >= currentPriority) {
      return incoming;
    }
    return current ?? incoming;
  }
}

class _ReplayTriggerContext {
  const _ReplayTriggerContext({
    required this.reason,
    required this.sourceKey,
  });

  final String reason;
  final String? sourceKey;
}
