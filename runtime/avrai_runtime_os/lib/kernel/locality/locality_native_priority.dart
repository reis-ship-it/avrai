enum LocalityNativeFallbackReason {
  unavailable,
  deferred,
}

class LocalityNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  int get totalFallbackCount =>
      fallbackUnavailableCount + fallbackDeferredCount;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(LocalityNativeFallbackReason reason) {
    switch (reason) {
      case LocalityNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case LocalityNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class LocalityNativeExecutionPolicy {
  static const bool _defaultRequireNative =
      bool.fromEnvironment('AVRAI_REQUIRE_NATIVE_LOCALITY');

  final bool requireNative;

  const LocalityNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required LocalityNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native locality is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
