import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

class GovernedForecastRuntimeResult {
  const GovernedForecastRuntimeResult({
    required this.selection,
    required this.projection,
  });

  final AuthoritativeReplayYearSelection selection;
  final ForecastGovernanceProjection projection;
}

class GovernedForecastRuntimeService {
  const GovernedForecastRuntimeService({
    required this.forecastGovernanceProjectionService,
    required this.replayYearSelectionService,
  });

  final ForecastGovernanceProjectionService forecastGovernanceProjectionService;
  final AuthoritativeReplayYearSelectionService replayYearSelectionService;

  Future<GovernedForecastRuntimeResult> evaluateBhamForecast({
    required ForecastKernelRequest request,
    required List<int> candidateYears,
    required List<ReplaySourceDescriptor> sources,
    List<GroundTruthOverrideRecord> overrideRecords = const <GroundTruthOverrideRecord>[],
  }) async {
    final selection = replayYearSelectionService.select(
      candidateYears: candidateYears,
      sources: sources,
    );

    final projection =
        await forecastGovernanceProjectionService.evaluateForecast(
      request: request,
      replayYearScore: selection.selectedScore,
      overrideRecords: overrideRecords,
    );

    return GovernedForecastRuntimeResult(
      selection: selection,
      projection: projection,
    );
  }
}
