import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';

abstract class LocalitySyscallTransport {
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  });

  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class InProcessLocalitySyscallTransport implements LocalitySyscallTransport {
  final LocalityKernelContract delegate;

  const InProcessLocalitySyscallTransport({
    required this.delegate,
  });

  @override
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) async {
    switch (syscall) {
      case 'resolve_where':
        return (await delegate.resolveWhere(
          LocalityPerceptionInput.fromJson(payload),
        ))
            .toJson();
      case 'seed_homebase':
        return (await delegate.seedHomebase(
          userId: (payload['userId'] as String?) ?? '',
          agentId: (payload['agentId'] as String?) ?? '',
          latitude: (payload['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (payload['longitude'] as num?)?.toDouble() ?? 0.0,
          cityCode: payload['cityCode'] as String?,
          source: (payload['source'] as String?) ?? 'native_stub',
        ))
            .toJson();
      case 'observe_visit':
        final receipt = await delegate.observeVisit(
          userId: (payload['userId'] as String?) ?? '',
          visit: Visit.fromJson(
            Map<String, dynamic>.from(payload['visit'] as Map? ?? const {}),
          ),
          source: (payload['source'] as String?) ?? 'native_stub',
        );
        return {
          if (receipt != null) 'receipt': receipt.toJson(),
        };
      case 'observe_locality':
        return (await delegate.observe(
          LocalityObservation.fromJson(payload),
        ))
            .toJson();
      case 'sync_locality':
        return (await delegate.sync(
          LocalitySyncRequest.fromJson(payload),
        ))
            .toJson();
      case 'resolve_point_locality':
        return (await delegate.resolvePoint(
          LocalityPointQuery.fromJson(payload),
        ))
            .toJson();
      case 'observe_mesh_locality':
        final observed = await delegate.observeMeshUpdate(
          key: LocalityAgentKeyV1.fromJson(
            Map<String, dynamic>.from(payload['key'] as Map? ?? const {}),
          ),
          delta12: (payload['delta12'] as List?)
                  ?.map((entry) => (entry as num).toDouble())
                  .toList() ??
              const <double>[],
          ttlMs: (payload['ttlMs'] as num?)?.toInt() ?? 0,
          hop: (payload['hop'] as num?)?.toInt() ?? 0,
        );
        return {'observed': observed};
      case 'evaluate_zero_locality':
        return (await delegate.evaluateZeroLocalityReadiness(
          cityProfile: (payload['cityProfile'] as String?) ?? 'unknown',
          modelFamily: (payload['modelFamily'] as String?) ?? 'default',
          localityCount: (payload['localityCount'] as num?)?.toInt() ?? 12,
        ))
            .toJson();
      case 'recover_locality':
        return (await delegate.recover(
          LocalityRecoveryRequest.fromJson(payload),
        ))
            .toJson();
      default:
        throw UnsupportedError('Unknown async locality syscall: $syscall');
    }
  }

  @override
  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'project_locality':
        return delegate
            .project(
              LocalityProjectionRequest.fromJson(payload),
            )
            .toJson();
      case 'snapshot_locality':
        final snapshot =
            delegate.snapshot((payload['agentId'] as String?) ?? '');
        return {
          if (snapshot != null) 'snapshot': snapshot.toJson(),
        };
      default:
        throw UnsupportedError('Unknown sync locality syscall: $syscall');
    }
  }
}

class LocalityNativeKernelStub implements LocalityKernelContract {
  final LocalitySyscallTransport transport;

  const LocalityNativeKernelStub({
    required this.transport,
  });

  @override
  Future<LocalityState> resolveWhere(LocalityPerceptionInput input) async {
    final response = await transport.invokeAsync(
      syscall: 'resolve_where',
      payload: input.toJson(),
    );
    return LocalityState.fromJson(response);
  }

  @override
  Future<LocalityState> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'native_stub',
  }) async {
    final response = await transport.invokeAsync(
      syscall: 'seed_homebase',
      payload: {
        'userId': userId,
        'agentId': agentId,
        'latitude': latitude,
        'longitude': longitude,
        if (cityCode != null) 'cityCode': cityCode,
        'source': source,
      },
    );
    return LocalityState.fromJson(response);
  }

  @override
  Future<LocalityUpdateReceipt?> observeVisit({
    required String userId,
    required Visit visit,
    required String source,
  }) async {
    final response = await transport.invokeAsync(
      syscall: 'observe_visit',
      payload: {
        'userId': userId,
        'visit': visit.toJson(),
        'source': source,
      },
    );
    final receipt = response['receipt'];
    if (receipt == null) {
      return null;
    }
    return LocalityUpdateReceipt.fromJson(
      Map<String, dynamic>.from(receipt as Map),
    );
  }

  @override
  Future<LocalityUpdateReceipt> observe(LocalityObservation observation) async {
    final response = await transport.invokeAsync(
      syscall: 'observe_locality',
      payload: observation.toJson(),
    );
    return LocalityUpdateReceipt.fromJson(response);
  }

  @override
  Future<LocalitySyncResult> sync(LocalitySyncRequest request) async {
    final response = await transport.invokeAsync(
      syscall: 'sync_locality',
      payload: request.toJson(),
    );
    return LocalitySyncResult.fromJson(response);
  }

  @override
  LocalityProjection project(LocalityProjectionRequest request) {
    final response = transport.invokeSync(
      syscall: 'project_locality',
      payload: request.toJson(),
    );
    return LocalityProjection.fromJson(response);
  }

  @override
  Future<LocalityPointResolution> resolvePoint(
      LocalityPointQuery request) async {
    final response = await transport.invokeAsync(
      syscall: 'resolve_point_locality',
      payload: request.toJson(),
    );
    return LocalityPointResolution.fromJson(response);
  }

  @override
  Future<bool> observeMeshUpdate({
    required LocalityAgentKeyV1 key,
    required List<double> delta12,
    required int ttlMs,
    required int hop,
  }) async {
    final response = await transport.invokeAsync(
      syscall: 'observe_mesh_locality',
      payload: {
        'key': key.toJson(),
        'delta12': delta12,
        'ttlMs': ttlMs,
        'hop': hop,
      },
    );
    return response['observed'] as bool? ?? false;
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocalityReadiness({
    required String cityProfile,
    String modelFamily = 'default',
    int localityCount = 12,
  }) async {
    final response = await transport.invokeAsync(
      syscall: 'evaluate_zero_locality',
      payload: {
        'cityProfile': cityProfile,
        'modelFamily': modelFamily,
        'localityCount': localityCount,
      },
    );
    return LocalityZeroReliabilityReport.fromJson(response);
  }

  @override
  LocalityKernelSnapshot? snapshot(String agentId) {
    final response = transport.invokeSync(
      syscall: 'snapshot_locality',
      payload: {'agentId': agentId},
    );
    final snapshot = response['snapshot'];
    if (snapshot == null) {
      return null;
    }
    return LocalityKernelSnapshot.fromJson(
      Map<String, dynamic>.from(snapshot as Map),
    );
  }

  @override
  Future<LocalityRecoveryResult> recover(
      LocalityRecoveryRequest request) async {
    final response = await transport.invokeAsync(
      syscall: 'recover_locality',
      payload: request.toJson(),
    );
    return LocalityRecoveryResult.fromJson(response);
  }
}
