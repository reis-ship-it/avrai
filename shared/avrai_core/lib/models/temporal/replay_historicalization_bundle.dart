class ReplayHistoricalizationSample {
  const ReplayHistoricalizationSample({
    required this.name,
    required this.entityType,
    this.locality,
    this.recordId,
  });

  final String name;
  final String entityType;
  final String? locality;
  final String? recordId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'entityType': entityType,
      if (locality != null) 'locality': locality,
      if (recordId != null) 'recordId': recordId,
    };
  }

  factory ReplayHistoricalizationSample.fromJson(Map<String, dynamic> json) {
    return ReplayHistoricalizationSample(
      name: json['name'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      locality: json['locality'] as String?,
      recordId: json['recordId'] as String?,
    );
  }
}

class ReplayHistoricalizationEntry {
  const ReplayHistoricalizationEntry({
    required this.sourceName,
    required this.sourceUri,
    required this.coverageStatus,
    required this.recordCount,
    required this.requiredHistoricalFields,
    required this.sourceSpecificActions,
    this.samples = const <ReplayHistoricalizationSample>[],
    this.notes = const <String>[],
  });

  final String sourceName;
  final String sourceUri;
  final String coverageStatus;
  final int recordCount;
  final List<String> requiredHistoricalFields;
  final List<String> sourceSpecificActions;
  final List<ReplayHistoricalizationSample> samples;
  final List<String> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceName': sourceName,
      'sourceUri': sourceUri,
      'coverageStatus': coverageStatus,
      'recordCount': recordCount,
      'requiredHistoricalFields': requiredHistoricalFields,
      'sourceSpecificActions': sourceSpecificActions,
      'samples': samples.map((sample) => sample.toJson()).toList(),
      'notes': notes,
    };
  }

  factory ReplayHistoricalizationEntry.fromJson(Map<String, dynamic> json) {
    return ReplayHistoricalizationEntry(
      sourceName: json['sourceName'] as String? ?? '',
      sourceUri: json['sourceUri'] as String? ?? '',
      coverageStatus: json['coverageStatus'] as String? ?? '',
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
      requiredHistoricalFields: (json['requiredHistoricalFields'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      sourceSpecificActions: (json['sourceSpecificActions'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      samples: (json['samples'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayHistoricalizationSample.fromJson(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <ReplayHistoricalizationSample>[],
      notes:
          (json['notes'] as List?)?.map((entry) => entry.toString()).toList() ??
              const <String>[],
    );
  }
}

class ReplayHistoricalizationBundle {
  const ReplayHistoricalizationBundle({
    required this.bundleId,
    required this.replayYear,
    required this.generatedAtUtc,
    required this.entries,
    this.notes = const <String>[],
  });

  final String bundleId;
  final int replayYear;
  final DateTime generatedAtUtc;
  final List<ReplayHistoricalizationEntry> entries;
  final List<String> notes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'bundleId': bundleId,
      'replayYear': replayYear,
      'generatedAtUtc': generatedAtUtc.toUtc().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'notes': notes,
    };
  }

  factory ReplayHistoricalizationBundle.fromJson(Map<String, dynamic> json) {
    return ReplayHistoricalizationBundle(
      bundleId: json['bundleId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      generatedAtUtc:
          DateTime.tryParse(json['generatedAtUtc'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      entries: (json['entries'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayHistoricalizationEntry.fromJson(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <ReplayHistoricalizationEntry>[],
      notes:
          (json['notes'] as List?)?.map((entry) => entry.toString()).toList() ??
              const <String>[],
    );
  }
}
