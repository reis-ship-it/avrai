enum MeshNativeFallbackReason {
  unavailable,
  deferred,
}

class MeshNativeFallbackAudit {
  int nativeHandledCount = 0;
  int fallbackUnavailableCount = 0;
  int fallbackDeferredCount = 0;

  void recordNativeHandled() {
    nativeHandledCount += 1;
  }

  void recordFallback(MeshNativeFallbackReason reason) {
    switch (reason) {
      case MeshNativeFallbackReason.unavailable:
        fallbackUnavailableCount += 1;
      case MeshNativeFallbackReason.deferred:
        fallbackDeferredCount += 1;
    }
  }
}

class MeshNativeExecutionPolicy {
  static const bool _defaultRequireNative = bool.fromEnvironment(
    'AVRAI_REQUIRE_NATIVE_MESH',
    defaultValue: false,
  );

  final bool requireNative;

  const MeshNativeExecutionPolicy({
    bool? requireNative,
  }) : requireNative = requireNative ?? _defaultRequireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required MeshNativeFallbackReason reason,
  }) {
    if (!requireNative) {
      return;
    }
    throw StateError(
      'Native mesh kernel is required but syscall "$syscall" fell back '
      'because native was ${reason.name}.',
    );
  }
}
