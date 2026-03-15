import 'package:avrai_core/models/temporal/temporal_interval.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';

enum HistoricalTemporalGranularity {
  year,
  month,
  day,
  hour,
  exact,
  unknownExact,
}

class HistoricalTemporalEvidence {
  const HistoricalTemporalEvidence({
    required this.evidenceId,
    required this.interval,
    required this.granularity,
    required this.confidence,
    required this.provenance,
    required this.reconstructionMethod,
    this.sourceArtifactRefs = const <String>[],
  });

  final String evidenceId;
  final TemporalInterval interval;
  final HistoricalTemporalGranularity granularity;
  final double confidence;
  final TemporalProvenance provenance;
  final String reconstructionMethod;
  final List<String> sourceArtifactRefs;

  Map<String, dynamic> toJson() {
    return {
      'evidenceId': evidenceId,
      'interval': interval.toJson(),
      'granularity': granularity.name,
      'confidence': confidence,
      'provenance': provenance.toJson(),
      'reconstructionMethod': reconstructionMethod,
      'sourceArtifactRefs': sourceArtifactRefs,
    };
  }

  factory HistoricalTemporalEvidence.fromJson(Map<String, dynamic> json) {
    return HistoricalTemporalEvidence(
      evidenceId: json['evidenceId'] as String? ?? '',
      interval: TemporalInterval.fromJson(
        Map<String, dynamic>.from(json['interval'] as Map? ?? const {}),
      ),
      granularity: HistoricalTemporalGranularity.values.firstWhere(
        (value) => value.name == json['granularity'],
        orElse: () => HistoricalTemporalGranularity.unknownExact,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      provenance: TemporalProvenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      ),
      reconstructionMethod:
          json['reconstructionMethod'] as String? ?? 'unknown',
      sourceArtifactRefs: (json['sourceArtifactRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
    );
  }
}
