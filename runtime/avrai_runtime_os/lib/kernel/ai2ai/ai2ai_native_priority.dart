enum Ai2AiNativeFallbackReason {
  unavailable,
  deferred,
}

class Ai2AiNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(Ai2AiNativeFallbackReason reason) {
    switch (reason) {
      case Ai2AiNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case Ai2AiNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class Ai2AiNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_AI2AI',
    defaultValue: false,
  );

  final bool requireNative;

  const Ai2AiNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required Ai2AiNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native AI2AI kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
