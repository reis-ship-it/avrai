import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

class LocalityCloudPriorGateway {
  static const String _logName = 'LocalityCloudPriorGateway';

  final SupabaseService _supabaseService;

  LocalityCloudPriorGateway({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    final fetchedAtUtc = DateTime.now().toUtc();
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
          return _fromSupabaseRow(mapped, key, fetchedAtUtc: fetchedAtUtc);
        }
      }
    } catch (e, st) {
      developer.log(
        'Global prior fetch failed (falling back to empty): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }

    return LocalityAgentGlobalStateV1.empty(key);
  }

  LocalityAgentGlobalStateV1 _fromSupabaseRow(
    Map<String, dynamic> row,
    LocalityAgentKeyV1 key, {
    required DateTime fetchedAtUtc,
  }) {
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
      syncedAtUtc: fetchedAtUtc,
    );
  }
}
