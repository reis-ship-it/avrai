class ReplayHoldoutMetric {
  const ReplayHoldoutMetric({
    required this.metricId,
    required this.metricName,
    required this.trainingValue,
    required this.validationValue,
    required this.holdoutValue,
    required this.threshold,
    required this.passed,
    this.metadata = const <String, dynamic>{},
  });

  final String metricId;
  final String metricName;
  final double trainingValue;
  final double validationValue;
  final double holdoutValue;
  final double threshold;
  final bool passed;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metricId': metricId,
      'metricName': metricName,
      'trainingValue': trainingValue,
      'validationValue': validationValue,
      'holdoutValue': holdoutValue,
      'threshold': threshold,
      'passed': passed,
      'metadata': metadata,
    };
  }

  factory ReplayHoldoutMetric.fromJson(Map<String, dynamic> json) {
    return ReplayHoldoutMetric(
      metricId: json['metricId'] as String? ?? '',
      metricName: json['metricName'] as String? ?? '',
      trainingValue: (json['trainingValue'] as num?)?.toDouble() ?? 0.0,
      validationValue: (json['validationValue'] as num?)?.toDouble() ?? 0.0,
      holdoutValue: (json['holdoutValue'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayHoldoutEvaluationReport {
  const ReplayHoldoutEvaluationReport({
    required this.environmentId,
    required this.replayYear,
    required this.trainingMonths,
    required this.validationMonths,
    required this.holdoutMonths,
    required this.passed,
    required this.metrics,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final List<String> trainingMonths;
  final List<String> validationMonths;
  final List<String> holdoutMonths;
  final bool passed;
  final List<ReplayHoldoutMetric> metrics;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'trainingMonths': trainingMonths,
      'validationMonths': validationMonths,
      'holdoutMonths': holdoutMonths,
      'passed': passed,
      'metrics': metrics.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayHoldoutEvaluationReport.fromJson(Map<String, dynamic> json) {
    return ReplayHoldoutEvaluationReport(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      trainingMonths: (json['trainingMonths'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      validationMonths: (json['validationMonths'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      holdoutMonths: (json['holdoutMonths'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      passed: json['passed'] as bool? ?? false,
      metrics: (json['metrics'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayHoldoutMetric.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayHoldoutMetric>[],
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
