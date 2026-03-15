import 'dart:async';

enum TemporalLineageStage {
  encoded,
  decoded,
  buffered,
  ordered,
}

class TemporalLineageEvent {
  const TemporalLineageEvent({
    required this.eventId,
    required this.stage,
    required this.occurredAt,
    required this.source,
    required this.eventType,
    this.peerId,
    this.sequenceNumber,
    this.metadata = const <String, dynamic>{},
  });

  final String eventId;
  final TemporalLineageStage stage;
  final DateTime occurredAt;
  final String source;
  final String eventType;
  final String? peerId;
  final int? sequenceNumber;
  final Map<String, dynamic> metadata;
}

abstract class TemporalLineageSink {
  Future<void> record(TemporalLineageEvent event);
}

class NullTemporalLineageSink implements TemporalLineageSink {
  @override
  Future<void> record(TemporalLineageEvent event) async {}
}
