import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhenNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeWhenBridge(available: false);

      WhenNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const WhenNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeWhenBridge(available: false);

      expect(
        () => WhenNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const WhenNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native when kernel is required at startup'),
          ),
        ),
      );
      expect(bridge.initialized, isTrue);
    });
  });
}

class _FakeWhenBridge implements WhenNativeInvocationBridge {
  _FakeWhenBridge({required this.available});

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
