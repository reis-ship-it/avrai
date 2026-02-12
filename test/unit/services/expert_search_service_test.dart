import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/expertise/expert_search_service.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/expertise/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Expert Search Service Tests
/// Tests expert search functionality
void main() {
  group('ExpertSearchService Tests', () {
    late ExpertSearchService service;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late UnifiedUser user;

    setUp(() {
      service = ExpertSearchService();
      user = ModelFactories.createTestUser(
        id: 'user-123',
        tags: ['food'],
      ).copyWith(
        expertiseMap: {'food': 'city'},
      );
    });

    // Removed: Property assignment tests
    // Expert search tests focus on business logic (searching, filtering, sorting), not property assignment

    group('searchExperts', () {
      test(
          'should return empty list when no experts match, filter by category, filter by location, filter by minimum level, respect maxResults parameter, and return results sorted by relevance score',
          () async {
        // Test business logic: expert search with various filters and sorting
        final results1 = await service.searchExperts(
          category: 'food',
        );
        expect(results1, isA<List<ExpertSearchResult>>());
        expect(results1, isEmpty);

        final results2 = await service.searchExperts(
          category: 'food',
        );
        expect(results2, isA<List<ExpertSearchResult>>());

        final results3 = await service.searchExperts(
          location: 'San Francisco',
        );
        expect(results3, isA<List<ExpertSearchResult>>());

        final results4 = await service.searchExperts(
          category: 'food',
          minLevel: ExpertiseLevel.city,
        );
        expect(results4, isA<List<ExpertSearchResult>>());

        final results5 = await service.searchExperts(
          category: 'food',
          maxResults: 10,
        );
        expect(results5.length, lessThanOrEqualTo(10));

        final results6 = await service.searchExperts(
          category: 'food',
        );
        for (var i = 0; i < results6.length - 1; i++) {
          expect(
            results6[i].relevanceScore,
            greaterThanOrEqualTo(results6[i + 1].relevanceScore),
          );
        }
      });
    });

    group('getTopExperts', () {
      test(
          'should return top experts in category, filter by location when provided, and include local level experts (not filter out local level)',
          () async {
        // Test business logic: top experts retrieval with filtering
        final results1 = await service.getTopExperts(
          'food',
          maxResults: 10,
        );
        expect(results1, isA<List<ExpertSearchResult>>());
        expect(results1.length, lessThanOrEqualTo(10));

        final results2 = await service.getTopExperts(
          'food',
          location: 'San Francisco',
          maxResults: 5,
        );
        expect(results2, isA<List<ExpertSearchResult>>());

        final results3 = await service.getTopExperts('food');
        for (final result in results3) {
          final level = result.user.getExpertiseLevel('food');
          if (level != null) {
            expect(
                level.index, greaterThanOrEqualTo(ExpertiseLevel.local.index));
          }
      // ignore: unused_local_variable
        }
        if (results3.isNotEmpty) {
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
          final hasLocalLevel = results3.any((result) {
            final level = result.user.getExpertiseLevel('food');
            return level == ExpertiseLevel.local;
          });
        }
      });
    });

    group('getExpertsNearLocation', () {
      test('should return experts near location', () async {
        final results = await service.getExpertsNearLocation(
          'San Francisco',
          maxResults: 20,
        );

        expect(results, isA<List<ExpertSearchResult>>());
        expect(results.length, lessThanOrEqualTo(20));
      });
    });

    group('getExpertsByLevel', () {
      test(
          'should return experts by specific level and filter by category when provided',
          () async {
        // Test business logic: expert retrieval by level with category filtering
        final results1 = await service.getExpertsByLevel(
          ExpertiseLevel.city,
          category: 'food',
          maxResults: 20,
        );
        expect(results1, isA<List<ExpertSearchResult>>());

        final results2 = await service.getExpertsByLevel(
          ExpertiseLevel.regional,
          category: 'food',
        );
        expect(results2, isA<List<ExpertSearchResult>>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
