import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_token.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

class LocalityNativeSyncPayloadBuilder {
  final LocalityInfrastructureBridge _infrastructureBridge;

  LocalityNativeSyncPayloadBuilder({
    required LocalityInfrastructureBridge infrastructureBridge,
  }) : _infrastructureBridge = infrastructureBridge;

  Future<Map<String, dynamic>> build(
    LocalitySyncRequest request, {
    LocalityKernelSnapshot? snapshot,
  }) async {
    final payload = <String, dynamic>{
      ...request.toJson(),
      'syncedAtUtc': DateTime.now().toUtc().toIso8601String(),
    };

    final currentSnapshot = snapshot;
    if (currentSnapshot == null) {
      return payload;
    }

    payload['snapshot'] = currentSnapshot.toJson();
    final key = _keyFromState(currentSnapshot.state);
    if (key == null) {
      return payload;
    }

    if (request.allowCloud) {
      final globalState = await _infrastructureBridge.fetchGlobalState(key);
      payload['globalState'] = globalState.toJson();
    }
    if (request.allowMesh) {
      payload['neighborMeshUpdates'] =
          _infrastructureBridge.readNeighborMeshUpdates(key);
    }

    return payload;
  }

  LocalityAgentKeyV1? _keyFromState(LocalityState state) {
    final token = state.activeToken;
    if (token.kind != LocalityTokenKind.geohashCell) {
      return null;
    }

    final parts = token.id.split(':');
    if (parts.length != 2) {
      return null;
    }

    final precision = int.tryParse(
      parts.first.startsWith('gh') ? parts.first.substring(2) : '',
    );
    if (precision == null) {
      return null;
    }

    final parentToken = state.parentToken;
    final cityCode = parentToken?.kind == LocalityTokenKind.cityPrior
        ? parentToken?.id
        : null;

    return LocalityAgentKeyV1(
      geohashPrefix: parts[1],
      precision: precision,
      cityCode: cityCode,
    );
  }
}
