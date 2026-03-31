import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';

import 'default_reality_model_port.dart';
import 'reality_model_port.dart';

class KernelBackedRealityModelPort implements RealityModelPort {
  KernelBackedRealityModelPort({
    required ModelTruthPort modelTruthPort,
    RealityModelPort? fallback,
  })  : _modelTruthPort = modelTruthPort,
        _fallback = fallback ?? DefaultRealityModelPort();

  static const String _logName = 'KernelBackedRealityModelPort';

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
      'mode': 'kernel_backed_wave1',
      'cityScope': 'bham',
      'replayPolicy': 'prior_only',
    },
  );

  static const RealityModelBoundaryValidator _validator =
      RealityModelBoundaryValidator();
  static const RealityModelPortContractGuard _contractGuard =
      RealityModelPortContractGuard();

  final ModelTruthPort _modelTruthPort;
  final RealityModelPort _fallback;

  @override
  Future<RealityModelContract> getActiveContract() async {
    return _baseContract.normalized();
  }

  @override
  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  ) async {
    final normalizedRequest = request.normalized();
    final requestValidation = _validator.validateRequest(normalizedRequest);
    if (!requestValidation.isValid) {
      throw StateError(
        'KernelBackedRealityModelPort received an invalid request: ${requestValidation.issues}',
      );
    }

    try {
      final contract = await getActiveContract();
      _contractGuard.ensureRequestSupported(
        portName: 'KernelBackedRealityModelPort',
        contract: contract,
        request: normalizedRequest,
      );
      final fusion = await _buildFusionInput(normalizedRequest);
      final selectedProjections = _selectProjections(
        domain: normalizedRequest.domain,
        fusion: fusion,
      );
      final boundedEvidenceRefs = normalizedRequest.evidenceRefs
          .take(contract.maxEvidenceRefs)
          .toList(growable: false);
      final projectionConfidence = _averageConfidence(selectedProjections);
      final evidenceCoverage = boundedEvidenceRefs.isEmpty
          ? 0.0
          : boundedEvidenceRefs.length / contract.maxEvidenceRefs;
      final signalCoverage =
          math.min(normalizedRequest.signalTags.length, 4) / 4.0;
      final score = _clampScore(
        (projectionConfidence * 0.62) +
            (evidenceCoverage * 0.23) +
            (signalCoverage * 0.10) +
            (normalizedRequest.truthScope == null ? 0.0 : 0.05),
      );
      final confidence = _clampScore(
        (projectionConfidence * 0.78) +
            (evidenceCoverage * 0.12) +
            (signalCoverage * 0.10),
      );
      final metadata = <String, dynamic>{
        'source': 'kernel_backed_reality_model_port',
        'city_code': normalizedRequest.cityCode,
        if (normalizedRequest.localityCode.isNotEmpty)
          'locality_code': normalizedRequest.localityCode,
        'fusion_generated_at_utc': fusion.generatedAtUtc.toIso8601String(),
        'selected_projection_domains': selectedProjections
            .map((projection) => projection.domain.name)
            .toList(growable: false),
        'projection_confidences': <String, double>{
          for (final projection in selectedProjections)
            projection.domain.name:
                _clampScore(projection.confidence.clamp(0.0, 1.0)),
        },
        'domain_mix': selectedProjections
            .map((projection) => projection.domain.name)
            .join('/'),
        'highlights': _buildHighlights(
          request: normalizedRequest,
          selectedProjections: selectedProjections,
          evidenceRefCount: boundedEvidenceRefs.length,
          confidence: confidence,
        ),
        'locality_contained_in_where': fusion.localityContainedInWhere,
        'truth_scope_key': normalizedRequest.truthScope?.scopeKey,
      };

      final evaluation = RealityModelEvaluation(
        evaluationId: '${normalizedRequest.requestId}:evaluation',
        requestId: normalizedRequest.requestId,
        contractId: contract.contractId,
        domain: normalizedRequest.domain,
        candidateRef: normalizedRequest.candidateRef,
        score: score,
        confidence: confidence,
        uncertaintySummary: _buildUncertaintySummary(
          request: normalizedRequest,
          selectedProjections: selectedProjections,
          evidenceRefCount: boundedEvidenceRefs.length,
        ),
        supportingEvidenceRefs: boundedEvidenceRefs,
        generatedAtUtc: fusion.generatedAtUtc,
        localityCode: normalizedRequest.localityCode.isEmpty
            ? null
            : normalizedRequest.localityCode,
        truthScope: normalizedRequest.truthScope,
        metadata: metadata,
      );

      final validation = _validator.validateEvaluation(evaluation);
      if (!validation.isValid) {
        throw StateError(
          'KernelBackedRealityModelPort produced an invalid evaluation: ${validation.issues}',
        );
      }
      _contractGuard.ensureEvaluationMatchesRequest(
        portName: 'KernelBackedRealityModelPort',
        contract: contract,
        request: normalizedRequest,
        evaluation: evaluation,
      );
      return evaluation;
    } catch (error, stackTrace) {
      developer.log(
        'Kernel-backed evaluation failed; falling back deterministically: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback.evaluate(normalizedRequest);
    }
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
    final normalizedRequest = request.normalized();
    if (evaluation.metadata['source'] != 'kernel_backed_reality_model_port') {
      return _fallback.traceDecision(
        request: normalizedRequest,
        evaluation: evaluation,
        disposition: disposition,
        evidenceRefs: evidenceRefs,
        localityCode: localityCode,
        metadata: metadata,
      );
    }

    try {
      final contract = await getActiveContract();
      final boundedEvidenceRefs = evidenceRefs
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .take(contract.maxEvidenceRefs)
          .toList(growable: false);
      final trace = RealityDecisionTrace(
        traceId: '${normalizedRequest.requestId}:trace',
        contractId: contract.contractId,
        requestId: normalizedRequest.requestId,
        selectedEvaluationId: evaluation.evaluationId,
        selectedCandidateRef: evaluation.candidateRef,
        disposition: disposition,
        evidenceRefs: boundedEvidenceRefs,
        createdAtUtc: evaluation.generatedAtUtc,
        localityCode: localityCode?.trim().isNotEmpty == true
            ? localityCode!.trim()
            : evaluation.localityCode,
        metadata: <String, dynamic>{
          'source': 'kernel_backed_reality_model_port',
          'domain': evaluation.domain.toWireValue(),
          'selected_projection_domains':
              evaluation.metadata['selected_projection_domains'],
          ...metadata,
        },
      );

      final validation = _validator.validateTrace(trace);
      if (!validation.isValid) {
        throw StateError(
          'KernelBackedRealityModelPort produced an invalid trace: ${validation.issues}',
        );
      }
      _contractGuard.ensureTraceMatchesEvaluation(
        portName: 'KernelBackedRealityModelPort',
        contract: contract,
        request: normalizedRequest,
        evaluation: evaluation,
        trace: trace,
      );
      return trace;
    } catch (error, stackTrace) {
      developer.log(
        'Kernel-backed trace failed; falling back deterministically: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback.traceDecision(
        request: normalizedRequest,
        evaluation: evaluation,
        disposition: disposition,
        evidenceRefs: evidenceRefs,
        localityCode: localityCode,
        metadata: metadata,
      );
    }
  }

  @override
  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  }) async {
    if (evaluation.metadata['source'] != 'kernel_backed_reality_model_port') {
      return _fallback.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: rendererKind,
      );
    }

    try {
      final contract = await getActiveContract();
      final highlights = _extractHighlights(
        evaluation.metadata['highlights'],
        maxHighlights: contract.maxHighlights,
      );
      final explanation = RealityModelExplanation(
        explanationId: '${trace.traceId}:explanation',
        traceId: trace.traceId,
        evaluationId: evaluation.evaluationId,
        rendererKind: rendererKind,
        summary: _buildExplanationSummary(
          trace: trace,
          evaluation: evaluation,
        ),
        highlights: highlights,
        uncertaintySummary: evaluation.uncertaintySummary,
        createdAtUtc: trace.createdAtUtc,
        followUpQuestion: contract.followUpQuestionsAllowed &&
                evaluation.confidence < 0.65
            ? 'Which live Birmingham signal should override the current replay prior?'
            : null,
        metadata: <String, dynamic>{
          'source': 'kernel_backed_reality_model_port',
          'rendererKind': rendererKind.toWireValue(),
        },
      );

      final validation = _validator.validateExplanation(explanation);
      if (!validation.isValid) {
        throw StateError(
          'KernelBackedRealityModelPort produced an invalid explanation: ${validation.issues}',
        );
      }
      _contractGuard.ensureExplanationMatchesTrace(
        portName: 'KernelBackedRealityModelPort',
        contract: contract,
        trace: trace,
        evaluation: evaluation,
        explanation: explanation,
        rendererKind: rendererKind,
      );
      return explanation;
    } catch (error, stackTrace) {
      developer.log(
        'Kernel-backed explanation failed; falling back deterministically: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return _fallback.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: rendererKind,
      );
    }
  }

  Future<RealityKernelFusionInput> _buildFusionInput(
    RealityModelEvaluationRequest request,
  ) {
    return _modelTruthPort.buildRealityKernelFusionInput(
      envelope: KernelEventEnvelope(
        eventId: 'reality_model:${request.requestId}',
        agentId: request.subjectId,
        sessionId: request.requestId,
        occurredAtUtc: request.requestedAtUtc,
        sourceSystem: 'kernel_backed_reality_model_port',
        eventType: 'reality_model_evaluation',
        actionType: 'evaluate_candidate',
        entityId: request.candidateRef,
        entityType: request.domain.toWireValue(),
        context: <String, dynamic>{
          'location_label': request.localityCode.isNotEmpty
              ? request.localityCode
              : request.cityCode,
          'candidate_ref': request.candidateRef,
          'city_code': request.cityCode,
          if (request.localityCode.isNotEmpty)
            'locality_code': request.localityCode,
          'signal_tags': request.signalTags,
        },
        predictionContext: <String, dynamic>{
          'requested_domain': request.domain.toWireValue(),
          if (request.truthScope != null)
            'truth_scope_key': request.truthScope!.scopeKey,
        },
        policyContext: <String, dynamic>{
          'replay_policy': 'prior_only',
          'uncertainty_disposition': 'never_bluff',
        },
        runtimeContext: <String, dynamic>{
          'execution_path': 'kernel_backed_reality_model_port.evaluate',
          'surface': request.metadata['surface'] ?? 'reality_model_port',
        },
      ),
      whyRequest: KernelWhyRequest(
        bundle: const KernelContextBundleWithoutWhy(),
        goal: 'evaluate_${request.domain.toWireValue()}',
        predictedOutcome: 'bounded_reality_model_fit',
        predictedConfidence: _predictionSeed(request),
        actualOutcome: 'requested',
        actualOutcomeScore: 1.0,
        coreSignals: _buildCoreSignals(request.signalTags),
        pheromoneSignals: _buildPheromoneSignals(request),
        policySignals: _buildPolicySignals(request),
        memoryContext: <String, dynamic>{
          'candidate_ref': request.candidateRef,
          'city_code': request.cityCode,
          if (request.localityCode.isNotEmpty)
            'locality_code': request.localityCode,
          'evidence_refs': request.evidenceRefs.take(5).toList(growable: false),
          'truth_scope_key': request.truthScope?.scopeKey,
        },
        severity:
            request.domain == RealityModelDomain.locality ? 'medium' : 'low',
      ),
    );
  }

  List<KernelRealityProjection> _selectProjections({
    required RealityModelDomain domain,
    required RealityKernelFusionInput fusion,
  }) {
    return switch (domain) {
      RealityModelDomain.place => <KernelRealityProjection>[
          fusion.where,
          fusion.what,
          fusion.why
        ],
      RealityModelDomain.event => <KernelRealityProjection>[
          fusion.what,
          fusion.when,
          fusion.where,
          fusion.why
        ],
      RealityModelDomain.community => <KernelRealityProjection>[
          fusion.what,
          fusion.where,
          fusion.why
        ],
      RealityModelDomain.list => <KernelRealityProjection>[
          fusion.what,
          fusion.when,
          fusion.why
        ],
      RealityModelDomain.business => <KernelRealityProjection>[
          fusion.what,
          fusion.where,
          fusion.how,
          fusion.why
        ],
      RealityModelDomain.locality => <KernelRealityProjection>[
          fusion.where,
          fusion.why,
          fusion.what
        ],
    };
  }

  List<WhySignal> _buildCoreSignals(List<String> signalTags) {
    if (signalTags.isEmpty) {
      return const <WhySignal>[
        WhySignal(
          label: 'signal_sparse',
          weight: -0.2,
          source: 'core',
          durable: false,
        ),
      ];
    }
    return signalTags.take(4).map((tag) {
      return WhySignal(
        label: 'signal_${_normalizeSignalTag(tag)}',
        weight: 0.18,
        source: 'core',
        durable: true,
      );
    }).toList(growable: false);
  }

  List<WhySignal> _buildPheromoneSignals(
    RealityModelEvaluationRequest request,
  ) {
    return <WhySignal>[
      if (request.localityCode.isNotEmpty)
        const WhySignal(
          label: 'locality_anchor_present',
          weight: 0.24,
          source: 'pheromone',
          durable: false,
        ),
      if (request.evidenceRefs.isEmpty)
        const WhySignal(
          label: 'evidence_sparse',
          weight: -0.28,
          source: 'pheromone',
          durable: false,
        ),
    ];
  }

  List<WhySignal> _buildPolicySignals(
    RealityModelEvaluationRequest request,
  ) {
    return <WhySignal>[
      const WhySignal(
        label: 'replay_prior_only',
        weight: 0.32,
        source: 'policy',
        durable: true,
      ),
      if (request.truthScope != null)
        WhySignal(
          label:
              'scope_${request.truthScope!.governanceStratum.name}_${request.truthScope!.truthSurfaceKind.name}',
          weight: 0.21,
          source: 'policy',
          durable: true,
        ),
    ];
  }

  double _predictionSeed(RealityModelEvaluationRequest request) {
    final signalCoverage = math.min(request.signalTags.length, 4) / 4.0;
    final evidenceCoverage = math.min(request.evidenceRefs.length, 5) / 5.0;
    return _clampScore((signalCoverage * 0.55) + (evidenceCoverage * 0.45));
  }

  double _averageConfidence(List<KernelRealityProjection> projections) {
    if (projections.isEmpty) {
      return 0.0;
    }
    final total = projections.fold<double>(
      0.0,
      (sum, projection) => sum + projection.confidence.clamp(0.0, 1.0),
    );
    return _clampScore(total / projections.length);
  }

  List<String> _buildHighlights({
    required RealityModelEvaluationRequest request,
    required List<KernelRealityProjection> selectedProjections,
    required int evidenceRefCount,
    required double confidence,
  }) {
    final highlights = <String>[
      'Kernel fusion confidence ${(confidence * 100).round()}% across ${selectedProjections.map((projection) => projection.domain.name).join('/')} signals.',
      _projectionHighlight(selectedProjections.first),
      'Evidence refs considered: $evidenceRefCount/${_baseContract.maxEvidenceRefs}.',
    ];
    if (request.localityCode.isNotEmpty &&
        !highlights.any((entry) => entry.contains(request.localityCode))) {
      highlights.insert(1, 'Locality anchor: ${request.localityCode}.');
    }
    return highlights
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .take(_baseContract.maxHighlights)
        .toList(growable: false);
  }

  String _buildUncertaintySummary({
    required RealityModelEvaluationRequest request,
    required List<KernelRealityProjection> selectedProjections,
    required int evidenceRefCount,
  }) {
    if (evidenceRefCount == 0) {
      return 'Kernel fusion is available, but no bounded evidence refs were attached; remain in observe-or-follow-up mode.';
    }
    if (selectedProjections.any((projection) => projection.confidence < 0.4)) {
      return 'One or more kernel projections remain low-confidence; live Birmingham contradiction should outrank this fusion immediately.';
    }
    if (request.signalTags.length < 2) {
      return 'Kernel fusion is present, but signal coverage is still thin for the current ${_domainLabel(request.domain).toLowerCase()} scope.';
    }
    return 'Kernel fusion is bounded by replay-safe priors and should yield to live contradiction immediately.';
  }

  List<String> _extractHighlights(
    Object? rawHighlights, {
    required int maxHighlights,
  }) {
    final values = rawHighlights is List ? rawHighlights : const <Object?>[];
    return values
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .take(maxHighlights)
        .toList(growable: false);
  }

  String _projectionHighlight(KernelRealityProjection projection) {
    final label = switch (projection.domain) {
      KernelDomain.what => 'Semantic view',
      KernelDomain.when => 'Temporal view',
      KernelDomain.where => 'Spatial view',
      KernelDomain.why => 'Reasoning view',
      KernelDomain.how => 'Execution view',
      KernelDomain.who => 'Identity view',
      KernelDomain.vibe => 'Vibe view',
    };
    return '$label: ${projection.summary}.';
  }

  String _normalizeSignalTag(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return 'unknown';
    }
    return trimmed
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  double _clampScore(double value) {
    if (value < 0.0) {
      return 0.0;
    }
    if (value > 1.0) {
      return 1.0;
    }
    return double.parse(value.toStringAsFixed(2));
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

  String _buildExplanationSummary({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
  }) {
    final domainMix = (evaluation.metadata['domain_mix'] as String?)?.trim();
    final mixSuffix = domainMix == null || domainMix.isEmpty
        ? 'kernel-fused signals'
        : 'kernel-fused $domainMix signals';
    return '${_candidateLabel(evaluation.candidateRef)} is in ${trace.disposition.toWireValue()} mode for ${_domainLabel(evaluation.domain)} decisions using $mixSuffix.';
  }
}
