import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Reads cached + remote global priors for LocalityAgents (v1).
///
/// The remote table is introduced by the locality agents migrations:
/// - `public.locality_agent_global_v1`
///
/// The repository is best-effort and always returns something usable.
class LocalityAgentGlobalRepositoryV1 {
  static const String _logName = 'LocalityAgentGlobalRepositoryV1';
  static const String _box = 'spots_ai';

  final SupabaseService _supabaseService;
  final StorageService _storage;

  LocalityAgentGlobalRepositoryV1({
    required SupabaseService supabaseService,
    required StorageService storage,
  })  : _supabaseService = supabaseService,
        _storage = storage;

  String _cacheKey(LocalityAgentKeyV1 key) =>
      'locality_agent_global_v1:${key.stableKey}';

  /// Get global prior for [key], using cache if offline/unavailable.
  Future<LocalityAgentGlobalStateV1> getGlobalState(
      LocalityAgentKeyV1 key) async {
    // 1) Try remote
    try {
      final client = _supabaseService.tryGetClient();
      if (client != null) {
        final row = await client
            .from('locality_agent_global_v1')
            .select('*')
            .eq('stable_key', key.stableKey)
            .maybeSingle();
        if (row != null) {
          final mapped = (row as Map).cast<String, dynamic>();
          final state = _fromSupabaseRow(mapped, key);
          // best-effort cache
          await _storage.setObject(_cacheKey(key), state.toJson(), box: _box);
          return state;
        }
      }
    } catch (e, st) {
      developer.log('Global fetch failed (falling back to cache): $e',
          name: _logName, error: e, stackTrace: st);
    }

    // 2) Cache fallback
    try {
      final cached = _storage.getObject<Map<String, dynamic>>(
        _cacheKey(key),
        box: _box,
      );
      if (cached != null) {
        return LocalityAgentGlobalStateV1.fromJson(cached);
      }
    } catch (e, st) {
      developer.log('Global cache read failed: $e',
          name: _logName, error: e, stackTrace: st);
    }

    return LocalityAgentGlobalStateV1.empty(key);
  }

  LocalityAgentGlobalStateV1 _fromSupabaseRow(
    Map<String, dynamic> row,
    LocalityAgentKeyV1 key,
  ) {
    final vec = (row['vector12'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        List<double>.filled(12, 0.5);
    final conf = (row['confidence12'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    final updatedAt = DateTime.tryParse((row['updated_at'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return LocalityAgentGlobalStateV1(
      key: key,
      vector12: vec.length == 12 ? vec : List<double>.filled(12, 0.5),
      sampleCount: (row['sample_count'] as num?)?.toInt() ?? 0,
      confidence12: conf?.length == 12 ? conf : null,
      updatedAtUtc: updatedAt.toUtc(),
    );
  }
}
