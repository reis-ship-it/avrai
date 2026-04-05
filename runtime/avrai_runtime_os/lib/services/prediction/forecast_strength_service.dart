import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_ensemble_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_math_support.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_regime_shift_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

enum ForecastStrengthBand {
  strong,
  reliable,
  guarded,
  weak,
  observational,
}

extension ForecastStrengthBandX on ForecastStrengthBand {
  String get label {
    return switch (this) {
      ForecastStrengthBand.strong => 'Strong',
      ForecastStrengthBand.reliable => 'Reliable',
      ForecastStrengthBand.guarded => 'Guarded',
      ForecastStrengthBand.weak => 'Weak',
      ForecastStrengthBand.observational => 'Observational only',
    };
  }
}

ForecastStrengthBand forecastStrengthBandFor(double value) {
  if (value >= 0.85) {
    return ForecastStrengthBand.strong;
  }
  if (value >= 0.70) {
    return ForecastStrengthBand.reliable;
  }
  if (value >= 0.55) {
    return ForecastStrengthBand.guarded;
  }
  if (value >= 0.40) {
    return ForecastStrengthBand.weak;
  }
  return ForecastStrengthBand.observational;
}

class ForecastStrengthAssessment {
  const ForecastStrengthAssessment({
    required this.truthScope,
    required this.sphereId,
    required this.bucketKey,
    required this.bucketHierarchy,
    required this.outcomeProbability,
    required this.predictedOutcome,
    required this.forecastStrength,
    required this.actionability,
    required this.supportQuality,
    required this.decisionMargin,
    required this.rawDistribution,
    required this.calibratedDistribution,
    required this.calibrationSnapshot,
    required this.regimeShift,
    required this.diagnostics,
    required this.componentWeights,
    required this.representationMix,
  });

  final TruthScopeDescriptor truthScope;
  final String sphereId;
  final String bucketKey;
  final List<String> bucketHierarchy;
  final double outcomeProbability;
  final String predictedOutcome;
  final double forecastStrength;
  final double actionability;
  final double supportQuality;
  final double decisionMargin;
  final ForecastPredictiveDistribution rawDistribution;
  final ForecastPredictiveDistribution calibratedDistribution;
  final ForecastCalibrationSnapshot calibrationSnapshot;
  final ForecastRegimeShiftAssessment regimeShift;
  final ForecastStrengthDiagnostics diagnostics;
  final Map<String, double> componentWeights;
  final Map<String, int> representationMix;
}

class ForecastStrengthService {
  ForecastStrengthService({
    required ForecastEnsembleService ensembleService,
    required ForecastCalibrationService calibrationService,
    required ForecastRegimeShiftService regimeShiftService,
  })  : _ensembleService = ensembleService,
        _calibrationService = calibrationService,
        _regimeShiftService = regimeShiftService;

  final ForecastEnsembleService _ensembleService;
  final ForecastCalibrationService _calibrationService;
  final ForecastRegimeShiftService _regimeShiftService;

  ForecastStrengthAssessment assess({
    required ForecastKernelRequest request,
    required ForecastKernelResult kernelResult,
    required ReplayYearCompletenessScore replayYearScore,
  }) {
    final truthScope = truthScopeForRequest(
      request: request,
      kernelResult: kernelResult,
    );
    final sphereId = truthScope.sphereId;
    final horizonBand = horizonBandFor(request.targetWindow.duration);
    final bucketHierarchy = forecastBucketHierarchy(
      scope: truthScope,
      outcomeKind: kernelResult.outcomeKind,
      horizonBand: horizonBand,
    );
    final rawDistribution = _rawDistributionFor(
      request: request,
      kernelResult: kernelResult,
    );
    final components = _componentDistributionsFor(
      request: request,
      kernelResult: kernelResult,
      fallback: rawDistribution,
    );
    final regimeShift = _regimeShiftService.assess(
      bucketKeys: bucketHierarchy,
      outcomeKind: kernelResult.outcomeKind,
    );
    final ensemble = _ensembleService.pool(
      components: components,
      bucketKeys: bucketHierarchy,
      outcomeKind: kernelResult.outcomeKind,
      changePointProbability: regimeShift.probability,
    );
    final calibratedDistribution = _calibrationService.calibrate(
      distribution: ensemble.pooledDistribution,
      bucketKeys: bucketHierarchy,
      outcomeKind: kernelResult.outcomeKind,
      decisionSpec: request.decisionSpec,
    );
    final calibrationSnapshot = _calibrationService.snapshotFor(
      bucketKeys: bucketHierarchy,
      outcomeKind: kernelResult.outcomeKind,
    );
    final baselineDenominator =
        calibrationSnapshot.baselinePrimaryScoreMean.abs() + 1e-6;
    final empiricalStrength = clamp01(
      sigmoid(
            calibrationSnapshot.skillLowerConfidenceBound / baselineDenominator,
          ) *
          (1.0 - calibrationSnapshot.calibrationGap) *
          math.exp(-ensemble.disagreement) *
          (1.0 - regimeShift.probability),
    );
    final priorStrength = clamp01(
      (0.50 + (0.30 * clamp01(rawDistribution.topProbability))) *
          (1.0 - (calibrationSnapshot.calibrationGap * 0.5)) *
          (1.0 - (regimeShift.probability * 0.5)),
    );
    final empiricalWeight = clamp01(
      calibrationSnapshot.effectiveSampleSize /
          _minimumSamplesFor(kernelResult.outcomeKind),
    );
    final strength = clamp01(
      (empiricalStrength * empiricalWeight) +
          (priorStrength * (1.0 - empiricalWeight)),
    );
    final supportQuality = _supportQualityFor(
      request: request,
      replayYearScore: replayYearScore,
    );
    final decisionMargin = _decisionMarginFor(
      distribution: calibratedDistribution,
      decisionSpec: request.decisionSpec,
      outcomeKind: kernelResult.outcomeKind,
      climatologyDistribution: ensemble.climatologyDistribution,
    );
    final actionability = clamp01(strength * decisionMargin * supportQuality);
    final outcomeProbability = _outcomeProbabilityFor(
      distribution: calibratedDistribution,
      decisionSpec: request.decisionSpec,
      kernelResult: kernelResult,
    );
    final predictedOutcome = _predictedOutcomeFor(
      distribution: calibratedDistribution,
      decisionSpec: request.decisionSpec,
      kernelResult: kernelResult,
    );
    final representationMix = _representationMixFor(components);
    final diagnostics = ForecastStrengthDiagnostics(
      forecastStrength: strength,
      actionability: actionability,
      supportQuality: supportQuality,
      decisionMargin: decisionMargin,
      calibrationGap: calibrationSnapshot.calibrationGap,
      disagreement: ensemble.disagreement,
      changePointProbability: regimeShift.probability,
      skillLowerConfidenceBound: calibrationSnapshot.skillLowerConfidenceBound,
      effectiveSampleSize: math.min(
        ensemble.effectiveSampleSize,
        calibrationSnapshot.effectiveSampleSize,
      ),
      metadata: <String, dynamic>{
        'sphere_id': sphereId,
        'truth_scope': truthScope.toJson(),
        'bucket_key': bucketHierarchy.first,
        'bucket_hierarchy': bucketHierarchy,
        'calibration_snapshot': calibrationSnapshot.toJson(),
        'component_weights': ensemble.componentWeights,
        'representation_mix': representationMix,
        'regime_shift_probability': regimeShift.probability,
        'regime_shift_recent_skill_mean': regimeShift.recentSkillMean,
        'regime_shift_historical_skill_mean': regimeShift.historicalSkillMean,
        'regime_shift_deterioration_zscore': regimeShift.deteriorationZScore,
        'raw_kernel_confidence': kernelResult.confidence,
      },
    );
    return ForecastStrengthAssessment(
      truthScope: truthScope,
      sphereId: sphereId,
      bucketKey: bucketHierarchy.first,
      bucketHierarchy: bucketHierarchy,
      outcomeProbability: outcomeProbability,
      predictedOutcome: predictedOutcome,
      forecastStrength: strength,
      actionability: actionability,
      supportQuality: supportQuality,
      decisionMargin: decisionMargin,
      rawDistribution: rawDistribution,
      calibratedDistribution: calibratedDistribution,
      calibrationSnapshot: calibrationSnapshot,
      regimeShift: regimeShift,
      diagnostics: diagnostics,
      componentWeights: ensemble.componentWeights,
      representationMix: representationMix,
    );
  }

  ForecastIssuedForecastRecord buildIssuedRecord({
    required ForecastKernelRequest request,
    required ForecastKernelResult result,
    required ForecastStrengthAssessment assessment,
    required String dispositionName,
    required List<String> governanceReasons,
  }) {
    return ForecastIssuedForecastRecord(
      forecastId: request.forecastId,
      bucketKey: assessment.bucketKey,
      subjectId: request.subjectId,
      forecastFamilyId: result.forecastFamilyId,
      outcomeKind: result.outcomeKind,
      issuedAt: result.claim.forecastCreatedAt.toUtc(),
      predictedOutcome: assessment.predictedOutcome,
      rawPredictiveDistribution: assessment.rawDistribution,
      calibratedPredictiveDistribution: assessment.calibratedDistribution,
      forecastStrength: assessment.forecastStrength,
      actionability: assessment.actionability,
      supportQuality: assessment.supportQuality,
      diagnostics: assessment.diagnostics,
      truthScope: assessment.truthScope,
      sphereId: assessment.sphereId,
      metadata: <String, dynamic>{
        'disposition': dispositionName,
        'governance_reasons': governanceReasons,
        'outcome_probability': assessment.outcomeProbability,
        'band': forecastStrengthBandFor(assessment.forecastStrength).name,
        'scope_key': assessment.truthScope.scopeKey,
        'truth_scope': assessment.truthScope.toJson(),
        'representation_mix': assessment.representationMix,
      },
    );
  }

  ForecastPredictiveDistribution _rawDistributionFor({
    required ForecastKernelRequest request,
    required ForecastKernelResult kernelResult,
  }) {
    final existing = kernelResult.rawPredictiveDistribution;
    if (existing != null) {
      return existing;
    }
    if (kernelResult.outcomeKind == ForecastOutcomeKind.continuous) {
      return ForecastPredictiveDistribution(
        outcomeKind: ForecastOutcomeKind.continuous,
        quantiles: const <String, double>{
          '0.05': 0.0,
          '0.50': 0.5,
          '0.95': 1.0,
        },
        mean: kernelResult.outcomeProbability ?? kernelResult.confidence,
      );
    }
    final positive = kernelResult.outcomeProbability ??
        kernelResult.claim.outcomeProbability ??
        kernelResult.confidence;
    return ForecastPredictiveDistribution(
      outcomeKind: kernelResult.outcomeKind,
      discreteProbabilities: <String, double>{
        'positive': clamp01(positive),
        'negative': clamp01(1.0 - positive),
      },
      mean: positive,
      variance: positive * (1.0 - positive),
      representationComponent: ForecastRepresentationComponent.classical,
      metadata: <String, dynamic>{
        'fallback_generator': 'forecast_strength_service',
        'forecast_id': request.forecastId,
      },
    );
  }

  List<ForecastPredictiveDistribution> _componentDistributionsFor({
    required ForecastKernelRequest request,
    required ForecastKernelResult kernelResult,
    required ForecastPredictiveDistribution fallback,
  }) {
    final raw = request.metadata['ensemble_predictive_distributions'] ??
        kernelResult.metadata['ensemble_predictive_distributions'];
    if (raw is! List) {
      return <ForecastPredictiveDistribution>[fallback];
    }
    final distributions = <ForecastPredictiveDistribution>[];
    for (final entry in raw) {
      if (entry is Map) {
        final normalized = Map<String, dynamic>.from(entry);
        final distributionJson = normalized['distribution'] is Map
            ? normalized['distribution']
            : normalized;
        final distribution = ForecastPredictiveDistribution.fromJson(
          Map<String, dynamic>.from(distributionJson as Map),
        );
        distributions.add(
          ForecastPredictiveDistribution(
            outcomeKind: distribution.outcomeKind,
            discreteProbabilities: distribution.discreteProbabilities,
            quantiles: distribution.quantiles,
            mean: distribution.mean,
            variance: distribution.variance,
            componentId: normalized['componentId']?.toString() ??
                distribution.componentId,
            representationComponent:
                normalized['representationComponent'] != null
                    ? ForecastRepresentationComponent.values.firstWhere(
                        (value) =>
                            value.name == normalized['representationComponent'],
                        orElse: () =>
                            distribution.representationComponent ??
                            ForecastRepresentationComponent.classical,
                      )
                    : distribution.representationComponent,
            metadata: distribution.metadata,
          ),
        );
      }
    }
    if (distributions.isEmpty) {
      return <ForecastPredictiveDistribution>[fallback];
    }
    return distributions;
  }

  double _supportQualityFor({
    required ForecastKernelRequest request,
    required ReplayYearCompletenessScore replayYearScore,
  }) {
    final replayBacked = request.metadata['replay_backed'] as bool? ?? true;
    if (replayBacked) {
      return clamp01(replayYearScore.overallScore);
    }
    return clamp01(
      (request.metadata['evidence_quality'] as num?)?.toDouble() ?? 0.5,
    );
  }

  double _decisionMarginFor({
    required ForecastPredictiveDistribution distribution,
    required ForecastDecisionSpec? decisionSpec,
    required ForecastOutcomeKind outcomeKind,
    required ForecastPredictiveDistribution climatologyDistribution,
  }) {
    if (outcomeKind == ForecastOutcomeKind.binary) {
      final positiveLabel =
          distribution.discreteProbabilities.containsKey('positive')
              ? 'positive'
              : distribution.topOutcome ?? '';
      final probability = distribution.discreteProbabilities[positiveLabel] ??
          distribution.topProbability;
      return clamp01(2.0 * (probability - 0.5).abs());
    }
    if (outcomeKind == ForecastOutcomeKind.categorical ||
        outcomeKind == ForecastOutcomeKind.count) {
      final sorted = distribution.discreteProbabilities.entries.toList()
        ..sort((left, right) => right.value.compareTo(left.value));
      if (sorted.isEmpty) {
        return 0.0;
      }
      if (sorted.length == 1) {
        return clamp01(sorted.first.value);
      }
      return clamp01(sorted[0].value - sorted[1].value);
    }
    if (decisionSpec?.threshold != null) {
      final cdf = cdfAtThreshold(
        distribution: distribution,
        threshold: decisionSpec!.threshold!,
      );
      final tailProbability = switch (decisionSpec.thresholdMode) {
        ForecastThresholdMode.below => cdf,
        ForecastThresholdMode.inside => 1.0 - (2.0 * (cdf - 0.5).abs()),
        ForecastThresholdMode.outside => 2.0 * (cdf - 0.5).abs(),
        _ => 1.0 - cdf,
      };
      return clamp01(2.0 * (tailProbability - 0.5).abs());
    }
    return clamp01(
      1.0 -
          normalizedIntervalWidth(
            distribution: distribution,
            climatologyWidth:
                ((climatologyDistribution.quantiles['0.95'] ?? 1.0) -
                        (climatologyDistribution.quantiles['0.05'] ?? 0.0))
                    .abs(),
          ),
    );
  }

  double _outcomeProbabilityFor({
    required ForecastPredictiveDistribution distribution,
    required ForecastDecisionSpec? decisionSpec,
    required ForecastKernelResult kernelResult,
  }) {
    if (kernelResult.outcomeKind == ForecastOutcomeKind.continuous) {
      if (decisionSpec?.threshold != null) {
        final cdf = cdfAtThreshold(
          distribution: distribution,
          threshold: decisionSpec!.threshold!,
        );
        return clamp01(
          switch (decisionSpec.thresholdMode) {
            ForecastThresholdMode.below => cdf,
            ForecastThresholdMode.inside => 1.0 - (2.0 * (cdf - 0.5).abs()),
            ForecastThresholdMode.outside => 2.0 * (cdf - 0.5).abs(),
            _ => 1.0 - cdf,
          },
        );
      }
      return clamp01(distribution.mean ?? kernelResult.confidence);
    }
    if (kernelResult.outcomeKind == ForecastOutcomeKind.binary &&
        distribution.discreteProbabilities.containsKey('positive')) {
      return clamp01(distribution.discreteProbabilities['positive'] ?? 0.0);
    }
    return clamp01(distribution.topProbability);
  }

  String _predictedOutcomeFor({
    required ForecastPredictiveDistribution distribution,
    required ForecastDecisionSpec? decisionSpec,
    required ForecastKernelResult kernelResult,
  }) {
    if (kernelResult.outcomeKind == ForecastOutcomeKind.continuous) {
      if (decisionSpec?.threshold != null) {
        final probability = _outcomeProbabilityFor(
          distribution: distribution,
          decisionSpec: decisionSpec,
          kernelResult: kernelResult,
        );
        return probability >= 0.5 ? 'threshold_likely' : 'threshold_unlikely';
      }
      return kernelResult.predictedOutcome;
    }
    return distribution.topOutcome ?? kernelResult.predictedOutcome;
  }

  int _minimumSamplesFor(ForecastOutcomeKind outcomeKind) {
    return switch (outcomeKind) {
      ForecastOutcomeKind.binary => 200,
      ForecastOutcomeKind.categorical => 500,
      ForecastOutcomeKind.count => 500,
      ForecastOutcomeKind.continuous => 300,
    };
  }

  Map<String, int> _representationMixFor(
    List<ForecastPredictiveDistribution> distributions,
  ) {
    final counts = <String, int>{};
    for (final distribution in distributions) {
      final key = (distribution.representationComponent ??
              ForecastRepresentationComponent.classical)
          .name;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

TruthScopeDescriptor truthScopeForRequest({
  required ForecastKernelRequest request,
  required ForecastKernelResult kernelResult,
}) {
  return const TruthScopeRegistry().normalizeForecastScope(
    scope: request.truthScope ??
        kernelResult.truthScope ??
        kernelResult.claim.truthScope,
    metadata: request.metadata,
    familyId: kernelResult.forecastFamilyId,
  );
}

List<String> forecastBucketHierarchy({
  required TruthScopeDescriptor scope,
  required ForecastOutcomeKind outcomeKind,
  required String horizonBand,
}) {
  final tenantIsPartner =
      scope.tenantScope == TruthTenantScope.trustedPartnerPrivate;
  return <String>[
    ForecastSkillBucketKey(
      scope: scope,
      outcomeKind: outcomeKind,
      horizonBand: horizonBand,
    ).value,
    ForecastSkillBucketKey(
      scope: scope.copyWith(familyId: 'all'),
      outcomeKind: outcomeKind,
      horizonBand: 'all',
    ).value,
    ForecastSkillBucketKey(
      scope: scope.copyWith(sphereId: 'all', familyId: 'all'),
      outcomeKind: outcomeKind,
      horizonBand: 'all',
    ).value,
    ForecastSkillBucketKey(
      scope: tenantIsPartner
          ? scope.copyWith(
              governanceStratum: GovernanceStratum.universal,
              agentClass: TruthAgentClass.partner,
              sphereId: 'global',
              familyId: 'all',
            )
          : scope.copyWith(
              governanceStratum: GovernanceStratum.universal,
              agentClass: TruthAgentClass.system,
              sphereId: 'global',
              familyId: 'all',
              clearTenantId:
                  scope.tenantScope != TruthTenantScope.trustedPartnerPrivate,
            ),
      outcomeKind: outcomeKind,
      horizonBand: 'all',
    ).value,
  ];
}
