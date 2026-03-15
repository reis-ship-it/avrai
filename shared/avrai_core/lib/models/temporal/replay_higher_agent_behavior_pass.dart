import 'package:avrai_core/models/temporal/monte_carlo_run_context.dart';
import 'package:avrai_core/models/temporal/replay_higher_agent_action.dart';

class ReplayHigherAgentBehaviorPass {
  const ReplayHigherAgentBehaviorPass({
    required this.environmentId,
    required this.replayYear,
    required this.runContext,
    required this.actionCountsByType,
    required this.actionCountsByLevel,
    required this.monthCounts,
    required this.actions,
    this.metadata = const <String, dynamic>{},
  });

  final String environmentId;
  final int replayYear;
  final MonteCarloRunContext runContext;
  final Map<String, int> actionCountsByType;
  final Map<String, int> actionCountsByLevel;
  final Map<String, int> monthCounts;
  final List<ReplayHigherAgentAction> actions;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environmentId': environmentId,
      'replayYear': replayYear,
      'runContext': runContext.toJson(),
      'actionCountsByType': actionCountsByType,
      'actionCountsByLevel': actionCountsByLevel,
      'monthCounts': monthCounts,
      'actions': actions.map((action) => action.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ReplayHigherAgentBehaviorPass.fromJson(Map<String, dynamic> json) {
    Map<String, int> readCounts(Object? raw) {
      return (raw as Map?)
              ?.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
              ) ??
          const <String, int>{};
    }

    return ReplayHigherAgentBehaviorPass(
      environmentId: json['environmentId'] as String? ?? '',
      replayYear: (json['replayYear'] as num?)?.toInt() ?? 0,
      runContext: MonteCarloRunContext.fromJson(
        Map<String, dynamic>.from(json['runContext'] as Map? ?? const {}),
      ),
      actionCountsByType: readCounts(json['actionCountsByType']),
      actionCountsByLevel: readCounts(json['actionCountsByLevel']),
      monthCounts: readCounts(json['monthCounts']),
      actions: (json['actions'] as List?)
              ?.whereType<Map>()
              .map(
                (entry) => ReplayHigherAgentAction.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              )
              .toList() ??
          const <ReplayHigherAgentAction>[],
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

