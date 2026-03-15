enum WhatNativeFallbackReason {
  unavailable,
  deferred,
}

class WhatNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(WhatNativeFallbackReason reason) {
    switch (reason) {
      case WhatNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case WhatNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class WhatNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_WHAT',
    defaultValue: true,
  );

  final bool requireNative;

  const WhatNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required WhatNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native what kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
