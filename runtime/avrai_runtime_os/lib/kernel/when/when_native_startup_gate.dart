import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';

class WhenNativeStartupGate {
  const WhenNativeStartupGate._();

  static void ensureReady({
    required WhenNativeInvocationBridge nativeBridge,
    required WhenNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native when kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the when dylib, or '
      'explicitly enable the Dart fallback only for development/test.',
    );
  }
}
