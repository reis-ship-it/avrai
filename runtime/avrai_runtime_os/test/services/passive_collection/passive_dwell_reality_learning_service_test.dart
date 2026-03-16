import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  String? lastSocialContext;
  Map<String, dynamic>? lastStructuredSignals;
  List<SemanticTuple>? lastSemanticTuples;
  String? lastEntityRef;

  @override
  Future<String?> currentAgentId() async => 'agent-passive-1';

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
    lastEntityRef = entityRef;
    lastSocialContext = socialContext;
    lastStructuredSignals = structuredSignals;
    lastSemanticTuples = semanticTuples;
    return WhatUpdateReceipt(
      state: WhatState(
        entityRef: entityRef,
        canonicalType: 'third_place',
        subtypes: const <String>[],
        aliases: const <String>[],
        placeType: 'third_place',
        activityTypes: const <String>['ambient_socializing'],
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
        lineageRefs: lineageRef == null
            ? const <String>[]
            : <String>[lineageRef],
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
    TrajectoryKernel.resetFallbackStateForTesting();
    TrajectoryKernel().importJournalWindow(
      records: const <TrajectoryMutationRecord>[],
    );
  });

  tearDown(() {
    VibeKernelRuntimeBindings.persistenceBridge = null;
  });

  group('PassiveDwellLearningProjection', () {
    test('derives crowd and place-vibe learning from multi-agent dwell', () {
      final projection = PassiveDwellLearningProjection.fromEvent(
        DwellEvent(
          startTime: DateTime.utc(2026, 3, 13, 18, 0),
          endTime: DateTime.utc(2026, 3, 13, 19, 15),
          latitude: 33.5207,
          longitude: -86.8025,
          encounteredAgentIds: const <String>['peer-a', 'peer-b', 'peer-c'],
        ),
      );

      expect(projection.socialContext, 'social_cluster');
      expect(projection.placeVibeLabel, 'social_hub');
      expect(projection.crowdRecognitionScore, greaterThan(0.7));
      expect(projection.localityStableKey, startsWith('gh7:'));
      expect(projection.structuredSignals['autonomousCrowdRecognition'], true);
      expect(projection.personalDimensions, isNotEmpty);
      expect(
        projection.derivedSemanticTuples.any(
          (entry) => entry.predicate == 'expresses_place_vibe',
        ),
        isTrue,
      );
    });

    test(
      'keeps personal DNA feedback off for solo dwell while preserving place vibe',
      () {
        final projection = PassiveDwellLearningProjection.fromEvent(
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 8, 0),
            endTime: DateTime.utc(2026, 3, 13, 8, 45),
            latitude: 33.5001,
            longitude: -86.7999,
          ),
        );

        expect(projection.socialContext, 'solo');
        expect(projection.placeVibeLabel, 'quiet_retreat');
        expect(projection.crowdRecognitionScore, 0.0);
        expect(projection.personalDimensions, isEmpty);
        expect(projection.structuredSignals['coPresenceDetected'], isFalse);
      },
    );

    test(
      'ambient social learning merges passive presence with confirmed interaction',
      () async {
        final whatIngestion = _FakeWhatRuntimeIngestionService();
        final service = AmbientSocialRealityLearningService(
          whatIngestion: whatIngestion,
          nowUtc: () => DateTime.utc(2026, 3, 13, 20),
        );
        final passiveProjection = PassiveDwellLearningProjection.fromEvent(
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 18, 0),
            endTime: DateTime.utc(2026, 3, 13, 19, 15),
            latitude: 33.5207,
            longitude: -86.8025,
            encounteredAgentIds: const <String>['peer-a', 'peer-b'],
          ),
        );

        await service.applyObservation(
          observation: AmbientSocialLearningObservation.fromPassiveDwell(
            event: DwellEvent(
              startTime: DateTime.utc(2026, 3, 13, 18, 0),
              endTime: DateTime.utc(2026, 3, 13, 19, 15),
              latitude: 33.5207,
              longitude: -86.8025,
              encounteredAgentIds: const <String>['peer-a', 'peer-b'],
            ),
            projection: passiveProjection,
          ),
          personalAgentId: 'agent-passive-1',
        );

        await service.applyObservation(
          observation: AmbientSocialLearningObservation(
            source: AmbientSocialLearningObservationSource
                .ai2aiCompletedInteraction,
            observedAtUtc: DateTime.utc(2026, 3, 13, 19, 18),
            localityBinding: passiveProjection.localityBinding,
            discoveredPeerIds: const <String>['peer-a'],
            confirmedInteractivePeerIds: const <String>['peer-a'],
            confidence: 0.84,
            interactionQuality: 0.81,
          ),
          personalAgentId: 'agent-passive-1',
        );

        final snapshot = service.snapshot(
          capturedAtUtc: DateTime.utc(2026, 3, 13, 20),
        );
        expect(snapshot.normalizedObservationCount, 2);
        expect(snapshot.confirmedInteractionPromotionCount, 1);
        expect(snapshot.duplicateMergeCount, 0);
        expect(snapshot.rejectedInteractionPromotionCount, 0);
        expect(snapshot.crowdUpgradeCount, 1);
        expect(snapshot.whatIngestionCount, 2);
        expect(snapshot.latestNearbyPeerCount, 2);
        expect(snapshot.latestConfirmedInteractivePeerCount, 1);
        expect(snapshot.latestPlaceVibeLabel, 'intimate_social');
        expect(snapshot.latestSocialContext, 'small_group');
        expect(snapshot.lastPromotionTrace, isNotNull);
        expect(
          snapshot.lastPromotionTrace?.confirmedInteractivePeerIds,
          contains('peer-a'),
        );
        expect(
          whatIngestion.lastEntityRef,
          startsWith('ambient_social_scene:'),
        );
        expect(
          whatIngestion.lastStructuredSignals?['interactivePresenceConfirmed'],
          isTrue,
        );
        expect(
          whatIngestion.lastSemanticTuples?.any(
            (entry) => entry.predicate == 'confirmed_interactive_presence',
          ),
          isTrue,
        );
      },
    );

    test(
      'rejects untrusted AI2AI promotion and counts duplicate merges without double-writing',
      () async {
        final whatIngestion = _FakeWhatRuntimeIngestionService();
        final service = AmbientSocialRealityLearningService(
          whatIngestion: whatIngestion,
          nowUtc: () => DateTime.utc(2026, 3, 13, 21),
        );
        final passiveProjection = PassiveDwellLearningProjection.fromEvent(
          DwellEvent(
            startTime: DateTime.utc(2026, 3, 13, 19, 0),
            endTime: DateTime.utc(2026, 3, 13, 19, 20),
            latitude: 33.5207,
            longitude: -86.8025,
            encounteredAgentIds: const <String>['peer-a'],
          ),
        );

        await service.applyObservation(
          observation: AmbientSocialLearningObservation.fromPassiveDwell(
            event: DwellEvent(
              startTime: DateTime.utc(2026, 3, 13, 19, 0),
              endTime: DateTime.utc(2026, 3, 13, 19, 20),
              latitude: 33.5207,
              longitude: -86.8025,
              encounteredAgentIds: const <String>['peer-a'],
            ),
            projection: passiveProjection,
          ),
          personalAgentId: 'agent-passive-1',
        );
        await service.applyObservation(
          observation: AmbientSocialLearningObservation(
            source: AmbientSocialLearningObservationSource
                .ai2aiCompletedInteraction,
            observedAtUtc: DateTime.utc(2026, 3, 13, 19, 22),
            localityBinding: passiveProjection.localityBinding,
            discoveredPeerIds: const <String>['peer-a'],
            confirmedInteractivePeerIds: const <String>['peer-a'],
            confidence: 0.8,
            interactionQuality: 0.77,
            structuredSignals: const <String, dynamic>{
              'interactionTrusted': true,
              'promotionEligible': true,
            },
            lineageRef: 'ambient:ai2ai:peer-a',
          ),
          personalAgentId: 'agent-passive-1',
        );
        final beforeRejected = service.snapshot(
          capturedAtUtc: DateTime.utc(2026, 3, 13, 21),
        );
        await service.applyObservation(
          observation: AmbientSocialLearningObservation(
            source: AmbientSocialLearningObservationSource
                .ai2aiCompletedInteraction,
            observedAtUtc: DateTime.utc(2026, 3, 13, 19, 23),
            localityBinding: passiveProjection.localityBinding,
            discoveredPeerIds: const <String>['peer-a'],
            confirmedInteractivePeerIds: const <String>['peer-a'],
            confidence: 0.8,
            interactionQuality: 0.77,
            structuredSignals: const <String, dynamic>{
              'interactionTrusted': true,
              'promotionEligible': true,
            },
            lineageRef: 'ambient:ai2ai:peer-a',
          ),
          personalAgentId: 'agent-passive-1',
        );
        await service.applyObservation(
          observation: AmbientSocialLearningObservation(
            source: AmbientSocialLearningObservationSource
                .ai2aiCompletedInteraction,
            observedAtUtc: DateTime.utc(2026, 3, 13, 19, 25),
            localityBinding: passiveProjection.localityBinding,
            discoveredPeerIds: const <String>['peer-a'],
            confidence: 0.2,
            structuredSignals: const <String, dynamic>{
              'interactionTrusted': false,
              'promotionEligible': false,
            },
            lineageRef: 'ambient:ai2ai:peer-a:rejected',
          ),
          personalAgentId: 'agent-passive-1',
        );

        final snapshot = service.snapshot(
          capturedAtUtc: DateTime.utc(2026, 3, 13, 21),
        );
        expect(snapshot.confirmedInteractionPromotionCount, 1);
        expect(snapshot.duplicateMergeCount, 1);
        expect(snapshot.rejectedInteractionPromotionCount, 1);
        expect(snapshot.whatIngestionCount, beforeRejected.whatIngestionCount);
        expect(
          snapshot.localityVibeUpdateCount,
          beforeRejected.localityVibeUpdateCount,
        );
        expect(
          snapshot.personalDnaAppliedCount,
          beforeRejected.personalDnaAppliedCount,
        );
      },
    );
  });
}
