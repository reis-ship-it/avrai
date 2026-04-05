class TemporalFreshnessPolicy {
  const TemporalFreshnessPolicy({
    required this.maxAge,
    this.maxFutureSkew = Duration.zero,
  });

  final Duration maxAge;
  final Duration maxFutureSkew;

  Map<String, dynamic> toJson() {
    return {
      'maxAgeMicros': maxAge.inMicroseconds,
      'maxFutureSkewMicros': maxFutureSkew.inMicroseconds,
    };
  }

  factory TemporalFreshnessPolicy.fromJson(Map<String, dynamic> json) {
    return TemporalFreshnessPolicy(
      maxAge: Duration(
        microseconds: (json['maxAgeMicros'] as num?)?.toInt() ?? 0,
      ),
      maxFutureSkew: Duration(
        microseconds: (json['maxFutureSkewMicros'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
