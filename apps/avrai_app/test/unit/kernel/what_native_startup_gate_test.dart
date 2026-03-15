import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhatNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeWhatBridge(available: false);

      WhatNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const WhatNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeWhatBridge(available: false);

      expect(
        () => WhatNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const WhatNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native what kernel is required at startup'),
          ),
        ),
      );
    });
  });
}

class _FakeWhatBridge implements WhatNativeInvocationBridge {
  _FakeWhatBridge({required this.available});

  final bool available;
  bool initialized = false;

  @override
  bool get isAvailable => available;

  @override
  void initialize() {
    initialized = true;
  }

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError();
  }
}
