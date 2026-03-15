class ReplayStochasticRunConfig {
  const ReplayStochasticRunConfig({
    required this.runId,
    required this.replayYear,
    required this.globalSeed,
    required this.localityPerturbationSeed,
    required this.actorSeed,
    required this.monthSeasonSeed,
    this.metadata = const <String, dynamic>{},
  });

  final String runId;
  final int replayYear;
  final int globalSeed;
  final int localityPerturbationSeed;
  final int actorSeed;
  final int monthSeasonSeed;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'runId': runId,
      'replayYear': replayYear,
      'globalSeed': globalSeed,
      'localityPerturbationSeed': localityPerturbationSeed,
      'actorSeed': actorSeed,
      'monthSeasonSeed': monthSeasonSeed,
      'metadata': metadata,
    };
  }

  factory ReplayStochasticRunConfig.fromJson(Map<String, dynamic> json) {
    return ReplayStochasticRunConfig(
      runId: json['runId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      globalSeed: (json['globalSeed'] as num?)?.toInt() ?? 0,
      localityPerturbationSeed:
          (json['localityPerturbationSeed'] as num?)?.toInt() ?? 0,
      actorSeed: (json['actorSeed'] as num?)?.toInt() ?? 0,
      monthSeasonSeed: (json['monthSeasonSeed'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayVariationProfile {
  const ReplayVariationProfile({
    required this.environmentId,
    required this.replayYear,
    required this.runConfig,
    required this.sameSeedReproducible,
    required this.untrackedWindowCount,
    required this.offlineQueuedCount,
    required this.attendanceVariationCount,
    required this.connectivityVariationCount,
    required this.routeVariationCount,
    required this.exchangeTimingVariationCount,
    required this.monthVariationCounts,
    this.notes = const <String>[],
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final ReplayStochasticRunConfig runConfig;
  final bool sameSeedReproducible;
  final int untrackedWindowCount;
  final int offlineQueuedCount;
  final int attendanceVariationCount;
  final int connectivityVariationCount;
  final int routeVariationCount;
  final int exchangeTimingVariationCount;
  final Map<String, int> monthVariationCounts;
  final List<String> notes;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'runConfig': runConfig.toJson(),
      'sameSeedReproducible': sameSeedReproducible,
      'untrackedWindowCount': untrackedWindowCount,
      'offlineQueuedCount': offlineQueuedCount,
      'attendanceVariationCount': attendanceVariationCount,
      'connectivityVariationCount': connectivityVariationCount,
      'routeVariationCount': routeVariationCount,
      'exchangeTimingVariationCount': exchangeTimingVariationCount,
      'monthVariationCounts': monthVariationCounts,
      'notes': notes,
      'metadata': metadata,
    };
  }

  factory ReplayVariationProfile.fromJson(Map<String, dynamic> json) {
    return ReplayVariationProfile(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runConfig: ReplayStochasticRunConfig.fromJson(
        Map<String, dynamic>.from(json['runConfig'] as Map? ?? const {}),
      ),
      sameSeedReproducible: json['sameSeedReproducible'] as bool? ?? true,
      untrackedWindowCount:
          (json['untrackedWindowCount'] as num?)?.toInt() ?? 0,
      offlineQueuedCount: (json['offlineQueuedCount'] as num?)?.toInt() ?? 0,
      attendanceVariationCount:
          (json['attendanceVariationCount'] as num?)?.toInt() ?? 0,
      connectivityVariationCount:
          (json['connectivityVariationCount'] as num?)?.toInt() ?? 0,
      routeVariationCount:
          (json['routeVariationCount'] as num?)?.toInt() ?? 0,
      exchangeTimingVariationCount:
          (json['exchangeTimingVariationCount'] as num?)?.toInt() ?? 0,
      monthVariationCounts: (json['monthVariationCounts'] as Map?)
              ?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
          const <String, int>{},
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
