import 'dart:io';

import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_state.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeKernelStub FFI smoke', () {
    test('serves seed snapshot and point resolution natively when dylib exists',
        () async {
      if (!_hasBuiltLocalityLibrary()) {
        return;
      }

      final audit = LocalityNativeFallbackAudit();
      final stub = LocalityNativeKernelStub(
        transport: FfiPreferredLocalitySyscallTransport(
          nativeBridge: LocalityNativeBridgeBindings(
            libraryManager: LocalityLibraryManager(),
          ),
          fallbackTransport: InProcessLocalitySyscallTransport(
            delegate: _UnusedLocalityFallbackSurface(),
          ),
          policy: const LocalityNativeExecutionPolicy(requireNative: true),
          audit: audit,
        ),
      );

      final seededState = await stub.seedHomebase(
        userId: 'ffi-user-1',
        agentId: 'ffi-agent-1',
        latitude: 33.5247,
        longitude: -86.7740,
        cityCode: 'birmingham_alabama',
      );
      final snapshot = stub.snapshot('ffi-agent-1');
      final pointResolution = await stub.resolvePoint(
        LocalityPointQuery(
          latitude: 33.5247,
          longitude: -86.7740,
          occurredAtUtc: DateTime.utc(2026, 3, 6, 12),
          audience: LocalityProjectionAudience.admin,
          includePrediction: true,
        ),
      );
      final reality = await stub.projectForRealityModel(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: seededState,
          includePrediction: true,
        ),
      );
      final governance = await stub.projectForGovernance(
        LocalityProjectionRequest(
          audience: LocalityProjectionAudience.admin,
          state: seededState,
          includePrediction: true,
        ),
      );
      final health = await stub.diagnoseWhere();

      expect(seededState.activeToken.id, isNotEmpty);
      expect(snapshot, isNotNull);
      expect(snapshot!.state.activeToken.id, seededState.activeToken.id);
      expect(pointResolution.projection.primaryLabel, isNotEmpty);
      expect(reality.summary, isNotEmpty);
      expect(governance.highlights, isNotEmpty);
      expect(health.nativeBacked, isTrue);
      expect(audit.nativeHandledCount, greaterThanOrEqualTo(3));
      expect(audit.fallbackUnavailableCount, 0);
      expect(audit.fallbackDeferredCount, 0);
    });
  });
}

class _UnusedLocalityFallbackSurface implements LocalityKernelFallbackSurface {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
        'Native locality smoke test should not fall back.');
  }
}

bool _hasBuiltLocalityLibrary() {
  if (Platform.isMacOS) {
    return File(
      '${Directory.current.path}/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.dylib',
    ).existsSync();
  }
  if (Platform.isLinux) {
    return File(
      '${Directory.current.path}/runtime/avrai_network/native/locality_kernel/target/debug/libavrai_locality_kernel.so',
    ).existsSync();
  }
  return false;
}
