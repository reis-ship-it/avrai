import 'dart:math' as math;

import 'package:avrai_core/models/personality_knot.dart';

/// Service responsible for executing lightning-fast mathematical comparisons
/// between two [PersonalityKnot] profiles locally on the device.
/// 
/// Part of the v0.1 Reality Check pivot. This completely replaces the need
/// to run expensive local LLM inference during a 5-second BLE passing window.
/// It operates purely on the topological invariants (the "DNA") of the knot.
class DeterministicMatcherService {
  /// Calculates a compatibility score [0.0, 1.0] between two knots.
  /// 
  /// 1.0 = mathematically identical topology
  /// 0.0 = completely disjoint topology
  /// 
  /// This operation takes fractions of a millisecond and uses virtually zero battery.
  double calculateVibeMatch(PersonalityKnot a, PersonalityKnot b) {
    final invA = a.invariants;
    final invB = b.invariants;

    // Weight allocations for different topological comparisons
    const double scalarWeight = 0.3;     // Crossing number, writhe, etc.
    const double jonesWeight = 0.35;     // Jones polynomial similarity
    const double alexanderWeight = 0.35; // Alexander polynomial similarity

    final scalarSim = _calculateScalarSimilarity(invA, invB);
    final jonesSim = _calculatePolynomialSimilarity(invA.jonesPolynomial, invB.jonesPolynomial);
    final alexanderSim = _calculatePolynomialSimilarity(invA.alexanderPolynomial, invB.alexanderPolynomial);

    return (scalarSim * scalarWeight) + 
           (jonesSim * jonesWeight) + 
           (alexanderSim * alexanderWeight);
  }

  /// Calculates a normalized similarity [0.0, 1.0] between simple scalar invariants.
  double _calculateScalarSimilarity(KnotInvariants a, KnotInvariants b) {
    // Determine distances
    final crossingDist = (a.crossingNumber - b.crossingNumber).abs();
    final writheDist = (a.writhe - b.writhe).abs();
    final signatureDist = (a.signature - b.signature).abs();

    // Max theoretical distances based on system bounds (to normalize)
    // Assume max crossings ~20, max writhe ~20, max signature ~10
    const maxCrossingDist = 20.0;
    const maxWritheDist = 20.0;
    const maxSignatureDist = 10.0;

    final crossingSim = math.max(0.0, 1.0 - (crossingDist / maxCrossingDist));
    final writheSim = math.max(0.0, 1.0 - (writheDist / maxWritheDist));
    final signatureSim = math.max(0.0, 1.0 - (signatureDist / maxSignatureDist));

    return (crossingSim * 0.4) + (writheSim * 0.4) + (signatureSim * 0.2);
  }

  /// Calculates Cosine Similarity between two polynomial coefficient arrays.
  /// Result is mapped from [-1.0, 1.0] to [0.0, 1.0].
  double _calculatePolynomialSimilarity(List<double> polyA, List<double> polyB) {
    if (polyA.isEmpty && polyB.isEmpty) return 1.0;
    if (polyA.isEmpty || polyB.isEmpty) return 0.0;

    // Pad arrays to the same length with zeroes
    final maxLength = math.max(polyA.length, polyB.length);
    final vecA = List<double>.filled(maxLength, 0.0);
    final vecB = List<double>.filled(maxLength, 0.0);

    for (int i = 0; i < polyA.length; i++) {
      vecA[i] = polyA[i];
    }
    for (int i = 0; i < polyB.length; i++) {
      vecB[i] = polyB[i];
    }

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < maxLength; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    final cosineSimilarity = dotProduct / (math.sqrt(normA) * math.sqrt(normB));
    
    // Map cosine similarity from [-1.0, 1.0] to [0.0, 1.0]
    return (cosineSimilarity + 1.0) / 2.0;
  }
}
