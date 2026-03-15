import 'package:avrai_core/avra_core.dart';

class BhamReplayActionExplanationService {
  const BhamReplayActionExplanationService();

  List<ReplayActionExplanation> buildExplanations({
    required ReplayVirtualWorldEnvironment environment,
    required ReplayPopulationProfile populationProfile,
    required ReplayPlaceGraph placeGraph,
    required ReplayHigherAgentBehaviorPass behaviorPass,
    ReplayDailyBehaviorBatch? dailyBehaviorBatch,
  }) {
    final actorById = <String, ReplayActorProfile>{
      for (final actor in populationProfile.actors) actor.actorId: actor,
    };
    final nodeById = <String, ReplayVirtualWorldNode>{
      for (final node in environment.nodes) node.nodeId: node,
    };
    final explanations = <ReplayActionExplanation>[];
    for (final action in behaviorPass.actions) {
      final actor = actorById[action.agentId];
      final supportingSourceRefs = <String>{};
      for (final nodeId in action.targetNodeIds) {
        supportingSourceRefs.addAll(nodeById[nodeId]?.sourceRefs ?? const <String>[]);
      }
      final kernelLanes = _kernelLanesFor(action.actionType);
      final explanation = _explanationFor(
        action: action,
        actor: actor,
        placeGraph: placeGraph,
      );
      explanations.add(
        ReplayActionExplanation(
          actionId: action.actionId,
          actorOrAgentId: action.agentId,
          kernelLanes: kernelLanes,
          supportingSourceRefs: supportingSourceRefs.toList()..sort(),
          explanation: explanation,
          localityAnchor: action.localityAnchor ?? actor?.localityAnchor ?? 'unanchored',
          metadata: <String, dynamic>{
            'level': action.level.name,
            'targetCount': action.targetNodeIds.length,
          },
        ),
      );
    }
    if (dailyBehaviorBatch != null) {
      for (final action in dailyBehaviorBatch.actions.take(600)) {
        explanations.add(
          ReplayActionExplanation(
            actionId: action.actionId,
            actorOrAgentId: action.actorId,
            kernelLanes: action.kernelLanes,
            supportingSourceRefs: action.destinationChoice.sourceRefs,
            explanation:
                'Replay actor `${action.actorId}` chooses `${action.destinationChoice.entityType}` in `${action.localityAnchor}` because `${action.destinationChoice.reason}`.',
            localityAnchor: action.localityAnchor,
            metadata: <String, dynamic>{
              'level': 'actor',
              'actionType': action.actionType,
              'sampledFromDailyBehavior': true,
              'status': action.status,
            },
          ),
        );
      }
    }
    return explanations;
  }

  List<String> _kernelLanesFor(ReplayHigherAgentActionType actionType) {
    return switch (actionType) {
      ReplayHigherAgentActionType.personalPlanDailyCircuit =>
        const <String>['when', 'where', 'who', 'how'],
      ReplayHigherAgentActionType.personalJoinCommunityPattern =>
        const <String>['who', 'where', 'what', 'how'],
      ReplayHigherAgentActionType.personalDeferForHouseholdFriction =>
        const <String>['who', 'when', 'how'],
      ReplayHigherAgentActionType.escalateContradictionToLocality =>
        const <String>['why', 'governance', 'higher_agent_truth'],
      ReplayHigherAgentActionType.stabilizeLocalityTruth =>
        const <String>['where', 'why', 'governance'],
      ReplayHigherAgentActionType.escalateLocalityReview =>
        const <String>['where', 'why', 'governance'],
      ReplayHigherAgentActionType.handoffLocalityDigestToPersonalAgents =>
        const <String>['higher_agent_truth', 'who', 'how'],
      ReplayHigherAgentActionType.aggregateCitySignal =>
        const <String>['higher_agent_truth', 'what', 'why'],
      ReplayHigherAgentActionType.routeCityGuidanceDownward =>
        const <String>['higher_agent_truth', 'how', 'who'],
      ReplayHigherAgentActionType.retainAsReplayPriorOnly =>
        const <String>['governance', 'forecast', 'why'],
      ReplayHigherAgentActionType.auditContradictionSurface =>
        const <String>['governance', 'why', 'forecast'],
    };
  }

  String _explanationFor({
    required ReplayHigherAgentAction action,
    required ReplayActorProfile? actor,
    required ReplayPlaceGraph placeGraph,
  }) {
    final locality = action.localityAnchor ?? actor?.localityAnchor ?? 'unanchored';
    final venueCount = placeGraph.venueProfiles
        .where((profile) => profile.localityAnchor == locality)
        .length;
    final communityCount = placeGraph.communityProfiles
        .where((profile) => profile.localityAnchor == locality)
        .length;
    return switch (action.actionType) {
      ReplayHigherAgentActionType.personalPlanDailyCircuit =>
        'Representative personal agent `${action.agentId}` plans a Birmingham-local circuit in `$locality` using replay-only place truth ($venueCount venues, $communityCount communities).',
      ReplayHigherAgentActionType.personalJoinCommunityPattern =>
        'Representative personal agent `${action.agentId}` prefers community-linked participation in `$locality` because replay truth shows recurring group anchors there.',
      ReplayHigherAgentActionType.personalDeferForHouseholdFriction =>
        'Representative personal agent `${action.agentId}` defers part of its activity window because household and dependent-mobility pressure are modeled in this locality.',
      ReplayHigherAgentActionType.escalateContradictionToLocality =>
        'Representative personal agent `${action.agentId}` raises a contradiction to locality review instead of promoting uncertain truth directly.',
      ReplayHigherAgentActionType.stabilizeLocalityTruth =>
        'Locality agent `${action.agentId}` keeps `$locality` stable as replay truth because caution load remains acceptable.',
      ReplayHigherAgentActionType.escalateLocalityReview =>
        'Locality agent `${action.agentId}` escalates `$locality` for bounded review because replay caution load is elevated.',
      ReplayHigherAgentActionType.handoffLocalityDigestToPersonalAgents =>
        'Locality agent `${action.agentId}` hands bounded locality context downward so personal agents can act without bypassing governance.',
      ReplayHigherAgentActionType.aggregateCitySignal =>
        'Birmingham city agent aggregates locality signals into one replay-year city view before sending bounded guidance back down.',
      ReplayHigherAgentActionType.routeCityGuidanceDownward =>
        'Birmingham city agent routes city-level guidance back to local and personal agents without direct human-facing speech.',
      ReplayHigherAgentActionType.retainAsReplayPriorOnly =>
        'Top-level reality agent keeps this synthesis as replay prior only, preventing overconfident cross-context promotion.',
      ReplayHigherAgentActionType.auditContradictionSurface =>
        'Top-level reality agent audits contradiction surfaces so this truth-year can become a safe Monte Carlo base later.',
    };
  }
}
