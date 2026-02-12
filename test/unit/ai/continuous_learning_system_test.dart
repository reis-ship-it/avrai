import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';

/// Continuous Learning System Tests
/// Tests the AI system that learns from everything continuously
/// OUR_GUTS.md: "AI that learns and improves itself every second"
void main() {
  group('ContinuousLearningSystem', () {
    late ContinuousLearningSystem system;

    setUp(() {
      // Create system without Supabase for unit tests
      system = ContinuousLearningSystem(
        agentIdService: AgentIdService(),
        supabase: null, // No Supabase in unit tests
      );
    });

    tearDown(() async {
      // Clean up: stop learning if active
      if (system.isLearningActive) {
        await system.stopContinuousLearning();
      }
    });

    group('Initialization', () {
      test('should initialize without errors', () async {
        await expectLater(
          system.initialize(),
          completes,
        );
      });
    });

    group('Continuous Learning Lifecycle', () {
      test('should start continuous learning', () async {
        await system.initialize();
        await expectLater(
          system.startContinuousLearning(),
          completes,
        );
        expect(system.isLearningActive, isTrue);
      });

      test('should stop continuous learning', () async {
        await system.initialize();
        await system.startContinuousLearning();
        await expectLater(
          system.stopContinuousLearning(),
          completes,
        );
        expect(system.isLearningActive, isFalse);
      });

      test('should handle multiple start calls gracefully', () async {
        await system.initialize();
        await system.startContinuousLearning();
        await system.startContinuousLearning(); // Second call should not error
        expect(system.isLearningActive, isTrue);
      });
    });

    group('User Interaction Processing', () {
      test('should process user interaction without errors', () async {
        await system.initialize();
        final payload = {
          'event_type': 'spot_visited',
          'parameters': {},
          'context': {},
        };
        await expectLater(
          system.processUserInteraction(
            userId: 'test-user-id',
            payload: payload,
          ),
          completes,
        );
      });

      test('should handle empty payload', () async {
        await system.initialize();
        await expectLater(
          system.processUserInteraction(
            userId: 'test-user-id',
            payload: {},
          ),
          completes,
        );
      });
    });

    group('Model Operations', () {
      test('should train model without errors', () async {
        await system.initialize();
        await expectLater(
          system.trainModel({'data': 'test'}),
          completes,
        );
      });

      test('should evaluate model and return score', () async {
        await system.initialize();
        final score = await system.evaluateModel({'data': 'test'});
        expect(score, isA<double>());
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should update model in realtime', () async {
        await system.initialize();
        final payload = {
          'update': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        };
        await expectLater(
          system.updateModelRealtime(payload),
          completes,
        );
      });

      test('should make predictions', () async {
        await system.initialize();
        final predictions = await system.predict({
          'context': 'test',
        });
        expect(predictions, isA<Map<String, double>>());
      });
    });

    group('Learning State', () {
      test('should track learning active state', () async {
        expect(system.isLearningActive, isFalse);
        await system.initialize();
        await system.startContinuousLearning();
        expect(system.isLearningActive, isTrue);
        await system.stopContinuousLearning();
        expect(system.isLearningActive, isFalse);
      });
    });
  });
}

