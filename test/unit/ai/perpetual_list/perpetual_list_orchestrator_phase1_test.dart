import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/perpetual_list/analyzers/location_pattern_analyzer.dart';
import 'package:avrai/core/ai/perpetual_list/analyzers/string_theory_possibility_engine.dart';
import 'package:avrai/core/ai/perpetual_list/engines/context_engine.dart';
import 'package:avrai/core/ai/perpetual_list/engines/generation_engine.dart';
import 'package:avrai/core/ai/perpetual_list/engines/trigger_engine.dart';
import 'package:avrai/core/ai/perpetual_list/filters/age_aware_list_filter.dart';
import 'package:avrai/core/ai/perpetual_list/integration/ai2ai_list_learning_integration.dart';
import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:avrai/core/ai/perpetual_list/perpetual_list_orchestrator.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTriggerEngine extends Mock implements TriggerEngine {}

class _MockContextEngine extends Mock implements ContextEngine {}

class _MockGenerationEngine extends Mock implements GenerationEngine {}

class _MockLocationPatternAnalyzer extends Mock
    implements LocationPatternAnalyzer {}

class _MockStringTheoryPossibilityEngine extends Mock
    implements StringTheoryPossibilityEngine {}

class _MockAgeAwareListFilter extends Mock implements AgeAwareListFilter {}

class _MockAI2AIListLearningIntegration extends Mock
    implements AI2AIListLearningIntegration {}

class _MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('PerpetualListOrchestrator Phase 1.2.7', () {
    test(
        'processListInteraction records episodic tuple while preserving AI2AI learning',
        () async {
      final episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();

      final ai2aiIntegration = _MockAI2AIListLearningIntegration();
      final agentIdService = _MockAgentIdService();
      final interaction = ListInteraction(
        type: ListInteractionType.dismissed,
        listId: 'list-42',
        timestamp: DateTime.utc(2026, 2, 16, 12, 0, 0),
      );

      when(() => ai2aiIntegration.learnFromListInteraction(
            userId: 'user-1',
            userAge: 24,
            interaction: interaction,
          )).thenAnswer((_) async => true);
      when(() => agentIdService.getUserAgentId('user-1'))
          .thenAnswer((_) async => 'agent-1');

      final orchestrator = PerpetualListOrchestrator(
        triggerEngine: _MockTriggerEngine(),
        contextEngine: _MockContextEngine(),
        generationEngine: _MockGenerationEngine(),
        locationAnalyzer: _MockLocationPatternAnalyzer(),
        possibilityEngine: _MockStringTheoryPossibilityEngine(),
        ageFilter: _MockAgeAwareListFilter(),
        ai2aiIntegration: ai2aiIntegration,
        episodicMemoryStore: episodicStore,
        agentIdService: agentIdService,
      );

      await orchestrator.processListInteraction(
        userId: 'user-1',
        userAge: 24,
        interaction: interaction,
      );

      verify(() => ai2aiIntegration.learnFromListInteraction(
            userId: 'user-1',
            userAge: 24,
            interaction: interaction,
          )).called(1);
      verify(() => agentIdService.getUserAgentId('user-1')).called(1);
      final tuples = await episodicStore.replay(agentId: 'agent-1');
      expect(tuples, hasLength(1));
      expect(tuples.first.actionType, 'list_dismissed');
      expect(tuples.first.actionPayload['listId'], 'list-42');
      expect(tuples.first.metadata['agent_id_source'], 'agent_id_service');
    });

    test(
        'processListInteraction falls back to userId when AgentIdService fails',
        () async {
      final episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();

      final ai2aiIntegration = _MockAI2AIListLearningIntegration();
      final agentIdService = _MockAgentIdService();
      final interaction = ListInteraction(
        type: ListInteractionType.viewed,
        listId: 'list-fallback',
        timestamp: DateTime.utc(2026, 2, 16, 12, 30, 0),
      );

      when(() => ai2aiIntegration.learnFromListInteraction(
            userId: 'user-fallback',
            userAge: 31,
            interaction: interaction,
          )).thenAnswer((_) async => true);
      when(() => agentIdService.getUserAgentId('user-fallback'))
          .thenThrow(Exception('mapping unavailable'));

      final orchestrator = PerpetualListOrchestrator(
        triggerEngine: _MockTriggerEngine(),
        contextEngine: _MockContextEngine(),
        generationEngine: _MockGenerationEngine(),
        locationAnalyzer: _MockLocationPatternAnalyzer(),
        possibilityEngine: _MockStringTheoryPossibilityEngine(),
        ageFilter: _MockAgeAwareListFilter(),
        ai2aiIntegration: ai2aiIntegration,
        episodicMemoryStore: episodicStore,
        agentIdService: agentIdService,
      );

      await orchestrator.processListInteraction(
        userId: 'user-fallback',
        userAge: 31,
        interaction: interaction,
      );

      verify(() => ai2aiIntegration.learnFromListInteraction(
            userId: 'user-fallback',
            userAge: 31,
            interaction: interaction,
          )).called(1);
      verify(() => agentIdService.getUserAgentId('user-fallback')).called(1);

      final tuples = await episodicStore.replay(agentId: 'user-fallback');
      expect(tuples, hasLength(1));
      expect(tuples.first.actionType, 'list_viewed');
      expect(tuples.first.metadata['agent_id_source'], 'user_id_fallback');
    });
  });
}
