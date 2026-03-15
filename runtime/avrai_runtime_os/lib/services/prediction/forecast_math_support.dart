import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';

double clamp01(double value) => value.clamp(0.0, 1.0).toDouble();

double sigmoid(double value) => 1.0 / (1.0 + math.exp(-value));

double safeLog(double value, {double epsilon = 1e-9}) {
  return math.log(value <= epsilon ? epsilon : value);
}

double effectiveSampleSize(Iterable<double> weights) {
  final values = weights.where((value) => value > 0).toList(growable: false);
  if (values.isEmpty) {
    return 0.0;
  }
  final sum = values.fold<double>(0.0, (total, value) => total + value);
  final sqSum =
      values.fold<double>(0.0, (total, value) => total + (value * value));
  if (sqSum == 0.0) {
    return 0.0;
  }
  return (sum * sum) / sqSum;
}

double weightedMean(List<double> values, List<double> weights) {
  if (values.isEmpty || weights.isEmpty || values.length != weights.length) {
    return 0.0;
  }
  final totalWeight =
      weights.fold<double>(0.0, (total, value) => total + value);
  if (totalWeight == 0.0) {
    return 0.0;
  }
  var weightedTotal = 0.0;
  for (var index = 0; index < values.length; index++) {
    weightedTotal += values[index] * weights[index];
  }
  return weightedTotal / totalWeight;
}

double weightedVariance(List<double> values, List<double> weights) {
  if (values.length < 2 || values.length != weights.length) {
    return 0.0;
  }
  final mean = weightedMean(values, weights);
  final totalWeight =
      weights.fold<double>(0.0, (total, value) => total + value);
  if (totalWeight == 0.0) {
    return 0.0;
  }
  var variance = 0.0;
  for (var index = 0; index < values.length; index++) {
    final delta = values[index] - mean;
    variance += weights[index] * delta * delta;
  }
  return variance / totalWeight;
}

double recencyWeight({
  required DateTime nowUtc,
  required DateTime observedAtUtc,
  Duration halfLife = const Duration(days: 30),
}) {
  if (!nowUtc.isAfter(observedAtUtc)) {
    return 1.0;
  }
  final ageMicros = nowUtc.difference(observedAtUtc).inMicroseconds;
  final halfLifeMicros = halfLife.inMicroseconds;
  if (halfLifeMicros <= 0) {
    return 1.0;
  }
  return math.exp(-math.ln2 * (ageMicros / halfLifeMicros));
}

double entropy(Map<String, double> probabilities) {
  if (probabilities.isEmpty) {
    return 0.0;
  }
  return -probabilities.values.fold<double>(
    0.0,
    (total, value) => total + (value <= 0.0 ? 0.0 : value * safeLog(value)),
  );
}

double jsDisagreement(List<ForecastPredictiveDistribution> distributions) {
  if (distributions.length <= 1) {
    return 0.0;
  }
  final allLabels = <String>{
    for (final distribution in distributions)
      ...distribution.discreteProbabilities.keys,
  };
  if (allLabels.isEmpty) {
    return 0.0;
  }
  final meanDistribution = <String, double>{};
  for (final label in allLabels) {
    final value = distributions.fold<double>(
          0.0,
          (total, distribution) =>
              total + (distribution.discreteProbabilities[label] ?? 0.0),
        ) /
        distributions.length;
    meanDistribution[label] = value;
  }
  final meanEntropy = entropy(meanDistribution);
  final componentEntropy = distributions.fold<double>(
        0.0,
        (total, distribution) => total + entropy(distribution.discreteProbabilities),
      ) /
      distributions.length;
  final divergence = (meanEntropy - componentEntropy).clamp(0.0, double.infinity);
  final normalization = safeLog(allLabels.length.toDouble());
  if (normalization == 0.0) {
    return 0.0;
  }
  return clamp01(divergence / normalization);
}

double scoreDiscreteLog({
  required ForecastPredictiveDistribution distribution,
  required String actualLabel,
}) {
  final probability = distribution.discreteProbabilities[actualLabel] ?? 1e-9;
  return -safeLog(probability);
}

double scoreDiscreteBrier({
  required ForecastPredictiveDistribution distribution,
  required String actualLabel,
}) {
  if (distribution.discreteProbabilities.isEmpty) {
    return 1.0;
  }
  return distribution.discreteProbabilities.entries.fold<double>(0.0, (
    total,
    entry,
  ) {
    final target = entry.key == actualLabel ? 1.0 : 0.0;
    final delta = entry.value - target;
    return total + (delta * delta);
  });
}

double pinballLoss({
  required double quantile,
  required double prediction,
  required double actual,
}) {
  final delta = actual - prediction;
  if (delta >= 0) {
    return quantile * delta;
  }
  return (quantile - 1.0) * delta;
}

double approximateCrps({
  required ForecastPredictiveDistribution distribution,
  required double actual,
}) {
  if (distribution.quantiles.isEmpty) {
    final mean = distribution.mean ?? 0.0;
    return (mean - actual).abs();
  }
  final quantiles = distribution.quantiles.entries
      .map((entry) => MapEntry(double.parse(entry.key), entry.value))
      .toList(growable: false)
    ..sort((left, right) => left.key.compareTo(right.key));
  final loss = quantiles.fold<double>(
    0.0,
    (total, entry) => total +
        (2.0 *
            pinballLoss(
              quantile: entry.key,
              prediction: entry.value,
              actual: actual,
            )),
  );
  return loss / quantiles.length;
}

double empiricalQuantile(List<double> sortedValues, double q) {
  if (sortedValues.isEmpty) {
    return 0.0;
  }
  final clampedQ = clamp01(q);
  final index = ((sortedValues.length - 1) * clampedQ).round();
  return sortedValues[index.clamp(0, sortedValues.length - 1)];
}

double cdfAtThreshold({
  required ForecastPredictiveDistribution distribution,
  required double threshold,
}) {
  if (distribution.quantiles.isEmpty) {
    final mean = distribution.mean ?? 0.0;
    return mean <= threshold ? 1.0 : 0.0;
  }
  final quantiles = distribution.quantiles.entries
      .map((entry) => MapEntry(double.parse(entry.key), entry.value))
      .toList(growable: false)
    ..sort((left, right) => left.value.compareTo(right.value));
  for (final entry in quantiles) {
    if (threshold <= entry.value) {
      return entry.key;
    }
  }
  return 1.0;
}

double normalizedIntervalWidth({
  required ForecastPredictiveDistribution distribution,
  required double climatologyWidth,
}) {
  final low = distribution.quantiles['0.05'];
  final high = distribution.quantiles['0.95'];
  if (low == null || high == null || climatologyWidth <= 0.0) {
    return 1.0;
  }
  return clamp01((high - low) / climatologyWidth);
}

double ksDistanceToUniform(List<double> pitValues) {
  if (pitValues.isEmpty) {
    return 0.0;
  }
  final sorted = [...pitValues]..sort();
  var maxDistance = 0.0;
  for (var index = 0; index < sorted.length; index++) {
    final empirical = (index + 1) / sorted.length;
    final uniform = sorted[index];
    maxDistance = math.max(maxDistance, (empirical - uniform).abs());
  }
  return clamp01(maxDistance);
}

String horizonBandFor(Duration targetWindow) {
  final minutes = targetWindow.inMinutes.abs();
  if (minutes < 60) {
    return '<1h';
  }
  if (minutes < 1440) {
    return '1h-24h';
  }
  if (minutes < 10080) {
    return '1d-7d';
  }
  return '>7d';
}
