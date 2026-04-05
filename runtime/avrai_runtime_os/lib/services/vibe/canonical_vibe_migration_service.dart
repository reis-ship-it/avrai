import 'dart:convert';
import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/vibe_kernel_persistence_service.dart';
import 'package:reality_engine/reality_engine.dart';

class CanonicalVibeMigrationService {
  CanonicalVibeMigrationService({
    required StorageService storage,
    required VibeKernelPersistenceService persistenceService,
    VibeKernel? vibeKernel,
    TrajectoryKernel? trajectoryKernel,
  })  : _storage = storage,
        _persistenceService = persistenceService,
        _vibeKernel = vibeKernel ?? VibeKernel(),
        _trajectoryKernel = trajectoryKernel ?? TrajectoryKernel();

  static const int migrationVersion = 1;
  static const String migrationReceipt = 'canonical_vibe_migration_v1';
  static const String _logName = 'CanonicalVibeMigrationService';

  final StorageService _storage;
  final VibeKernelPersistenceService _persistenceService;
  final VibeKernel _vibeKernel;
  final TrajectoryKernel _trajectoryKernel;

  Future<void> runIfNeeded() async {
    final manifest = _persistenceService.loadManifest();
    if (manifest?.migrationReceipts.contains(migrationReceipt) ?? false) {
      return;
    }

    var personalityImports = 0;
    var entityImports = 0;
    var localityImports = 0;

    for (final key in _storage.getKeys()) {
      if (!key.startsWith('personality_profile_')) {
        continue;
      }
      final rawProfile = _storage.getString(key);
      if (rawProfile == null || rawProfile.trim().isEmpty) {
        continue;
      }
      final profile = PersonalityProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawProfile) as Map),
      );
      _vibeKernel.seedSubjectStateFromOnboarding(
        subjectRef: VibeSubjectRef.personal(profile.agentId),
        dimensions: profile.dimensions,
        dimensionConfidence: profile.dimensionConfidence,
        provenanceTags: const <String>['migration:personality_profile'],
      );
      personalityImports++;
    }

    for (final key in _storage.getKeys()) {
      if (!key.startsWith('entity_signature_v1:')) {
        continue;
      }
      final rawSignature = _storage.getObject<Map<dynamic, dynamic>>(key);
      if (rawSignature == null) {
        continue;
      }
      final signature = EntitySignature.fromJson(
        rawSignature.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
      );
      _vibeKernel.ingestEntityObservation(
        entityId: signature.entityId,
        entityType: signature.entityKind.name,
        dimensions: signature.dna,
        provenanceTags: const <String>['migration:entity_signature'],
      );
      entityImports++;
    }

    for (final key in _storage.getKeys(
      box: VibeKernelPersistenceService.box,
    )) {
      if (key.startsWith('locality_kernel_global_v1:')) {
        final rawState = _storage.getObject<Map<String, dynamic>>(
          key,
          box: VibeKernelPersistenceService.box,
        );
        if (rawState == null) {
          continue;
        }
        _migrateLocalityVector(
          state: LocalityAgentGlobalStateV1.fromJson(rawState),
          vector12: LocalityAgentGlobalStateV1.fromJson(rawState).vector12,
          source: 'migration:locality_global',
          attenuation: 0.68,
        );
        localityImports++;
        continue;
      }
      if (key.startsWith('locality_kernel_delta_v1:')) {
        final rawDelta = _storage.getObject<Map<String, dynamic>>(
          key,
          box: VibeKernelPersistenceService.box,
        );
        if (rawDelta == null) {
          continue;
        }
        final delta = LocalityAgentPersonalDeltaV1.fromJson(rawDelta);
        _migrateLocalityVector(
          state: LocalityAgentGlobalStateV1(
            key: delta.key,
            vector12: delta.delta12.map((entry) => 0.5 + entry).toList(),
            sampleCount: delta.visitCount,
            updatedAtUtc: delta.updatedAtUtc.toUtc(),
          ),
          vector12: delta.delta12.map((entry) => 0.5 + entry).toList(),
          source: 'migration:locality_personal_delta',
          attenuation: 0.52,
        );
        localityImports++;
        continue;
      }
      if (key.startsWith('locality_kernel_mesh_v1:')) {
        final rawMesh = _storage.getObject<Map<String, dynamic>>(
          key,
          box: VibeKernelPersistenceService.box,
        );
        if (rawMesh == null) {
          continue;
        }
        final localityKey = LocalityAgentKeyV1.fromJson(
          Map<String, dynamic>.from(rawMesh['key'] as Map? ?? const {}),
        );
        final delta12 =
            ((rawMesh['delta12'] as List?) ?? const <dynamic>[])
                .map((entry) => (entry as num?)?.toDouble() ?? 0.0)
                .toList();
        if (delta12.length != 12) {
          continue;
        }
        _migrateLocalityVector(
          state: LocalityAgentGlobalStateV1(
            key: localityKey,
            vector12: delta12.map((entry) => 0.5 + entry).toList(),
            sampleCount: 1,
            updatedAtUtc:
                DateTime.tryParse(rawMesh['receivedAt']?.toString() ?? '')
                        ?.toUtc() ??
                    DateTime.now().toUtc(),
          ),
          vector12: delta12.map((entry) => 0.5 + entry).toList(),
          source: 'migration:locality_mesh',
          attenuation: 0.44,
        );
        localityImports++;
      }
    }

    final totalImports = personalityImports + entityImports + localityImports;
    if (totalImports == 0) {
      await _persistenceService.persistMigrationReceipt(
        receipt: migrationReceipt,
        migrationVersion: migrationVersion,
        metadata: <String, dynamic>{
          'personality_imports': personalityImports,
          'entity_imports': entityImports,
          'locality_imports': localityImports,
          'canonical_persist_skipped': true,
          'skip_reason': 'no_legacy_state',
        },
      );
      developer.log(
        'Canonical vibe migration skipped; no legacy state found.',
        name: _logName,
      );
      return;
    }

    await _persistenceService.persistCanonicalState(
      envelope: _vibeKernel.exportSnapshotEnvelope(),
      journalWindow: _trajectoryKernel.exportJournalWindow(limit: 2048),
    );
    await _persistenceService.persistMigrationReceipt(
      receipt: migrationReceipt,
      migrationVersion: migrationVersion,
      metadata: <String, dynamic>{
        'personality_imports': personalityImports,
        'entity_imports': entityImports,
        'locality_imports': localityImports,
      },
    );

    developer.log(
      'Canonical vibe migration completed '
      '(personality=$personalityImports, entity=$entityImports, locality=$localityImports)',
      name: _logName,
    );
  }

  void _migrateLocalityVector({
    required LocalityAgentGlobalStateV1 state,
    required List<double> vector12,
    required String source,
    required double attenuation,
  }) {
    final localityRef = VibeSubjectRef.locality(state.key.stableKey);
    _vibeKernel.ingestEcosystemObservation(
      subjectId: localityRef.subjectId,
      subjectKind: localityRef.kind,
      source: source,
      dimensions: _dimensionsFromVector(vector12),
      provenanceTags: <String>[source, 'stable_key:${state.key.stableKey}'],
    );

    final cityCode = state.key.cityCode;
    if (cityCode != null && cityCode.trim().isNotEmpty) {
      final cityRef = VibeSubjectRef.city(cityCode);
      _vibeKernel.ingestEcosystemObservation(
        subjectId: cityRef.subjectId,
        subjectKind: cityRef.kind,
        source: source,
        dimensions: _dimensionsFromVector(vector12, attenuation: attenuation),
        provenanceTags: <String>[source, 'stable_key:${state.key.stableKey}'],
      );
    }
  }

  Map<String, double> _dimensionsFromVector(
    List<double> vector12, {
    double attenuation = 1.0,
  }) {
    final normalized = vector12.length == VibeConstants.coreDimensions.length
        ? vector12
        : List<double>.filled(VibeConstants.coreDimensions.length, 0.5);
    return <String, double>{
      for (var index = 0; index < VibeConstants.coreDimensions.length; index++)
        VibeConstants.coreDimensions[index]:
            (normalized[index] * attenuation + (0.5 * (1 - attenuation)))
                .clamp(0.0, 1.0),
    };
  }
}
