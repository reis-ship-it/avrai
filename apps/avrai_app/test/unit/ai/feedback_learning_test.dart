import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/ai/feedback_learning.dart'
    show
        UserFeedbackAnalyzer,
        FeedbackEvent,
        FeedbackType,
        FeedbackAnalysisResult,
        BehavioralPattern,
        SatisfactionPrediction,
        FeedbackLearningInsights;
import 'package:avrai_runtime_os/ai/personality_learning.dart'
    show PersonalityLearning;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

import '../../helpers/platform_channel_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserFeedbackAnalyzer', () {
    late UserFeedbackAnalyzer analyzer;
    late SharedPreferencesCompat prefs;
    late PersonalityLearning personalityLearning;

    setUpAll(() async {
      await setupTestStorage();
    });

    setUp(() async {
      prefs =
          await SharedPreferencesCompat.getInstance(storage: getTestStorage());
      personalityLearning = PersonalityLearning.withPrefs(prefs);
      analyzer = UserFeedbackAnalyzer(
        prefs: prefs,
        personalityLearning: personalityLearning,
      );
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });

    group('Feedback Analysis', () {
      test('should analyze feedback without errors', () async {
        const userId = 'test-user-123';
        final feedback = FeedbackEvent(
          type: FeedbackType.recommendation,
          satisfaction: 0.8,
          metadata: {},
          timestamp: DateTime.now(),
        );

        final result = await analyzer.analyzeFeedback(userId, feedback);

        expect(result, isA<FeedbackAnalysisResult>());
        expect(result.userId, equals(userId));
        expect(result.feedback, equals(feedback));
        expect(result.confidenceScore, greaterThanOrEqualTo(0.0));
        expect(result.confidenceScore, lessThanOrEqualTo(1.0));
      });

      test('should handle different feedback types', () async {
        const userId = 'test-user-123';
        final feedback = FeedbackEvent(
          type: FeedbackType.spotExperience,
          satisfaction: 0.6,
          metadata: {},
          timestamp: DateTime.now(),
        );

        final result = await analyzer.analyzeFeedback(userId, feedback);

        expect(result, isA<FeedbackAnalysisResult>());
        expect(result.feedback.type, equals(FeedbackType.spotExperience));
      });
    });

    group('Behavioral Pattern Identification', () {
      test('should identify behavioral patterns without errors', () async {
        const userId = 'test-user-123';

        final patterns = await analyzer.identifyBehavioralPatterns(userId);

        expect(patterns, isA<List<BehavioralPattern>>());
      });

      test('should return empty list for insufficient feedback history',
          () async {
        const userId = 'new-user';

        final patterns = await analyzer.identifyBehavioralPatterns(userId);

        expect(patterns, isEmpty);
      });
    });

    group('Dimension Extraction', () {
      test('should extract new dimensions without errors', () async {
        const userId = 'test-user-123';

        // Provide recent feedback input (required by updated API)
        final dimensions =
            await analyzer.extractNewDimensions(userId, const []);

        expect(dimensions, isA<Map<String, double>>());
      });
    });

    group('Satisfaction Prediction', () {
      test('should predict user satisfaction without errors', () async {
        const userId = 'test-user-123';
        final scenario = {
          'type': 'spot_recommendation',
          'category': 'food',
        };

        final prediction =
            await analyzer.predictUserSatisfaction(userId, scenario);

        expect(prediction, isA<SatisfactionPrediction>());
        expect(prediction.predictedSatisfaction, greaterThanOrEqualTo(0.0));
        expect(prediction.predictedSatisfaction, lessThanOrEqualTo(1.0));
        expect(prediction.confidence, greaterThanOrEqualTo(0.0));
        expect(prediction.confidence, lessThanOrEqualTo(1.0));
      });
    });

    group('Feedback Insights', () {
      test('should get feedback insights without errors', () async {
        const userId = 'test-user-123';

        final insights = await analyzer.getFeedbackInsights(userId);

        expect(insights, isA<FeedbackLearningInsights>());
        expect(insights.userId, equals(userId));
      });
    });
  });
}
