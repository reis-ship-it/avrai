class ForecastStrengthDiagnostics {
  const ForecastStrengthDiagnostics({
    required this.forecastStrength,
    required this.actionability,
    required this.supportQuality,
    required this.decisionMargin,
    required this.calibrationGap,
    required this.disagreement,
    required this.changePointProbability,
    required this.skillLowerConfidenceBound,
    required this.effectiveSampleSize,
    this.metadata = const <String, dynamic>{},
  });

  final double forecastStrength;
  final double actionability;
  final double supportQuality;
  final double decisionMargin;
  final double calibrationGap;
  final double disagreement;
  final double changePointProbability;
  final double skillLowerConfidenceBound;
  final double effectiveSampleSize;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'forecastStrength': forecastStrength,
      'actionability': actionability,
      'supportQuality': supportQuality,
      'decisionMargin': decisionMargin,
      'calibrationGap': calibrationGap,
      'disagreement': disagreement,
      'changePointProbability': changePointProbability,
      'skillLowerConfidenceBound': skillLowerConfidenceBound,
      'effectiveSampleSize': effectiveSampleSize,
      'metadata': metadata,
    };
  }

  factory ForecastStrengthDiagnostics.fromJson(Map<String, dynamic> json) {
    return ForecastStrengthDiagnostics(
      forecastStrength: (json['forecastStrength'] as num?)?.toDouble() ?? 0.0,
      actionability: (json['actionability'] as num?)?.toDouble() ?? 0.0,
      supportQuality: (json['supportQuality'] as num?)?.toDouble() ?? 0.0,
      decisionMargin: (json['decisionMargin'] as num?)?.toDouble() ?? 0.0,
      calibrationGap: (json['calibrationGap'] as num?)?.toDouble() ?? 0.0,
      disagreement: (json['disagreement'] as num?)?.toDouble() ?? 0.0,
      changePointProbability:
          (json['changePointProbability'] as num?)?.toDouble() ?? 0.0,
      skillLowerConfidenceBound:
          (json['skillLowerConfidenceBound'] as num?)?.toDouble() ?? 0.0,
      effectiveSampleSize:
          (json['effectiveSampleSize'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
