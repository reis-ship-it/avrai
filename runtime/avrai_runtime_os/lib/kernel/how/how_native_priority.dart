enum HowNativeFallbackReason {
  unavailable,
  deferred,
}

class HowNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(HowNativeFallbackReason reason) {
    switch (reason) {
      case HowNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case HowNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class HowNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_HOW',
    defaultValue: true,
  );

  final bool requireNative;

  const HowNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required HowNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native how kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
