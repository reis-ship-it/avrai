import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_priority.dart';

class HowNativeStartupGate {
  const HowNativeStartupGate._();

  static void ensureReady({
    required HowNativeInvocationBridge nativeBridge,
    required HowNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native how kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the how dylib, or '
      'explicitly enable the Dart fallback only for development/test.',
    );
  }
}
