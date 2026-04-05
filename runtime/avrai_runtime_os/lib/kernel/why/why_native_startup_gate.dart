import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_priority.dart';

class WhyNativeStartupGate {
  const WhyNativeStartupGate._();

  static void ensureReady({
    required WhyNativeInvocationBridge nativeBridge,
    required WhyNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native why kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the why dylib, or '
      'explicitly enable the Dart fallback only for development/test.',
    );
  }
}
