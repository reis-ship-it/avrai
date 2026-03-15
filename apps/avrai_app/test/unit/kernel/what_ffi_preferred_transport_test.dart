import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FfiPreferredWhatSyscallTransport', () {
    test('uses native bridge when available', () async {
      final bridge = _FakeWhatBridge(
        available: true,
        response: <String, dynamic>{
          'ok': true,
          'handled': true,
          'payload': <String, dynamic>{'path': 'native'},
        },
      );
      final fallback = _FakeTransport(
        response: <String, dynamic>{'path': 'fallback'},
      );
      final audit = WhatNativeFallbackAudit();
      final transport = FfiPreferredWhatSyscallTransport(
        nativeBridge: bridge,
        fallbackTransport: fallback,
        audit: audit,
      );

      final result = await transport.invokeAsync(
        syscall: 'resolve_what',
        payload: const <String, dynamic>{'agentId': 'agent-1'},
      );

      expect(result['path'], 'native');
      expect(bridge.invocations, 1);
      expect(fallback.invocations, 0);
      expect(audit.nativeHandledCount, 1);
    });

    test('falls back when native bridge is unavailable', () {
      final bridge = _FakeWhatBridge(
        available: false,
        response: const <String, dynamic>{},
      );
      final fallback = _FakeTransport(
        response: <String, dynamic>{'path': 'fallback'},
      );
      final audit = WhatNativeFallbackAudit();
      final transport = FfiPreferredWhatSyscallTransport(
        nativeBridge: bridge,
        fallbackTransport: fallback,
        audit: audit,
        policy: const WhatNativeExecutionPolicy(requireNative: false),
      );

      final result = transport.invokeSync(
        syscall: 'snapshot_what',
        payload: const <String, dynamic>{'agentId': 'agent-1'},
      );

      expect(result['path'], 'fallback');
      expect(audit.fallbackUnavailableCount, 1);
    });
  });
}

class _FakeWhatBridge implements WhatNativeInvocationBridge {
  _FakeWhatBridge({
    required this.available,
    required this.response,
  });

  final bool available;
  final Map<String, dynamic> response;
  int invocations = 0;

  @override
  bool get isAvailable => available;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    invocations += 1;
    return response;
  }
}

class _FakeTransport implements WhatSyscallTransport {
  _FakeTransport({required this.response});

  final Map<String, dynamic> response;
  int invocations = 0;

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
