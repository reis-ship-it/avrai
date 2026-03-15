import 'package:avrai_core/avra_core.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';

class BaselineForecastKernel implements ForecastKernel {
  const BaselineForecastKernel();

  @override
  Future<ForecastKernelResult> forecast(ForecastKernelRequest request) async {
    final truthScope = request.truthScope ??
        const TruthScopeRegistry().normalizeForecastScope(
          metadata: request.metadata,
          familyId: request.forecastFamilyId,
        );
    final ai2aiRuntimeStateSummary = request
            .metadata['ai2ai_runtime_state_summary'] as Map<String, dynamic>? ??
        (request.runContext.metadata['ai2ai_runtime_state_summary'] is Map
            ? Map<String, dynamic>.from(
                request.runContext.metadata['ai2ai_runtime_state_summary']
                    as Map,
              )
            : null);
    final meshRuntimeStateSummary = request
            .metadata['mesh_runtime_state_summary'] as Map<String, dynamic>? ??
        (request.runContext.metadata['mesh_runtime_state_summary'] is Map
            ? Map<String, dynamic>.from(
                request.runContext.metadata['mesh_runtime_state_summary']
                    as Map,
              )
            : null);
    final demandSignal =
        (request.replayEnvelope.metadata['demand_signal'] as num?)
                ?.toDouble() ??
            0.5;
    final certainty = request.replayEnvelope.uncertainty.confidence;
    final outcomeProbability = _clamp(
      (demandSignal * 0.75) + (certainty * 0.25),
    );
    final confidence = _clamp(
      (certainty * 0.65) + (demandSignal * 0.35),
    );
    final rawPredictiveDistribution = ForecastPredictiveDistribution(
      outcomeKind: request.outcomeKind,
      discreteProbabilities: <String, double>{
        'positive': outcomeProbability,
        'negative': _clamp(1.0 - outcomeProbability),
      },
      mean: outcomeProbability,
      variance: outcomeProbability * (1.0 - outcomeProbability),
      representationComponent: ForecastRepresentationComponent.classical,
      metadata: const <String, dynamic>{
        'generator': 'baseline_forecast_kernel'
      },
    );

    final claim = ForecastTemporalClaim(
      claimId: request.forecastId,
      forecastCreatedAt:
          request.replayEnvelope.observedAt.referenceTime.toUtc(),
      targetWindow: request.targetWindow,
      evidenceWindow: request.evidenceWindow,
      confidence: confidence,
      modelVersion: 'baseline_forecast_kernel_v1',
      provenance: TemporalProvenance(
        authority: TemporalAuthority.forecast,
        source: 'reality_engine.baseline_forecast_kernel',
      ),
      outcomeProbability: outcomeProbability,
      predictedOutcome: _predictedOutcomeFor(outcomeProbability),
      outcomeKind: request.outcomeKind,
      forecastFamilyId: request.forecastFamilyId,
      laterOutcomeRef: request.subjectId,
      truthScope: truthScope,
    );

    return ForecastKernelResult(
      claim: claim,
      predictedOutcome: _predictedOutcomeFor(outcomeProbability),
      confidence: confidence,
      branchId: request.runContext.branchId,
      runId: request.runContext.runId,
      explanation:
          'Baseline replay forecast using governed replay envelope and run context.',
      forecastFamilyId: request.forecastFamilyId,
      outcomeProbability: outcomeProbability,
      outcomeKind: request.outcomeKind,
      rawPredictiveDistribution: rawPredictiveDistribution,
      calibratedPredictiveDistribution: rawPredictiveDistribution,
      decisionSpec: request.decisionSpec,
      truthScope: truthScope,
      contradictionHooks: const <String>[
        'live_user_behavior',
        'locality_agent_override',
        'admin_ground_truth_override',
      ],
      metadata: <String, dynamic>{
        'forecast_kernel_id': 'baseline_forecast_kernel',
        'forecast_kernel_execution_mode': 'baseline',
        'canonical_replay_year': request.runContext.canonicalReplayYear,
        'replay_year': request.runContext.replayYear,
        'divergence_policy': request.runContext.divergencePolicy,
        'temporal_authority_source':
            request.replayEnvelope.temporalAuthoritySource,
        'truth_scope': truthScope.toJson(),
        if (ai2aiRuntimeStateSummary != null)
          'ai2ai_runtime_state_summary': ai2aiRuntimeStateSummary,
        if (meshRuntimeStateSummary != null)
          'mesh_runtime_state_summary': meshRuntimeStateSummary,
      },
    );
  }

  String _predictedOutcomeFor(double confidence) {
    if (confidence >= 0.85) {
      return 'high-confidence-positive';
    }
    if (confidence >= 0.6) {
      return 'moderate-confidence-positive';
    }
    return 'uncertain';
  }

  double _clamp(double value) {
    if (value < 0.0) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    return value;
  }
}
