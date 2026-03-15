import 'package:avrai_runtime_os/kernel/what/what_models.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart'
    show
        KernelDomain,
        KernelGovernanceProjection,
        KernelHealthReport,
        WhatRealityProjection;
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';

abstract class WhatSyscallTransport {
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  });

  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  });
}

class InProcessWhatSyscallTransport implements WhatSyscallTransport {
  final WhatKernelFallbackSurface delegate;

  const InProcessWhatSyscallTransport({
    required this.delegate,
  });

  @override
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) async {
    switch (syscall) {
      case 'resolve_what':
        return (await delegate.resolveWhat(
          WhatPerceptionInput.fromJson(payload),
        ))
            .toJson();
      case 'observe_what':
        return (await delegate.observeWhat(
          WhatObservation.fromJson(payload),
        ))
            .toJson();
      case 'sync_what':
        final result = await delegate.syncWhat(
          WhatSyncRequest.fromJson(payload),
        );
        return {
          'acceptedCount': result.acceptedCount,
          'rejectedCount': result.rejectedCount,
          'mergedEntityRefs': result.mergedEntityRefs,
          'savedAtUtc': result.savedAtUtc.toIso8601String(),
        };
      case 'recover_what':
        final result = await delegate.recoverWhat(
          WhatRecoveryRequest.fromJson(payload),
        );
        return {
          'restoredCount': result.restoredCount,
          'droppedCount': result.droppedCount,
          'schemaVersion': result.schemaVersion,
          'savedAtUtc': result.savedAtUtc.toIso8601String(),
        };
      case 'project_what_reality':
        return (await delegate.projectForRealityModel(
          WhatProjectionRequest.fromJson(payload),
        ))
            .toJson();
      case 'project_what_governance':
        return (await delegate.projectForGovernance(
          WhatProjectionRequest.fromJson(payload),
        ))
            .toJson();
      case 'diagnose_what_kernel':
        return (await delegate.diagnoseWhat()).toJson();
      default:
        throw UnsupportedError('Unknown async what syscall: $syscall');
    }
  }

  @override
  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    switch (syscall) {
      case 'project_what':
        return delegate
            .projectWhat(
              WhatProjectionRequest.fromJson(payload),
            )
            .toJson();
      case 'snapshot_what':
        final snapshot =
            delegate.snapshotWhat((payload['agentId'] as String?) ?? '');
        return {
          if (snapshot != null) 'snapshot': snapshot.toJson(),
        };
      default:
        throw UnsupportedError('Unknown sync what syscall: $syscall');
    }
  }
}

class FfiPreferredWhatSyscallTransport implements WhatSyscallTransport {
  final WhatNativeInvocationBridge nativeBridge;
  final WhatSyscallTransport fallbackTransport;
  final WhatNativeExecutionPolicy policy;
  final WhatNativeFallbackAudit? audit;

  const FfiPreferredWhatSyscallTransport({
    required this.nativeBridge,
    required this.fallbackTransport,
    this.policy = const WhatNativeExecutionPolicy(),
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
        final nativePayload = response['payload'];
        if (nativePayload is Map<String, dynamic>) {
          return nativePayload;
        }
      }
      audit?.recordFallback(WhatNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhatNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(WhatNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhatNativeFallbackReason.unavailable,
      );
    }
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
        final nativePayload = response['payload'];
        if (nativePayload is Map<String, dynamic>) {
          return nativePayload;
        }
      }
      audit?.recordFallback(WhatNativeFallbackReason.deferred);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhatNativeFallbackReason.deferred,
      );
    } else {
      audit?.recordFallback(WhatNativeFallbackReason.unavailable);
      policy.verifyFallbackAllowed(
        syscall: syscall,
        reason: WhatNativeFallbackReason.unavailable,
      );
    }
    return fallbackTransport.invokeSync(syscall: syscall, payload: payload);
  }
}

class WhatNativeKernelStub extends WhatKernelContract {
  final WhatSyscallTransport transport;

  const WhatNativeKernelStub({
    required this.transport,
  });

  @override
  Future<WhatState> resolveWhat(WhatPerceptionInput input) async {
    final response = await transport.invokeAsync(
      syscall: 'resolve_what',
      payload: input.toJson(),
    );
    return WhatState.fromJson(response);
  }

  @override
  Future<WhatUpdateReceipt> observeWhat(WhatObservation observation) async {
    final response = await transport.invokeAsync(
      syscall: 'observe_what',
      payload: observation.toJson(),
    );
    return WhatUpdateReceipt.fromJson(response);
  }

  @override
  WhatProjection projectWhat(WhatProjectionRequest request) {
    final response = transport.invokeSync(
      syscall: 'project_what',
      payload: request.toJson(),
    );
    return WhatProjection.fromJson(response);
  }

  @override
  WhatKernelSnapshot? snapshotWhat(String agentId) {
    final response = transport.invokeSync(
      syscall: 'snapshot_what',
      payload: {'agentId': agentId},
    );
    final snapshot = response['snapshot'];
    if (snapshot is Map<String, dynamic>) {
      return WhatKernelSnapshot.fromJson(snapshot);
    }
    return null;
  }

  @override
  Future<WhatSyncResult> syncWhat(WhatSyncRequest request) async {
    final response = await transport.invokeAsync(
      syscall: 'sync_what',
      payload: request.toJson(),
    );
    return WhatSyncResult.fromJson(response);
  }

  @override
  Future<WhatRecoveryResult> recoverWhat(WhatRecoveryRequest request) async {
    final response = await transport.invokeAsync(
      syscall: 'recover_what',
      payload: request.toJson(),
    );
    return WhatRecoveryResult.fromJson(response);
  }

  @override
  Future<WhatRealityProjection> projectForRealityModel(
    WhatProjectionRequest request,
  ) async {
    final response = await transport.invokeAsync(
      syscall: 'project_what_reality',
      payload: request.toJson(),
    );
    return WhatRealityProjection(
      summary: response['summary'] as String? ?? 'Semantic state unavailable',
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
    WhatProjectionRequest request,
  ) async {
    final response = await transport.invokeAsync(
      syscall: 'project_what_governance',
      payload: request.toJson(),
    );
    return KernelGovernanceProjection(
      domain: KernelDomain.values.byName(
        response['domain'] as String? ?? KernelDomain.what.name,
      ),
      summary: response['summary'] as String? ?? 'Governance semantic view',
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
  Future<KernelHealthReport> diagnoseWhat() async {
    final response = await transport.invokeAsync(
      syscall: 'diagnose_what_kernel',
      payload: const <String, dynamic>{},
    );
    return KernelHealthReport.fromJson(response);
  }
}
