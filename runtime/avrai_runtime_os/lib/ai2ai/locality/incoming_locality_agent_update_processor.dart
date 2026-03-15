// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/transport/mesh/adaptive_mesh_hop_policy.dart'
    as mesh_policy;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_inputs.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';
import 'package:avrai_runtime_os/services/vibe/scoped_context_vibe_projector.dart';
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

  static final HierarchicalLocalityVibeProjector _hierarchicalProjector =
      HierarchicalLocalityVibeProjector();
  static final ScopedContextVibeProjector _scopedProjector =
      ScopedContextVibeProjector();

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
    var stored = false;
    if (sl.isRegistered<WhereKernelContract>()) {
      try {
        final ttlMs =
            (payload['ttl_ms'] as num?)?.toInt() ?? (6 * 60 * 60 * 1000);
        stored = await sl<WhereKernelContract>().observeMeshUpdate(
          key: WhereMeshKey.fromLocality(key),
          delta12: delta12,
          ttlMs: ttlMs,
          hop: hop,
        );
      } catch (e) {
        logger.debug(
          'Failed to import mesh update through native locality kernel contract: $e',
          tag: logName,
        );
      }
    }

    if (!stored && sl.isRegistered<LocalityMemory>()) {
      try {
        final ttlMs =
            (payload['ttl_ms'] as num?)?.toInt() ?? (6 * 60 * 60 * 1000);
        await sl<LocalityMemory>().saveMeshUpdate(
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
          'Failed to store mesh update in locality memory: $e',
          tag: logName,
        );
      }
    }

    logger.debug(
      'Received locality agent update: ${key.stableKey} (hop=$hop)',
      tag: logName,
    );

    final geographicBinding = payload['geographic_vibe_binding'] is Map
        ? GeographicVibeBinding.fromJson(
            Map<String, dynamic>.from(
              payload['geographic_vibe_binding'] as Map,
            ),
          )
        : payload['locality_vibe_binding'] is Map
            ? LocalityVibeBinding.fromJson(
                Map<String, dynamic>.from(
                  payload['locality_vibe_binding'] as Map,
                ),
              ).toGeographicBinding()
            : GeographicVibeBinding(
                localityRef: VibeSubjectRef.locality(key.stableKey),
                stableKey: key.stableKey,
                higherGeographicRefs: <VibeSubjectRef>[
                  if (cityCode != null && cityCode.trim().isNotEmpty)
                    VibeSubjectRef.city(cityCode),
                ],
                scope: scope ?? 'locality',
                cityCode: cityCode,
              );
    final scopedBindings =
        ((payload['scoped_bindings'] as List?) ?? const <dynamic>[])
            .map(
              (entry) => ScopedVibeBinding.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList(growable: false);
    final dimensions = _dimensionsFromVector(delta12);
    _hierarchicalProjector.projectObservation(
      binding: geographicBinding,
      source: 'ai2ai_locality_update',
      dimensions: dimensions,
      provenanceTags: <String>[
        'ai2ai_locality_update',
        'origin:${payload['origin_id'] ?? senderId}',
      ],
    );
    _scopedProjector.projectScopedObservation(
      bindings: scopedBindings,
      source: 'ai2ai_locality_update',
      dimensions: dimensions,
      provenanceTags: <String>[
        'ai2ai_locality_update',
        'origin:${payload['origin_id'] ?? senderId}',
      ],
    );

    return LocalityAgentUpdateIngestionResult(
      hop: hop,
      originId: payload['origin_id'] as String? ?? senderId,
    );
  }

  static Map<String, double> _dimensionsFromVector(
    List<double> vector12, {
    double attenuation = 1.0,
  }) {
    final values = vector12.length == VibeConstants.coreDimensions.length
        ? vector12
        : List<double>.filled(VibeConstants.coreDimensions.length, 0.0);
    return <String, double>{
      for (var index = 0; index < VibeConstants.coreDimensions.length; index++)
        VibeConstants.coreDimensions[index]:
            (0.5 + (values[index] * attenuation)).clamp(0.0, 1.0),
    };
  }
}
