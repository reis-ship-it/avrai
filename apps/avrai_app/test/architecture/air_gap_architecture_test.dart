import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Air Gap Architecture Tests', () {
    test('DeviceIntakeRouter should NEVER import Engine directly', () {
      final file = File(
          'runtime/avrai_runtime_os/lib/endpoints/intake/device_intake_router.dart');

      // If the file doesn't exist, the architecture test fails by default
      expect(file.existsSync(), isTrue,
          reason: 'DeviceIntakeRouter file missing');

      final content = file.readAsStringSync();

      // The router should only ever know about the Abstract `AirGapContract`
      // It must never import `TupleExtractionEngine` directly or the prong rules are broken
      expect(content.contains('import \'package:reality_engine/'), isFalse,
          reason:
              'CRITICAL ARCHITECTURE VIOLATION: The OS Runtime cannot directly import the Reality Engine. It must only use the shared AirGapContract.');
      expect(content.contains('TupleExtractionEngine'), isFalse,
          reason:
              'CRITICAL ARCHITECTURE VIOLATION: DeviceIntakeRouter is tightly coupled to the concrete TupleExtractionEngine.');
    });
  });
}
