class TemporalUncertainty {
  const TemporalUncertainty({
    required this.window,
    required this.confidence,
  });

  const TemporalUncertainty.zero()
      : window = Duration.zero,
        confidence = 1.0;

  final Duration window;
  final double confidence;

  Map<String, dynamic> toJson() {
    return {
      'windowMicros': window.inMicroseconds,
      'confidence': confidence,
    };
  }

  factory TemporalUncertainty.fromJson(Map<String, dynamic> json) {
    return TemporalUncertainty(
      window: Duration(
        microseconds: (json['windowMicros'] as num?)?.toInt() ?? 0,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
