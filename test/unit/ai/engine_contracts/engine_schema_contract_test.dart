import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/engine_contracts/engine_schema_contract.dart';

void main() {
  group('EngineSchemaContract', () {
    test('constructs host-neutral envelopes with schema version', () {
      final event = EngineEventEnvelope(
        agentId: 'agent_1',
        eventType: 'spot_viewed',
        occurredAt: DateTime.utc(2026, 2, 26),
        payload: const {'spot_id': 's_1'},
      );

      final outcome = EngineOutcomeEnvelope(
        agentId: 'agent_1',
        outcomeType: 'save_spot',
        recordedAt: DateTime.utc(2026, 2, 26),
        payload: const {'spot_id': 's_1'},
        reward: 0.75,
      );

      expect(event.schemaVersion, EngineSchemaContract.schemaVersion);
      expect(outcome.schemaVersion, EngineSchemaContract.schemaVersion);
    });

    test('rejects payloads with empty keys', () {
      expect(
        () => EngineActionEnvelope(
          agentId: 'agent_1',
          actionType: 'recommend',
          plannedAt: DateTime.utc(2026, 2, 26),
          payload: const {'': 'bad'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
