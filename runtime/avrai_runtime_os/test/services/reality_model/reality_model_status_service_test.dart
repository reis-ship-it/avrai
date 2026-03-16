import 'package:avrai_runtime_os/reality_model_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealityModelStatusService', () {
    test('loads normalized kernel-backed contract status', () async {
      final service = RealityModelStatusService(
        realityModelPort: _FakeRealityModelPort(),
      );

      final snapshot = await service.loadStatus();

      expect(snapshot.available, isTrue);
      expect(snapshot.contract?.contractId, 'reality_model_wave1_bham_beta');
      expect(snapshot.mode, 'kernel_backed_wave1');
      expect(snapshot.boundary, 'reality_model_port');
      expect(snapshot.modeLabel, 'Kernel Backed Wave1');
      expect(snapshot.boundaryLabel, 'Reality Model Port');
      expect(snapshot.supportedDomainLabels, contains('Event'));
      expect(snapshot.rendererLabels, contains('Template'));
      expect(snapshot.summary, contains('kernel_backed_wave1'));
    });

    test('reports unavailable status when port is missing', () async {
      final service = RealityModelStatusService(realityModelPort: null);

      final snapshot = await service.loadStatus();

      expect(snapshot.available, isFalse);
      expect(snapshot.contract, isNull);
      expect(snapshot.summary, contains('not registered'));
    });
  });
}

class _FakeRealityModelPort implements RealityModelPort {
  @override
  Future<RealityModelExplanation> buildExplanation({
    required RealityDecisionTrace trace,
    required RealityModelEvaluation evaluation,
    required RealityExplanationRendererKind rendererKind,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RealityModelEvaluation> evaluate(
    RealityModelEvaluationRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<RealityModelContract> getActiveContract() async {
    return const RealityModelContract(
      contractId: 'reality_model_wave1_bham_beta',
      version: '2026.03-wave1',
      supportedDomains: <RealityModelDomain>[
        RealityModelDomain.event,
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
        'mode': 'kernel_backed_wave1',
        'boundary': 'reality_model_port',
      },
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
  }) {
    throw UnimplementedError();
  }
}
