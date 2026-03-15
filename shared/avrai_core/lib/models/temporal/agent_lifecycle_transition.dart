import 'package:avrai_core/models/temporal/temporal_instant.dart';

enum AgentLifecycleState {
  active,
  dormant,
  deleted,
  systemAgent,
}

enum SimulatedPopulationRole {
  humanNonAgent,
  humanWithAgent,
  dependentMobilityOnly,
  systemAgent,
}

class AgentLifecycleTransition {
  const AgentLifecycleTransition({
    required this.transitionId,
    required this.agentId,
    required this.role,
    required this.toState,
    required this.occurredAt,
    required this.trigger,
    this.fromState,
    this.subjectId,
    this.metadata = const <String, dynamic>{},
  });

  final String transitionId;
  final String agentId;
  final SimulatedPopulationRole role;
  final AgentLifecycleState? fromState;
  final AgentLifecycleState toState;
  final TemporalInstant occurredAt;
  final String trigger;
  final String? subjectId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return {
      'transitionId': transitionId,
      'agentId': agentId,
      'role': role.name,
      'fromState': fromState?.name,
      'toState': toState.name,
      'occurredAt': occurredAt.toJson(),
      'trigger': trigger,
      'subjectId': subjectId,
      'metadata': metadata,
    };
  }

  factory AgentLifecycleTransition.fromJson(Map<String, dynamic> json) {
    AgentLifecycleState? parseOptionalState(Object? raw) {
      for (final value in AgentLifecycleState.values) {
        if (value.name == raw) {
          return value;
        }
      }
      return null;
    }

    return AgentLifecycleTransition(
      transitionId: json['transitionId'] as String? ?? '',
      agentId: json['agentId'] as String? ?? '',
      role: SimulatedPopulationRole.values.firstWhere(
        (value) => value.name == json['role'],
        orElse: () => SimulatedPopulationRole.humanNonAgent,
      ),
      fromState: parseOptionalState(json['fromState']),
      toState: AgentLifecycleState.values.firstWhere(
        (value) => value.name == json['toState'],
        orElse: () => AgentLifecycleState.active,
      ),
      occurredAt: TemporalInstant.fromJson(
        Map<String, dynamic>.from(json['occurredAt'] as Map? ?? const {}),
      ),
      trigger: json['trigger'] as String? ?? 'unknown',
      subjectId: json['subjectId'] as String?,
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
