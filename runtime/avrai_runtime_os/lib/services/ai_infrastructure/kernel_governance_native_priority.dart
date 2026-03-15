enum KernelGovernanceNativeFallbackReason {
  unavailable,
  deferred,
}

class KernelGovernanceNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(KernelGovernanceNativeFallbackReason reason) {
    switch (reason) {
      case KernelGovernanceNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case KernelGovernanceNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class KernelGovernanceNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_GOVERNANCE',
    defaultValue: true,
  );

  final bool requireNative;

  const KernelGovernanceNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required KernelGovernanceNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native governance kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
