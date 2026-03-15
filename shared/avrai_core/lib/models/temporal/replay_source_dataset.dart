class ReplaySourceDataset {
  const ReplaySourceDataset({
    required this.sourceName,
    this.records = const <Map<String, dynamic>>[],
    this.metadata = const <String, dynamic>{},
  });

  final String sourceName;
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceName': sourceName,
      'records': records,
      'metadata': metadata,
    };
  }

  factory ReplaySourceDataset.fromJson(Map<String, dynamic> json) {
    return ReplaySourceDataset(
      sourceName: json['sourceName'] as String? ?? '',
      records: (json['records'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => Map<String, dynamic>.from(
                  entry.map((key, value) => MapEntry('$key', value)),
                ),
              )
              .toList() ??
          const <Map<String, dynamic>>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}
