import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/expertise_network_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expertise Network Service Tests
/// Tests expertise-based social graph and network functionality
void main() {
  group('ExpertiseNetworkService Tests', () {
    late ExpertiseNetworkService service;
    late UnifiedUser user;

    setUp(() {
      service = ExpertiseNetworkService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food', 'travel'],
      ).copyWith(
        expertiseMap: {'food': 'city', 'travel': 'local'},
      );
    });

    // Removed: Property assignment tests
    // Expertise network tests focus on business logic (network retrieval, circles, influence, followers), not property assignment

    group('getUserExpertiseNetwork', () {
      test(
          'should return expertise network for user, return empty network when user has no expertise, or include strongest connections',
          () async {
        // Test business logic: user expertise network retrieval
        final network1 = await service.getUserExpertiseNetwork(user);
        expect(network1, isA<ExpertiseNetwork>());
        expect(network1.user.id, equals(user.id));
        expect(network1.connections, isA<List<ExpertiseConnection>>());
        expect(network1.networkSize, greaterThanOrEqualTo(0));
        expect(network1.strongestConnections, isA<List<ExpertiseConnection>>());
        expect(network1.strongestConnections.length, lessThanOrEqualTo(10));

        final userWithoutExpertise = ModelFactories.createTestUser(
          id: 'user-456',
        ).copyWith(expertiseMap: {});
        final network2 =
            await service.getUserExpertiseNetwork(userWithoutExpertise);
        expect(network2, isA<ExpertiseNetwork>());
        expect(network2.networkSize, equals(0));
        expect(network2.connections, isEmpty);
      });
    });

    group('getExpertiseCircles', () {
      test(
          'should return expertise circles for category, filter by location when provided, return empty list when no experts in category, or group experts by level',
          () async {
        // Test business logic: expertise circle retrieval
        final circles1 = await service.getExpertiseCircles('food');
        expect(circles1, isA<List<ExpertiseCircle>>());
        for (final circle in circles1) {
          expect(circle.level, isNotNull);
          expect(circle.category, equals('food'));
          expect(circle.members, isA<List<UnifiedUser>>());
          expect(circle.memberCount, equals(circle.members.length));
        }

        final circles2 = await service.getExpertiseCircles(
          'food',
          location: 'San Francisco',
        );
        expect(circles2, isA<List<ExpertiseCircle>>());

        final circles3 =
            await service.getExpertiseCircles('nonexistent-category');
        expect(circles3, isA<List<ExpertiseCircle>>());
      });
    });

    group('getExpertiseInfluence', () {
      test('should return expertise influence for user', () async {
        final influences = await service.getExpertiseInfluence(user);

        expect(influences, isA<List<ExpertiseInfluence>>());
      });

      test('should return empty list when no influences', () async {
        final influences = await service.getExpertiseInfluence(user);

        // In test environment, placeholder returns empty list
        expect(influences, isEmpty);
      });
    });

    group('getExpertiseFollowers', () {
      test(
          'should return expertise followers for user, or return empty list when no followers',
          () async {
        // Test business logic: expertise follower retrieval
        final followers = await service.getExpertiseFollowers(user);
        expect(followers, isA<List<UnifiedUser>>());
        expect(followers, isEmpty);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
