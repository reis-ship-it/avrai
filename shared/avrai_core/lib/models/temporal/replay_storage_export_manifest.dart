class ReplayStorageExportEntry {
  const ReplayStorageExportEntry({
    required this.artifactRef,
    required this.sourcePath,
    required this.bucket,
    required this.objectPath,
    required this.byteSize,
  });

  final String artifactRef;
  final String sourcePath;
  final String bucket;
  final String objectPath;
  final int byteSize;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artifactRef': artifactRef,
      'sourcePath': sourcePath,
      'bucket': bucket,
      'objectPath': objectPath,
      'byteSize': byteSize,
    };
  }

  factory ReplayStorageExportEntry.fromJson(Map<String, dynamic> json) {
    return ReplayStorageExportEntry(
      artifactRef: json['artifactRef'] as String? ?? '',
      sourcePath: json['sourcePath'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      objectPath: json['objectPath'] as String? ?? '',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReplayStorageExportManifest {
  const ReplayStorageExportManifest({
    required this.environmentId,
    required this.replayYear,
    required this.status,
    required this.exportRoot,
    required this.projectIsolationMode,
    required this.replaySchema,
    required this.entries,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final String status;
  final String exportRoot;
  final String projectIsolationMode;
  final String replaySchema;
  final List<ReplayStorageExportEntry> entries;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  int get totalBytes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.byteSize);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'status': status,
      'exportRoot': exportRoot,
      'projectIsolationMode': projectIsolationMode,
      'replaySchema': replaySchema,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayStorageExportManifest.fromJson(Map<String, dynamic> json) {
    return ReplayStorageExportManifest(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      exportRoot: json['exportRoot'] as String? ?? '',
      projectIsolationMode: json['projectIsolationMode'] as String? ?? 'unknown',
      replaySchema: json['replaySchema'] as String? ?? '',
      entries: (json['entries'] as List?)
              ?.map(
                (entry) => ReplayStorageExportEntry.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const <ReplayStorageExportEntry>[],
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
