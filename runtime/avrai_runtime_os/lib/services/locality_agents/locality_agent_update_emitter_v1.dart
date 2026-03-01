import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';

/// Emits privacy-bounded locality agent updates to Supabase (v1).
///
/// This writes to `public.locality_agent_updates_v1`.
class LocalityAgentUpdateEmitterV1 {
  static const String _logName = 'LocalityAgentUpdateEmitterV1';

  final SupabaseService _supabaseService;

  LocalityAgentUpdateEmitterV1({required SupabaseService supabaseService})
      : _supabaseService = supabaseService;

  /// Best-effort emit. If Supabase is unavailable/offline, this is a no-op.
  Future<void> emit({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      developer.log('Supabase unavailable; skipping update emit',
          name: _logName);
      return;
    }

    try {
      await client.from('locality_agent_updates_v1').insert({
        'user_id': userId,
        'stable_key': event.key.stableKey,
        'geohash_prefix': event.key.geohashPrefix,
        'geohash_precision': event.key.precision,
        // Legacy (v1) city bucket used by existing aggregations.
        'city_code': event.key.cityCode,
        // Dual-tracking fields (best-effort; may be null).
        'reported_city_code': event.reportedCityCode ?? event.key.cityCode,
        'inferred_city_code': event.inferredCityCode,
        'occurred_at': event.occurredAtUtc.toIso8601String(),
        'source': event.source,
        'dwell_minutes': event.dwellMinutes,
        'quality_score': event.qualityScore,
        'is_repeat_visit': event.isRepeatVisit,
      });
      developer.log(
        'Emitted locality agent update for ${event.key.stableKey} '
        '(reported=${event.reportedCityCode ?? event.key.cityCode} '
        'inferred=${event.inferredCityCode})',
        name: _logName,
      );
    } catch (e, st) {
      developer.log('Failed to emit locality agent update: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }
}
