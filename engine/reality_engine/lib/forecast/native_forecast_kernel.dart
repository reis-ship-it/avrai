import 'package:avrai_core/avra_core.dart';
import 'package:reality_engine/forecast/baseline_forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_kernel.dart';
import 'package:reality_engine/forecast/forecast_native_priority.dart';
import 'package:reality_engine/forecast/forecast_native_support.dart';

class NativeForecastKernel implements ForecastKernel {
  NativeForecastKernel({
    required this.nativeBridge,
    required this.fallback,
    this.policy = const ForecastNativeExecutionPolicy(),
  });

  final ForecastKernelJsonNativeBridge nativeBridge;
  final ForecastKernel fallback;
  final ForecastNativeExecutionPolicy policy;

  @override
  Future<ForecastKernelResult> forecast(ForecastKernelRequest request) async {
    nativeBridge.initialize();
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
    if (!nativeBridge.isAvailable) {
      policy.verifyFallbackAllowed(
        syscall: 'forecast',
        reason: 'native_unavailable',
      );
      final fallbackResult = await fallback.forecast(request);
      return ForecastKernelResult(
        claim: fallbackResult.claim,
        predictedOutcome: fallbackResult.predictedOutcome,
        confidence: fallbackResult.confidence,
        branchId: fallbackResult.branchId,
        runId: fallbackResult.runId,
        explanation: fallbackResult.explanation,
        forecastFamilyId: fallbackResult.forecastFamilyId,
        outcomeProbability: fallbackResult.outcomeProbability,
        outcomeKind: fallbackResult.outcomeKind,
        rawPredictiveDistribution: fallbackResult.rawPredictiveDistribution,
        calibratedPredictiveDistribution:
            fallbackResult.calibratedPredictiveDistribution,
        forecastStrength: fallbackResult.forecastStrength,
        actionability: fallbackResult.actionability,
        diagnostics: fallbackResult.diagnostics,
        decisionSpec: fallbackResult.decisionSpec,
        truthScope: fallbackResult.truthScope ?? truthScope,
        contradictionHooks: fallbackResult.contradictionHooks,
        metadata: <String, dynamic>{
          ...fallbackResult.metadata,
          'forecast_kernel_wrapper': 'native_forecast_kernel',
          'forecast_kernel_execution_mode': 'fallback',
          if (ai2aiRuntimeStateSummary != null &&
              !fallbackResult.metadata
                  .containsKey('ai2ai_runtime_state_summary'))
            'ai2ai_runtime_state_summary': ai2aiRuntimeStateSummary,
          if (meshRuntimeStateSummary != null &&
              !fallbackResult.metadata
                  .containsKey('mesh_runtime_state_summary'))
            'mesh_runtime_state_summary': meshRuntimeStateSummary,
        },
      );
    }

    final response = nativeBridge.invoke(
      syscall: 'forecast',
      payload: <String, dynamic>{
        'forecast_id': request.forecastId,
        'subject_id': request.subjectId,
        'replay_envelope': request.replayEnvelope.toJson(),
        'run_context': request.runContext.toJson(),
        'target_window': request.targetWindow.toJson(),
        'evidence_window': request.evidenceWindow.toJson(),
        'forecast_family_id': request.forecastFamilyId,
        'outcome_kind': request.outcomeKind.name,
        'truth_scope': truthScope.toJson(),
        'metadata': request.metadata,
      },
    );

    if (response['handled'] != true) {
      policy.verifyFallbackAllowed(
        syscall: 'forecast',
        reason: 'native_deferred',
      );
      final fallbackResult = await fallback.forecast(request);
      return ForecastKernelResult(
        claim: fallbackResult.claim,
        predictedOutcome: fallbackResult.predictedOutcome,
        confidence: fallbackResult.confidence,
        branchId: fallbackResult.branchId,
        runId: fallbackResult.runId,
        explanation: fallbackResult.explanation,
        forecastFamilyId: fallbackResult.forecastFamilyId,
        outcomeProbability: fallbackResult.outcomeProbability,
        outcomeKind: fallbackResult.outcomeKind,
        rawPredictiveDistribution: fallbackResult.rawPredictiveDistribution,
        calibratedPredictiveDistribution:
            fallbackResult.calibratedPredictiveDistribution,
        forecastStrength: fallbackResult.forecastStrength,
        actionability: fallbackResult.actionability,
        diagnostics: fallbackResult.diagnostics,
        decisionSpec: fallbackResult.decisionSpec,
        truthScope: fallbackResult.truthScope ?? truthScope,
        contradictionHooks: fallbackResult.contradictionHooks,
        metadata: <String, dynamic>{
          ...fallbackResult.metadata,
          'forecast_kernel_wrapper': 'native_forecast_kernel',
          'forecast_kernel_execution_mode': 'fallback',
          if (ai2aiRuntimeStateSummary != null &&
              !fallbackResult.metadata
                  .containsKey('ai2ai_runtime_state_summary'))
            'ai2ai_runtime_state_summary': ai2aiRuntimeStateSummary,
          if (meshRuntimeStateSummary != null &&
              !fallbackResult.metadata
                  .containsKey('mesh_runtime_state_summary'))
            'mesh_runtime_state_summary': meshRuntimeStateSummary,
        },
      );
    }

    final payload = Map<String, dynamic>.from(
      response['payload'] as Map? ?? const <String, dynamic>{},
    );
    final resultMetadata = Map<String, dynamic>.from(
      payload['metadata'] as Map<String, dynamic>? ?? const {},
    );
    final outcomeProbability =
        (payload['outcome_probability'] as num?)?.toDouble() ??
            (payload['confidence'] as num?)?.toDouble();
    final rawDistribution = payload['raw_predictive_distribution'] is Map
        ? ForecastPredictiveDistribution.fromJson(
            Map<String, dynamic>.from(
              payload['raw_predictive_distribution'] as Map,
            ),
          )
        : _fallbackDistribution(
            outcomeProbability: outcomeProbability ?? 0.5,
            outcomeKind: request.outcomeKind,
          );
    final calibratedDistribution =
        payload['calibrated_predictive_distribution'] is Map
            ? ForecastPredictiveDistribution.fromJson(
                Map<String, dynamic>.from(
                  payload['calibrated_predictive_distribution'] as Map,
                ),
              )
            : rawDistribution;
    final diagnostics = payload['diagnostics'] is Map
        ? ForecastStrengthDiagnostics.fromJson(
            Map<String, dynamic>.from(payload['diagnostics'] as Map),
          )
        : null;
    return ForecastKernelResult(
      claim: ForecastTemporalClaim.fromJson(
        Map<String, dynamic>.from(payload['claim'] as Map? ?? const {}),
      ),
      predictedOutcome: payload['predicted_outcome'] as String? ?? 'unknown',
      confidence: (payload['confidence'] as num?)?.toDouble() ?? 0.0,
      branchId: payload['branch_id'] as String? ?? request.runContext.branchId,
      runId: payload['run_id'] as String? ?? request.runContext.runId,
      explanation: payload['explanation'] as String? ?? 'No explanation',
      forecastFamilyId:
          payload['forecast_family_id'] as String? ?? request.forecastFamilyId,
      outcomeProbability: outcomeProbability,
      outcomeKind: ForecastOutcomeKind.values.firstWhere(
        (value) => value.name == payload['outcome_kind'],
        orElse: () => request.outcomeKind,
      ),
      rawPredictiveDistribution: rawDistribution,
      calibratedPredictiveDistribution: calibratedDistribution,
      forecastStrength: (payload['forecast_strength'] as num?)?.toDouble(),
      actionability: (payload['actionability'] as num?)?.toDouble() ?? 0.0,
      diagnostics: diagnostics,
      decisionSpec: request.decisionSpec,
      truthScope: payload['truth_scope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(payload['truth_scope'] as Map),
            )
          : (payload['claim'] is Map
              ? ForecastTemporalClaim.fromJson(
                      Map<String, dynamic>.from(payload['claim'] as Map))
                  .truthScope
              : truthScope),
      contradictionHooks: (payload['contradiction_hooks'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: <String, dynamic>{
        ...resultMetadata,
        if (!resultMetadata.containsKey('forecast_kernel_id'))
          'forecast_kernel_id': 'native_forecast_kernel',
        if (!resultMetadata.containsKey('forecast_kernel_execution_mode'))
          'forecast_kernel_execution_mode': 'native',
        if (!resultMetadata.containsKey('truth_scope'))
          'truth_scope': truthScope.toJson(),
        if (ai2aiRuntimeStateSummary != null &&
            !resultMetadata.containsKey('ai2ai_runtime_state_summary'))
          'ai2ai_runtime_state_summary': ai2aiRuntimeStateSummary,
        if (meshRuntimeStateSummary != null &&
            !resultMetadata.containsKey('mesh_runtime_state_summary'))
          'mesh_runtime_state_summary': meshRuntimeStateSummary,
      },
    );
  }

  ForecastPredictiveDistribution _fallbackDistribution({
    required double outcomeProbability,
    required ForecastOutcomeKind outcomeKind,
  }) {
    return ForecastPredictiveDistribution(
      outcomeKind: outcomeKind,
      discreteProbabilities: <String, double>{
        'positive': outcomeProbability.clamp(0.0, 1.0),
        'negative': (1.0 - outcomeProbability).clamp(0.0, 1.0),
      },
      mean: outcomeProbability.clamp(0.0, 1.0),
      variance: outcomeProbability.clamp(0.0, 1.0) *
          (1.0 - outcomeProbability.clamp(0.0, 1.0)),
      representationComponent: ForecastRepresentationComponent.classical,
    );
  }
}

NativeForecastKernel buildNativeForecastKernel({
  ForecastKernelJsonNativeBridge? nativeBridge,
  ForecastKernel? fallback,
  ForecastNativeExecutionPolicy policy = const ForecastNativeExecutionPolicy(),
}) {
  return NativeForecastKernel(
    nativeBridge: nativeBridge ?? ForecastKernelJsonNativeBridge(),
    fallback: fallback ?? const BaselineForecastKernel(),
    policy: policy,
  );
}
