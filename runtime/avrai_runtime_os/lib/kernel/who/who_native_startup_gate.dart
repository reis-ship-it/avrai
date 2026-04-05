import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_priority.dart';

class WhoNativeStartupGate {
  const WhoNativeStartupGate._();

  static void ensureReady({
    required WhoNativeInvocationBridge nativeBridge,
    required WhoNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native who kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the who dylib, or '
      'explicitly enable the Dart fallback only for development/test.',
    );
  }
}
