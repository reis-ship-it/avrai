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

class RealityModelPortContractGuard {
  const RealityModelPortContractGuard();

  static const RealityModelBoundaryValidator _validator =
      RealityModelBoundaryValidator();

  void ensureRequestSupported({
    required String portName,
    required RealityModelContract contract,
    required RealityModelEvaluationRequest request,
  }) {
    final contractValidation = _validator.validateContract(contract);
    if (!contractValidation.isValid) {
      throw StateError(
        '$portName contract validation failed: ${contractValidation.issues}',
      );
    }
    final requestValidation = _validator.validateRequest(request);
    if (!requestValidation.isValid) {
      throw StateError(
        '$portName request validation failed: ${requestValidation.issues}',
      );
    }
    if (!contract.supportedDomains.contains(request.domain)) {
      throw StateError(
        '$portName does not support ${request.domain.toWireValue()} under '
        'contract ${contract.contractId}.',
      );
    }
  }

  void ensureEvaluationMatchesRequest({
    required String portName,
    required RealityModelContract contract,
    required RealityModelEvaluationRequest request,
    required RealityModelEvaluation evaluation,
  }) {
    final violations = <String>[];
    final contractValidation = _validator.validateContract(contract);
    if (!contractValidation.isValid) {
      violations.add('active contract is structurally invalid');
    }
    final requestValidation = _validator.validateRequest(request);
    if (!requestValidation.isValid) {
      violations.add('request is structurally invalid');
    }
    final evaluationValidation = _validator.validateEvaluation(evaluation);
    if (!evaluationValidation.isValid) {
      violations.add('evaluation is structurally invalid');
    }
    if (evaluation.contractId != contract.contractId) {
      violations.add('evaluation contractId must match the active contract');
    }
    if (evaluation.requestId != request.requestId) {
      violations.add('evaluation requestId must match the source request');
    }
    if (evaluation.candidateRef != request.candidateRef) {
      violations.add('evaluation candidateRef must match the source request');
    }
    if (evaluation.domain != request.domain) {
      violations.add('evaluation domain must match the source request');
    }
    if (evaluation.supportingEvidenceRefs.length > contract.maxEvidenceRefs) {
      violations
          .add('evaluation evidence refs exceeded the active contract cap');
    }
    final requestEvidence = request.evidenceRefs.toSet();
    final strayEvidence = evaluation.supportingEvidenceRefs
        .where((entry) => !requestEvidence.contains(entry))
        .toSet()
        .toList()
      ..sort();
    if (strayEvidence.isNotEmpty) {
      violations.add(
        'evaluation evidence refs must remain within the source request set',
      );
    }
    _throwIfInvalid(
      portName: portName,
      stage: 'evaluation contract drift',
      violations: violations,
    );
  }

  void ensureTraceMatchesEvaluation({
    required String portName,
    required RealityModelContract contract,
    required RealityModelEvaluationRequest request,
    required RealityModelEvaluation evaluation,
    required RealityDecisionTrace trace,
  }) {
    final violations = <String>[];
    final contractValidation = _validator.validateContract(contract);
    if (!contractValidation.isValid) {
      violations.add('active contract is structurally invalid');
    }
    final requestValidation = _validator.validateRequest(request);
    if (!requestValidation.isValid) {
      violations.add('request is structurally invalid');
    }
    final evaluationValidation = _validator.validateEvaluation(evaluation);
    if (!evaluationValidation.isValid) {
      violations.add('evaluation is structurally invalid');
    }
    final traceValidation = _validator.validateTrace(trace);
    if (!traceValidation.isValid) {
      violations.add('trace is structurally invalid');
    }
    if (evaluation.contractId != contract.contractId) {
      violations.add('evaluation contractId must match the active contract');
    }
    if (evaluation.requestId != request.requestId) {
      violations.add('evaluation requestId must match the source request');
    }
    if (evaluation.candidateRef != request.candidateRef) {
      violations.add('evaluation candidateRef must match the source request');
    }
    if (evaluation.domain != request.domain) {
      violations.add('evaluation domain must match the source request');
    }
    if (trace.contractId != contract.contractId) {
      violations.add('trace contractId must match the active contract');
    }
    if (trace.requestId != request.requestId) {
      violations.add('trace requestId must match the source request');
    }
    if (trace.selectedEvaluationId != evaluation.evaluationId) {
      violations.add('trace selectedEvaluationId must match the evaluation');
    }
    if (trace.selectedCandidateRef != evaluation.candidateRef) {
      violations.add('trace selectedCandidateRef must match the evaluation');
    }
    if (trace.evidenceRefs.length > contract.maxEvidenceRefs) {
      violations.add('trace evidence refs exceeded the active contract cap');
    }
    final evaluationEvidence = evaluation.supportingEvidenceRefs.toSet();
    final strayEvidence = trace.evidenceRefs
        .where((entry) => !evaluationEvidence.contains(entry))
        .toSet()
        .toList()
      ..sort();
    if (strayEvidence.isNotEmpty) {
      violations.add(
        'trace evidence refs must remain within the evaluation evidence set',
      );
    }
    _throwIfInvalid(
      portName: portName,
      stage: 'trace contract drift',
      violations: violations,
    );
  }

  void ensureExplanationMatchesTrace({
    required String portName,
    required RealityModelContract contract,
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityModelExplanation explanation,
    required RealityExplanationRendererKind rendererKind,
  }) {
    final violations = <String>[];
    final contractValidation = _validator.validateContract(contract);
    if (!contractValidation.isValid) {
      violations.add('active contract is structurally invalid');
    }
    final evaluationValidation = _validator.validateEvaluation(evaluation);
    if (!evaluationValidation.isValid) {
      violations.add('evaluation is structurally invalid');
    }
    final traceValidation = _validator.validateTrace(trace);
    if (!traceValidation.isValid) {
      violations.add('trace is structurally invalid');
    }
    final explanationValidation = _validator.validateExplanation(explanation);
    if (!explanationValidation.isValid) {
      violations.add('explanation is structurally invalid');
    }
    if (!contract.rendererKinds.contains(rendererKind)) {
      violations.add(
        'renderer ${rendererKind.toWireValue()} is not enabled by the active contract',
      );
    }
    if (explanation.traceId != trace.traceId) {
      violations.add('explanation traceId must match the source trace');
    }
    if (explanation.evaluationId != evaluation.evaluationId) {
      violations
          .add('explanation evaluationId must match the source evaluation');
    }
    if (explanation.rendererKind != rendererKind) {
      violations
          .add('explanation rendererKind must match the requested renderer');
    }
    if (explanation.highlights.length > contract.maxHighlights) {
      violations.add('explanation highlights exceeded the active contract cap');
    }
    if (!contract.followUpQuestionsAllowed &&
        explanation.followUpQuestion?.trim().isNotEmpty == true) {
      violations.add(
        'follow-up questions are disabled by the active contract',
      );
    }
    _throwIfInvalid(
      portName: portName,
      stage: 'explanation contract drift',
      violations: violations,
    );
  }

  void _throwIfInvalid({
    required String portName,
    required String stage,
    required List<String> violations,
  }) {
    if (violations.isEmpty) {
      return;
    }
    throw StateError('$portName $stage: ${violations.join(' | ')}');
  }
}
