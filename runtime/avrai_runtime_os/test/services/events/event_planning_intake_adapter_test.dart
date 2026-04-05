import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/models/events/event_planning.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_intake_adapter.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAirGap implements AirGapContract {
  final List<RawDataPayload> payloads = <RawDataPayload>[];

  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    payloads.add(payload);
    return <SemanticTuple>[
      SemanticTuple(
        id: 'tuple-airgap-1',
        category: 'event_planning',
        subject: 'event_plan',
        predicate: 'describes',
        object: 'sanitized_event_truth',
        confidence: 0.91,
        extractedAt: DateTime.utc(2026, 3, 14, 12),
      ),
    ];
  }
}

class _RecordedPluginObservation {
  final Map<String, dynamic>? structuredSignals;
  final Map<String, dynamic>? locationContext;

  const _RecordedPluginObservation({
    required this.structuredSignals,
    required this.locationContext,
  });
}

class _FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  final List<_RecordedPluginObservation> pluginObservations =
      <_RecordedPluginObservation>[];

  @override
  Future<String?> currentAgentId() async => 'agent-beta-1';

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
        locationContext: locationContext,
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

class _FakeGeoHierarchyService extends GeoHierarchyService {
  @override
  Future<String?> lookupCityCode(String placeName) async => 'birmingham_al';

  @override
  Future<String?> lookupLocalityCode({
    required String cityCode,
    required String localityName,
  }) async =>
      'bham_${localityName.toLowerCase().replaceAll(' ', '_')}';
}

void main() {
  group('EventPlanningIntakeAdapter', () {
    test(
        'crosses raw planning through the air gap and persists only sanitized truth',
        () async {
      final airGap = _FakeAirGap();
      final whatIngestion = _FakeWhatRuntimeIngestionService();
      final adapter = EventPlanningIntakeAdapter(
        airGap,
        whatIngestion: whatIngestion,
        geoHierarchyService: _FakeGeoHierarchyService(),
      );

      final result = await adapter.ingestPlanningInput(
        ownerUserId: 'host-1',
        input: RawEventPlanningInput(
          sourceKind: EventPlanningSourceKind.human,
          purposeText: 'spring music celebration for neighbors',
          vibeText: 'joyful outdoor community rhythm',
          targetAudienceText: 'families creatives neighbors',
          candidateLocalityLabel: 'Avondale',
          preferredStartDate: DateTime.utc(2026, 3, 21, 17),
          preferredEndDate: DateTime.utc(2026, 3, 21, 21),
          sizeIntent: EventSizeIntent.large,
          priceIntent: EventPriceIntent.lowCost,
          hostGoal: EventHostGoal.celebration,
        ),
      );

      expect(airGap.payloads, hasLength(1));
      expect(
        airGap.payloads.single.rawContent,
        contains('spring music celebration for neighbors'),
      );
      expect(
          result.docket.intentTags, containsAll(<String>['spring', 'music']));
      expect(result.docket.vibeTags, contains('joyful'));
      expect(result.docket.audienceTags, contains('families'));
      expect(result.docket.candidateLocalityCode, equals('bham_avondale'));
      expect(result.docket.airGapProvenance.crossingId, startsWith('evtplan_'));
      expect(
        result.docket.toJson().keys,
        isNot(containsAll(<String>[
          'purposeText',
          'vibeText',
          'targetAudienceText',
        ])),
      );
      expect(result.truthScope.truthSurfaceKind, TruthSurfaceKind.planning);
      expect(result.truthScope.governanceStratum, GovernanceStratum.locality);
      expect(result.truthScope.agentClass, TruthAgentClass.organizer);
      expect(result.evidenceEnvelope, isNotNull);
      expect(
        result.evidenceEnvelope?.scope.scopeKey,
        result.truthScope.scopeKey,
      );
      expect(result.compressedArtifactEnvelope, isNotNull);
      expect(result.compressedKnowledgePacket, isNotNull);
      expect(result.compressionBudgetProfile, isNotNull);
      expect(
        result.compressedKnowledgePacket?.environmentId,
        contains('event_planning'),
      );
      expect(
        result.evidenceEnvelope?.evidenceClass,
        equals('planning_air_gap_result'),
      );

      expect(whatIngestion.pluginObservations, hasLength(1));
      final observation = whatIngestion.pluginObservations.single;
      expect(
        observation.structuredSignals,
        containsPair('hostGoal', EventHostGoal.celebration.name),
      );
      expect(
        observation.structuredSignals,
        contains('airGapCrossingId'),
      );
      expect(
        observation.structuredSignals.toString(),
        isNot(contains('spring music celebration for neighbors')),
      );
      expect(
        observation.locationContext,
        containsPair('candidateLocalityCode', 'bham_avondale'),
      );
      expect(
        observation.structuredSignals,
        containsPair('planningScopeKey', result.truthScope.scopeKey),
      );
      expect(
        observation.structuredSignals,
        contains('airGapCompression'),
      );
    });
  });
}
