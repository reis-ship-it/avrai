import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_math_support.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';

class ForecastEnsembleOutput {
  const ForecastEnsembleOutput({
    required this.pooledDistribution,
    required this.climatologyDistribution,
    required this.componentWeights,
    required this.disagreement,
    required this.effectiveSampleSize,
    required this.currentSupportMass,
  });

  final ForecastPredictiveDistribution pooledDistribution;
  final ForecastPredictiveDistribution climatologyDistribution;
  final Map<String, double> componentWeights;
  final double disagreement;
  final double effectiveSampleSize;
  final double currentSupportMass;
}

class ForecastEnsembleService {
  ForecastEnsembleService({
    required ForecastSkillLedger skillLedger,
    DateTime Function()? nowProvider,
  })  : _skillLedger = skillLedger,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final ForecastSkillLedger _skillLedger;
  final DateTime Function() _nowProvider;

  ForecastEnsembleOutput pool({
    required List<ForecastPredictiveDistribution> components,
    required Iterable<String> bucketKeys,
    required ForecastOutcomeKind outcomeKind,
    required double changePointProbability,
  }) {
    final normalizedComponents = _normalizeComponents(
      components,
      outcomeKind: outcomeKind,
    );
    final climatologyDistribution = _skillLedger.climatologyDistributionFor(
      bucketKeys: bucketKeys,
      outcomeKind: outcomeKind,
    );
    if (normalizedComponents.isEmpty) {
      return ForecastEnsembleOutput(
        pooledDistribution: climatologyDistribution,
        climatologyDistribution: climatologyDistribution,
        componentWeights: const <String, double>{},
        disagreement: 0.0,
        effectiveSampleSize: 0.0,
        currentSupportMass: 0.0,
      );
    }

    final componentWeights = _componentWeightsFor(
      components: normalizedComponents,
      bucketKeys: bucketKeys,
    );
    final initialDisagreement = outcomeKind == ForecastOutcomeKind.continuous
        ? _continuousDisagreement(
            normalizedComponents,
            climatologyDistribution,
          )
        : jsDisagreement(normalizedComponents);
    final currentSupportMass = _currentSupportMass(
      componentCount: normalizedComponents.length,
      disagreement: initialDisagreement,
      outcomeKind: outcomeKind,
    );
    final pooledDistribution = outcomeKind == ForecastOutcomeKind.continuous
        ? _blendContinuous(
            normalizedComponents,
            componentWeights,
          )
        : _blendDiscrete(
            normalizedComponents,
            componentWeights,
            outcomeKind: outcomeKind,
          );
    final historyWeights = _skillLedger
        .resolvedRecordsForBucketKeys(bucketKeys)
        .map(
          (entry) => recencyWeight(
            nowUtc: _nowProvider(),
            observedAtUtc: entry.resolution.resolvedAt.toUtc(),
          ),
        )
        .toList(growable: false);
    final ess = effectiveSampleSize(historyWeights);
    final shrunkDistribution = _shrinkToClimatology(
      distribution: pooledDistribution,
      climatology: climatologyDistribution,
      effectiveSampleSizeValue: ess,
      currentSupportMass: currentSupportMass,
      changePointProbability: changePointProbability,
      outcomeKind: outcomeKind,
    );
    final disagreement = initialDisagreement;
    return ForecastEnsembleOutput(
      pooledDistribution: shrunkDistribution,
      climatologyDistribution: climatologyDistribution,
      componentWeights: componentWeights,
      disagreement: disagreement,
      effectiveSampleSize: ess,
      currentSupportMass: currentSupportMass,
    );
  }

  Map<String, double> _componentWeightsFor({
    required List<ForecastPredictiveDistribution> components,
    required Iterable<String> bucketKeys,
  }) {
    if (components.length == 1) {
      final componentId = components.first.componentId ?? 'component_0';
      return <String, double>{componentId: 1.0};
    }
    final rawSkillScores = <String, double>{
      for (final component in components)
        component.componentId ?? 'component_${components.indexOf(component)}':
            _skillLedger.componentSkillMean(
          bucketKeys: bucketKeys,
          componentId: component.componentId ??
              'component_${components.indexOf(component)}',
        ),
    };
    final maxSkill = rawSkillScores.values.isEmpty
        ? 0.0
        : rawSkillScores.values.reduce(math.max);
    final expScores = rawSkillScores.map(
      (key, value) => MapEntry(key, math.exp((value - maxSkill) / 0.20)),
    );
    final expTotal =
        expScores.values.fold<double>(0.0, (sum, value) => sum + value);
    if (expTotal == 0.0) {
      final uniform = 1.0 / components.length;
      return <String, double>{
        for (final component in components)
          component.componentId ?? 'component_${components.indexOf(component)}':
              uniform,
      };
    }
    final uniform = 1.0 / components.length;
    return expScores.map((key, value) {
      final softmaxWeight = value / expTotal;
      return MapEntry(key, clamp01((softmaxWeight * 0.95) + (uniform * 0.05)));
    });
  }

  List<ForecastPredictiveDistribution> _normalizeComponents(
    List<ForecastPredictiveDistribution> components, {
    required ForecastOutcomeKind outcomeKind,
  }) {
    if (components.isEmpty) {
      return const <ForecastPredictiveDistribution>[];
    }
    return [
      for (var index = 0; index < components.length; index++)
        outcomeKind == ForecastOutcomeKind.continuous
            ? ForecastPredictiveDistribution(
                outcomeKind: ForecastOutcomeKind.continuous,
                quantiles:
                    Map<String, double>.from(components[index].quantiles),
                mean: components[index].mean,
                variance: components[index].variance,
                componentId:
                    components[index].componentId ?? 'component_$index',
                metadata: components[index].metadata,
              )
            : ForecastPredictiveDistribution(
                outcomeKind: outcomeKind,
                discreteProbabilities: _normalizedDiscreteProbabilities(
                  components[index].discreteProbabilities,
                ),
                mean: components[index].mean,
                variance: components[index].variance,
                componentId:
                    components[index].componentId ?? 'component_$index',
                metadata: components[index].metadata,
              ),
    ];
  }

  ForecastPredictiveDistribution _blendDiscrete(
    List<ForecastPredictiveDistribution> components,
    Map<String, double> componentWeights, {
    required ForecastOutcomeKind outcomeKind,
  }) {
    final labels = <String>{
      for (final component in components)
        ...component.discreteProbabilities.keys,
    };
    final pooled = <String, double>{};
    for (final label in labels) {
      pooled[label] = 0.0;
    }
    for (final component in components) {
      final weight =
          componentWeights[component.componentId ?? 'component_0'] ?? 0.0;
      for (final label in labels) {
        pooled[label] = (pooled[label] ?? 0.0) +
            ((component.discreteProbabilities[label] ?? 0.0) * weight);
      }
    }
    final normalized = _normalizedDiscreteProbabilities(pooled);
    final topProbability =
        normalized.values.isEmpty ? 0.0 : normalized.values.reduce(math.max);
    return ForecastPredictiveDistribution(
      outcomeKind: outcomeKind,
      discreteProbabilities: normalized,
      mean: topProbability,
      variance: topProbability * (1.0 - topProbability),
      metadata: const <String, dynamic>{'pooled': true},
    );
  }

  ForecastPredictiveDistribution _blendContinuous(
    List<ForecastPredictiveDistribution> components,
    Map<String, double> componentWeights,
  ) {
    final quantileKeys = <String>{
      for (final component in components) ...component.quantiles.keys,
    }.toList()
      ..sort();
    final pooledQuantiles = <String, double>{};
    for (final key in quantileKeys) {
      var total = 0.0;
      var totalWeight = 0.0;
      for (final component in components) {
        final value = component.quantiles[key];
        if (value == null) {
          continue;
        }
        final weight =
            componentWeights[component.componentId ?? 'component_0'] ?? 0.0;
        total += value * weight;
        totalWeight += weight;
      }
      if (totalWeight > 0.0) {
        pooledQuantiles[key] = total / totalWeight;
      }
    }
    final means = [
      for (final component in components)
        if (component.mean != null) component.mean!,
    ];
    final weights = [
      for (final component in components)
        if (component.mean != null)
          componentWeights[component.componentId ?? 'component_0'] ?? 0.0,
    ];
    return ForecastPredictiveDistribution(
      outcomeKind: ForecastOutcomeKind.continuous,
      quantiles: _monotonicQuantiles(pooledQuantiles),
      mean: means.isEmpty ? null : weightedMean(means, weights),
      metadata: const <String, dynamic>{'pooled': true},
    );
  }

  ForecastPredictiveDistribution _shrinkToClimatology({
    required ForecastPredictiveDistribution distribution,
    required ForecastPredictiveDistribution climatology,
    required double effectiveSampleSizeValue,
    required double currentSupportMass,
    required double changePointProbability,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final kappa = 5.0 * (1.0 + (4.0 * changePointProbability));
    final supportMass = math.max(effectiveSampleSizeValue, currentSupportMass);
    final denominator = supportMass + kappa;
    if (denominator <= 0.0) {
      return climatology;
    }
    if (outcomeKind == ForecastOutcomeKind.continuous) {
      final quantileKeys = <String>{
        ...distribution.quantiles.keys,
        ...climatology.quantiles.keys,
      }.toList()
        ..sort();
      final quantiles = <String, double>{};
      for (final key in quantileKeys) {
        final pooled =
            distribution.quantiles[key] ?? climatology.quantiles[key];
        final prior = climatology.quantiles[key] ?? distribution.quantiles[key];
        if (pooled == null || prior == null) {
          continue;
        }
        quantiles[key] =
            ((supportMass * pooled) + (kappa * prior)) / denominator;
      }
      final mean = distribution.mean == null && climatology.mean == null
          ? null
          : (((supportMass * (distribution.mean ?? 0.0)) +
                      (kappa * (climatology.mean ?? 0.0))) /
                  denominator)
              .toDouble();
      return ForecastPredictiveDistribution(
        outcomeKind: ForecastOutcomeKind.continuous,
        quantiles: _monotonicQuantiles(quantiles),
        mean: mean,
        metadata: const <String, dynamic>{'shrunk_to_climatology': true},
      );
    }

    final labels = <String>{
      ...distribution.discreteProbabilities.keys,
      ...climatology.discreteProbabilities.keys,
    };
    final blended = <String, double>{};
    for (final label in labels) {
      final pooled = distribution.discreteProbabilities[label] ?? 0.0;
      final prior = climatology.discreteProbabilities[label] ??
          (labels.isEmpty ? 0.0 : 1.0 / labels.length);
      blended[label] = ((supportMass * pooled) + (kappa * prior)) / denominator;
    }
    final normalized = _normalizedDiscreteProbabilities(blended);
    return ForecastPredictiveDistribution(
      outcomeKind: outcomeKind,
      discreteProbabilities: normalized,
      mean:
          normalized.values.isEmpty ? 0.0 : normalized.values.reduce(math.max),
      metadata: const <String, dynamic>{'shrunk_to_climatology': true},
    );
  }

  double _currentSupportMass({
    required int componentCount,
    required double disagreement,
    required ForecastOutcomeKind outcomeKind,
  }) {
    final agreementMass =
        componentCount.toDouble() * (1.0 + (1.0 - disagreement) * 6.0);
    final floor = outcomeKind == ForecastOutcomeKind.continuous ? 5.0 : 7.0;
    return math.max(floor, agreementMass);
  }

  double _continuousDisagreement(
    List<ForecastPredictiveDistribution> components,
    ForecastPredictiveDistribution climatology,
  ) {
    if (components.length <= 1) {
      return 0.0;
    }
    final quantileKeys = <String>{
      for (final component in components) ...component.quantiles.keys,
    };
    if (quantileKeys.isEmpty) {
      return 0.0;
    }
    final climatologyWidth = ((climatology.quantiles['0.75'] ?? 1.0) -
            (climatology.quantiles['0.25'] ?? 0.0))
        .abs();
    final normalization = climatologyWidth <= 0.0 ? 1.0 : climatologyWidth;
    final deviations = <double>[];
    for (final key in quantileKeys) {
      final values = [
        for (final component in components)
          if (component.quantiles.containsKey(key)) component.quantiles[key]!,
      ];
      if (values.length <= 1) {
        continue;
      }
      final mean =
          values.fold<double>(0.0, (sum, value) => sum + value) / values.length;
      final variance = values.fold<double>(
            0.0,
            (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
          ) /
          values.length;
      deviations.add(math.sqrt(variance));
    }
    if (deviations.isEmpty) {
      return 0.0;
    }
    final averageDeviation =
        deviations.fold<double>(0.0, (sum, value) => sum + value) /
            deviations.length;
    return clamp01(averageDeviation / normalization);
  }

  Map<String, double> _normalizedDiscreteProbabilities(
    Map<String, double> probabilities,
  ) {
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
