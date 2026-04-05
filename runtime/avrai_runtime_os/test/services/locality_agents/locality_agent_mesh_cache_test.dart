import 'dart:io';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageRoot;
  late GetStorage defaultStorage;
  late GetStorage userStorage;
  late GetStorage aiStorage;
  late GetStorage analyticsStorage;

  setUpAll(() async {
    storageRoot = await Directory.systemTemp.createTemp(
      'locality_agent_mesh_cache_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return storageRoot.path;
        }
        return null;
      },
    );
    await GetStorage('mesh_cache_default', storageRoot.path).initStorage;
    await GetStorage('mesh_cache_user', storageRoot.path).initStorage;
    await GetStorage('mesh_cache_ai', storageRoot.path).initStorage;
    await GetStorage('mesh_cache_analytics', storageRoot.path).initStorage;
    defaultStorage = GetStorage('mesh_cache_default', storageRoot.path);
    userStorage = GetStorage('mesh_cache_user', storageRoot.path);
    aiStorage = GetStorage('mesh_cache_ai', storageRoot.path);
    analyticsStorage = GetStorage('mesh_cache_analytics', storageRoot.path);
    await StorageService.instance.initForTesting(
      defaultStorage: defaultStorage,
      userStorage: userStorage,
      aiStorage: aiStorage,
      analyticsStorage: analyticsStorage,
    );
  });

  tearDown(() async {
    await defaultStorage.erase();
    await userStorage.erase();
    await aiStorage.erase();
    await analyticsStorage.erase();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await _deleteDirectoryWithRetry(storageRoot);
  });

  group('LocalityAgentMeshCache', () {
    test('marks same-key writes as superseding the prior cached update',
        () async {
      final storage = StorageService.instance;
      final cache = LocalityAgentMeshCache(storage: storage);
      const key = LocalityAgentKeyV1(
        geohashPrefix: '9q8yy',
        precision: 5,
        cityCode: 'bham',
      );
      final firstReceivedAt = DateTime.utc(2026, 4, 5, 12, 0);
      final secondReceivedAt = DateTime.utc(2026, 4, 5, 12, 10);

      final firstResult = await cache.storeMeshUpdate(
        key: key,
        delta12: List<double>.filled(12, 0.1),
        receivedAt: firstReceivedAt,
        ttl: const Duration(hours: 1),
      );
      final secondResult = await cache.storeMeshUpdate(
        key: key,
        delta12: List<double>.filled(12, 0.9),
        receivedAt: secondReceivedAt,
        ttl: const Duration(hours: 2),
      );

      expect(firstResult.supersededPriorRecord, isFalse);
      expect(secondResult.supersededPriorRecord, isTrue);
      expect(secondResult.supersededReceivedAt, firstReceivedAt);

      final stored = storage.getObject<Map<String, dynamic>>(
        'locality_agent_mesh_cache:${key.stableKey}',
        box: 'spots_ai',
      );
      expect(stored, isNotNull);
      expect(stored!['superseded_prior_record'], isTrue);
      expect(
          stored['superseded_received_at'], firstReceivedAt.toIso8601String());
      expect(stored['superseded_expires_at'],
          firstReceivedAt.add(const Duration(hours: 1)).toIso8601String());
      expect(stored['received_at'], secondReceivedAt.toIso8601String());
      expect((stored['delta12'] as List<dynamic>).first, 0.9);
    });

    test('cleanupExpiredEntries removes expired persisted mesh updates',
        () async {
      final storage = StorageService.instance;
      final cache = LocalityAgentMeshCache(storage: storage);
      const expiredKey = LocalityAgentKeyV1(
        geohashPrefix: '9q8yz',
        precision: 5,
        cityCode: 'bham',
      );
      const activeKey = LocalityAgentKeyV1(
        geohashPrefix: '9q8yw',
        precision: 5,
        cityCode: 'bham',
      );

      await cache.storeMeshUpdate(
        key: expiredKey,
        delta12: List<double>.filled(12, 0.2),
        receivedAt: DateTime.now().toUtc().subtract(const Duration(hours: 4)),
        ttl: const Duration(hours: 1),
      );
      await cache.storeMeshUpdate(
        key: activeKey,
        delta12: List<double>.filled(12, 0.7),
        receivedAt: DateTime.now().toUtc(),
        ttl: const Duration(hours: 1),
      );

      final cleanup = await cache.cleanupExpiredEntries();

      expect(cleanup.expiredPersistedEntriesRemoved, 1);
      expect(cleanup.expiredStableKeys, contains(expiredKey.stableKey));
      expect(cleanup.failures, isEmpty);
      expect(
        storage.containsKey(
          'locality_agent_mesh_cache:${expiredKey.stableKey}',
          box: 'spots_ai',
        ),
        isFalse,
      );
      expect(
        storage.containsKey(
          'locality_agent_mesh_cache:${activeKey.stableKey}',
          box: 'spots_ai',
        ),
        isTrue,
      );
    });

    test('neighbor reads use only the latest superseding mesh update',
        () async {
      final storage = StorageService.instance;
      final cache = LocalityAgentMeshCache(storage: storage);
      const sourceKey = LocalityAgentKeyV1(
        geohashPrefix: '9q8yy',
        precision: 5,
        cityCode: 'bham',
      );
      const consumerKey = LocalityAgentKeyV1(
        geohashPrefix: '9q8yv',
        precision: 5,
        cityCode: 'bham',
      );
      final firstReceivedAt = DateTime.now().toUtc().subtract(
            const Duration(minutes: 10),
          );
      final secondReceivedAt = DateTime.now().toUtc();

      await cache.storeMeshUpdate(
        key: sourceKey,
        delta12: List<double>.filled(12, 0.1),
        receivedAt: firstReceivedAt,
        ttl: const Duration(hours: 1),
      );
      await cache.storeMeshUpdate(
        key: sourceKey,
        delta12: List<double>.filled(12, 0.9),
        receivedAt: secondReceivedAt,
        ttl: const Duration(hours: 1),
      );

      final neighborUpdates = await cache.getNeighborMeshUpdates(consumerKey);

      expect(neighborUpdates, hasLength(1));
      expect(neighborUpdates.single.first, 0.9);
      expect(neighborUpdates.single, isNot(List<double>.filled(12, 0.1)));

      final stored = storage.getObject<Map<String, dynamic>>(
        'locality_agent_mesh_cache:${sourceKey.stableKey}',
        box: 'spots_ai',
      );
      expect(stored, isNotNull);
      expect(stored!['superseded_prior_record'], isTrue);
      expect(stored['superseded_at'], secondReceivedAt.toIso8601String());
      expect(stored['received_at'], secondReceivedAt.toIso8601String());
    });
  });
}

Future<void> _deleteDirectoryWithRetry(Directory directory) async {
  if (!directory.existsSync()) {
    return;
  }

  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      await directory.delete(recursive: true);
      return;
    } on FileSystemException {
      final entities = directory.listSync(recursive: true).reversed.toList();
      for (final entity in entities) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException {
          // Retry outer directory deletion after other handles settle.
        }
      }
      await Future<void>.delayed(
        Duration(milliseconds: 40 * (attempt + 1)),
      );
    }
  }

  if (directory.existsSync()) {
    await directory.delete(recursive: true);
  }
}
