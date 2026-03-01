import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_service.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_core/models/expertise/expertise_pin.dart';
import 'package:avrai_core/models/expertise/expertise_progress.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expertise Service Tests
/// OUR_GUTS.md: "Pins, Not Badges" - Tests expertise calculation based on authentic contributions
void main() {
  group('ExpertiseService Tests', () {
    late ExpertiseService service;

    setUp(() {
      service = ExpertiseService();
    });

    // Removed: Property assignment tests
    // Expertise level calculation tests focus on business logic (thresholds, location handling), not property assignment

    group('calculateExpertiseLevel', () {
      test(
          'should calculate correct expertise level based on contributions and trust, with location support',
          () {
        // Test business logic: expertise level calculation with various thresholds
        // Local level
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 1,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.local),
        );
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 0,
            thoughtfulReviewsCount: 10,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.local),
        );

        // City level
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 3,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.city),
        );
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 0,
            thoughtfulReviewsCount: 25,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.city),
        );

        // Regional level
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 6,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.regional),
        );

        // National level
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 11,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
          ),
          equals(ExpertiseLevel.national),
        );

        // Global level (requires high trust)
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 21,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.8,
          ),
          equals(ExpertiseLevel.global),
        );

        // Test location parameter
        expect(
          service.calculateExpertiseLevel(
            respectedListsCount: 3,
            thoughtfulReviewsCount: 0,
            spotsReviewedCount: 0,
            communityTrustScore: 0.5,
            location: 'San Francisco',
          ),
          equals(ExpertiseLevel.city),
        );
      });
    });

    group('getUserPins', () {
      test(
          'should return pins from user expertise map or empty list if no expertise',
          () {
        // Test business logic: pin extraction with empty case handling
        final userWithExpertise = ModelFactories.createTestUser(
          id: 'test-user',
          tags: ['food', 'travel'],
        ).copyWith(
          expertiseMap: {
            'food': 'city',
            'travel': 'local',
          },
        );

        final pins = service.getUserPins(userWithExpertise);
        expect(pins, isA<List<ExpertisePin>>());
        expect(pins.length, equals(2));
        expect(pins[0].category, equals('food'));
        expect(pins[1].category, equals('travel'));

        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'test-user',
          tags: [],
        );
        expect(service.getUserPins(userWithoutExpertise), isEmpty);
      });
    });

    group('calculateProgress', () {
      test(
          'should calculate progress toward next level with contribution breakdown, and return 100% for highest level',
          () {
        // Test business logic: progress calculation with breakdown and highest level handling
        final progress1 = service.calculateProgress(
          category: 'food',
          location: 'San Francisco',
          currentLevel: ExpertiseLevel.local,
          respectedListsCount: 2,
          thoughtfulReviewsCount: 8,
          spotsReviewedCount: 15,
          communityTrustScore: 0.6,
        );

        expect(progress1, isA<ExpertiseProgress>());
        expect(progress1.category, equals('food'));
        expect(progress1.currentLevel, equals(ExpertiseLevel.local));
        expect(progress1.nextLevel, equals(ExpertiseLevel.city));
        expect(progress1.progressPercentage, greaterThanOrEqualTo(0.0));
        expect(progress1.progressPercentage, lessThanOrEqualTo(100.0));
        expect(progress1.contributionBreakdown['lists'], equals(2));
        expect(progress1.contributionBreakdown['reviews'], equals(8));
        expect(progress1.contributionBreakdown['spots'], equals(15));

        // Test highest level (100% progress, no next level)
        final progress2 = service.calculateProgress(
          category: 'food',
          location: null,
          currentLevel: ExpertiseLevel.universal,
          respectedListsCount: 25,
          thoughtfulReviewsCount: 250,
          spotsReviewedCount: 100,
          communityTrustScore: 0.9,
        );
        expect(progress2.progressPercentage, equals(100.0));
        expect(progress2.nextLevel, isNull);
      });
    });

    group('canEarnPin', () {
      test(
          'should return true for sufficient contributions and trust, or false for insufficient contributions or low trust',
          () {
        // Test business logic: pin eligibility validation
        expect(
          service.canEarnPin(
            category: 'food',
            respectedListsCount: 1,
            thoughtfulReviewsCount: 0,
            communityTrustScore: 0.5,
          ),
          isTrue,
        );
        expect(
          service.canEarnPin(
            category: 'food',
            respectedListsCount: 0,
            thoughtfulReviewsCount: 10,
            communityTrustScore: 0.5,
          ),
          isTrue,
        );

        // Test failure cases
        expect(
          service.canEarnPin(
            category: 'food',
            respectedListsCount: 0,
            thoughtfulReviewsCount: 5,
            communityTrustScore: 0.5,
          ),
          isFalse,
        );
        expect(
          service.canEarnPin(
            category: 'food',
            respectedListsCount: 1,
            thoughtfulReviewsCount: 0,
            communityTrustScore: 0.3,
          ),
          isFalse,
        );
      });
    });

    group('getExpertiseStory', () {
      test(
          'should generate story with lists and reviews, or with only lists or only reviews',
          () {
        // Test business logic: story generation with different contribution types
        final story1 = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.city,
          respectedListsCount: 3,
          thoughtfulReviewsCount: 10,
          location: 'San Francisco',
        );
        expect(story1, contains('food'));
        expect(story1, contains('City'));
        expect(story1, contains('San Francisco'));

        final story2 = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.local,
          respectedListsCount: 1,
          thoughtfulReviewsCount: 0,
        );
        expect(story2, contains('lists'));
        expect(story2, isNot(contains('reviews')));

        final story3 = service.getExpertiseStory(
          category: 'food',
          level: ExpertiseLevel.local,
          respectedListsCount: 0,
          thoughtfulReviewsCount: 10,
        );
        expect(story3, contains('reviews'));
        expect(story3, isNot(contains('lists')));
      });
    });

    group('getUnlockedFeatures', () {
      test('should return correct features for each expertise level', () {
        // Test business logic: feature unlocking based on expertise level
        final localFeatures = service.getUnlockedFeatures(ExpertiseLevel.local);
        expect(localFeatures, contains('event_hosting'));
        expect(localFeatures.length, equals(1));

        final cityFeatures = service.getUnlockedFeatures(ExpertiseLevel.city);
        expect(cityFeatures, contains('event_hosting'));

        final regionalFeatures =
            service.getUnlockedFeatures(ExpertiseLevel.regional);
        expect(regionalFeatures, contains('event_hosting'));
        expect(regionalFeatures, contains('expert_validation'));

        final nationalFeatures =
            service.getUnlockedFeatures(ExpertiseLevel.national);
        expect(nationalFeatures, contains('event_hosting'));
        expect(nationalFeatures, contains('expert_validation'));
        expect(nationalFeatures, contains('expert_curation'));

        final globalFeatures =
            service.getUnlockedFeatures(ExpertiseLevel.global);
        expect(globalFeatures, contains('event_hosting'));
        expect(globalFeatures, contains('expert_validation'));
        expect(globalFeatures, contains('expert_curation'));
        expect(globalFeatures, contains('community_leadership'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
