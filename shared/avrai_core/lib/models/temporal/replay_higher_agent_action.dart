import 'package:avrai_core/models/temporal/replay_higher_agent_rollup.dart';

enum ReplayHigherAgentActionType {
  personalPlanDailyCircuit,
  personalJoinCommunityPattern,
  personalDeferForHouseholdFriction,
  escalateContradictionToLocality,
  stabilizeLocalityTruth,
  escalateLocalityReview,
  handoffLocalityDigestToPersonalAgents,
  aggregateCitySignal,
  routeCityGuidanceDownward,
  retainAsReplayPriorOnly,
  auditContradictionSurface,
}

class ReplayHigherAgentAction {
  const ReplayHigherAgentAction({
    required this.actionId,
    required this.environmentId,
    required this.level,
    required this.agentId,
    required this.actionType,
    required this.monthKey,
    required this.targetNodeIds,
    required this.reason,
    required this.guidance,
    required this.cautionScore,
    this.localityAnchor,
    this.metadata = const <String, dynamic>{},
  });

  final String actionId;
  final String environmentId;
  final ReplayHigherAgentLevel level;
  final String agentId;
  final ReplayHigherAgentActionType actionType;
  final String monthKey;
  final String? localityAnchor;
  final List<String> targetNodeIds;
  final String reason;
  final List<String> guidance;
  final double cautionScore;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'actionId': actionId,
      'environmentId': environmentId,
      'level': level.name,
      'agentId': agentId,
      'actionType': actionType.name,
      'monthKey': monthKey,
      'localityAnchor': localityAnchor,
      'targetNodeIds': targetNodeIds,
      'reason': reason,
      'guidance': guidance,
      'cautionScore': cautionScore,
      'metadata': metadata,
    };
  }

  factory ReplayHigherAgentAction.fromJson(Map<String, dynamic> json) {
    return ReplayHigherAgentAction(
      actionId: json['actionId'] as String? ?? '',
      environmentId: json['environmentId'] as String? ?? '',
      level: ReplayHigherAgentLevel.values.firstWhere(
        (value) => value.name == json['level'],
        orElse: () => ReplayHigherAgentLevel.locality,
      ),
      agentId: json['agentId'] as String? ?? '',
      actionType: ReplayHigherAgentActionType.values.firstWhere(
        (value) => value.name == json['actionType'],
        orElse: () => ReplayHigherAgentActionType.stabilizeLocalityTruth,
      ),
      monthKey: json['monthKey'] as String? ?? '',
      localityAnchor: json['localityAnchor'] as String?,
      targetNodeIds: (json['targetNodeIds'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      reason: json['reason'] as String? ?? '',
      guidance: (json['guidance'] as List?)
              ?.map((entry) => entry.toString())
              .toList() ??
          const <String>[],
      cautionScore: (json['cautionScore'] as num?)?.toDouble() ?? 0.0,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
