import 'package:avrai_core/models/temporal/forecast_outcome_kind.dart';

class ForecastCalibrationSnapshot {
  const ForecastCalibrationSnapshot({
    required this.bucketKey,
    required this.outcomeKind,
    required this.sampleCount,
    required this.effectiveSampleSize,
    required this.warmingUp,
    required this.primaryScoreMean,
    required this.baselinePrimaryScoreMean,
    required this.skillMean,
    required this.skillLowerConfidenceBound,
    required this.calibrationGap,
    required this.expectedCalibrationError,
    required this.classwiseExpectedCalibrationError,
    required this.coverageGap,
    required this.pitKolmogorovSmirnov,
    required this.updatedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String bucketKey;
  final ForecastOutcomeKind outcomeKind;
  final int sampleCount;
  final double effectiveSampleSize;
  final bool warmingUp;
  final double primaryScoreMean;
  final double baselinePrimaryScoreMean;
  final double skillMean;
  final double skillLowerConfidenceBound;
  final double calibrationGap;
  final double expectedCalibrationError;
  final double classwiseExpectedCalibrationError;
  final double coverageGap;
  final double pitKolmogorovSmirnov;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bucketKey': bucketKey,
      'outcomeKind': outcomeKind.name,
      'sampleCount': sampleCount,
      'effectiveSampleSize': effectiveSampleSize,
      'warmingUp': warmingUp,
      'primaryScoreMean': primaryScoreMean,
      'baselinePrimaryScoreMean': baselinePrimaryScoreMean,
      'skillMean': skillMean,
      'skillLowerConfidenceBound': skillLowerConfidenceBound,
      'calibrationGap': calibrationGap,
      'expectedCalibrationError': expectedCalibrationError,
      'classwiseExpectedCalibrationError': classwiseExpectedCalibrationError,
      'coverageGap': coverageGap,
      'pitKolmogorovSmirnov': pitKolmogorovSmirnov,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ForecastCalibrationSnapshot.fromJson(Map<String, dynamic> json) {
    return ForecastCalibrationSnapshot(
      bucketKey: json['bucketKey'] as String? ?? '',
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == json['outcomeKind'],
        orElse: () => ForecastOutcomeKind.binary,
      ),
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      effectiveSampleSize:
          (json['effectiveSampleSize'] as num?)?.toDouble() ?? 0.0,
      warmingUp: json['warmingUp'] as bool? ?? true,
      primaryScoreMean: (json['primaryScoreMean'] as num?)?.toDouble() ?? 0.0,
      baselinePrimaryScoreMean:
          (json['baselinePrimaryScoreMean'] as num?)?.toDouble() ?? 0.0,
      skillMean: (json['skillMean'] as num?)?.toDouble() ?? 0.0,
      skillLowerConfidenceBound:
          (json['skillLowerConfidenceBound'] as num?)?.toDouble() ?? 0.0,
      calibrationGap: (json['calibrationGap'] as num?)?.toDouble() ?? 0.0,
      expectedCalibrationError:
          (json['expectedCalibrationError'] as num?)?.toDouble() ?? 0.0,
      classwiseExpectedCalibrationError:
          (json['classwiseExpectedCalibrationError'] as num?)?.toDouble() ??
              0.0,
      coverageGap: (json['coverageGap'] as num?)?.toDouble() ?? 0.0,
      pitKolmogorovSmirnov:
          (json['pitKolmogorovSmirnov'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                .toIso8601String(),
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
