// Knot Weaving Service
// 
// Service for creating braided knots from two personality knots
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/api.dart';
import 'package:uuid/uuid.dart';

/// Service for creating braided knots from two personality knots
/// 
/// **Flow:**
/// 1. Get braid sequences from both knots
/// 2. Apply relationship-specific braiding pattern
/// 3. Create combined braid sequence
/// 4. Calculate complexity, stability, harmony
/// 5. Return BraidedKnot
class KnotWeavingService {
  static const String _logName = 'KnotWeavingService';
  
  // PersonalityKnotService reserved for future integration with PersonalityProfile
  // ignore: unused_field
  final PersonalityKnotService _personalityKnotService;
  
  // Weights for compatibility calculation
  static const double _topologicalWeight = 0.4;
  static const double _quantumWeight = 0.6;
  
  KnotWeavingService({
    required PersonalityKnotService personalityKnotService,
  }) : _personalityKnotService = personalityKnotService;

  /// Create braided knot from two personality knots
  /// 
  /// **Parameters:**
  /// - `knotA`: First personality knot
  /// - `knotB`: Second personality knot
  /// - `relationshipType`: Type of relationship (friendship, mentorship, etc.)
  /// 
  /// **Returns:**
  /// BraidedKnot representing the interweaving of the two knots
  Future<BraidedKnot> weaveKnots({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
    required RelationshipType relationshipType,
  }) async {
    developer.log(
      'Weaving knots for ${knotA.agentId.length > 10 ? '${knotA.agentId.substring(0, 10)}...' : knotA.agentId} and ${knotB.agentId.length > 10 ? '${knotB.agentId.substring(0, 10)}...' : knotB.agentId}',
      name: _logName,
    );

    try {
      // Step 1: Get braid sequences from both knots
      final braidA = knotA.braidData;
      final braidB = knotB.braidData;

      // Step 2: Apply relationship-specific braiding pattern
      final braidSequence = _createBraidForRelationshipType(
        braidA: braidA,
        braidB: braidB,
        relationshipType: relationshipType,
      );

      // Step 3: Calculate metrics
      final complexity = _calculateComplexity(braidSequence);
      final stability = _calculateStability(braidSequence, knotA, knotB);
      final harmony = _calculateHarmony(knotA, knotB, relationshipType);

      // Step 4: Create braided knot
      final braidedKnot = BraidedKnot(
        id: const Uuid().v4(),
        knotA: knotA,
        knotB: knotB,
        braidSequence: braidSequence,
        complexity: complexity,
        stability: stability,
        harmonyScore: harmony,
        relationshipType: relationshipType,
        createdAt: DateTime.now(),
      );

      developer.log(
        '✅ Braided knot created: complexity=$complexity, stability=$stability, harmony=$harmony',
        name: _logName,
      );

      return braidedKnot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to weave knots: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Calculate weaving compatibility between two knots
  /// 
  /// **Formula:**
  /// ```
  /// C_weaving = 0.4·C_topological + 0.6·C_quantum
  /// ```
  /// 
  /// **Parameters:**
  /// - `knotA`: First personality knot
  /// - `knotB`: Second personality knot
  /// 
  /// **Returns:**
  /// Compatibility score (0.0 to 1.0)
  Future<double> calculateWeavingCompatibility({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
  }) async {
    try {
      // Topological compatibility (from Rust FFI)
      final topological = calculateTopologicalCompatibility(
        braidDataA: knotA.braidData,
        braidDataB: knotB.braidData,
      );

      // Quantum compatibility (from PersonalityProfile if available)
      // For now, use a simplified calculation based on knot invariants
      // TODO: Integrate with PersonalityProfile.calculateCompatibility() when profiles are available
      final quantum = _calculateQuantumCompatibilityFromKnots(knotA, knotB);

      // Combined: 40% topological, 60% quantum
      final compatibility = (_topologicalWeight * topological) +
          (_quantumWeight * quantum);

      developer.log(
        'Weaving compatibility: $compatibility (topological: $topological, quantum: $quantum)',
        name: _logName,
      );

      return compatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating weaving compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.5; // Neutral fallback
    }
  }

  /// Preview braiding before connection
  /// 
  /// Creates a temporary braided knot and calculates all metrics
  /// without actually storing it
  Future<BraidingPreview> previewBraiding({
    required PersonalityKnot knotA,
    required PersonalityKnot knotB,
    RelationshipType relationshipType = RelationshipType.friendship,
  }) async {
    developer.log(
      'Previewing braiding for ${knotA.agentId.length > 10 ? '${knotA.agentId.substring(0, 10)}...' : knotA.agentId} and ${knotB.agentId.length > 10 ? '${knotB.agentId.substring(0, 10)}...' : knotB.agentId}',
      name: _logName,
    );

    try {
      // Create temporary braided knot
      final braidedKnot = await weaveKnots(
        knotA: knotA,
        knotB: knotB,
        relationshipType: relationshipType,
      );

      // Calculate compatibility
      final compatibility = await calculateWeavingCompatibility(
        knotA: knotA,
        knotB: knotB,
      );

      // Create preview
      final preview = BraidingPreview(
        braidedKnot: braidedKnot,
        complexity: braidedKnot.complexity,
        stability: braidedKnot.stability,
        harmony: braidedKnot.harmonyScore,
        compatibility: compatibility,
        relationshipType: relationshipType.displayName,
      );

      developer.log(
        '✅ Braiding preview created: compatibility=$compatibility',
        name: _logName,
      );

      return preview;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create braiding preview: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Create braid sequence for specific relationship type
  /// 
  /// **Algorithm:**
  /// - Friendship: Balanced interweaving (alternating pattern)
  /// - Mentorship: Asymmetric (mentor wraps around mentee)
  /// - Romantic: Deep interweaving (high crossing count)
  /// - Collaborative: Parallel with periodic crossings
  /// - Professional: Structured, regular pattern
  List<double> _createBraidForRelationshipType({
    required List<double> braidA,
    required List<double> braidB,
    required RelationshipType relationshipType,
  }) {
    switch (relationshipType) {
      case RelationshipType.friendship:
        return _createFriendshipBraid(braidA, braidB);
      case RelationshipType.mentorship:
        return _createMentorshipBraid(braidA, braidB);
      case RelationshipType.romantic:
        return _createRomanticBraid(braidA, braidB);
      case RelationshipType.collaborative:
        return _createCollaborativeBraid(braidA, braidB);
      case RelationshipType.professional:
        return _createProfessionalBraid(braidA, braidB);
    }
  }

  /// Create friendship braid (balanced interweaving)
  /// 
  /// Alternates between braidA and braidB crossings
  List<double> _createFriendshipBraid(List<double> braidA, List<double> braidB) {
    // Get number of strands (first element)
    final strandsA = braidA.isNotEmpty ? braidA[0].toInt() : 8;
    final strandsB = braidB.isNotEmpty ? braidB[0].toInt() : 8;
    final totalStrands = strandsA + strandsB;

    // Start with total strands
    final braidSequence = <double>[totalStrands.toDouble()];

    // Extract crossings from both braids (skip first element which is strand count)
    final crossingsA = braidA.length > 1 ? braidA.sublist(1) : <double>[];
    final crossingsB = braidB.length > 1 ? braidB.sublist(1) : <double>[];

    // Alternate between A and B crossings
    final maxCrossings = crossingsA.length > crossingsB.length
        ? crossingsA.length
        : crossingsB.length;

    for (int i = 0; i < maxCrossings; i++) {
      // Add crossing from A (if available)
      if (i < crossingsA.length) {
        braidSequence.add(crossingsA[i]);
      }
      // Add crossing from B (if available)
      if (i < crossingsB.length) {
        // Adjust strand index for B (offset by strandsA)
        final adjustedCrossing = crossingsB[i] + strandsA;
        braidSequence.add(adjustedCrossing);
      }
    }

    return braidSequence;
  }

  /// Create mentorship braid (asymmetric structure)
  /// 
  /// Mentor's braid (braidA) wraps around mentee's braid (braidB)
  List<double> _createMentorshipBraid(List<double> braidA, List<double> braidB) {
    final strandsA = braidA.isNotEmpty ? braidA[0].toInt() : 8;
    final strandsB = braidB.isNotEmpty ? braidB[0].toInt() : 8;
    final totalStrands = strandsA + strandsB;

    final braidSequence = <double>[totalStrands.toDouble()];

    // First add all mentee crossings (braidB)
    final crossingsB = braidB.length > 1 ? braidB.sublist(1) : <double>[];
    for (final crossing in crossingsB) {
      braidSequence.add(crossing);
    }

    // Then add mentor crossings (braidA) wrapping around
    final crossingsA = braidA.length > 1 ? braidA.sublist(1) : <double>[];
    for (final crossing in crossingsA) {
      // Mentor crossings wrap around mentee strands
      final wrappedCrossing = crossing + strandsB;
      braidSequence.add(wrappedCrossing);
    }

    return braidSequence;
  }

  /// Create romantic braid (deep interweaving)
  /// 
  /// High crossing count, complex structure
  List<double> _createRomanticBraid(List<double> braidA, List<double> braidB) {
    final strandsA = braidA.isNotEmpty ? braidA[0].toInt() : 8;
    final strandsB = braidB.isNotEmpty ? braidB[0].toInt() : 8;
    final totalStrands = strandsA + strandsB;

    final braidSequence = <double>[totalStrands.toDouble()];

    // Extract all crossings
    final crossingsA = braidA.length > 1 ? braidA.sublist(1) : <double>[];
    final crossingsB = braidB.length > 1 ? braidB.sublist(1) : <double>[];

    // Interweave deeply: A, B, A, B, A, B...
    final maxCrossings = crossingsA.length > crossingsB.length
        ? crossingsA.length
        : crossingsB.length;

    for (int i = 0; i < maxCrossings; i++) {
      // Add A crossing
      if (i < crossingsA.length) {
        braidSequence.add(crossingsA[i]);
      }
      // Add B crossing (adjusted)
      if (i < crossingsB.length) {
        braidSequence.add(crossingsB[i] + strandsA);
      }
      // Add another A crossing for depth
      if (i < crossingsA.length && i % 2 == 0) {
        braidSequence.add(crossingsA[i]);
      }
    }

    return braidSequence;
  }

  /// Create collaborative braid (parallel with periodic crossings)
  /// 
  /// Parallel strands with regular crossing intervals
  List<double> _createCollaborativeBraid(List<double> braidA, List<double> braidB) {
    final strandsA = braidA.isNotEmpty ? braidA[0].toInt() : 8;
    final strandsB = braidB.isNotEmpty ? braidB[0].toInt() : 8;
    final totalStrands = strandsA + strandsB;

    final braidSequence = <double>[totalStrands.toDouble()];

    final crossingsA = braidA.length > 1 ? braidA.sublist(1) : <double>[];
    final crossingsB = braidB.length > 1 ? braidB.sublist(1) : <double>[];

    // Add crossings at regular intervals (every 3rd position)
    const interval = 3;
    for (int i = 0; i < crossingsA.length; i += interval) {
      if (i < crossingsA.length) {
        braidSequence.add(crossingsA[i]);
      }
    }
    for (int i = 0; i < crossingsB.length; i += interval) {
      if (i < crossingsB.length) {
        braidSequence.add(crossingsB[i] + strandsA);
      }
    }

    return braidSequence;
  }

  /// Create professional braid (structured, regular pattern)
  /// 
  /// Clean, organized braiding pattern
  List<double> _createProfessionalBraid(List<double> braidA, List<double> braidB) {
    final strandsA = braidA.isNotEmpty ? braidA[0].toInt() : 8;
    final strandsB = braidB.isNotEmpty ? braidB[0].toInt() : 8;
    final totalStrands = strandsA + strandsB;

    final braidSequence = <double>[totalStrands.toDouble()];

    final crossingsA = braidA.length > 1 ? braidA.sublist(1) : <double>[];
    final crossingsB = braidB.length > 1 ? braidB.sublist(1) : <double>[];

    // Structured pattern: A, A, B, B (pairs)
    final maxPairs = (crossingsA.length > crossingsB.length
            ? crossingsA.length
            : crossingsB.length) ~/
        2;

    for (int i = 0; i < maxPairs; i++) {
      final idxA = i * 2;
      final idxB = i * 2;

      // Add two A crossings
      if (idxA < crossingsA.length) {
        braidSequence.add(crossingsA[idxA]);
      }
      if (idxA + 1 < crossingsA.length) {
        braidSequence.add(crossingsA[idxA + 1]);
      }

      // Add two B crossings (adjusted)
      if (idxB < crossingsB.length) {
        braidSequence.add(crossingsB[idxB] + strandsA);
      }
      if (idxB + 1 < crossingsB.length) {
        braidSequence.add(crossingsB[idxB + 1] + strandsA);
      }
    }

    return braidSequence;
  }

  /// Calculate complexity score from braid sequence
  /// 
  /// Complexity = normalized crossing count
  double _calculateComplexity(List<double> braidSequence) {
    if (braidSequence.isEmpty) return 0.0;

    // Number of crossings = (braidSequence.length - 1) / 2
    // (First element is strand count, then pairs of [strand, over/under])
    final crossingCount = (braidSequence.length - 1) / 2.0;

    // Normalize to [0, 1] (assuming max ~100 crossings)
    return (crossingCount / 100.0).clamp(0.0, 1.0);
  }

  /// Calculate stability score
  /// 
  /// Stability = how well the two knots can be braided together
  /// Based on topological compatibility and knot invariants
  double _calculateStability(
    List<double> braidSequence,
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    try {
      // Use topological compatibility as stability measure
      final topological = calculateTopologicalCompatibility(
        braidDataA: knotA.braidData,
        braidDataB: knotB.braidData,
      );

      // Also consider knot invariants similarity
      final jonesSimilarity = _calculatePolynomialSimilarity(
        knotA.invariants.jonesPolynomial,
        knotB.invariants.jonesPolynomial,
      );

      // Combined: 70% topological, 30% polynomial similarity
      return (topological * 0.7 + jonesSimilarity * 0.3).clamp(0.0, 1.0);
    } catch (e) {
      developer.log(
        'Error calculating stability: $e',
        name: _logName,
      );
      return 0.5; // Neutral fallback
    }
  }

  /// Calculate harmony score
  /// 
  /// Harmony = how well the relationship type matches the knot structures
  double _calculateHarmony(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
    RelationshipType relationshipType,
  ) {
    // Base harmony from topological compatibility
    final topological = calculateTopologicalCompatibility(
      braidDataA: knotA.braidData,
      braidDataB: knotB.braidData,
    );

    // Adjust based on relationship type
    double typeMultiplier = 1.0;
    switch (relationshipType) {
      case RelationshipType.friendship:
        typeMultiplier = 1.0; // Neutral
        break;
      case RelationshipType.mentorship:
        typeMultiplier = 0.9; // Slightly lower (asymmetric)
        break;
      case RelationshipType.romantic:
        typeMultiplier = 1.1; // Higher (deep connection)
        break;
      case RelationshipType.collaborative:
        typeMultiplier = 1.0; // Neutral
        break;
      case RelationshipType.professional:
        typeMultiplier = 0.95; // Slightly lower (structured)
        break;
    }

    return (topological * typeMultiplier).clamp(0.0, 1.0);
  }

  /// Calculate quantum compatibility from knots
  /// 
  /// Simplified calculation based on knot invariants
  /// TODO: Integrate with PersonalityProfile.calculateCompatibility() when available
  double _calculateQuantumCompatibilityFromKnots(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Use polynomial similarity as proxy for quantum compatibility
    final jonesSimilarity = _calculatePolynomialSimilarity(
      knotA.invariants.jonesPolynomial,
      knotB.invariants.jonesPolynomial,
    );

    final alexanderSimilarity = _calculatePolynomialSimilarity(
      knotA.invariants.alexanderPolynomial,
      knotB.invariants.alexanderPolynomial,
    );

    // Combined: 60% Jones, 40% Alexander
    return (jonesSimilarity * 0.6 + alexanderSimilarity * 0.4).clamp(0.0, 1.0);
  }

  /// Calculate similarity between two polynomials
  /// 
  /// Uses L2 distance normalized to [0, 1]
  double _calculatePolynomialSimilarity(
    List<double> polyA,
    List<double> polyB,
  ) {
    if (polyA.isEmpty && polyB.isEmpty) return 1.0;
    if (polyA.isEmpty || polyB.isEmpty) return 0.0;

    // Calculate L2 distance (handle different lengths by padding with zeros)
    final maxLength = polyA.length > polyB.length ? polyA.length : polyB.length;
    double sumSquaredDiff = 0.0;
    for (int i = 0; i < maxLength; i++) {
      final a = i < polyA.length ? polyA[i] : 0.0;
      final b = i < polyB.length ? polyB[i] : 0.0;
      final diff = a - b;
      sumSquaredDiff += diff * diff;
    }

    final distance = math.sqrt(sumSquaredDiff);

    // Convert distance to similarity (inverse, normalized)
    // Use exponential decay: similarity = e^(-distance)
    final similarity = math.exp(-distance);

    return similarity.clamp(0.0, 1.0);
  }
}
