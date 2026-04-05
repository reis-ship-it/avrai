import 'package:avrai_core/models/temporal/agent_lifecycle_transition.dart';
import 'package:avrai_core/models/temporal/replay_agent_kernel_bundle.dart';

class ReplayPopulationProfile {
  const ReplayPopulationProfile({
    required this.replayYear,
    required this.totalPopulation,
    required this.totalHousingUnits,
    required this.estimatedOccupiedHousingUnits,
    required this.agentEligiblePopulation,
    required this.estimatedActiveAgentPopulation,
    required this.estimatedDormantAgentPopulation,
    required this.estimatedDeletedAgentPopulation,
    required this.dependentMobilityPopulation,
    required this.modeledActorCount,
    required this.localityPopulationCounts,
    required this.households,
    required this.actors,
    required this.eligibilityRecords,
    required this.lifecycleTransitions,
    this.metadata = const <String, dynamic>{},
  });

  final int replayYear;
  final int totalPopulation;
  final int totalHousingUnits;
  final int estimatedOccupiedHousingUnits;
  final int agentEligiblePopulation;
  final int estimatedActiveAgentPopulation;
  final int estimatedDormantAgentPopulation;
  final int estimatedDeletedAgentPopulation;
  final int dependentMobilityPopulation;
  final int modeledActorCount;
  final Map<String, int> localityPopulationCounts;
  final List<ReplayHouseholdProfile> households;
  final List<ReplayActorProfile> actors;
  final List<ReplayAgentEligibilityRecord> eligibilityRecords;
  final List<AgentLifecycleTransition> lifecycleTransitions;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'replayYear': replayYear,
      'totalPopulation': totalPopulation,
      'totalHousingUnits': totalHousingUnits,
      'estimatedOccupiedHousingUnits': estimatedOccupiedHousingUnits,
      'agentEligiblePopulation': agentEligiblePopulation,
      'estimatedActiveAgentPopulation': estimatedActiveAgentPopulation,
      'estimatedDormantAgentPopulation': estimatedDormantAgentPopulation,
      'estimatedDeletedAgentPopulation': estimatedDeletedAgentPopulation,
      'dependentMobilityPopulation': dependentMobilityPopulation,
      'modeledActorCount': modeledActorCount,
      'localityPopulationCounts': localityPopulationCounts,
      'households': households.map((entry) => entry.toJson()).toList(),
      'actors': actors.map((entry) => entry.toJson()).toList(),
      'eligibilityRecords':
          eligibilityRecords.map((entry) => entry.toJson()).toList(),
      'lifecycleTransitions':
          lifecycleTransitions.map((entry) => entry.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayPopulationProfile.fromJson(Map<String, dynamic> json) {
    return ReplayPopulationProfile(
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      totalPopulation: (json['totalPopulation'] as num?)?.toInt() ?? 0,
      totalHousingUnits: (json['totalHousingUnits'] as num?)?.toInt() ?? 0,
      estimatedOccupiedHousingUnits:
          (json['estimatedOccupiedHousingUnits'] as num?)?.toInt() ?? 0,
      agentEligiblePopulation:
          (json['agentEligiblePopulation'] as num?)?.toInt() ?? 0,
      estimatedActiveAgentPopulation:
          (json['estimatedActiveAgentPopulation'] as num?)?.toInt() ?? 0,
      estimatedDormantAgentPopulation:
          (json['estimatedDormantAgentPopulation'] as num?)?.toInt() ?? 0,
      estimatedDeletedAgentPopulation:
          (json['estimatedDeletedAgentPopulation'] as num?)?.toInt() ?? 0,
      dependentMobilityPopulation:
          (json['dependentMobilityPopulation'] as num?)?.toInt() ?? 0,
      modeledActorCount: (json['modeledActorCount'] as num?)?.toInt() ?? 0,
      localityPopulationCounts: _readCounts(json['localityPopulationCounts']),
      households: (json['households'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayHouseholdProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayHouseholdProfile>[],
      actors: (json['actors'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayActorProfile.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayActorProfile>[],
      eligibilityRecords: (json['eligibilityRecords'] as List?)
              ?.whereType<Map>()
              .map((entry) => ReplayAgentEligibilityRecord.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <ReplayAgentEligibilityRecord>[],
      lifecycleTransitions: (json['lifecycleTransitions'] as List?)
              ?.whereType<Map>()
              .map((entry) => AgentLifecycleTransition.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList() ??
          const <AgentLifecycleTransition>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  static Map<String, int> _readCounts(Object? raw) {
    return (raw as Map?)?.map(
          (key, value) =>
              MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
        ) ??
        const <String, int>{};
  }
}

class ReplayHouseholdProfile {
  const ReplayHouseholdProfile({
    required this.householdId,
    required this.localityAnchor,
    required this.householdType,
    required this.householdCount,
    required this.representedPopulationCount,
    required this.dependentMobilityCount,
    required this.commutingPressureBand,
    required this.economicPressureBand,
    this.metadata = const <String, dynamic>{},
  });

  final String householdId;
  final String localityAnchor;
  final String householdType;
  final int householdCount;
  final int representedPopulationCount;
  final int dependentMobilityCount;
  final String commutingPressureBand;
  final String economicPressureBand;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'householdId': householdId,
      'localityAnchor': localityAnchor,
      'householdType': householdType,
      'householdCount': householdCount,
      'representedPopulationCount': representedPopulationCount,
      'dependentMobilityCount': dependentMobilityCount,
      'commutingPressureBand': commutingPressureBand,
      'economicPressureBand': economicPressureBand,
      'metadata': metadata,
    };
  }

  factory ReplayHouseholdProfile.fromJson(Map<String, dynamic> json) {
    return ReplayHouseholdProfile(
      householdId: json['householdId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      householdType: json['householdType'] as String? ?? 'unknown',
      householdCount: (json['householdCount'] as num?)?.toInt() ?? 0,
      representedPopulationCount:
          (json['representedPopulationCount'] as num?)?.toInt() ?? 0,
      dependentMobilityCount:
          (json['dependentMobilityCount'] as num?)?.toInt() ?? 0,
      commutingPressureBand:
          json['commutingPressureBand'] as String? ?? 'moderate',
      economicPressureBand:
          json['economicPressureBand'] as String? ?? 'moderate',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayActorProfile {
  const ReplayActorProfile({
    required this.actorId,
    required this.localityAnchor,
    required this.representedPopulationCount,
    required this.populationRole,
    required this.lifecycleState,
    required this.ageBand,
    required this.lifeStage,
    required this.householdType,
    required this.workStudentStatus,
    required this.hasPersonalAgent,
    required this.preferredEntityTypes,
    this.kernelBundle,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String localityAnchor;
  final int representedPopulationCount;
  final SimulatedPopulationRole populationRole;
  final AgentLifecycleState lifecycleState;
  final String ageBand;
  final String lifeStage;
  final String householdType;
  final String workStudentStatus;
  final bool hasPersonalAgent;
  final List<String> preferredEntityTypes;
  final ReplayAgentKernelBundle? kernelBundle;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'localityAnchor': localityAnchor,
      'representedPopulationCount': representedPopulationCount,
      'populationRole': populationRole.name,
      'lifecycleState': lifecycleState.name,
      'ageBand': ageBand,
      'lifeStage': lifeStage,
      'householdType': householdType,
      'workStudentStatus': workStudentStatus,
      'hasPersonalAgent': hasPersonalAgent,
      'preferredEntityTypes': preferredEntityTypes,
      'kernelBundle': kernelBundle?.toJson(),
      'metadata': metadata,
    };
  }

  factory ReplayActorProfile.fromJson(Map<String, dynamic> json) {
    return ReplayActorProfile(
      actorId: json['actorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      representedPopulationCount:
          (json['representedPopulationCount'] as num?)?.toInt() ?? 0,
      populationRole: SimulatedPopulationRole.values.firstWhere(
        (value) => value.name == json['populationRole'],
        orElse: () => SimulatedPopulationRole.humanNonAgent,
      ),
      lifecycleState: AgentLifecycleState.values.firstWhere(
        (value) => value.name == json['lifecycleState'],
        orElse: () => AgentLifecycleState.active,
      ),
      ageBand: json['ageBand'] as String? ?? 'unknown',
      lifeStage: json['lifeStage'] as String? ?? 'unknown',
      householdType: json['householdType'] as String? ?? 'unknown',
      workStudentStatus: json['workStudentStatus'] as String? ?? 'unknown',
      hasPersonalAgent: json['hasPersonalAgent'] as bool? ?? false,
      preferredEntityTypes: (json['preferredEntityTypes'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      kernelBundle: json['kernelBundle'] == null
          ? null
          : ReplayAgentKernelBundle.fromJson(
              Map<String, dynamic>.from(json['kernelBundle'] as Map),
            ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}

class ReplayAgentEligibilityRecord {
  const ReplayAgentEligibilityRecord({
    required this.actorId,
    required this.localityAnchor,
    required this.ageBand,
    required this.personalAgentAllowed,
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  final String actorId;
  final String localityAnchor;
  final String ageBand;
  final bool personalAgentAllowed;
  final String reason;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actorId': actorId,
      'localityAnchor': localityAnchor,
      'ageBand': ageBand,
      'personalAgentAllowed': personalAgentAllowed,
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ReplayAgentEligibilityRecord.fromJson(Map<String, dynamic> json) {
    return ReplayAgentEligibilityRecord(
      actorId: json['actorId'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String? ?? '',
      ageBand: json['ageBand'] as String? ?? 'unknown',
      personalAgentAllowed: json['personalAgentAllowed'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }
}
