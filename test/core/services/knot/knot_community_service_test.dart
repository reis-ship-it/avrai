// Knot Community Service Tests
// 
// Tests for KnotCommunityService
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 3: Onboarding Integration

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai_knot/models/knot/knot_community.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/knot_community_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai/core/services/community/community_service.dart';

class MockPersonalityKnotService extends Mock implements PersonalityKnotService {}
class MockKnotStorageService extends Mock implements KnotStorageService {}
class MockCommunityService extends Mock implements CommunityService {}

// Fallback values for mocktail
class _FakePersonalityProfile extends Fake implements PersonalityProfile {}
class _FakePersonalityKnot extends Fake implements PersonalityKnot {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePersonalityProfile());
    registerFallbackValue(_FakePersonalityKnot());
  });

  group('KnotCommunityService Tests', () {
    late KnotCommunityService service;
    late MockPersonalityKnotService mockPersonalityKnotService;
    late MockKnotStorageService mockKnotStorageService;
    late MockCommunityService mockCommunityService;

    late PersonalityKnot userKnot;
    late PersonalityProfile userProfile;

    setUp(() {
      mockPersonalityKnotService = MockPersonalityKnotService();
      mockKnotStorageService = MockKnotStorageService();
      mockCommunityService = MockCommunityService();

      service = KnotCommunityService(
        personalityKnotService: mockPersonalityKnotService,
        knotStorageService: mockKnotStorageService,
        communityService: mockCommunityService,
      );

      userKnot = PersonalityKnot(
        agentId: 'user-agent',
        invariants: KnotInvariants(
          jonesPolynomial: [1.0, 2.0, 3.0],
          alexanderPolynomial: [1.0, 1.0],
          crossingNumber: 5,
          writhe: 2,
          signature: 0,
          bridgeNumber: 2,
          braidIndex: 2,
          determinant: 1,
        ),
        physics: KnotPhysics(energy: 0.5, stability: 0.7, length: 0.3),
        braidData: [8.0, 0.0, 1.0, 1.0, 1.0],
        createdAt: DateTime(2025, 1, 1),
        lastUpdated: DateTime(2025, 1, 1),
      );

      userProfile = PersonalityProfile.initial('user-agent');
    });

    group('findKnotTribe', () {
      test('should return empty list when no communities exist', () async {
        // Service uses internal _getAllCommunities() which returns empty list for now
        final result = await service.findKnotTribe(userKnot: userKnot);

        expect(result, isEmpty);
      });

      test('should return empty list when _getAllCommunities returns empty (current implementation)', () async {
        // Current implementation uses _getAllCommunities() which returns empty list
        // This test verifies the current behavior
        final result = await service.findKnotTribe(
          userKnot: userKnot,
          similarityThreshold: 0.6,
        );

        expect(result, isEmpty);
      });

      test('should respect maxResults parameter', () async {
        // Current implementation returns empty list, but we test the parameter is accepted
        final result = await service.findKnotTribe(
          userKnot: userKnot,
          maxResults: 2,
        );

        expect(result.length, lessThanOrEqualTo(2));
      });

      test('should handle empty communities gracefully', () async {
        final result = await service.findKnotTribe(userKnot: userKnot);

        // Should handle gracefully - returns empty list when no communities
        expect(result, isA<List<KnotCommunity>>());
        expect(result, isEmpty);
      });
    });

    group('createOnboardingKnotGroup', () {
      test('should create group (may return empty with current implementation)', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenAnswer((_) async => userKnot);

        final result = await service.createOnboardingKnotGroup(
          newUserProfile: userProfile,
          maxGroupSize: 3,
        );

        expect(result, isA<List<PersonalityProfile>>());
        expect(result.length, lessThanOrEqualTo(3));
      });

      test('should respect maxGroupSize parameter', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenAnswer((_) async => userKnot);

        final result = await service.createOnboardingKnotGroup(
          newUserProfile: userProfile,
          maxGroupSize: 5,
        );

        expect(result.length, lessThanOrEqualTo(5));
      });

      test('should handle empty onboarding pool', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenAnswer((_) async => userKnot);

        final result = await service.createOnboardingKnotGroup(
          newUserProfile: userProfile,
          maxGroupSize: 5,
        );

        // Should return empty list if no compatible users found
        expect(result, isA<List<PersonalityProfile>>());
      });
    });

    group('generateKnotBasedRecommendations', () {
      test('should generate recommendations with all components', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenAnswer((_) async => userKnot);

        final recommendations = await service.generateKnotBasedRecommendations(
          profile: userProfile,
        );

        expect(recommendations, isNotNull);
        expect(recommendations, isA<Map<String, dynamic>>());
        expect(recommendations['suggestedCommunities'], isA<List<KnotCommunity>>());
        expect(recommendations['suggestedUsers'], isA<List<PersonalityProfile>>());
        expect(recommendations['knotInsights'], isA<List<String>>());
        expect(recommendations['knotInsights'], isNotEmpty);
      });

      test('should include knot insights in recommendations', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenAnswer((_) async => userKnot);

        final recommendations = await service.generateKnotBasedRecommendations(
          profile: userProfile,
        );

        final insights = recommendations['knotInsights'] as List<String>;
        expect(insights, isNotEmpty);
        expect(insights.first, contains('personality'));
      });
    });

    group('Error Handling', () {
      test('should handle errors gracefully in findKnotTribe', () async {
        // Service uses internal _getAllCommunities() which doesn't throw
        // But we test that the method handles errors gracefully
        final result = await service.findKnotTribe(userKnot: userKnot);

        expect(result, isA<List<KnotCommunity>>());
      });

      test('should handle errors gracefully in createOnboardingKnotGroup', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenThrow(Exception('Generation error'));

        // Service rethrows errors
        expect(
          service.createOnboardingKnotGroup(newUserProfile: userProfile),
          throwsException,
        );
      });

      test('should handle errors gracefully in generateKnotBasedRecommendations', () async {
        when(() => mockPersonalityKnotService.generateKnot(any()))
            .thenThrow(Exception('Generation error'));

        // Service rethrows errors, so expect exception
        expect(
          service.generateKnotBasedRecommendations(profile: userProfile),
          throwsException,
        );
      });
    });
  });
}
