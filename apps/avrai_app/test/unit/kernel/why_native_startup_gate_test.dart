import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_priority.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WhyNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeWhyBridge(available: false);

      WhyNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const WhyNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeWhyBridge(available: false);

      expect(
        () => WhyNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const WhyNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native why kernel is required at startup'),
          ),
        ),
      );
      expect(bridge.initialized, isTrue);
    });
  });
}

class _FakeWhyBridge implements WhyNativeInvocationBridge {
  _FakeWhyBridge({required this.available});

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
