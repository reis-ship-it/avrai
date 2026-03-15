import 'dart:io';

import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MeshSegmentRevocationStore', () {
    late Directory storageRoot;
    late GetStorage defaultStorage;
    late GetStorage userStorage;
    late GetStorage aiStorage;
    late GetStorage analyticsStorage;

    setUpAll(() async {
      storageRoot = await Directory.systemTemp.createTemp(
        'mesh_segment_revocation_store_test_',
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
      await GetStorage('revocation_default', storageRoot.path).initStorage;
      await GetStorage('revocation_user', storageRoot.path).initStorage;
      await GetStorage('revocation_ai', storageRoot.path).initStorage;
      await GetStorage('revocation_analytics', storageRoot.path).initStorage;
      defaultStorage = GetStorage('revocation_default', storageRoot.path);
      userStorage = GetStorage('revocation_user', storageRoot.path);
      aiStorage = GetStorage('revocation_ai', storageRoot.path);
      analyticsStorage = GetStorage('revocation_analytics', storageRoot.path);
      await StorageService.instance.initForTesting(
        defaultStorage: defaultStorage,
        userStorage: userStorage,
        aiStorage: aiStorage,
        analyticsStorage: analyticsStorage,
      );
    });

    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await defaultStorage.erase();
      await userStorage.erase();
      await aiStorage.erase();
      await analyticsStorage.erase();
    });

    tearDownAll(() async {
      try {
        if (storageRoot.existsSync()) {
          await storageRoot.delete(recursive: true);
        }
      } on FileSystemException {
        // GetStorage can keep temp files open briefly in tests; ignore cleanup failures.
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });

    test('persists revocations across store instances', () async {
      final store = MeshSegmentRevocationStore(
        storageService: StorageService.instance,
      );
      store.revokeCredential('cred-1', reason: 'compromised');
      store.revokeAttestation('attest-1', reason: 'expired');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final reloaded = MeshSegmentRevocationStore(
        storageService: StorageService.instance,
      );
      expect(reloaded.isCredentialRevoked('cred-1'), isTrue);
      expect(reloaded.isAttestationRevoked('attest-1'), isTrue);
      expect(reloaded.credentialRevocationCount(), 1);
      expect(reloaded.attestationRevocationCount(), 1);
      expect(reloaded.reasonCounts()['compromised'], 1);
      expect(reloaded.reasonCounts()['expired'], 1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
