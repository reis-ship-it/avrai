import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/quantum/connection_metrics.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/ai2ai/aipersonality_node.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/ai2ai/peer_interaction_outcome_learning_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../support/fake_kernel_governance.dart';
import '../support/fake_language_kernels.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  int ambientIngestionCount = 0;
  String? lastEntityRef;
  String? lastSocialContext;

  @override
  Future<String?> currentAgentId() async => 'agent-local';

  @override
  Future<WhatUpdateReceipt?> ingestAmbientSocialObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async {
    ambientIngestionCount += 1;
    lastEntityRef = entityRef;
    lastSocialContext = socialContext;
    return WhatUpdateReceipt(
      state: WhatState(
        entityRef: entityRef,
        canonicalType: 'third_place',
        subtypes: const <String>[],
        aliases: const <String>[],
        placeType: 'third_place',
        activityTypes: activityContext == null
            ? const <String>[]
            : <String>[activityContext],
        socialContexts: socialContext == null
            ? const <String>[]
            : <String>[socialContext],
        affordanceVector: const <String, double>{},
        vibeSignature: const <String, double>{},
        confidence: confidence,
        evidenceCount: 1,
        firstObservedAtUtc: observedAtUtc,
        lastObservedAtUtc: observedAtUtc,
        sourceMix: const WhatSourceMix(structured: 1.0),
        lineageRefs:
            lineageRef == null ? const <String>[] : <String>[lineageRef],
      ),
    );
  }

  @override
  Future<WhatUpdateReceipt?> ingestEventAttendanceObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.64,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestListInteractionObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.57,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestPassiveDwellObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.58,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestPluginSemanticObservation({
    required String source,
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    List<SemanticTuple> semanticTuples = const <SemanticTuple>[],
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.6,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async => null;

  @override
  Future<WhatUpdateReceipt?> ingestVisitObservation({
    required String entityRef,
    required DateTime observedAtUtc,
    String? agentId,
    Map<String, dynamic>? structuredSignals,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? socialContext,
    String? activityContext,
    double confidence = 0.62,
    String? lineageRef,
  }) async => null;
}

void main() {
  setUp(() {
    VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
    VibeKernel().importSnapshotEnvelope(
      VibeSnapshotEnvelope(exportedAtUtc: DateTime.utc(2026, 3, 12)),
    );
    TrajectoryKernel().importJournalWindow(
      records: const <TrajectoryMutationRecord>[],
    );
  });

  tearDown(() {
    VibeKernelRuntimeBindings.persistenceBridge = null;
  });

  group('PeerInteractionOutcomeLearningService', () {
    test('remote payload alone does not mutate local vibe state', () async {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'exploration_eagerness': 0.71,
          'community_orientation': 0.64,
          'authenticity_preference': 0.66,
          'energy_preference': 0.58,
        },
        provenanceTags: const <String>['test:peer_learning'],
      );
      final trajectoryKernel = TrajectoryKernel();
      final before = trajectoryKernel.exportJournalWindow(limit: 64).length;
      final service = PeerInteractionOutcomeLearningService(
        interpretationKernelService: TestInterpretationKernelService(),
        boundaryKernelService: TestBoundaryKernelService(),
        governanceKernelService: buildTestGovernanceKernelService(),
        vibeKernel: vibeKernel,
      );

      final result = await service.recordCompletedInteraction(
        localUserId: 'user-local',
        localAgentId: 'agent-local',
        remoteNode: _resolvedRemoteNode(),
        connection: ConnectionMetrics.initial(
          localAISignature: 'local-signature',
          remoteAISignature: 'remote-signature',
          compatibility: 0.8,
        ),
      );

      final after = trajectoryKernel.exportJournalWindow(limit: 64).length;
      expect(result.applied, isFalse);
      expect(after, before);
    });

    test('completed governed peer interaction creates local mutation receipts',
        () async {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'exploration_eagerness': 0.72,
          'community_orientation': 0.67,
          'authenticity_preference': 0.65,
          'temporal_flexibility': 0.62,
          'energy_preference': 0.61,
          'novelty_seeking': 0.7,
        },
        provenanceTags: const <String>['test:peer_learning'],
      );
      final trajectoryKernel = TrajectoryKernel();
      final before = trajectoryKernel.exportJournalWindow(limit: 64).length;
      final service = PeerInteractionOutcomeLearningService(
        interpretationKernelService: TestInterpretationKernelService(),
        boundaryKernelService: TestBoundaryKernelService(),
        governanceKernelService: buildTestGovernanceKernelService(),
        vibeKernel: vibeKernel,
      );
      final connection = ConnectionMetrics.initial(
        localAISignature: 'local-signature',
        remoteAISignature: 'remote-signature',
        compatibility: 0.82,
        learningOutcomesSeed: const <String, dynamic>{
          'canonical_reason_codes': <String>[
            'shared_geography',
            'personal_surface_alignment',
          ],
          'shared_geographic_levels': <String>['locality', 'city'],
          'shared_scoped_context_ids': <String>[
            'scene:locality-agent:bham-downtown:indie-music',
          ],
        },
      ).updateDuringInteraction(
        newCompatibility: 0.84,
        learningEffectiveness: 0.72,
        aiPleasureScore: 0.78,
        newInteraction: InteractionEvent.success(
          type: InteractionType.vibeExchange,
          data: const <String, dynamic>{'canonical_peer_payload': true},
        ),
      ).complete(
        finalStatus: ConnectionStatus.completed,
        completionReason: 'natural_completion',
      );

      final result = await service.recordCompletedInteraction(
        localUserId: 'user-local',
        localAgentId: 'agent-local',
        remoteNode: _resolvedRemoteNode(),
        connection: connection,
        completionReason: 'natural_completion',
      );

      final after = trajectoryKernel.exportJournalWindow(limit: 64).length;
      expect(result.applied, isTrue);
      expect(result.receipts, isNotEmpty);
      expect(after, greaterThan(before));
    });

    test('completed trusted interaction promotes ambient-social evidence through what ingress',
        () async {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'community_orientation': 0.66,
          'energy_preference': 0.61,
        },
        provenanceTags: const <String>['test:ambient_peer_learning'],
      );
      final whatIngestion = _FakeWhatRuntimeIngestionService();
      final ambientService = AmbientSocialRealityLearningService(
        whatIngestion: whatIngestion,
        governanceKernelService: buildTestGovernanceKernelService(),
        vibeKernel: vibeKernel,
        nowUtc: () => DateTime.utc(2026, 3, 14, 2),
      );
      final service = PeerInteractionOutcomeLearningService(
        interpretationKernelService: TestInterpretationKernelService(),
        boundaryKernelService: TestBoundaryKernelService(),
        governanceKernelService: buildTestGovernanceKernelService(),
        ambientSocialRealityLearningService: ambientService,
        vibeKernel: vibeKernel,
      );
      final connection = ConnectionMetrics.initial(
        localAISignature: 'local-signature',
        remoteAISignature: 'remote-signature',
        compatibility: 0.83,
        learningOutcomesSeed: const <String, dynamic>{
          'shared_geographic_levels': <String>['locality'],
        },
      ).updateDuringInteraction(
        newCompatibility: 0.85,
        learningEffectiveness: 0.74,
        aiPleasureScore: 0.8,
        newInteraction: InteractionEvent.success(
          type: InteractionType.vibeExchange,
          data: const <String, dynamic>{'canonical_peer_payload': true},
        ),
      ).complete(
        finalStatus: ConnectionStatus.completed,
        completionReason: 'natural_completion',
      );

      final result = await service.recordCompletedInteraction(
        localUserId: 'user-local',
        localAgentId: 'agent-local',
        remoteNode: _resolvedRemoteNode(),
        connection: connection,
        completionReason: 'natural_completion',
      );

      final snapshot = ambientService.snapshot(
        capturedAtUtc: DateTime.utc(2026, 3, 14, 2),
      );
      expect(result.applied, isTrue);
      expect(whatIngestion.ambientIngestionCount, 1);
      expect(whatIngestion.lastEntityRef, startsWith('ambient_social_scene:'));
      expect(whatIngestion.lastSocialContext, 'dyad');
      expect(snapshot.normalizedObservationCount, 1);
      expect(snapshot.confirmedInteractionPromotionCount, 1);
      expect(snapshot.whatIngestionCount, 1);
      expect(snapshot.latestConfirmedInteractivePeerCount, 1);
      expect(snapshot.latestPlaceVibeLabel, 'intimate_social');
    });
  });
}

AIPersonalityNode _resolvedRemoteNode() {
  final service = CanonicalPeerResolutionService(
    governanceKernelService: buildTestGovernanceKernelService(),
  );
  final now = DateTime.utc(2026, 3, 12, 12);
  final resolved = service.resolveInboundPayload(
    localAgentId: 'agent-local',
    remotePayload: Ai2AiCanonicalPeerPayload(
      reference: Ai2AiVibeReference(
        subjectRef: VibeSubjectRef.personal('agent-remote'),
        scope: 'personal',
        confidence: 0.83,
        geographicBinding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality('bham-downtown'),
          stableKey: 'bham-downtown',
          higherGeographicRefs: <VibeSubjectRef>[
            VibeSubjectRef.city('bham'),
            VibeSubjectRef.region('al'),
            VibeSubjectRef.global('earth'),
          ],
          cityCode: 'bham',
          regionCode: 'al',
          globalCode: 'earth',
        ),
        scopedBindings: <ScopedVibeBinding>[
          ScopedVibeBinding(
            contextRef: VibeSubjectRef.scoped(
              scopedId: 'scene:locality-agent:bham-downtown:indie-music',
              scopedKind: ScopedAgentKind.scene,
            ),
            scopedKind: ScopedAgentKind.scene,
            anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
          ),
        ],
        snapshotUpdatedAtUtc: now,
      ),
      personalSurface: const CanonicalPeerCompatibilitySurface(
        signatureHash: 'remote-signature',
        archetype: 'social_connector',
        dimensionWindow: <String, double>{
          'exploration_eagerness': 0.71,
          'community_orientation': 0.68,
          'authenticity_preference': 0.64,
          'temporal_flexibility': 0.62,
          'energy_preference': 0.6,
          'novelty_seeking': 0.69,
          'value_orientation': 0.5,
          'crowd_tolerance': 0.57,
        },
        energy: 0.61,
        socialCadence: 0.72,
        directness: 0.58,
        confidence: 0.83,
      ),
      geographicBinding: GeographicVibeBinding(
        localityRef: VibeSubjectRef.locality('bham-downtown'),
        stableKey: 'bham-downtown',
        higherGeographicRefs: <VibeSubjectRef>[
          VibeSubjectRef.city('bham'),
          VibeSubjectRef.region('al'),
          VibeSubjectRef.global('earth'),
        ],
        cityCode: 'bham',
        regionCode: 'al',
        globalCode: 'earth',
      ),
      scopedBindings: <ScopedVibeBinding>[
        ScopedVibeBinding(
          contextRef: VibeSubjectRef.scoped(
            scopedId: 'scene:locality-agent:bham-downtown:indie-music',
            scopedKind: ScopedAgentKind.scene,
          ),
          scopedKind: ScopedAgentKind.scene,
          anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
        ),
      ],
      freshnessHours: 1.0,
      confidence: 0.83,
      generatedAtUtc: now,
    ),
  )!;

  return AIPersonalityNode(
    nodeId: 'agent-remote',
    vibe: service.synthesizeUserVibe(resolved.personalSurface),
    resolvedPeerContext: resolved,
    lastSeen: now,
    trustScore: 0.84,
    learningHistory: const <String, dynamic>{},
  );
}
