import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAirGap implements AirGapContract {
  final List<RawDataPayload> payloads = <RawDataPayload>[];

  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    payloads.add(payload);
    return <SemanticTuple>[
      SemanticTuple(
        id: 'airgap-tuple-${payloads.length}',
        category: 'event_planning',
        subject: 'event',
        predicate: 'sanitized',
        object: 'tuple',
        confidence: 0.88,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

class _FakeContinuousLearningSystem extends ContinuousLearningSystem {
  final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];

  @override
  Future<void> processUserInteraction({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    payloads.add(<String, dynamic>{'userId': userId, ...payload});
  }
}

class _RecordedPluginObservation {
  final Map<String, dynamic>? structuredSignals;
  final List<SemanticTuple> semanticTuples;

  const _RecordedPluginObservation({
    required this.structuredSignals,
    required this.semanticTuples,
  });
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  final List<_RecordedPluginObservation> pluginObservations =
      <_RecordedPluginObservation>[];

  @override
  Future<String?> currentAgentId() async => 'agent-learning-1';

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
  }) async {
    pluginObservations.add(
      _RecordedPluginObservation(
        structuredSignals: structuredSignals,
        semanticTuples: semanticTuples,
      ),
    );
    return null;
  }

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
  }) async =>
      null;

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
  }) async =>
      null;

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
    double confidence = 0.6,
    String? lineageRef,
  }) async =>
      null;

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
  }) async =>
      null;

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async =>
      null;

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
  }) async =>
      null;
}

void main() {
  group('EventLearningSignalService', () {
    const planningScope = TruthScopeDescriptor.defaultPlanning(
      governanceStratum: GovernanceStratum.locality,
      sphereId: 'event_planning_locality',
      familyId: 'creator_event_prep_human',
    );
    late _FakeAirGap airGap;
    late _FakeContinuousLearningSystem learningSystem;
    late _FakeWhatRuntimeIngestionService whatIngestion;
    late UniversalIntakeRepository intakeRepository;
    late GovernedUpwardLearningIntakeService upwardService;
    late EventLearningSignalService service;
    late ExpertiseEvent event;
    late EventPlanningSnapshot snapshot;

    setUp(() {
      airGap = _FakeAirGap();
      learningSystem = _FakeContinuousLearningSystem();
      whatIngestion = _FakeWhatRuntimeIngestionService();
      intakeRepository = UniversalIntakeRepository();
      upwardService = GovernedUpwardLearningIntakeService(
        intakeRepository: intakeRepository,
        atomicClockService: AtomicClockService(),
      );
      service = EventLearningSignalService(
        continuousLearningSystem: learningSystem,
        whatIngestion: whatIngestion,
        airGap: airGap,
        governedUpwardLearningIntakeService: upwardService,
      );

      final host = UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        createdAt: DateTime.utc(2026, 3, 14),
        updatedAt: DateTime.utc(2026, 3, 14),
        isOnline: false,
      );

      snapshot = EventPlanningSnapshot(
        docket: EventDocketLite(
          intentTags: const <String>['spring', 'music'],
          vibeTags: const <String>['joyful', 'outdoor'],
          audienceTags: const <String>['families'],
          candidateLocalityLabel: 'Avondale',
          candidateLocalityCode: 'bham_avondale',
          preferredStartDate: DateTime.utc(2026, 3, 21, 17),
          preferredEndDate: DateTime.utc(2026, 3, 21, 21),
          sizeIntent: EventSizeIntent.large,
          priceIntent: EventPriceIntent.lowCost,
          hostGoal: EventHostGoal.celebration,
          airGapProvenance: EventAirGapProvenance(
            crossingId: 'crossing-event-learning-signal-test',
            crossedAt: DateTime.utc(2026, 3, 14, 12),
            sourceKind: EventPlanningSourceKind.human,
            tupleRefs: const <String>['tuple-1'],
            confidence: EventPlanningConfidence.high,
          ),
        ),
        acceptedSuggestion: EventCreationSuggestion(
          suggestedStartTime: DateTime.utc(2026, 3, 21, 18),
          suggestedEndTime: DateTime.utc(2026, 3, 21, 20),
          suggestedLocalityLabel: 'Avondale',
          suggestedMaxAttendees: 48,
          suggestedPrice: 15.0,
          predictedAttendanceFillBand: EventAttendanceFillBand.high,
          confidence: EventPlanningConfidence.high,
          explanation: 'High confidence suggestion.',
          truthScope: planningScope,
        ),
        createdAt: DateTime.utc(2026, 3, 14, 12, 30),
        truthScope: planningScope,
      );

      event = ExpertiseEvent(
        id: 'event-123',
        title: 'Spring Music Festival',
        description: 'City-wide spring celebration.',
        category: 'Music',
        eventType: ExpertiseEventType.meetup,
        host: host,
        spots: <Spot>[
          Spot(
            id: 'spot-1',
            name: 'Venue One',
            description: 'Open-air venue',
            latitude: 33.5248,
            longitude: -86.7742,
            category: 'music_venue',
            rating: 4.7,
            createdBy: 'host-1',
            cityCode: 'birmingham_al',
            localityCode: 'bham_avondale',
            metadata: const <String, dynamic>{'businessId': 'business-1'},
            createdAt: DateTime.utc(2026, 3, 14),
            updatedAt: DateTime.utc(2026, 3, 14),
          ),
        ],
        cityCode: 'birmingham_al',
        localityCode: 'bham_avondale',
        startTime: DateTime.utc(2026, 3, 21, 17),
        endTime: DateTime.utc(2026, 3, 21, 21),
        createdAt: DateTime.utc(2026, 3, 14),
        updatedAt: DateTime.utc(2026, 3, 14),
        planningSnapshot: snapshot,
      );
    });

    test('records creation learning from sanitized planning snapshot only',
        () async {
      final signal = await service.recordEventCreated(
        event: event,
        snapshot: snapshot,
      );

      expect(signal.kind, equals(EventLearningSignalKind.eventCreated));
      expect(learningSystem.payloads, hasLength(1));
      expect(
        learningSystem.payloads.single['event_type'],
        equals('event_planning_created'),
      );
      expect(
        learningSystem.payloads.single.toString(),
        isNot(contains('city-wide spring celebration for everybody')),
      );
      expect(
        learningSystem.payloads.single.toString(),
        contains('spring'),
      );
      expect(signal.truthScope.scopeKey, planningScope.scopeKey);
      expect(
        signal.boundedPayload['planning_scope_key'],
        planningScope.scopeKey,
      );
      expect(signal.evidenceEnvelope, isNotNull);
      expect(signal.evidenceEnvelope?.scope.scopeKey, planningScope.scopeKey);
      expect(signal.compressedArtifactEnvelope, isNotNull);
      expect(signal.compressedKnowledgePacket, isNotNull);
      expect(signal.compressionBudgetProfile, isNotNull);
      expect(
        signal.evidenceEnvelope?.evidenceClass,
        equals('planning_learning_signal'),
      );
      expect(whatIngestion.pluginObservations.length, greaterThanOrEqualTo(3));
      expect(
        whatIngestion.pluginObservations.first.structuredSignals.toString(),
        isNot(contains('raw planning text')),
      );
      expect(
        whatIngestion.pluginObservations.first.structuredSignals,
        contains('air_gap_compression'),
      );
    });

    test('outcome notes cross the air gap before outcome learning', () async {
      final debrief = HostEventDebrief(
        eventId: event.id,
        predictedAttendanceFillBand: EventAttendanceFillBand.high,
        actualAttendance: 91,
        attendanceRate: 0.82,
        averageRating: 4.6,
        wouldAttendAgainRate: 0.9,
        insightLines: const <String>['Families stayed longer than expected.'],
        createdAt: DateTime.utc(2026, 3, 22, 9),
        truthScope: planningScope,
      );

      final signal = await service.recordEventOutcome(
        event: event,
        debrief: debrief,
        outcomeNotesRaw: 'The raw crowd notes should stay private.',
      );

      expect(airGap.payloads, hasLength(1));
      expect(
        airGap.payloads.single.rawContent,
        contains('The raw crowd notes should stay private.'),
      );
      expect(signal.kind, equals(EventLearningSignalKind.eventCompleted));
      expect(signal.tupleRefs, contains('airgap-tuple-1'));
      expect(signal.truthScope.scopeKey, planningScope.scopeKey);
      expect(signal.evidenceEnvelope, isNotNull);
      expect(signal.evidenceEnvelope?.scope.scopeKey, planningScope.scopeKey);
      expect(signal.compressedArtifactEnvelope, isNotNull);
      expect(signal.compressedKnowledgePacket, isNotNull);
      expect(learningSystem.payloads, hasLength(1));
      expect(
        learningSystem.payloads.single['event_type'],
        equals('event_planning_outcome_recorded'),
      );
      expect(
        learningSystem.payloads.single.toString(),
        isNot(contains('The raw crowd notes should stay private.')),
      );
      expect(
        learningSystem.payloads.single.toString(),
        contains('outcome_note_tuple_count'),
      );
      expect(signal.boundedPayload, contains('air_gap_compression'));
      final reviews = await intakeRepository.getAllReviewItems();
      expect(reviews, hasLength(1));
      expect(reviews.single.payload['sourceKind'], 'event_outcome_intake');
      expect(
        reviews.single.payload['upwardDomainHints'],
        containsAll(
            const <String>['business', 'event', 'locality', 'place', 'venue']),
      );
    });
  });
}
