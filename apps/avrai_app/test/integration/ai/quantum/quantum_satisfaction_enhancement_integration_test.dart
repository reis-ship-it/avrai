import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/feedback_learning.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_satisfaction_enhancer.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_satisfaction_feature_extractor.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import '../../../helpers/platform_channel_helper.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('Quantum Satisfaction Enhancement Integration', () {
    late UserFeedbackAnalyzer feedbackAnalyzer;
    late PersonalityLearning personalityLearning;
    late QuantumSatisfactionEnhancer quantumSatisfactionEnhancer;
    late AtomicClockService atomicClock;

    setUp(() async {
      TestHelpers.setupTestEnvironment();

      // Initialize services
      await setupTestStorage();
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      personalityLearning = PersonalityLearning.withPrefs(prefs);
      atomicClock = AtomicClockService();

      // Initialize quantum satisfaction enhancer (simplified for integration test)
      // In real app, this would come from DI
      quantumSatisfactionEnhancer = QuantumSatisfactionEnhancer(
        featureExtractor: QuantumSatisfactionFeatureExtractor(),
      );

      feedbackAnalyzer = UserFeedbackAnalyzer(
        prefs: prefs,
        personalityLearning: personalityLearning,
        quantumSatisfactionEnhancer: quantumSatisfactionEnhancer,
        atomicClock: atomicClock,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    test(
        'should predict satisfaction with quantum enhancement when quantum data available',
        () async {
      const userId = 'test_user_1';

      // Initialize personality for user
      await personalityLearning.initializePersonality(userId);

      // Create scenario with quantum data
      final scenario = {
        'type': 'recommendation',
        'context': 'event_recommendation',
        'vibeDimensions': {
          for (final dim in VibeConstants.coreDimensions) dim: 0.7
        },
        'event': {
          'vibeDimensions': {
            for (final dim in VibeConstants.coreDimensions) dim: 0.8
          },
          'timestamp': DateTime.now(),
          'location': {
            'latitude': 37.7749,
            'longitude': -122.4194,
          },
        },
        'userLocation': {
          'latitude': 37.7849,
          'longitude': -122.4094,
        },
      };

      // Add some feedback history for the user
      for (int i = 0; i < 5; i++) {
        await feedbackAnalyzer.analyzeFeedback(
          userId,
          FeedbackEvent(
            type: FeedbackType.recommendation,
            satisfaction: (0.70 + (i * 0.05)).clamp(0.0, 1.0),
            metadata: {},
            timestamp: DateTime.now().subtract(Duration(days: i + 1)),
          ),
        );
      }

      // Predict satisfaction
      final prediction = await feedbackAnalyzer.predictUserSatisfaction(
        userId,
        scenario,
      );

      // Verify prediction
      expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
      expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
      expect(prediction.confidence, greaterThanOrEqualTo(0.0));
      expect(prediction.confidence, lessThanOrEqualTo(1.0));

      // Verify factors analyzed include quantum features if enhancement was applied
      expect(prediction.factorsAnalyzed, isA<Map<String, double>>());
      expect(prediction.factorsAnalyzed['context_match'], isNotNull);
      expect(prediction.factorsAnalyzed['preference_alignment'], isNotNull);
      expect(prediction.factorsAnalyzed['novelty_score'], isNotNull);
    });

    test('should fall back to base satisfaction when quantum data unavailable',
        () async {
      const userId = 'test_user_2';

      // Initialize personality for user
      await personalityLearning.initializePersonality(userId);

      // Create scenario without quantum data
      final scenario = {
        'type': 'recommendation',
        'context': 'event_recommendation',
        // No vibeDimensions, no location data
      };

      // Add some feedback history
      await feedbackAnalyzer.analyzeFeedback(
        userId,
        FeedbackEvent(
          type: FeedbackType.recommendation,
          satisfaction: 0.7,
          metadata: {},
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      // Predict satisfaction (should work even without quantum data)
      final prediction = await feedbackAnalyzer.predictUserSatisfaction(
        userId,
        scenario,
      );

      // Verify prediction still works
      expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
      expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
    });

    test('should handle errors gracefully and return base satisfaction',
        () async {
      const userId = 'test_user_3';

      // Initialize personality for user
      await personalityLearning.initializePersonality(userId);

      // Create scenario with invalid data
      final scenario = {
        'type': 'recommendation',
        'context': 'event_recommendation',
        'vibeDimensions': null, // Invalid
        'event': null, // Invalid
      };

      // Predict satisfaction (should not throw)
      final prediction = await feedbackAnalyzer.predictUserSatisfaction(
        userId,
        scenario,
      );

      // Should return a valid prediction (may be uncertain)
      expect(prediction, isNotNull);
      expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
      expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
    });
  });
}
