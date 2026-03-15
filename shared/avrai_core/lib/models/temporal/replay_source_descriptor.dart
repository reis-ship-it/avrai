enum ReplaySourceTrustTier {
  tier1,
  tier2,
  tier3,
  tier4,
  tier5,
}

enum ReplaySourceAccessMethod {
  api,
  ics,
  rss,
  scrape,
  partnerExport,
  openData,
  archive,
  manual,
  simulated,
}

enum ReplaySourceStatus {
  candidate,
  approved,
  ingested,
  blocked,
  deferred,
  legacy,
}

class ReplaySourceDescriptor {
  const ReplaySourceDescriptor({
    required this.sourceName,
    required this.sourceType,
    required this.accessMethod,
    required this.trustTier,
    required this.status,
    required this.entityCoverage,
    required this.temporalStartYear,
    required this.temporalEndYear,
    required this.replayRole,
    required this.legalStatus,
    this.sourceOwner,
    this.sourceUrl,
    this.updateCadence,
    this.richestYear,
    this.structuredExportAvailable = false,
    this.seedingEligible = false,
    this.ageSafetyNotes,
    this.metadata = const <String, dynamic>{},
  });

  final String sourceName;
  final String sourceType;
  final ReplaySourceAccessMethod accessMethod;
  final ReplaySourceTrustTier trustTier;
  final ReplaySourceStatus status;
  final List<String> entityCoverage;
  final int temporalStartYear;
  final int temporalEndYear;
  final String replayRole;
  final String legalStatus;
  final String? sourceOwner;
  final String? sourceUrl;
  final String? updateCadence;
  final int? richestYear;
  final bool structuredExportAvailable;
  final bool seedingEligible;
  final String? ageSafetyNotes;
  final Map<String, dynamic> metadata;

  bool coversYear(int year) => year >= temporalStartYear && year <= temporalEndYear;

  Map<String, dynamic> toJson() {
    return {
      'sourceName': sourceName,
      'sourceType': sourceType,
      'accessMethod': accessMethod.name,
      'trustTier': trustTier.name,
      'status': status.name,
      'entityCoverage': entityCoverage,
      'temporalStartYear': temporalStartYear,
      'temporalEndYear': temporalEndYear,
      'replayRole': replayRole,
      'legalStatus': legalStatus,
      'sourceOwner': sourceOwner,
      'sourceUrl': sourceUrl,
      'updateCadence': updateCadence,
      'richestYear': richestYear,
      'structuredExportAvailable': structuredExportAvailable,
      'seedingEligible': seedingEligible,
      'ageSafetyNotes': ageSafetyNotes,
      'metadata': metadata,
    };
  }

  factory ReplaySourceDescriptor.fromJson(Map<String, dynamic> json) {
    return ReplaySourceDescriptor(
      sourceName: json['sourceName'] as String? ?? '',
      sourceType: json['sourceType'] as String? ?? 'unknown',
      accessMethod: ReplaySourceAccessMethod.values.firstWhere(
        (value) => value.name == json['accessMethod'],
        orElse: () => ReplaySourceAccessMethod.manual,
      ),
      trustTier: ReplaySourceTrustTier.values.firstWhere(
        (value) => value.name == json['trustTier'],
        orElse: () => ReplaySourceTrustTier.tier5,
      ),
      status: ReplaySourceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ReplaySourceStatus.candidate,
      ),
      entityCoverage: (json['entityCoverage'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      temporalStartYear: (json['temporalStartYear'] as num?)?.toInt() ?? 0,
      temporalEndYear: (json['temporalEndYear'] as num?)?.toInt() ?? 0,
      replayRole: json['replayRole'] as String? ?? 'unknown',
      legalStatus: json['legalStatus'] as String? ?? 'unknown',
      sourceOwner: json['sourceOwner'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      updateCadence: json['updateCadence'] as String?,
      richestYear: (json['richestYear'] as num?)?.toInt(),
      structuredExportAvailable:
          json['structuredExportAvailable'] as bool? ?? false,
      seedingEligible: json['seedingEligible'] as bool? ?? false,
      ageSafetyNotes: json['ageSafetyNotes'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
