// Knot Evolution Coordinator Service
// 
// Coordinates automatic knot regeneration and evolution tracking when personality profiles evolve
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Evolution Tracking for String Generation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';

// AgentIdService is passed from DI registration (not imported to avoid package dependency)
// The service accepts a function to resolve agentId to avoid direct dependency

/// Service for coordinating automatic knot evolution tracking
/// 
/// **Responsibilities:**
/// - Listen to profile evolution events
/// - Regenerate knots when profiles evolve
/// - Detect significant knot changes
/// - Create snapshots for evolution history
/// - Enable string service to track continuous evolution
/// 
/// **Flow:**
/// 1. Profile evolves → callback fires
/// 2. Load old knot for comparison
/// 3. Regenerate knot from evolved profile
/// 4. Detect if change is significant
/// 5. Save new knot
/// 6. Create snapshot if significant change detected
class KnotEvolutionCoordinatorService {
  static const String _logName = 'KnotEvolutionCoordinatorService';

  // Thresholds for significance detection
  static const int _crossingChangeThreshold = 2; // Significant if crossing number changes by 2+
  static const double _complexityChangeThreshold = 0.2; // 20% complexity change
  static const double _polynomialDistanceThreshold = 0.3; // Polynomial distance threshold

  final PersonalityKnotService _knotService;
  final KnotStorageService _storageService;
  final Future<String> Function(String) _getAgentId;

  KnotEvolutionCoordinatorService({
    required PersonalityKnotService knotService,
    required KnotStorageService storageService,
    required Future<String> Function(String) getAgentId,
  })  : _knotService = knotService,
        _storageService = storageService,
        _getAgentId = getAgentId;

  /// Handle profile evolution - regenerate knot and create snapshot if needed
  /// 
  /// **Called by:** onPersonalityEvolved callback
  /// **Flow:**
  /// 1. Get agentId from userId
  /// 2. Load old knot for comparison
  /// 3. Regenerate knot from evolved profile
  /// 4. Detect if change is significant
  /// 5. Save new knot
  /// 6. Create snapshot if significant change detected
  Future<void> handleProfileEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    try {
      developer.log(
        'Handling profile evolution for user: ${userId.substring(0, 10)}... (generation ${evolvedProfile.evolutionGeneration})',
        name: _logName,
      );

      // Step 1: Get agentId
      final agentId = await _getAgentId(userId);

      // Step 2: Load old knot for comparison
      final oldKnot = await _storageService.loadKnot(agentId);

      // Step 3: Regenerate knot from evolved profile
      final newKnot = await _knotService.generateKnot(evolvedProfile);

      // Step 4: Detect if change is significant
      final isSignificant = oldKnot == null ||
          _detectSignificantChange(oldKnot, newKnot);

      // Step 5: Save new knot
      await _storageService.saveKnot(agentId, newKnot);

      developer.log(
        '✅ Knot regenerated: crossings=${newKnot.invariants.crossingNumber}, writhe=${newKnot.invariants.writhe}',
        name: _logName,
      );

      // Step 6: Create snapshot if significant change detected
      if (isSignificant) {
        final reason = _determineSnapshotReason(
          oldKnot: oldKnot,
          newKnot: newKnot,
          profile: evolvedProfile,
        );

        await _storageService.addSnapshot(
          agentId,
          KnotSnapshot(
            timestamp: DateTime.now(),
            knot: newKnot,
            reason: reason,
          ),
        );

        developer.log(
          '✅ Snapshot created: $reason (${oldKnot != null ? "change detected" : "initial knot"})',
          name: _logName,
        );
      } else {
        developer.log(
          'ℹ️ Change not significant, skipping snapshot',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to handle profile evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - knot evolution is non-blocking
      // Profile evolution should continue even if knot tracking fails
    }
  }

  /// Detect if knot change is significant enough to create snapshot
  /// 
  /// **Criteria:**
  /// - Knot type change (different invariants) → always significant
  /// - Crossing number change ≥ threshold → significant
  /// - Complexity change ≥ threshold → significant
  /// - Polynomial distance ≥ threshold → significant
  bool _detectSignificantChange(
    PersonalityKnot oldKnot,
    PersonalityKnot newKnot,
  ) {
    // 1. Check knot type change (different invariants = different knot type)
    if (_areKnotsDifferentType(oldKnot, newKnot)) {
      developer.log(
        'Knot type change detected (different invariants)',
        name: _logName,
      );
      return true; // Always significant
    }

    // 2. Check crossing number change
    final crossingDelta = (newKnot.invariants.crossingNumber -
            oldKnot.invariants.crossingNumber)
        .abs();
    if (crossingDelta >= _crossingChangeThreshold) {
      developer.log(
        'Significant crossing number change: $crossingDelta (threshold: $_crossingChangeThreshold)',
        name: _logName,
      );
      return true;
    }

    // 3. Check complexity change
    final oldComplexity = _calculateComplexity(oldKnot);
    final newComplexity = _calculateComplexity(newKnot);
    if (oldComplexity > 0.0) {
      final complexityChange =
          (newComplexity - oldComplexity).abs() / oldComplexity;
      if (complexityChange >= _complexityChangeThreshold) {
        developer.log(
          'Significant complexity change: ${(complexityChange * 100).toStringAsFixed(1)}% (threshold: ${(_complexityChangeThreshold * 100).toStringAsFixed(1)}%)',
          name: _logName,
        );
        return true;
      }
    }

    // 4. Check polynomial distance
    final polynomialDistance = _calculatePolynomialDistance(
      oldKnot.invariants.jonesPolynomial,
      newKnot.invariants.jonesPolynomial,
    );
    if (polynomialDistance >= _polynomialDistanceThreshold) {
      developer.log(
        'Significant polynomial distance: ${polynomialDistance.toStringAsFixed(3)} (threshold: $_polynomialDistanceThreshold)',
        name: _logName,
      );
      return true;
    }

    return false; // Change not significant
  }

  /// Check if knots are different types (different invariants)
  /// 
  /// Compares Jones polynomials as primary invariant
  bool _areKnotsDifferentType(
    PersonalityKnot knotA,
    PersonalityKnot knotB,
  ) {
    // Compare Jones polynomials (primary invariant)
    final jonesA = knotA.invariants.jonesPolynomial;
    final jonesB = knotB.invariants.jonesPolynomial;

    if (jonesA.length != jonesB.length) {
      return true; // Different lengths = different knot types
    }

    // Compare coefficients (with small tolerance for floating point)
    for (int i = 0; i < jonesA.length; i++) {
      if ((jonesA[i] - jonesB[i]).abs() > 0.01) {
        return true; // Different coefficients = different knot type
      }
    }

    return false; // Same knot type
  }

  /// Calculate knot complexity (crossing number × writhe magnitude)
  /// 
  /// Higher complexity = more complex knot structure
  double _calculateComplexity(PersonalityKnot knot) {
    return (knot.invariants.crossingNumber *
            knot.invariants.writhe.abs().clamp(1, 100))
        .toDouble();
  }

  /// Calculate distance between polynomials using Euclidean distance
  /// 
  /// Returns normalized distance (0.0 = identical, higher = more different)
  double _calculatePolynomialDistance(
    List<double> polyA,
    List<double> polyB,
  ) {
    // Use Euclidean distance
    final maxLength =
        polyA.length > polyB.length ? polyA.length : polyB.length;
    var distance = 0.0;

    for (int i = 0; i < maxLength; i++) {
      final valA = i < polyA.length ? polyA[i] : 0.0;
      final valB = i < polyB.length ? polyB[i] : 0.0;
      final diff = valA - valB;
      distance += diff * diff;
    }

    // Normalize by max length
    return math.sqrt(distance) / maxLength.clamp(1, 100);
  }

  /// Determine reason for snapshot creation
  /// 
  /// Provides context about why snapshot was created
  String _determineSnapshotReason({
    PersonalityKnot? oldKnot,
    required PersonalityKnot newKnot,
    required PersonalityProfile profile,
  }) {
    if (oldKnot == null) {
      return 'initial_knot_creation';
    }

    // Check for knot type change
    if (_areKnotsDifferentType(oldKnot, newKnot)) {
      return 'knot_type_change';
    }

    // Check for milestone (using profile evolution milestones)
    final milestones =
        profile.learningHistory['evolution_milestones'] as List<dynamic>?;
    if (milestones != null && milestones.isNotEmpty) {
      // Get last milestone timestamp
      DateTime? lastMilestone;
      for (final milestone in milestones.reversed) {
        if (milestone is DateTime) {
          lastMilestone = milestone;
          break;
        } else if (milestone is String) {
          try {
            lastMilestone = DateTime.parse(milestone);
            break;
          } catch (_) {
            // Skip invalid dates
          }
        }
      }

      if (lastMilestone != null &&
          DateTime.now().difference(lastMilestone).inHours < 24) {
        return 'profile_milestone';
      }
    }

    // Check for complexity milestone
    final oldComplexity = _calculateComplexity(oldKnot);
    final newComplexity = _calculateComplexity(newKnot);
    if (oldComplexity > 0.0) {
      final complexityChange =
          (newComplexity - oldComplexity).abs() / oldComplexity;
      if (complexityChange >= 0.3) {
        return 'complexity_milestone';
      }
    }

    // Default: profile evolution
    return 'profile_evolution_generation_${profile.evolutionGeneration}';
  }
}
