class ReplayYearCompletenessScore {
  const ReplayYearCompletenessScore({
    required this.year,
    required this.eventCoverage,
    required this.venueCoverage,
    required this.communityCoverage,
    required this.recurrenceFidelity,
    required this.temporalCertainty,
    required this.trustQuality,
    required this.overallScore,
    this.notes = const <String>[],
    this.sourceRefs = const <String>[],
  });

  final int year;
  final double eventCoverage;
  final double venueCoverage;
  final double communityCoverage;
  final double recurrenceFidelity;
  final double temporalCertainty;
  final double trustQuality;
  final double overallScore;
  final List<String> notes;
  final List<String> sourceRefs;

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'eventCoverage': eventCoverage,
      'venueCoverage': venueCoverage,
      'communityCoverage': communityCoverage,
      'recurrenceFidelity': recurrenceFidelity,
      'temporalCertainty': temporalCertainty,
      'trustQuality': trustQuality,
      'overallScore': overallScore,
      'notes': notes,
      'sourceRefs': sourceRefs,
    };
  }

  factory ReplayYearCompletenessScore.fromJson(Map<String, dynamic> json) {
    return ReplayYearCompletenessScore(
      year: (json['year'] as num?)?.toInt() ?? 0,
      eventCoverage: (json['eventCoverage'] as num?)?.toDouble() ?? 0.0,
      venueCoverage: (json['venueCoverage'] as num?)?.toDouble() ?? 0.0,
      communityCoverage:
          (json['communityCoverage'] as num?)?.toDouble() ?? 0.0,
      recurrenceFidelity:
          (json['recurrenceFidelity'] as num?)?.toDouble() ?? 0.0,
      temporalCertainty:
          (json['temporalCertainty'] as num?)?.toDouble() ?? 0.0,
      trustQuality: (json['trustQuality'] as num?)?.toDouble() ?? 0.0,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0.0,
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceRefs: (json['sourceRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
    );
  }
}
