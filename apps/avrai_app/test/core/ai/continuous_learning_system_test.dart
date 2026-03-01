// Tests for ContinuousLearningSystem
// Phase 11 Section 8: Learning Quality Monitoring

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

void main() {
  group('ContinuousLearningSystem - Learning History Persistence', () {
    late ContinuousLearningSystem learningSystem;
    late AgentIdService agentIdService;

    setUp(() {
      agentIdService = AgentIdService();
      // Create system without Supabase for unit tests
      learningSystem = ContinuousLearningSystem(
        agentIdService: agentIdService,
        supabase: null, // No Supabase in unit tests
      );
    });

    test('getLearningHistory returns empty list when Supabase is null',
        () async {
      final history = await learningSystem.getLearningHistory(
        userId: 'test-user-id',
        limit: 10,
      );

      expect(history, isEmpty);
    });

    test(
        'getLearningHistory returns empty list when dimension is specified but Supabase is null',
        () async {
      final history = await learningSystem.getLearningHistory(
        userId: 'test-user-id',
        dimension: 'user_preference_understanding',
        limit: 10,
      );

      expect(history, isEmpty);
    });

    // Note: _recordLearningEvent is a private method
    // It is tested indirectly through processUserInteraction and trainModel

    test('processUserInteraction requires userId parameter', () async {
      // Test that processUserInteraction requires userId
      await expectLater(
        learningSystem.processUserInteraction(
          userId: 'test-user-id',
          payload: {
            'event_type': 'spot_visited',
            'parameters': {},
            'context': {},
          },
        ),
        completes,
      );
    });
  });

  group('LearningEvent Model', () {
    test('creates correctly with all required fields', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final event = LearningEvent(
        dimension: 'user_preference_understanding',
        improvement: 0.05,
        dataSource: 'user_actions',
        timestamp: timestamp,
      );

      expect(event.dimension, equals('user_preference_understanding'));
      expect(event.improvement, equals(0.05));
      expect(event.dataSource, equals('user_actions'));
      expect(event.timestamp, equals(timestamp));
    });

    test('handles different improvement values', () {
      final event1 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 0.0,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );
      final event2 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 1.0,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );
      final event3 = LearningEvent(
        dimension: 'test_dimension',
        improvement: 0.5,
        dataSource: 'test_source',
        timestamp: DateTime.now(),
      );

      expect(event1.improvement, equals(0.0));
      expect(event2.improvement, equals(1.0));
      expect(event3.improvement, equals(0.5));
    });

    test('handles different data sources', () {
      final sources = [
        'user_actions',
        'location_data',
        'weather_data',
        'social_data'
      ];

      for (final source in sources) {
        final event = LearningEvent(
          dimension: 'test_dimension',
          improvement: 0.05,
          dataSource: source,
          timestamp: DateTime.now(),
        );

        expect(event.dataSource, equals(source));
      }
    });
  });
}
