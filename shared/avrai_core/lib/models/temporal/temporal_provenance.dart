enum TemporalAuthority {
  device,
  synchronizedServer,
  historicalImport,
  inferred,
  forecast,
}

class TemporalProvenance {
  const TemporalProvenance({
    required this.authority,
    required this.source,
  });

  final TemporalAuthority authority;
  final String source;

  Map<String, dynamic> toJson() {
    return {
      'authority': authority.name,
      'source': source,
    };
  }

  factory TemporalProvenance.fromJson(Map<String, dynamic> json) {
    return TemporalProvenance(
      authority: TemporalAuthority.values.firstWhere(
        (value) => value.name == json['authority'],
        orElse: () => TemporalAuthority.device,
      ),
      source: json['source'] as String? ?? 'unknown',
    );
  }
}
