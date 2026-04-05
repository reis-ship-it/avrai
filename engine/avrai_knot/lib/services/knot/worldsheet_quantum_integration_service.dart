// Worldsheet-Quantum Integration Service
//
// Integrates worldsheets with quantum systems
// Part of Phase 4: Cross-System Integration
// Patent #31: Topological Knot Theory for Personality Representation

import 'dart:developer' as developer;
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';

// Note: QuantumTemporalState is in lib/core/ai/quantum/quantum_temporal_state.dart
// Since this is in a package, we'll work with temporal state data directly

/// Service to integrate worldsheets with quantum systems
///
/// **Responsibilities:**
/// - Use quantum temporal states for worldsheet time interpolation
/// - Apply quantum entity states to fabric composition
/// - Use quantum compatibility for group formation
/// - Track fabric evolution with quantum precision
class WorldsheetQuantumIntegrationService {
  static const String _logName = 'WorldsheetQuantumIntegrationService';

  final KnotWorldsheetService _worldsheetService;

  WorldsheetQuantumIntegrationService({
    required KnotWorldsheetService worldsheetService,
    KnotFabricService? fabricService, // Reserved for future use
  }) : _worldsheetService = worldsheetService;

  /// Create worldsheet from quantum states
  ///
  /// Creates a worldsheet representation from a list of quantum entity states
  Future<KnotWorldsheet?> createWorldsheetFromQuantumStates({
    required String groupId,
    required List<QuantumEntityState> states,
    required AtomicTimestamp tAtomic,
    Map<String, dynamic>? temporalStateData,
  }) async {
    try {
      developer.log(
        'Creating worldsheet from quantum states: groupId=$groupId, '
        '${states.length} entities, tAtomic=${tAtomic.timestampId}',
        name: _logName,
      );

      // Extract user IDs from quantum entity states
      final userIds = states.map((s) => s.entityId).toList();

      // Create worldsheet using worldsheet service
      final worldsheet = await _worldsheetService.createWorldsheet(
        groupId: groupId,
        userIds: userIds,
      );

      if (worldsheet == null) {
        developer.log('Failed to create worldsheet', name: _logName);
        return null;
      }

      developer.log(
        '✅ Worldsheet created from quantum states: ${worldsheet.snapshots.length} snapshots',
        name: _logName,
      );

      return worldsheet;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to create worldsheet from quantum states: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Interpolate worldsheet at temporal state
  ///
  /// Uses atomic timestamp for precise interpolation
  Future<KnotFabric?> interpolateWorldsheetAtTemporalState({
    required String groupId,
    required DateTime t,
    required AtomicTimestamp tAtomic,
    Map<String, dynamic>? temporalStateData,
  }) async {
    try {
      developer.log(
        'Interpolating worldsheet at temporal state: groupId=$groupId, '
        't=$t, tAtomic=${tAtomic.timestampId}',
        name: _logName,
      );

      // Use atomic timestamp for precise interpolation
      final fabric = await _worldsheetService.getFabricAtTime(
        groupId: groupId,
        time: t,
      );

      if (fabric == null) {
        developer.log('No fabric found at time $t', name: _logName);
        return null;
      }

      developer.log(
        '✅ Worldsheet interpolated at temporal state: stability=${fabric.stability.toStringAsFixed(3)}',
        name: _logName,
      );

      return fabric;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to interpolate worldsheet at temporal state: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate quantum-fabric compatibility
  ///
  /// Compatibility between quantum entity states and fabric
  double calculateQuantumFabricCompatibility({
    required KnotFabric fabric,
    required List<QuantumEntityState> states,
  }) {
    developer.log(
      'Calculating quantum-fabric compatibility: fabricId=${fabric.fabricId}, '
      '${states.length} entities',
      name: _logName,
    );

    try {
      if (states.isEmpty) {
        return 0.0;
      }

      // Calculate average quantum compatibility
      double totalCompatibility = 0.0;
      int count = 0;

      // Compare each entity state with fabric
      for (final state in states) {
        // Find corresponding knot in fabric
        final correspondingKnot = fabric.userKnots.firstWhere(
          (knot) => knot.agentId == state.entityId,
          orElse: () => fabric.userKnots.first,
        );

        // Calculate compatibility (simplified)
        final avgPersonality =
            state.personalityState.values.fold(0.0, (a, b) => a + b) /
            state.personalityState.length.clamp(1, 100);

        final knotComplexity =
            (correspondingKnot.invariants.crossingNumber / 100.0).clamp(
              0.0,
              1.0,
            );

        final compatibility = 1.0 - (avgPersonality - knotComplexity).abs();
        totalCompatibility += compatibility;
        count++;
      }

      final avgCompatibility = count > 0 ? totalCompatibility / count : 0.0;

      // Factor in fabric stability
      final finalCompatibility =
          (0.7 * avgCompatibility + 0.3 * fabric.stability);

      return finalCompatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to calculate quantum-fabric compatibility: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return 0.0;
    }
  }
}
