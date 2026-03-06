import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FfiPreferredLocalitySyscallTransport', () {
    test('uses native bridge when available', () async {
      final bridge = _FakeNativeBridge(
        available: true,
        response: <String, dynamic>{'path': 'native'},
      );
      final fallback = _FakeTransport(
        response: <String, dynamic>{'path': 'fallback'},
      );
      final transport = FfiPreferredLocalitySyscallTransport(
        nativeBridge: bridge,
        fallbackTransport: fallback,
      );

      final result = await transport.invokeAsync(
        syscall: 'resolve_where',
        payload: const <String, dynamic>{'agentId': 'agent-1'},
      );

      expect(result['path'], 'native');
      expect(bridge.invocations, 1);
      expect(fallback.invocations, 0);
    });

    test('falls back when native bridge is unavailable', () async {
      final bridge = _FakeNativeBridge(
        available: false,
        response: <String, dynamic>{'path': 'native'},
      );
      final fallback = _FakeTransport(
        response: <String, dynamic>{'path': 'fallback'},
      );
      final transport = FfiPreferredLocalitySyscallTransport(
        nativeBridge: bridge,
        fallbackTransport: fallback,
      );

      final result = transport.invokeSync(
        syscall: 'snapshot_locality',
        payload: const <String, dynamic>{'agentId': 'agent-1'},
      );

      expect(result['path'], 'fallback');
      expect(bridge.initialized, isTrue);
      expect(fallback.invocations, 1);
    });
  });
}

class _FakeNativeBridge implements LocalityNativeInvocationBridge {
  final bool available;
  final Map<String, dynamic> response;

  bool initialized = false;
  int invocations = 0;

  _FakeNativeBridge({
    required this.available,
    required this.response,
  });

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
    invocations += 1;
    return response;
  }
}

class _FakeTransport implements LocalitySyscallTransport {
  final Map<String, dynamic> response;

  int invocations = 0;

  _FakeTransport({
    required this.response,
  });

  @override
  Future<Map<String, dynamic>> invokeAsync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) async {
    invocations += 1;
    return response;
  }

  @override
  Map<String, dynamic> invokeSync({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    invocations += 1;
    return response;
  }
}
