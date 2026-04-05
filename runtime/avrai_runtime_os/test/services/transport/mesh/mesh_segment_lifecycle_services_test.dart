import 'dart:io';

import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_models.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mesh segment lifecycle services', () {
    late Directory storageRoot;
    late GetStorage defaultStorage;
    late GetStorage userStorage;
    late GetStorage aiStorage;
    late GetStorage analyticsStorage;

    setUpAll(() async {
      storageRoot = await Directory.systemTemp.createTemp(
        'mesh_segment_lifecycle_services_test_',
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
      await GetStorage('segment_lifecycle_default', storageRoot.path)
          .initStorage;
      await GetStorage('segment_lifecycle_user', storageRoot.path).initStorage;
      await GetStorage('segment_lifecycle_ai', storageRoot.path).initStorage;
      await GetStorage('segment_lifecycle_analytics', storageRoot.path)
          .initStorage;
      defaultStorage = GetStorage(
        'segment_lifecycle_default',
        storageRoot.path,
      );
      userStorage = GetStorage('segment_lifecycle_user', storageRoot.path);
      aiStorage = GetStorage('segment_lifecycle_ai', storageRoot.path);
      analyticsStorage = GetStorage(
        'segment_lifecycle_analytics',
        storageRoot.path,
      );
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
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    tearDownAll(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
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

    test('refreshes expiring credentials and skips revoked credentials',
        () async {
      final now = DateTime.utc(2026, 3, 12, 23);
      final revocationStore = MeshSegmentRevocationStore();
      final service = MeshSegmentCredentialRefreshService(
        revocationPolicy: MeshSegmentRevocationPolicy(
          revocationStore: revocationStore,
        ),
        nowUtc: () => now,
      );
      final expiringCredential = MeshSegmentCredential(
        credentialId: 'cred-expiring',
        segmentProfileId: 'segment-1',
        principalId: 'peer-a',
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: now.subtract(const Duration(minutes: 5)),
        expiresAtUtc: now.add(const Duration(minutes: 5)),
      );
      final revokedCredential = MeshSegmentCredential(
        credentialId: 'cred-revoked',
        segmentProfileId: 'segment-1',
        principalId: 'peer-b',
        principalKind: SignatureEntityKind.user,
        issuedAtUtc: now.subtract(const Duration(minutes: 5)),
        expiresAtUtc: now.add(const Duration(minutes: 5)),
      );
      service.recordIssued(credential: expiringCredential);
      service.recordIssued(credential: revokedCredential);
      revocationStore.revokeCredential('cred-revoked', reason: 'compromised');

      final refreshed = await service.refreshExpiringCredentials(
        renew: (credential) => MeshSegmentCredential(
          credentialId: credential.credentialId,
          segmentProfileId: credential.segmentProfileId,
          principalId: credential.principalId,
          principalKind: credential.principalKind,
          issuedAtUtc: now,
          expiresAtUtc: now.add(const Duration(hours: 2)),
        ),
        nowUtc: now,
      );

      expect(refreshed, 1);
      expect(service.activeCredentialCount(nowUtc: now), 1);
      expect(service.expiringSoonCredentialCount(nowUtc: now), 0);
      expect(revocationStore.credentialRevocationCount(), 1);
      expect(revocationStore.reasonCounts()['compromised'], 1);
    });

    test('persists credential inventory across service instances', () async {
      final now = DateTime.utc(2026, 3, 12, 23);
      final revocationStore = MeshSegmentRevocationStore(
        storageService: StorageService.instance,
      );
      final service = MeshSegmentCredentialRefreshService(
        storageService: StorageService.instance,
        revocationPolicy: MeshSegmentRevocationPolicy(
          revocationStore: revocationStore,
        ),
        nowUtc: () => now,
      );
      service.recordIssued(
        credential: MeshSegmentCredential(
          credentialId: 'cred-persisted',
          segmentProfileId: 'segment-1',
          principalId: 'peer-c',
          principalKind: SignatureEntityKind.user,
          issuedAtUtc: now.subtract(const Duration(minutes: 5)),
          expiresAtUtc: now.add(const Duration(hours: 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final reloaded = MeshSegmentCredentialRefreshService(
        storageService: StorageService.instance,
        revocationPolicy: MeshSegmentRevocationPolicy(
          revocationStore: revocationStore,
        ),
        nowUtc: () => now,
      );
      expect(reloaded.activeCredentialCount(nowUtc: now), 1);
      expect(reloaded.expiringSoonCredentialCount(nowUtc: now), 0);
    });

    test('refreshExpiringTrustMaterial refreshes attestations in place',
        () async {
      final now = DateTime.utc(2026, 3, 12, 23);
      final service = MeshSegmentCredentialRefreshService(
        nowUtc: () => now,
      );
      service.recordIssued(
        credential: MeshSegmentCredential(
          credentialId: 'cred-attested',
          segmentProfileId: 'segment-1',
          principalId: 'peer-d',
          principalKind: SignatureEntityKind.user,
          issuedAtUtc: now.subtract(const Duration(minutes: 5)),
          expiresAtUtc: now.add(const Duration(minutes: 5)),
        ),
        attestation: MeshAnnounceAttestation(
          attestationId: 'attest-attested',
          segmentProfileId: 'segment-1',
          credentialId: 'cred-attested',
          signerEntityId: 'peer-d',
          signerEntityKind: SignatureEntityKind.user,
          signedAtUtc: now.subtract(const Duration(minutes: 5)),
          expiresAtUtc: now.add(const Duration(minutes: 5)),
        ),
      );

      final refreshed = await service.refreshExpiringTrustMaterial(nowUtc: now);

      expect(refreshed, 1);
      expect(service.allCredentials(), hasLength(1));
      expect(service.allAttestations(), hasLength(1));
      expect(
        service.allAttestations().single.expiresAtUtc,
        now.add(const Duration(hours: 2)),
      );
    });
  });
}
