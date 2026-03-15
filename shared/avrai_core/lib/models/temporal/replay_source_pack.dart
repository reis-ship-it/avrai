import 'package:avrai_core/models/temporal/replay_source_dataset.dart';

class ReplaySourcePack {
  const ReplaySourcePack({
    required this.packId,
    required this.replayYear,
    required this.generatedAtUtc,
    this.datasets = const <ReplaySourceDataset>[],
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String packId;
  final int replayYear;
  final DateTime generatedAtUtc;
  final List<ReplaySourceDataset> datasets;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'packId': packId,
      'replayYear': replayYear,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'datasets': datasets.map((dataset) => dataset.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplaySourcePack.fromJson(Map<String, dynamic> json) {
    return ReplaySourcePack(
      packId: json['packId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      generatedAtUtc:
          DateTime.tryParse(json['generatedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      datasets: (json['datasets'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplaySourceDataset.fromJson(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <ReplaySourceDataset>[],
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
