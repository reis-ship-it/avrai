// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_mesh_cache.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:get_it/get_it.dart';

class LocalityAgentUpdateIngestionResult {
  const LocalityAgentUpdateIngestionResult({
    required this.hop,
    required this.originId,
  });

  final int hop;
  final String originId;
}

class IncomingLocalityAgentUpdateProcessor {
  const IncomingLocalityAgentUpdateProcessor._();

  static Future<LocalityAgentUpdateIngestionResult?> process({
    required Map<String, dynamic> payload,
    required String senderId,
    required AdaptiveMeshNetworkingService? adaptiveMeshService,
    required AppLogger logger,
    required String logName,
  }) async {
    final type = payload['type'] as String?;
    if (type != 'locality_agent_update') return null;

    final geohashPrefix = payload['geohash_prefix'] as String?;
    final precision = (payload['precision'] as num?)?.toInt() ?? 7;
    final cityCode = payload['city_code'] as String?;
    final delta12Raw = payload['delta12'] as List?;
    final hop = (payload['hop'] as num?)?.toInt() ?? 0;

    if (geohashPrefix == null || delta12Raw == null) return null;
    if (hop < 0) return null;

    final scope = payload['scope'] as String?;
    if (adaptiveMeshService != null) {
      if (!adaptiveMeshService.shouldForwardMessage(
        currentHop: hop,
        priority: mesh_policy.MessagePriority.high,
        messageType: mesh_policy.MessageType.localityAgentUpdate,
        geographicScope: scope,
      )) {
        return null;
      }
    }

    final delta12 = delta12Raw
        .map((e) => (e as num).toDouble())
        .where((v) => v.abs() <= 0.35)
        .toList();
    if (delta12.length != 12) return null;

    final key = LocalityAgentKeyV1(
      geohashPrefix: geohashPrefix,
      precision: precision,
      cityCode: cityCode,
    );

    final sl = GetIt.instance;
    if (sl.isRegistered<LocalityAgentMeshCache>()) {
      try {
        final meshCache = sl<LocalityAgentMeshCache>();
        final ttlMs =
            (payload['ttl_ms'] as num?)?.toInt() ?? (6 * 60 * 60 * 1000);
        await meshCache.storeMeshUpdate(
          key: key,
          delta12: delta12,
          receivedAt: DateTime.now(),
          ttl: Duration(milliseconds: ttlMs),
        );
        logger.debug(
          'Stored locality agent mesh update: ${key.stableKey} (hop=$hop)',
          tag: logName,
        );
      } catch (e) {
        logger.debug(
          'Failed to store mesh update in cache: $e',
          tag: logName,
        );
      }
    }

    logger.debug(
      'Received locality agent update: ${key.stableKey} (hop=$hop)',
      tag: logName,
    );

    return LocalityAgentUpdateIngestionResult(
      hop: hop,
      originId: payload['origin_id'] as String? ?? senderId,
    );
  }
}
