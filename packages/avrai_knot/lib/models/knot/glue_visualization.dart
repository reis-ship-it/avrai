// Glue Visualization Model
// 
// Represents visualization properties for glue (bonding mechanisms)
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:flutter/material.dart';

/// Glue visualization properties
class GlueVisualization {
  /// Line thickness (proportional to strength)
  final double thickness;
  
  /// Color (HSV/CIELAB based, colorblind accessible)
  final Color color;
  
  /// Opacity (depth perception)
  final double opacity;
  
  /// Glue strength (0.0 to 1.0)
  final double strength;

  const GlueVisualization({
    required this.thickness,
    required this.color,
    required this.opacity,
    required this.strength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlueVisualization &&
          runtimeType == other.runtimeType &&
          thickness == other.thickness &&
          color == other.color &&
          opacity == other.opacity &&
          strength == other.strength;

  @override
  int get hashCode =>
      thickness.hashCode ^
      color.hashCode ^
      opacity.hashCode ^
      strength.hashCode;
}
