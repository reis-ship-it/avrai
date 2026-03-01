import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../models/models.dart';

/// String Theory Possibility Engine
///
/// Generates multiple possible future personality states ("possibility space")
/// and scores candidates against weighted possibilities.
///
/// This implements "string theory-inspired" matching where we:
/// 1. Predict multiple possible future states
/// 2. Assign probabilities to each state
/// 3. Score candidates against ALL possibilities weighted by probability
/// 4. Collapse the superposition when we observe user behavior
///
/// Part of Phase 6: Perpetual List Orchestrator

class StringTheoryPossibilityEngine {
  static const String _logName = 'StringTheoryPossibilityEngine';

  /// Default number of possibility branches to generate
  static const int defaultBranchCount = 5;

  StringTheoryPossibilityEngine();

  /// Generate possibility space for a user
  ///
  /// Creates multiple predicted future states based on current personality
  /// and context signals (AI2AI insights, behavioral patterns).
  ///
  /// [context] - Current list generation context
  /// [branchCount] - Number of possibilities to generate (default: 5)
  ///
  /// Returns list of PossibilityState with normalized probabilities
  Future<List<PossibilityState>> generatePossibilitySpace({
    required ListGenerationContext context,
    int branchCount = defaultBranchCount,
  }) async {
    developer.log(
      'Generating possibility space with $branchCount branches',
      name: _logName,
    );

    final currentDimensions = context.personality.dimensions;
    final possibilities = <PossibilityState>[];

    // 1. Stable trajectory (current state continues)
    possibilities.add(_createStableState(currentDimensions));

    // 2. Growth trajectories (dimensions that might increase)
    final growthStates = _createGrowthStates(
      currentDimensions,
      context.networkInsights,
      context.visitPatterns,
    );
    possibilities.addAll(growthStates.take(2)); // Max 2 growth states

    // 3. Network-influenced trajectories (AI2AI learning)
    if (context.networkInsights.isNotEmpty) {
      possibilities.add(_createNetworkInfluencedState(
        currentDimensions,
        context.networkInsights,
      ));
    }

    // 4. Consolidation trajectory (settling into current patterns)
    if (possibilities.length < branchCount) {
      possibilities.add(_createConsolidationState(
        currentDimensions,
        context.visitPatterns,
      ));
    }

    // Ensure we have exactly branchCount possibilities
    while (possibilities.length < branchCount) {
      possibilities
          .add(_createVariationState(currentDimensions, possibilities.length));
    }
    if (possibilities.length > branchCount) {
      possibilities.removeRange(branchCount, possibilities.length);
    }

    // Normalize probabilities to sum to 1.0
    _normalizeProbabilities(possibilities);

    developer.log(
      'Generated ${possibilities.length} possibilities',
      name: _logName,
    );

    return possibilities;
  }

  /// Score a candidate across all possibilities
  ///
  /// [candidateDimensions] - Personality dimensions of the candidate (place/list)
  /// [possibilities] - Possibility space to score against
  ///
  /// Returns weighted score (0.0 to 1.0)
  Future<double> scoreAcrossPossibilities({
    required Map<String, double> candidateDimensions,
    required List<PossibilityState> possibilities,
  }) async {
    double weightedScore = 0.0;

    for (final possibility in possibilities) {
      // Calculate compatibility for this possibility
      final compatibility = _calculateDimensionCompatibility(
        possibility.dimensions,
        candidateDimensions,
      );

      // Weight by normalized probability
      weightedScore += compatibility * possibility.normalizedProbability;
    }

    return weightedScore.clamp(0.0, 1.0);
  }

  /// Collapse the possibility space based on observed user behavior
  ///
  /// When a user interacts with a list, we update our understanding
  /// of which possibility they're actualizing.
  ///
  /// [interaction] - The observed interaction
  /// [previousPossibilities] - The possibility space that was used
  ///
  /// Returns collapse result with dimension updates
  Future<PossibilityCollapseResult> collapseFromObservation({
    required ListInteraction interaction,
    required List<PossibilityState> previousPossibilities,
  }) async {
    developer.log(
      'Collapsing possibility space from observation: ${interaction.type}',
      name: _logName,
    );

    // Convert interaction to observation dimensions
    final observationDimensions =
        _interactionToObservationDimensions(interaction);

    // Find which possibility best matches the observation
    PossibilityState? bestMatch;
    double bestScore = 0.0;

    for (final possibility in previousPossibilities) {
      final score = _calculateDimensionCompatibility(
        possibility.dimensions,
        observationDimensions,
      );

      if (score > bestScore) {
        bestScore = score;
        bestMatch = possibility;
      }
    }

    if (bestMatch == null) {
      // Fallback to first possibility
      bestMatch = previousPossibilities.first;
      bestScore = 0.5;
    }

    // Calculate dimension updates based on collapse
    final dimensionUpdates = _calculateDimensionUpdates(
      observationDimensions,
      bestMatch.dimensions,
      bestScore,
    );

    // Check if this was surprising (low probability possibility realized)
    final wasSurprising = bestMatch.normalizedProbability < 0.15;

    return PossibilityCollapseResult(
      realizedPossibility: bestMatch,
      matchScore: bestScore,
      dimensionUpdates: dimensionUpdates,
      wasSurprising: wasSurprising,
    );
  }

  /// Create a stable state (current dimensions with minimal change)
  PossibilityState _createStableState(Map<String, double> current) {
    return PossibilityState(
      id: const Uuid().v4(),
      dimensions: Map.from(current),
      probability: 0.35, // Highest probability - status quo
      trajectory: TrajectoryInfo.stable(),
      confidenceBounds: ConfidenceInterval.high(),
    );
  }

  /// Create growth states based on behavioral signals
  List<PossibilityState> _createGrowthStates(
    Map<String, double> current,
    List<AI2AIInsightSummary> insights,
    List<VisitPattern> patterns,
  ) {
    final states = <PossibilityState>[];

    // Find dimensions with growth potential
    final growthDimensions = _identifyGrowthDimensions(current, patterns);

    for (final dimension in growthDimensions.take(2)) {
      final newDimensions = Map<String, double>.from(current);
      final currentValue = current[dimension] ?? 0.5;

      // Grow toward 0.7-0.8 range if below, or maintain if already high
      if (currentValue < 0.7) {
        newDimensions[dimension] = (currentValue + 0.15).clamp(0.0, 1.0);
      }

      states.add(PossibilityState(
        id: const Uuid().v4(),
        dimensions: newDimensions,
        probability: 0.20,
        trajectory: TrajectoryInfo.growth(
          dimension: dimension,
          momentum: 0.6,
        ),
        confidenceBounds: ConfidenceInterval.moderate(),
      ));
    }

    return states;
  }

  /// Create a network-influenced state based on AI2AI insights
  PossibilityState _createNetworkInfluencedState(
    Map<String, double> current,
    List<AI2AIInsightSummary> insights,
  ) {
    final newDimensions = Map<String, double>.from(current);

    // Apply small nudges based on high-quality insights
    final highQualityInsights = insights.where((i) => i.isHighQuality);

    // Apply network influence (small adjustments)
    // This would be enhanced with actual insight dimension data
    if (highQualityInsights.isNotEmpty) {
      // Small adjustment to exploration based on network
      final exploration = newDimensions['exploration_eagerness'] ?? 0.5;
      newDimensions['exploration_eagerness'] =
          (exploration + 0.05).clamp(0.0, 1.0);
    }

    return PossibilityState(
      id: const Uuid().v4(),
      dimensions: newDimensions,
      probability: 0.15,
      trajectory: TrajectoryInfo(
        type: TrajectoryType.networkInfluenced,
        direction: TrajectoryDirection.increasing,
        momentum: 0.4,
        description: 'AI2AI network influence',
      ),
      confidenceBounds: ConfidenceInterval.moderate(),
    );
  }

  /// Create a consolidation state (settling into patterns)
  PossibilityState _createConsolidationState(
    Map<String, double> current,
    List<VisitPattern> patterns,
  ) {
    final newDimensions = Map<String, double>.from(current);

    // Move toward behavioral patterns
    if (patterns.isNotEmpty) {
      // Calculate how much user explores vs returns to favorites
      final repeatVisits = patterns.where((p) => p.isRepeatVisit).length;
      final repeatRatio = repeatVisits / patterns.length;

      // Adjust novelty_seeking based on actual behavior
      newDimensions['novelty_seeking'] = repeatRatio < 0.5 ? 0.7 : 0.3;
    }

    return PossibilityState(
      id: const Uuid().v4(),
      dimensions: newDimensions,
      probability: 0.15,
      trajectory: TrajectoryInfo(
        type: TrajectoryType.consolidation,
        direction: TrajectoryDirection.neutral,
        momentum: 0.3,
        description: 'Consolidating behavioral patterns',
      ),
      confidenceBounds: ConfidenceInterval.high(),
    );
  }

  /// Create a variation state for additional diversity
  PossibilityState _createVariationState(
    Map<String, double> current,
    int index,
  ) {
    final newDimensions = Map<String, double>.from(current);
    final random = math.Random(index);

    // Small random variations to explore possibility space
    for (final key in newDimensions.keys.toList()) {
      final variation = (random.nextDouble() - 0.5) * 0.1; // ±5%
      newDimensions[key] = (newDimensions[key]! + variation).clamp(0.0, 1.0);
    }

    return PossibilityState(
      id: const Uuid().v4(),
      dimensions: newDimensions,
      probability: 0.10,
      trajectory: TrajectoryInfo(
        type: TrajectoryType.pivot,
        direction: TrajectoryDirection.oscillating,
        momentum: 0.2,
        description: 'Exploratory variation',
      ),
      confidenceBounds: ConfidenceInterval.low(),
    );
  }

  /// Identify dimensions with growth potential
  List<String> _identifyGrowthDimensions(
    Map<String, double> current,
    List<VisitPattern> patterns,
  ) {
    // Find dimensions that are below 0.6 but have behavioral signal
    final candidates = <String, double>{};

    for (final entry in current.entries) {
      if (entry.value < 0.6) {
        candidates[entry.key] = 0.6 - entry.value; // Growth potential
      }
    }

    // Sort by growth potential
    final sorted = candidates.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => e.key).toList();
  }

  /// Normalize probabilities to sum to 1.0
  void _normalizeProbabilities(List<PossibilityState> possibilities) {
    final totalProbability =
        possibilities.map((p) => p.probability).fold(0.0, (a, b) => a + b);

    for (final possibility in possibilities) {
      possibility.normalizedProbability = totalProbability > 0
          ? possibility.probability / totalProbability
          : 0.0;
    }
  }

  /// Calculate compatibility between two dimension sets
  double _calculateDimensionCompatibility(
    Map<String, double> a,
    Map<String, double> b,
  ) {
    if (a.isEmpty || b.isEmpty) return 0.5;

    double sumSimilarity = 0.0;
    int count = 0;

    for (final key in a.keys) {
      if (b.containsKey(key)) {
        final diff = (a[key]! - b[key]!).abs();
        sumSimilarity += 1.0 - diff; // Higher similarity for smaller diff
        count++;
      }
    }

    return count > 0 ? sumSimilarity / count : 0.5;
  }

  /// Convert interaction to observation dimensions
  Map<String, double> _interactionToObservationDimensions(
    ListInteraction interaction,
  ) {
    final dimensions = <String, double>{};

    // Infer dimensions from interaction type
    switch (interaction.type) {
      case ListInteractionType.saved:
        // User liked this - they value what was suggested
        dimensions['novelty_seeking'] = 0.6;
        dimensions['exploration_eagerness'] = 0.7;
        break;
      case ListInteractionType.dismissed:
        // User dismissed - opposite of what was suggested
        dimensions['novelty_seeking'] = 0.4;
        break;
      case ListInteractionType.placeVisited:
        // User actually visited - strong signal
        dimensions['exploration_eagerness'] = 0.8;
        dimensions['temporal_flexibility'] = 0.7;
        break;
      case ListInteractionType.viewed:
        // Just viewed - neutral signal
        dimensions['exploration_eagerness'] = 0.5;
        break;
      case ListInteractionType.shared:
        // Shared - high engagement
        dimensions['community_orientation'] = 0.8;
        dimensions['curation_tendency'] = 0.7;
        break;
      case ListInteractionType.addedToCollection:
        // Added to collection - values organization
        dimensions['curation_tendency'] = 0.7;
        break;
    }

    return dimensions;
  }

  /// Calculate dimension updates from collapse
  Map<String, double> _calculateDimensionUpdates(
    Map<String, double> observed,
    Map<String, double> predicted,
    double matchScore,
  ) {
    final updates = <String, double>{};

    // Only update if match score is high enough
    if (matchScore < 0.5) return updates;

    // Apply small updates toward observed values
    const learningRate = 0.05; // 5% adjustment

    for (final key in observed.keys) {
      if (predicted.containsKey(key)) {
        final diff = observed[key]! - predicted[key]!;
        updates[key] = diff * learningRate * matchScore;
      }
    }

    return updates;
  }
}
