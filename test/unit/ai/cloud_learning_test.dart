import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai/core/ai/cloud_learning.dart' show CloudLearningInterface, CloudContributionResult, CloudLearningResult, CollectiveIntelligenceTrends, CloudBasedRecommendations, CloudLearningMetrics;
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_core/models/personality_profile.dart';

import 'cloud_learning_test.mocks.dart';

@GenerateMocks([SharedPreferences, PersonalityLearning])
void main() {
  group('CloudLearningInterface', () {
    late CloudLearningInterface cloudLearning;
    late MockSharedPreferences mockPrefs;
    late MockPersonalityLearning mockPersonalityLearning;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockPersonalityLearning = MockPersonalityLearning();
      
      cloudLearning = CloudLearningInterface(
        prefs: mockPrefs,
        personalityLearning: mockPersonalityLearning,
      );
    });

    group('Cloud Contribution', () {
      test('should contribute anonymous patterns without errors', () async {
        const userId = 'test-user-123';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);
        final context = {'source': 'test'};

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await cloudLearning.contributeAnonymousPatterns(
          userId,
          profile,
          context,
        );

        expect(result, isA<CloudContributionResult>());
        expect(result.userId, equals(userId));
        expect(result.anonymizationLevel, greaterThanOrEqualTo(0.0));
        expect(result.privacyScore, greaterThanOrEqualTo(0.0));
      });

      test('should handle contribution errors gracefully', () async {
        const userId = 'test-user-123';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);

        when(mockPrefs.getString(any)).thenThrow(Exception('Storage error'));

        final result = await cloudLearning.contributeAnonymousPatterns(
          userId,
          profile,
          {},
        );

        expect(result, isA<CloudContributionResult>());
        expect(result.uploadSuccess, isFalse);
      });
    });

    group('Cloud Learning', () {
      test('should learn from cloud patterns without errors', () async {
        const userId = 'test-user-123';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);

        when(mockPrefs.getString(any)).thenReturn(null);
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        final result = await cloudLearning.learnFromCloudPatterns(
          userId,
          profile,
        );

        expect(result, isA<CloudLearningResult>());
        expect(result.userId, equals(userId));
      });

      test('should handle empty cloud patterns', () async {
        const userId = 'test-user-123';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);

        when(mockPrefs.getString(any)).thenReturn(null);

        final result = await cloudLearning.learnFromCloudPatterns(
          userId,
          profile,
        );

        expect(result, isA<CloudLearningResult>());
      });
    });

    group('Collective Trends Analysis', () {
      test('should analyze collective trends without errors', () async {
        const communityContext = 'San Francisco';

        when(mockPrefs.getString(any)).thenReturn(null);

        final trends = await cloudLearning.analyzeCollectiveTrends(communityContext);

        expect(trends, isA<CollectiveIntelligenceTrends>());
        expect(trends.communityContext, equals(communityContext));
      });
    });

    group('Cloud Recommendations', () {
      test('should generate cloud recommendations without errors', () async {
        const userId = 'test-user-123';
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_$userId';
        final profile = PersonalityProfile.initial(agentId, userId: userId);

        when(mockPrefs.getString(any)).thenReturn(null);

        final recommendations = await cloudLearning.generateCloudRecommendations(
          userId,
          profile,
        );

        expect(recommendations, isA<CloudBasedRecommendations>());
      });
    });

    group('Learning Impact Measurement', () {
      test('should measure cloud learning impact without errors', () async {
        const userId = 'test-user-123';
        const timeWindow = Duration(days: 30);

        when(mockPrefs.getString(any)).thenReturn(null);

        final metrics = await cloudLearning.measureCloudLearningImpact(
          userId,
          timeWindow,
        );

        expect(metrics, isA<CloudLearningMetrics>());
        expect(metrics.userId, equals(userId));
      });
    });
  });
}

