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

  final SupabaseService _supabaseService;

  LocalityAgentGlobalRepositoryV1({
    required SupabaseService supabaseService,
    StorageService? storage,
  }) : _supabaseService = supabaseService;

  /// Get global prior for [key] from the remote aggregation surface.
  Future<LocalityAgentGlobalStateV1> getGlobalState(
      LocalityAgentKeyV1 key) async {
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
          return _fromSupabaseRow(mapped, key);
        }
      }
    } catch (e, st) {
      developer.log('Global fetch failed (falling back to empty): $e',
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
      aggregateHappiness:
          (row['aggregate_happiness'] as num?)?.toDouble() ?? 0.5,
      happinessSampleCount:
          (row['happiness_sample_count'] as num?)?.toInt() ?? 0,
      happinessTrendSlope:
          (row['happiness_trend_slope'] as num?)?.toDouble() ?? 0.0,
      updatedAtUtc: updatedAt.toUtc(),
    );
  }
}
