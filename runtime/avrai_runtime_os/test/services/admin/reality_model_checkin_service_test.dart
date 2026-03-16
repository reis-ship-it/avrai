import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:avrai_runtime_os/services/admin/reality_model_checkin_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback response includes active reality-model artifacts', () async {
    final service = RealityModelCheckInService(
      realityModelPort: _FakeRealityModelPort(),
    );

    final result = await service.runCheckIn(
      layer: 'reality',
      prompt: '',
      context: const <String, dynamic>{},
      approvedGroupings: const <String>['music_cluster'],
    );

    expect(result.response, contains('reality_model_test_contract'));
    expect(result.response, contains('allows 4 evidence refs'));
    expect(result.response, contains('Locality oversight remains bounded'));
    expect(result.contract?.contractId, 'reality_model_test_contract');
    expect(result.evaluation?.domain, RealityModelDomain.locality);
    expect(result.trace?.disposition, RealityDecisionDisposition.recommend);
    expect(result.explanation?.summary,
        contains('Locality oversight remains bounded'));
  });

  test('low-confidence evaluations remain in observe mode', () async {
    final service = RealityModelCheckInService(
      realityModelPort: _LowConfidenceRealityModelPort(),
    );

    final result = await service.runCheckIn(
      layer: 'reality',
      prompt: '',
      context: const <String, dynamic>{},
      approvedGroupings: const <String>['music_cluster'],
    );

    expect(result.trace?.disposition, RealityDecisionDisposition.observe);
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
  ) async {
    return RealityModelEvaluation(
      evaluationId: 'evaluation-1',
      requestId: request.requestId,
      contractId: 'reality_model_test_contract',
      domain: request.domain,
      candidateRef: request.candidateRef,
      score: 0.82,
      confidence: 0.74,
      uncertaintySummary: 'Bounded by deterministic test coverage.',
      supportingEvidenceRefs: request.evidenceRefs.take(4).toList(),
      generatedAtUtc: request.requestedAtUtc,
      localityCode: request.localityCode,
    );
  }

  @override
  Future<RealityDecisionTrace> traceDecision({
    required RealityModelEvaluationRequest request,
    required RealityModelEvaluation evaluation,
    required RealityDecisionDisposition disposition,
    required List<String> evidenceRefs,
    String? localityCode,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    return RealityDecisionTrace(
      traceId: 'trace-1',
      contractId: 'reality_model_test_contract',
      requestId: request.requestId,
      selectedEvaluationId: evaluation.evaluationId,
      selectedCandidateRef: evaluation.candidateRef,
      disposition: disposition,
      evidenceRefs: evidenceRefs,
      createdAtUtc: evaluation.generatedAtUtc,
      localityCode: localityCode,
      metadata: metadata,
    );
  }

  @override
  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  }) async {
    return RealityModelExplanation(
      explanationId: 'explanation-1',
      traceId: trace.traceId,
      evaluationId: evaluation.evaluationId,
      rendererKind: rendererKind,
      summary: 'Locality oversight remains bounded by replay-safe evidence.',
      highlights: const <String>[
        'Approved groupings were used as bounded evidence.',
      ],
      uncertaintySummary: evaluation.uncertaintySummary,
      createdAtUtc: evaluation.generatedAtUtc,
    );
  }
}

class _LowConfidenceRealityModelPort extends _FakeRealityModelPort {
  @override
  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  ) async {
    return RealityModelEvaluation(
      evaluationId: 'evaluation-low',
      requestId: request.requestId,
      contractId: 'reality_model_test_contract',
      domain: request.domain,
      candidateRef: request.candidateRef,
      score: 0.31,
      confidence: 0.33,
      uncertaintySummary: 'Thin bounded evidence.',
      supportingEvidenceRefs: request.evidenceRefs.take(2).toList(),
      generatedAtUtc: request.requestedAtUtc,
      localityCode: request.localityCode,
    );
  }
}
