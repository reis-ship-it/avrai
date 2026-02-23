import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/memory/procedural/procedural_rule_schema.dart';

/// Extracts procedural rules from episodic tuples.
///
/// Phase 1.1B.2: identify recurring state-action patterns that predict success.
class ProceduralRuleExtractor {
  const ProceduralRuleExtractor();

  Future<List<ProceduralRule>> extractRules({
    required String agentId,
    required EpisodicMemoryStore episodicMemoryStore,
    DateTime? afterExclusive,
    int replayLimit = 2500,
    int minEvidence = 4,
    double minSuccessLift = 0.08,
    int maxRules = 24,
  }) async {
    final tuples = await episodicMemoryStore.replay(
      agentId: agentId,
      afterExclusive: afterExclusive,
      limit: replayLimit,
    );
    if (tuples.isEmpty) return const [];

    final actionGroups = <String, List<EpisodicTuple>>{};
    for (final tuple in tuples) {
      final actionType = tuple.actionType.trim();
      if (actionType.isEmpty) continue;
      actionGroups.putIfAbsent(actionType, () => <EpisodicTuple>[]).add(tuple);
    }

    final rules = <ProceduralRule>[];
    for (final entry in actionGroups.entries) {
      final actionType = entry.key;
      final actionTuples = entry.value;
      if (actionTuples.length < minEvidence) continue;

      final actionBaseSuccess = _averageSuccess(actionTuples);
      final featureSeries = _collectFeatureSeries(actionTuples);

      for (final featureEntry in featureSeries.entries) {
        final featureName = featureEntry.key;
        final values = featureEntry.value;
        if (values.length < minEvidence) continue;

        final thresholds =
            _quantileThresholds(values.map((v) => v.value).toList());
        final bestBin = _bestBin(
          values: values,
          thresholds: thresholds,
          minEvidence: minEvidence,
        );
        if (bestBin == null) continue;

        final lift = bestBin.successRate - actionBaseSuccess;
        if (lift < minSuccessLift) continue;

        final confidence = _ruleConfidence(
          evidenceCount: bestBin.evidenceCount,
          successRate: bestBin.successRate,
          successLift: lift,
        );
        final now = DateTime.now().toUtc();
        rules.add(
          ProceduralRule(
            id: _ruleId(
              agentId: agentId,
              actionType: actionType,
              featureName: featureName,
              binLabel: bestBin.label,
            ),
            agentId: agentId,
            conditions: {
              featureName: FeatureThreshold(
                minInclusive: bestBin.minInclusive,
                maxInclusive: bestBin.maxInclusive,
              ),
            },
            actionPreference: actionType,
            evidenceCount: bestBin.evidenceCount,
            successRate: bestBin.successRate.clamp(0.0, 1.0),
            confidence: confidence,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    rules.sort((a, b) => b.confidence.compareTo(a.confidence));
    return rules.take(maxRules).toList(growable: false);
  }

  Map<String, List<_FeaturePoint>> _collectFeatureSeries(
      List<EpisodicTuple> tuples) {
    final pointsByFeature = <String, List<_FeaturePoint>>{};
    for (final tuple in tuples) {
      final success = _successScore(tuple.outcome);
      tuple.stateBefore.forEach((key, raw) {
        final numeric = _asDouble(raw);
        if (numeric == null) return;
        pointsByFeature
            .putIfAbsent(key, () => <_FeaturePoint>[])
            .add(_FeaturePoint(value: numeric, success: success));
      });
    }
    return pointsByFeature;
  }

  _BinStats? _bestBin({
    required List<_FeaturePoint> values,
    required _QuantileThresholds thresholds,
    required int minEvidence,
  }) {
    final bins = <_BinStats>[
      _BinStats(label: 'low', minInclusive: null, maxInclusive: thresholds.p33),
      _BinStats(
        label: 'mid',
        minInclusive: thresholds.p33,
        maxInclusive: thresholds.p66,
      ),
      _BinStats(
          label: 'high', minInclusive: thresholds.p66, maxInclusive: null),
    ];

    for (final point in values) {
      for (final bin in bins) {
        if (bin.matches(point.value)) {
          bin.add(point.success);
          break;
        }
      }
    }

    _BinStats? best;
    for (final bin in bins) {
      if (bin.evidenceCount < minEvidence) continue;
      if (best == null || bin.successRate > best.successRate) {
        best = bin;
      }
    }
    return best;
  }

  _QuantileThresholds _quantileThresholds(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final p33 = _percentile(sorted, 0.33);
    final p66 = _percentile(sorted, 0.66);
    return _QuantileThresholds(p33: p33, p66: p66);
  }

  double _percentile(List<double> sortedValues, double p) {
    if (sortedValues.isEmpty) return 0.0;
    if (sortedValues.length == 1) return sortedValues.first;
    final idx = (p.clamp(0.0, 1.0) * (sortedValues.length - 1)).round();
    return sortedValues[idx];
  }

  double _averageSuccess(List<EpisodicTuple> tuples) {
    if (tuples.isEmpty) return 0.0;
    var sum = 0.0;
    for (final tuple in tuples) {
      sum += _successScore(tuple.outcome);
    }
    return (sum / tuples.length).clamp(0.0, 1.0);
  }

  double _successScore(OutcomeSignal outcome) {
    switch (outcome.category) {
      case OutcomeCategory.binary:
      case OutcomeCategory.temporal:
        return outcome.value.clamp(0.0, 1.0);
      case OutcomeCategory.quality:
        final scaleMax = (outcome.metadata['scale_max'] as num?)?.toDouble();
        if (scaleMax != null && scaleMax > 0) {
          return (outcome.value / scaleMax).clamp(0.0, 1.0);
        }
        return outcome.value.clamp(0.0, 1.0);
      case OutcomeCategory.behavioral:
        return ((outcome.value + 1.0) / 2.0).clamp(0.0, 1.0);
    }
  }

  double _ruleConfidence({
    required int evidenceCount,
    required double successRate,
    required double successLift,
  }) {
    final evidenceFactor = (evidenceCount / 24.0).clamp(0.0, 1.0);
    final liftFactor = (successLift / 0.35).clamp(0.0, 1.0);
    return ((successRate.clamp(0.0, 1.0) * 0.6) +
            (evidenceFactor * 0.25) +
            (liftFactor * 0.15))
        .clamp(0.0, 1.0);
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  String _ruleId({
    required String agentId,
    required String actionType,
    required String featureName,
    required String binLabel,
  }) {
    final canonical = jsonEncode({
      'agent': agentId,
      'action': actionType,
      'feature': featureName,
      'bin': binLabel,
    });
    final digest = sha256.convert(utf8.encode(canonical)).toString();
    return 'proc-${digest.substring(0, 16)}';
  }
}

class _FeaturePoint {
  final double value;
  final double success;

  const _FeaturePoint({
    required this.value,
    required this.success,
  });
}

class _QuantileThresholds {
  final double p33;
  final double p66;

  const _QuantileThresholds({
    required this.p33,
    required this.p66,
  });
}

class _BinStats {
  final String label;
  final double? minInclusive;
  final double? maxInclusive;
  int evidenceCount = 0;
  double _successSum = 0.0;

  _BinStats({
    required this.label,
    required this.minInclusive,
    required this.maxInclusive,
  });

  bool matches(double value) {
    final aboveMin = minInclusive == null || value >= minInclusive!;
    final belowMax = maxInclusive == null || value <= maxInclusive!;
    return aboveMin && belowMax;
  }

  void add(double success) {
    evidenceCount += 1;
    _successSum += success;
  }

  double get successRate =>
      evidenceCount == 0 ? 0.0 : (_successSum / evidenceCount).clamp(0.0, 1.0);
}
