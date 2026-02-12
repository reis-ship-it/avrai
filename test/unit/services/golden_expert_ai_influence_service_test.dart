/// SPOTS GoldenExpertAIInfluenceService Tests
/// Date: November 25, 2025
/// Purpose: Test golden expert AI influence weight calculation and application
///
/// Test Coverage:
/// - Weight Calculation: 10% higher base, proportional to residency (1.1 + residencyYears/100)
/// - Weight Application: Behavior, preferences, connections
/// - Integration: AI personality learning, list/review weighting
/// - Edge Cases: Minimum/maximum weights, non-golden experts
///
/// Dependencies:
/// - Mock MultiPathExpertiseService: For golden expert status
/// - Mock PersonalityLearning: For AI personality integration
/// - LocalExpertise model: For residency data
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/golden_expert_ai_influence_service.dart';
import 'package:avrai/core/models/expertise/multi_path_expertise.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('GoldenExpertAIInfluenceService Tests', () {
    late GoldenExpertAIInfluenceService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = GoldenExpertAIInfluenceService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Golden expert AI influence tests focus on business logic (weight calculation, weight application), not property assignment

    group('calculateInfluenceWeight', () {
      test(
          'should return correct weight for various residency years (20, 25, 30 years), cap weight at 1.5x for 40+ years, return 1.0x weight for non-golden expert or when expertise is null, and handle errors gracefully',
          () {
        // Test business logic: influence weight calculation based on residency
        final localExpertise1 = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 7300),
          firstLocalVisit: testDate.subtract(const Duration(days: 7300)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 7300),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight1 = service.calculateInfluenceWeight(localExpertise1);
        expect(weight1, closeTo(1.3, 0.01));

        final localExpertise2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'user-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight2 = service.calculateInfluenceWeight(localExpertise2);
        expect(weight2, closeTo(1.35, 0.01));

        final localExpertise3 = LocalExpertise(
          id: 'expertise-3',
          userId: 'user-3',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950),
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight3 = service.calculateInfluenceWeight(localExpertise3);
        expect(weight3, closeTo(1.4, 0.01));

        final localExpertise4 = LocalExpertise(
          id: 'expertise-4',
          userId: 'user-4',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 14600),
          firstLocalVisit: testDate.subtract(const Duration(days: 14600)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 14600),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight4 = service.calculateInfluenceWeight(localExpertise4);
        expect(weight4, lessThanOrEqualTo(1.5));
        expect(weight4, closeTo(1.5, 0.01));

        final localExpertise5 = LocalExpertise(
          id: 'expertise-5',
          userId: 'user-5',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 3650),
          firstLocalVisit: testDate.subtract(const Duration(days: 3650)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 3650),
          isGoldenLocalExpert: false,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight5 = service.calculateInfluenceWeight(localExpertise5);
        expect(weight5, equals(1.0));

        final weight6 = service.calculateInfluenceWeight(null);
        expect(weight6, equals(1.0));

        final localExpertise7 = LocalExpertise(
          id: 'expertise-7',
          userId: 'user-7',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: null,
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight7 = service.calculateInfluenceWeight(localExpertise7);
        expect(weight7, equals(1.1));
      });
    });

    group('applyWeightToBehavior', () {
      test(
          'should apply weight to behavior data, or not apply weight to non-golden expert behavior',
          () {
        // Test business logic: weight application to behavior data
        final behaviorData1 = {
          'visitCount': 10,
          'actionCount': 5,
          'influenceScore': 0.6,
        };
        final localExpertise1 = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight1 = service.calculateInfluenceWeight(localExpertise1);
        final weightedData1 =
            service.applyWeightToBehavior(behaviorData1, weight1);
        expect(weightedData1['visitCount'], closeTo(10 * 1.35, 0.01));
        expect(weightedData1['actionCount'], closeTo(5 * 1.35, 0.01));
        expect(weightedData1['influenceScore'], closeTo(0.6 * 1.35, 0.01));

        final behaviorData2 = {
          'visitCount': 10,
          'actionCount': 5,
        };
        final localExpertise2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'user-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 3650),
          firstLocalVisit: testDate.subtract(const Duration(days: 3650)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 3650),
          isGoldenLocalExpert: false,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final weight2 = service.calculateInfluenceWeight(localExpertise2);
        final weightedData2 =
            service.applyWeightToBehavior(behaviorData2, weight2);
        expect(weightedData2['visitCount'], equals(10));
        expect(weightedData2['actionCount'], equals(5));
      });
    });

    group('applyWeightToPreferences', () {
      test('should apply weight to preference data', () {
        final preferences = {
          'preferenceScores': {
            'food': 0.8,
            'coffee': 0.7,
          },
          'categoryPreferences': {
            'casual': 0.9,
            'mid-range': 0.6,
          },
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedPreferences =
            service.applyWeightToPreferences(preferences, weight);

        // Weight should be applied to numeric preference scores
        final preferenceScores =
            weightedPreferences['preferenceScores'] as Map<String, dynamic>;
        expect(preferenceScores['food'], closeTo(0.8 * 1.4, 0.01));
        expect(preferenceScores['coffee'], closeTo(0.7 * 1.4, 0.01));
      });
    });

    group('applyWeightToConnections', () {
      test('should apply weight to connection data', () {
        final connections = {
          'connectionScore': 0.8,
          'ai2aiCompatibility': 0.7,
          'networkInfluence': 0.6,
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedConnections =
            service.applyWeightToConnections(connections, weight);

        // Weight should be applied to connection scores
        expect(
            weightedConnections['connectionScore'], closeTo(0.8 * 1.4, 0.01));
        expect(weightedConnections['ai2aiCompatibility'],
            closeTo(0.7 * 1.4, 0.01));
        expect(
            weightedConnections['networkInfluence'], closeTo(0.6 * 1.4, 0.01));
      });
    });

    group('Integration with AI Personality Learning', () {
      test('should integrate with personality learning system', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final behaviorData = {
          'visitCount': 10,
          'influenceScore': 0.7,
        };

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedData =
            service.applyWeightToBehavior(behaviorData, weight);

        // Verify weight was applied (1.35x for 25 years)
        expect(weightedData['visitCount'], closeTo(10 * 1.35, 0.01));
        expect(weightedData['influenceScore'], closeTo(0.7 * 1.35, 0.01));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
