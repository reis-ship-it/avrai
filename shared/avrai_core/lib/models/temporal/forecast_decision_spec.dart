enum ForecastThresholdMode {
  above,
  below,
  inside,
  outside,
}

class ForecastDecisionSpec {
  const ForecastDecisionSpec({
    this.threshold,
    this.thresholdMode,
    this.preferredOutcomes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final double? threshold;
  final ForecastThresholdMode? thresholdMode;
  final List<String> preferredOutcomes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'threshold': threshold,
      'thresholdMode': thresholdMode?.name,
      'preferredOutcomes': preferredOutcomes,
      'metadata': metadata,
    };
  }

  factory ForecastDecisionSpec.fromJson(Map<String, dynamic> json) {
    return ForecastDecisionSpec(
      threshold: (json['threshold'] as num?)?.toDouble(),
      thresholdMode: ForecastThresholdMode.values.firstWhere(
        (value) => value.name == json['thresholdMode'],
        orElse: () => ForecastThresholdMode.above,
      ),
      preferredOutcomes: (json['preferredOutcomes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
