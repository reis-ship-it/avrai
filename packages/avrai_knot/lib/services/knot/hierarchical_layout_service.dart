// Hierarchical Layout Service
// 
// Generates hierarchical layouts for fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/hierarchical_layout.dart';
import 'package:avrai_knot/models/knot/radial_position.dart';
import 'package:avrai_knot/services/knot/prominence_calculator.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';

/// Service for generating hierarchical layouts
/// 
/// Layout algorithm:
/// 1. Select center entity (highest prominence)
/// 2. Calculate connection strengths to center
/// 3. Arrange in radial layers (flow-based, continuous)
/// 4. Apply quantum phase adjustments
class HierarchicalLayoutService {
  static const String _logName = 'HierarchicalLayoutService';
  
  // Radial positioning parameters
  static const double _rMin = 50.0; // Minimum radius
  static const double _rMax = 300.0; // Maximum radius
  static const double _quantumInfluenceWeight = 0.1; // Quantum phase influence

  final ProminenceCalculator _prominenceCalculator;
  final CrossEntityCompatibilityService _compatibilityService;

  HierarchicalLayoutService({
    required ProminenceCalculator prominenceCalculator,
    required CrossEntityCompatibilityService compatibilityService,
  })  : _prominenceCalculator = prominenceCalculator,
        _compatibilityService = compatibilityService;

  /// Generate hierarchical layout for fabric cluster
  /// 
  /// Note: This method works with EntityKnot, but KnotFabric uses PersonalityKnot.
  /// The caller should convert PersonalityKnot to EntityKnot if needed.
  Future<HierarchicalLayout> generateLayout({
    required List<EntityKnot> cluster,
    required KnotFabric fabric,
  }) async {
    developer.log(
      'Generating hierarchical layout for cluster with ${cluster.length} entities',
      name: _logName,
    );

    if (cluster.isEmpty) {
      throw ArgumentError('Cluster cannot be empty');
    }

    // 1. Select center entity (highest prominence)
    final center = await _selectCenterEntity(cluster, fabric);

    // 2. Calculate connection strengths to center
    final connectionStrengths = await _calculateConnectionStrengths(
      center,
      cluster,
    );

    // 3. Arrange in radial layers (flow-based, continuous)
    final positions = await _calculateRadialPositions(
      center: center,
      cluster: cluster,
      connectionStrengths: connectionStrengths,
    );

    // 4. Calculate quantum phase adjustments
    final quantumAdjustedPositions = await _applyQuantumPhaseAdjustments(
      positions: positions,
      center: center,
      cluster: cluster,
    );

    return HierarchicalLayout(
      center: center,
      positions: quantumAdjustedPositions,
      connectionStrengths: connectionStrengths,
      generatedAt: DateTime.now(),
    );
  }

  /// Select center entity (highest prominence)
  Future<EntityKnot> _selectCenterEntity(
    List<EntityKnot> cluster,
    KnotFabric fabric,
  ) async {
    EntityKnot? center;
    double maxProminence = -1.0;

    for (final entity in cluster) {
      final prominence = await _prominenceCalculator.calculateProminenceScore(
        entity: entity,
        cluster: cluster,
        fabric: fabric,
      );

      if (prominence.score > maxProminence) {
        maxProminence = prominence.score;
        center = entity;
      }
    }

    return center ?? cluster.first;
  }

  /// Calculate connection strengths to center
  Future<Map<EntityKnot, double>> _calculateConnectionStrengths(
    EntityKnot center,
    List<EntityKnot> cluster,
  ) async {
    final strengths = <EntityKnot, double>{};

    for (final entity in cluster) {
      if (entity == center) {
        continue; // Skip center itself
      }

      // Calculate compatibility as connection strength
      final compatibility = await _compatibilityService.calculateIntegratedCompatibility(
        entityA: center,
        entityB: entity,
      );

      strengths[entity] = compatibility.clamp(0.0, 1.0);
    }

    return strengths;
  }

  /// Calculate radial positions (flow-based, continuous)
  Future<Map<EntityKnot, RadialPosition>> _calculateRadialPositions({
    required EntityKnot center,
    required List<EntityKnot> cluster,
    required Map<EntityKnot, double> connectionStrengths,
  }) async {
    final positions = <EntityKnot, RadialPosition>{};

    // Normalize connection strengths
    final normalizedStrengths = _normalizeConnectionStrengths(connectionStrengths);

    // Sort by connection strength (descending)
    final sortedEntities = cluster
        .where((e) => e != center)
        .toList()
      ..sort((a, b) => normalizedStrengths[b]!.compareTo(normalizedStrengths[a]!));

    // Calculate positions
    for (int i = 0; i < sortedEntities.length; i++) {
      final entity = sortedEntities[i];
      final strength = normalizedStrengths[entity]!;

      // Radial distance (continuous flow)
      // Stronger connections are closer to center
      final r = _rMin + (_rMax - _rMin) * (1 - strength);

      // Angular position (base angle)
      final baseAngle = (2 * math.pi / sortedEntities.length) * i;

      positions[entity] = RadialPosition.fromPolar(r, baseAngle);
    }

    return positions;
  }

  /// Normalize connection strengths to [0, 1]
  Map<EntityKnot, double> _normalizeConnectionStrengths(
    Map<EntityKnot, double> strengths,
  ) {
    if (strengths.isEmpty) {
      return {};
    }

    final values = strengths.values.toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = max - min;

    if (range == 0.0) {
      // All values are the same, return normalized to 0.5
      return strengths.map((key, value) => MapEntry(key, 0.5));
    }

    return strengths.map(
      (key, value) => MapEntry(key, ((value - min) / range).clamp(0.0, 1.0)),
    );
  }

  /// Apply quantum phase adjustments
  Future<Map<EntityKnot, RadialPosition>> _applyQuantumPhaseAdjustments({
    required Map<EntityKnot, RadialPosition> positions,
    required EntityKnot center,
    required List<EntityKnot> cluster,
  }) async {
    final adjustedPositions = <EntityKnot, RadialPosition>{};

    for (final entry in positions.entries) {
      final entity = entry.key;
      final position = entry.value;

      // Calculate quantum phase from knot invariants
      final quantumPhase = _calculateQuantumPhase(center, entity);

      // Adjust angle with quantum phase
      final adjustedAngle = position.theta + (quantumPhase * _quantumInfluenceWeight);

      adjustedPositions[entity] = RadialPosition.fromPolar(position.r, adjustedAngle);
    }

    return adjustedPositions;
  }

  /// Calculate quantum phase from knot invariants
  /// 
  /// Uses Jones polynomial coefficients to derive a phase value
  double _calculateQuantumPhase(EntityKnot center, EntityKnot entity) {
    final centerJones = center.knot.invariants.jonesPolynomial;
    final entityJones = entity.knot.invariants.jonesPolynomial;

    // Use first coefficient difference as phase indicator
    final centerCoeff = centerJones.isNotEmpty ? centerJones.first : 0.0;
    final entityCoeff = entityJones.isNotEmpty ? entityJones.first : 0.0;

    // Phase is based on coefficient difference (normalized to [-π, π])
    final phase = (entityCoeff - centerCoeff) * math.pi;

    return phase.clamp(-math.pi, math.pi);
  }
}
