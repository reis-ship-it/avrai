import 'dart:async';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';

class ForecastKernelAdminForecastRow {
  const ForecastKernelAdminForecastRow({
    required this.forecastId,
    required this.subjectId,
    required this.forecastFamilyId,
    required this.truthScope,
    required this.sphereId,
    required this.governanceStratum,
    required this.agentClass,
    required this.tenantScope,
    required this.tenantId,
    required this.predictedOutcome,
    required this.band,
    required this.disposition,
    required this.issuedAt,
    required this.outcomeProbability,
    required this.forecastStrength,
    required this.actionability,
    required this.supportQuality,
    required this.calibrationGap,
    required this.changeRisk,
    required this.skillLowerConfidenceBound,
    required this.warmingUp,
    required this.representationMix,
  });

  final String forecastId;
  final String subjectId;
  final String forecastFamilyId;
  final TruthScopeDescriptor truthScope;
  final String sphereId;
  final GovernanceStratum governanceStratum;
  final TruthAgentClass agentClass;
  final TruthTenantScope tenantScope;
  final String? tenantId;
  final String predictedOutcome;
  final ForecastStrengthBand band;
  final String disposition;
  final DateTime issuedAt;
  final double outcomeProbability;
  final double forecastStrength;
  final double actionability;
  final double supportQuality;
  final double calibrationGap;
  final double changeRisk;
  final double skillLowerConfidenceBound;
  final bool warmingUp;
  final Map<String, int> representationMix;
}

class ForecastKernelAdminSnapshot {
  const ForecastKernelAdminSnapshot({
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.issuedCount,
    required this.resolvedCount,
    required this.averageOutcomeProbability,
    required this.averageForecastStrength,
    required this.averageActionability,
    required this.averageSupportQuality,
    required this.averageCalibrationGap,
    required this.averageChangeRisk,
    required this.averageSkillLowerConfidenceBound,
    required this.bandCounts,
    required this.dispositionCounts,
    required this.strengthTrend,
    required this.recentForecasts,
  });

  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int issuedCount;
  final int resolvedCount;
  final double averageOutcomeProbability;
  final double averageForecastStrength;
  final double averageActionability;
  final double averageSupportQuality;
  final double averageCalibrationGap;
  final double averageChangeRisk;
  final double averageSkillLowerConfidenceBound;
  final Map<String, int> bandCounts;
  final Map<String, int> dispositionCounts;
  final List<double> strengthTrend;
  final List<ForecastKernelAdminForecastRow> recentForecasts;
}

class ForecastKernelAdminService {
  ForecastKernelAdminService({
    required ForecastSkillLedger skillLedger,
    DateTime Function()? nowProvider,
  })  : _skillLedger = skillLedger,
        _nowProvider = nowProvider ?? (() => DateTime.now().toUtc());

  final ForecastSkillLedger _skillLedger;
  final DateTime Function() _nowProvider;

  Future<ForecastKernelAdminSnapshot> getForecastSnapshot({
    Duration lookbackWindow = const Duration(hours: 24),
    int limit = 100,
  }) async {
    final now = _nowProvider().toUtc();
    final windowStart = now.subtract(lookbackWindow);
    final recentForecasts = _skillLedger.recentIssuedForecasts(
      lookbackWindow: lookbackWindow,
      limit: limit,
    );
    final rows = recentForecasts.map(_rowFromRecord).toList(growable: false);
    final bandCounts = <String, int>{};
    final dispositionCounts = <String, int>{};
    for (final row in rows) {
      bandCounts[row.band.label] = (bandCounts[row.band.label] ?? 0) + 1;
      dispositionCounts[row.disposition] =
          (dispositionCounts[row.disposition] ?? 0) + 1;
    }
    final bucketKeys = recentForecasts
        .map((record) => record.bucketKey)
        .toSet()
        .toList(growable: false);
    final resolvedCount =
        _skillLedger.resolvedRecordsForBucketKeys(bucketKeys).length;
    return ForecastKernelAdminSnapshot(
      generatedAt: now,
      windowStart: windowStart,
      windowEnd: now,
      issuedCount: rows.length,
      resolvedCount: resolvedCount,
      averageOutcomeProbability:
          _average(rows.map((row) => row.outcomeProbability)),
      averageForecastStrength:
          _average(rows.map((row) => row.forecastStrength)),
      averageActionability: _average(rows.map((row) => row.actionability)),
      averageSupportQuality: _average(rows.map((row) => row.supportQuality)),
      averageCalibrationGap: _average(rows.map((row) => row.calibrationGap)),
      averageChangeRisk: _average(rows.map((row) => row.changeRisk)),
      averageSkillLowerConfidenceBound:
          _average(rows.map((row) => row.skillLowerConfidenceBound)),
      bandCounts: bandCounts,
      dispositionCounts: dispositionCounts,
      strengthTrend: rows.reversed
          .take(12)
          .map((row) => row.forecastStrength)
          .toList(growable: false),
      recentForecasts: rows,
    );
  }

  Stream<ForecastKernelAdminSnapshot> watchForecastSnapshot({
    Duration lookbackWindow = const Duration(hours: 24),
    Duration refreshInterval = const Duration(seconds: 15),
    int limit = 100,
  }) {
    late final StreamController<ForecastKernelAdminSnapshot> controller;
    Timer? timer;

    Future<void> emit() async {
      controller.add(
        await getForecastSnapshot(
          lookbackWindow: lookbackWindow,
          limit: limit,
        ),
      );
    }

    controller = StreamController<ForecastKernelAdminSnapshot>.broadcast(
      onListen: () async {
        await emit();
        timer = Timer.periodic(refreshInterval, (_) {
          unawaited(emit());
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  ForecastKernelAdminForecastRow _rowFromRecord(
    ForecastIssuedForecastRecord record,
  ) {
    final diagnostics = record.diagnostics;
    final snapshotJson =
        diagnostics.metadata['calibration_snapshot'] as Map<String, dynamic>?;
    final skillLowerConfidenceBound = snapshotJson == null
        ? diagnostics.skillLowerConfidenceBound
        : (snapshotJson['skillLowerConfidenceBound'] as num?)?.toDouble() ??
            diagnostics.skillLowerConfidenceBound;
    final warmingUp = snapshotJson == null
        ? false
        : snapshotJson['warmingUp'] as bool? ?? false;
    final truthScope = record.truthScope;
    final representationMix =
        (record.metadata['representation_mix'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
            ) ??
            (diagnostics.metadata['representation_mix'] as Map?)?.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
            ) ??
            const <String, int>{};
    return ForecastKernelAdminForecastRow(
      forecastId: record.forecastId,
      subjectId: record.subjectId,
      forecastFamilyId: record.forecastFamilyId,
      truthScope: truthScope,
      sphereId: record.sphereId,
      governanceStratum: truthScope.governanceStratum,
      agentClass: truthScope.agentClass,
      tenantScope: truthScope.tenantScope,
      tenantId: truthScope.tenantId,
      predictedOutcome: record.predictedOutcome,
      band: forecastStrengthBandFor(record.forecastStrength),
      disposition: record.metadata['disposition']?.toString() ?? 'unknown',
      issuedAt: record.issuedAt,
      outcomeProbability:
          (record.metadata['outcome_probability'] as num?)?.toDouble() ??
              record.calibratedPredictiveDistribution.topProbability,
      forecastStrength: record.forecastStrength,
      actionability: record.actionability,
      supportQuality: record.supportQuality,
      calibrationGap: diagnostics.calibrationGap,
      changeRisk: diagnostics.changePointProbability,
      skillLowerConfidenceBound: skillLowerConfidenceBound,
      warmingUp: warmingUp,
      representationMix: representationMix,
    );
  }

  double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) {
      return 0.0;
    }
    return list.reduce((left, right) => left + right) / list.length;
  }
}
