import 'package:avrai_core/models/temporal/replay_ingestion_source_plan.dart';
import 'package:avrai_core/models/temporal/replay_year_completeness_score.dart';

class ReplayIngestionManifest {
  const ReplayIngestionManifest({
    required this.manifestId,
    required this.replayYear,
    required this.generatedAtUtc,
    required this.selectedScore,
    required this.sourcePlans,
    this.canonicalEntityTypes = const <String>[],
    this.notes = const <String>[],
    this.sourceStatusCounts = const <String, int>{},
  });

  final String manifestId;
  final int replayYear;
  final DateTime generatedAtUtc;
  final ReplayYearCompletenessScore selectedScore;
  final List<ReplayIngestionSourcePlan> sourcePlans;
  final List<String> canonicalEntityTypes;
  final List<String> notes;
  final Map<String, int> sourceStatusCounts;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'manifestId': manifestId,
      'replayYear': replayYear,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'selectedScore': selectedScore.toJson(),
      'sourcePlans': sourcePlans.map((plan) => plan.toJson()).toList(),
      'canonicalEntityTypes': canonicalEntityTypes,
      'notes': notes,
      'sourceStatusCounts': sourceStatusCounts,
    };
  }

  factory ReplayIngestionManifest.fromJson(Map<String, dynamic> json) {
    return ReplayIngestionManifest(
      manifestId: json['manifestId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      generatedAtUtc:
          DateTime.tryParse(json['generatedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      selectedScore: ReplayYearCompletenessScore.fromJson(
        Map<String, dynamic>.from(json['selectedScore'] as Map? ?? const {}),
      ),
      sourcePlans: (json['sourcePlans'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayIngestionSourcePlan.fromJson(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <ReplayIngestionSourcePlan>[],
      canonicalEntityTypes: (json['canonicalEntityTypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceStatusCounts: (json['sourceStatusCounts'] as Map?)
              ?.map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as num?)?.toInt() ?? 0,
                ),
              ) ??
          const <String, int>{},
    );
  }
}
