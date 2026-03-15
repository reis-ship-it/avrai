import 'dart:io';

import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_training_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/synthetic_locality_training_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeTrainingBridge', () {
    test('uses the built locality dylib for bootstrap training contracts',
        () async {
      if (!_hasBuiltLocalityLibrary()) {
        return;
      }

      final bridge = LocalityNativeTrainingBridge(
        nativeBridge: LocalityNativeBridgeBindings(
          libraryManager: LocalityLibraryManager(),
        ),
        fallback: const SyntheticLocalityTrainingService(),
      );

      final artifact = await bridge.loadBaselineArtifact(
        cityProfile: 'birmingham_alabama',
        modelFamily: 'reality_kernel',
      );
      final batch = await bridge.buildBootstrapBatch(
        cityProfile: 'birmingham_alabama',
        localityCount: 12,
      );
      final report = await bridge.evaluateZeroLocality(
        artifact: artifact,
        batch: batch,
      );

      expect(artifact.version, '2.0.0');
      expect(artifact.calibration['statePersistencePath'], isNotNull);
      expect(
        batch.scenarios.map((scenario) => scenario.scenarioId),
        contains('birmingham_alabama-candidate-emergence'),
      );
      expect(report.metrics, isNotEmpty);
      expect(report.calibration['candidateRegistrySize'], isNotNull);
      expect(report.calibration['statePersistencePath'], isNotNull);
    });
  });
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
