import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/matching/personality_analysis_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Personality Analysis Service Tests
/// Tests personality analysis functionality
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  group('PersonalityAnalysisService Tests', () {
    // Removed: Property assignment tests
    // Personality analysis tests focus on business logic (personality analysis functionality), not property assignment

    group('analyzePersonality', () {
      test(
          'should analyze personality and return analysis map with traits, preferences, and compatibility maps, handle empty user data, or handle complex user data',
          () {
        // Test business logic: personality analysis with various scenarios
        final userData1 = {
          'userId': 'user-123',
          'preferences': {'food': 'Italian', 'music': 'Jazz'},
        };
        final analysis1 =
            PersonalityAnalysisService.analyzePersonality(userData1);
        expect(analysis1, isA<Map<String, dynamic>>());
        expect(analysis1['traits'], isA<Map<String, double>>());
        expect(analysis1['preferences'], isA<Map<String, double>>());
        expect(analysis1['compatibility'], isA<Map<String, double>>());

        final userData2 = <String, dynamic>{};
        final analysis2 =
            PersonalityAnalysisService.analyzePersonality(userData2);
        expect(analysis2, isA<Map<String, dynamic>>());
        expect(analysis2['traits'], isA<Map<String, double>>());
        expect(analysis2['preferences'], isA<Map<String, double>>());
        expect(analysis2['compatibility'], isA<Map<String, double>>());

        final userData3 = {
          'userId': 'user-123',
          'preferences': {
            'food': 'Italian',
            'music': 'Jazz',
            'activities': ['hiking', 'reading'],
          },
          'location': 'San Francisco',
          'age': 30,
        };
        final analysis3 =
            PersonalityAnalysisService.analyzePersonality(userData3);
        expect(analysis3, isA<Map<String, dynamic>>());
        expect(analysis3['traits'], isA<Map<String, double>>());
        expect(analysis3['preferences'], isA<Map<String, double>>());
        expect(analysis3['compatibility'], isA<Map<String, double>>());

        final userData4 = {
          'userId': 'user-123',
          'personality': {
            'exploration_eagerness': 0.8,
            'community_orientation': 0.6,
          },
        };
        final analysis4 =
            PersonalityAnalysisService.analyzePersonality(userData4);
        expect(analysis4, isA<Map<String, dynamic>>());
        expect(analysis4['traits'], isA<Map<String, double>>());
      });
    });
  });
}
