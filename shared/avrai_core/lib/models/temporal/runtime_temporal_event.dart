import 'package:avrai_core/models/temporal/temporal_provenance.dart';

enum RuntimeTemporalEventStage {
  encoded,
  decoded,
  buffered,
  ordered,
}

class RuntimeTemporalEvent {
  const RuntimeTemporalEvent({
    required this.eventId,
    required this.occurredAt,
    required this.source,
    required this.eventType,
    required this.stage,
    this.peerId,
    this.sequenceNumber,
    this.metadata = const <String, dynamic>{},
    this.provenance = const TemporalProvenance(
      authority: TemporalAuthority.inferred,
      source: 'runtime_event',
    ),
  });

  final String eventId;
  final DateTime occurredAt;
  final String source;
  final String eventType;
  final RuntimeTemporalEventStage stage;
  final String? peerId;
  final int? sequenceNumber;
  final Map<String, dynamic> metadata;
  final TemporalProvenance provenance;

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'source': source,
      'eventType': eventType,
      'stage': stage.name,
      'peerId': peerId,
      'sequenceNumber': sequenceNumber,
      'metadata': metadata,
      'provenance': provenance.toJson(),
    };
  }

  factory RuntimeTemporalEvent.fromJson(Map<String, dynamic> json) {
    return RuntimeTemporalEvent(
      eventId: json['eventId'] as String? ?? '',
      occurredAt: DateTime.parse(
        json['occurredAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                .toIso8601String(),
      ),
      source: json['source'] as String? ?? 'unknown',
      eventType: json['eventType'] as String? ?? 'unknown',
      stage: RuntimeTemporalEventStage.values.firstWhere(
        (value) => value.name == json['stage'],
        orElse: () => RuntimeTemporalEventStage.ordered,
      ),
      peerId: json['peerId'] as String?,
      sequenceNumber: (json['sequenceNumber'] as num?)?.toInt(),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
      provenance: TemporalProvenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      ),
    );
  }
}
