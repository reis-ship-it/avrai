import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_priority.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_startup_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HowNativeStartupGate', () {
    test('does not throw when native is optional', () {
      final bridge = _FakeHowBridge(available: false);

      HowNativeStartupGate.ensureReady(
        nativeBridge: bridge,
        policy: const HowNativeExecutionPolicy(requireNative: false),
      );

      expect(bridge.initialized, isTrue);
    });

    test('throws when native is required and unavailable', () {
      final bridge = _FakeHowBridge(available: false);

      expect(
        () => HowNativeStartupGate.ensureReady(
          nativeBridge: bridge,
          policy: const HowNativeExecutionPolicy(requireNative: true),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Native how kernel is required at startup'),
          ),
        ),
      );
      expect(bridge.initialized, isTrue);
    });
  });
}

class _FakeHowBridge implements HowNativeInvocationBridge {
  _FakeHowBridge({required this.available});

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
