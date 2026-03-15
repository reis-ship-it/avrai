import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_priority.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhoNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeWhoBridge(available: false);

      WhoNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const WhoNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeWhoBridge(available: false);

      expect(
        () => WhoNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const WhoNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native who kernel is required at startup'),
          ),
        ),
      );
      expect(bridge.initialized, isTrue);
    });
  });
}

class _FakeWhoBridge implements WhoNativeInvocationBridge {
  _FakeWhoBridge({required this.available});

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
