enum ReplaySourceAcquisitionMode {
  automated,
  apiKeyRequired,
  manualImport,
  partnerReview,
}

class ReplaySourcePullPlan {
  const ReplaySourcePullPlan({
    required this.sourceName,
    required this.replayYear,
    required this.acquisitionMode,
    required this.rawOutputKey,
    this.sourceUrl,
    this.endpointRef,
    this.requiresReview = false,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String sourceName;
  final int replayYear;
  final ReplaySourceAcquisitionMode acquisitionMode;
  final String rawOutputKey;
  final String? sourceUrl;
  final String? endpointRef;
  final bool requiresReview;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceName': sourceName,
      'replayYear': replayYear,
      'acquisitionMode': acquisitionMode.name,
      'rawOutputKey': rawOutputKey,
      'sourceUrl': sourceUrl,
      'endpointRef': endpointRef,
      'requiresReview': requiresReview,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplaySourcePullPlan.fromJson(Map<String, dynamic> json) {
    return ReplaySourcePullPlan(
      sourceName: json['sourceName'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      acquisitionMode: ReplaySourceAcquisitionMode.values.firstWhere(
        (value) => value.name == json['acquisitionMode'],
        orElse: () => ReplaySourceAcquisitionMode.manualImport,
      ),
      rawOutputKey: json['rawOutputKey'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
      endpointRef: json['endpointRef'] as String?,
      requiresReview: json['requiresReview'] as bool? ?? false,
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
