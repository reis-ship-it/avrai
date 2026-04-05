import 'package:avrai_core/models/boundary/boundary_models.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/kernel/boundary/boundary_kernel_service.dart';
import 'package:avrai_runtime_os/kernel/interpretation/interpretation_kernel_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:reality_engine/reality_engine.dart';

class PeerInteractionOutcomeLearningResult {
  const PeerInteractionOutcomeLearningResult({
    required this.applied,
    required this.receipts,
    required this.boundaryDecision,
    required this.governanceDecision,
  });

  final bool applied;
  final List<VibeUpdateReceipt> receipts;
  final BoundaryDecision? boundaryDecision;
  final VibeMutationDecision? governanceDecision;
}

class PeerInteractionOutcomeLearningService {
  PeerInteractionOutcomeLearningService({
    InterpretationKernelService? interpretationKernelService,
    BoundaryKernelService? boundaryKernelService,
    GovernanceKernelService? governanceKernelService,
    AmbientSocialRealityLearningService? ambientSocialRealityLearningService,
    VibeKernel? vibeKernel,
  })  : _interpretationKernelService =
            interpretationKernelService ?? InterpretationKernelService(),
        _boundaryKernelService =
            boundaryKernelService ?? BoundaryKernelService(),
        _governanceKernelService =
            governanceKernelService ?? GovernanceKernelService(),
        _ambientSocialRealityLearningService = ambientSocialRealityLearningService,
        _vibeKernel = vibeKernel ?? VibeKernel();

  final InterpretationKernelService _interpretationKernelService;
  final BoundaryKernelService _boundaryKernelService;
  final GovernanceKernelService _governanceKernelService;
  final AmbientSocialRealityLearningService? _ambientSocialRealityLearningService;
  final VibeKernel _vibeKernel;

  Future<PeerInteractionOutcomeLearningResult> recordCompletedInteraction({
    required String localUserId,
    required String localAgentId,
    required AIPersonalityNode remoteNode,
    required ConnectionMetrics connection,
    String? completionReason,
  }) async {
    final remoteContext = remoteNode.resolvedPeerContext;
    if (remoteContext == null ||
        connection.status != ConnectionStatus.completed ||
        !_hasMeaningfulInteraction(connection)) {
      return const PeerInteractionOutcomeLearningResult(
        applied: false,
        receipts: <VibeUpdateReceipt>[],
        boundaryDecision: null,
        governanceDecision: null,
      );
    }

    final sessionSummary = _buildSessionSummary(
      remoteNode: remoteNode,
      remoteContext: remoteContext,
      connection: connection,
      completionReason: completionReason,
    );
    final interpretation = _interpretationKernelService.interpretHumanText(
      rawText: sessionSummary,
      surface: 'ai2ai_connection',
      channel: 'session_outcome',
    );
    final boundaryDecision = _boundaryKernelService.enforceBoundary(
      actorAgentId: localAgentId,
      rawText: sessionSummary,
      interpretation: interpretation,
      consentScopes: const <String>{
        'governed_peer_learning',
        'governance_runtime_learning',
      },
      privacyMode: BoundaryPrivacyMode.governance,
      shareRequested: false,
      egressPurpose: BoundaryEgressPurpose.none,
    );
    if (!boundaryDecision.accepted || !boundaryDecision.learningAllowed) {
      return PeerInteractionOutcomeLearningResult(
        applied: false,
        receipts: const <VibeUpdateReceipt>[],
        boundaryDecision: boundaryDecision,
        governanceDecision: null,
      );
    }

    final evidence = _buildOutcomeEvidence(
      remoteNode: remoteNode,
      remoteContext: remoteContext,
      connection: connection,
      completionReason: completionReason,
    );
    final ambientObservation = _buildAmbientSocialObservation(
      remoteNode: remoteNode,
      remoteContext: remoteContext,
      connection: connection,
      completionReason: completionReason,
    );
    if (ambientObservation != null) {
      await _ambientSocialRealityLearningService?.applyObservation(
        observation: ambientObservation,
        personalAgentId: localAgentId,
      );
    }
    final governanceDecision = _governanceKernelService.authorizeVibeMutation(
      subjectId: localAgentId,
      evidence: evidence,
      governanceScope: 'personal',
    );
    if (!governanceDecision.stateWriteAllowed) {
      return PeerInteractionOutcomeLearningResult(
        applied: false,
        receipts: const <VibeUpdateReceipt>[],
        boundaryDecision: boundaryDecision,
        governanceDecision: governanceDecision,
      );
    }

    final receipts = <VibeUpdateReceipt>[
      _vibeKernel.ingestLanguageEvidence(
        subjectId: localAgentId,
        evidence: evidence,
        mutationDecision: governanceDecision,
        provenanceTags: <String>[
          'peer_interaction_outcome',
          localUserId,
          connection.connectionId,
        ],
      ),
      _vibeKernel.recordOutcome(
        subjectId: localAgentId,
        outcome: completionReason == null || completionReason.isEmpty
            ? 'peer_connection_completed'
            : 'peer_connection_$completionReason',
        outcomeScore: connection.qualityScore.clamp(0.0, 1.0),
      ),
    ];

    return PeerInteractionOutcomeLearningResult(
      applied: true,
      receipts: receipts,
      boundaryDecision: boundaryDecision,
      governanceDecision: governanceDecision,
    );
  }

  bool _hasMeaningfulInteraction(ConnectionMetrics connection) {
    return connection.interactionHistory.isNotEmpty ||
        connection.connectionDuration.inSeconds >= 30 ||
        connection.learningEffectiveness > 0.0 ||
        connection.aiPleasureScore > 0.5;
  }

  String _buildSessionSummary({
    required AIPersonalityNode remoteNode,
    required ResolvedPeerVibeContext remoteContext,
    required ConnectionMetrics connection,
    String? completionReason,
  }) {
    final reasonCodes =
        (connection.learningOutcomes['canonical_reason_codes'] as List?)
                ?.map((entry) => entry.toString())
                .where((entry) => entry.isNotEmpty)
                .toList(growable: false) ??
            const <String>[];
    final sharedGeography =
        (connection.learningOutcomes['shared_geographic_levels'] as List?)
                ?.map((entry) => entry.toString())
                .where((entry) => entry.isNotEmpty)
                .toList(growable: false) ??
            const <String>[];
    final sharedScoped =
        (connection.learningOutcomes['shared_scoped_context_ids'] as List?)
                ?.map((entry) => entry.toString())
                .where((entry) => entry.isNotEmpty)
                .toList(growable: false) ??
            const <String>[];
    final parts = <String>[
      'Completed a peer interaction with ${remoteNode.nodeId}.',
      'Peer archetype ${remoteContext.personalSurface.archetype}.',
      'Quality score ${connection.qualityScore.toStringAsFixed(2)}.',
      if (completionReason != null && completionReason.isNotEmpty)
        'Completion reason $completionReason.',
      if (reasonCodes.isNotEmpty)
        'Canonical reasons ${reasonCodes.join(", ")}.',
      if (sharedGeography.isNotEmpty)
        'Shared geography ${sharedGeography.join(", ")}.',
      if (sharedScoped.isNotEmpty) 'Shared scoped contexts present.',
    ];
    return parts.join(' ');
  }

  VibeEvidence _buildOutcomeEvidence({
    required AIPersonalityNode remoteNode,
    required ResolvedPeerVibeContext remoteContext,
    required ConnectionMetrics connection,
    String? completionReason,
  }) {
    final quality = connection.qualityScore.clamp(0.0, 1.0);
    final sharedGeographyCount =
        ((connection.learningOutcomes['shared_geographic_levels'] as List?)
                    ?.length ??
                0)
            .toDouble();
    final sharedScopedCount =
        ((connection.learningOutcomes['shared_scoped_context_ids'] as List?)
                    ?.length ??
                0)
            .toDouble();
    final freshnessSignal =
        (1.0 - (remoteContext.freshnessHours.clamp(0.0, 168.0) / 168.0))
            .clamp(0.0, 1.0);
    final confidence = remoteContext.confidence.clamp(0.0, 1.0);
    final provenance = <String>[
      'peer_interaction_outcome',
      remoteNode.nodeId,
      connection.connectionId,
    ];
    return VibeEvidence(
      summary:
          'Governed peer interaction outcome for ${remoteNode.nodeId}${completionReason == null ? '' : ' ($completionReason)'}',
      identitySignals: <VibeSignal>[
        VibeSignal(
          key: 'peer_session_alignment',
          kind: VibeSignalKind.identity,
          value: connection.currentCompatibility.clamp(0.0, 1.0),
          confidence: confidence,
          provenance: provenance,
        ),
      ],
      pheromoneSignals: <VibeSignal>[
        VibeSignal(
          key: 'peer_session_resonance',
          kind: VibeSignalKind.pheromone,
          value: quality,
          confidence: confidence,
          provenance: provenance,
        ),
      ],
      behaviorSignals: <VibeSignal>[
        VibeSignal(
          key: 'peer_connection_quality',
          kind: VibeSignalKind.behavior,
          value: quality,
          confidence: confidence,
          provenance: provenance,
        ),
        if (sharedGeographyCount > 0)
          VibeSignal(
            key: 'peer_shared_geography',
            kind: VibeSignalKind.behavior,
            value: (sharedGeographyCount / 4.0).clamp(0.0, 1.0),
            confidence: confidence,
            provenance: provenance,
          ),
        if (sharedScopedCount > 0)
          VibeSignal(
            key: 'peer_shared_scoped_context',
            kind: VibeSignalKind.behavior,
            value: (sharedScopedCount / 3.0).clamp(0.0, 1.0),
            confidence: confidence,
            provenance: provenance,
          ),
      ],
      affectiveSignals: <VibeSignal>[
        VibeSignal(
          key: 'peer_interaction_valence',
          kind: VibeSignalKind.affective,
          value: connection.aiPleasureScore.clamp(0.0, 1.0),
          confidence: confidence,
          provenance: provenance,
        ),
        VibeSignal(
          key: 'peer_context_freshness',
          kind: VibeSignalKind.affective,
          value: freshnessSignal,
          confidence: confidence,
          provenance: provenance,
        ),
      ],
      styleSignals: <VibeSignal>[
        VibeSignal(
          key: 'peer_directness_fit',
          kind: VibeSignalKind.style,
          value: remoteContext.personalSurface.directness.clamp(0.0, 1.0),
          confidence: confidence,
          provenance: provenance,
        ),
      ],
    );
  }

  AmbientSocialLearningObservation? _buildAmbientSocialObservation({
    required AIPersonalityNode remoteNode,
    required ResolvedPeerVibeContext remoteContext,
    required ConnectionMetrics connection,
    String? completionReason,
  }) {
    final geographicBinding = remoteContext.geographicBinding;
    if (geographicBinding == null || geographicBinding.stableKey.trim().isEmpty) {
      return null;
    }
    final sharedGeography =
        ((connection.learningOutcomes['shared_geographic_levels'] as List?) ??
                const <dynamic>[])
            .map((entry) => entry.toString())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final sharedScoped =
        ((connection.learningOutcomes['shared_scoped_context_ids'] as List?) ??
                const <dynamic>[])
            .map((entry) => entry.toString())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final observedAtUtc =
        (connection.endTime ?? DateTime.now()).toUtc();
    return AmbientSocialLearningObservation(
      source: AmbientSocialLearningObservationSource.ai2aiCompletedInteraction,
      observedAtUtc: observedAtUtc,
      localityBinding: geographicBinding,
      discoveredPeerIds: <String>[remoteNode.nodeId],
      confirmedInteractivePeerIds: <String>[remoteNode.nodeId],
      confidence:
          ((remoteContext.confidence + connection.qualityScore) / 2.0)
              .clamp(0.0, 1.0),
      interactionQuality: connection.qualityScore.clamp(0.0, 1.0),
      semanticTuples: <SemanticTuple>[
        SemanticTuple(
          id: 'ai2ai-social-confirmed:${connection.connectionId}',
          category: 'ai2ai_presence',
          subject: 'ai2ai_runtime',
          predicate: 'confirmed_interactive_presence',
          object: 'dyad',
          confidence: (0.70 + connection.qualityScore * 0.18)
              .clamp(0.0, 0.98),
          extractedAt: observedAtUtc,
        ),
      ],
      structuredSignals: <String, dynamic>{
        'ai2aiInteractionConfirmed': true,
        'connectionId': connection.connectionId,
        'completionReason': completionReason ?? 'completed',
        'peerSessionQuality': connection.qualityScore.clamp(0.0, 1.0),
        'sharedGeographicLevels': sharedGeography,
        'sharedScopedContextIds': sharedScoped,
      },
      locationContext: <String, dynamic>{
        'localityStableKey': geographicBinding.stableKey,
        if (geographicBinding.cityCode != null)
          'cityCode': geographicBinding.cityCode,
        if (geographicBinding.regionCode != null)
          'regionCode': geographicBinding.regionCode,
      },
      temporalContext: <String, dynamic>{
        'interactionStartedAtUtc': connection.startTime.toUtc().toIso8601String(),
        'interactionEndedAtUtc': observedAtUtc.toIso8601String(),
        'durationSeconds': connection.connectionDuration.inSeconds,
      },
      activityContext: 'ambient_socializing',
      lineageRef: 'ai2ai_completed:${connection.connectionId}',
    );
  }
}
