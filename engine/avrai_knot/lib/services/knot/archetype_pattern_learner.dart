import 'dart:math' as math;
import 'dart:developer' as developer;

import 'package:avrai_core/models/personality_knot.dart';

/// Represents a topological pattern (Archetype) derived from successful past interactions.
class LearnedArchetype {
  final String label;

  // The average/centroid mathematical properties of people the user vibes with
  final double avgCrossingNumber;
  final double avgWrithe;
  final List<double> baseJonesPolynomial;

  // How strong this signal is (e.g. based on number of positive interactions)
  final double confidenceWeight;

  LearnedArchetype({
    required this.label,
    required this.avgCrossingNumber,
    required this.avgWrithe,
    required this.baseJonesPolynomial,
    required this.confidenceWeight,
  });
}

/// Service that analyzes recent physical encounters (e.g. from DwellEvents)
/// and extracts topological patterns to bias future recommendations.
///
/// Part of the v0.1 Reality Check pivot (Spike 6 addition).
class ArchetypePatternLearner {
  static const String _logName = 'ArchetypePatternLearner';

  /// In a real scenario, this would be fetched from the local SQLite db
  /// where we logged explicit positive user actions (e.g. hitting "Sync" on a card).
  final List<PersonalityKnot> _positiveEncounters = [];

  void recordPositiveEncounter(PersonalityKnot knot) {
    _positiveEncounters.add(knot);
    developer.log(
      'Recorded positive encounter for archetype learning.',
      name: _logName,
    );
  }

  /// Runs during the Nightly Batch Process to update the user's known archetypes.
  List<LearnedArchetype> deriveArchetypes() {
    if (_positiveEncounters.isEmpty) {
      return [];
    }

    // A very basic clustering algorithm to find the "average" knot
    // the user tends to interact with.
    double sumCrossings = 0;
    double sumWrithe = 0;

    // We assume the user tends to like a specific topological complexity
    for (final knot in _positiveEncounters) {
      sumCrossings += knot.invariants.crossingNumber;
      sumWrithe += knot.invariants.writhe;
    }

    final avgCrossings = sumCrossings / _positiveEncounters.length;
    final avgWrithe = sumWrithe / _positiveEncounters.length;

    // We can confidently say the user resonates with this topological "shape"
    final derivedArchetype = LearnedArchetype(
      label: 'Primary Resonance Pattern',
      avgCrossingNumber: avgCrossings,
      avgWrithe: avgWrithe,
      baseJonesPolynomial: _positiveEncounters
          .first
          .invariants
          .jonesPolynomial, // Simplified for Spike
      confidenceWeight: math.min(
        1.0,
        _positiveEncounters.length * 0.1,
      ), // Capped at 1.0
    );

    developer.log(
      'Derived new Archetype: avg crossings ${avgCrossings.toStringAsFixed(1)}, weight: ${derivedArchetype.confidenceWeight}',
      name: _logName,
    );

    return [derivedArchetype];
  }

  /// Used by the Daily Serendipity Drop generator to weight a potential Spot/Event
  /// based on whether the *other* people who go there match the user's Learned Archetypes.
  double calculateLocationAffinity(
    List<LearnedArchetype> userArchetypes,
    KnotInvariants locationVibeKnot,
  ) {
    if (userArchetypes.isEmpty) return 0.5; // Neutral baseline

    double maxAffinity = 0.0;

    for (final archetype in userArchetypes) {
      // Calculate how close the location's average patron knot is to the user's archetype
      final crossDist =
          (archetype.avgCrossingNumber - locationVibeKnot.crossingNumber).abs();
      final writheDist = (archetype.avgWrithe - locationVibeKnot.writhe).abs();

      // Normalize (assuming max crossing diff of ~20)
      final crossSim = math.max(0.0, 1.0 - (crossDist / 20.0));
      final writheSim = math.max(0.0, 1.0 - (writheDist / 20.0));

      final affinity =
          ((crossSim + writheSim) / 2.0) * archetype.confidenceWeight;
      if (affinity > maxAffinity) {
        maxAffinity = affinity;
      }
    }

    return maxAffinity;
  }
}
