enum WhoNativeFallbackReason {
  unavailable,
  deferred,
}

class WhoNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(WhoNativeFallbackReason reason) {
    switch (reason) {
      case WhoNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case WhoNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class WhoNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_WHO',
    defaultValue: true,
  );

  final bool requireNative;

  const WhoNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required WhoNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native who kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
