class ReplayStoragePartitionEntry {
  const ReplayStoragePartitionEntry({
    required this.artifactRef,
    required this.section,
    required this.chunkIndex,
    required this.recordCount,
    required this.objectPath,
    required this.byteSize,
  });

  final String artifactRef;
  final String section;
  final int chunkIndex;
  final int recordCount;
  final String objectPath;
  final int byteSize;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'artifactRef': artifactRef,
      'section': section,
      'chunkIndex': chunkIndex,
      'recordCount': recordCount,
      'objectPath': objectPath,
      'byteSize': byteSize,
    };
  }

  factory ReplayStoragePartitionEntry.fromJson(Map<String, dynamic> json) {
    return ReplayStoragePartitionEntry(
      artifactRef: json['artifactRef'] as String? ?? '',
      section: json['section'] as String? ?? '',
      chunkIndex: (json['chunkIndex'] as num?)?.toInt() ?? 0,
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
      objectPath: json['objectPath'] as String? ?? '',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReplayStoragePartitionManifest {
  const ReplayStoragePartitionManifest({
    required this.environmentId,
    required this.replayYear,
    required this.partitionRoot,
    required this.maxRecordsPerChunk,
    required this.entries,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final String partitionRoot;
  final int maxRecordsPerChunk;
  final List<ReplayStoragePartitionEntry> entries;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  int get totalBytes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.byteSize);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'partitionRoot': partitionRoot,
      'maxRecordsPerChunk': maxRecordsPerChunk,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayStoragePartitionManifest.fromJson(Map<String, dynamic> json) {
    return ReplayStoragePartitionManifest(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      partitionRoot: json['partitionRoot'] as String? ?? '',
      maxRecordsPerChunk:
          (json['maxRecordsPerChunk'] as num?)?.toInt() ?? 0,
      entries: (json['entries'] as List?)
              ?.map(
                (entry) => ReplayStoragePartitionEntry.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const <ReplayStoragePartitionEntry>[],
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
