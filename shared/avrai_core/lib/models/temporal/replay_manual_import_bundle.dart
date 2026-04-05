class ReplayManualImportEntry {
  const ReplayManualImportEntry({
    required this.sourceName,
    required this.rawOutputKey,
    required this.requiredFields,
    required this.dedupeKeys,
    required this.normalizationTargets,
    this.requiresReview = false,
    this.templateRecord = const <String, dynamic>{},
    this.records = const <Map<String, dynamic>>[],
    this.notes = const <String>[],
    this.status = ReplayManualImportEntryStatus.template,
  });

  final String sourceName;
  final String rawOutputKey;
  final List<String> requiredFields;
  final List<String> dedupeKeys;
  final List<String> normalizationTargets;
  final bool requiresReview;
  final Map<String, dynamic> templateRecord;
  final List<Map<String, dynamic>> records;
  final List<String> notes;
  final ReplayManualImportEntryStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceName': sourceName,
      'rawOutputKey': rawOutputKey,
      'requiredFields': requiredFields,
      'dedupeKeys': dedupeKeys,
      'normalizationTargets': normalizationTargets,
      'requiresReview': requiresReview,
      'templateRecord': templateRecord,
      'records': records,
      'notes': notes,
      'status': status.name,
    };
  }

  factory ReplayManualImportEntry.fromJson(Map<String, dynamic> json) {
    return ReplayManualImportEntry(
      sourceName: json['sourceName'] as String? ?? '',
      rawOutputKey: json['rawOutputKey'] as String? ?? '',
      requiredFields: (json['requiredFields'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      dedupeKeys: (json['dedupeKeys'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      normalizationTargets: (json['normalizationTargets'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      requiresReview: json['requiresReview'] as bool? ?? false,
      templateRecord: Map<String, dynamic>.from(
        json['templateRecord'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => Map<String, dynamic>.from(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <Map<String, dynamic>>[],
      notes:
          (json['notes'] as List?)?.map((entry) => entry.toString()).toList() ??
              const <String>[],
      status: ReplayManualImportEntryStatusX.fromName(
        json['status'] as String?,
      ),
    );
  }
}

enum ReplayManualImportEntryStatus {
  template,
  populated,
  reviewed,
}

extension ReplayManualImportEntryStatusX on ReplayManualImportEntryStatus {
  static ReplayManualImportEntryStatus fromName(String? raw) {
    return ReplayManualImportEntryStatus.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ReplayManualImportEntryStatus.template,
    );
  }
}

class ReplayManualImportBundle {
  const ReplayManualImportBundle({
    required this.bundleId,
    required this.replayYear,
    required this.generatedAtUtc,
    this.entries = const <ReplayManualImportEntry>[],
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String bundleId;
  final int replayYear;
  final DateTime generatedAtUtc;
  final List<ReplayManualImportEntry> entries;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bundleId': bundleId,
      'replayYear': replayYear,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayManualImportBundle.fromJson(Map<String, dynamic> json) {
    return ReplayManualImportBundle(
      bundleId: json['bundleId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      generatedAtUtc:
          DateTime.tryParse(json['generatedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      entries: (json['entries'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayManualImportEntry.fromJson(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <ReplayManualImportEntry>[],
      notes:
          (json['notes'] as List?)?.map((entry) => entry.toString()).toList() ??
              const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
