/// Host-neutral envelopes for Reality Engine state/event/action/outcome exchange.
///
/// This keeps engine internals decoupled from product-specific semantics.
class EngineSchemaContract {
  static const String schemaVersion = '1.0.0';

  static void assertValidPayload(Map<String, dynamic> payload) {
    if (payload.keys.any((k) => k.trim().isEmpty)) {
      throw ArgumentError('Envelope payload contains an empty key.');
    }
  }
}

class EngineStateEnvelope {
  final String schemaVersion;
  final String agentId;
  final DateTime observedAt;
  final Map<String, dynamic> state;

  EngineStateEnvelope({
    required this.agentId,
    required this.observedAt,
    required this.state,
    this.schemaVersion = EngineSchemaContract.schemaVersion,
  }) {
    EngineSchemaContract.assertValidPayload(state);
  }
}

class EngineEventEnvelope {
  final String schemaVersion;
  final String agentId;
  final String eventType;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;

  EngineEventEnvelope({
    required this.agentId,
    required this.eventType,
    required this.occurredAt,
    required this.payload,
    this.schemaVersion = EngineSchemaContract.schemaVersion,
  }) {
    EngineSchemaContract.assertValidPayload(payload);
  }
}

class EngineActionEnvelope {
  final String schemaVersion;
  final String agentId;
  final String actionType;
  final DateTime plannedAt;
  final Map<String, dynamic> payload;

  EngineActionEnvelope({
    required this.agentId,
    required this.actionType,
    required this.plannedAt,
    required this.payload,
    this.schemaVersion = EngineSchemaContract.schemaVersion,
  }) {
    EngineSchemaContract.assertValidPayload(payload);
  }
}

class EngineOutcomeEnvelope {
  final String schemaVersion;
  final String agentId;
  final String outcomeType;
  final DateTime recordedAt;
  final double? reward;
  final Map<String, dynamic> payload;

  EngineOutcomeEnvelope({
    required this.agentId,
    required this.outcomeType,
    required this.recordedAt,
    required this.payload,
    this.reward,
    this.schemaVersion = EngineSchemaContract.schemaVersion,
  }) {
    EngineSchemaContract.assertValidPayload(payload);
  }
}
