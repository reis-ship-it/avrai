import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_core/models/temporal/forecast_predictive_distribution.dart';
import 'package:avrai_core/models/temporal/forecast_strength_diagnostics.dart';
import 'package:avrai_core/models/temporal/replay_temporal_envelope.dart';
import 'package:avrai_core/models/temporal/temporal_interval.dart';
import 'package:avrai_core/models/temporal/temporal_uncertainty.dart';
import 'package:avrai_core/models/truth/truth_scope_descriptor.dart';

class ForecastEvaluationTrace {
  const ForecastEvaluationTrace({
    required this.traceId,
    required this.forecastId,
    required this.subjectId,
    required this.replayEnvelope,
    required this.runContext,
    required this.validityWindow,
    required this.uncertainty,
    required this.explanation,
    this.truthScope,
    this.forecastFamilyId,
    this.rawPredictiveDistribution,
    this.calibratedPredictiveDistribution,
    this.diagnostics,
    this.inputSourceRefs = const <String>[],
    this.contradictionHooks = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String traceId;
  final String forecastId;
  final String subjectId;
  final ReplayTemporalEnvelope replayEnvelope;
  final MonteCarloRunContext runContext;
  final TemporalInterval validityWindow;
  final TemporalUncertainty uncertainty;
  final String explanation;
  final TruthScopeDescriptor? truthScope;
  final String? forecastFamilyId;
  final ForecastPredictiveDistribution? rawPredictiveDistribution;
  final ForecastPredictiveDistribution? calibratedPredictiveDistribution;
  final ForecastStrengthDiagnostics? diagnostics;
  final List<String> inputSourceRefs;
  final List<String> contradictionHooks;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'traceId': traceId,
      'forecastId': forecastId,
      'subjectId': subjectId,
      'replayEnvelope': replayEnvelope.toJson(),
      'runContext': runContext.toJson(),
      'validityWindow': validityWindow.toJson(),
      'uncertainty': uncertainty.toJson(),
      'explanation': explanation,
      'truthScope': truthScope?.toJson(),
      'forecastFamilyId': forecastFamilyId,
      'rawPredictiveDistribution': rawPredictiveDistribution?.toJson(),
      'calibratedPredictiveDistribution':
          calibratedPredictiveDistribution?.toJson(),
      'diagnostics': diagnostics?.toJson(),
      'inputSourceRefs': inputSourceRefs,
      'contradictionHooks': contradictionHooks,
      'metadata': metadata,
    };
  }

  factory ForecastEvaluationTrace.fromJson(Map<String, dynamic> json) {
    return ForecastEvaluationTrace(
      traceId: json['traceId'] as String? ?? '',
      forecastId: json['forecastId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      replayEnvelope: ReplayTemporalEnvelope.fromJson(
        Map<String, dynamic>.from(json['replayEnvelope'] as Map? ?? const {}),
      ),
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      validityWindow: TemporalInterval.fromJson(
        Map<String, dynamic>.from(json['validityWindow'] as Map? ?? const {}),
      ),
      uncertainty: TemporalUncertainty.fromJson(
        Map<String, dynamic>.from(json['uncertainty'] as Map? ?? const {}),
      ),
      explanation: json['explanation'] as String? ?? '',
      truthScope: json['truthScope'] is Map
          ? TruthScopeDescriptor.fromJson(
              Map<String, dynamic>.from(json['truthScope'] as Map),
            )
          : null,
      forecastFamilyId: json['forecastFamilyId'] as String?,
      rawPredictiveDistribution: json['rawPredictiveDistribution'] is Map
          ? ForecastPredictiveDistribution.fromJson(
              Map<String, dynamic>.from(
                json['rawPredictiveDistribution'] as Map,
              ),
            )
          : null,
      calibratedPredictiveDistribution:
          json['calibratedPredictiveDistribution'] is Map
              ? ForecastPredictiveDistribution.fromJson(
                  Map<String, dynamic>.from(
                    json['calibratedPredictiveDistribution'] as Map,
                  ),
                )
              : null,
      diagnostics: json['diagnostics'] is Map
          ? ForecastStrengthDiagnostics.fromJson(
              Map<String, dynamic>.from(json['diagnostics'] as Map),
            )
          : null,
      inputSourceRefs: (json['inputSourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      contradictionHooks: (json['contradictionHooks'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
