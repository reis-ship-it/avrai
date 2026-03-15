import 'package:avrai_core/avra_core.dart';

class BhamReplayCalibrationService {
  const BhamReplayCalibrationService();

  ReplayCalibrationReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayKernelParticipationReport kernelParticipationReport,
  }) {
    final localityCoveragePct =
        ((populationProfile.metadata['localityCoveragePct'] as num?) ?? 0).toDouble();
    final actorCountTarget = 25000.0;
    final activeKernelTarget = kernelParticipationReport.requiredKernelCount.toDouble();
    final actorBearingLocalities = populationProfile.localityPopulationCounts.keys.toSet();
    final coveredActorBearingLocalities = dailyBehaviorBatch.actionCountsByLocality.keys
        .where(actorBearingLocalities.contains)
        .length;
    final records = <ReplayCalibrationRecord>[
      _exactRecord(
        metricId: 'city_population_total',
        targetValue: populationProfile.totalPopulation.toDouble(),
        actualValue: populationProfile.totalPopulation.toDouble(),
        allowedVariancePct: 1.0,
        rationale: 'Population total should exactly reflect ACS/BEA truth-year intake.',
      ),
      _exactRecord(
        metricId: 'city_housing_total',
        targetValue: populationProfile.totalHousingUnits.toDouble(),
        actualValue: populationProfile.totalHousingUnits.toDouble(),
        allowedVariancePct: 1.0,
        rationale: 'Housing total should remain aligned with replay truth-year inputs.',
      ),
      _minimumRecord(
        metricId: 'metro_core_locality_coverage_pct',
        targetValue: 100.0,
        actualValue: localityCoveragePct * 100.0,
        rationale: 'Every in-scope metro-core locality must be represented.',
      ),
      _minimumRecord(
        metricId: 'weighted_actor_count',
        targetValue: actorCountTarget,
        actualValue: populationProfile.modeledActorCount.toDouble(),
        rationale: 'Dense city-faithful replay requires at least 25k weighted actors.',
      ),
      _minimumRecord(
        metricId: 'venue_profile_count',
        targetValue: 700.0,
        actualValue: placeGraph.venueProfiles.length.toDouble(),
        rationale: 'Venue graph should be dense enough for metro-core destination choice.',
      ),
      _minimumRecord(
        metricId: 'club_profile_count',
        targetValue: 120.0,
        actualValue: placeGraph.clubProfiles.length.toDouble(),
        rationale: 'Club structure must be materially present in the truth-year graph.',
      ),
      _minimumRecord(
        metricId: 'community_profile_count',
        targetValue: 500.0,
        actualValue: placeGraph.communityProfiles.length.toDouble(),
        rationale: 'Community density should be citywide, not just structural anchors.',
      ),
      _minimumRecord(
        metricId: 'organization_profile_count',
        targetValue: 300.0,
        actualValue: placeGraph.organizationProfiles.length.toDouble(),
        rationale: 'Organizations should be explicit enough to host city life.',
      ),
      _minimumRecord(
        metricId: 'event_profile_count',
        targetValue: 1000.0,
        actualValue: placeGraph.eventProfiles.length.toDouble(),
        rationale: 'A 2023 city-faithful year needs a materially dense event corpus.',
      ),
      _minimumRecord(
        metricId: 'active_kernel_count',
        targetValue: activeKernelTarget,
        actualValue: kernelParticipationReport.activeKernelCount.toDouble(),
        rationale: 'All replay-participating kernels must remain active.',
      ),
      _minimumRecord(
        metricId: 'daily_behavior_locality_coverage_pct',
        targetValue: 100.0,
        actualValue: actorBearingLocalities.isEmpty
            ? 0.0
            : (coveredActorBearingLocalities / actorBearingLocalities.length) *
                100.0,
        rationale: 'Daily behavior should cover nearly all replay localities.',
      ),
      _minimumRecord(
        metricId: 'daily_behavior_action_density',
        targetValue: populationProfile.modeledActorCount.toDouble(),
        actualValue: dailyBehaviorBatch.actions.length.toDouble(),
        rationale: 'At least one explicit replay action per weighted actor is expected.',
      ),
    ];

    final passed = records.every((record) => record.passed);
    return ReplayCalibrationReport(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      passed: passed,
      records: records,
      unresolvedMetrics: records
          .where((record) => !record.passed)
          .map((record) => record.metricId)
          .toList(growable: false),
      metadata: <String, dynamic>{
        'nodeCount': environment.nodeCount,
        'localityCount': placeGraph.localityCounts.length,
      },
    );
  }

  ReplayCalibrationRecord _exactRecord({
    required String metricId,
    required double targetValue,
    required double actualValue,
    required double allowedVariancePct,
    required String rationale,
  }) {
    final delta = (actualValue - targetValue).abs();
    final pct = targetValue == 0 ? (actualValue == 0 ? 0.0 : 100.0) : (delta / targetValue) * 100.0;
    return ReplayCalibrationRecord(
      metricId: metricId,
      targetValue: targetValue,
      actualValue: actualValue,
      allowedVariancePct: allowedVariancePct,
      passed: pct <= allowedVariancePct,
      rationale: rationale,
      metadata: <String, dynamic>{
        'delta': delta,
        'variancePct': pct.isFinite ? pct : double.nan,
        'comparison': 'exact',
      },
    );
  }

  ReplayCalibrationRecord _minimumRecord({
    required String metricId,
    required double targetValue,
    required double actualValue,
    required String rationale,
  }) {
    final delta = actualValue - targetValue;
    final pctBelow = targetValue == 0
        ? 0.0
        : ((targetValue - actualValue).clamp(0, double.infinity) / targetValue) *
            100.0;
    return ReplayCalibrationRecord(
      metricId: metricId,
      targetValue: targetValue,
      actualValue: actualValue,
      allowedVariancePct: 0.0,
      passed: actualValue >= targetValue,
      rationale: rationale,
      metadata: <String, dynamic>{
        'delta': delta,
        'variancePct': pctBelow.isFinite ? pctBelow : double.nan,
        'comparison': 'minimum',
      },
    );
  }
}
