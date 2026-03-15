import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_runtime_os/ai/privacy_protection.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/services/ai2ai_broadcast_service.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_knot/services/knot/deterministic_matcher_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_protocol_codec_adapter.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';

/// Supports discovery of nearby AI personalities and prioritization
class DiscoveryManager {
  final Connectivity connectivity;
  final UserVibeAnalyzer vibeAnalyzer;
  final CanonicalVibeProjectionService canonicalVibeProjectionService;
  final CanonicalPeerResolutionService canonicalPeerResolutionService;

  DiscoveryManager({
    required this.connectivity,
    required this.vibeAnalyzer,
    CanonicalVibeProjectionService? canonicalVibeProjectionService,
    CanonicalPeerResolutionService? canonicalPeerResolutionService,
  })  : canonicalVibeProjectionService =
            canonicalVibeProjectionService ?? CanonicalVibeProjectionService(),
        canonicalPeerResolutionService =
            canonicalPeerResolutionService ?? CanonicalPeerResolutionService();

  Future<List<AIPersonalityNode>> discover(
    String userId,
    PersonalityProfile personality,
    Future<List<AIPersonalityNode>> Function(AnonymizedVibeData)
        performDiscovery,
  ) async {
    final canonicalPersonality =
        await canonicalVibeProjectionService.canonicalizeUserProfile(
      userId: userId,
      profile: personality,
    );
    // Offline-first: physical-layer discovery (BLE, etc.) must work without
    // internet connectivity. Cloud/realtime discovery can be layered on top.
    // So we intentionally do NOT short-circuit when offline.

    final userVibe =
        await vibeAnalyzer.compileUserVibe(userId, canonicalPersonality);
    final anonymizedVibe = await PrivacyProtection.anonymizeUserVibe(userVibe);
    final nodes = await performDiscovery(anonymizedVibe);

    final compatibility = await _analyzeCompatibility(userVibe, nodes,
        localPersonality: canonicalPersonality);
    final prioritized = _prioritize(nodes, compatibility);
    return prioritized;
  }

  Future<Map<String, VibeCompatibilityResult>> _analyzeCompatibility(
      UserVibe localVibe, List<AIPersonalityNode> nodes,
      {PersonalityProfile? localPersonality}) async {
    final result = <String, VibeCompatibilityResult>{};

    // Phase 0.1 Pivot: Prepare local knot for deterministic matching if possible
    PersonalityKnot? localKnot;
    if (localPersonality != null) {
      try {
        final knotService =
            GetIt.instance.isRegistered<PersonalityKnotService>()
                ? GetIt.instance<PersonalityKnotService>()
                : PersonalityKnotService();
        localKnot = await knotService.generateKnot(localPersonality);
      } catch (e) {
        // Fallback to legacy analyzer if knot generation fails
      }
    }

    for (final node in nodes) {
      if (localPersonality != null && node.resolvedPeerContext != null) {
        final localPayload = canonicalPeerResolutionService.buildLocalPayload(
          localPersonality: localPersonality,
        );
        final canonicalCompatibility =
            canonicalPeerResolutionService.computeCompatibility(
          localPayload: localPayload,
          remoteContext: node.resolvedPeerContext!,
        );
        result[node.nodeId] =
            canonicalPeerResolutionService.toLegacyCompatibilityResult(
          canonicalCompatibility,
          localPayload: localPayload,
          remoteContext: node.resolvedPeerContext!,
        );
        continue;
      }
      if (localKnot != null && node.knot != null) {
        final matcher = DeterministicMatcherService();
        final matchScore = matcher.calculateVibeMatch(localKnot, node.knot!);
        result[node.nodeId] = VibeCompatibilityResult(
          basicCompatibility: matchScore,
          aiPleasurePotential: matchScore,
          learningOpportunities: [],
          connectionStrength: matchScore,
          interactionStyle: AI2AIInteractionStyle.focusedExchange,
          trustBuildingPotential: matchScore,
          recommendedConnectionDuration: const Duration(seconds: 300),
          connectionPriority:
              matchScore >= VibeConstants.minimumCompatibilityThreshold
                  ? ConnectionPriority.high
                  : ConnectionPriority.low,
        );
      } else {
        final c =
            await vibeAnalyzer.analyzeVibeCompatibility(localVibe, node.vibe);
        result[node.nodeId] = c;
      }
    }
    return result;
  }

  List<AIPersonalityNode> _prioritize(
    List<AIPersonalityNode> nodes,
    Map<String, VibeCompatibilityResult> results,
  ) {
    nodes.sort((a, b) {
      final ar = results[a.nodeId];
      final br = results[b.nodeId];
      if (ar == null || br == null) return 0;
      final ap = (ar.basicCompatibility * 0.4) +
          (ar.aiPleasurePotential * 0.3) +
          (ar.learningOpportunities.length / 8.0 * 0.2) +
          (a.trustScore * 0.1);
      final bp = (br.basicCompatibility * 0.4) +
          (br.aiPleasurePotential * 0.3) +
          (br.learningOpportunities.length / 8.0 * 0.2) +
          (b.trustScore * 0.1);
      return bp.compareTo(ap);
    });
    return nodes.take(5).toList();
  }
}

/// Manages connection establishment and maintenance
/// Philosophy: "Always Learning With You" - AI learns alongside you, online and offline
class ConnectionManager {
  final UserVibeAnalyzer vibeAnalyzer;
  final CanonicalVibeProjectionService canonicalVibeProjectionService;
  final CanonicalPeerResolutionService canonicalPeerResolutionService;
  final PersonalityLearning?
      personalityLearning; // NEW: For offline AI learning
  final LegacyProtocolCodecAdapter? protocolCodecAdapter;

  ConnectionManager({
    required this.vibeAnalyzer,
    CanonicalVibeProjectionService? canonicalVibeProjectionService,
    CanonicalPeerResolutionService? canonicalPeerResolutionService,
    this.personalityLearning, // Optional for backward compatibility
    this.protocolCodecAdapter,
  })  : canonicalVibeProjectionService =
            canonicalVibeProjectionService ?? CanonicalVibeProjectionService(),
        canonicalPeerResolutionService =
            canonicalPeerResolutionService ?? CanonicalPeerResolutionService();

  Future<ConnectionMetrics?> establish(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
    Future<ConnectionMetrics?> Function(
      UserVibe localVibe,
      AIPersonalityNode remoteNode,
      VibeCompatibilityResult compatibility,
      ConnectionMetrics initialMetrics,
    ) performEstablishment,
  ) async {
    final canonicalLocalPersonality =
        await canonicalVibeProjectionService.canonicalizeUserProfile(
      userId: localUserId,
      profile: localPersonality,
    );
    final localVibe = await vibeAnalyzer.compileUserVibe(
      localUserId,
      canonicalLocalPersonality,
    );
    final localPeerPayload = canonicalPeerResolutionService.buildLocalPayload(
      localPersonality: canonicalLocalPersonality,
    );
    final canonicalCompatibility = remoteNode.resolvedPeerContext == null
        ? null
        : canonicalPeerResolutionService.computeCompatibility(
            localPayload: localPeerPayload,
            remoteContext: remoteNode.resolvedPeerContext!,
          );
    final compatibility = canonicalCompatibility == null
        ? await vibeAnalyzer.analyzeVibeCompatibility(
            localVibe, remoteNode.vibe)
        : canonicalPeerResolutionService.toLegacyCompatibilityResult(
            canonicalCompatibility,
            localPayload: localPeerPayload,
            remoteContext: remoteNode.resolvedPeerContext!,
          );

    if (!_isWorthy(compatibility)) return null;

    final metrics = _buildInitialMetrics(
      localPayload: localPeerPayload,
      remoteContext: remoteNode.resolvedPeerContext,
      compatibility: compatibility,
      canonicalCompatibility: canonicalCompatibility,
    );

    return performEstablishment(localVibe, remoteNode, compatibility, metrics);
  }

  Future<ResolvedPeerVibeContext?> resolveRemotePeerContextForDevice({
    required String localUserId,
    required PersonalityProfile localPersonality,
    required String remoteDeviceId,
  }) async {
    if (protocolCodecAdapter == null) {
      return null;
    }

    final canonicalLocalPersonality =
        await canonicalVibeProjectionService.canonicalizeUserProfile(
      userId: localUserId,
      profile: localPersonality,
    );
    final localPeerPayload = canonicalPeerResolutionService.buildLocalPayload(
      localPersonality: canonicalLocalPersonality,
    );
    return protocolCodecAdapter!.exchangeResolvedPeerContext(
      remoteDeviceId: remoteDeviceId,
      localAgentId: canonicalLocalPersonality.agentId,
      localPersonality: canonicalLocalPersonality,
      localPeerPayload: localPeerPayload,
    );
  }

  bool _isWorthy(VibeCompatibilityResult c) {
    return c.basicCompatibility >=
            VibeConstants.minimumCompatibilityThreshold &&
        c.aiPleasurePotential >= VibeConstants.minAIPleasureScore &&
        c.learningOpportunities.isNotEmpty;
  }

  // ========================================================================
  // OFFLINE PEER CONNECTION (Philosophy Implementation - Phase 1)
  // OUR_GUTS.md: "Always Learning With You"
  // Philosophy: The key works everywhere - offline AI2AI connections via Bluetooth
  // ========================================================================

  /// Establish offline peer-to-peer connection (no internet required)
  ///
  /// Philosophy: "Doors appear everywhere (subway, park, street).
  /// The key should work anywhere, not just when online."
  ///
  /// Flow:
  /// 1. Exchange bounded canonical peer payloads via Bluetooth/NSD
  /// 2. Resolve the inbound payload into governed session-scoped peer context
  /// 3. Compute compatibility and connection metrics without importing remote truth
  Future<ConnectionMetrics?> establishOfflinePeerConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    String remoteDeviceId,
  ) async {
    // Verify we have the required dependency
    if (protocolCodecAdapter == null) {
      throw Exception(
        'Offline AI2AI requires LegacyProtocolCodecAdapter dependency',
      );
    }

    try {
      final canonicalLocalPersonality =
          await canonicalVibeProjectionService.canonicalizeUserProfile(
        userId: localUserId,
        profile: localPersonality,
      );
      final localPeerPayload = canonicalPeerResolutionService.buildLocalPayload(
        localPersonality: canonicalLocalPersonality,
      );
      final remoteContext = await resolveRemotePeerContextForDevice(
        localUserId: localUserId,
        localPersonality: canonicalLocalPersonality,
        remoteDeviceId: remoteDeviceId,
      );
      if (remoteContext == null) {
        return null;
      }

      final canonicalCompatibility =
          canonicalPeerResolutionService.computeCompatibility(
        localPayload: localPeerPayload,
        remoteContext: remoteContext,
      );
      final compatibility =
          canonicalPeerResolutionService.toLegacyCompatibilityResult(
        canonicalCompatibility,
        localPayload: localPeerPayload,
        remoteContext: remoteContext,
      );
      if (!_isWorthy(compatibility)) {
        return null;
      }

      final initialMetrics = _buildInitialMetrics(
        localPayload: localPeerPayload,
        remoteContext: remoteContext,
        compatibility: compatibility,
        canonicalCompatibility: canonicalCompatibility,
      );
      return initialMetrics.updateDuringInteraction(
        newCompatibility: compatibility.basicCompatibility,
        learningEffectiveness: compatibility.connectionStrength,
        aiPleasureScore: compatibility.aiPleasurePotential,
        newInteraction: InteractionEvent.success(
          type: InteractionType.vibeExchange,
          data: <String, dynamic>{
            'canonical_peer_payload': true,
            'local_peer_archetype': localPeerPayload.personalSurface.archetype,
            'remote_peer_archetype': remoteContext.personalSurface.archetype,
            'remote_scope': remoteContext.reference.scope,
            'shared_scoped_context_count':
                canonicalCompatibility.sharedScopedContextIds.length,
          },
        ),
        additionalOutcomes: <String, dynamic>{
          'successful_exchanges': 1,
          'canonical_peer_payload_exchange': 1,
          'governed_peer_resolution': 1,
        },
      );
    } catch (e) {
      // Log error but don't throw - offline connections can fail gracefully
      return null;
    }
  }

  ConnectionMetrics _buildInitialMetrics({
    required Ai2AiCanonicalPeerPayload localPayload,
    required VibeCompatibilityResult compatibility,
    ResolvedPeerVibeContext? remoteContext,
    CanonicalPeerCompatibilityResult? canonicalCompatibility,
  }) {
    final learningOutcomesSeed = <String, dynamic>{
      if (remoteContext != null && canonicalCompatibility != null)
        ...canonicalPeerResolutionService.compatibilityMetadata(
          canonicalCompatibility,
          remoteContext: remoteContext,
        ),
      if (remoteContext != null && canonicalCompatibility != null)
        'peer_why_summary': canonicalPeerResolutionService
            .buildPeerCompatibilityWhySnapshot(
              localPayload: localPayload,
              remoteContext: remoteContext,
              result: canonicalCompatibility,
            )
            .summary,
    };
    return ConnectionMetrics.initial(
      localAISignature: localPayload.personalSurface.signatureHash,
      remoteAISignature:
          remoteContext?.personalSurface.signatureHash ?? 'remote-unknown',
      compatibility: compatibility.basicCompatibility,
      learningOutcomesSeed: learningOutcomesSeed,
    );
  }
}

/// Bundles realtime listener wiring and disposables
class RealtimeCoordinator {
  final AI2AIBroadcastService realtime;
  StreamSubscription? personalitySub;
  StreamSubscription? learningSub;
  StreamSubscription? anonymousSub;

  RealtimeCoordinator(this.realtime);

  void setup({
    required void Function(RealtimeMessage) onPersonality,
    required void Function(RealtimeMessage) onLearning,
    required void Function(RealtimeMessage) onAnonymous,
  }) {
    dispose();
    personalitySub =
        realtime.listenToPersonalityDiscovery().listen(onPersonality);
    learningSub = realtime.listenToVibeLearning().listen(onLearning);
    anonymousSub =
        realtime.listenToAnonymousCommunication().listen(onAnonymous);
  }

  void dispose() {
    personalitySub?.cancel();
    learningSub?.cancel();
    anonymousSub?.cancel();
  }
}
