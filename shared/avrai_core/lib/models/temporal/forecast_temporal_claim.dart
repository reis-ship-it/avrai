import 'package:avrai_core/models/temporal/temporal_interval.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';
import 'package:avrai_core/models/temporal/forecast_outcome_kind.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class ForecastTemporalClaim {
  const ForecastTemporalClaim({
    required this.claimId,
    required this.forecastCreatedAt,
    required this.targetWindow,
    required this.evidenceWindow,
    required this.confidence,
    required this.modelVersion,
    required this.provenance,
    this.outcomeProbability,
    this.predictedOutcome,
    this.outcomeKind = ForecastOutcomeKind.binary,
    this.forecastFamilyId,
    this.laterOutcomeRef,
    this.truthScope,
  });

  final String claimId;
  final DateTime forecastCreatedAt;
  final TemporalInterval targetWindow;
  final TemporalInterval evidenceWindow;
  final double confidence;
  final String modelVersion;
  final TemporalProvenance provenance;
  final double? outcomeProbability;
  final String? predictedOutcome;
  final ForecastOutcomeKind outcomeKind;
  final String? forecastFamilyId;
  final String? laterOutcomeRef;
  final TruthScopeDescriptor? truthScope;

  Map<String, dynamic> toJson() {
    return {
      'claimId': claimId,
      'forecastCreatedAt': forecastCreatedAt.toUtc().toIso8601String(),
      'targetWindow': targetWindow.toJson(),
      'evidenceWindow': evidenceWindow.toJson(),
      'confidence': confidence,
      'modelVersion': modelVersion,
      'provenance': provenance.toJson(),
      'outcomeProbability': outcomeProbability,
      'predictedOutcome': predictedOutcome,
      'outcomeKind': outcomeKind.name,
      'forecastFamilyId': forecastFamilyId,
      'laterOutcomeRef': laterOutcomeRef,
      'truthScope': truthScope?.toJson(),
    };
  }

  factory ForecastTemporalClaim.fromJson(Map<String, dynamic> json) {
    return ForecastTemporalClaim(
      claimId: json['claimId'] as String? ?? '',
      forecastCreatedAt: DateTime.parse(
        json['forecastCreatedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                .toIso8601String(),
      ),
      targetWindow: TemporalInterval.fromJson(
        Map<String, dynamic>.from(json['targetWindow'] as Map? ?? const {}),
      ),
      evidenceWindow: TemporalInterval.fromJson(
        Map<String, dynamic>.from(json['evidenceWindow'] as Map? ?? const {}),
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      modelVersion: json['modelVersion'] as String? ?? 'unknown',
      provenance: TemporalProvenance.fromJson(
        Map<String, dynamic>.from(json['provenance'] as Map? ?? const {}),
      ),
      outcomeProbability: (json['outcomeProbability'] as num?)?.toDouble(),
      predictedOutcome: json['predictedOutcome'] as String?,
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == json['outcomeKind'],
        orElse: () => ForecastOutcomeKind.binary,
      ),
      forecastFamilyId: json['forecastFamilyId'] as String?,
      laterOutcomeRef: json['laterOutcomeRef'] as String?,
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
    );
  }
}
