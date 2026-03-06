import 'package:avrai_core/models/signatures/entity_signature.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

class SignatureRepository {
  static const String _storagePrefix = 'entity_signature_v1:';

  final StorageService _storageService;

  SignatureRepository({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService.instance;

  Future<void> save(EntitySignature signature) async {
    await _storageService.setObject(
      _storageKey(signature.entityKind, signature.entityId),
      signature.toJson(),
    );
  }

  EntitySignature? get({
    required SignatureEntityKind entityKind,
    required String entityId,
  }) {
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
    await _storageService.remove(_storageKey(entityKind, entityId));
  }

  String _storageKey(SignatureEntityKind entityKind, String entityId) {
    return '$_storagePrefix${entityKind.name}:$entityId';
  }
}
