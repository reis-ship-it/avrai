import 'package:equatable/equatable.dart';

/// Stable key for identifying a LocalityAgent (v1).
///
/// **Design choice:** the identity is stable and grid-based (geohash prefix),
/// while “areas” (clusters/labels) are allowed to evolve independently.
class LocalityAgentKeyV1 extends Equatable {
  final String geohashPrefix;
  final int precision;

  /// Optional geo hierarchy context (best-effort enrichment).
  /// Not part of the stable identity.
  final String? cityCode;

  const LocalityAgentKeyV1({
    required this.geohashPrefix,
    required this.precision,
    this.cityCode,
  }) : assert(geohashPrefix.length > 0);

  /// Canonical stable string key.
  ///
  /// Example: `gh7:dr5regw`
  String get stableKey => 'gh$precision:$geohashPrefix';

  Map<String, dynamic> toJson() => {
        'geohashPrefix': geohashPrefix,
        'precision': precision,
        if (cityCode != null) 'cityCode': cityCode,
      };

  factory LocalityAgentKeyV1.fromJson(Map<String, dynamic> json) {
    return LocalityAgentKeyV1(
      geohashPrefix: (json['geohashPrefix'] ?? '').toString(),
      precision: (json['precision'] as num?)?.toInt() ?? 7,
      cityCode: (json['cityCode'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['cityCode'] as String?),
    );
  }

  @override
  List<Object?> get props => [geohashPrefix, precision, cityCode];
}

/// Global (shared) locality agent state stored in Supabase (v1).
class LocalityAgentGlobalStateV1 extends Equatable {
  final LocalityAgentKeyV1 key;

  /// A 12-dim vector representing “what this area is like” as a shared prior.
  /// The semantics align with SPOTS 12 dimensions, but this is a locality-context vector.
  final List<double> vector12;

  /// Lightweight counters for aggregation/debugging.
  final int sampleCount;

  /// Optional per-dimension confidence (0..1).
  final List<double>? confidence12;

  final DateTime updatedAtUtc;

  const LocalityAgentGlobalStateV1({
    required this.key,
    required this.vector12,
    required this.sampleCount,
    required this.updatedAtUtc,
    this.confidence12,
  }) : assert(vector12.length == 12);

  static LocalityAgentGlobalStateV1 empty(LocalityAgentKeyV1 key) =>
      LocalityAgentGlobalStateV1(
        key: key,
        vector12: List<double>.filled(12, 0.5),
        sampleCount: 0,
        confidence12: List<double>.filled(12, 0.0),
        updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toJson() => {
        'key': key.toJson(),
        'vector12': vector12,
        'sampleCount': sampleCount,
        'confidence12': confidence12,
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
      };

  factory LocalityAgentGlobalStateV1.fromJson(Map<String, dynamic> json) {
    final vec = (json['vector12'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
        List<double>.filled(12, 0.5);
    final conf = (json['confidence12'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList();
    return LocalityAgentGlobalStateV1(
      key: LocalityAgentKeyV1.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      vector12: vec.length == 12 ? vec : List<double>.filled(12, 0.5),
      sampleCount: (json['sampleCount'] as num?)?.toInt() ?? 0,
      confidence12: conf?.length == 12 ? conf : null,
      updatedAtUtc: DateTime.tryParse((json['updatedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [key, vector12, sampleCount, confidence12, updatedAtUtc];
}

/// Per-user private delta applied on top of global priors (v1).
class LocalityAgentPersonalDeltaV1 extends Equatable {
  final LocalityAgentKeyV1 key;

  /// Personal delta vector (can be negative/positive). Length 12.
  final List<double> delta12;

  final int visitCount;
  final DateTime updatedAtUtc;

  const LocalityAgentPersonalDeltaV1({
    required this.key,
    required this.delta12,
    required this.visitCount,
    required this.updatedAtUtc,
  }) : assert(delta12.length == 12);

  static LocalityAgentPersonalDeltaV1 empty(LocalityAgentKeyV1 key) =>
      LocalityAgentPersonalDeltaV1(
        key: key,
        delta12: List<double>.filled(12, 0.0),
        visitCount: 0,
        updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toJson() => {
        'key': key.toJson(),
        'delta12': delta12,
        'visitCount': visitCount,
        'updatedAtUtc': updatedAtUtc.toIso8601String(),
      };

  factory LocalityAgentPersonalDeltaV1.fromJson(Map<String, dynamic> json) {
    final delta = (json['delta12'] as List?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        List<double>.filled(12, 0.0);
    return LocalityAgentPersonalDeltaV1(
      key: LocalityAgentKeyV1.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      delta12: delta.length == 12 ? delta : List<double>.filled(12, 0.0),
      visitCount: (json['visitCount'] as num?)?.toInt() ?? 0,
      updatedAtUtc: DateTime.tryParse((json['updatedAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  List<Object?> get props => [key, delta12, visitCount, updatedAtUtc];
}

/// Privacy-preserving update event emitted from device → backend (v1).
///
/// **Important:** must not contain user identifiers.
class LocalityAgentUpdateEventV1 extends Equatable {
  final LocalityAgentKeyV1 key;

  /// UTC timestamp of the underlying trigger/visit (coarsening handled server-side).
  final DateTime occurredAtUtc;

  /// City scoping (best-effort enrichment; not part of stable identity).
  ///
  /// - `reportedCityCode`: the device’s current “bucket/source” notion of city membership
  ///   (offline-first; should usually be present).
  /// - `inferredCityCode`: best-effort inference that may disagree with reported
  ///   (may be null when offline).
  final String? reportedCityCode;
  final String? inferredCityCode;

  /// Derived features (minimal v1). All values should be non-identifying.
  final int? dwellMinutes;
  final double? qualityScore;
  final bool? isRepeatVisit;

  /// Source category for auditability: geofence/bluetooth/onboarding_seed/other.
  final String source;

  const LocalityAgentUpdateEventV1({
    required this.key,
    required this.occurredAtUtc,
    required this.source,
    this.reportedCityCode,
    this.inferredCityCode,
    this.dwellMinutes,
    this.qualityScore,
    this.isRepeatVisit,
  });

  Map<String, dynamic> toJson() => {
        'key': key.toJson(),
        'occurredAtUtc': occurredAtUtc.toIso8601String(),
        if (reportedCityCode != null) 'reportedCityCode': reportedCityCode,
        if (inferredCityCode != null) 'inferredCityCode': inferredCityCode,
        'dwellMinutes': dwellMinutes,
        'qualityScore': qualityScore,
        'isRepeatVisit': isRepeatVisit,
        'source': source,
      };

  factory LocalityAgentUpdateEventV1.fromJson(Map<String, dynamic> json) {
    return LocalityAgentUpdateEventV1(
      key: LocalityAgentKeyV1.fromJson(
        Map<String, dynamic>.from(json['key'] as Map? ?? const {}),
      ),
      occurredAtUtc: DateTime.parse((json['occurredAtUtc'] ?? '').toString())
          .toUtc(),
      reportedCityCode: (json['reportedCityCode'] as String?)?.trim().isEmpty ??
              true
          ? null
          : (json['reportedCityCode'] as String?),
      inferredCityCode: (json['inferredCityCode'] as String?)?.trim().isEmpty ??
              true
          ? null
          : (json['inferredCityCode'] as String?),
      dwellMinutes: (json['dwellMinutes'] as num?)?.toInt(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      isRepeatVisit: json['isRepeatVisit'] as bool?,
      source: (json['source'] ?? 'unknown').toString(),
    );
  }

  @override
  List<Object?> get props => [
        key,
        occurredAtUtc,
        reportedCityCode,
        inferredCityCode,
        dwellMinutes,
        qualityScore,
        isRepeatVisit,
        source,
      ];
}

