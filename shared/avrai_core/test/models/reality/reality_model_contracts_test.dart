import 'package:avrai_core/models/reality/reality_model_contracts.dart';
import 'package:test/test.dart';

void main() {
  const validator = RealityModelBoundaryValidator();

  test('RealityModelContract normalizes domains, renderers, and limits', () {
    final contract = RealityModelContract(
      contractId: '  contract-1  ',
      version: ' v1 ',
      supportedDomains: const <RealityModelDomain>[
        RealityModelDomain.event,
        RealityModelDomain.event,
        RealityModelDomain.locality,
      ],
      rendererKinds: const <RealityExplanationRendererKind>[
        RealityExplanationRendererKind.template,
        RealityExplanationRendererKind.template,
        RealityExplanationRendererKind.offlineSlm,
      ],
      uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
      followUpQuestionsAllowed: true,
      maxEvidenceRefs: 0,
      maxHighlights: -2,
    ).normalized();

    expect(contract.contractId, 'contract-1');
    expect(contract.version, 'v1');
    expect(contract.supportedDomains, hasLength(2));
    expect(contract.rendererKinds, hasLength(2));
    expect(contract.maxEvidenceRefs, 1);
    expect(contract.maxHighlights, 1);
    expect(validator.validateContract(contract).isValid, isTrue);
  });

  test('RealityModelEvaluationRequest round-trips through json', () {
    final request = RealityModelEvaluationRequest(
      requestId: 'request-1',
      subjectId: 'user-1',
      domain: RealityModelDomain.place,
      candidateRef: 'spot:avondale-stage',
      localityCode: 'bham_avondale',
      cityCode: 'bham',
      signalTags: const <String>['  music  ', 'music', 'outdoor'],
      evidenceRefs: const <String>['tuple:1', ' tuple:1 ', 'tuple:2'],
      requestedAtUtc: DateTime.utc(2026, 3, 16, 3),
      metadata: const <String, dynamic>{'surface': 'beta_admin'},
    );

    final decoded = RealityModelEvaluationRequest.fromJson(request.toJson());

    expect(decoded.signalTags, <String>['music', 'outdoor']);
    expect(decoded.evidenceRefs, <String>['tuple:1', 'tuple:2']);
    expect(decoded.cityCode, 'bham');
    expect(validator.validateRequest(decoded).isValid, isTrue);
  });

  test('RealityModelEvaluation, trace, and explanation validate correctly', () {
    final evaluation = RealityModelEvaluation(
      evaluationId: 'evaluation-1',
      requestId: 'request-1',
      contractId: 'contract-1',
      domain: RealityModelDomain.event,
      candidateRef: 'event:spring-bham',
      score: 0.82,
      confidence: 0.74,
      uncertaintySummary: 'Bounded by current locality coverage.',
      supportingEvidenceRefs: const <String>['tuple:1', 'tuple:2'],
      generatedAtUtc: DateTime.utc(2026, 3, 16, 3, 5),
      localityCode: 'bham_downtown',
    );
    final trace = RealityDecisionTrace(
      traceId: 'trace-1',
      contractId: 'contract-1',
      requestId: 'request-1',
      selectedEvaluationId: 'evaluation-1',
      selectedCandidateRef: 'event:spring-bham',
      disposition: RealityDecisionDisposition.recommend,
      evidenceRefs: const <String>['tuple:1'],
      createdAtUtc: DateTime.utc(2026, 3, 16, 3, 6),
      localityCode: 'bham_downtown',
    );
    final explanation = RealityModelExplanation(
      explanationId: 'explanation-1',
      traceId: 'trace-1',
      evaluationId: 'evaluation-1',
      rendererKind: RealityExplanationRendererKind.template,
      summary: 'Spring Bham fits the current downtown-locality profile.',
      highlights: const <String>[
        'High fit with recent live-music demand.',
        'Confidence is bounded by replay-only priors.',
      ],
      uncertaintySummary: 'Ask follow-up if venue constraints change.',
      createdAtUtc: DateTime.utc(2026, 3, 16, 3, 7),
      followUpQuestion: 'Should this prefer outdoor-only venues?',
    );

    expect(
      RealityModelEvaluation.fromJson(evaluation.toJson()).candidateRef,
      'event:spring-bham',
    );
    expect(
      RealityDecisionTrace.fromJson(trace.toJson()).disposition,
      RealityDecisionDisposition.recommend,
    );
    expect(
      RealityModelExplanation.fromJson(explanation.toJson()).rendererKind,
      RealityExplanationRendererKind.template,
    );
    expect(validator.validateEvaluation(evaluation).isValid, isTrue);
    expect(validator.validateTrace(trace).isValid, isTrue);
    expect(validator.validateExplanation(explanation).isValid, isTrue);
  });

  test('validator rejects out-of-range scores and empty summaries', () {
    final evaluation = RealityModelEvaluation(
      evaluationId: 'evaluation-1',
      requestId: 'request-1',
      contractId: 'contract-1',
      domain: RealityModelDomain.business,
      candidateRef: 'business:test',
      score: 1.2,
      confidence: -0.1,
      uncertaintySummary: 'Invalid example',
      supportingEvidenceRefs: const <String>[],
      generatedAtUtc: DateTime.utc(2026, 3, 16),
    );
    final explanation = RealityModelExplanation(
      explanationId: 'explanation-1',
      traceId: 'trace-1',
      evaluationId: 'evaluation-1',
      rendererKind: RealityExplanationRendererKind.onlineAi,
      summary: '   ',
      highlights: const <String>[],
      uncertaintySummary: 'Invalid example',
      createdAtUtc: DateTime.utc(2026, 3, 16),
    );

    expect(
      validator.validateEvaluation(evaluation).issues,
      containsAll(<RealityModelValidationIssue>[
        RealityModelValidationIssue.invalidScore,
        RealityModelValidationIssue.invalidConfidence,
      ]),
    );
    expect(
      validator.validateExplanation(explanation).issues,
      contains(RealityModelValidationIssue.missingSummary),
    );
  });
}
