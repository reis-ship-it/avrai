import 'package:avrai_core/models/temporal/replay_temporal_envelope.dart';

class ReplaySourceRecord {
  const ReplaySourceRecord({
    required this.recordId,
    required this.sourceName,
    required this.replayYear,
    required this.rawEntityId,
    required this.rawEntityType,
    required this.replayEnvelope,
    this.canonicalEntityHint,
    this.localityHint,
    this.payload = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  final String recordId;
  final String sourceName;
  final int replayYear;
  final String rawEntityId;
  final String rawEntityType;
  final ReplayTemporalEnvelope replayEnvelope;
  final String? canonicalEntityHint;
  final String? localityHint;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'recordId': recordId,
      'sourceName': sourceName,
      'replayYear': replayYear,
      'rawEntityId': rawEntityId,
      'rawEntityType': rawEntityType,
      'replayEnvelope': replayEnvelope.toJson(),
      'canonicalEntityHint': canonicalEntityHint,
      'localityHint': localityHint,
      'payload': payload,
      'metadata': metadata,
    };
  }

  factory ReplaySourceRecord.fromJson(Map<String, dynamic> json) {
    return ReplaySourceRecord(
      recordId: json['recordId'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      rawEntityId: json['rawEntityId'] as String? ?? '',
      rawEntityType: json['rawEntityType'] as String? ?? 'unknown',
      replayEnvelope: ReplayTemporalEnvelope.fromJson(
        Map<String, dynamic>.from(json['replayEnvelope'] as Map? ?? const {}),
      ),
      canonicalEntityHint: json['canonicalEntityHint'] as String?,
      localityHint: json['localityHint'] as String?,
      payload: Map<String, dynamic>.from(
        json['payload'] as Map<String, dynamic>? ?? const {},
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
