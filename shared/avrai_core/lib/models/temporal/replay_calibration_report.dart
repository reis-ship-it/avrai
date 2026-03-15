class ReplayCalibrationRecord {
  const ReplayCalibrationRecord({
    required this.metricId,
    required this.targetValue,
    required this.actualValue,
    required this.allowedVariancePct,
    required this.passed,
    required this.rationale,
    this.metadata = const <String, dynamic>{},
  });

  final String metricId;
  final double targetValue;
  final double actualValue;
  final double allowedVariancePct;
  final bool passed;
  final String rationale;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'metricId': metricId,
      'targetValue': targetValue,
      'actualValue': actualValue,
      'allowedVariancePct': allowedVariancePct,
      'passed': passed,
      'rationale': rationale,
      'metadata': metadata,
    };
  }

  factory ReplayCalibrationRecord.fromJson(Map<String, dynamic> json) {
    return ReplayCalibrationRecord(
      metricId: json['metricId'] as String? ?? '',
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0.0,
      actualValue: (json['actualValue'] as num?)?.toDouble() ?? 0.0,
      allowedVariancePct: (json['allowedVariancePct'] as num?)?.toDouble() ?? 0.0,
      passed: json['passed'] as bool? ?? false,
      rationale: json['rationale'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayCalibrationReport {
  const ReplayCalibrationReport({
    required this.reportId,
    required this.replayYear,
    required this.passed,
    required this.records,
    this.unresolvedMetrics = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String reportId;
  final int replayYear;
  final bool passed;
  final List<ReplayCalibrationRecord> records;
  final List<String> unresolvedMetrics;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reportId': reportId,
      'replayYear': replayYear,
      'passed': passed,
      'records': records.map((entry) => entry.toJson()).toList(),
      'unresolvedMetrics': unresolvedMetrics,
      'metadata': metadata,
    };
  }

  factory ReplayCalibrationReport.fromJson(Map<String, dynamic> json) {
    return ReplayCalibrationReport(
      reportId: json['reportId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayCalibrationRecord.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList(growable: false) ??
          const <ReplayCalibrationRecord>[],
      unresolvedMetrics: (json['unresolvedMetrics'] as List?)
              ?.map((entry) => entry.toString())
              .toList(growable: false) ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
