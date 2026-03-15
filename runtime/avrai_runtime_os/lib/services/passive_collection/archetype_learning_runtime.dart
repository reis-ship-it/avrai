import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/archetype_pattern_learner.dart';

/// Runtime-owned facade for archetype learning.
///
/// Apps should depend on this runtime surface instead of importing the knot
/// package directly. The runtime remains free to use knot-backed math internals.
abstract class ArchetypeLearningRuntime {
  void recordPositiveEncounter(PersonalityKnot knot);

  List<RuntimeLearnedArchetype> deriveArchetypes();

  double calculateLocationAffinity(
    List<RuntimeLearnedArchetype> userArchetypes,
    KnotInvariants locationVibeKnot,
  );
}

class RuntimeLearnedArchetype {
  const RuntimeLearnedArchetype({
    required this.label,
    required this.avgCrossingNumber,
    required this.avgWrithe,
    required this.baseJonesPolynomial,
    required this.confidenceWeight,
  });

  final String label;
  final double avgCrossingNumber;
  final double avgWrithe;
  final List<double> baseJonesPolynomial;
  final double confidenceWeight;
}

class KnotBackedArchetypeLearningRuntime implements ArchetypeLearningRuntime {
  KnotBackedArchetypeLearningRuntime({
    ArchetypePatternLearner? learner,
  }) : _learner = learner ?? ArchetypePatternLearner();

  final ArchetypePatternLearner _learner;

  @override
  void recordPositiveEncounter(PersonalityKnot knot) {
    _learner.recordPositiveEncounter(knot);
  }

  @override
  List<RuntimeLearnedArchetype> deriveArchetypes() {
    return _learner
        .deriveArchetypes()
        .map(
          (archetype) => RuntimeLearnedArchetype(
            label: archetype.label,
            avgCrossingNumber: archetype.avgCrossingNumber,
            avgWrithe: archetype.avgWrithe,
            baseJonesPolynomial: archetype.baseJonesPolynomial,
            confidenceWeight: archetype.confidenceWeight,
          ),
        )
        .toList(growable: false);
  }

  @override
  double calculateLocationAffinity(
    List<RuntimeLearnedArchetype> userArchetypes,
    KnotInvariants locationVibeKnot,
  ) {
    return _learner.calculateLocationAffinity(
      userArchetypes
          .map(
            (archetype) => LearnedArchetype(
              label: archetype.label,
              avgCrossingNumber: archetype.avgCrossingNumber,
              avgWrithe: archetype.avgWrithe,
              baseJonesPolynomial: archetype.baseJonesPolynomial,
              confidenceWeight: archetype.confidenceWeight,
            ),
          )
          .toList(growable: false),
      locationVibeKnot,
    );
  }
}
