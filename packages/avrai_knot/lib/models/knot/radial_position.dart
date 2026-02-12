// Radial Position Model
// 
// Represents a position in radial (polar) coordinates for hierarchical layout
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:equatable/equatable.dart';
import 'dart:math' as math;

/// Radial position in polar coordinates
class RadialPosition extends Equatable {
  /// Radial distance from center
  final double r;
  
  /// Angular position (theta) in radians
  final double theta;
  
  /// X coordinate (Cartesian)
  final double x;
  
  /// Y coordinate (Cartesian)
  final double y;

  const RadialPosition({
    required this.r,
    required this.theta,
    required this.x,
    required this.y,
  });

  /// Create from polar coordinates
  factory RadialPosition.fromPolar(double r, double theta) {
    return RadialPosition(
      r: r,
      theta: theta,
      x: r * math.cos(theta),
      y: r * math.sin(theta),
    );
  }

  /// Create from Cartesian coordinates
  factory RadialPosition.fromCartesian(double x, double y) {
    final r = math.sqrt(x * x + y * y);
    final theta = math.atan2(y, x);
    return RadialPosition(
      r: r,
      theta: theta,
      x: x,
      y: y,
    );
  }

  /// Distance to another position
  double distanceTo(RadialPosition other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  List<Object?> get props => [r, theta, x, y];
}
