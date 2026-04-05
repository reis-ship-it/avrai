import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';

import 'reality_model_port.dart';

class DefaultRealityModelPort implements RealityModelPort {
  DefaultRealityModelPort();

  static const RealityModelContract _baseContract = RealityModelContract(
    contractId: 'reality_model_wave1_bham_beta',
    version: '2026.03-wave1',
    supportedDomains: <RealityModelDomain>[
      RealityModelDomain.place,
      RealityModelDomain.event,
      RealityModelDomain.community,
      RealityModelDomain.list,
      RealityModelDomain.business,
      RealityModelDomain.locality,
    ],
    rendererKinds: <RealityExplanationRendererKind>[
      RealityExplanationRendererKind.template,
    ],
    uncertaintyDisposition: RealityUncertaintyDisposition.neverBluff,
    followUpQuestionsAllowed: true,
    maxEvidenceRefs: 5,
    maxHighlights: 3,
    metadata: <String, dynamic>{
      'boundary': 'reality_model_port',
      'mode': 'deterministic_wave1',
      'cityScope': 'bham',
      'replayPolicy': 'prior_only',
    },
  );

  static const RealityModelBoundaryValidator _validator =
      RealityModelBoundaryValidator();
  static const RealityModelPortContractGuard _contractGuard =
      RealityModelPortContractGuard();

  @override
  Future<RealityModelContract> getActiveContract() async {
    return _baseContract.normalized();
  }

  @override
  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  ) async {
    final contract = await getActiveContract();
    final normalizedRequest = request.normalized();
    _contractGuard.ensureRequestSupported(
      portName: 'DefaultRealityModelPort',
      contract: contract,
      request: normalizedRequest,
    );
    final evidenceRefs = normalizedRequest.evidenceRefs
        .take(contract.maxEvidenceRefs)
        .toList(growable: false);
    final signalCount = normalizedRequest.signalTags.length;
    final evidenceCount = evidenceRefs.length;
    final truthScopeBonus = normalizedRequest.truthScope == null ? 0.0 : 0.05;
    final localityBonus = normalizedRequest.localityCode.isEmpty ? 0.0 : 0.08;
    final score = _clampScore(
      0.28 +
          (signalCount * 0.08) +
          (evidenceCount * 0.11) +
          truthScopeBonus +
          localityBonus,
    );
    final confidence = _clampScore(
      0.22 + (math.min(signalCount, 3) * 0.09) + (evidenceCount * 0.12),
    );

    final evaluation = RealityModelEvaluation(
      evaluationId: '${normalizedRequest.requestId}:evaluation',
      requestId: normalizedRequest.requestId,
      contractId: contract.contractId,
      domain: normalizedRequest.domain,
      candidateRef: normalizedRequest.candidateRef,
      score: score,
      confidence: confidence,
      uncertaintySummary: _buildUncertaintySummary(
        evidenceCount: evidenceCount,
        signalCount: signalCount,
      ),
      supportingEvidenceRefs: evidenceRefs,
      generatedAtUtc: normalizedRequest.requestedAtUtc,
      localityCode: normalizedRequest.localityCode.isEmpty
          ? null
          : normalizedRequest.localityCode,
      truthScope: normalizedRequest.truthScope,
      metadata: <String, dynamic>{
        'source': 'default_reality_model_port',
        'signalTagCount': signalCount,
        'evidenceRefCount': evidenceCount,
        'cityCode': normalizedRequest.cityCode,
      },
    );

    final validation = _validator.validateEvaluation(evaluation);
    if (!validation.isValid) {
      throw StateError(
        'DefaultRealityModelPort produced an invalid evaluation: ${validation.issues}',
      );
    }
    _contractGuard.ensureEvaluationMatchesRequest(
      portName: 'DefaultRealityModelPort',
      contract: contract,
      request: normalizedRequest,
      evaluation: evaluation,
    );
    return evaluation;
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
    final contract = await getActiveContract();
    final boundedEvidence = evidenceRefs
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .take(contract.maxEvidenceRefs)
        .toList(growable: false);
    final trace = RealityDecisionTrace(
      traceId: '${request.requestId}:trace',
      contractId: contract.contractId,
      requestId: request.requestId.trim(),
      selectedEvaluationId: evaluation.evaluationId.trim(),
      selectedCandidateRef: evaluation.candidateRef.trim(),
      disposition: disposition,
      evidenceRefs: boundedEvidence,
      createdAtUtc: evaluation.generatedAtUtc,
      localityCode: localityCode?.trim().isNotEmpty == true
          ? localityCode!.trim()
          : evaluation.localityCode,
      metadata: <String, dynamic>{
        'source': 'default_reality_model_port',
        'domain': evaluation.domain.toWireValue(),
        ...metadata,
      },
    );

    final validation = _validator.validateTrace(trace);
    if (!validation.isValid) {
      throw StateError(
        'DefaultRealityModelPort produced an invalid trace: ${validation.issues}',
      );
    }
    _contractGuard.ensureTraceMatchesEvaluation(
      portName: 'DefaultRealityModelPort',
      contract: contract,
      request: request.normalized(),
      evaluation: evaluation,
      trace: trace,
    );
    return trace;
  }

  @override
  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  }) async {
    final contract = await getActiveContract();
    final highlights = <String>[
      '${_domainLabel(evaluation.domain)} fit ${(evaluation.score * 100).round()}% with confidence ${(evaluation.confidence * 100).round()}%.',
      if (trace.localityCode?.isNotEmpty == true)
        'Locality anchor: ${trace.localityCode}.',
      'Evidence refs considered: ${trace.evidenceRefs.length}/${contract.maxEvidenceRefs}.',
    ].take(contract.maxHighlights).toList(growable: false);
    final explanation = RealityModelExplanation(
      explanationId: '${trace.traceId}:explanation',
      traceId: trace.traceId,
      evaluationId: evaluation.evaluationId,
      rendererKind: rendererKind,
      summary:
          '${_candidateLabel(evaluation.candidateRef)} is in ${trace.disposition.toWireValue()} mode for ${_domainLabel(evaluation.domain)} decisions.',
      highlights: highlights,
      uncertaintySummary: evaluation.uncertaintySummary,
      createdAtUtc: trace.createdAtUtc,
      followUpQuestion: contract.followUpQuestionsAllowed &&
              evaluation.confidence < 0.65
          ? 'What live Birmingham signal would most change this recommendation?'
          : null,
      metadata: <String, dynamic>{
        'source': 'default_reality_model_port',
        'rendererKind': rendererKind.toWireValue(),
      },
    );

    final validation = _validator.validateExplanation(explanation);
    if (!validation.isValid) {
      throw StateError(
        'DefaultRealityModelPort produced an invalid explanation: ${validation.issues}',
      );
    }
    _contractGuard.ensureExplanationMatchesTrace(
      portName: 'DefaultRealityModelPort',
      contract: contract,
      trace: trace,
      evaluation: evaluation,
      explanation: explanation,
      rendererKind: rendererKind,
    );
    return explanation;
  }

  double _clampScore(double value) {
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return double.parse(value.toStringAsFixed(2));
  }

  String _buildUncertaintySummary({
    required int evidenceCount,
    required int signalCount,
  }) {
    if (evidenceCount == 0) {
      return 'No evidence refs were available; remain in observe-or-follow-up mode.';
    }
    if (evidenceCount == 1) {
      return 'Single evidence ref only; keep locality-specific uncertainty explicit.';
    }
    if (signalCount < 2) {
      return 'Evidence is present, but signal coverage is still thin across the current locality.';
    }
    return 'Replay priors are bounded by current locality evidence and should yield to live contradiction immediately.';
  }

  String _domainLabel(RealityModelDomain domain) {
    return switch (domain) {
      RealityModelDomain.place => 'Place',
      RealityModelDomain.event => 'Event',
      RealityModelDomain.community => 'Community',
      RealityModelDomain.list => 'List',
      RealityModelDomain.business => 'Business',
      RealityModelDomain.locality => 'Locality',
    };
  }

  String _candidateLabel(String candidateRef) {
    final trimmed = candidateRef.trim();
    if (trimmed.isEmpty) {
      return 'Unknown candidate';
    }
    return trimmed.replaceAll(':', ' / ');
  }
}
