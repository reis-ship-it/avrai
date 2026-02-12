// Integrated Knot Recommendation Engine
// 
// Integrates knot topology into recommendation and matching systems
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 6: Integrated Recommendations

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/compatibility_score.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';

/// Integrated recommendation engine combining quantum and knot topology
/// 
/// **Integration Formula:**
/// C_integrated = α·C_quantum + β·C_knot
/// 
/// Where:
/// - α = 0.7 (quantum weight)
/// - β = 0.3 (knot weight)
class IntegratedKnotRecommendationEngine {
  static const String _logName = 'IntegratedKnotRecommendationEngine';
  
  // Compatibility weights
  static const double _quantumWeight = 0.7;
  static const double _knotWeight = 0.3;

  final PersonalityKnotService _knotService;

  IntegratedKnotRecommendationEngine({
    required PersonalityKnotService knotService,
    CrossEntityCompatibilityService? compatibilityService,
  }) : _knotService = knotService;

  /// Calculate integrated compatibility using BOTH quantum + knot topology
  /// 
  /// **Formula:** C_integrated = α·C_quantum + β·C_knot
  /// 
  /// **Returns:** CompatibilityScore with quantum, knot, and combined scores
  Future<CompatibilityScore> calculateIntegratedCompatibility({
    required PersonalityProfile profileA,
    required PersonalityProfile profileB,
  }) async {
    developer.log(
      'Calculating integrated compatibility for profiles',
      name: _logName,
    );

    try {
      // Get knots (generate if not already present)
      final knotA = profileA.personalityKnot ??
          await _knotService.generateKnot(profileA);
      final knotB = profileB.personalityKnot ??
          await _knotService.generateKnot(profileB);

      // Calculate quantum compatibility (from PersonalityProfile)
      final quantumCompatibility = _calculateQuantumCompatibility(
        profileA,
        profileB,
      );

      // Calculate knot topological compatibility
      final knotCompatibility = _calculateKnotTopologicalCompatibility(
        knotA,
        knotB,
      );

      // Integrated score: α·C_quantum + β·C_knot
      final combined = (_quantumWeight * quantumCompatibility) +
          (_knotWeight * knotCompatibility);

      // Generate knot insights
      final knotInsights = _generateKnotInsights(knotA, knotB);

      developer.log(
        '✅ Integrated compatibility: $combined (quantum: $quantumCompatibility, knot: $knotCompatibility)',
        name: _logName,
      );

      return CompatibilityScore(
        quantum: quantumCompatibility,
        knot: knotCompatibility,
        combined: combined.clamp(0.0, 1.0),
        knotInsights: knotInsights,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate integrated compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate quantum compatibility from personality profiles
  /// 
  /// Uses dimension similarity as a proxy for quantum compatibility
  double _calculateQuantumCompatibility(
    PersonalityProfile profileA,
    PersonalityProfile profileB,
  ) {
    // Calculate dimension similarity
    final dimensionSimilarity = _calculateDimensionSimilarity(
      profileA.dimensions,
      profileB.dimensions,
    );

    // Calculate archetype similarity
    final archetypeSimilarity = profileA.archetype == profileB.archetype
        ? 1.0
        : 0.5;

    // Combined: 70% dimensions, 30% archetype
    return (dimensionSimilarity * 0.7 + archetypeSimilarity * 0.3)
        .clamp(0.0, 1.0);
  }

  /// Calculate dimension similarity between two profiles
  double _calculateDimensionSimilarity(
    Map<String, double> dimensionsA,
    Map<String, double> dimensionsB,
  ) {
    if (dimensionsA.isEmpty && dimensionsB.isEmpty) return 1.0;
    if (dimensionsA.isEmpty || dimensionsB.isEmpty) return 0.0;

    // Get all unique dimension keys
    final allKeys = <String>{
      ...dimensionsA.keys,
      ...dimensionsB.keys,
    };

    // Calculate cosine similarity
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (final key in allKeys) {
      final valueA = dimensionsA[key] ?? 0.0;
      final valueB = dimensionsB[key] ?? 0.0;
      dotProduct += valueA * valueB;
      normA += valueA * valueA;
      normB += valueB * valueB;
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return (dotProduct / (math.sqrt(normA) * math.sqrt(normB))).clamp(0.0, 1.0);
  }

  /// Calculate knot topological compatibility
  /// 
  /// Compares knot invariants to determine topological similarity
  double _calculateKnotTopologicalCompatibility(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Compare knot invariants
    final invariantSimilarity = _compareKnotInvariants(
      knotA.invariants,
      knotB.invariants,
    );

    // Compare crossing numbers (complexity similarity)
    final crossingA = knotA.invariants.crossingNumber;
    final crossingB = knotB.invariants.crossingNumber;
    final maxCrossing = math.max(crossingA, crossingB);
    final complexitySimilarity = maxCrossing > 0
        ? 1.0 - ((crossingA - crossingB).abs() / maxCrossing)
        : 1.0;

    // Weighted combination
    return (invariantSimilarity * 0.7 + complexitySimilarity * 0.3)
        .clamp(0.0, 1.0);
  }

  /// Compare knot invariants using all invariants
  /// 
  /// Uses comprehensive comparison of all invariants for accurate matching
  double _compareKnotInvariants(
    KnotInvariants invariantsA,
    KnotInvariants invariantsB,
  ) {
    // Calculate polynomial distance using Rust FFI
    final jonesDistance = polynomialDistance(
      coefficientsA: invariantsA.jonesPolynomial,
      coefficientsB: invariantsB.jonesPolynomial,
    );

    final alexanderDistance = polynomialDistance(
      coefficientsA: invariantsA.alexanderPolynomial,
      coefficientsB: invariantsB.alexanderPolynomial,
    );

    // Convert distances to similarities (exponential decay)
    final jonesSimilarity = math.exp(-jonesDistance).clamp(0.0, 1.0);
    final alexanderSimilarity = math.exp(-alexanderDistance).clamp(0.0, 1.0);
    
    // Compare integer invariants
    final crossingSimilarity = _integerSimilarity(
      invariantsA.crossingNumber,
      invariantsB.crossingNumber,
    );
    final writheSimilarity = _integerSimilarity(
      invariantsA.writhe,
      invariantsB.writhe,
    );
    final signatureSimilarity = _integerSimilarity(
      invariantsA.signature,
      invariantsB.signature,
    );
    final bridgeSimilarity = _integerSimilarity(
      invariantsA.bridgeNumber,
      invariantsB.bridgeNumber,
    );
    final braidIndexSimilarity = _integerSimilarity(
      invariantsA.braidIndex,
      invariantsB.braidIndex,
    );
    final determinantSimilarity = _integerSimilarity(
      invariantsA.determinant,
      invariantsB.determinant,
    );
    
    // Optional invariants
    final unknottingSimilarity = _optionalIntegerSimilarity(
      invariantsA.unknottingNumber,
      invariantsB.unknottingNumber,
    );
    final arfSimilarity = invariantsA.arfInvariant != null &&
            invariantsB.arfInvariant != null
        ? (invariantsA.arfInvariant == invariantsB.arfInvariant ? 1.0 : 0.0)
        : 0.5; // Partial if one is null
    final volumeSimilarity = _optionalDoubleSimilarity(
      invariantsA.hyperbolicVolume,
      invariantsB.hyperbolicVolume,
    );
    
    // HOMFLY polynomial similarity (if available)
    final homflySimilarity = invariantsA.homflyPolynomial != null &&
            invariantsB.homflyPolynomial != null
        ? math.exp(-polynomialDistance(
            coefficientsA: invariantsA.homflyPolynomial!,
            coefficientsB: invariantsB.homflyPolynomial!,
          )).clamp(0.0, 1.0)
        : 0.5; // Partial if one is null
    
    // Weighted combination (matching Rust weights)
    return (
      jonesSimilarity * 0.12 +
      alexanderSimilarity * 0.12 +
      crossingSimilarity * 0.08 +
      writheSimilarity * 0.05 +
      signatureSimilarity * 0.10 +
      unknottingSimilarity * 0.08 +
      bridgeSimilarity * 0.08 +
      braidIndexSimilarity * 0.08 +
      determinantSimilarity * 0.07 +
      arfSimilarity * 0.05 +
      volumeSimilarity * 0.05 +
      homflySimilarity * 0.12
    ).clamp(0.0, 1.0);
  }
  
  /// Helper: integer similarity (normalized difference)
  double _integerSimilarity(int a, int b) {
    final maxVal = math.max(a.abs(), b.abs()).clamp(1, 1000);
    final diff = (a - b).abs();
    return 1.0 - (diff / maxVal).clamp(0.0, 1.0);
  }
  
  /// Helper: optional integer similarity
  double _optionalIntegerSimilarity(int? a, int? b) {
    if (a != null && b != null) {
      return _integerSimilarity(a, b);
    } else if (a == null && b == null) {
      return 1.0; // Both null = similar
    } else {
      return 0.5; // One null = partial
    }
  }
  
  /// Helper: optional double similarity
  double _optionalDoubleSimilarity(double? a, double? b) {
    if (a != null && b != null) {
      final maxVal = math.max(a.abs(), b.abs()).clamp(1.0, 1000.0);
      final diff = (a - b).abs();
      return 1.0 - (diff / maxVal).clamp(0.0, 1.0);
    } else if (a == null && b == null) {
      return 1.0; // Both null = similar
    } else {
      return 0.5; // One null = partial
    }
  }

  /// Generate knot-based insights
  /// 
  /// Creates human-readable insights about knot compatibility
  List<String> _generateKnotInsights(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    final insights = <String>[];

    // Crossing number comparison
    final crossingA = knotA.invariants.crossingNumber;
    final crossingB = knotB.invariants.crossingNumber;
    if (crossingA == crossingB) {
      insights.add('Both knots have the same complexity ($crossingA crossings)');
    } else {
      insights.add(
        'Knot complexity: $crossingA vs $crossingB crossings',
      );
    }

    // Writhe comparison
    final writheA = knotA.invariants.writhe;
    final writheB = knotB.invariants.writhe;
    if ((writheA - writheB).abs() <= 1) {
      insights.add('Similar writhe values suggest compatible orientations');
    }

    // Polynomial similarity
    final invariantSimilarity = _compareKnotInvariants(
      knotA.invariants,
      knotB.invariants,
    );
    if (invariantSimilarity > 0.7) {
      insights.add('Highly similar knot topology');
    } else if (invariantSimilarity > 0.4) {
      insights.add('Moderately similar knot topology');
    } else {
      insights.add('Complementary knot topology');
    }

    return insights;
  }

  /// Calculate knot bonus for recommendations
  /// 
  /// Returns a bonus score (0.0-1.0) based on knot topology
  double calculateKnotBonus({
    required PersonalityKnot userKnot,
    required PersonalityKnot targetKnot,
  }) {
    // Topological compatibility bonus
    final topologicalMatch = _calculateKnotTopologicalCompatibility(
      userKnot,
      targetKnot,
    );

    // Rare knot type bonus (discover interesting connections)
    final rarityBonus = _calculateRarityBonus(userKnot, targetKnot);

    // Combined: 70% topological, 30% rarity
    return (topologicalMatch * 0.7 + rarityBonus * 0.3).clamp(0.0, 1.0);
  }

  /// Calculate rarity bonus
  /// 
  /// Rewards connections with rare or interesting knot types
  double _calculateRarityBonus(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // For now, use crossing number as a proxy for rarity
    // Higher crossing numbers are generally rarer
    final crossingA = knotA.invariants.crossingNumber;
    final crossingB = knotB.invariants.crossingNumber;
    final avgCrossing = (crossingA + crossingB) / 2.0;

    // Normalize to [0, 1] (assuming max crossing ~20)
    return (avgCrossing / 20.0).clamp(0.0, 1.0);
  }

  /// Generate knot-based insight string
  String generateKnotInsight({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
  }) {
    final crossingA = knotA.invariants.crossingNumber;
    final crossingB = knotB.invariants.crossingNumber;

    if (crossingA == crossingB) {
      return 'Your knots share the same complexity ($crossingA crossings) - a strong topological match!';
    } else {
      return 'Your $crossingA-crossing knot complements their $crossingB-crossing knot.';
    }
  }
}
