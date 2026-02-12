import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/business/user_business_matching_service.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// User Business Matching Service Tests
/// Tests user-business matching functionality
void main() {
  group('UserBusinessMatchingService Tests', () {
    late UserBusinessMatchingService service;
    late UnifiedUser user;

    setUp(() {
      service = UserBusinessMatchingService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food', 'travel'],
      ).copyWith(

        expertiseMap: {'food': 'city', 'travel': 'local'},
      );
    });

    group('findBusinessesForUser', () {
      test('should return empty list when no businesses match', () async {
        final matches = await service.findBusinessesForUser(user);

        expect(matches, isA<List<UserBusinessMatch>>());
        expect(matches, isEmpty);
      });

      test('should respect maxResults parameter', () async {
        final matches = await service.findBusinessesForUser(
          user,
          maxResults: 5,
        );

        expect(matches.length, lessThanOrEqualTo(5));
      });
    });

    group('getUserCompatibilityScore', () {
      test('should return compatibility score for business without preferences', () async {
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        final score = await service.getUserCompatibilityScore(user, business);

        expect(score, isA<BusinessCompatibilityScore>());
        expect(score.business.id, equals(business.id));
        expect(score.user.id, equals(user.id));
        expect(score.overallScore, equals(0.5));
        expect(score.reason, equals('No patron preferences set'));
      });

      test('should return compatibility score with preferences', () async {
        const preferences = BusinessPatronPreferences(
          preferLocalPatrons: true,
          preferCommunityMembers: true,
        );

        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          patronPreferences: preferences,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        final score = await service.getUserCompatibilityScore(user, business);

        expect(score, isA<BusinessCompatibilityScore>());
        expect(score.overallScore, greaterThanOrEqualTo(0.0));
        expect(score.overallScore, lessThanOrEqualTo(1.0));
        expect(score.matchedCriteria, isA<List<String>>());
        expect(score.missingCriteria, isA<List<String>>());
      });

      test('should calculate percentage score', () async {
        const preferences = BusinessPatronPreferences(
          preferLocalPatrons: true,
        );

        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          patronPreferences: preferences,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        final score = await service.getUserCompatibilityScore(user, business);

        expect(score.percentageScore, greaterThanOrEqualTo(0));
        expect(score.percentageScore, lessThanOrEqualTo(100));
      });

      test('should determine if user is good match', () async {
        const preferences = BusinessPatronPreferences(
          preferLocalPatrons: true,
          preferCommunityMembers: true,
        );

        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          patronPreferences: preferences,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        final score = await service.getUserCompatibilityScore(user, business);

        expect(score.isGoodMatch, isA<bool>());
      });

      test('should provide summary of match', () async {
        const preferences = BusinessPatronPreferences(
          preferLocalPatrons: true,
        );

        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          patronPreferences: preferences,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        final score = await service.getUserCompatibilityScore(user, business);

        expect(score.summary, isA<String>());
        expect(score.summary, isNotEmpty);
      });
    });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
  });
}

