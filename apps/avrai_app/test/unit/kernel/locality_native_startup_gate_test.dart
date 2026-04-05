import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalityNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeNativeBridge(available: false);

      LocalityNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const LocalityNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeNativeBridge(available: false);

      expect(
        () => LocalityNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const LocalityNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native locality kernel is required at startup'),
          ),
        ),
      );
      expect(bridge.initialized, isTrue);
    });
  });
}

class _FakeNativeBridge implements LocalityNativeInvocationBridge {
  _FakeNativeBridge({
    required this.available,
  });

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
