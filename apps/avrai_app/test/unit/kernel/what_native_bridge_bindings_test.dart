import 'dart:io';

import 'package:avrai_runtime_os/kernel/what/what_library_manager.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatNativeBridgeBindings', () {
    test('invokes the built what dylib when available', () {
      if (!_hasBuiltWhatLibrary()) {
        return;
      }

      final bridge = WhatNativeBridgeBindings(
        libraryManager: WhatLibraryManager(),
      );
      bridge.initialize();

      expect(bridge.isAvailable, isTrue);

      final response = bridge.invoke(
        syscall: 'resolve_what',
        payload: <String, dynamic>{
          'agentId': 'agent-1',
          'entityRef': 'spot:cafe',
          'observedAtUtc': DateTime.utc(2026, 3, 6).toIso8601String(),
          'candidateLabels': const <String>['coffee shop'],
        },
      );

      expect(response['handled'], isTrue);
      expect(
        (response['payload'] as Map<String, dynamic>)['canonical_type'],
        'cafe',
      );
    });
  });
}

bool _hasBuiltWhatLibrary() {
  final currentDir = Directory.current.path;
  final candidates = <String>[
    '$currentDir/runtime/avrai_network/native/what_kernel/macos/libavrai_what_kernel.dylib',
    '$currentDir/runtime/avrai_network/native/what_kernel/target/debug/libavrai_what_kernel.dylib',
    '$currentDir/runtime/avrai_network/native/what_kernel/target/release/libavrai_what_kernel.dylib',
  ];
  return candidates.any((path) => File(path).existsSync());
}
