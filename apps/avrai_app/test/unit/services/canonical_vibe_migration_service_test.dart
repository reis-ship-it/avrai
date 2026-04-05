// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_migration_service.dart';
import 'package:avrai_runtime_os/services/vibe/vibe_kernel_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../helpers/fake_vibe_kernel.dart';
import '../../mocks/mock_storage_service.dart';

class _ThrowingExportVibeKernel extends TestVibeKernel {
  @override
  Never exportSnapshotEnvelope() {
    throw StateError('export should not be called in this test');
  }
}

void main() {
  group('CanonicalVibeMigrationService', () {
    late TestVibeKernel vibeKernel;
    late TrajectoryKernel trajectoryKernel;

    setUpAll(() async {
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage: MockGetStorage.getInstance(
          boxName: 'spots_analytics',
        ),
      );
    });

    setUp(() async {
      MockGetStorage.clear(boxName: 'spots_default');
      MockGetStorage.clear(boxName: 'spots_user');
      MockGetStorage.clear(boxName: 'spots_ai');
      MockGetStorage.clear(boxName: 'spots_analytics');
      TrajectoryKernel.resetFallbackStateForTesting();
      trajectoryKernel = TrajectoryKernel(allowFallback: true);
      vibeKernel = TestVibeKernel(trajectoryKernel: trajectoryKernel);
    });

    test(
      'imports legacy personality, signature, and locality state once',
      () async {
        final storage = StorageService.instance;
        final profile = PersonalityProfile.fromDimensions(
          'agent_migrate_user',
          const <String, double>{
            'energy_preference': 0.18,
            'community_orientation': 0.79,
          },
        );
        await storage.setString(
          'personality_profile_${profile.agentId}',
          jsonEncode(profile.toJson()),
        );

        final signature = EntitySignature(
          signatureId: 'sig_spot_1',
          entityId: 'spot-123',
          entityKind: SignatureEntityKind.spot,
          dna: const <String, double>{
            'energy_preference': 0.66,
            'community_orientation': 0.44,
          },
          pheromones: const <String, double>{},
          confidence: 0.7,
          freshness: 0.8,
          updatedAt: DateTime.utc(2026, 3, 12),
          summary: 'Signature migration fixture',
        );
        await storage.setObject(
          'entity_signature_v1:${signature.entityKind.name}:${signature.entityId}',
          signature.toJson(),
        );

        final localityKey = LocalityAgentKeyV1(
          geohashPrefix: '9q5ctr7',
          precision: 7,
          cityCode: 'bham',
        );
        final localityState = LocalityAgentGlobalStateV1(
          key: localityKey,
          vector12: const <double>[
            0.82,
            0.45,
            0.54,
            0.49,
            0.62,
            0.58,
            0.41,
            0.67,
            0.52,
            0.61,
            0.57,
            0.43,
          ],
          sampleCount: 12,
          updatedAtUtc: DateTime.utc(2026, 3, 12),
        );
        await storage.setObject(
          'locality_kernel_global_v1:${localityKey.stableKey}',
          localityState.toJson(),
          box: VibeKernelPersistenceService.box,
        );

        final persistenceService = VibeKernelPersistenceService(
          storage: storage,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );
        await persistenceService.restore();
        final migrationService = CanonicalVibeMigrationService(
          storage: storage,
          persistenceService: persistenceService,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );

        await migrationService.runIfNeeded();
        await migrationService.runIfNeeded();

        final manifest = persistenceService.loadManifest();
        expect(
          manifest?.migrationReceipts,
          contains(CanonicalVibeMigrationService.migrationReceipt),
        );

        final migratedUser = vibeKernel.getUserSnapshot(profile.agentId);
        final migratedLocality = vibeKernel.getSnapshot(
          VibeSubjectRef.locality(localityKey.stableKey),
        );
        final migratedEntity = vibeKernel.getEntitySnapshot(
          entityId: signature.entityId,
          entityType: signature.entityKind.name,
        );

        expect(
          migratedUser.coreDna.dimensions['energy_preference'],
          lessThan(0.5),
        );
        expect(
          migratedLocality.coreDna.dimensions['energy_preference'],
          greaterThan(0.5),
        );
        expect(
          migratedEntity.vibe.coreDna.dimensions['energy_preference'],
          greaterThan(0.5),
        );
      },
    );

    test(
      'runIfNeeded tolerates string-key iteration from storage service',
      () async {
        final storage = StorageService.instance;
        await storage.setString(
          'personality_profile_agent_smoke_fix',
          jsonEncode(
            PersonalityProfile.fromDimensions(
              'agent_smoke_fix',
              const <String, double>{'community_orientation': 0.71},
            ).toJson(),
          ),
        );

        final persistenceService = VibeKernelPersistenceService(
          storage: storage,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );
        await persistenceService.restore();
        final migrationService = CanonicalVibeMigrationService(
          storage: storage,
          persistenceService: persistenceService,
          vibeKernel: vibeKernel,
          trajectoryKernel: trajectoryKernel,
        );

        expect(() => migrationService.runIfNeeded(), returnsNormally);
      },
    );

    test('skips canonical export when no legacy state exists', () async {
      final storage = StorageService.instance;
      final persistenceService = VibeKernelPersistenceService(
        storage: storage,
        vibeKernel: vibeKernel,
        trajectoryKernel: trajectoryKernel,
      );
      await persistenceService.restore();
      final migrationService = CanonicalVibeMigrationService(
        storage: storage,
        persistenceService: persistenceService,
        vibeKernel: _ThrowingExportVibeKernel(),
        trajectoryKernel: trajectoryKernel,
      );

      await migrationService.runIfNeeded();

      final manifest = persistenceService.loadManifest();
      expect(
        manifest?.migrationReceipts,
        contains(CanonicalVibeMigrationService.migrationReceipt),
      );
      expect(manifest?.metadata['canonical_persist_skipped'], isTrue);
      expect(manifest?.metadata['skip_reason'], 'no_legacy_state');
    });
  });
}
