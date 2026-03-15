class ReplayKernelParticipationRecord {
  const ReplayKernelParticipationRecord({
    required this.kernelId,
    required this.authoritySurface,
    required this.status,
    required this.evidenceCount,
    required this.evidenceRefs,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String kernelId;
  final String authoritySurface;
  final String status;
  final int evidenceCount;
  final List<String> evidenceRefs;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'kernelId': kernelId,
      'authoritySurface': authoritySurface,
      'status': status,
      'evidenceCount': evidenceCount,
      'evidenceRefs': evidenceRefs,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayKernelParticipationRecord.fromJson(Map<String, dynamic> json) {
    return ReplayKernelParticipationRecord(
      kernelId: json['kernelId'] as String? ?? '',
      authoritySurface: json['authoritySurface'] as String? ?? '',
      status: json['status'] as String? ?? 'inactive',
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      evidenceRefs: (json['evidenceRefs'] as List?)
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

class ReplayKernelParticipationReport {
  const ReplayKernelParticipationReport({
    required this.environmentId,
    required this.requiredKernelCount,
    required this.activeKernelCount,
    required this.records,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int requiredKernelCount;
  final int activeKernelCount;
  final List<ReplayKernelParticipationRecord> records;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'requiredKernelCount': requiredKernelCount,
      'activeKernelCount': activeKernelCount,
      'records': records.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayKernelParticipationReport.fromJson(Map<String, dynamic> json) {
    return ReplayKernelParticipationReport(
      environmentId: json['environmentId'] as String? ?? '',
      requiredKernelCount:
          (json['requiredKernelCount'] as num?)?.toInt() ?? 0,
      activeKernelCount: (json['activeKernelCount'] as num?)?.toInt() ?? 0,
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayKernelParticipationRecord.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayKernelParticipationRecord>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
