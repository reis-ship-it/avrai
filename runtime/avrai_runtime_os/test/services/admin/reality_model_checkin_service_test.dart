import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/services/admin/reality_model_checkin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback response includes active reality-model contract context',
      () async {
    final service = RealityModelCheckInService(
      realityModelPort: _FakeRealityModelPort(),
    );

    final response = await service.checkIn(
      layer: 'reality',
      prompt: '',
      context: const <String, dynamic>{},
      approvedGroupings: const <String>['music_cluster'],
    );

    expect(response, contains('reality_model_test_contract'));
    expect(response, contains('allows 4 evidence refs'));
  });
}

class _FakeRealityModelPort implements RealityModelPort {
  @override
  Future<RealityModelContract> getActiveContract() async {
    return const RealityModelContract(
      contractId: 'reality_model_test_contract',
      version: 'test-v1',
      supportedDomains: <RealityModelDomain>[RealityModelDomain.locality],
      rendererKinds: <RealityExplanationRendererKind>[
        RealityExplanationRendererKind.template,
      ],
      uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
      followUpQuestionsAllowed: true,
      maxEvidenceRefs: 4,
      maxHighlights: 2,
    );
  }

  @override
  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RealityDecisionTrace> traceDecision({
    required RealityModelEvaluationRequest request,
    required RealityModelEvaluation evaluation,
    required RealityDecisionDisposition disposition,
    required List<String> evidenceRefs,
    String? localityCode,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  }) {
    throw UnimplementedError();
  }
}
