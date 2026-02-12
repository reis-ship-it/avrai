import 'package:get_storage/get_storage.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/models/quantum/decoherence_pattern.dart';
import 'package:avrai/data/datasources/local/decoherence_pattern_local_datasource.dart';

/// GetStorage Data Source Implementation for Decoherence Patterns
///
/// Stores decoherence patterns in local GetStorage (offline-first).
/// Replaces DecoherencePatternSembastDataSource as part of Phase 26 migration.
class DecoherencePatternGetStorageDataSource
    implements DecoherencePatternLocalDataSource {
  static const String _boxName = 'decoherence_patterns';
  static const String _indexKey = '_pattern_index';

  late final GetStorage _box;
  final AppLogger _logger = const AppLogger(
    defaultTag: 'DecoherencePatternDataSource',
    minimumLevel: LogLevel.debug,
  );

  DecoherencePatternGetStorageDataSource() {
    _box = GetStorage(_boxName);
  }

  /// Initialize storage (call during app startup)
  static Future<void> initStorage() async {
    await GetStorage.init(_boxName);
  }

  @override
  Future<DecoherencePattern?> getByUserId(String userId) async {
    try {
      final data = _box.read<Map<String, dynamic>>('pattern_$userId');
      if (data != null) {
        return DecoherencePattern.fromJson(data);
      }
      return null;
    } catch (e) {
      _logger.error(
        'Error getting decoherence pattern',
        error: e,
        tag: 'DecoherencePatternGetStorageDataSource',
      );
      return null;
    }
  }

  @override
  Future<void> save(DecoherencePattern pattern) async {
    try {
      final patternData = pattern.toJson();
      await _box.write('pattern_${pattern.userId}', patternData);

      // Update index
      final index = _getIndex();
      if (!index.contains(pattern.userId)) {
        index.add(pattern.userId);
        await _box.write(_indexKey, index);
      }
    } catch (e) {
      _logger.error(
        'Error saving decoherence pattern',
        error: e,
        tag: 'DecoherencePatternGetStorageDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<List<DecoherencePattern>> getAll() async {
    try {
      final index = _getIndex();
      final patterns = <DecoherencePattern>[];

      for (final userId in index) {
        final pattern = await getByUserId(userId);
        if (pattern != null) {
          patterns.add(pattern);
        }
      }

      return patterns;
    } catch (e) {
      _logger.error(
        'Error getting all decoherence patterns',
        error: e,
        tag: 'DecoherencePatternGetStorageDataSource',
      );
      return [];
    }
  }

  @override
  Future<void> delete(String userId) async {
    try {
      await _box.remove('pattern_$userId');

      // Update index
      final index = _getIndex();
      index.remove(userId);
      await _box.write(_indexKey, index);
    } catch (e) {
      _logger.error(
        'Error deleting decoherence pattern',
        error: e,
        tag: 'DecoherencePatternGetStorageDataSource',
      );
      rethrow;
    }
  }

  /// Get the list of stored user IDs
  List<String> _getIndex() {
    final indexData = _box.read<List<dynamic>>(_indexKey);
    if (indexData == null) return [];
    return indexData.cast<String>();
  }
}
