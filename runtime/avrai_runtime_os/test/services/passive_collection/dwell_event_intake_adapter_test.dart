import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
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

void main() {
  group('DwellEventIntakeAdapter', () {
    late MockAirGap mockAirGap;
    late DwellEventIntakeAdapter adapter;

    setUp(() {
      mockAirGap = MockAirGap();
      adapter = DwellEventIntakeAdapter(mockAirGap);
    });

    test('should serialize raw DwellEvent and throw it over the Air Gap', () async {
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
