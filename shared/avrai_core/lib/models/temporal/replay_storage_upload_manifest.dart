class ReplayStorageUploadEntry {
  const ReplayStorageUploadEntry({
    required this.artifactRef,
    required this.bucket,
    required this.objectPath,
    required this.localPath,
    required this.representation,
    required this.byteSize,
    this.section,
    this.chunkIndex,
    this.recordCount,
  });

  final String artifactRef;
  final String bucket;
  final String objectPath;
  final String localPath;
  final String representation;
  final int byteSize;
  final String? section;
  final int? chunkIndex;
  final int? recordCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artifactRef': artifactRef,
      'bucket': bucket,
      'objectPath': objectPath,
      'localPath': localPath,
      'representation': representation,
      'byteSize': byteSize,
      'section': section,
      'chunkIndex': chunkIndex,
      'recordCount': recordCount,
    };
  }

  factory ReplayStorageUploadEntry.fromJson(Map<String, dynamic> json) {
    return ReplayStorageUploadEntry(
      artifactRef: json['artifactRef'] as String? ?? '',
      bucket: json['bucket'] as String? ?? '',
      objectPath: json['objectPath'] as String? ?? '',
      localPath: json['localPath'] as String? ?? '',
      representation: json['representation'] as String? ?? 'single_object',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      section: json['section'] as String?,
      chunkIndex: (json['chunkIndex'] as num?)?.toInt(),
      recordCount: (json['recordCount'] as num?)?.toInt(),
    );
  }
}

class ReplayStorageUploadManifest {
  const ReplayStorageUploadManifest({
    required this.environmentId,
    required this.replayYear,
    required this.status,
    required this.dryRun,
    required this.projectIsolationMode,
    required this.replaySchema,
    required this.entries,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final String status;
  final bool dryRun;
  final String projectIsolationMode;
  final String replaySchema;
  final List<ReplayStorageUploadEntry> entries;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  int get totalBytes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.byteSize);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'status': status,
      'dryRun': dryRun,
      'projectIsolationMode': projectIsolationMode,
      'replaySchema': replaySchema,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayStorageUploadManifest.fromJson(Map<String, dynamic> json) {
    return ReplayStorageUploadManifest(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      dryRun: json['dryRun'] as bool? ?? true,
      projectIsolationMode: json['projectIsolationMode'] as String? ?? 'unknown',
      replaySchema: json['replaySchema'] as String? ?? '',
      entries: (json['entries'] as List?)
              ?.map(
                (entry) => ReplayStorageUploadEntry.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const <ReplayStorageUploadEntry>[],
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
