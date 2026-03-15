class ReplayRealismGateRecord {
  const ReplayRealismGateRecord({
    required this.gateId,
    required this.status,
    required this.rationale,
    this.metrics = const <String, dynamic>{},
  });

  final String gateId;
  final String status;
  final String rationale;
  final Map<String, dynamic> metrics;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gateId': gateId,
      'status': status,
      'rationale': rationale,
      'metrics': metrics,
    };
  }

  factory ReplayRealismGateRecord.fromJson(Map<String, dynamic> json) {
    return ReplayRealismGateRecord(
      gateId: json['gateId'] as String? ?? '',
      status: json['status'] as String? ?? 'failed',
      rationale: json['rationale'] as String? ?? '',
      metrics: Map<String, dynamic>.from(
        json['metrics'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayRealismGateReport {
  const ReplayRealismGateReport({
    required this.environmentId,
    required this.replayYear,
    required this.readyForMonteCarloBaseYear,
    required this.records,
    this.unresolvedGaps = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final bool readyForMonteCarloBaseYear;
  final List<ReplayRealismGateRecord> records;
  final List<String> unresolvedGaps;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'readyForMonteCarloBaseYear': readyForMonteCarloBaseYear,
      'records': records.map((entry) => entry.toJson()).toList(),
      'unresolvedGaps': unresolvedGaps,
      'metadata': metadata,
    };
  }

  factory ReplayRealismGateReport.fromJson(Map<String, dynamic> json) {
    return ReplayRealismGateReport(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      readyForMonteCarloBaseYear:
          json['readyForMonteCarloBaseYear'] as bool? ?? false,
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayRealismGateRecord.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayRealismGateRecord>[],
      unresolvedGaps: (json['unresolvedGaps'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
