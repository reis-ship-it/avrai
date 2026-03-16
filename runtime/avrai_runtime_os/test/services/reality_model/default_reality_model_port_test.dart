import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultRealityModelPort', () {
    final port = DefaultRealityModelPort();
    const validator = RealityModelBoundaryValidator();

    test('returns a valid active contract', () async {
      final contract = await port.getActiveContract();

      expect(contract.contractId, 'reality_model_wave1_bham_beta');
      expect(contract.maxEvidenceRefs, 5);
      expect(contract.rendererKinds, <RealityExplanationRendererKind>[
        RealityExplanationRendererKind.template
      ]);
      expect(validator.validateContract(contract).isValid, isTrue);
    });

    test('produces bounded evaluation, trace, and explanation', () async {
      final request = RealityModelEvaluationRequest(
        requestId: 'request-1',
        subjectId: 'admin-operator',
        domain: RealityModelDomain.event,
        candidateRef: 'event:spring-in-bham',
        localityCode: 'bham_downtown',
        cityCode: 'bham',
        signalTags: const <String>['music', 'spring', 'outdoor'],
        evidenceRefs: const <String>[
          'tuple:1',
          'tuple:2',
          'tuple:3',
          'tuple:4',
          'tuple:5',
          'tuple:6',
        ],
        requestedAtUtc: DateTime.utc(2026, 3, 15, 2),
      );

      final evaluation = await port.evaluate(request);
      final trace = await port.traceDecision(
        request: request,
        evaluation: evaluation,
        disposition: RealityDecisionDisposition.recommend,
        evidenceRefs: evaluation.supportingEvidenceRefs,
        localityCode: request.localityCode,
      );
      final explanation = await port.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: RealityExplanationRendererKind.template,
      );

      expect(evaluation.supportingEvidenceRefs, hasLength(5));
      expect(evaluation.score, inInclusiveRange(0.0, 1.0));
      expect(evaluation.confidence, inInclusiveRange(0.0, 1.0));
      expect(trace.localityCode, 'bham_downtown');
      expect(explanation.summary, contains('event / spring-in-bham'));
      expect(explanation.highlights.length, lessThanOrEqualTo(3));
      expect(validator.validateEvaluation(evaluation).isValid, isTrue);
      expect(validator.validateTrace(trace).isValid, isTrue);
      expect(validator.validateExplanation(explanation).isValid, isTrue);
    });
  });
}
