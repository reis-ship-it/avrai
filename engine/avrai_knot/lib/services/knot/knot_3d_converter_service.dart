// Knot 3D Converter Service
//
// Service for converting braid data to 3D coordinates
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1: 3D Knot Visualization and Conversion

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_3d.dart';

/// Service for converting braid data to 3D coordinates
///
/// **Responsibilities:**
/// - Parse braid sequences
/// - Generate 3D curves using parametric equations
/// - Handle crossings in 3D space
/// - Apply knot invariants to shape
class Knot3DConverterService {
  static const String _logName = 'Knot3DConverterService';

  /// Convert PersonalityKnot to Knot3D
  ///
  /// **Algorithm:**
  /// 1. Parse braid data
  /// 2. Generate 3D curve using parametric equations
  /// 3. Map braid crossings to 3D crossings
  /// 4. Apply knot invariants to shape
  Knot3D convertTo3D(PersonalityKnot knot) {
    developer.log(
      'Converting knot to 3D: agentId=${knot.agentId.substring(0, 10)}..., '
      'crossings=${knot.invariants.crossingNumber}',
      name: _logName,
    );

    try {
      return Knot3D.fromBraidData(
        braidData: knot.braidData,
        invariants: knot.invariants,
        agentId: knot.agentId,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to convert knot to 3D: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Generate 3D coordinates using advanced parametric equations
  ///
  /// Uses multiple knot types based on invariants:
  /// - Trefoil (3 crossings)
  /// - Figure-eight (4 crossings)
  /// - Torus knots (higher crossings)
  /// - Custom parametric curves for complex knots
  List<Vector3> generate3DCoordinates({
    required int numStrands,
    required int crossingNumber,
    required int writhe,
    required List<Crossing3D> crossings,
    int numPoints = 200,
  }) {
    // Choose knot type based on crossing number
    if (crossingNumber <= 3) {
      return _generateTrefoil(numPoints: numPoints, writhe: writhe);
    } else if (crossingNumber == 4) {
      return _generateFigureEight(numPoints: numPoints, writhe: writhe);
    } else {
      return _generateTorusKnot(
        numPoints: numPoints,
        crossingNumber: crossingNumber,
        writhe: writhe,
        numStrands: numStrands,
      );
    }
  }

  /// Generate trefoil knot (3 crossings)
  ///
  /// Parametric equations for trefoil:
  /// x = sin(t) + 2*sin(2*t)
  /// y = cos(t) - 2*cos(2*t)
  /// z = -sin(3*t)
  List<Vector3> _generateTrefoil({
    required int numPoints,
    required int writhe,
  }) {
    final coordinates = <Vector3>[];
    final scale = 1.0 + (writhe.abs() / 20.0).clamp(0.0, 0.5);

    for (int i = 0; i < numPoints; i++) {
      final t = (i / numPoints) * 2 * math.pi;

      final x = (math.sin(t) + 2 * math.sin(2 * t)) * scale;
      final y = (math.cos(t) - 2 * math.cos(2 * t)) * scale;
      final z = -math.sin(3 * t) * scale * (writhe.sign == -1 ? -1 : 1);

      coordinates.add(Vector3(x, y, z));
    }

    return coordinates;
  }

  /// Generate figure-eight knot (4 crossings)
  ///
  /// Parametric equations for figure-eight:
  /// x = (2 + cos(2*t)) * cos(3*t)
  /// y = (2 + cos(2*t)) * sin(3*t)
  /// z = sin(4*t)
  List<Vector3> _generateFigureEight({
    required int numPoints,
    required int writhe,
  }) {
    final coordinates = <Vector3>[];
    final scale = 1.0 + (writhe.abs() / 20.0).clamp(0.0, 0.5);

    for (int i = 0; i < numPoints; i++) {
      final t = (i / numPoints) * 2 * math.pi;

      final x = (2 + math.cos(2 * t)) * math.cos(3 * t) * scale;
      final y = (2 + math.cos(2 * t)) * math.sin(3 * t) * scale;
      final z = math.sin(4 * t) * scale * (writhe.sign == -1 ? -1 : 1);

      coordinates.add(Vector3(x, y, z));
    }

    return coordinates;
  }

  /// Generate torus knot (higher crossings)
  ///
  /// Parametric equations for torus knot:
  /// x = (R + r*cos(n*t))*cos(m*t)
  /// y = (R + r*cos(n*t))*sin(m*t)
  /// z = r*sin(n*t)
  ///
  /// Where n and m are coprime integers determining knot type
  List<Vector3> _generateTorusKnot({
    required int numPoints,
    required int crossingNumber,
    required int writhe,
    required int numStrands,
  }) {
    final coordinates = <Vector3>[];

    // Calculate n and m from crossing number
    // For torus knots, crossing number ≈ n*m
    final n = math.sqrt(crossingNumber).ceil().clamp(2, 10);
    final m = (crossingNumber / n).ceil().clamp(3, 15);

    // Torus parameters
    final R = 2.0; // Major radius
    final r =
        0.5 +
        (crossingNumber / 20.0).clamp(
          0.0,
          1.0,
        ); // Minor radius (complexity-based)

    // Apply writhe to affect chirality
    final writheFactor = 1.0 + (writhe.abs() / 30.0).clamp(0.0, 0.3);
    final chirality = writhe.sign == -1 ? -1 : 1;

    for (int i = 0; i < numPoints; i++) {
      final t = (i / numPoints) * 2 * math.pi;

      final x = (R + r * writheFactor * math.cos(n * t)) * math.cos(m * t);
      final y = (R + r * writheFactor * math.cos(n * t)) * math.sin(m * t);
      final z = r * writheFactor * math.sin(n * t) * chirality;

      coordinates.add(Vector3(x, y, z));
    }

    return coordinates;
  }

  /// Smooth 3D coordinates using Catmull-Rom spline
  ///
  /// Applies smoothing to create continuous curves
  List<Vector3> smoothCoordinates(
    List<Vector3> coordinates, {
    int iterations = 1,
  }) {
    if (coordinates.length < 4) {
      return coordinates; // Need at least 4 points for Catmull-Rom
    }

    var smoothed = List<Vector3>.from(coordinates);

    for (int iter = 0; iter < iterations; iter++) {
      final newCoordinates = <Vector3>[];

      // Keep first point
      newCoordinates.add(smoothed[0]);

      // Interpolate between points using Catmull-Rom
      for (int i = 1; i < smoothed.length - 2; i++) {
        final p0 = smoothed[i - 1];
        final p1 = smoothed[i];
        final p2 = smoothed[i + 1];
        final p3 = smoothed[i + 2];

        // Catmull-Rom interpolation at t=0.5
        final t = 0.5;
        final t2 = t * t;
        final t3 = t2 * t;

        final x =
            0.5 *
            ((2 * p1.x) +
                (-p0.x + p2.x) * t +
                (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
                (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3);

        final y =
            0.5 *
            ((2 * p1.y) +
                (-p0.y + p2.y) * t +
                (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
                (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);

        final z =
            0.5 *
            ((2 * p1.z) +
                (-p0.z + p2.z) * t +
                (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 +
                (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3);

        newCoordinates.add(Vector3(x, y, z));
      }

      // Keep last point
      newCoordinates.add(smoothed[smoothed.length - 1]);

      smoothed = newCoordinates;
    }

    return smoothed;
  }

  /// Apply knot invariants to shape
  ///
  /// Modifies 3D coordinates based on knot invariants:
  /// - Crossing number affects complexity
  /// - Writhe affects chirality
  /// - Signature affects overall shape
  List<Vector3> applyInvariantsToShape({
    required List<Vector3> coordinates,
    required KnotInvariants invariants,
  }) {
    final modified = <Vector3>[];

    // Apply crossing number (complexity)
    final complexityFactor =
        1.0 + (invariants.crossingNumber / 20.0).clamp(0.0, 0.5);

    // Apply writhe (chirality)
    final chiralityFactor = invariants.writhe.sign == -1 ? -1 : 1;

    // Apply signature (overall shape)
    final signatureFactor =
        1.0 + (invariants.signature.abs() / 10.0).clamp(0.0, 0.2);

    for (final coord in coordinates) {
      // Scale by complexity
      final scaled = coord * complexityFactor;

      // Apply chirality to z-axis
      final chiraled = Vector3(
        scaled.x,
        scaled.y,
        scaled.z * chiralityFactor * signatureFactor,
      );

      modified.add(chiraled);
    }

    return modified;
  }
}
