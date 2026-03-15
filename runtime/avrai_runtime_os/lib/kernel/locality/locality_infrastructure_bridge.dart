import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';

class LocalityInfrastructureBridge {
  static const String _logName = 'LocalityInfrastructureBridge';

  final LocalityCloudPriorGateway _cloudPriorGateway;
  final LocalityCloudUpdateGateway _cloudUpdateGateway;
  final LocalityMemory? _memory;
  final HierarchicalLocalityVibeProjector _hierarchicalProjector =
      HierarchicalLocalityVibeProjector();

  LocalityInfrastructureBridge({
    required LocalityCloudPriorGateway cloudPriorGateway,
    required LocalityCloudUpdateGateway cloudUpdateGateway,
    LocalityMemory? memory,
  })  : _cloudPriorGateway = cloudPriorGateway,
        _cloudUpdateGateway = cloudUpdateGateway,
        _memory = memory;

  Future<LocalityAgentGlobalStateV1> fetchGlobalState(
    LocalityAgentKeyV1 key,
  ) async {
    final cached =
        _memory?.getGlobalState(key) ?? _memory?.getCanonicalGlobalState(key);
    try {
      final remote = await _cloudPriorGateway.fetchGlobalState(key);
      final shouldUseCached =
          remote.sampleCount == 0 && cached != null && cached.sampleCount > 0;
      final resolved = shouldUseCached ? cached : remote;
      if (_memory != null) {
        await _memory.saveGlobalState(state: resolved);
      }
      _syncCanonicalVibeState(resolved);
      return resolved;
    } catch (e, st) {
      developer.log(
        'Failed to refresh locality infrastructure state: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return cached ?? LocalityAgentGlobalStateV1.empty(key);
    }
  }

  List<List<double>> readNeighborMeshUpdates(LocalityAgentKeyV1 key) {
    return _memory?.getNeighborMeshUpdates(key) ?? const <List<double>>[];
  }

  Future<bool> emitObservation({
    required String userId,
    required LocalityAgentUpdateEventV1 event,
  }) async {
    try {
      await _cloudUpdateGateway.emitObservation(userId: userId, event: event);
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to emit locality infrastructure observation: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  Future<bool> persistMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required Duration ttl,
  }) async {
    if (_memory == null) {
      developer.log(
        'Skipping mesh locality persistence because no locality memory is registered',
        name: _logName,
      );
      return false;
    }
    try {
      await _memory.saveMeshUpdate(
        key: key,
        delta12: delta12,
        receivedAt: DateTime.now(),
        ttl: ttl,
      );
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to persist mesh locality update: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  void _syncCanonicalVibeState(LocalityAgentGlobalStateV1 state) {
    final binding = GeographicVibeBinding(
      localityRef: VibeSubjectRef.locality(state.key.stableKey),
      stableKey: state.key.stableKey,
      higherGeographicRefs: <VibeSubjectRef>[
        if ((state.key.cityCode ?? '').trim().isNotEmpty)
          VibeSubjectRef.city(state.key.cityCode!.trim()),
      ],
      scope: 'locality',
      cityCode: state.key.cityCode,
    );
    _hierarchicalProjector.projectObservation(
      binding: binding,
      source: 'locality_cloud_prior',
      dimensions: <String, double>{
        for (var index = 0;
            index < VibeConstants.coreDimensions.length;
            index++)
          VibeConstants.coreDimensions[index]:
              (index < state.vector12.length ? state.vector12[index] : 0.5)
                  .clamp(0.0, 1.0),
      },
      provenanceTags: <String>[
        'locality_cloud_prior',
        'stable_key:${state.key.stableKey}',
      ],
    );
  }
}
