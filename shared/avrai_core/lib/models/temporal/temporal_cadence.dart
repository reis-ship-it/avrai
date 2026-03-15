class TemporalCadence {
  const TemporalCadence({
    required this.period,
    this.tolerance = Duration.zero,
    this.recurrenceCount = 0,
  });

  final Duration period;
  final Duration tolerance;
  final int recurrenceCount;

  Map<String, dynamic> toJson() {
    return {
      'periodMicros': period.inMicroseconds,
      'toleranceMicros': tolerance.inMicroseconds,
      'recurrenceCount': recurrenceCount,
    };
  }

  factory TemporalCadence.fromJson(Map<String, dynamic> json) {
    return TemporalCadence(
      period: Duration(
        microseconds: (json['periodMicros'] as num?)?.toInt() ?? 0,
      ),
      tolerance: Duration(
        microseconds: (json['toleranceMicros'] as num?)?.toInt() ?? 0,
      ),
      recurrenceCount: (json['recurrenceCount'] as num?)?.toInt() ?? 0,
    );
  }
}
