import 'pathfinding_service.dart';
import 'swarm_map_environment.dart';
import '../simulated_human.dart';

import '../federated_knowledge_exchange.dart';

/// Service to find "Interstitial Gaps" - spaces in a human's routine
/// where they are open to serendipitous suggestions (e.g. along a commute).
class InterstitialGapFinder {
  final SwarmMapEnvironment environment;
  final PathfindingService pathfinder;
  final FederatedKnowledgeExchange knowledgeExchange;

  InterstitialGapFinder({
    required this.environment,
    required this.pathfinder,
    required this.knowledgeExchange,
  });

  /// Finds POIs that are highly relevant along a given route (e.g., commute).
  ///
  /// This optimizes for "Routine Enhancement" - finding things that add slightly
  /// to the existing journey without fundamentally breaking the schedule.
  List<PointOfInterest> findEnhancementsAlongRoute(
    SimulatedHuman human,
    RoutePath route, {
    double maxDeviationKm = 1.0,
    int limit = 5,
  }) {
    // Determine what categories make sense for an interstitial gap
    // based on the time of day / state.
    // E.g., morning commute = coffee, breakfast. Evening = gym, bar, dinner.
    Set<POICategory> relevantCategories =
        getRelevantCategories(human.currentState);

    // Get all POIs along the route
    final candidates = environment.findPOIsAlongRoute(
      route.allPoints,
      maxDistanceKm: maxDeviationKm,
    );

    // Filter and score candidates
    final scoredCandidates = <_ScoredPOI>[];
    for (final poi in candidates) {
      if (!relevantCategories.contains(poi.category)) continue;

      // Ensure it's financially viable
      if (poi.cost > human.finances.discretionaryBudget) continue;

      // Calculate a score
      // Higher quality is better. Swarm knowledge boosts quality.
      double perceivedQuality =
          poi.baseQuality + knowledgeExchange.getSwarmConfidenceBoost(poi.id);

      // Closer to the route is better (lower friction).
      double minDistanceToRoute = double.maxFinite;
      for (final point in route.allPoints) {
        final dist = point.distanceTo(poi.location);
        if (dist < minDistanceToRoute) {
          minDistanceToRoute = dist;
        }
      }

      // Base friction from distance
      double friction = minDistanceToRoute * 0.5; // 1km = 0.5 friction penalty

      // Financial friction
      double financialFriction = 0;
      if (poi.cost > human.finances.discretionaryBudget * 0.8) {
        financialFriction =
            (poi.cost - (human.finances.discretionaryBudget * 0.8)) *
                human.finances.priceSensitivity;
      }
      friction += financialFriction;

      // Score = Quality - Friction
      // If friction > human's activation energy, they won't do it.
      if (friction > human.currentActivationEnergy) continue;

      final score = perceivedQuality - friction;
      if (score > 0) {
        scoredCandidates.add(_ScoredPOI(poi, score, friction));
      }
    }

    // Sort by score descending
    scoredCandidates.sort((a, b) => b.score.compareTo(a.score));

    // Return the top N
    return scoredCandidates.take(limit).map((e) => e.poi).toList();
  }

  Set<POICategory> getRelevantCategories(RoutineState state) {
    switch (state) {
      case RoutineState.commuting:
        return {
          POICategory.cafe,
          POICategory.park,
        };
      case RoutineState.freeTime:
        return {
          POICategory.restaurant,
          POICategory.bar,
          POICategory.park,
          POICategory.gym,
          POICategory.retail,
        };
      case RoutineState.working:
        return {
          POICategory.cafe, // Lunch/coffee breaks
          POICategory.restaurant,
        };
      case RoutineState.home:
      case RoutineState.sleeping:
        return {}; // Not looking for gaps when home/asleep
    }
  }
}

class _ScoredPOI {
  final PointOfInterest poi;
  final double score;
  final double estimatedFriction;

  _ScoredPOI(this.poi, this.score, this.estimatedFriction);
}
