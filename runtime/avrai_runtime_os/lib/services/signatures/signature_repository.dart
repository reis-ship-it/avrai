import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_signal.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_runtime_policy.dart';
import 'package:reality_engine/reality_engine.dart';

class SignatureRepository {
  static const String _storagePrefix = 'entity_signature_v1:';

  final StorageService _storageService;

  SignatureRepository({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService.instance;

  Future<void> save(EntitySignature signature) async {
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storageService.setObject(
      _storageKey(signature.entityKind, signature.entityId),
      signature.toJson(),
    );
  }

  EntitySignature? get({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
    final canonicalSignature = _canonicalSignatureFor(
      entityKind: entityKind,
      entityId: entityId,
    );
    if (canonicalSignature != null) {
      return canonicalSignature;
    }
    final raw = _storageService.getObject<Map<dynamic, dynamic>>(
      _storageKey(entityKind, entityId),
    );
    if (raw == null) {
      return null;
    }

    return EntitySignature.fromJson(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  Future<void> remove({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) async {
    if (CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return;
    }
    await _storageService.remove(_storageKey(entityKind, entityId));
  }

  String _storageKey(SignatureEntityKind entityKind, String entityId) {
    return '$_storagePrefix${entityKind.name}:$entityId';
  }

  EntitySignature? _canonicalSignatureFor({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
    if (!CanonicalVibeRuntimePolicy.isCanonicalAuthorityActive) {
      return null;
    }

    try {
      if (entityKind == SignatureEntityKind.user) {
        if (!entityId.startsWith('agent_')) {
          return null;
        }
        final snapshot = VibeKernel().getUserSnapshot(entityId);
        if (!hasCanonicalVibeSignal(snapshot)) {
          return null;
        }
        return _signatureFromSnapshot(
          entityId: entityId,
          entityKind: entityKind,
          snapshot: snapshot,
        );
      }

      final snapshot = VibeKernel().getEntitySnapshot(
        entityId: entityId,
        entityType: entityKind.name,
      );
      if (!hasCanonicalVibeSignal(snapshot.vibe)) {
        return null;
      }
      return _signatureFromSnapshot(
        entityId: entityId,
        entityKind: entityKind,
        snapshot: snapshot.vibe,
      );
    } catch (_) {
      return null;
    }
  }

  EntitySignature _signatureFromSnapshot({
    required String entityId,
    required SignatureEntityKind entityKind,
    required VibeStateSnapshot snapshot,
  }) {
    return EntitySignature(
      signatureId: 'canonical:${entityKind.name}:$entityId',
      entityId: entityId,
      entityKind: entityKind,
      dna: Map<String, double>.from(snapshot.coreDna.dimensions),
      pheromones: Map<String, double>.from(snapshot.pheromones.vectors),
      confidence: snapshot.confidence,
      freshness: (1.0 - (snapshot.freshnessHours / 168.0)).clamp(0.0, 1.0),
      updatedAt: snapshot.updatedAtUtc,
      summary: 'Canonical ${entityKind.name} vibe projection from VibeKernel.',
      sourceTrace: const <SignatureSourceTrace>[
        SignatureSourceTrace(
          kind: SignatureSourceKind.derived,
          label: 'canonical_vibe_kernel',
          weight: 1.0,
        ),
      ],
    );
  }
}
