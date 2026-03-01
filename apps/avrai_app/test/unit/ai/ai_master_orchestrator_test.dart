import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/ai_master_orchestrator.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/unified_models.dart';

/// AI Master Orchestrator Tests
/// Tests the master AI orchestrator that coordinates all AI systems
void main() {
  group('AIMasterOrchestrator', () {
    late AIMasterOrchestrator orchestrator;

    setUp(() {
      orchestrator = AIMasterOrchestrator();
    });

    tearDown(() async {
      // Clean up: stop learning if it's running
      try {
        await orchestrator.stopComprehensiveLearning();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);
      });

      test('should be initialized after initialize()', () async {
        expect(orchestrator.isInitialized, isTrue);
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);
      });
    });

    group('Legacy API', () {
      test('isInitialized should return true', () {
        expect(orchestrator.isInitialized, isTrue);
      });

      test('processLearningCycle should complete without error', () async {
        await expectLater(
          orchestrator.processLearningCycle(),
          completes,
        );
      });

      test('analyzeCollaborationPatterns should complete without error',
          () async {
        await expectLater(
          orchestrator.analyzeCollaborationPatterns([]),
          completes,
        );
      });

      test('generateRecommendations should return empty list', () async {
        final user = UnifiedUser(
          id: 'test-user',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          preferences: {},
          homebases: [],
          experienceLevel: 1,
          pins: [],
        );
        final recommendations =
            await orchestrator.generateRecommendations(user);
        expect(recommendations, isA<List<String>>());
        expect(recommendations, isEmpty);
      });

      test('updatePersonalityProfile should accept PersonalityProfile',
          () async {
        // Phase 8.3: Use agentId for privacy protection
        final profile =
            PersonalityProfile.initial('agent_test-user', userId: 'test-user');
        await expectLater(
          orchestrator.updatePersonalityProfile(profile),
          completes,
        );
      });

      test('updatePersonalityProfile should accept Map<String, dynamic>',
          () async {
        final profileMap = {
          'userId': 'test-user',
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        await expectLater(
          orchestrator.updatePersonalityProfile(profileMap),
          completes,
        );
      });

      test('stopLearning should complete without error', () async {
        await expectLater(
          orchestrator.stopLearning(),
          completes,
        );
      });

      test('processCompleteAIPipeline should complete without error', () async {
        final interaction = {
          'type': 'test',
          'data': {},
        };
        await expectLater(
          orchestrator.processCompleteAIPipeline(interaction),
          completes,
        );
      });
    });

    group('Comprehensive Learning', () {
      test('should start comprehensive learning', () async {
        await orchestrator.initialize();
        await expectLater(
          orchestrator.startComprehensiveLearning(),
          completes,
        );
      });

      test('should stop comprehensive learning', () async {
        await orchestrator.initialize();
        await orchestrator.startComprehensiveLearning();

        await expectLater(
          orchestrator.stopComprehensiveLearning(),
          completes,
        );
      });

      test('should handle multiple start calls gracefully', () async {
        await orchestrator.initialize();
        await orchestrator.startComprehensiveLearning();

        // Second call should not throw
        await expectLater(
          orchestrator.startComprehensiveLearning(),
          completes,
        );
      });

      test('should handle stop without start', () async {
        await orchestrator.initialize();
        await expectLater(
          orchestrator.stopComprehensiveLearning(),
          completes,
        );
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // Initialize multiple times should not throw
        await orchestrator.initialize();
        await orchestrator.initialize();
        await orchestrator.initialize();

        expect(orchestrator.isInitialized, isTrue);
      });

      test('should handle start/stop cycle multiple times', () async {
        await orchestrator.initialize();

        // Multiple start/stop cycles
        await orchestrator.startComprehensiveLearning();
        await orchestrator.stopComprehensiveLearning();

        await orchestrator.startComprehensiveLearning();
        await orchestrator.stopComprehensiveLearning();

        await orchestrator.startComprehensiveLearning();
        await orchestrator.stopComprehensiveLearning();

        expect(orchestrator.isInitialized, isTrue);
      });
    });

    group('Integration', () {
      test('should complete full lifecycle', () async {
        // Initialize
        await orchestrator.initialize();
        expect(orchestrator.isInitialized, isTrue);

        // Start learning
        await orchestrator.startComprehensiveLearning();

        // Use legacy API while learning
        final user = UnifiedUser(
          id: 'test-user',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          preferences: {},
          homebases: [],
          experienceLevel: 1,
          pins: [],
        );
        final recommendations =
            await orchestrator.generateRecommendations(user);
        expect(recommendations, isA<List<String>>());

        // Process learning cycle
        await orchestrator.processLearningCycle();

        // Stop learning
        await orchestrator.stopComprehensiveLearning();

        // Verify still initialized
        expect(orchestrator.isInitialized, isTrue);
      });

      test('should handle concurrent operations', () async {
        await orchestrator.initialize();
        await orchestrator.startComprehensiveLearning();

        // Run multiple operations concurrently
        final testUser = UnifiedUser(
          id: 'test-user',
          name: 'Test User',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          preferences: {},
          homebases: [],
          experienceLevel: 1,
          pins: [],
        );
        final futures = [
          orchestrator.processLearningCycle(),
          orchestrator.generateRecommendations(testUser),
          orchestrator.analyzeCollaborationPatterns([]),
        ];

        await expectLater(
          Future.wait(futures),
          completes,
        );

        await orchestrator.stopComprehensiveLearning();
      });
    });
  });
}
