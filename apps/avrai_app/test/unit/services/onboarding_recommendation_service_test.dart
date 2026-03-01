/// SPOTS OnboardingRecommendationService Tests
/// Date: December 15, 2025
/// Purpose: Test OnboardingRecommendationService functionality
///
/// Test Coverage:
/// - List Recommendations: Recommending lists based on onboarding
/// - Account Recommendations: Recommending accounts based on onboarding
/// - Compatibility Calculation: Calculating compatibility scores
/// - Privacy Protection: userId → agentId conversion validation
/// - Edge Cases: Empty data, no matches, invalid inputs
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../helpers/test_helpers.dart';

// Mock classes
class MockAgentIdService extends Mock implements AgentIdService {}

void main() {
  group('OnboardingRecommendationService Tests', () {
    late OnboardingRecommendationService service;
    late MockAgentIdService mockAgentIdService;
    const String testUserId = 'user_123';
    const String testAgentId = 'agent_abc123def456ghi789jkl012mno345pqr678';

    setUp(() {
      TestHelpers.setupTestEnvironment();
      mockAgentIdService = MockAgentIdService();
      service = OnboardingRecommendationService(
        agentIdService: mockAgentIdService,
      );

      // Setup mock default behavior
      when(() => mockAgentIdService.getUserAgentId(testUserId))
          .thenAnswer((_) async => testAgentId);
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Get Recommended Lists', () {
      test('should return list of recommendations with compatibility scores',
          () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee', 'Craft Beer'],
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test('should limit recommendations to maxRecommendations parameter',
          () async {
        // Arrange
        final onboardingData = {
          'preferences': {
            'Food & Drink': ['Coffee']
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7
        };

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 5,
        );

        // Assert
        expect(recommendations.length, lessThanOrEqualTo(5));
      });

      test('should convert userId to agentId for privacy protection', () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{
            'exploration_eagerness': 0.7,
            'curation_tendency': 0.6,
          },
        );

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test('should handle empty onboarding data gracefully', () async {
        // Arrange
        final onboardingData = <String, dynamic>{};
        final personalityDimensions = <String, double>{};

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
      });

      test('should handle errors gracefully and return empty list', () async {
        // Arrange
        when(() => mockAgentIdService.getUserAgentId(testUserId))
            .thenThrow(Exception('Service error'));

        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: {},
          personalityDimensions: {},
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
        expect(recommendations.isEmpty, isTrue);
      });
    });

    group('Get Recommended Accounts', () {
      test(
          'should return list of account recommendations with compatibility scores',
          () async {
        // Arrange
        final onboardingData = <String, dynamic>{
          'preferences': {
            'Activities': ['Hiking', 'Live Music'],
          },
          'homebase': 'San Francisco, CA',
        };
        final personalityDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'community_orientation': 0.6,
        };

        // Act
        final recommendations = await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: personalityDimensions,
          maxRecommendations: 10,
        );

        // Assert
        expect(recommendations, isA<List<AccountRecommendation>>());
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });

      test(
          'should limit account recommendations to maxRecommendations parameter',
          () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        final recommendations = await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{},
          maxRecommendations: 3,
        );

        // Assert
        expect(recommendations.length, lessThanOrEqualTo(3));
      });

      test('should convert userId to agentId for privacy protection', () async {
        // Arrange
        final onboardingData = {'preferences': {}};

        // Act
        await service.getRecommendedAccounts(
          userId: testUserId,
          onboardingData: onboardingData,
          personalityDimensions: <String, double>{},
        );

        // Assert
        verify(() => mockAgentIdService.getUserAgentId(testUserId)).called(1);
      });
    });

    group('Calculate Compatibility', () {
      test(
          'should calculate compatibility score between user and list dimensions',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
          'location_adventurousness': 0.8,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.75,
          'curation_tendency': 0.65,
          'location_adventurousness': 0.85,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
        expect(
            score, greaterThan(0.5)); // Should be high for similar dimensions
      });

      test(
          'should return low compatibility score for very different dimensions',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.9,
          'curation_tendency': 0.8,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.1,
          'curation_tendency': 0.2,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, lessThan(0.5)); // Should be low for different dimensions
      });

      test('should return zero when user dimensions are empty', () {
        // Arrange
        final userDimensions = <String, double>{};
        final listDimensions = {
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(0.0));
      });

      test('should return zero when list dimensions are empty', () {
        // Arrange
        final userDimensions = {
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{};

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(0.0));
      });

      test('should return perfect compatibility for identical dimensions', () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, equals(1.0));
      });

      test(
          'should only consider matching dimensions in compatibility calculation',
          () {
        // Arrange
        final userDimensions = <String, double>{
          'exploration_eagerness': 0.7,
          'curation_tendency': 0.6,
        };
        final listDimensions = <String, double>{
          'exploration_eagerness': 0.8, // Matching but different value
          'location_adventurousness':
              0.8, // Different dimension, should be ignored
        };

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThan(0.0));
        expect(score, lessThan(1.0));
        // Should only consider exploration_eagerness match (0.7 vs 0.8 = 0.9 compatibility)
      });
    });

    group('ListRecommendation Model', () {
      // Removed: Constructor-only test - tests Dart constructor, not business logic

      test(
          'should serialize to JSON with correct structure for storage and transmission',
          () {
        // Arrange
        final recommendation = ListRecommendation(
          listId: 'list_123',
          listName: 'Coffee Lovers',
          curatorName: 'John Doe',
          description: 'Best coffee spots',
          compatibilityScore: 0.85,
          matchingReasons: ['Similar interests', 'Same location'],
          metadata: {'source': 'onboarding'},
        );

        // Act
        final json = recommendation.toJson();

        // Assert - Test business logic: JSON structure is correct for system use
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('listId'), isTrue);
        expect(json.containsKey('compatibilityScore'), isTrue);
        expect(json['compatibilityScore'], isA<double>());
        // JSON should be usable for storage/transmission
        expect(json['listId'], equals('list_123'));
      });
    });

    group('AccountRecommendation Model', () {
      // Removed: Constructor-only test - tests Dart constructor, not business logic

      test(
          'should serialize to JSON with correct structure for storage and transmission',
          () {
        // Arrange
        final recommendation = AccountRecommendation(
          accountId: 'account_123',
          accountName: 'coffee_explorer',
          displayName: 'Coffee Explorer',
          description: 'Coffee enthusiast',
          compatibilityScore: 0.80,
          matchingReasons: ['Similar interests', 'Same location'],
          metadata: {'source': 'onboarding'},
        );

        // Act
        final json = recommendation.toJson();

        // Assert - Test business logic: JSON structure is correct for system use
        expect(json, isA<Map<String, dynamic>>());
        expect(json.containsKey('accountId'), isTrue);
        expect(json.containsKey('compatibilityScore'), isTrue);
        expect(json['compatibilityScore'], isA<double>());
        // JSON should be usable for storage/transmission
        expect(json['accountId'], equals('account_123'));
      });
    });

    group('Edge Cases', () {
      test('should handle null personality dimensions', () async {
        // Act
        final recommendations = await service.getRecommendedLists(
          userId: testUserId,
          onboardingData: {},
          personalityDimensions: {},
        );

        // Assert
        expect(recommendations, isA<List<ListRecommendation>>());
      });

      test('should handle very large personality dimension maps', () {
        // Arrange
        final userDimensions = Map.fromEntries(
          List.generate(50, (i) => MapEntry('dimension_$i', 0.5)),
        );
        final listDimensions = Map.fromEntries(
          List.generate(50, (i) => MapEntry('dimension_$i', 0.6)),
        );

        // Act
        final score = service.calculateCompatibility(
          userDimensions: userDimensions,
          listDimensions: listDimensions,
        );

        // Assert
        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });
    });
  });
}
