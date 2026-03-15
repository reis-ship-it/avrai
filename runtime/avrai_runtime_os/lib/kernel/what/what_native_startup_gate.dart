import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';

class WhatNativeStartupGate {
  const WhatNativeStartupGate._();

  static void ensureReady({
    required WhatNativeInvocationBridge nativeBridge,
    required WhatNativeExecutionPolicy policy,
  }) {
    nativeBridge.initialize();
    if (!policy.requireNative) {
      return;
    }
    if (nativeBridge.isAvailable) {
      return;
    }
    throw StateError(
      'Native what kernel is required at startup but the native bridge '
      'could not be initialized. Build or ship the what dylib, or '
      'explicitly enable the Dart fallback only for development/test.',
    );
  }
}
