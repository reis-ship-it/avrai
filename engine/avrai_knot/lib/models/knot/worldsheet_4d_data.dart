// Worldsheet 4D Data Model
//
// 4D data representation for worldsheet visualization (3D space + time)
// Part of Medium Priority Improvements
// Patent #31: Topological Knot Theory for Personality Representation

import 'package:vector_math/vector_math.dart';

/// 4D worldsheet data for visualization
///
/// Represents worldsheet evolution in 4D space (3D + time)
/// - 3D space: Fabric structure at a point in time
/// - Time dimension: Evolution over time
class Worldsheet4DData {
  /// Time points
  final List<DateTime> timePoints;

  /// 3D fabric data at each time point
  /// Index corresponds to timePoints index
  final List<Fabric3DData> fabricData;

  /// Time range
  final DateTime startTime;
  final DateTime endTime;

  Worldsheet4DData({
    required this.timePoints,
    required this.fabricData,
    required this.startTime,
    required this.endTime,
  });

  /// Get fabric 3D data at specific time
  Fabric3DData? getFabricAtTime(DateTime t) {
    if (timePoints.isEmpty) return null;

    // Find nearest time point
    int closestIndex = 0;
    var minDiff = (timePoints[0].difference(t)).abs();

    for (int i = 1; i < timePoints.length; i++) {
      final diff = (timePoints[i].difference(t)).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    if (closestIndex < fabricData.length) {
      return fabricData[closestIndex];
    }

    return null;
  }

  /// Get time index for a given time
  int? getTimeIndex(DateTime t) {
    for (int i = 0; i < timePoints.length; i++) {
      if (timePoints[i].isAtSameMomentAs(t)) {
        return i;
      }
    }
    return null;
  }
}

/// 3D fabric data at a specific time point
///
/// Represents the 3D structure of a fabric at a moment in time
class Fabric3DData {
  /// 3D positions of fabric strands
  /// Each strand is a list of 3D points
  final List<List<Vector3>> strandPositions;

  /// Fabric invariants at this time
  final FabricInvariantsData invariants;

  /// Time point
  final DateTime timestamp;

  Fabric3DData({
    required this.strandPositions,
    required this.invariants,
    required this.timestamp,
  });
}

/// Fabric invariants data (simplified for 4D visualization)
class FabricInvariantsData {
  final double stability;
  final double density;
  final int crossingNumber;

  FabricInvariantsData({
    required this.stability,
    required this.density,
    required this.crossingNumber,
  });
}
