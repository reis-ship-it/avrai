class ReplayPopulationGeneratorConfig {
  const ReplayPopulationGeneratorConfig({
    this.geographyScope = 'metro_core',
    this.targetWeightedActorCount = 25000,
    this.minimumActorsPerLocality = 40,
    this.minimumPersonalAgentActorsPerLocality = 8,
    this.includeOptionalLocalityArchetypes = true,
  });

  final String geographyScope;
  final int targetWeightedActorCount;
  final int minimumActorsPerLocality;
  final int minimumPersonalAgentActorsPerLocality;
  final bool includeOptionalLocalityArchetypes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'geographyScope': geographyScope,
      'targetWeightedActorCount': targetWeightedActorCount,
      'minimumActorsPerLocality': minimumActorsPerLocality,
      'minimumPersonalAgentActorsPerLocality':
          minimumPersonalAgentActorsPerLocality,
      'includeOptionalLocalityArchetypes': includeOptionalLocalityArchetypes,
    };
  }

  factory ReplayPopulationGeneratorConfig.fromJson(Map<String, dynamic> json) {
    return ReplayPopulationGeneratorConfig(
      geographyScope: json['geographyScope'] as String? ?? 'metro_core',
      targetWeightedActorCount:
          (json['targetWeightedActorCount'] as num?)?.toInt() ?? 25000,
      minimumActorsPerLocality:
          (json['minimumActorsPerLocality'] as num?)?.toInt() ?? 40,
      minimumPersonalAgentActorsPerLocality:
          (json['minimumPersonalAgentActorsPerLocality'] as num?)?.toInt() ?? 8,
      includeOptionalLocalityArchetypes:
          json['includeOptionalLocalityArchetypes'] as bool? ?? true,
    );
  }
}

class ReplayCommuteProfile {
  const ReplayCommuteProfile({
    required this.localityAnchor,
    required this.commuteBand,
    required this.primaryCorridor,
    required this.workdayStartHour,
    required this.workdayReturnHour,
    this.metadata = const <String, dynamic>{},
  });

  final String localityAnchor;
  final String commuteBand;
  final String primaryCorridor;
  final int workdayStartHour;
  final int workdayReturnHour;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localityAnchor': localityAnchor,
      'commuteBand': commuteBand,
      'primaryCorridor': primaryCorridor,
      'workdayStartHour': workdayStartHour,
      'workdayReturnHour': workdayReturnHour,
      'metadata': metadata,
    };
  }

  factory ReplayCommuteProfile.fromJson(Map<String, dynamic> json) {
    return ReplayCommuteProfile(
      localityAnchor: json['localityAnchor'] as String? ?? '',
      commuteBand: json['commuteBand'] as String? ?? 'moderate',
      primaryCorridor: json['primaryCorridor'] as String? ?? 'unknown',
      workdayStartHour: (json['workdayStartHour'] as num?)?.toInt() ?? 8,
      workdayReturnHour: (json['workdayReturnHour'] as num?)?.toInt() ?? 17,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayBudgetPressureProfile {
  const ReplayBudgetPressureProfile({
    required this.localityAnchor,
    required this.pressureBand,
    required this.housingPressureBand,
    required this.discretionarySpendingBand,
    this.metadata = const <String, dynamic>{},
  });

  final String localityAnchor;
  final String pressureBand;
  final String housingPressureBand;
  final String discretionarySpendingBand;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'localityAnchor': localityAnchor,
      'pressureBand': pressureBand,
      'housingPressureBand': housingPressureBand,
      'discretionarySpendingBand': discretionarySpendingBand,
      'metadata': metadata,
    };
  }

  factory ReplayBudgetPressureProfile.fromJson(Map<String, dynamic> json) {
    return ReplayBudgetPressureProfile(
      localityAnchor: json['localityAnchor'] as String? ?? '',
      pressureBand: json['pressureBand'] as String? ?? 'moderate',
      housingPressureBand: json['housingPressureBand'] as String? ?? 'moderate',
      discretionarySpendingBand:
          json['discretionarySpendingBand'] as String? ?? 'moderate',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayDailyScheduleAnchor {
  const ReplayDailyScheduleAnchor({
    required this.anchorId,
    required this.localityAnchor,
    required this.scheduleKind,
    required this.startHour,
    required this.endHour,
    required this.dayPattern,
    this.metadata = const <String, dynamic>{},
  });

  final String anchorId;
  final String localityAnchor;
  final String scheduleKind;
  final int startHour;
  final int endHour;
  final String dayPattern;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'anchorId': anchorId,
      'localityAnchor': localityAnchor,
      'scheduleKind': scheduleKind,
      'startHour': startHour,
      'endHour': endHour,
      'dayPattern': dayPattern,
      'metadata': metadata,
    };
  }

  factory ReplayDailyScheduleAnchor.fromJson(Map<String, dynamic> json) {
    return ReplayDailyScheduleAnchor(
      anchorId: json['anchorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      scheduleKind: json['scheduleKind'] as String? ?? 'routine',
      startHour: (json['startHour'] as num?)?.toInt() ?? 8,
      endHour: (json['endHour'] as num?)?.toInt() ?? 17,
      dayPattern: json['dayPattern'] as String? ?? 'weekday',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplaySyntheticPopulationBatch {
  const ReplaySyntheticPopulationBatch({
    required this.replayYear,
    required this.config,
    required this.inScopeLocalityCount,
    required this.weightedActorCount,
    required this.commuteProfiles,
    required this.budgetProfiles,
    required this.scheduleAnchors,
    this.metadata = const <String, dynamic>{},
  });

  final int replayYear;
  final ReplayPopulationGeneratorConfig config;
  final int inScopeLocalityCount;
  final int weightedActorCount;
  final List<ReplayCommuteProfile> commuteProfiles;
  final List<ReplayBudgetPressureProfile> budgetProfiles;
  final List<ReplayDailyScheduleAnchor> scheduleAnchors;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'replayYear': replayYear,
      'config': config.toJson(),
      'inScopeLocalityCount': inScopeLocalityCount,
      'weightedActorCount': weightedActorCount,
      'commuteProfiles': commuteProfiles.map((entry) => entry.toJson()).toList(),
      'budgetProfiles': budgetProfiles.map((entry) => entry.toJson()).toList(),
      'scheduleAnchors': scheduleAnchors.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplaySyntheticPopulationBatch.fromJson(Map<String, dynamic> json) {
    return ReplaySyntheticPopulationBatch(
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      config: ReplayPopulationGeneratorConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map? ?? const {}),
      ),
      inScopeLocalityCount:
          (json['inScopeLocalityCount'] as num?)?.toInt() ?? 0,
      weightedActorCount: (json['weightedActorCount'] as num?)?.toInt() ?? 0,
      commuteProfiles: (json['commuteProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayCommuteProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayCommuteProfile>[],
      budgetProfiles: (json['budgetProfiles'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayBudgetPressureProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayBudgetPressureProfile>[],
      scheduleAnchors: (json['scheduleAnchors'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayDailyScheduleAnchor.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayDailyScheduleAnchor>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
