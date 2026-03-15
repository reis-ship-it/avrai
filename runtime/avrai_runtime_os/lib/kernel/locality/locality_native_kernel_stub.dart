import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_sync_payload_builder.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_why_contract.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_agent_models_v1.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';

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
  final LocalityWhereProviderFallbackSurface delegate;

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
        return {
          'stored': await delegate.observeMeshUpdate(
            key: LocalityAgentKeyV1.fromJson(
              Map<String, dynamic>.from(payload['key'] as Map? ?? const {}),
            ),
            delta12: (payload['delta12'] as List? ?? const <dynamic>[])
                .map((entry) => (entry as num).toDouble())
                .toList(),
            ttlMs: (payload['ttlMs'] as num?)?.toInt() ?? 0,
            hop: (payload['hop'] as num?)?.toInt() ?? 0,
          ),
        };
      case 'evaluate_zero_locality':
        return (await delegate.evaluateZeroLocalityReadiness(
          cityProfile: (payload['cityProfile'] as String?) ?? 'unknown',
          modelFamily: (payload['modelFamily'] as String?) ?? 'reality_kernel',
          localityCount: (payload['localityCount'] as num?)?.toInt() ?? 12,
        ))
            .toJson();
      case 'project_where_reality':
        return (await delegate.projectForRealityModel(
          LocalityProjectionRequest.fromJson(payload),
        ))
            .toJson();
      case 'project_where_governance':
        return (await delegate.projectForGovernance(
          LocalityProjectionRequest.fromJson(payload),
        ))
            .toJson();
      case 'diagnose_where_kernel':
        return (await delegate.diagnoseWhere()).toJson();
      case 'recover_locality':
        return (await delegate.recover(
          LocalityRecoveryRequest.fromJson(payload),
        ))
            .toJson();
      default:
        throw UnsupportedError('Unsupported async locality syscall: $syscall');
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
      case 'explain_why':
        return delegate
            .explainWhy(
              WhyKernelRequest.fromJson(payload),
            )
            .toJson();
      default:
        throw UnsupportedError('Unsupported sync locality syscall: $syscall');
    }
  }
}

class FfiPreferredLocalitySyscallTransport implements LocalitySyscallTransport {
  final LocalityNativeInvocationBridge nativeBridge;
  final LocalitySyscallTransport fallbackTransport;
  final LocalityNativeExecutionPolicy policy;
  final LocalityNativeFallbackAudit? audit;

  const FfiPreferredLocalitySyscallTransport({
    required this.nativeBridge,
    required this.fallbackTransport,
    this.policy = const LocalityNativeExecutionPolicy(),
    this.audit,
  });

  @override
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) async {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(syscall: syscall, payload: payload);
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        return Map<String, dynamic>.from(
          response['payload'] as Map? ?? response,
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: LocalityNativeFallbackReason.deferred,
      );
      return fallbackTransport.invokeAsync(syscall: syscall, payload: payload);
    }
    audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: LocalityNativeFallbackReason.unavailable,
    );
    return fallbackTransport.invokeAsync(syscall: syscall, payload: payload);
  }

  @override
  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    nativeBridge.initialize();
    if (nativeBridge.isAvailable) {
      final response = nativeBridge.invoke(syscall: syscall, payload: payload);
      if (response['handled'] == true) {
        audit?.recordNativeHandled();
        return Map<String, dynamic>.from(
          response['payload'] as Map? ?? response,
        );
      }
      audit?.recordFallback(LocalityNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: LocalityNativeFallbackReason.deferred,
      );
      return fallbackTransport.invokeSync(syscall: syscall, payload: payload);
    }
    audit?.recordFallback(LocalityNativeFallbackReason.unavailable);
    policy.verifyFallbackAllowed(
      syscall: syscall,
      reason: LocalityNativeFallbackReason.unavailable,
    );
    return fallbackTransport.invokeSync(syscall: syscall, payload: payload);
  }
}

class LocalityNativeKernelStub implements LocalityWhereProviderContract {
  final LocalitySyscallTransport transport;
  final AgentIdService? agentIdService;
  final LocalityNativeSyncPayloadBuilder? syncPayloadBuilder;
  final KernelOutcomeAttributionLane? kernelOutcomeAttributionLane;
  final KernelOutcomeAttributionLane? Function()?
      kernelOutcomeAttributionLaneProvider;

  const LocalityNativeKernelStub({
    required this.transport,
    this.agentIdService,
    this.syncPayloadBuilder,
    this.kernelOutcomeAttributionLane,
    this.kernelOutcomeAttributionLaneProvider,
  });

  KernelOutcomeAttributionLane? get _resolvedKernelOutcomeAttributionLane =>
      kernelOutcomeAttributionLane ?? kernelOutcomeAttributionLaneProvider?.call();

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
    final resolvedAgentId = agentIdService == null
        ? null
        : await agentIdService!.getUserAgentId(userId);
    final response = await transport.invokeAsync(
      syscall: 'observe_visit',
      payload: {
        'userId': userId,
        if (resolvedAgentId != null) 'agentId': resolvedAgentId,
        'visit': visit.toJson(),
        'source': source,
      },
    );
    final receipt = response['receipt'];
    if (receipt is! Map) {
      return null;
    }
    return LocalityUpdateReceipt.fromJson(Map<String, dynamic>.from(receipt));
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
    final currentSnapshot = snapshot(request.agentId);
    final payload = syncPayloadBuilder == null
        ? request.toJson()
        : await syncPayloadBuilder!.build(request, snapshot: currentSnapshot);
    final response = await transport.invokeAsync(
      syscall: 'sync_locality',
      payload: payload,
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
    return response['stored'] as bool? ?? false;
  }

  @override
  Future<LocalityZeroReliabilityReport> evaluateZeroLocalityReadiness({
    required String cityProfile,
    String modelFamily = 'reality_kernel',
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
    final snapshotJson = response['snapshot'];
    if (snapshotJson is! Map) {
      return null;
    }
    return LocalityKernelSnapshot.fromJson(
      Map<String, dynamic>.from(snapshotJson),
    );
  }

  @override
  Future<LocalityRecoveryResult> recover(
      LocalityRecoveryRequest request) async {
    final response = await transport.invokeAsync(
      syscall: 'recover_locality',
      payload: request.toJson(),
    );
    final result = LocalityRecoveryResult.fromJson(response);
    final attributionLane = _resolvedKernelOutcomeAttributionLane;
    if (attributionLane != null) {
      await attributionLane.recordLocalityRecovery(
        agentId: request.agentId,
        request: request,
        result: result,
      );
    }
    return result;
  }

  @override
  WhySnapshot explainWhy(WhyKernelRequest request) {
    final response = transport.invokeSync(
      syscall: 'explain_why',
      payload: request.toJson(),
    );
    return WhySnapshot.fromJson(response);
  }

  @override
  Future<WhereRealityProjection> projectForRealityModel(
    LocalityProjectionRequest request,
  ) async {
    final response = await transport.invokeAsync(
      syscall: 'project_where_reality',
      payload: request.toJson(),
    );
    return WhereRealityProjection(
      summary: response['summary'] as String? ?? 'Spatial truth unavailable',
      confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
      features: Map<String, dynamic>.from(
        response['features'] as Map? ?? const <String, dynamic>{},
      ),
      payload: Map<String, dynamic>.from(
        response['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  Future<KernelGovernanceProjection> projectForGovernance(
    LocalityProjectionRequest request,
  ) async {
    final response = await transport.invokeAsync(
      syscall: 'project_where_governance',
      payload: request.toJson(),
    );
    return KernelGovernanceProjection(
      domain: KernelDomain.values.byName(
        response['domain'] as String? ?? KernelDomain.where.name,
      ),
      summary: response['summary'] as String? ?? 'Spatial governance view',
      confidence: (response['confidence'] as num?)?.toDouble() ?? 0.0,
      highlights: ((response['highlights'] as List?) ?? const <dynamic>[])
          .map((entry) => entry.toString())
          .toList(),
      payload: Map<String, dynamic>.from(
        response['payload'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  @override
  Future<KernelHealthReport> diagnoseWhere() async {
    final response = await transport.invokeAsync(
      syscall: 'diagnose_where_kernel',
      payload: const <String, dynamic>{},
    );
    return KernelHealthReport.fromJson(response);
  }
}
