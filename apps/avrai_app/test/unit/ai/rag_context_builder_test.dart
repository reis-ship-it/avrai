import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/ai/conversation_preferences.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart' as pl;
import 'package:avrai_runtime_os/ai/rag_context_builder.dart';
import 'package:avrai_runtime_os/ai/structured_facts.dart';
import 'package:avrai_runtime_os/services/geographic/metro_experience_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class _MockFactsIndex extends Mock implements FactsIndex {}

class _MockPersonalityLearning extends Mock implements pl.PersonalityLearning {}

class _MockConversationPreferenceStore extends Mock
    implements ConversationPreferenceStore {}

class _MockAgentIdService extends Mock implements AgentIdService {}

class _MockMetroExperienceService extends Mock
    implements MetroExperienceService {}

void main() {
  late _MockFactsIndex factsIndex;
  late _MockPersonalityLearning personalityLearning;
  late _MockConversationPreferenceStore conversationPreferenceStore;
  late _MockAgentIdService agentIdService;
  late _MockMetroExperienceService metroExperienceService;

  setUp(() async {
    await GetIt.instance.reset();
    factsIndex = _MockFactsIndex();
    personalityLearning = _MockPersonalityLearning();
    conversationPreferenceStore = _MockConversationPreferenceStore();
    agentIdService = _MockAgentIdService();
    metroExperienceService = _MockMetroExperienceService();

    GetIt.instance.registerSingleton<ConversationPreferenceStore>(
      conversationPreferenceStore,
    );
    GetIt.instance.registerSingleton<AgentIdService>(agentIdService);
    GetIt.instance.registerSingleton<MetroExperienceService>(
      metroExperienceService,
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  test(
    'buildContext carries governed metro timing into conversation preferences',
    () async {
      final capturedAt = DateTime.utc(2026, 4, 2, 15, 0);
      when(() => factsIndex.retrieveFacts(userId: 'user_123')).thenAnswer(
        (_) async => StructuredFacts(
          traits: const <String>['coffee'],
          places: const <String>['museum_cafe'],
          socialGraph: const <String>['friend_1'],
          timestamp: DateTime.utc(2026, 4, 2, 14, 0),
        ),
      );
      when(() => personalityLearning.getCurrentPersonality('user_123'))
          .thenAnswer(
        (_) async => PersonalityProfile.initial(
          'agent_test',
          userId: 'user_123',
        ),
      );
      when(() => agentIdService.getUserAgentId('user_123'))
          .thenAnswer((_) async => 'agent_user_123');
      when(() => conversationPreferenceStore.get('agent_user_123')).thenAnswer(
        (_) async => ConversationPreferences(
          bypassRate: 0.25,
          totalRagTurns: 3,
          totalBypassTurns: 1,
          lastUpdated: DateTime.utc(2026, 4, 2, 13, 0),
        ),
      );
      when(
        () => metroExperienceService.resolveBestEffort(
          latitude: null,
          longitude: null,
          locationLabel: null,
        ),
      ).thenAnswer(
        (_) async => MetroExperienceContext(
          metroKey: 'bham',
          displayName: 'Birmingham',
          cityCode: 'bham',
          localityCode: 'downtown',
          summary: 'Grounded locality context for Birmingham.',
          categoryKeywords: const <String>['locality'],
          spotPriors: const <String>['Museum Cafe'],
          eventPriors: const <String>['Art Walk'],
          communityPriors: const <String>['Downtown Creative'],
          promptSuggestions: const <String>['Mention downtown context'],
          governedKnowledgeCapturedAtUtc: capturedAt,
          governedKnowledgePhase: 'locality_personal_visit_captured',
        ),
      );

      final builder = RAGContextBuilder(
        factsIndex: factsIndex,
        personalityLearning: personalityLearning,
      );
      final context = await builder.buildContext(userId: 'user_123');

      expect(context.preferences?['traits'], equals(const <String>['coffee']));
      expect(context.conversationPreferences?['bypassRate'], equals(0.25));
      expect(
        context.conversationPreferences?['display_name'],
        equals('Birmingham'),
      );
      expect(
        context.conversationPreferences?['governed_knowledge_phase'],
        equals('locality_personal_visit_captured'),
      );
      expect(
        context.conversationPreferences?['governed_knowledge_captured_at'],
        equals(capturedAt.toIso8601String()),
      );
      expect(
        context.conversationPreferences?['governed_knowledge_timing_summary'],
        contains('effective knowledge ${capturedAt.toIso8601String()}'),
      );
    },
  );
}
