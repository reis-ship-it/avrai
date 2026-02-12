import 'package:avrai/core/models/quantum/decoherence_pattern.dart';

/// Decoherence Pattern Repository Interface
///
/// Defines the contract for storing and retrieving decoherence patterns.
///
/// **Purpose:**
/// - Store decoherence patterns (offline-first)
/// - Query by user ID
/// - Query by time range
/// - Query by behavior phase
/// - Aggregate patterns for analysis
///
/// **Implementation:**
/// Part of Quantum Enhancement Implementation Plan - Phase 2.1
abstract class DecoherencePatternRepository {
  /// Get decoherence pattern for a user
  Future<DecoherencePattern?> getByUserId(String userId);

  /// Save decoherence pattern
  Future<void> save(DecoherencePattern pattern);

  /// Get patterns by behavior phase
  Future<List<DecoherencePattern>> getByBehaviorPhase(BehaviorPhase phase);

  /// Get patterns updated within a time range
  Future<List<DecoherencePattern>> getByTimeRange({
    required DateTime start,
    required DateTime end,
  });

  /// Delete pattern for a user
  Future<void> delete(String userId);
}

