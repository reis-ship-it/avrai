import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_core/models/temporal/replay_isolation_report.dart';
import 'package:avrai_core/models/temporal/replay_kernel_participation_report.dart';
import 'package:avrai_core/models/temporal/replay_actor_kernel_coverage_report.dart';
import 'package:avrai_core/models/temporal/replay_calibration_report.dart';
import 'package:avrai_core/models/temporal/replay_exchange.dart';
import 'package:avrai_core/models/temporal/replay_holdout_evaluation_report.dart';
import 'package:avrai_core/models/temporal/replay_place_graph.dart';
import 'package:avrai_core/models/temporal/replay_population_profile.dart';
import 'package:avrai_core/models/temporal/replay_realism_gate_report.dart';
import 'package:avrai_core/models/temporal/replay_stochastic_run_config.dart';

class ReplaySingleYearPassSummary {
  const ReplaySingleYearPassSummary({
    required this.environmentId,
    required this.replayYear,
    required this.runContext,
    required this.executedObservationCount,
    required this.forecastEvaluatedCount,
    required this.virtualNodeCount,
    required this.rollupCount,
    required this.behaviorActionCount,
    required this.dailyAgendaCount,
    required this.dailyActorActionCount,
    required this.closureOverrideCount,
    required this.monthCounts,
    required this.entityTypeCounts,
    required this.forecastDispositionCounts,
    required this.actionExplanationCount,
    required this.actionTrainingRecordCount,
    required this.counterfactualChoiceCount,
    required this.outcomeLabelCount,
    required this.truthDecisionRecordCount,
    required this.higherAgentInterventionTraceCount,
    required this.notes,
    this.populationProfile,
    this.placeGraph,
    this.isolationReport,
    this.kernelParticipationReport,
    this.actorKernelCoverageReport,
    this.exchangeSummary,
    this.realismGateReport,
    this.calibrationReport,
    this.stochasticRunConfig,
    this.variationProfile,
    this.holdoutEvaluationReport,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final MonteCarloRunContext runContext;
  final int executedObservationCount;
  final int forecastEvaluatedCount;
  final int virtualNodeCount;
  final int rollupCount;
  final int behaviorActionCount;
  final int dailyAgendaCount;
  final int dailyActorActionCount;
  final int closureOverrideCount;
  final Map<String, int> monthCounts;
  final Map<String, int> entityTypeCounts;
  final Map<String, int> forecastDispositionCounts;
  final int actionExplanationCount;
  final int actionTrainingRecordCount;
  final int counterfactualChoiceCount;
  final int outcomeLabelCount;
  final int truthDecisionRecordCount;
  final int higherAgentInterventionTraceCount;
  final List<String> notes;
  final ReplayPopulationProfile? populationProfile;
  final ReplayPlaceGraph? placeGraph;
  final ReplayIsolationReport? isolationReport;
  final ReplayKernelParticipationReport? kernelParticipationReport;
  final ReplayActorKernelCoverageReport? actorKernelCoverageReport;
  final ReplayExchangeSummary? exchangeSummary;
  final ReplayRealismGateReport? realismGateReport;
  final ReplayCalibrationReport? calibrationReport;
  final ReplayStochasticRunConfig? stochasticRunConfig;
  final ReplayVariationProfile? variationProfile;
  final ReplayHoldoutEvaluationReport? holdoutEvaluationReport;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'runContext': runContext.toJson(),
      'executedObservationCount': executedObservationCount,
      'forecastEvaluatedCount': forecastEvaluatedCount,
      'virtualNodeCount': virtualNodeCount,
      'rollupCount': rollupCount,
      'behaviorActionCount': behaviorActionCount,
      'dailyAgendaCount': dailyAgendaCount,
      'dailyActorActionCount': dailyActorActionCount,
      'closureOverrideCount': closureOverrideCount,
      'monthCounts': monthCounts,
      'entityTypeCounts': entityTypeCounts,
      'forecastDispositionCounts': forecastDispositionCounts,
      'actionExplanationCount': actionExplanationCount,
      'actionTrainingRecordCount': actionTrainingRecordCount,
      'counterfactualChoiceCount': counterfactualChoiceCount,
      'outcomeLabelCount': outcomeLabelCount,
      'truthDecisionRecordCount': truthDecisionRecordCount,
      'higherAgentInterventionTraceCount': higherAgentInterventionTraceCount,
      'notes': notes,
      'populationProfile': populationProfile?.toJson(),
      'placeGraph': placeGraph?.toJson(),
      'isolationReport': isolationReport?.toJson(),
      'kernelParticipationReport': kernelParticipationReport?.toJson(),
      'actorKernelCoverageReport': actorKernelCoverageReport?.toJson(),
      'exchangeSummary': exchangeSummary?.toJson(),
      'realismGateReport': realismGateReport?.toJson(),
      'calibrationReport': calibrationReport?.toJson(),
      'stochasticRunConfig': stochasticRunConfig?.toJson(),
      'variationProfile': variationProfile?.toJson(),
      'holdoutEvaluationReport': holdoutEvaluationReport?.toJson(),
      'metadata': metadata,
    };
  }

  factory ReplaySingleYearPassSummary.fromJson(Map<String, dynamic> json) {
    Map<String, int> readCounts(Object? raw) {
      return (raw as Map?)
              ?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
          const <String, int>{};
    }

    return ReplaySingleYearPassSummary(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      executedObservationCount:
          (json['executedObservationCount'] as num?)?.toInt() ?? 0,
      forecastEvaluatedCount:
          (json['forecastEvaluatedCount'] as num?)?.toInt() ?? 0,
      virtualNodeCount: (json['virtualNodeCount'] as num?)?.toInt() ?? 0,
      rollupCount: (json['rollupCount'] as num?)?.toInt() ?? 0,
      behaviorActionCount: (json['behaviorActionCount'] as num?)?.toInt() ?? 0,
      dailyAgendaCount: (json['dailyAgendaCount'] as num?)?.toInt() ?? 0,
      dailyActorActionCount:
          (json['dailyActorActionCount'] as num?)?.toInt() ?? 0,
      closureOverrideCount:
          (json['closureOverrideCount'] as num?)?.toInt() ?? 0,
      monthCounts: readCounts(json['monthCounts']),
      entityTypeCounts: readCounts(json['entityTypeCounts']),
      forecastDispositionCounts: readCounts(json['forecastDispositionCounts']),
      actionExplanationCount:
          (json['actionExplanationCount'] as num?)?.toInt() ?? 0,
      actionTrainingRecordCount:
          (json['actionTrainingRecordCount'] as num?)?.toInt() ?? 0,
      counterfactualChoiceCount:
          (json['counterfactualChoiceCount'] as num?)?.toInt() ?? 0,
      outcomeLabelCount: (json['outcomeLabelCount'] as num?)?.toInt() ?? 0,
      truthDecisionRecordCount:
          (json['truthDecisionRecordCount'] as num?)?.toInt() ?? 0,
      higherAgentInterventionTraceCount:
          (json['higherAgentInterventionTraceCount'] as num?)?.toInt() ?? 0,
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      populationProfile: json['populationProfile'] == null
          ? null
          : ReplayPopulationProfile.fromJson(
              Map<String, dynamic>.from(json['populationProfile'] as Map),
            ),
      placeGraph: json['placeGraph'] == null
          ? null
          : ReplayPlaceGraph.fromJson(
              Map<String, dynamic>.from(json['placeGraph'] as Map),
            ),
      isolationReport: json['isolationReport'] == null
          ? null
          : ReplayIsolationReport.fromJson(
              Map<String, dynamic>.from(json['isolationReport'] as Map),
            ),
      kernelParticipationReport: json['kernelParticipationReport'] == null
          ? null
          : ReplayKernelParticipationReport.fromJson(
              Map<String, dynamic>.from(
                  json['kernelParticipationReport'] as Map),
            ),
      actorKernelCoverageReport: json['actorKernelCoverageReport'] == null
          ? null
          : ReplayActorKernelCoverageReport.fromJson(
              Map<String, dynamic>.from(
                json['actorKernelCoverageReport'] as Map,
              ),
            ),
      exchangeSummary: json['exchangeSummary'] == null
          ? null
          : ReplayExchangeSummary.fromJson(
              Map<String, dynamic>.from(json['exchangeSummary'] as Map),
            ),
      realismGateReport: json['realismGateReport'] == null
          ? null
          : ReplayRealismGateReport.fromJson(
              Map<String, dynamic>.from(json['realismGateReport'] as Map),
            ),
      calibrationReport: json['calibrationReport'] == null
          ? null
          : ReplayCalibrationReport.fromJson(
              Map<String, dynamic>.from(json['calibrationReport'] as Map),
            ),
      stochasticRunConfig: json['stochasticRunConfig'] == null
          ? null
          : ReplayStochasticRunConfig.fromJson(
              Map<String, dynamic>.from(json['stochasticRunConfig'] as Map),
            ),
      variationProfile: json['variationProfile'] == null
          ? null
          : ReplayVariationProfile.fromJson(
              Map<String, dynamic>.from(json['variationProfile'] as Map),
            ),
      holdoutEvaluationReport: json['holdoutEvaluationReport'] == null
          ? null
          : ReplayHoldoutEvaluationReport.fromJson(
              Map<String, dynamic>.from(
                json['holdoutEvaluationReport'] as Map,
              ),
            ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
