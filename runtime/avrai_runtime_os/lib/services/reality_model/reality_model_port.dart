import 'package:avrai_core/avra_core.dart';

abstract class RealityModelPort {
  Future<RealityModelContract> getActiveContract();

  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  );

  Future<RealityDecisionTrace> traceDecision({
    required RealityModelEvaluationRequest request,
    required RealityModelEvaluation evaluation,
    required RealityDecisionDisposition disposition,
    required List<String> evidenceRefs,
    String? localityCode,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  });

  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  });
}
