class ForecastNativeExecutionPolicy {
  const ForecastNativeExecutionPolicy({
    this.requireNative = true,
  });

  final bool requireNative;

  void verifyFallbackAllowed({
    required String syscall,
    required String reason,
  }) {
    if (requireNative) {
      throw StateError(
        'Native forecast kernel is required but syscall "$syscall" fell back '
        'because of $reason.',
      );
    }
  }
}
