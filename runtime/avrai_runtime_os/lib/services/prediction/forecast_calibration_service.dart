import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_math_support.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';

class ForecastCalibrationSelection {
  const ForecastCalibrationSelection({
    required this.bucketKey,
    required this.records,
  });

  final String bucketKey;
  final List<ForecastResolvedForecastRecord> records;
}

class ForecastCalibrationService {
  ForecastCalibrationService({
    required ForecastSkillLedger skillLedger,
    DateTime Function()? nowProvider,
  })  : _skillLedger = skillLedger,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final ForecastSkillLedger _skillLedger;
  final DateTime Function() _nowProvider;

  ForecastCalibrationSelection selectCalibrationBucket({
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final hierarchy = bucketKeys.toList(growable: false);
    final minimumSamples = _minimumSamplesFor(outcomeKind);
    ForecastCalibrationSelection? fallbackSelection;
    for (final bucketKey in hierarchy) {
      final records =
          _skillLedger.resolvedRecordsForBucketKeys(<String>[bucketKey]);
      if (records.isEmpty) {
        continue;
      }
      fallbackSelection ??=
          ForecastCalibrationSelection(bucketKey: bucketKey, records: records);
      if (records.length >= minimumSamples) {
        return ForecastCalibrationSelection(
            bucketKey: bucketKey, records: records);
      }
    }
    return fallbackSelection ??
        ForecastCalibrationSelection(
            bucketKey: hierarchy.firstOrNull ?? '', records: const []);
  }

  ForecastCalibrationSnapshot snapshotFor({
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final selection = selectCalibrationBucket(
      bucketKeys: bucketKeys,
      outcomeKind: outcomeKind,
    );
    if (selection.bucketKey.isEmpty) {
      return _skillLedger.calibrationSnapshotFor(
        bucketKeys: const <String>[],
        outcomeKind: outcomeKind,
      );
    }
    return _skillLedger.calibrationSnapshotFor(
      bucketKeys: <String>[selection.bucketKey],
      outcomeKind: outcomeKind,
    );
  }

  ForecastPredictiveDistribution calibrate({
    required ForecastPredictiveDistribution distribution,
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
    ForecastDecisionSpec? decisionSpec,
  }) {
    final selection = selectCalibrationBucket(
      bucketKeys: bucketKeys,
      outcomeKind: outcomeKind,
    );
    if (selection.records.isEmpty) {
      return distribution;
    }
    if (outcomeKind == ForecastOutcomeKind.binary) {
      return _calibrateBinary(
        distribution: distribution,
        records: selection.records,
        decisionSpec: decisionSpec,
      );
    }
    if (outcomeKind == ForecastOutcomeKind.continuous) {
      return _calibrateContinuous(
        distribution: distribution,
        records: selection.records,
      );
    }
    return _calibrateCategorical(
      distribution: distribution,
      records: selection.records,
      outcomeKind: outcomeKind,
    );
  }

  ForecastPredictiveDistribution _calibrateBinary({
    required ForecastPredictiveDistribution distribution,
    required List<ForecastResolvedForecastRecord> records,
    ForecastDecisionSpec? decisionSpec,
  }) {
    final labels = <String>{
      ...distribution.discreteProbabilities.keys,
      for (final record in records)
        if (record.resolution.actualOutcomeLabel != null)
          record.resolution.actualOutcomeLabel!,
    }.toList(growable: false);
    if (labels.length < 2) {
      return distribution;
    }
    final positiveLabel = _positiveLabelFor(labels, decisionSpec);
    final rawPositive = distribution.discreteProbabilities[positiveLabel] ??
        distribution.topProbability;
    var bandwidth = 0.10;
    List<ForecastResolvedForecastRecord> localRecords = const [];
    while (bandwidth <= 0.50) {
      localRecords = records.where((record) {
        final historical = record.issuedRecord.rawPredictiveDistribution
                .discreteProbabilities[positiveLabel] ??
            0.0;
        return (historical - rawPositive).abs() <= bandwidth;
      }).toList(growable: false);
      if (localRecords.length >= 25) {
        break;
      }
      bandwidth += 0.10;
    }
    if (localRecords.isEmpty) {
      return distribution;
    }
    final now = _nowProvider();
    var weightedPositives = 0.0;
    var totalWeight = 0.0;
    for (final record in localRecords) {
      final historicalProbability = record.issuedRecord
              .rawPredictiveDistribution.discreteProbabilities[positiveLabel] ??
          0.0;
      final kernelWeight = math.max(
        0.0,
        1.0 - ((historicalProbability - rawPositive).abs() / bandwidth),
      );
      final recency = recencyWeight(
        nowUtc: now,
        observedAtUtc: record.resolution.resolvedAt.toUtc(),
      );
      final weight = kernelWeight * recency;
      totalWeight += weight;
      if (record.resolution.actualOutcomeLabel == positiveLabel) {
        weightedPositives += weight;
      }
    }
    if (totalWeight == 0.0) {
      return distribution;
    }
    final betaMean = (1.0 + weightedPositives) / (2.0 + totalWeight);
    final calibratedPositive =
        ((totalWeight * betaMean) + (10.0 * rawPositive)) /
            (totalWeight + 10.0);
    final adjusted = <String, double>{};
    adjusted[positiveLabel] = clamp01(calibratedPositive);
    final otherLabels =
        labels.where((label) => label != positiveLabel).toList();
    final originalOtherMass = otherLabels.fold<double>(
      0.0,
      (sum, label) => sum + (distribution.discreteProbabilities[label] ?? 0.0),
    );
    final remaining = clamp01(1.0 - adjusted[positiveLabel]!);
    for (final label in otherLabels) {
      final original = distribution.discreteProbabilities[label] ?? 0.0;
      adjusted[label] = originalOtherMass == 0.0
          ? remaining / math.max(otherLabels.length, 1)
          : remaining * (original / originalOtherMass);
    }
    final normalized = _normalizeDiscrete(adjusted);
    return ForecastPredictiveDistribution(
      outcomeKind: ForecastOutcomeKind.binary,
      discreteProbabilities: normalized,
      mean: normalized[positiveLabel],
      variance: normalized[positiveLabel]! * (1.0 - normalized[positiveLabel]!),
      metadata: const <String, dynamic>{'calibrator': 'local_beta_binomial'},
    );
  }

  ForecastPredictiveDistribution _calibrateCategorical({
    required ForecastPredictiveDistribution distribution,
    required List<ForecastResolvedForecastRecord> records,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final labels = <String>{
      ...distribution.discreteProbabilities.keys,
      for (final record in records)
        if (record.resolution.actualOutcomeLabel != null)
          record.resolution.actualOutcomeLabel!,
    };
    if (labels.isEmpty) {
      return distribution;
    }
    final now = _nowProvider();
    final empiricalCounts = <String, double>{
      for (final label in labels) label: 1.0
    };
    final predictedTotals = <String, double>{
      for (final label in labels) label: 1.0
    };
    var totalWeight = labels.length.toDouble();
    for (final record in records) {
      final recency = recencyWeight(
        nowUtc: now,
        observedAtUtc: record.resolution.resolvedAt.toUtc(),
      );
      totalWeight += recency;
      final actual = record.resolution.actualOutcomeLabel;
      if (actual != null) {
        empiricalCounts[actual] = (empiricalCounts[actual] ?? 1.0) + recency;
      }
      for (final label in labels) {
        predictedTotals[label] = (predictedTotals[label] ?? 1.0) +
            ((record.issuedRecord.rawPredictiveDistribution
                        .discreteProbabilities[label] ??
                    0.0) *
                recency);
      }
    }
    final adjusted = <String, double>{};
    for (final label in labels) {
      final empirical = (empiricalCounts[label] ?? 1.0) / totalWeight;
      final meanPredicted = (predictedTotals[label] ?? 1.0) / totalWeight;
      final scale = empirical / math.max(meanPredicted, 1e-6);
      adjusted[label] =
          (distribution.discreteProbabilities[label] ?? 0.0) * scale;
    }
    final normalized = _normalizeDiscrete(adjusted);
    return ForecastPredictiveDistribution(
      outcomeKind: outcomeKind,
      discreteProbabilities: normalized,
      mean:
          normalized.values.isEmpty ? 0.0 : normalized.values.reduce(math.max),
      metadata: const <String, dynamic>{'calibrator': 'empirical_dirichlet'},
    );
  }

  ForecastPredictiveDistribution _calibrateContinuous({
    required ForecastPredictiveDistribution distribution,
    required List<ForecastResolvedForecastRecord> records,
  }) {
    if (records.length < _minimumSamplesFor(ForecastOutcomeKind.continuous) ||
        distribution.quantiles.isEmpty) {
      return distribution;
    }
    final adjusted = Map<String, double>.from(distribution.quantiles);
    final intervalPairs = <String, ({String low, String high, double nominal})>{
      '50': (low: '0.25', high: '0.75', nominal: 0.50),
      '80': (low: '0.10', high: '0.90', nominal: 0.80),
      '90': (low: '0.05', high: '0.95', nominal: 0.90),
      '95': (low: '0.01', high: '0.99', nominal: 0.95),
    };
    for (final pair in intervalPairs.values) {
      final residuals = <double>[];
      for (final record in records) {
        final actual = record.resolution.actualOutcomeValue;
        final low =
            record.issuedRecord.rawPredictiveDistribution.quantiles[pair.low];
        final high =
            record.issuedRecord.rawPredictiveDistribution.quantiles[pair.high];
        if (actual == null || low == null || high == null) {
          continue;
        }
        residuals.add(
            math.max(low - actual, actual - high).clamp(0.0, double.infinity));
      }
      if (residuals.isEmpty) {
        continue;
      }
      residuals.sort();
      final qhat = empiricalQuantile(residuals, pair.nominal);
      if (adjusted.containsKey(pair.low)) {
        adjusted[pair.low] = adjusted[pair.low]! - qhat;
      }
      if (adjusted.containsKey(pair.high)) {
        adjusted[pair.high] = adjusted[pair.high]! + qhat;
      }
    }
    return ForecastPredictiveDistribution(
      outcomeKind: ForecastOutcomeKind.continuous,
      quantiles: _monotonicQuantiles(adjusted),
      mean: distribution.mean,
      variance: distribution.variance,
      metadata: const <String, dynamic>{'calibrator': 'split_conformal'},
    );
  }

  int _minimumSamplesFor(ForecastOutcomeKind outcomeKind) {
    return switch (outcomeKind) {
      ForecastOutcomeKind.binary => 200,
      ForecastOutcomeKind.categorical => 500,
      ForecastOutcomeKind.count => 500,
      ForecastOutcomeKind.continuous => 300,
    };
  }

  String _positiveLabelFor(
    List<String> labels,
    ForecastDecisionSpec? decisionSpec,
  ) {
    if (decisionSpec != null) {
      for (final label in decisionSpec.preferredOutcomes) {
        if (labels.contains(label)) {
          return label;
        }
      }
    }
    if (labels.contains('positive')) {
      return 'positive';
    }
    if (labels.contains('yes')) {
      return 'yes';
    }
    final sorted = [...labels]..sort();
    return sorted.first;
  }

  Map<String, double> _normalizeDiscrete(Map<String, double> probabilities) {
    if (probabilities.isEmpty) {
      return const <String, double>{};
    }
    final sanitized = probabilities.map(
      (key, value) =>
          MapEntry(key, value.isFinite ? math.max(0.0, value) : 0.0),
    );
    final total =
        sanitized.values.fold<double>(0.0, (sum, value) => sum + value);
    if (total == 0.0) {
      final uniform = 1.0 / sanitized.length;
      return sanitized.map((key, _) => MapEntry(key, uniform));
    }
    return sanitized.map((key, value) => MapEntry(key, value / total));
  }

  Map<String, double> _monotonicQuantiles(Map<String, double> quantiles) {
    final sorted = quantiles.entries
        .map((entry) => MapEntry(double.parse(entry.key), entry.value))
        .toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    var runningMax = double.negativeInfinity;
    final normalized = <String, double>{};
    for (final entry in sorted) {
      runningMax = math.max(runningMax, entry.value);
      normalized[entry.key.toStringAsFixed(2)] = runningMax;
    }
    return normalized;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
