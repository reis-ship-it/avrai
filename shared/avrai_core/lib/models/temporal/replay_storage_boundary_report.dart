class ReplayStorageBoundaryReport {
  const ReplayStorageBoundaryReport({
    required this.environmentId,
    required this.replayYear,
    required this.passed,
    required this.projectIsolationMode,
    required this.replaySchema,
    required this.replayBuckets,
    required this.replayMetadataTables,
    required this.appBuckets,
    required this.appSchemas,
    required this.violations,
    required this.policySnapshot,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final bool passed;
  final String projectIsolationMode;
  final String replaySchema;
  final List<String> replayBuckets;
  final List<String> replayMetadataTables;
  final List<String> appBuckets;
  final List<String> appSchemas;
  final List<String> violations;
  final Map<String, String> policySnapshot;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'passed': passed,
      'projectIsolationMode': projectIsolationMode,
      'replaySchema': replaySchema,
      'replayBuckets': replayBuckets,
      'replayMetadataTables': replayMetadataTables,
      'appBuckets': appBuckets,
      'appSchemas': appSchemas,
      'violations': violations,
      'policySnapshot': policySnapshot,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayStorageBoundaryReport.fromJson(Map<String, dynamic> json) {
    return ReplayStorageBoundaryReport(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      projectIsolationMode:
          json['projectIsolationMode'] as String? ?? 'unknown',
      replaySchema: json['replaySchema'] as String? ?? '',
      replayBuckets: (json['replayBuckets'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      replayMetadataTables: (json['replayMetadataTables'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      appBuckets: (json['appBuckets'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      appSchemas: (json['appSchemas'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      violations: (json['violations'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      policySnapshot: (json['policySnapshot'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          const <String, String>{},
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
