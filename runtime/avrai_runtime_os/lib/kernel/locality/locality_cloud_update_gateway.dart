import 'dart:developer' as developer;

import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

class LocalityCloudUpdateGateway {
  static const String _logName = 'LocalityCloudUpdateGateway';

  final SupabaseService _supabaseService;

  LocalityCloudUpdateGateway({
    required SupabaseService supabaseService,
  }) : _supabaseService = supabaseService;

  Future<void> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {
    final client = _supabaseService.tryGetClient();
    if (client == null) {
      developer.log(
        'Supabase unavailable; skipping locality cloud update emit',
        name: _logName,
      );
      return;
    }

    try {
      await client.from('locality_agent_updates_v1').insert({
        'user_id': userId,
        'stable_key': event.key.stableKey,
        'geohash_prefix': event.key.geohashPrefix,
        'geohash_precision': event.key.precision,
        'city_code': event.key.cityCode,
        'reported_city_code': event.reportedCityCode ?? event.key.cityCode,
        'inferred_city_code': event.inferredCityCode,
        'occurred_at': event.occurredAtUtc.toIso8601String(),
        'source': event.source,
        'dwell_minutes': event.dwellMinutes,
        'quality_score': event.qualityScore,
        'is_repeat_visit': event.isRepeatVisit,
      });
    } catch (e, st) {
      developer.log(
        'Failed to emit locality cloud update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
}
