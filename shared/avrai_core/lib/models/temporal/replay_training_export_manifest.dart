class ReplayTrainingExportManifest {
  const ReplayTrainingExportManifest({
    required this.environmentId,
    required this.replayYear,
    required this.status,
    required this.artifactRefs,
    required this.metrics,
    this.trainingTables = const <String>[],
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final String status;
  final List<String> artifactRefs;
  final Map<String, dynamic> metrics;
  final List<String> trainingTables;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'status': status,
      'artifactRefs': artifactRefs,
      'metrics': metrics,
      'trainingTables': trainingTables,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayTrainingExportManifest.fromJson(Map<String, dynamic> json) {
    return ReplayTrainingExportManifest(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      artifactRefs: (json['artifactRefs'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metrics: Map<String, dynamic>.from(
        json['metrics'] as Map? ?? const <String, dynamic>{},
      ),
      trainingTables: (json['trainingTables'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      notes: (json['notes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
