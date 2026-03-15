class TemporalOrderingPolicy {
  const TemporalOrderingPolicy({
    required this.maxSequenceGap,
    this.maxBufferedAge = const Duration(minutes: 5),
  });

  final int maxSequenceGap;
  final Duration maxBufferedAge;

  Map<String, dynamic> toJson() {
    return {
      'maxSequenceGap': maxSequenceGap,
      'maxBufferedAgeMicros': maxBufferedAge.inMicroseconds,
    };
  }

  factory TemporalOrderingPolicy.fromJson(Map<String, dynamic> json) {
    return TemporalOrderingPolicy(
      maxSequenceGap: (json['maxSequenceGap'] as num?)?.toInt() ?? 0,
      maxBufferedAge: Duration(
        microseconds: (json['maxBufferedAgeMicros'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
