enum WhyNativeFallbackReason {
  unavailable,
  deferred,
}

class WhyNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(WhyNativeFallbackReason reason) {
    switch (reason) {
      case WhyNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case WhyNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class WhyNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_WHY',
    defaultValue: true,
  );

  final bool requireNative;

  const WhyNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required WhyNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native why kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
