class WorldPlaneViewState {
  final bool isAvailable;
  final dynamic worldsheet;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final double confidence;
  final bool isStale;
  final String? fallbackReason;
  final DateTime generatedAt;

  const WorldPlaneViewState({
    required this.isAvailable,
    this.worldsheet,
    required this.rangeStart,
    required this.rangeEnd,
    required this.confidence,
    required this.isStale,
    required this.fallbackReason,
    required this.generatedAt,
  });

  factory WorldPlaneViewState.unavailable({
    required String reason,
    DateTime? generatedAt,
  }) {
    return WorldPlaneViewState(
      isAvailable: false,
      worldsheet: null,
      rangeStart: null,
      rangeEnd: null,
      confidence: 0.0,
      isStale: false,
      fallbackReason: reason,
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }
}
