import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';

class LocalityTransportSupport {
  static const String _logName = 'LocalityTransportSupport';

  final LocalityInfrastructureBridge _infrastructureBridge;
  final HierarchicalLocalityVibeProjector _hierarchicalProjector =
      HierarchicalLocalityVibeProjector();

  LocalityTransportSupport({
    required LocalityInfrastructureBridge infrastructureBridge,
  }) : _infrastructureBridge = infrastructureBridge;

  Future<bool> emitObservation(LocalityObservation observation) async {
    try {
      final emittedAtUtc = DateTime.now().toUtc();
      return await _infrastructureBridge.emitObservation(
        userId: observation.userId,
        event: observation.toUpdateEvent(
          emittedAtUtc: emittedAtUtc,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to emit locality observation: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> forwardMeshUpdate({
    required String agentId,
    required LocalityAgentKeyV1 key,
    required LocalityAgentPersonalDeltaV1 delta,
  }) async {
    try {
      final sl = GetIt.instance;
      if (!sl.isRegistered<VibeConnectionOrchestrator>()) {
        return false;
      }

      final orchestrator = sl<VibeConnectionOrchestrator>();
      final scope = _scopeFromPrecision(key.precision);
      final localityRef = VibeSubjectRef.locality(key.stableKey);
      final geographicBinding = GeographicVibeBinding(
        localityRef: localityRef,
        stableKey: key.stableKey,
        higherGeographicRefs: <VibeSubjectRef>[
          if (key.cityCode != null && key.cityCode!.trim().isNotEmpty)
            VibeSubjectRef.city(key.cityCode!),
        ],
        scope: scope,
        cityCode: key.cityCode,
      );
      final receipts = _hierarchicalProjector.projectObservation(
        binding: geographicBinding,
        source: 'locality_mesh_forward',
        dimensions: _dimensionsFromVector(delta.delta12),
        provenanceTags: <String>[
          'locality_mesh_forward',
          'stable_key:${key.stableKey}',
        ],
      );
      final localityReceipt = receipts.isEmpty ? null : receipts.first;
      final ai2aiVibeReference = Ai2AiVibeReference(
        subjectRef: localityRef,
        scope: scope,
        confidence: localityReceipt?.snapshot.confidence ?? 0.5,
        geographicBinding: geographicBinding,
        snapshotUpdatedAtUtc: localityReceipt?.snapshot.updatedAtUtc,
        metadata: <String, dynamic>{
          'visit_count': delta.visitCount,
        },
      );
      await orchestrator.forwardLocalityAgentUpdate({
        'type': 'locality_agent_update',
        'agent_id': agentId,
        'key': key.stableKey,
        'geohash_prefix': key.geohashPrefix,
        'precision': key.precision,
        'city_code': key.cityCode,
        'delta12': delta.delta12,
        'visit_count': delta.visitCount,
        'origin_occurred_at':
            delta.originOccurredAtUtc?.toUtc().toIso8601String(),
        'local_state_captured_at':
            delta.localStateCapturedAtUtc?.toUtc().toIso8601String(),
        'hop': 0,
        'origin_id': agentId,
        'scope': scope,
        'geographic_vibe_binding': geographicBinding.toJson(),
        'locality_vibe_binding':
            LocalityVibeBinding.fromGeographicBinding(geographicBinding)
                .toJson(),
        'ai2ai_vibe_reference': ai2aiVibeReference.toJson(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'kernel_exchange_phase':
            delta.kernelExchangePhase ?? 'locality_mesh_forward',
        'ttl_ms': 6 * 60 * 60 * 1000,
      });
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to forward locality mesh update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> ingestMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    try {
      final imported = await _infrastructureBridge.persistMeshUpdate(
        key: key,
        delta12: delta12,
        ttl: Duration(milliseconds: ttlMs),
      );
      if (!imported) {
        developer.log(
          'Skipping mesh locality import because no locality infrastructure persistence is registered',
          name: _logName,
        );
        return false;
      }
      developer.log(
        'Imported mesh locality update for ${key.stableKey} (hop=$hop)',
        name: _logName,
      );
      final geographicBinding = GeographicVibeBinding(
        localityRef: VibeSubjectRef.locality(key.stableKey),
        stableKey: key.stableKey,
        higherGeographicRefs: <VibeSubjectRef>[
          if ((key.cityCode ?? '').trim().isNotEmpty)
            VibeSubjectRef.city(key.cityCode!.trim()),
        ],
        scope: _scopeFromPrecision(key.precision),
        cityCode: key.cityCode,
      );
      _hierarchicalProjector.projectObservation(
        binding: geographicBinding,
        source: 'locality_mesh_ingest',
        dimensions: _dimensionsFromVector(delta12),
        provenanceTags: <String>['locality_mesh_ingest', 'hop:$hop'],
      );
      return imported;
    } catch (e, st) {
      developer.log(
        'Failed to import mesh locality update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<LocalitySyncResult> sync(LocalitySyncRequest request) async {
    return LocalitySyncResult(
      synced: request.allowCloud || request.allowMesh,
      message: 'Locality transport support is active for ${request.agentId}',
    );
  }

  String _scopeFromPrecision(int precision) {
    if (precision >= 7) return 'locality';
    if (precision >= 6) return 'city';
    if (precision >= 5) return 'region';
    if (precision >= 4) return 'country';
    return 'global';
  }

  Map<String, double> _dimensionsFromVector(
    List<double> vector12, {
    double attenuation = 1.0,
  }) {
    final dimensions = VibeConstants.coreDimensions;
    final values = vector12.length == dimensions.length
        ? vector12
        : List<double>.filled(dimensions.length, 0.0);
    return <String, double>{
      for (var index = 0; index < dimensions.length; index++)
        dimensions[index]:
            (0.5 + (values[index] * attenuation)).clamp(0.0, 1.0),
    };
  }
}
