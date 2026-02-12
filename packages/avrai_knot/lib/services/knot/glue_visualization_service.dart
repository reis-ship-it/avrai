// Glue Visualization Service
// 
// Calculates and visualizes glue (bonding mechanisms) for fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/models/knot/glue_metrics.dart';
import 'package:avrai_knot/models/knot/glue_visualization.dart';
import 'package:avrai_knot/services/knot/cross_entity_compatibility_service.dart';

/// Service for calculating and visualizing glue
/// 
/// Glue represents the bonding mechanisms between entities in a cluster.
/// Visual properties (thickness, color, opacity) are calculated from glue strength.
class GlueVisualizationService {
  static const String _logName = 'GlueVisualizationService';
  
  // Visualization parameters
  static const double _thicknessMin = 1.0;
  static const double _thicknessMax = 5.0;
  static const double _opacityExponent = 0.7; // For depth perception

  final CrossEntityCompatibilityService _compatibilityService;

  GlueVisualizationService({
    required CrossEntityCompatibilityService compatibilityService,
  }) : _compatibilityService = compatibilityService;

  /// Calculate glue strength metrics
  Future<GlueMetrics> calculateGlueMetrics({
    required EntityKnot center,
    required List<EntityKnot> cluster,
  }) async {
    developer.log(
      'Calculating glue metrics for cluster with ${cluster.length} entities',
      name: _logName,
    );

    final individualStrengths = <EntityKnot, double>{};
    double totalGlue = 0.0;

    for (final entity in cluster.where((e) => e != center)) {
      final strength = await _calculateIntegratedCompatibility(center, entity);
      individualStrengths[entity] = strength;
      totalGlue += strength;
    }

    final avgGlue = cluster.length > 1
        ? totalGlue / (cluster.length - 1)
        : 0.0;

    final variance = _calculateVariance(individualStrengths.values, avgGlue);

    // Glue stability = 1 - coefficient of variation
    final coefficientOfVariation = avgGlue > 0.0
        ? math.sqrt(variance) / avgGlue
        : 0.0;
    final glueStability = (1.0 - coefficientOfVariation).clamp(0.0, 1.0);

    return GlueMetrics(
      individualStrengths: individualStrengths,
      totalGlue: totalGlue,
      averageGlue: avgGlue,
      glueVariance: variance,
      glueStability: glueStability,
    );
  }

  /// Calculate integrated compatibility between two entities
  Future<double> _calculateIntegratedCompatibility(
    EntityKnot center,
    EntityKnot entity,
  ) async {
    final compatibility = await _compatibilityService.calculateIntegratedCompatibility(
      entityA: center,
      entityB: entity,
    );

    return compatibility.clamp(0.0, 1.0);
  }

  /// Calculate variance of values
  double _calculateVariance(Iterable<double> values, double mean) {
    if (values.isEmpty) {
      return 0.0;
    }

    final squaredDiffs = values.map((v) => math.pow(v - mean, 2)).toList();
    final sumSquaredDiffs = squaredDiffs.fold(0.0, (a, b) => a + b);

    return sumSquaredDiffs / values.length;
  }

  /// Generate glue visualization properties
  Future<GlueVisualization> generateGlueVisualization({
    required EntityKnot center,
    required EntityKnot entity,
    required double glueStrength,
  }) async {
    // Line thickness (proportional to strength)
    final thickness = _thicknessMin + (_thicknessMax - _thicknessMin) * glueStrength;

    // Color (HSV/CIELAB based, colorblind accessible)
    final color = _calculateConnectionColor(
      glueStrength,
      await _getConnectionType(center, entity),
    );

    // Opacity (depth perception)
    final opacity = math.pow(glueStrength, _opacityExponent).toDouble().clamp(0.0, 1.0);

    return GlueVisualization(
      thickness: thickness,
      color: color,
      opacity: opacity,
      strength: glueStrength,
    );
  }

  /// Calculate connection color based on strength and type
  /// 
  /// Uses HSV color space for colorblind accessibility
  Color _calculateConnectionColor(double strength, ConnectionType type) {
    // Base hue based on connection type
    double hue;
    switch (type) {
      case ConnectionType.strong:
        hue = 120.0; // Green
        break;
      case ConnectionType.moderate:
        hue = 60.0; // Yellow
        break;
      case ConnectionType.weak:
        hue = 0.0; // Red
        break;
      case ConnectionType.neutral:
        hue = 180.0; // Cyan
        break;
    }

    // Saturation based on strength (stronger = more saturated)
    final saturation = strength.clamp(0.3, 1.0);

    // Value (brightness) based on strength (stronger = brighter)
    final value = 0.5 + (strength * 0.5);

    return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
  }

  /// Get connection type based on strength
  Future<ConnectionType> _getConnectionType(
    EntityKnot center,
    EntityKnot entity,
  ) async {
    final strength = await _calculateIntegratedCompatibility(center, entity);

    if (strength >= 0.7) {
      return ConnectionType.strong;
    } else if (strength >= 0.4) {
      return ConnectionType.moderate;
    } else if (strength >= 0.1) {
      return ConnectionType.weak;
    } else {
      return ConnectionType.neutral;
    }
  }
}

/// Connection type for color encoding
enum ConnectionType {
  strong,
  moderate,
  weak,
  neutral,
}
