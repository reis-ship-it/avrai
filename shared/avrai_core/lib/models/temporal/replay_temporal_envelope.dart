import 'package:avrai_core/models/temporal/semantic_time_band.dart';
import 'package:avrai_core/models/temporal/temporal_instant.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';
import 'package:avrai_core/models/temporal/temporal_uncertainty.dart';

class ReplayTemporalEnvelope {
  const ReplayTemporalEnvelope({
    required this.envelopeId,
    required this.subjectId,
    required this.observedAt,
    required this.provenance,
    required this.uncertainty,
    required this.temporalAuthoritySource,
    this.publishedAt,
    this.validFrom,
    this.validTo,
    this.eventStartAt,
    this.eventEndAt,
    this.lastVerifiedAt,
    this.semanticBand,
    this.branchId,
    this.runId,
    this.metadata = const <String, dynamic>{},
  });

  final String envelopeId;
  final String subjectId;
  final TemporalInstant observedAt;
  final TemporalInstant? publishedAt;
  final TemporalInstant? validFrom;
  final TemporalInstant? validTo;
  final TemporalInstant? eventStartAt;
  final TemporalInstant? eventEndAt;
  final TemporalInstant? lastVerifiedAt;
  final SemanticTimeBand? semanticBand;
  final TemporalProvenance provenance;
  final TemporalUncertainty uncertainty;
  final String temporalAuthoritySource;
  final String? branchId;
  final String? runId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'envelopeId': envelopeId,
      'subjectId': subjectId,
      'observedAt': observedAt.toJson(),
      'publishedAt': publishedAt?.toJson(),
      'validFrom': validFrom?.toJson(),
      'validTo': validTo?.toJson(),
      'eventStartAt': eventStartAt?.toJson(),
      'eventEndAt': eventEndAt?.toJson(),
      'lastVerifiedAt': lastVerifiedAt?.toJson(),
      'semanticBand': semanticBand?.name,
      'provenance': provenance.toJson(),
      'uncertainty': uncertainty.toJson(),
      'temporalAuthoritySource': temporalAuthoritySource,
      'branchId': branchId,
      'runId': runId,
      'metadata': metadata,
    };
  }

  factory ReplayTemporalEnvelope.fromJson(Map<String, dynamic> json) {
    return ReplayTemporalEnvelope(
      envelopeId: json['envelopeId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      observedAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['observedAt'] as Map? ?? const {}),
      ),
      publishedAt: _readInstant(json['publishedAt']),
      validFrom: _readInstant(json['validFrom']),
      validTo: _readInstant(json['validTo']),
      eventStartAt: _readInstant(json['eventStartAt']),
      eventEndAt: _readInstant(json['eventEndAt']),
      lastVerifiedAt: _readInstant(json['lastVerifiedAt']),
      semanticBand: SemanticTimeBand.values.firstWhere(
        (value) => value.name == json['semanticBand'],
        orElse: () => SemanticTimeBand.unknown,
      ),
      provenance: TemporalProvenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      ),
      uncertainty: TemporalUncertainty.fromJson(
        Map<String, dynamic>.from(json['uncertainty'] as Map? ?? const {}),
      ),
      temporalAuthoritySource:
          json['temporalAuthoritySource'] as String? ?? 'unknown',
      branchId: json['branchId'] as String?,
      runId: json['runId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  static TemporalInstant? _readInstant(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return TemporalInstant.fromJson(raw);
    }
    if (raw is Map) {
      return TemporalInstant.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}
