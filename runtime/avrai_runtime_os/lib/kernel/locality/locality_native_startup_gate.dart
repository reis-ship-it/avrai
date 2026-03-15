import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';

class LocalityNativeStartupGate {
  const LocalityNativeStartupGate._();

  static void ensureReady({
    required LocalityNativeInvocationBridge nativeBridge,
    required LocalityNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native locality kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the locality dylib, or '
      'explicitly enable the legacy Dart fallback only for development/test.',
    );
  }
}
