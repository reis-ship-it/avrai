import 'dart:io';

import 'package:avrai_runtime_os/kernel/locality/locality_native_admin_diagnostics_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeAdminDiagnosticsBridge', () {
    test('uses the built locality dylib for admin diagnostics aggregation',
        () async {
      if (!_hasBuiltLocalityLibrary()) {
        return;
      }

      final bridge = LocalityNativeAdminDiagnosticsBridge(
        nativeBridge: LocalityNativeBridgeBindings(
          libraryManager: LocalityLibraryManager(),
        ),
        fallbackKernel: _UnusedLocalityKernelContract(),
        audit: LocalityNativeFallbackAudit(),
      );

      final report = await bridge.diagnose(
        probes: <LocalityAdminDiagnosticsProbe>[
          LocalityAdminDiagnosticsProbe(
            latitude: 33.5247,
            longitude: -86.7740,
            occurredAtUtc: DateTime.utc(2026, 3, 6, 12),
          ),
          LocalityAdminDiagnosticsProbe(
            latitude: 33.5016,
            longitude: -86.7972,
            occurredAtUtc: DateTime.utc(2026, 3, 6, 12, 5),
          ),
        ],
        cityProfile: 'birmingham_alabama',
      );

      expect(report.resolutions.length, 2);
      expect(report.resolutionCount, 2);
      expect(report.topLocalities, isNotEmpty);
      expect(report.cityProfile, 'birmingham_alabama');
      expect(report.executionPath, 'native');
      expect(report.nativeAvailable, isTrue);
      expect(report.nativeRequired, isFalse);
      expect(report.nativeHandledCount, 1);
      expect(report.fallbackUnavailableCount, 0);
      expect(report.fallbackDeferredCount, 0);
      expect(report.stateStore['schemaVersion'], 2);
      expect(report.stateStore['persistencePath'], isNotNull);
      expect(report.zeroLocalityReport.metrics, isNotEmpty);
      expect(report.predictiveBreakdown, isNotEmpty);
      expect(report.stabilityBreakdown, isNotEmpty);
      expect(report.sampleResolution, isNotNull);
    });
  });
}

class _UnusedLocalityKernelContract implements LocalityKernelFallbackSurface {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
