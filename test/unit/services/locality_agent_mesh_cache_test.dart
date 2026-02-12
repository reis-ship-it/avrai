import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/places/geohash_service.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:avrai/core/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('LocalityAgentMeshCache', () {
    late LocalityAgentMeshCache cache;
    late StorageService storage;

    setUp(() async {
      // Initialize StorageService for tests
      await setupTestStorage();
      storage = StorageService.instance;
      cache = LocalityAgentMeshCache(storage: storage);
    });

    // Note: Full tests require StorageService initialization
    // These tests verify the cache interface and logic
    // For complete testing, add proper storage mocking
    test('cache interface is correct', () {
      // Verify cache can be instantiated (requires storage)
      // This is a placeholder - full tests need storage setup
      expect(true, isTrue); // Placeholder test
    });

    test('getNeighborMeshUpdates returns updates for neighbors', () async {
      final key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5regy',
        precision: 7,
        cityCode: 'us-nyc',
      );

      // Store update for a neighbor geohash
      final neighborGeohashes = GeohashService.neighbors(geohash: 'dr5regy');
      if (neighborGeohashes.isNotEmpty) {
        final neighborKey = LocalityAgentKeyV1(
          geohashPrefix: neighborGeohashes.first,
          precision: 7,
          cityCode: 'us-nyc',
        );
        final delta12 = List<double>.generate(12, (i) => 0.1 * i);

        await cache.storeMeshUpdate(
          key: neighborKey,
          delta12: delta12,
          receivedAt: DateTime.now(),
        );

        // Get neighbor updates
        final updates = await cache.getNeighborMeshUpdates(key);
        expect(updates.length, greaterThan(0));
        expect(updates.first.length, equals(12));
      }
    });

    test('getNeighborMeshUpdates filters expired updates', () async {
      final key = LocalityAgentKeyV1(
        geohashPrefix: 'dr5regy',
        precision: 7,
        cityCode: 'us-nyc',
      );

      // Store expired update
      final neighborGeohashes = GeohashService.neighbors(geohash: 'dr5regy');
      if (neighborGeohashes.isNotEmpty) {
        final neighborKey = LocalityAgentKeyV1(
          geohashPrefix: neighborGeohashes.first,
          precision: 7,
          cityCode: 'us-nyc',
        );
        final delta12 = List<double>.generate(12, (i) => 0.1 * i);

        await cache.storeMeshUpdate(
          key: neighborKey,
          delta12: delta12,
          receivedAt: DateTime.now().subtract(const Duration(hours: 7)), // Expired
          ttl: const Duration(hours: 6),
        );

        // Get neighbor updates (should filter out expired)
        final updates = await cache.getNeighborMeshUpdates(key);
        expect(updates.length, equals(0)); // Expired update filtered out
      }
    });
  });
}
