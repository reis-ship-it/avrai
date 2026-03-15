import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';

class MockAirGap implements AirGapContract {
  final List<RawDataPayload> receivedPayloads = [];

  @override
  Future<List<SemanticTuple>> scrubAndExtract(RawDataPayload payload) async {
    receivedPayloads.add(payload);

    // Simulate what the TupleExtractionEngine does: return an abstract tuple
    return [
      SemanticTuple(
        id: 'test-uuid',
        category: 'routine',
        subject: 'user_self',
        predicate: 'dwelled_at',
        object: 'location_category_cafe',
        confidence: 0.85,
        extractedAt: DateTime.now(),
      )
    ];
  }
}

class FakeWhatRuntimeIngestionService implements WhatRuntimeIngestionService {
  String? resolvedAgentId = 'agent-passive-1';
  Map<String, dynamic>? structuredSignals;
  String? socialContext;
  Map<String, dynamic>? locationContext;
  List<SemanticTuple>? semanticTuples;
  Map<String, dynamic>? ambientStructuredSignals;

  @override
  Future<String?> currentAgentId() async => resolvedAgentId;

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
  }) async {
    return null;
  }

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
  }) async {
    return null;
  }

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
  }) async {
    this.structuredSignals = structuredSignals;
    this.socialContext = socialContext;
    this.locationContext = locationContext;
    this.semanticTuples = semanticTuples;
    return null;
  }

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
    double confidence = 0.58,
    String? lineageRef,
  }) async {
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
  }) async {
    ambientStructuredSignals = structuredSignals;
    return null;
  }

  @override
  Future<WhatUpdateReceipt?> ingestSemanticTuples({
    required String source,
    required String entityRef,
    required List<SemanticTuple> tuples,
    String? agentId,
    Map<String, dynamic>? locationContext,
    Map<String, dynamic>? temporalContext,
    String? lineageRef,
  }) async {
    return null;
  }

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
  }) async {
    return null;
  }
}

void main() {
  group('DwellEventIntakeAdapter', () {
    late MockAirGap mockAirGap;
    late DwellEventIntakeAdapter adapter;

    setUp(() {
      mockAirGap = MockAirGap();
      adapter = DwellEventIntakeAdapter(mockAirGap);
    });

    test('should serialize raw DwellEvent and throw it over the Air Gap',
        () async {
      final now = DateTime.now();

      // The raw physical event containing GPS coordinates (which must be destroyed)
      final event = DwellEvent(
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now,
        latitude: 40.7128,
        longitude: -74.0060,
        encounteredAgentIds: ['knot_abc', 'knot_xyz'],
      );

      // Act
      await adapter.ingestDwellEvent(event);

      // Assert
      expect(mockAirGap.receivedPayloads.length, equals(1));

      final payload = mockAirGap.receivedPayloads.first;
      expect(payload.sourceId, equals('passive_dwell_sensor'));

      // Ensure the raw data made it into the string payload for the LLM to parse
      expect(payload.rawContent, contains('40.7128'));
      expect(payload.rawContent, contains('-74.006'));
      expect(payload.rawContent, contains('120 minutes')); // 2 hours duration
      expect(payload.rawContent, contains('knot_abc'));
    });

    test(
        'keeps passive dwell ingestion separate from ambient-social kernel ingestion',
        () async {
      final whatIngestion = FakeWhatRuntimeIngestionService();
      adapter = DwellEventIntakeAdapter(
        mockAirGap,
        whatIngestion: whatIngestion,
      );
      final now = DateTime.now().toUtc();
      final event = DwellEvent(
        startTime: now.subtract(const Duration(minutes: 70)),
        endTime: now,
        latitude: 40.7128,
        longitude: -74.0060,
        encounteredAgentIds: const <String>['peer_1', 'peer_2', 'peer_3'],
      );

      final tuples = await adapter.ingestDwellEvent(event);

      expect(whatIngestion.socialContext, isNull);
      expect(whatIngestion.structuredSignals?['encounteredAgentCount'], 3);
      expect(whatIngestion.structuredSignals?['dwellDurationMinutes'], 70);
      expect(
        whatIngestion.locationContext?['localityStableKey'],
        startsWith('gh7:'),
      );
      expect(
        tuples.any((entry) => entry.predicate == 'expresses_place_vibe'),
        isFalse,
      );
      expect(whatIngestion.semanticTuples?.length, tuples.length);
      expect(whatIngestion.ambientStructuredSignals, isNull);
    });

    test('should ingest batches of DwellEvents from the queue', () async {
      final now = DateTime.now();

      final events = [
        DwellEvent(startTime: now, endTime: now, latitude: 1.0, longitude: 1.0),
        DwellEvent(startTime: now, endTime: now, latitude: 2.0, longitude: 2.0),
        DwellEvent(startTime: now, endTime: now, latitude: 3.0, longitude: 3.0),
      ];

      // Act
      await adapter.ingestBatch(events);

      // Assert
      expect(mockAirGap.receivedPayloads.length, equals(3));
    });
  });
}
