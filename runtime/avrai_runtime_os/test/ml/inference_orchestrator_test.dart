import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/ml/inference_orchestrator.dart';
import 'package:avrai_runtime_os/services/infrastructure/config_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLanguageKernelOrchestratorService
    extends LanguageKernelOrchestratorService {
  @override
  RenderedExpression renderGroundedOutput({
    required ExpressionSpeechAct speechAct,
    required ExpressionAudience audience,
    required ExpressionSurfaceShape surfaceShape,
    required String subjectLabel,
    required List<String> allowedClaims,
    List<String> forbiddenClaims = const <String>[],
    List<String> evidenceRefs = const <String>[],
    String confidenceBand = 'medium',
    String toneProfile = 'clear_calm',
    VibeExpressionContext? vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    final text = <String>[
      subjectLabel,
      ...allowedClaims,
      if (uncertaintyNotice != null && uncertaintyNotice.isNotEmpty)
        uncertaintyNotice,
    ].join('\n');
    return RenderedExpression(
      text: text,
      sections: <ExpressionSection>[
        ExpressionSection(kind: 'body', text: text),
      ],
      assertedClaims: allowedClaims,
    );
  }
}

void main() {
  group('InferenceOrchestrator', () {
    test('renders grounded reasoning through the mouth for device-first mode',
        () async {
      final orchestrator = InferenceOrchestrator(
        config: const ConfigService(
          environment: 'test',
          supabaseUrl: 'https://example.com',
          supabaseAnonKey: 'anon',
          googlePlacesApiKey: 'test-key',
        ),
        languageKernelOrchestrator: _FakeLanguageKernelOrchestratorService(),
      );

      final result = await orchestrator.infer(
        input: <String, dynamic>{
          'query': 'Can you explain why this recommendation fits me tonight?',
          'places': const <String>['Coffee shop'],
          'social_graph': const <String>['Friend'],
          'needs_narrative': true,
        },
        strategy: InferenceStrategy.deviceFirst,
      );

      expect(result.source, equals(InferenceSource.hybrid));
      expect(result.reasoning, isNotNull);
      expect(result.reasoning, contains('Inference reasoning'));
      expect(result.reasoning, contains('AVRAI grounded this reasoning'));
      expect(result.reasoning, contains('Strongest local signals'));
    });
  });
}
