import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/episodic_tuple.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ml/calling_score_neural_model.dart';
import 'package:avrai/core/services/calling_score/calling_score_training_data_preparer.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  group('CallingScoreTrainingDataPreparer', () {
    late EpisodicMemoryStore episodicStore;
    late CallingScoreTrainingDataPreparer preparer;

    setUp(() async {
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();
      preparer = CallingScoreTrainingDataPreparer(
        supabase: _MockSupabaseClient(),
        agentIdService: AgentIdService(),
        neuralModel: CallingScoreNeuralModel(),
        episodicMemoryStore: episodicStore,
      );
    });

    test('buildTrainingRecordsFromEpisodicReplay returns mapped records',
        () async {
      await episodicStore.writeTuple(EpisodicTuple(
        agentId: 'agent-1',
        stateBefore: const {
          'context_features': {'location_proximity': 0.8},
          'timing_features': {'user_patterns': 0.7},
        },
        actionType: 'spot_visited',
        actionPayload: const {
          'spot_vibe_dimensions': {'overall_energy': 0.9},
        },
        nextState: const {},
        outcome: const OutcomeSignal(
          type: 'spot_visited',
          category: OutcomeCategory.binary,
          value: 1.0,
        ),
      ));

      final records = await preparer.buildTrainingRecordsFromEpisodicReplay(
        agentId: 'agent-1',
      );

      expect(records, hasLength(1));
      expect(records.first['outcome_type'], 'positive');
      expect(records.first['outcome_score'], 1.0);
      expect(records.first['formula_calling_score'], 0.5);
    });
  });
}
