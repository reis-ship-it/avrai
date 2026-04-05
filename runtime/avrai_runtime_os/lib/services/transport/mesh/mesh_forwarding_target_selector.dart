// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'dart:math' as math;

import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/ai2ai/discovery/peer_candidate_selector.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_producer_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_forwarding_context.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';

class MeshResolvedForwardingCandidate {
  const MeshResolvedForwardingCandidate({
    required this.peerId,
    required this.score,
    this.announce,
    this.interfaceProfile,
    this.device,
    this.historicalRouteScore,
  });

  final String peerId;
  final double score;
  final MeshAnnounceRecord? announce;
  final MeshInterfaceProfile? interfaceProfile;
  final DiscoveredDevice? device;
  final double? historicalRouteScore;
}

class MeshForwardingSelection {
  const MeshForwardingSelection({
    required this.candidates,
    required this.routeResolutionMode,
    this.cloudCustodyAnnounce,
  });

  final List<MeshResolvedForwardingCandidate> candidates;
  final String routeResolutionMode;
  final MeshAnnounceRecord? cloudCustodyAnnounce;

  List<String> get peerIds => candidates.map((entry) => entry.peerId).toList();
}

class MeshForwardingTargetSelector {
  const MeshForwardingTargetSelector._();

  static List<String> select({
    required Iterable<String> discoveredNodeIds,
    Set<String> excludedNodeIds = const <String>{},
    String? destinationId,
    DeviceDiscoveryService? discovery,
    MeshRouteLedger? routeLedger,
    String? geographicScope,
    int maxCandidates = 2,
  }) {
    final filteredNodeIds =
        discoveredNodeIds.where((id) => !excludedNodeIds.contains(id)).toList();
    if (destinationId == null || discovery == null || routeLedger == null) {
      return PeerCandidateSelector.select(
        discoveredNodeIds: filteredNodeIds,
        maxCandidates: maxCandidates,
      );
    }

    return routeLedger.rankCandidates(
      destinationId: destinationId,
      candidatePeerIds: filteredNodeIds,
      discovery: discovery,
      geographicScope: geographicScope,
      maxCandidates: maxCandidates,
    );
  }

  static Future<MeshForwardingSelection> selectWithContext({
    required MeshForwardingContext context,
    required Iterable<String> discoveredNodeIds,
    Set<String> excludedNodeIds = const <String>{},
    required String? destinationId,
    String? geographicScope,
    int maxCandidates = 2,
  }) async {
    final filteredPeerIds =
        discoveredNodeIds.where((id) => !excludedNodeIds.contains(id)).toList();
    if (destinationId == null) {
      return MeshForwardingSelection(
        candidates: const <MeshResolvedForwardingCandidate>[],
        routeResolutionMode: 'historical_fallback_none',
      );
    }
    if (!context.reticulumTransportControlPlaneEnabled ||
        context.announceLedger == null ||
        context.interfaceRegistry == null) {
      final peerIds = select(
        discoveredNodeIds: filteredPeerIds,
        destinationId: destinationId,
        discovery: context.discovery,
        routeLedger: context.routeLedger,
        geographicScope: geographicScope,
        maxCandidates: maxCandidates,
      );
      return MeshForwardingSelection(
        candidates: peerIds
            .map(
              (peerId) => MeshResolvedForwardingCandidate(
                peerId: peerId,
                score: context.routeLedger?.scoreCandidate(
                      destinationId: destinationId,
                      peerId: peerId,
                      device: context.discovery.getDevice(peerId),
                      geographicScope: geographicScope,
                    ) ??
                    (context.discovery.getDevice(peerId)?.proximityScore ??
                        0.0),
                device: context.discovery.getDevice(peerId),
              ),
            )
            .toList(),
        routeResolutionMode: 'historical_fallback_none',
      );
    }

    final privacyMode = MeshTransportPrivacyMode.normalize(context.privacyMode);
    if (privacyMode == MeshTransportPrivacyMode.localSovereign) {
      return const MeshForwardingSelection(
        candidates: <MeshResolvedForwardingCandidate>[],
        routeResolutionMode: 'historical_fallback_none',
      );
    }

    await MeshAnnounceProducerLane.syncReachablePeers(
      announceLedger: context.announceLedger!,
      reachablePeerIds: filteredPeerIds,
      discovery: context.discovery,
      interfaceRegistry: context.interfaceRegistry!,
      privacyMode: privacyMode,
      segmentProfileResolver: context.segmentProfileResolver,
      segmentCredentialFactory: context.segmentCredentialFactory,
      announceAttestationFactory: context.announceAttestationFactory,
      credentialRefreshService: context.segmentCredentialRefreshService,
      routeLedger: context.routeLedger,
    );
    await context.announceLedger!.pruneExpiredHistory();

    final now = DateTime.now().toUtc();
    final activeAnnounces = context.announceLedger!.activeRecords(
      destinationId: destinationId,
    );
    final rankedByPeer = <String, MeshResolvedForwardingCandidate>{};
    for (final announce in activeAnnounces) {
      if (!filteredPeerIds.contains(announce.nextHopPeerId)) {
        continue;
      }
      final interfaceProfile = context.interfaceRegistry!.resolveByInterfaceId(
        announce.interfaceId,
        privacyMode: privacyMode,
      );
      if (!interfaceProfile.enabled ||
          !interfaceProfile.allowsPrivacyMode(privacyMode)) {
        continue;
      }
      final device = context.discovery.getDevice(announce.nextHopPeerId);
      final historicalRouteScore = context.routeLedger?.scoreCandidate(
        destinationId: destinationId,
        peerId: announce.nextHopPeerId,
        device: device,
        geographicScope: geographicScope,
      );
      final score = _scoreAnnouncedCandidate(
        announce: announce,
        interfaceProfile: interfaceProfile,
        device: device,
        historicalRouteScore: historicalRouteScore,
        requestedGeographicScope: geographicScope,
        nowUtc: now,
        routeLedger: context.routeLedger,
      );
      final candidate = MeshResolvedForwardingCandidate(
        peerId: announce.nextHopPeerId,
        score: score,
        announce: announce,
        interfaceProfile: interfaceProfile,
        device: device,
        historicalRouteScore: historicalRouteScore,
      );
      final existing = rankedByPeer[announce.nextHopPeerId];
      if (existing == null || candidate.score > existing.score) {
        rankedByPeer[announce.nextHopPeerId] = candidate;
      }
    }

    final ranked = rankedByPeer.values.toList()
      ..sort((left, right) {
        final scoreCompare = right.score.compareTo(left.score);
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        final rightSignal = right.device?.signalStrength ?? -999;
        final leftSignal = left.device?.signalStrength ?? -999;
        return rightSignal.compareTo(leftSignal);
      });
    if (ranked.isNotEmpty) {
      return MeshForwardingSelection(
        candidates: ranked.take(maxCandidates).toList(),
        routeResolutionMode: 'announce',
      );
    }

    if (privacyMode == MeshTransportPrivacyMode.federatedCloud ||
        privacyMode == MeshTransportPrivacyMode.multiMode) {
      final cloudProfile = context.interfaceRegistry!.cloudProfile(
        privacyMode: privacyMode,
      );
      MeshAnnounceRecord? cloudAnnounce;
      for (final announce in context.announceLedger!.activeRecords(
        destinationId: destinationId,
      )) {
        if (announce.interfaceId == cloudProfile.interfaceId) {
          cloudAnnounce = announce;
          break;
        }
      }
      if (cloudProfile.enabled && cloudAnnounce != null) {
        return MeshForwardingSelection(
          candidates: const <MeshResolvedForwardingCandidate>[],
          routeResolutionMode: 'cloud_custody',
          cloudCustodyAnnounce: cloudAnnounce,
        );
      }
    }

    return const MeshForwardingSelection(
      candidates: <MeshResolvedForwardingCandidate>[],
      routeResolutionMode: 'historical_fallback_none',
    );
  }

  static Future<List<String>> excludingReceivedFromAndOrigin({
    required Iterable<String> discoveredNodeIds,
    required String receivedFromDeviceId,
    required String originId,
    required MeshForwardingContext context,
    String? geographicScope,
    int maxCandidates = 2,
  }) async {
    final selection = await selectWithContext(
      context: context,
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: <String>{receivedFromDeviceId, originId},
      destinationId: originId,
      geographicScope: geographicScope,
      maxCandidates: maxCandidates,
    );
    return selection.peerIds;
  }

  static Future<List<String>> excludingRecipientAndLocalNode({
    required Iterable<String> discoveredNodeIds,
    required String recipientId,
    required String localNodeId,
    required MeshForwardingContext context,
    String? geographicScope,
    int maxCandidates = 2,
  }) async {
    final selection = await selectWithContext(
      context: context,
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: <String>{recipientId, localNodeId},
      destinationId: recipientId,
      geographicScope: geographicScope,
      maxCandidates: maxCandidates,
    );
    return selection.peerIds;
  }

  static Future<List<String>> excludingOptionalOrigin({
    required Iterable<String> discoveredNodeIds,
    required String? originId,
    required MeshForwardingContext context,
    String? geographicScope,
    String? destinationId,
    int maxCandidates = 2,
  }) async {
    final excludedNodeIds = <String>{};
    if (originId != null) {
      excludedNodeIds.add(originId);
    }
    final selection = await selectWithContext(
      context: context,
      discoveredNodeIds: discoveredNodeIds,
      excludedNodeIds: excludedNodeIds,
      destinationId: destinationId ?? originId,
      geographicScope: geographicScope,
      maxCandidates: maxCandidates,
    );
    return selection.peerIds;
  }

  static double _scoreAnnouncedCandidate({
    required MeshAnnounceRecord announce,
    required MeshInterfaceProfile interfaceProfile,
    required DiscoveredDevice? device,
    required DateTime nowUtc,
    required String? requestedGeographicScope,
    required MeshRouteLedger? routeLedger,
    double? historicalRouteScore,
  }) {
    final ttlWindowMs = math.max(
      announce.expiresAtUtc
          .difference(announce.observedAtUtc)
          .inMilliseconds
          .abs(),
      1,
    );
    final freshnessRemainingMs = math.max(
      announce.expiresAtUtc.difference(nowUtc).inMilliseconds,
      0,
    );
    final freshnessScore =
        (freshnessRemainingMs / ttlWindowMs).clamp(0.0, 1.0).toDouble();
    final liveSignalScore = MeshInterfaceRegistry.liveSignalScore(device);
    final localityScore = requestedGeographicScope == null ||
            announce.geographicScope == requestedGeographicScope
        ? 1.0
        : 0.68;
    final historicalScore = historicalRouteScore ??
        routeLedger?.scoreCandidate(
          destinationId: announce.destinationId,
          peerId: announce.nextHopPeerId,
          device: device,
          geographicScope: requestedGeographicScope,
        ) ??
        0.0;
    final recentFailurePenalty = () {
      final entry = routeLedger?.entryForPeer(
        destinationId: announce.destinationId,
        peerId: announce.nextHopPeerId,
      );
      if (entry?.lastFailureAtUtc == null) {
        return 0.0;
      }
      return nowUtc.difference(entry!.lastFailureAtUtc!).inMinutes < 10
          ? 0.12
          : 0.0;
    }();

    return ((freshnessScore * 0.23) +
            (announce.confidence * 0.18) +
            (interfaceProfile.policyScore * 0.16) +
            (historicalScore * 0.17) +
            (liveSignalScore * 0.12) +
            (localityScore * 0.08) +
            ((1.0 - ((announce.hopCount - 1).clamp(0, 5) / 5.0)) * 0.06) -
            recentFailurePenalty)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
