import 'package:avrai_core/avra_core.dart';

abstract class ForecastKernel {
  Future<ForecastKernelResult> forecast(ForecastKernelRequest request);
}

class ForecastKernelRequest {
  const ForecastKernelRequest({
    required this.forecastId,
    required this.subjectId,
    required this.replayEnvelope,
    required this.runContext,
    required this.targetWindow,
    required this.evidenceWindow,
    this.forecastFamilyId = 'default_forecast_family',
    this.outcomeKind = ForecastOutcomeKind.binary,
    this.decisionSpec,
    this.truthScope,
    this.metadata = const <String, dynamic>{},
  });

  final String forecastId;
  final String subjectId;
  final ReplayTemporalEnvelope replayEnvelope;
  final MonteCarloRunContext runContext;
  final TemporalInterval targetWindow;
  final TemporalInterval evidenceWindow;
  final String forecastFamilyId;
  final ForecastOutcomeKind outcomeKind;
  final ForecastDecisionSpec? decisionSpec;
  final TruthScopeDescriptor? truthScope;
  final Map<String, dynamic> metadata;
}

class ForecastKernelResult {
  const ForecastKernelResult({
    required this.claim,
    required this.predictedOutcome,
    required this.confidence,
    required this.branchId,
    required this.runId,
    required this.explanation,
    this.forecastFamilyId = 'default_forecast_family',
    this.outcomeProbability,
    this.outcomeKind = ForecastOutcomeKind.binary,
    this.rawPredictiveDistribution,
    this.calibratedPredictiveDistribution,
    double? forecastStrength,
    this.actionability = 0.0,
    this.diagnostics,
    this.decisionSpec,
    this.truthScope,
    this.contradictionHooks = const <String>[],
    this.metadata = const <String, dynamic>{},
  }) : forecastStrength = forecastStrength ?? confidence;

  final ForecastTemporalClaim claim;
  final String predictedOutcome;
  final double confidence;
  final String branchId;
  final String runId;
  final String explanation;
  final String forecastFamilyId;
  final double? outcomeProbability;
  final ForecastOutcomeKind outcomeKind;
  final ForecastPredictiveDistribution? rawPredictiveDistribution;
  final ForecastPredictiveDistribution? calibratedPredictiveDistribution;
  final double forecastStrength;
  final double actionability;
  final ForecastStrengthDiagnostics? diagnostics;
  final ForecastDecisionSpec? decisionSpec;
  final TruthScopeDescriptor? truthScope;
  final List<String> contradictionHooks;
  final Map<String, dynamic> metadata;
}
