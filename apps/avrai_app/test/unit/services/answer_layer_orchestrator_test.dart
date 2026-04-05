import 'package:avrai_core/models/expression/expression_models.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/ai/answer_layer_orchestrator.dart';
import 'package:avrai_runtime_os/ai/bypass_intent_detector.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai/rag_context_builder.dart';
import 'package:avrai_runtime_os/ai/scope_classifier.dart';
import 'package:avrai_runtime_os/kernel/language/language_kernel_orchestrator_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFactsIndex extends Mock implements FactsIndex {}

class _MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

class _AlwaysInScopeClassifier extends ScopeClassifier {
  @override
  Scope classify(String message) => Scope.inScope;
}

class _AlwaysBypassDetector extends BypassIntentDetector {
  @override
  bool bypassRequested(String userMessage, {String? lastAssistantMessage}) =>
      true;
}

class _StubRagContextBuilder extends RAGContextBuilder {
  _StubRagContextBuilder(this.context)
      : super(
          factsIndex: _MockFactsIndex(),
          personalityLearning: _MockPersonalityLearning(),
        );

  final LanguageRuntimeContext context;

  @override
  Future<LanguageRuntimeContext> buildContext({
    required String userId,
    String? query,
    location,
  }) async {
    return context;
  }
}

class _CapturingLanguageKernelOrchestrator
    extends LanguageKernelOrchestratorService {
  List<String> lastAllowedClaims = const <String>[];
  List<String> lastEvidenceRefs = const <String>[];
  String lastConfidenceBand = 'unknown';

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
    vibeContext,
    String? uncertaintyNotice,
    String? cta,
    String? adaptationProfileRef,
  }) {
    lastAllowedClaims = allowedClaims;
    lastEvidenceRefs = evidenceRefs;
    lastConfidenceBand = confidenceBand;
    return RenderedExpression(
      text: 'captured response',
      sections: const <ExpressionSection>[
        ExpressionSection(kind: 'body', text: 'captured response'),
      ],
      assertedClaims: allowedClaims,
    );
  }
}

void main() {
  group('AnswerLayerOrchestrator timing-aware bypass path', () {
    test('fresh governed locality timing counts as grounded evidence',
        () async {
      final kernel = _CapturingLanguageKernelOrchestrator();
      final orchestrator = AnswerLayerOrchestrator(
        scopeClassifier: _AlwaysInScopeClassifier(),
        bypassDetector: _AlwaysBypassDetector(),
        contextBuilder: _StubRagContextBuilder(
          LanguageRuntimeContext(
            userId: 'user_123',
            preferences: const <String, dynamic>{
              'traits': <String>['coffee'],
            },
            personality: PersonalityProfile.initial(
              'agent_test',
              userId: 'user_123',
            ),
            conversationPreferences: <String, dynamic>{
              'display_name': 'Denver',
              'summary': 'Grounded locality context.',
              'governed_knowledge_timing_summary':
                  'phase locality_personal_visit_captured, effective knowledge ${DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String()}',
              'governed_knowledge_captured_at': DateTime.now()
                  .toUtc()
                  .subtract(const Duration(hours: 2))
                  .toIso8601String(),
              'governed_knowledge_phase': 'locality_personal_visit_captured',
            },
          ),
        ),
        languageKernelOrchestrator: kernel,
      );

      final response = await orchestrator.respond(
        userId: 'user_123',
        message: 'tell me more',
        history: <LanguageTurnMessage>[
          LanguageTurnMessage(
            role: LanguageTurnRole.assistant,
            content: 'Earlier grounded answer.',
          ),
        ],
      );

      expect(response, equals('captured response'));
      expect(kernel.lastAllowedClaims.join(' '),
          contains('local context timing:'));
      expect(
        kernel.lastAllowedClaims.join(' '),
        contains(
            'fresh enough to support grounded locality-sensitive phrasing'),
      );
      expect(
        kernel.lastEvidenceRefs,
        contains('conversation_preferences_timing'),
      );
      expect(kernel.lastConfidenceBand, equals('medium'));
    });

    test('stale governed locality timing lowers answer confidence', () async {
      final kernel = _CapturingLanguageKernelOrchestrator();
      final orchestrator = AnswerLayerOrchestrator(
        scopeClassifier: _AlwaysInScopeClassifier(),
        bypassDetector: _AlwaysBypassDetector(),
        contextBuilder: _StubRagContextBuilder(
          LanguageRuntimeContext(
            userId: 'user_123',
            preferences: const <String, dynamic>{
              'traits': <String>['coffee'],
            },
            personality: PersonalityProfile.initial(
              'agent_test',
              userId: 'user_123',
            ),
            conversationPreferences: <String, dynamic>{
              'display_name': 'Denver',
              'summary': 'Grounded locality context.',
              'governed_knowledge_timing_summary':
                  'phase locality_personal_visit_captured, effective knowledge ${DateTime.now().toUtc().subtract(const Duration(days: 45)).toIso8601String()}',
              'governed_knowledge_captured_at': DateTime.now()
                  .toUtc()
                  .subtract(const Duration(days: 45))
                  .toIso8601String(),
              'governed_knowledge_phase': 'locality_personal_visit_captured',
            },
          ),
        ),
        languageKernelOrchestrator: kernel,
      );

      await orchestrator.respond(
        userId: 'user_123',
        message: 'tell me more',
        history: <LanguageTurnMessage>[
          LanguageTurnMessage(
            role: LanguageTurnRole.assistant,
            content: 'Earlier grounded answer.',
          ),
        ],
      );

      expect(
        kernel.lastAllowedClaims.join(' '),
        contains('stale enough that AVRAI should answer more cautiously'),
      );
      expect(kernel.lastConfidenceBand, equals('low'));
    });
  });
}
