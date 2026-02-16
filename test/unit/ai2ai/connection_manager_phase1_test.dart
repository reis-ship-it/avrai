import 'package:avrai/core/ai/memory/episodic/episodic_memory_store.dart';
import 'package:avrai/core/ai/memory/episodic/outcome_taxonomy.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/aipersonality_node.dart';
import 'package:avrai/core/ai2ai/orchestrator_components.dart';
import 'package:avrai/core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}

class _MockPersonalityLearning extends Mock implements PersonalityLearning {}

class _MockAI2AIProtocol extends Mock implements AI2AIProtocol {}

void main() {
  group('ConnectionManager Phase 1.2.11', () {
    late _MockUserVibeAnalyzer vibeAnalyzer;
    late _MockPersonalityLearning personalityLearning;
    late _MockAI2AIProtocol ai2aiProtocol;
    late EpisodicMemoryStore episodicStore;
    late ConnectionManager manager;

    const localUserId = 'user-local';
    final localPersonality =
        PersonalityProfile.initial('agent-local', userId: localUserId);

    setUpAll(() {
      registerFallbackValue(
        AI2AILearningInsight(
          type: AI2AIInsightType.dimensionDiscovery,
          dimensionInsights: const {},
          learningQuality: 0.0,
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );
    });

    setUp(() async {
      vibeAnalyzer = _MockUserVibeAnalyzer();
      personalityLearning = _MockPersonalityLearning();
      ai2aiProtocol = _MockAI2AIProtocol();
      episodicStore = EpisodicMemoryStore();
      await episodicStore.clearForTesting();

      manager = ConnectionManager(
        vibeAnalyzer: vibeAnalyzer,
        personalityLearning: personalityLearning,
        ai2aiProtocol: ai2aiProtocol,
        episodicMemoryStore: episodicStore,
        outcomeTaxonomy: const OutcomeTaxonomy(),
      );
    });

    test('establish writes ai2ai connection outcome tuple', () async {
      final localVibe = _buildVibe('local-sig');
      final remoteVibe = _buildVibe('remote-sig');
      final remoteNode = AIPersonalityNode(
        nodeId: 'remote-node-1',
        vibe: remoteVibe,
        lastSeen: DateTime.now(),
        trustScore: 0.8,
        learningHistory: const {},
      );
      final compatibility = _buildCompatibility();

      when(() => vibeAnalyzer.compileUserVibe(localUserId, localPersonality))
          .thenAnswer((_) async => localVibe);
      when(() => vibeAnalyzer.analyzeVibeCompatibility(localVibe, remoteVibe))
          .thenAnswer((_) async => compatibility);

      final result = await manager.establish(
        localUserId,
        localPersonality,
        remoteNode,
        (_, __, ___, initialMetrics) async {
          return initialMetrics.updateDuringInteraction(
            newCompatibility: 0.86,
            learningEffectiveness: 0.74,
            aiPleasureScore: 0.82,
            additionalOutcomes: const {'insights_gained': 3},
          );
        },
      );

      expect(result, isNotNull);
      final tuples = await episodicStore.replay(agentId: localUserId);
      expect(tuples, isNotEmpty);
      final tuple = tuples.last;
      expect(tuple.actionType, 'connect_ai2ai');
      expect(tuple.outcome.type, 'ai2ai_connection_outcome');
      expect(tuple.outcome.category, OutcomeCategory.quality);
      expect(tuple.actionPayload['connection_mode'], 'online');
      expect(tuple.outcome.metadata['learning_value'], 0.74);
    });

    test('establishOfflinePeerConnection writes offline outcome tuple',
        () async {
      final localVibe = _buildVibe('local-sig-offline');
      final remoteVibe = _buildVibe('remote-sig-offline');
      final remoteProfile =
          PersonalityProfile.initial('agent-remote', userId: 'user-remote');
      final compatibility = _buildCompatibility();

      when(() => ai2aiProtocol.exchangePersonalityProfile(
            'device-42',
            localPersonality,
          )).thenAnswer((_) async => remoteProfile);
      when(() => vibeAnalyzer.compileUserVibe(localUserId, localPersonality))
          .thenAnswer((_) async => localVibe);
      when(() => vibeAnalyzer.compileUserVibe(
              remoteProfile.agentId, remoteProfile))
          .thenAnswer((_) async => remoteVibe);
      when(() => vibeAnalyzer.analyzeVibeCompatibility(localVibe, remoteVibe))
          .thenAnswer((_) async => compatibility);
      when(() => personalityLearning.evolveFromAI2AILearning(
            localUserId,
            any(),
          )).thenAnswer((_) async => localPersonality);

      final result = await manager.establishOfflinePeerConnection(
        localUserId,
        localPersonality,
        'device-42',
      );

      expect(result, isNotNull);
      final tuples = await episodicStore.replay(agentId: localUserId);
      expect(tuples, isNotEmpty);
      final tuple = tuples.last;
      expect(tuple.actionType, 'connect_ai2ai');
      expect(tuple.actionPayload['connection_mode'], 'offline_peer');
      expect(tuple.outcome.type, 'ai2ai_connection_outcome');
      expect(tuple.outcome.category, OutcomeCategory.quality);
    });
  });
}

VibeCompatibilityResult _buildCompatibility() {
  return VibeCompatibilityResult(
    basicCompatibility: 0.82,
    aiPleasurePotential: 0.79,
    learningOpportunities: [
      LearningOpportunity(
        dimension: 'community_orientation',
        learningPotential: 0.7,
        learningType: LearningType.discovery,
      ),
    ],
    connectionStrength: 0.8,
    interactionStyle: AI2AIInteractionStyle.moderateLearning,
    trustBuildingPotential: 0.75,
    recommendedConnectionDuration: const Duration(minutes: 8),
    connectionPriority: ConnectionPriority.high,
  );
}

UserVibe _buildVibe(String signature) {
  final now = DateTime.now();
  return UserVibe(
    hashedSignature: signature,
    anonymizedDimensions: const {
      'exploration_eagerness': 0.8,
      'community_orientation': 0.7,
      'authenticity_preference': 0.6,
    },
    overallEnergy: 0.75,
    socialPreference: 0.7,
    explorationTendency: 0.72,
    createdAt: now,
    expiresAt: now.add(const Duration(days: 1)),
    privacyLevel: 1.0,
    temporalContext: 'weekday_evening',
  );
}
