import 'dart:convert';
import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/prediction/forecast_math_support.dart';

class ForecastSkillBucketKey {
  const ForecastSkillBucketKey({
    required this.scope,
    required this.outcomeKind,
    required this.horizonBand,
  });

  final TruthScopeDescriptor scope;
  final ForecastOutcomeKind outcomeKind;
  final String horizonBand;

  String get value => '${scope.scopeKey}|${outcomeKind.name}|$horizonBand';
}

class ForecastIssuedForecastRecord {
  ForecastIssuedForecastRecord({
    required this.forecastId,
    required this.bucketKey,
    required this.subjectId,
    required this.forecastFamilyId,
    required this.outcomeKind,
    required this.issuedAt,
    required this.predictedOutcome,
    required this.rawPredictiveDistribution,
    required this.calibratedPredictiveDistribution,
    required this.forecastStrength,
    required this.actionability,
    required this.supportQuality,
    required this.diagnostics,
    this.truthScope = const TruthScopeDescriptor.defaultForecast(),
    String? sphereId,
    this.metadata = const <String, dynamic>{},
  }) : sphereId = sphereId ?? truthScope.sphereId;

  final String forecastId;
  final String bucketKey;
  final String subjectId;
  final String forecastFamilyId;
  final ForecastOutcomeKind outcomeKind;
  final DateTime issuedAt;
  final String predictedOutcome;
  final ForecastPredictiveDistribution rawPredictiveDistribution;
  final ForecastPredictiveDistribution calibratedPredictiveDistribution;
  final double forecastStrength;
  final double actionability;
  final double supportQuality;
  final ForecastStrengthDiagnostics diagnostics;
  final TruthScopeDescriptor truthScope;
  final String sphereId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'forecastId': forecastId,
      'bucketKey': bucketKey,
      'subjectId': subjectId,
      'forecastFamilyId': forecastFamilyId,
      'outcomeKind': outcomeKind.name,
      'issuedAt': issuedAt.toUtc().toIso8601String(),
      'predictedOutcome': predictedOutcome,
      'rawPredictiveDistribution': rawPredictiveDistribution.toJson(),
      'calibratedPredictiveDistribution':
          calibratedPredictiveDistribution.toJson(),
      'forecastStrength': forecastStrength,
      'actionability': actionability,
      'supportQuality': supportQuality,
      'diagnostics': diagnostics.toJson(),
      'truthScope': truthScope.toJson(),
      'sphereId': sphereId,
      'metadata': metadata,
    };
  }

  factory ForecastIssuedForecastRecord.fromJson(Map<String, dynamic> json) {
    return ForecastIssuedForecastRecord(
      forecastId: json['forecastId'] as String? ?? '',
      bucketKey: json['bucketKey'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      forecastFamilyId: json['forecastFamilyId'] as String? ?? '',
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == json['outcomeKind'],
        orElse: () => ForecastOutcomeKind.binary,
      ),
      issuedAt: DateTime.parse(
        json['issuedAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
                .toIso8601String(),
      ),
      predictedOutcome: json['predictedOutcome'] as String? ?? '',
      rawPredictiveDistribution: ForecastPredictiveDistribution.fromJson(
        Map<String, dynamic>.from(
          json['rawPredictiveDistribution'] as Map? ?? const {},
        ),
      ),
      calibratedPredictiveDistribution: ForecastPredictiveDistribution.fromJson(
        Map<String, dynamic>.from(
          json['calibratedPredictiveDistribution'] as Map? ?? const {},
        ),
      ),
      forecastStrength: (json['forecastStrength'] as num?)?.toDouble() ?? 0.0,
      actionability: (json['actionability'] as num?)?.toDouble() ?? 0.0,
      supportQuality: (json['supportQuality'] as num?)?.toDouble() ?? 0.0,
      diagnostics: ForecastStrengthDiagnostics.fromJson(
        Map<String, dynamic>.from(json['diagnostics'] as Map? ?? const {}),
      ),
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : const TruthScopeDescriptor.defaultForecast(),
      sphereId: json['sphereId'] as String? ?? 'forecast',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ForecastResolvedForecastRecord {
  const ForecastResolvedForecastRecord({
    required this.resolution,
    required this.issuedRecord,
    required this.primaryScore,
    required this.baselinePrimaryScore,
    required this.secondaryScore,
    required this.pitValue,
    required this.coverageByInterval,
  });

  final ForecastResolutionRecord resolution;
  final ForecastIssuedForecastRecord issuedRecord;
  final double primaryScore;
  final double baselinePrimaryScore;
  final double secondaryScore;
  final double pitValue;
  final Map<String, bool> coverageByInterval;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'resolution': resolution.toJson(),
      'issuedRecord': issuedRecord.toJson(),
      'primaryScore': primaryScore,
      'baselinePrimaryScore': baselinePrimaryScore,
      'secondaryScore': secondaryScore,
      'pitValue': pitValue,
      'coverageByInterval': coverageByInterval,
    };
  }

  factory ForecastResolvedForecastRecord.fromJson(Map<String, dynamic> json) {
    return ForecastResolvedForecastRecord(
      resolution: ForecastResolutionRecord.fromJson(
        Map<String, dynamic>.from(json['resolution'] as Map? ?? const {}),
      ),
      issuedRecord: ForecastIssuedForecastRecord.fromJson(
        Map<String, dynamic>.from(json['issuedRecord'] as Map? ?? const {}),
      ),
      primaryScore: (json['primaryScore'] as num?)?.toDouble() ?? 0.0,
      baselinePrimaryScore:
          (json['baselinePrimaryScore'] as num?)?.toDouble() ?? 0.0,
      secondaryScore: (json['secondaryScore'] as num?)?.toDouble() ?? 0.0,
      pitValue: (json['pitValue'] as num?)?.toDouble() ?? 0.5,
      coverageByInterval: (json['coverageByInterval'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value == true),
          ) ??
          const <String, bool>{},
    );
  }
}

class ForecastSkillLedger {
  ForecastSkillLedger({
    SharedPreferencesCompat? prefs,
    DateTime Function()? nowProvider,
  })  : _prefs = prefs,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc()) {
    _hydrate();
  }

  static const String _resolutionsKey = 'forecast_skill_resolutions_v2';
  static const int _maxResolvedRecords = 200;
  static const int _maxIssuedRecords = 250;

  final SharedPreferencesCompat? _prefs;
  final DateTime Function() _nowProvider;
  final Map<String, ForecastIssuedForecastRecord> _issuedById =
      <String, ForecastIssuedForecastRecord>{};
  final List<ForecastIssuedForecastRecord> _recentIssued =
      <ForecastIssuedForecastRecord>[];
  final List<ForecastResolvedForecastRecord> _resolved =
      <ForecastResolvedForecastRecord>[];

  void recordIssuedForecast(ForecastIssuedForecastRecord record) {
    _issuedById[record.forecastId] = record;
    _recentIssued.removeWhere((entry) => entry.forecastId == record.forecastId);
    _recentIssued.insert(0, record);
    if (_recentIssued.length > _maxIssuedRecords) {
      _recentIssued.removeRange(_maxIssuedRecords, _recentIssued.length);
    }
  }

  Future<void> recordResolution(ForecastResolutionRecord resolution) async {
    final issued = _issuedById[resolution.forecastId];
    if (issued == null) {
      return;
    }
    final baseline = _baselineDistributionFor(
      bucketKey: issued.bucketKey,
      outcomeKind: issued.outcomeKind,
      excludingForecastId: issued.forecastId,
    );
    final primaryScore = _primaryScore(
      distribution: issued.calibratedPredictiveDistribution,
      resolution: resolution,
    );
    final baselinePrimaryScore = _primaryScore(
      distribution: baseline,
      resolution: resolution,
    );
    final secondaryScore = _secondaryScore(
      distribution: issued.calibratedPredictiveDistribution,
      resolution: resolution,
    );
    final pitValue = _pitValue(
      distribution: issued.calibratedPredictiveDistribution,
      resolution: resolution,
    );
    final coverageByInterval = _coverageByInterval(
      distribution: issued.calibratedPredictiveDistribution,
      resolution: resolution,
    );
    final resolvedRecord = ForecastResolvedForecastRecord(
      resolution: resolution,
      issuedRecord: issued,
      primaryScore: primaryScore,
      baselinePrimaryScore: baselinePrimaryScore,
      secondaryScore: secondaryScore,
      pitValue: pitValue,
      coverageByInterval: coverageByInterval,
    );
    _resolved.removeWhere(
      (entry) => entry.resolution.resolutionId == resolution.resolutionId,
    );
    _resolved.add(resolvedRecord);
    if (_resolved.length > _maxResolvedRecords) {
      _resolved.removeRange(0, _resolved.length - _maxResolvedRecords);
    }
    await _persist();
  }

  List<ForecastIssuedForecastRecord> recentIssuedForecasts({
    String? sphereId,
    String? forecastFamilyId,
    TruthScopeDescriptor? truthScope,
    Duration? lookbackWindow,
    int limit = 100,
  }) {
    final now = _nowProvider();
    final filtered = _recentIssued.where((record) {
      if (truthScope != null &&
          record.truthScope.scopeKey != truthScope.scopeKey) {
        return false;
      }
      if (sphereId != null && record.sphereId != sphereId) {
        return false;
      }
      if (forecastFamilyId != null &&
          record.forecastFamilyId != forecastFamilyId) {
        return false;
      }
      if (lookbackWindow != null &&
          now.difference(record.issuedAt).compareTo(lookbackWindow) > 0) {
        return false;
      }
      return true;
    }).toList(growable: false);
    if (filtered.length <= limit) {
      return filtered;
    }
    return filtered.sublist(0, limit);
  }

  List<ForecastResolvedForecastRecord> resolvedRecordsForBucketKeys(
    Iterable<String> bucketKeys,
  ) {
    final set = bucketKeys.toSet();
    return _resolved
        .where((entry) => set.contains(entry.issuedRecord.bucketKey))
        .toList(growable: false);
  }

  ForecastIssuedForecastRecord? issuedForecastById(String forecastId) {
    return _issuedById[forecastId];
  }

  ForecastPredictiveDistribution climatologyDistributionFor({
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
    String? excludingForecastId,
  }) {
    final set = bucketKeys.toSet();
    final records = _resolved
        .where((entry) => set.contains(entry.issuedRecord.bucketKey))
        .where((entry) => entry.issuedRecord.forecastId != excludingForecastId)
        .toList(growable: false);
    return _distributionFromResolvedRecords(
      records: records,
      outcomeKind: outcomeKind,
    );
  }

  ForecastCalibrationSnapshot calibrationSnapshotFor({
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final records = resolvedRecordsForBucketKeys(bucketKeys);
    if (records.isEmpty) {
      return ForecastCalibrationSnapshot(
        bucketKey: bucketKeys.isEmpty ? '' : bucketKeys.first,
        outcomeKind: outcomeKind,
        sampleCount: 0,
        effectiveSampleSize: 0.0,
        warmingUp: true,
        primaryScoreMean: 0.0,
        baselinePrimaryScoreMean: 0.0,
        skillMean: 0.0,
        skillLowerConfidenceBound: 0.0,
        calibrationGap: 0.35,
        expectedCalibrationError: 0.35,
        classwiseExpectedCalibrationError: 0.35,
        coverageGap: 0.35,
        pitKolmogorovSmirnov: 0.35,
        updatedAt: _nowProvider(),
      );
    }

    final now = _nowProvider();
    final weights = records
        .map((entry) => recencyWeight(
              nowUtc: now,
              observedAtUtc: entry.resolution.resolvedAt.toUtc(),
            ))
        .toList(growable: false);
    final primaryScores = records.map((entry) => entry.primaryScore).toList();
    final baselineScores =
        records.map((entry) => entry.baselinePrimaryScore).toList();
    final improvements = <double>[
      for (var index = 0; index < records.length; index++)
        baselineScores[index] - primaryScores[index],
    ];
    final ess = effectiveSampleSize(weights);
    final primaryMean = weightedMean(primaryScores, weights);
    final baselineMean = weightedMean(baselineScores, weights);
    final skillMean = weightedMean(improvements, weights);
    final improvementVariance = weightedVariance(improvements, weights);
    final skillLcb = skillMean -
        (1.2815515655446004 *
            math.sqrt(improvementVariance / math.max(ess, 1.0)));
    final ece = _expectedCalibrationError(records, outcomeKind);
    final classwiseEce = _classwiseExpectedCalibrationError(records);
    final coverageGap = _coverageGap(records);
    final pitKs = ksDistanceToUniform(
      records.map((entry) => entry.pitValue).toList(growable: false),
    );
    final calibrationGap = outcomeKind == ForecastOutcomeKind.continuous
        ? clamp01(coverageGap + (0.5 * pitKs))
        : math.max(ece, classwiseEce);

    return ForecastCalibrationSnapshot(
      bucketKey: bucketKeys.isEmpty ? '' : bucketKeys.first,
      outcomeKind: outcomeKind,
      sampleCount: records.length,
      effectiveSampleSize: ess,
      warmingUp: records.length < _minimumSamplesFor(outcomeKind),
      primaryScoreMean: primaryMean,
      baselinePrimaryScoreMean: baselineMean,
      skillMean: skillMean,
      skillLowerConfidenceBound: skillLcb,
      calibrationGap: calibrationGap,
      expectedCalibrationError: ece,
      classwiseExpectedCalibrationError: classwiseEce,
      coverageGap: coverageGap,
      pitKolmogorovSmirnov: pitKs,
      updatedAt: now,
    );
  }

  double componentSkillMean({
    required Iterable<String> bucketKeys,
    required String componentId,
  }) {
    final records = resolvedRecordsForBucketKeys(bucketKeys)
        .where(
          (entry) =>
              entry.issuedRecord.rawPredictiveDistribution.componentId ==
              componentId,
        )
        .toList(growable: false);
    if (records.isEmpty) {
      return 0.0;
    }
    final weights = records
        .map((entry) => recencyWeight(
              nowUtc: _nowProvider(),
              observedAtUtc: entry.resolution.resolvedAt.toUtc(),
            ))
        .toList(growable: false);
    final improvements = records
        .map((entry) => entry.baselinePrimaryScore - entry.primaryScore)
        .toList(growable: false);
    return weightedMean(improvements, weights);
  }

  ForecastPredictiveDistribution _baselineDistributionFor({
    required String bucketKey,
    required ForecastOutcomeKind outcomeKind,
    String? excludingForecastId,
  }) {
    final records = _resolved
        .where((entry) => entry.issuedRecord.bucketKey == bucketKey)
        .where((entry) => entry.issuedRecord.forecastId != excludingForecastId)
        .toList(growable: false);
    return _distributionFromResolvedRecords(
      records: records,
      outcomeKind: outcomeKind,
    );
  }

  ForecastPredictiveDistribution _distributionFromResolvedRecords({
    required List<ForecastResolvedForecastRecord> records,
    required ForecastOutcomeKind outcomeKind,
  }) {
    if (records.isEmpty) {
      if (outcomeKind == ForecastOutcomeKind.continuous) {
        return const ForecastPredictiveDistribution(
          outcomeKind: ForecastOutcomeKind.continuous,
          quantiles: <String, double>{
            '0.05': 0.0,
            '0.50': 0.0,
            '0.95': 1.0,
          },
          mean: 0.5,
          variance: 1.0,
        );
      }
      return const ForecastPredictiveDistribution(
        outcomeKind: ForecastOutcomeKind.binary,
        discreteProbabilities: <String, double>{
          'positive': 0.5,
          'negative': 0.5,
        },
        mean: 0.5,
        variance: 0.25,
      );
    }
    if (outcomeKind == ForecastOutcomeKind.continuous) {
      final values = records
          .map((entry) => entry.resolution.actualOutcomeValue)
          .whereType<double>()
          .toList()
        ..sort();
      if (values.isEmpty) {
        return const ForecastPredictiveDistribution(
          outcomeKind: ForecastOutcomeKind.continuous,
          quantiles: <String, double>{
            '0.05': 0.0,
            '0.50': 0.0,
            '0.95': 1.0,
          },
          mean: 0.5,
          variance: 1.0,
        );
      }
      final meanValue =
          values.fold<double>(0.0, (total, value) => total + value) /
              values.length;
      return ForecastPredictiveDistribution(
        outcomeKind: ForecastOutcomeKind.continuous,
        quantiles: <String, double>{
          '0.05': empiricalQuantile(values, 0.05),
          '0.10': empiricalQuantile(values, 0.10),
          '0.25': empiricalQuantile(values, 0.25),
          '0.50': empiricalQuantile(values, 0.50),
          '0.75': empiricalQuantile(values, 0.75),
          '0.90': empiricalQuantile(values, 0.90),
          '0.95': empiricalQuantile(values, 0.95),
        },
        mean: meanValue,
      );
    }
    final counts = <String, double>{};
    for (final record in records) {
      final label = record.resolution.actualOutcomeLabel ?? 'unknown';
      counts[label] = (counts[label] ?? 0.0) + 1.0;
    }
    final total = counts.values.fold<double>(0.0, (sum, value) => sum + value);
    final normalized = counts.map(
      (key, value) => MapEntry(key, total == 0.0 ? 0.0 : value / total),
    );
    return ForecastPredictiveDistribution(
      outcomeKind: outcomeKind,
      discreteProbabilities: normalized,
      mean: normalized.values.isEmpty
          ? 0.0
          : normalized.values.reduce(
              (left, right) => left >= right ? left : right,
            ),
    );
  }

  double _primaryScore({
    required ForecastPredictiveDistribution distribution,
    required ForecastResolutionRecord resolution,
  }) {
    if (resolution.outcomeKind == ForecastOutcomeKind.continuous) {
      return approximateCrps(
        distribution: distribution,
        actual: resolution.actualOutcomeValue ?? 0.0,
      );
    }
    return scoreDiscreteLog(
      distribution: distribution,
      actualLabel: resolution.actualOutcomeLabel ?? 'unknown',
    );
  }

  double _secondaryScore({
    required ForecastPredictiveDistribution distribution,
    required ForecastResolutionRecord resolution,
  }) {
    if (resolution.outcomeKind == ForecastOutcomeKind.continuous) {
      return normalizedIntervalWidth(
        distribution: distribution,
        climatologyWidth: ((distribution.quantiles['0.95'] ?? 1.0) -
                (distribution.quantiles['0.05'] ?? 0.0))
            .abs(),
      );
    }
    return scoreDiscreteBrier(
      distribution: distribution,
      actualLabel: resolution.actualOutcomeLabel ?? 'unknown',
    );
  }

  double _pitValue({
    required ForecastPredictiveDistribution distribution,
    required ForecastResolutionRecord resolution,
  }) {
    if (resolution.outcomeKind == ForecastOutcomeKind.continuous) {
      return cdfAtThreshold(
        distribution: distribution,
        threshold: resolution.actualOutcomeValue ?? 0.0,
      );
    }
    return distribution.discreteProbabilities[
            resolution.actualOutcomeLabel ?? 'unknown'] ??
        0.0;
  }

  Map<String, bool> _coverageByInterval({
    required ForecastPredictiveDistribution distribution,
    required ForecastResolutionRecord resolution,
  }) {
    if (resolution.actualOutcomeValue == null) {
      return const <String, bool>{};
    }
    final actual = resolution.actualOutcomeValue!;
    bool contains(String lowKey, String highKey) {
      final low = distribution.quantiles[lowKey];
      final high = distribution.quantiles[highKey];
      if (low == null || high == null) {
        return false;
      }
      return actual >= low && actual <= high;
    }

    return <String, bool>{
      '50': contains('0.25', '0.75'),
      '80': contains('0.10', '0.90'),
      '90': contains('0.05', '0.95'),
      '95': contains('0.01', '0.99'),
    };
  }

  double _expectedCalibrationError(
    List<ForecastResolvedForecastRecord> records,
    ForecastOutcomeKind outcomeKind,
  ) {
    if (outcomeKind == ForecastOutcomeKind.continuous || records.isEmpty) {
      return 0.0;
    }
    final bins = List.generate(10, (_) => <double>[]);
    final outcomes = List.generate(10, (_) => <double>[]);
    for (final record in records) {
      final probability =
          record.issuedRecord.calibratedPredictiveDistribution.topProbability;
      final bin = math.min(9, (probability * 10).floor());
      bins[bin].add(probability);
      outcomes[bin].add(
        record.issuedRecord.predictedOutcome ==
                record.resolution.actualOutcomeLabel
            ? 1.0
            : 0.0,
      );
    }
    var ece = 0.0;
    final total = records.length.toDouble();
    for (var index = 0; index < bins.length; index++) {
      if (bins[index].isEmpty) {
        continue;
      }
      final conf = bins[index].fold<double>(0.0, (sum, value) => sum + value) /
          bins[index].length;
      final acc =
          outcomes[index].fold<double>(0.0, (sum, value) => sum + value) /
              outcomes[index].length;
      ece += (bins[index].length / total) * (conf - acc).abs();
    }
    return clamp01(ece);
  }

  double _classwiseExpectedCalibrationError(
    List<ForecastResolvedForecastRecord> records,
  ) {
    if (records.isEmpty) {
      return 0.0;
    }
    final labels = <String>{
      for (final record in records)
        ...record.issuedRecord.calibratedPredictiveDistribution
            .discreteProbabilities.keys,
    };
    var maxEce = 0.0;
    for (final label in labels) {
      final bins = List.generate(10, (_) => <double>[]);
      final outcomes = List.generate(10, (_) => <double>[]);
      for (final record in records) {
        final probability = record.issuedRecord.calibratedPredictiveDistribution
                .discreteProbabilities[label] ??
            0.0;
        final bin = math.min(9, (probability * 10).floor());
        bins[bin].add(probability);
        outcomes[bin].add(
          record.resolution.actualOutcomeLabel == label ? 1.0 : 0.0,
        );
      }
      var ece = 0.0;
      for (var index = 0; index < bins.length; index++) {
        if (bins[index].isEmpty) {
          continue;
        }
        final conf =
            bins[index].fold<double>(0.0, (sum, value) => sum + value) /
                bins[index].length;
        final acc =
            outcomes[index].fold<double>(0.0, (sum, value) => sum + value) /
                outcomes[index].length;
        ece += (bins[index].length / records.length) * (conf - acc).abs();
      }
      maxEce = math.max(maxEce, ece);
    }
    return clamp01(maxEce);
  }

  double _coverageGap(List<ForecastResolvedForecastRecord> records) {
    if (records.isEmpty) {
      return 0.0;
    }
    const nominal = <String, double>{
      '50': 0.50,
      '80': 0.80,
      '90': 0.90,
      '95': 0.95,
    };
    var totalGap = 0.0;
    var count = 0;
    for (final entry in nominal.entries) {
      var covered = 0;
      var seen = 0;
      for (final record in records) {
        final value = record.coverageByInterval[entry.key];
        if (value == null) {
          continue;
        }
        seen++;
        if (value) {
          covered++;
        }
      }
      if (seen == 0) {
        continue;
      }
      totalGap += ((covered / seen) - entry.value).abs();
      count++;
    }
    if (count == 0) {
      return 0.0;
    }
    return clamp01(totalGap / count);
  }

  int _minimumSamplesFor(ForecastOutcomeKind outcomeKind) {
    return switch (outcomeKind) {
      ForecastOutcomeKind.binary => 200,
      ForecastOutcomeKind.categorical => 500,
      ForecastOutcomeKind.count => 500,
      ForecastOutcomeKind.continuous => 300,
    };
  }

  void _hydrate() {
    final raw = _prefs?.getString(_resolutionsKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return;
    }
    _resolved
      ..clear()
      ..addAll(
        decoded.whereType<Map>().map(
              (entry) => ForecastResolvedForecastRecord.fromJson(
                Map<String, dynamic>.from(entry),
              ),
            ),
      );
  }

  Future<void> _persist() async {
    if (_prefs == null) {
      return;
    }
    await _prefs.setString(
      _resolutionsKey,
      jsonEncode(_resolved.map((entry) => entry.toJson()).toList()),
    );
  }
}
