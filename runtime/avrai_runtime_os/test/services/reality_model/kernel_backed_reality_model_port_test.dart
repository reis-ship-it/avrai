import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelBackedRealityModelPort', () {
    const validator = RealityModelBoundaryValidator();

    test('produces bounded reality-model artifacts from kernel fusion',
        () async {
      final port = KernelBackedRealityModelPort(
        modelTruthPort: _FakeModelTruthPort(),
      );
      final request = RealityModelEvaluationRequest(
        requestId: 'request-1',
        subjectId: 'admin-operator',
        domain: RealityModelDomain.locality,
        candidateRef: 'admin_surface:reality',
        localityCode: 'bham_downtown',
        cityCode: 'bham',
        signalTags: const <String>['spring', 'music', 'outdoor'],
        evidenceRefs: const <String>[
          'tuple:1',
          'tuple:2',
          'tuple:3',
          'tuple:4',
          'tuple:5',
          'tuple:6',
        ],
        requestedAtUtc: DateTime.utc(2026, 3, 15, 4),
      );

      final contract = await port.getActiveContract();
      final evaluation = await port.evaluate(request);
      final trace = await port.traceDecision(
        request: request,
        evaluation: evaluation,
        disposition: RealityDecisionDisposition.observe,
        evidenceRefs: evaluation.supportingEvidenceRefs,
        localityCode: request.localityCode,
      );
      final explanation = await port.buildExplanation(
        trace: trace,
        evaluation: evaluation,
        rendererKind: RealityExplanationRendererKind.template,
      );

      expect(contract.metadata['mode'], 'kernel_backed_wave1');
      expect(evaluation.metadata['source'], 'kernel_backed_reality_model_port');
      expect(evaluation.supportingEvidenceRefs, hasLength(5));
      expect(
        evaluation.metadata['selected_projection_domains'],
        containsAll(<String>['where', 'why', 'what']),
      );
      expect(trace.metadata['source'], 'kernel_backed_reality_model_port');
      expect(explanation.summary, contains('kernel-fused'));
      expect(explanation.highlights, isNotEmpty);
      expect(validator.validateContract(contract).isValid, isTrue);
      expect(validator.validateEvaluation(evaluation).isValid, isTrue);
      expect(validator.validateTrace(trace).isValid, isTrue);
      expect(validator.validateExplanation(explanation).isValid, isTrue);
    });

    test('falls back deterministically when model truth fusion fails',
        () async {
      final port = KernelBackedRealityModelPort(
        modelTruthPort: _ThrowingModelTruthPort(),
      );
      final request = RealityModelEvaluationRequest(
        requestId: 'request-2',
        subjectId: 'admin-operator',
        domain: RealityModelDomain.event,
        candidateRef: 'event:spring-in-bham',
        localityCode: 'bham_downtown',
        cityCode: 'bham',
        signalTags: const <String>['music'],
        evidenceRefs: const <String>['tuple:1', 'tuple:2'],
        requestedAtUtc: DateTime.utc(2026, 3, 15, 5),
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

      expect(
        evaluation.metadata['source'],
        anyOf(isNull, equals('default_reality_model_port')),
      );
      expect(explanation.summary, contains('event / spring-in-bham'));
      expect(validator.validateEvaluation(evaluation).isValid, isTrue);
      expect(validator.validateTrace(trace).isValid, isTrue);
      expect(validator.validateExplanation(explanation).isValid, isTrue);
    });
  });
}

class _FakeModelTruthPort implements ModelTruthPort {
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) async {
    return RealityKernelFusionInput(
      envelope: envelope,
      bundle: const KernelContextBundle(
        who: null,
        what: null,
        when: null,
        where: null,
        how: null,
        why: null,
      ),
      who: const WhoRealityProjection(
        summary: 'Bounded actor context',
        confidence: 0.61,
        features: <String, dynamic>{'trust_scope': 'private'},
      ),
      what: const WhatRealityProjection(
        summary: 'Semantic state for downtown spring programming',
        confidence: 0.82,
        features: <String, dynamic>{
          'projected_types': <String>['event']
        },
      ),
      when: const WhenRealityProjection(
        summary: 'Temporal ordering for spring launch weekend',
        confidence: 0.74,
      ),
      where: const WhereRealityProjection(
        summary: 'Birmingham Downtown',
        confidence: 0.88,
        features: <String, dynamic>{
          'active_token_id': 'bham_downtown',
          'locality_contained_in_where': true,
        },
      ),
      why: const WhyRealityProjection(
        summary: 'Reasoning path favors bounded locality fit',
        confidence: 0.79,
      ),
      how: const HowRealityProjection(
        summary: 'Execution posture remains observe-only',
        confidence: 0.68,
      ),
      generatedAtUtc: DateTime.utc(2026, 3, 15, 4, 30),
    );
  }
}

class _ThrowingModelTruthPort implements ModelTruthPort {
  @override
  Future<RealityKernelFusionInput> buildRealityKernelFusionInput({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw StateError('kernel fusion unavailable');
  }
}
