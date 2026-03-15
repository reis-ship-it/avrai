import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_action_training_service.dart';

class BhamReplayHoldoutEvaluationService {
  const BhamReplayHoldoutEvaluationService();

  static const List<String> _trainingMonths = <String>[
    '2023-01',
    '2023-02',
    '2023-04',
    '2023-05',
    '2023-07',
    '2023-08',
    '2023-10',
    '2023-11',
  ];
  static const List<String> _validationMonths = <String>['2023-03', '2023-09'];
  static const List<String> _holdoutMonths = <String>['2023-06', '2023-12'];

  ReplayHoldoutEvaluationReport buildReport({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPlaceGraph placeGraph,
    required ReplayDailyBehaviorBatch dailyBehaviorBatch,
    required ReplayExchangeSummary exchangeSummary,
    required ReplayPhysicalMovementReport physicalMovementReport,
    required BhamReplayActionTrainingBundle trainingBundle,
  }) {
    final metrics = <ReplayHoldoutMetric>[
      _eventDensityMetric(dailyBehaviorBatch),
      _attendanceMetric(trainingBundle),
      _localityPressureMetric(dailyBehaviorBatch),
      _venueCommunityParticipationMetric(trainingBundle),
      _exchangeParticipationMetric(exchangeSummary),
      _offlineQueueMetric(exchangeSummary, trainingBundle),
    ];
    final passed = metrics.every((metric) => metric.passed);
    return ReplayHoldoutEvaluationReport(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      trainingMonths: _trainingMonths,
      validationMonths: _validationMonths,
      holdoutMonths: _holdoutMonths,
      passed: passed,
      metrics: metrics,
      notes: <String>[
        if (passed)
          'Held-out 2023 windows stay within replay variation thresholds.'
        else
          'One or more held-out 2023 windows deviate beyond replay thresholds.',
      ],
      metadata: <String, dynamic>{
        'placeNodeCount': placeGraph.nodeCount,
        'movementCount': physicalMovementReport.movements.length,
        'untrackedWindowCount': physicalMovementReport.untrackedWindows.length,
      },
    );
  }

  ReplayHoldoutMetric _eventDensityMetric(ReplayDailyBehaviorBatch batch) {
    final trainingValue = _averageMonthlyMatchCount(
      _trainingMonths,
      batch.actions,
      match: (action) => action.destinationChoice.entityType == 'event',
    );
    final validationValue = _averageMonthlyMatchCount(
      _validationMonths,
      batch.actions,
      match: (action) => action.destinationChoice.entityType == 'event',
    );
    final holdoutValue = _averageMonthlyMatchCount(
      _holdoutMonths,
      batch.actions,
      match: (action) => action.destinationChoice.entityType == 'event',
    );
    return _metric(
      metricId: 'holdout:event_density',
      metricName: 'event_density',
      trainingValue: trainingValue,
      validationValue: validationValue,
      holdoutValue: holdoutValue,
      threshold: 0.35,
    );
  }

  ReplayHoldoutMetric _attendanceMetric(
    BhamReplayActionTrainingBundle trainingBundle,
  ) {
    final outcomesById = <String, ReplayOutcomeLabel>{
      for (final label in trainingBundle.outcomeLabels) label.labelId: label,
    };

    double attendanceRate(List<String> months) {
      final relevant = trainingBundle.records
          .where((record) => months.contains(record.monthKey))
          .where((record) => record.chosenType == 'event')
          .where((record) => outcomesById.containsKey(record.outcomeRef))
          .map((record) => outcomesById[record.outcomeRef]!)
          .where((label) => label.outcomeKind == 'attendance')
          .toList(growable: false);
      if (relevant.isEmpty) {
        return 0;
      }
      final positive = relevant
          .where((label) => label.outcomeValue == 'attended')
          .length;
      return positive / relevant.length;
    }

    return _metric(
      metricId: 'holdout:attendance_plausibility',
      metricName: 'attendance_plausibility',
      trainingValue: attendanceRate(_trainingMonths),
      validationValue: attendanceRate(_validationMonths),
      holdoutValue: attendanceRate(_holdoutMonths),
      threshold: 0.2,
    );
  }

  ReplayHoldoutMetric _localityPressureMetric(ReplayDailyBehaviorBatch batch) {
    double densityForMonths(List<String> months) {
      if (months.isEmpty) {
        return 0;
      }
      var total = 0.0;
      for (final month in months) {
        final localityCounts = <String, int>{};
        for (final action in batch.actions.where(
          (entry) => entry.monthKey == month,
        )) {
          localityCounts[action.localityAnchor] =
              (localityCounts[action.localityAnchor] ?? 0) + 1;
        }
        if (localityCounts.isNotEmpty) {
          total += localityCounts.values.reduce((a, b) => a + b) /
              localityCounts.length;
        }
      }
      return total / months.length;
    }

    return _metric(
      metricId: 'holdout:locality_pressure',
      metricName: 'locality_pressure',
      trainingValue: densityForMonths(_trainingMonths),
      validationValue: densityForMonths(_validationMonths),
      holdoutValue: densityForMonths(_holdoutMonths),
      threshold: 0.25,
    );
  }

  ReplayHoldoutMetric _venueCommunityParticipationMetric(
    BhamReplayActionTrainingBundle trainingBundle,
  ) {
    final totalActors = trainingBundle.records
        .map((record) => record.actorId)
        .toSet()
        .length;

    double participationForMonths(List<String> months) {
      if (months.isEmpty || totalActors == 0) {
        return 0;
      }
      var totalRatio = 0.0;
      for (final month in months) {
        final relevant = trainingBundle.records
            .where((record) => record.monthKey == month)
            .where(
              (record) =>
                  record.chosenType == 'venue' ||
                  record.chosenType == 'community',
            )
            .length;
        totalRatio += relevant / totalActors;
      }
      return totalRatio / months.length;
    }

    final trainingValue = participationForMonths(_trainingMonths);
    final validationValue = participationForMonths(_validationMonths);
    final holdoutValue = participationForMonths(_holdoutMonths);
    const threshold = 0.03;
    final validationDelta = (validationValue - trainingValue).abs();
    final holdoutDelta = (holdoutValue - trainingValue).abs();
    return ReplayHoldoutMetric(
      metricId: 'holdout:venue_community_participation',
      metricName: 'venue_community_participation',
      trainingValue: trainingValue,
      validationValue: validationValue,
      holdoutValue: holdoutValue,
      threshold: threshold,
      passed: validationDelta <= threshold && holdoutDelta <= threshold,
      metadata: <String, dynamic>{
        'validationDeltaAbs': validationDelta,
        'holdoutDeltaAbs': holdoutDelta,
        'comparisonMode': 'absolute_participation_band',
      },
    );
  }

  ReplayHoldoutMetric _exchangeParticipationMetric(
    ReplayExchangeSummary exchangeSummary,
  ) {
    final totalActors =
        (exchangeSummary.metadata['totalModeledActors'] as num?)?.toDouble() ??
        0;
    final actorsWithExchange = exchangeSummary.actorsWithAnyExchange.toDouble();
    final baseline = totalActors == 0 ? 0 : actorsWithExchange / totalActors;
    return ReplayHoldoutMetric(
      metricId: 'holdout:exchange_participation',
      metricName: 'exchange_participation',
      trainingValue: baseline.toDouble(),
      validationValue: baseline.toDouble(),
      holdoutValue: baseline.toDouble(),
      threshold: 0.0,
      passed: baseline > 0 && baseline < 0.9,
      metadata: <String, dynamic>{'actorsWithAnyExchange': actorsWithExchange},
    );
  }

  ReplayHoldoutMetric _offlineQueueMetric(
    ReplayExchangeSummary exchangeSummary,
    BhamReplayActionTrainingBundle trainingBundle,
  ) {
    final total = exchangeSummary.totalExchangeEvents;
    final queued = trainingBundle.outcomeLabels
        .where((label) => label.outcomeValue == 'queued_offline')
        .length;
    final rate = total == 0 ? 0 : queued / total;
    return ReplayHoldoutMetric(
      metricId: 'holdout:offline_queue_behavior',
      metricName: 'offline_queue_behavior',
      trainingValue: rate.toDouble(),
      validationValue: rate.toDouble(),
      holdoutValue: rate.toDouble(),
      threshold: 0.0,
      passed: rate > 0 && rate < 0.75,
      metadata: <String, dynamic>{
        'offlineQueuedCount': queued,
        'exchangeEventCount': total,
      },
    );
  }

  ReplayHoldoutMetric _metric({
    required String metricId,
    required String metricName,
    required double trainingValue,
    required double validationValue,
    required double holdoutValue,
    required double threshold,
  }) {
    final baseline = trainingValue.abs() < 0.000001 ? 1.0 : trainingValue.abs();
    final validationDelta = ((validationValue - trainingValue).abs()) / baseline;
    final holdoutDelta = ((holdoutValue - trainingValue).abs()) / baseline;
    final passed = validationDelta <= threshold && holdoutDelta <= threshold;
    return ReplayHoldoutMetric(
      metricId: metricId,
      metricName: metricName,
      trainingValue: trainingValue,
      validationValue: validationValue,
      holdoutValue: holdoutValue,
      threshold: threshold,
      passed: passed,
      metadata: <String, dynamic>{
        'validationDeltaPct': validationDelta,
        'holdoutDeltaPct': holdoutDelta,
      },
    );
  }

  double _averageMonthlyMatchCount(
    List<String> months,
    Iterable<ReplayActorAction> actions, {
    required bool Function(ReplayActorAction action) match,
  }) {
    if (months.isEmpty) {
      return 0;
    }
    var total = 0.0;
    for (final month in months) {
      final count = actions
          .where((action) => action.monthKey == month)
          .where(match)
          .length;
      total += count;
    }
    return total / months.length;
  }
}
