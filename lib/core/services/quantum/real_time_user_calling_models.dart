// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Extracted cache models for real-time user calling service.

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';

/// Cached quantum state
class CachedQuantumState {
  final QuantumEntityState state;
  final AtomicTimestamp timestamp;
  final DateTime cachedAt;

  CachedQuantumState({
    required this.state,
    required this.timestamp,
  }) : cachedAt = DateTime.now();

  bool get isExpired {
    // Check if cache is expired using DateTime comparison
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    // TTL is 5 minutes
    return age > const Duration(minutes: 5);
  }
}

/// Cached compatibility
class CachedCompatibility {
  final double compatibility;
  final AtomicTimestamp timestamp;
  final DateTime cachedAt;

  CachedCompatibility({
    required this.compatibility,
    required this.timestamp,
  }) : cachedAt = DateTime.now();

  bool get isExpired {
    // Check if cache is expired using DateTime comparison
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    // TTL is 5 minutes
    return age > const Duration(minutes: 5);
  }
}
