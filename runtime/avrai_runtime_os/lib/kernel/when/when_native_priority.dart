enum WhenNativeFallbackReason {
  unavailable,
  deferred,
}

class WhenNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(WhenNativeFallbackReason reason) {
    switch (reason) {
      case WhenNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case WhenNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class WhenNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_WHEN',
    defaultValue: true,
  );

  final bool requireNative;

  const WhenNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required WhenNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native when kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
