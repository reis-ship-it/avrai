import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/ai/answer_layer_orchestrator.dart';
import 'package:avrai_runtime_os/ai/rag_context_builder.dart';
import 'package:avrai_runtime_os/ai/rag_formatter.dart';
import 'package:avrai_runtime_os/ai/retrieval_result.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRAGContextBuilder extends Mock implements RAGContextBuilder {}

void main() {
  group('Grounded answer layer', () {
    test('RAGFormatter renders grounded retrieval through the mouth', () async {
      final formatter = RAGFormatter();
      final result = RetrievalResult(
        items: const <RetrievedItem>[
          RetrievedItem(
            id: 'trait-coffee',
            type: 'traits',
            content: 'coffee',
            score: 1.0,
            source: 'facts',
          ),
          RetrievedItem(
            id: 'place-museum-cafe',
            type: 'places',
            content: 'Museum Cafe',
            score: 0.9,
            source: 'facts',
          ),
        ],
        coverage: const <String, int>{
          'traits': 1,
          'places': 1,
          'social': 0,
          'cues': 0,
          'insight': 0,
        },
      );

      final response = await formatter.format(
        result: result,
        query: 'What fits me tonight?',
        userId: 'user_123',
        languageStyle: 'Prefer concise, calm phrasing.',
      );

      expect(response, contains('coffee'));
      expect(response, contains('Museum Cafe'));
    });

    test('AnswerLayerOrchestrator bypass path stays grounded in context',
        () async {
      final contextBuilder = _MockRAGContextBuilder();
      when(() => contextBuilder.buildContext(
            userId: 'user_123',
            query: 'tell me more',
            location: null,
          )).thenAnswer(
        (_) async => LanguageRuntimeContext(
          userId: 'user_123',
          preferences: const <String, dynamic>{
            'traits': <String>['coffee', 'art'],
            'places': <String>['Museum Cafe'],
            'social_graph': <String>['friend_1'],
          },
          personality: PersonalityProfile.initial(
            'agent_user_123',
            userId: 'user_123',
          ),
          languageStyle: 'Brief and calm',
        ),
      );

      final orchestrator = AnswerLayerOrchestrator(
        contextBuilder: contextBuilder,
      );

      final response = await orchestrator.respond(
        userId: 'user_123',
        message: 'tell me more',
        history: <LanguageTurnMessage>[
          LanguageTurnMessage(
            role: LanguageTurnRole.assistant,
            content: 'Here is a grounded answer.',
          ),
        ],
      );

      expect(response, contains('coffee'));
      expect(response, contains('Museum Cafe'));
      expect(response, isNot(contains('Try again later')));
    });
  });
}
