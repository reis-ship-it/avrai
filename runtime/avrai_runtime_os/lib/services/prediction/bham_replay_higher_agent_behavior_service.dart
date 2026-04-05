import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/prediction/bham_replay_execution_service.dart';

class BhamReplayHigherAgentBehaviorService {
  const BhamReplayHigherAgentBehaviorService();

  ReplayHigherAgentBehaviorPass buildBehaviorPass({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayHigherAgentRollupBatch rollupBatch,
    required BhamReplayExecutionPlan executionPlan,
    ReplayPopulationProfile? populationProfile,
  }) {
    final actorsById = <String, ReplayActorProfile>{
      for (final actor
          in populationProfile?.actors ?? const <ReplayActorProfile>[])
        actor.actorId: actor,
    };
    final monthKeysBySubject = <String, Set<String>>{};
    for (final entry in executionPlan.entries) {
      monthKeysBySubject.putIfAbsent(
        entry.observation.subjectIdentity.normalizedEntityId,
        () => <String>{},
      );
      monthKeysBySubject[entry.observation.subjectIdentity.normalizedEntityId]!
          .add(entry.monthKey);
    }

    final actions = <ReplayHigherAgentAction>[];
    for (final rollup in rollupBatch.rollups) {
      final monthKeys = <String>{};
      for (final nodeId in rollup.nodeIds) {
        final subjectId = nodeId.replaceFirst('replay-node:', '');
        monthKeys.addAll(monthKeysBySubject[subjectId] ?? const <String>{});
      }
      final orderedMonths = monthKeys.toList()..sort();
      if (orderedMonths.isEmpty) {
        orderedMonths.add('${environment.replayYear}-01');
      }

      for (final monthKey in orderedMonths) {
        actions.addAll(
          _actionsForRollupAndMonth(
            environment: environment,
            rollup: rollup,
            monthKey: monthKey,
            actor: actorsById[rollup.agentId],
          ),
        );
      }
    }

    final actionCountsByType = <String, int>{};
    final actionCountsByLevel = <String, int>{};
    final monthCounts = <String, int>{};
    for (final action in actions) {
      actionCountsByType[action.actionType.name] =
          (actionCountsByType[action.actionType.name] ?? 0) + 1;
      actionCountsByLevel[action.level.name] =
          (actionCountsByLevel[action.level.name] ?? 0) + 1;
      monthCounts[action.monthKey] = (monthCounts[action.monthKey] ?? 0) + 1;
    }

    return ReplayHigherAgentBehaviorPass(
      environmentId: environment.environmentId,
      replayYear: environment.replayYear,
      runContext: environment.runContext,
      actionCountsByType: _sortedCounts(actionCountsByType),
      actionCountsByLevel: _sortedCounts(actionCountsByLevel),
      monthCounts: _sortedCounts(monthCounts),
      actions: actions,
      metadata: <String, dynamic>{
        'namespace': environment.isolationBoundary.environmentNamespace,
        'replayOnly': true,
        'appSurfacePolicy': environment.isolationBoundary.appSurfacePolicy.name,
        'cityCode': environment.metadata['cityCode']?.toString(),
        'citySlug': environment.metadata['citySlug']?.toString(),
        'cityDisplayName': environment.metadata['cityDisplayName']?.toString(),
      },
    );
  }

  List<ReplayHigherAgentAction> _actionsForRollupAndMonth({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayHigherAgentRollup rollup,
    required String monthKey,
    ReplayActorProfile? actor,
  }) {
    final cityDisplayName =
        environment.metadata['cityDisplayName']?.toString() ?? 'replay city';
    final cautionScore = _cautionScore(rollup);
    final actions = <ReplayHigherAgentAction>[];

    if (rollup.level == ReplayHigherAgentLevel.personal) {
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: ReplayHigherAgentActionType.personalPlanDailyCircuit,
          reason:
              'Representative personal agent should plan a replay-only $cityDisplayName circuit using bounded locality and place truth.',
          guidance: <String>[
            'Prefer replay-world destinations that match the actor profile.',
            'Do not bypass locality or city guidance.',
          ],
          cautionScore: cautionScore,
        ),
      );
      if ((actor?.preferredEntityTypes.contains('community') ?? false) ||
          (rollup.entityTypeCounts['community'] ?? 0) > 0) {
        actions.add(
          _buildAction(
            environment: environment,
            rollup: rollup,
            monthKey: monthKey,
            actionType:
                ReplayHigherAgentActionType.personalJoinCommunityPattern,
            reason:
                'Representative personal agent should follow recurring community and organization patterns in the replay year.',
            guidance: const <String>[
              'Favor recurring community anchors before one-off novelty.',
            ],
            cautionScore: cautionScore,
          ),
        );
      }
      if ((actor?.householdType.contains('family') ?? false) ||
          actor?.populationRole ==
              SimulatedPopulationRole.dependentMobilityOnly) {
        actions.add(
          _buildAction(
            environment: environment,
            rollup: rollup,
            monthKey: monthKey,
            actionType:
                ReplayHigherAgentActionType.personalDeferForHouseholdFriction,
            reason:
                'Representative household pressure should defer some activity windows in the replay year.',
            guidance: const <String>[
              'Preserve household timing and dependent mobility pressure.',
            ],
            cautionScore: cautionScore,
          ),
        );
      }
      if (cautionScore >= 0.25) {
        actions.add(
          _buildAction(
            environment: environment,
            rollup: rollup,
            monthKey: monthKey,
            actionType:
                ReplayHigherAgentActionType.escalateContradictionToLocality,
            reason:
                'Representative personal agent detected bounded contradiction and should escalate to locality review.',
            guidance: const <String>[
              'Do not promote contradiction directly to live truth.',
            ],
            cautionScore: cautionScore,
          ),
        );
      }
    } else if (rollup.level == ReplayHigherAgentLevel.locality) {
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: cautionScore >= 0.4
              ? ReplayHigherAgentActionType.escalateLocalityReview
              : ReplayHigherAgentActionType.stabilizeLocalityTruth,
          reason: cautionScore >= 0.4
              ? 'Locality rollup contains caution-bearing replay nodes that require bounded review.'
              : 'Locality rollup is stable enough to continue as replay truth.',
          guidance: <String>[
            if (cautionScore >= 0.4)
              'Keep this locality inside replay-only review and do not promote directly to live truth.'
            else
              'Allow this locality to remain a stable replay prior for downstream personal-agent guidance.',
          ],
          cautionScore: cautionScore,
        ),
      );
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType:
              ReplayHigherAgentActionType.handoffLocalityDigestToPersonalAgents,
          reason:
              'Locality digest should be available to replay-world personal agents as bounded context, not direct user speech.',
          guidance: <String>[
            'Provide only locality-bounded summaries downward.',
            'Do not allow higher-agent direct human speech.',
          ],
          cautionScore: cautionScore,
        ),
      );
    } else if (rollup.level == ReplayHigherAgentLevel.city) {
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: ReplayHigherAgentActionType.aggregateCitySignal,
          reason:
              'City agent should aggregate locality signals into one $cityDisplayName replay-city view.',
          guidance: const <String>[
            'Aggregate locality trends upward.',
            'Return only bounded city-level guidance downward.',
          ],
          cautionScore: cautionScore,
        ),
      );
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: ReplayHigherAgentActionType.routeCityGuidanceDownward,
          reason:
              'City agent should return bounded $cityDisplayName-wide guidance back to local and personal replay agents.',
          guidance: const <String>[
            'Keep city guidance bounded and replay-only.',
          ],
          cautionScore: cautionScore,
        ),
      );
    } else if (rollup.level == ReplayHigherAgentLevel.topLevelReality) {
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: ReplayHigherAgentActionType.retainAsReplayPriorOnly,
          reason:
              'Top-level reality should remain replay prior only and never bypass replay isolation.',
          guidance: const <String>[
            'Retain top-level synthesis as replay-only prior.',
          ],
          cautionScore: cautionScore,
        ),
      );
      actions.add(
        _buildAction(
          environment: environment,
          rollup: rollup,
          monthKey: monthKey,
          actionType: ReplayHigherAgentActionType.auditContradictionSurface,
          reason:
              'Top-level reality should inspect contradiction surfaces before any future multi-year branching.',
          guidance: const <String>[
            'Keep contradiction audit inside admin-visible replay inspection only.',
          ],
          cautionScore: cautionScore,
        ),
      );
    }

    return actions;
  }

  ReplayHigherAgentAction _buildAction({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayHigherAgentRollup rollup,
    required String monthKey,
    required ReplayHigherAgentActionType actionType,
    required String reason,
    required List<String> guidance,
    required double cautionScore,
  }) {
    return ReplayHigherAgentAction(
      actionId:
          '${environment.environmentId}:${rollup.agentId}:${actionType.name}:$monthKey',
      environmentId: environment.environmentId,
      level: rollup.level,
      agentId: rollup.agentId,
      actionType: actionType,
      monthKey: monthKey,
      localityAnchor: rollup.localityAnchor,
      targetNodeIds: rollup.nodeIds,
      reason: reason,
      guidance: guidance,
      cautionScore: cautionScore,
      metadata: <String, dynamic>{
        'replayOnly': true,
        'namespace': environment.isolationBoundary.environmentNamespace,
        'cityCode': environment.metadata['cityCode']?.toString(),
        'citySlug': environment.metadata['citySlug']?.toString(),
        'cityDisplayName': environment.metadata['cityDisplayName']?.toString(),
      },
    );
  }

  double _cautionScore(ReplayHigherAgentRollup rollup) {
    final totalNodes = rollup.nodeCount == 0 ? 1 : rollup.nodeCount;
    final cautionCount =
        (rollup.forecastDispositionCounts['admittedWithCaution'] ?? 0) +
            (rollup.forecastDispositionCounts['downgraded'] ?? 0) +
            (rollup.forecastDispositionCounts['blocked'] ?? 0);
    return (cautionCount / totalNodes).clamp(0.0, 1.0);
  }

  Map<String, int> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        if (countOrder != 0) {
          return countOrder;
        }
        return left.key.compareTo(right.key);
      });
    return Map<String, int>.fromEntries(entries);
  }
}
