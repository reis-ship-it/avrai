import 'dart:convert';

import 'package:avrai_core/models/discovery/discovery_models.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:get_it/get_it.dart';

class SavedDiscoveryService {
  static const String _storageKeyPrefix = 'bham:saved_discovery:v1:';

  final SharedPreferencesCompat? _prefs;

  SavedDiscoveryService({
    SharedPreferencesCompat? prefs,
  }) : _prefs = prefs ??
            (GetIt.instance.isRegistered<SharedPreferencesCompat>()
                ? GetIt.instance<SharedPreferencesCompat>()
                : null);

  Future<void> save({
    required String userId,
    required DiscoveryEntityReference entity,
    required String sourceSurface,
    RecommendationAttribution? attribution,
  }) async {
    final items = await listAll(userId);
    final next = <SavedDiscoveryEntity>[
      ...items.where(
        (item) =>
            item.entity.type != entity.type || item.entity.id != entity.id,
      ),
      SavedDiscoveryEntity(
        userId: userId,
        entity: entity,
        savedAtUtc: DateTime.now().toUtc(),
        sourceSurface: sourceSurface,
        attribution: attribution,
      ),
    ];
    await _writeAll(userId, next);
  }

  Future<void> unsave({
    required String userId,
    required DiscoveryEntityReference entity,
  }) async {
    final items = await listAll(userId);
    final next = items.where(
      (item) => item.entity.type != entity.type || item.entity.id != entity.id,
    );
    await _writeAll(userId, next.toList());
  }

  Future<bool> isSaved({
    required String userId,
    required DiscoveryEntityReference entity,
  }) async {
    final items = await listAll(userId);
    return items.any(
      (item) => item.entity.type == entity.type && item.entity.id == entity.id,
    );
  }

  Future<List<SavedDiscoveryEntity>> listSavedByType({
    required String userId,
    required DiscoveryEntityType type,
  }) async {
    final items = await listAll(userId);
    return items.where((item) => item.entity.type == type).toList()
      ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
  }

  Future<List<SavedDiscoveryEntity>> listAll(String userId) async {
    final raw = _prefs?.getString(_storageKey(userId));
    if (raw == null || raw.isEmpty) {
      return const <SavedDiscoveryEntity>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <SavedDiscoveryEntity>[];
      }
      return decoded
          .whereType<Map>()
          .map(
            (item) => SavedDiscoveryEntity.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList()
        ..sort((a, b) => b.savedAtUtc.compareTo(a.savedAtUtc));
    } catch (_) {
      return const <SavedDiscoveryEntity>[];
    }
  }

  Future<void> clearAll(String userId) async {
    await _prefs?.remove(_storageKey(userId));
  }

  Future<void> _writeAll(
    String userId,
    List<SavedDiscoveryEntity> entities,
  ) async {
    await _prefs?.setString(
      _storageKey(userId),
      jsonEncode(entities.map((entity) => entity.toJson()).toList()),
    );
  }

  String _storageKey(String userId) => '$_storageKeyPrefix$userId';
}
