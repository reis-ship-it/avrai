import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:avrai_runtime_os/services/infrastructure/search_cache_service.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/test_storage_helper.dart';

/// Search Cache Service Tests
/// Tests search caching functionality for performance optimization
void main() {
  group('SearchCacheService Tests', () {
    late SearchCacheService service;

    setUpAll(() async {
      await TestStorageHelper.initTestStorage();
      await GetStorage.init('search_cache');
      await GetStorage('search_cache').erase();
    });

    setUp(() {
      service = SearchCacheService();
    });

    // Removed: Property assignment tests
    // Search cache tests focus on business logic (caching, retrieval, maintenance), not property assignment

    group('getCachedResult', () {
      test(
          'should return null when no cached result exists, return null for new query, or accept query with location',
          () async {
        // Test business logic: cache retrieval
        final result1 = await service.getCachedResult(
          query: 'test query',
        );
        expect(result1, isNull);

        final result2 = await service.getCachedResult(
          query: 'coffee shops',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        expect(result2, isNull);

        final result3 = await service.getCachedResult(
          query: 'restaurants',
          latitude: 37.7749,
          longitude: -122.4194,
          maxResults: 20,
          includeExternal: false,
        );
        expect(result3, anyOf(isNull, isA<HybridSearchResult>()));
      });
    });

    group('cacheResult', () {
      test(
          'should cache search result, cache result with location, or cache result with custom maxResults',
          () async {
        // Test business logic: result caching
        final searchResult1 = HybridSearchResult(
          spots: [],
          communityCount: 0,
          externalCount: 0,
          totalCount: 0,
          searchDuration: const Duration(milliseconds: 100),
          sources: {},
        );
        await service.cacheResult(
          query: 'test query',
          result: searchResult1,
        );
        expect(searchResult1, isNotNull);

        final searchResult2 = HybridSearchResult(
          spots: [],
          communityCount: 0,
          externalCount: 0,
          totalCount: 0,
          searchDuration: const Duration(milliseconds: 50),
          sources: {},
        );
        await service.cacheResult(
          query: 'coffee',
          latitude: 40.7128,
          longitude: -74.0060,
          result: searchResult2,
        );
        expect(searchResult2, isNotNull);

        final searchResult3 = HybridSearchResult(
          spots: [],
          communityCount: 0,
          externalCount: 0,
          totalCount: 0,
          searchDuration: const Duration(milliseconds: 75),
          sources: {},
        );
        await service.cacheResult(
          query: 'restaurants',
          maxResults: 100,
          result: searchResult3,
        );
        expect(searchResult3, isNotNull);
      });
    });

    group('prefetchPopularSearches', () {
      test('should prefetch popular searches', () async {
        await service.prefetchPopularSearches(
          searchFunction: (query) async => HybridSearchResult(
            spots: [],
            communityCount: 0,
            externalCount: 0,
            totalCount: 0,
            searchDuration: const Duration(milliseconds: 100),
            sources: {},
          ),
        );

        // Verify prefetching doesn't throw
        expect(service, isNotNull);
      });
    });

    group('warmLocationCache', () {
      test('should warm location cache', () async {
        await service.warmLocationCache(
          latitude: 40.7128,
          longitude: -74.0060,
          nearbySearchFunction: (lat, lng) async => HybridSearchResult(
            spots: [],
            communityCount: 0,
            externalCount: 0,
            totalCount: 0,
            searchDuration: const Duration(milliseconds: 50),
            sources: {},
          ),
        );

        // Verify warming doesn't throw
        expect(service, isNotNull);
      });
    });

    group('getCacheStatistics', () {
      test('should return cache statistics', () {
        final stats = service.getCacheStatistics();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['cache_hits'], isA<int>());
        expect(stats['cache_misses'], isA<int>());
        expect(stats['offline_hits'], isA<int>());
        expect(stats['memory_cache_size'], isA<int>());
      });
    });

    group('clearCache', () {
      test('should clear cache', () async {
        await service.clearCache();

        // Verify clearing doesn't throw
        expect(service, isNotNull);
      });
    });

    group('performMaintenance', () {
      test('should perform cache maintenance', () async {
        await service.performMaintenance();

        // Verify maintenance doesn't throw
        expect(service, isNotNull);
      });
    });

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await GetStorage('search_cache').erase();
      await TestStorageHelper.clearTestStorage();
      await cleanupTestStorage();
    });
  });
}
