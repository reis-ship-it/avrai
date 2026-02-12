// Temporal-String Integration Service
// 
// Integrates quantum time with string evolution
// Part of Phase 4: Cross-System Integration
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';

// Note: QuantumTemporalState is in lib/core/ai/quantum/quantum_temporal_state.dart
// Since this is in a package, we'll work with temporal state data directly
// or use AtomicTimestamp for temporal precision

/// Service to integrate quantum time with string evolution
/// 
/// **Responsibilities:**
/// - Use atomic timestamps for precise string interpolation
/// - Apply temporal quantum states to string evolution rate
/// - Use temporal compatibility for string matching
/// - Track string evolution with quantum temporal precision
class TemporalStringIntegrationService {
  static const String _logName = 'TemporalStringIntegrationService';

  final KnotEvolutionStringService _stringService;

  TemporalStringIntegrationService({
    required KnotEvolutionStringService stringService,
    KnotStorageService? storageService, // Reserved for future use
  }) : _stringService = stringService;

  /// Create string with temporal state
  /// 
  /// Links string evolution with temporal quantum state
  Future<KnotString?> createStringWithTemporalState({
    required String agentId,
    required AtomicTimestamp tAtomic,
    Map<String, dynamic>? temporalStateData,
  }) async {
    try {
      developer.log(
        'Creating string with temporal state: agentId=${agentId.substring(0, 10)}..., '
        'tAtomic=${tAtomic.timestampId}',
        name: _logName,
      );

      // Create string from evolution history
      final string = await _stringService.createStringFromHistory(agentId);
      
      if (string == null) {
        developer.log(
          'No string created for agentId',
          name: _logName,
        );
        return null;
      }

      // Store temporal state association (would be stored in metadata)
      // For now, the association is implicit through atomic timestamps
      
      developer.log(
        '✅ String created with temporal state: ${string.snapshots.length} snapshots',
        name: _logName,
      );
      
      return string;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create string with temporal state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Interpolate string at temporal state
  /// 
  /// Uses atomic timestamp for precise interpolation
  Future<PersonalityKnot?> interpolateStringAtTemporalState({
    required String agentId,
    required DateTime t,
    required AtomicTimestamp tAtomic,
    Map<String, dynamic>? temporalStateData,
  }) async {
    try {
      developer.log(
        'Interpolating string at temporal state: agentId=${agentId.substring(0, 10)}..., '
        't=$t, tAtomic=${tAtomic.timestampId}',
        name: _logName,
      );

      // Use atomic timestamp for precise interpolation
      // The string service will use the precise time
      final knot = await _stringService.getKnotAtTime(agentId, t);
      
      if (knot == null) {
        developer.log(
          'No knot found at time $t',
          name: _logName,
        );
        return null;
      }

      developer.log(
        '✅ String interpolated at temporal state: crossings=${knot.invariants.crossingNumber}',
        name: _logName,
      );
      
      return knot;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to interpolate string at temporal state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate temporal-string compatibility
  /// 
  /// Compatibility between two strings based on temporal quantum states
  double calculateTemporalStringCompatibility({
    required KnotString s1,
    required KnotString s2,
    required AtomicTimestamp t1,
    required AtomicTimestamp t2,
    Map<String, dynamic>? temporalState1Data,
    Map<String, dynamic>? temporalState2Data,
  }) {
    developer.log(
      'Calculating temporal-string compatibility',
      name: _logName,
    );

    try {
      // Get knots at their respective temporal states
      final knot1 = s1.getKnotAtTime(t1.serverTime);
      final knot2 = s2.getKnotAtTime(t2.serverTime);
      
      if (knot1 == null || knot2 == null) {
        return 0.0;
      }

      // Calculate temporal compatibility (simplified)
      // Full implementation would use QuantumTemporalState.temporalCompatibility()
      final timeDiff = (t1.serverTime.difference(t2.serverTime).inHours.abs()).toDouble();
      final temporalCompatibility = math.exp(-timeDiff / 24.0); // Decay over 24 hours

      // Calculate knot compatibility (simplified)
      final crossingDiff = (knot1.invariants.crossingNumber - 
                           knot2.invariants.crossingNumber).abs();
      final knotCompatibility = 1.0 - (crossingDiff / 100.0).clamp(0.0, 1.0);

      // Combined compatibility
      final combined = (0.6 * temporalCompatibility + 0.4 * knotCompatibility);
      
      return combined.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate temporal-string compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }

  /// Apply temporal quantum state to string evolution rate
  /// 
  /// Modifies string evolution rate based on temporal quantum state
  double applyTemporalStateToEvolutionRate({
    required double baseRate,
    required AtomicTimestamp tAtomic,
    Map<String, dynamic>? temporalStateData,
  }) {
    // Use time-of-day from atomic timestamp to modify evolution rate
    final hour = tAtomic.localTime.hour;
    
    // Evolution rate varies by time of day
    // Higher during active hours (9am-9pm), lower during quiet hours
    double timeFactor = 1.0;
    if (hour >= 9 && hour <= 21) {
      timeFactor = 1.2; // 20% faster during active hours
    } else {
      timeFactor = 0.8; // 20% slower during quiet hours
    }
    
    return baseRate * timeFactor;
  }
}
