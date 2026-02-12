// Worldsheet 4D Visualization Service
// 
// Service for preparing 4D worldsheet data for visualization
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Medium Priority: 4D Worldsheet Visualization

import 'dart:developer' as developer;
import 'package:vector_math/vector_math.dart';
import 'package:avrai_knot/models/knot/knot_worldsheet.dart';
import 'package:avrai_knot/models/knot/worldsheet_4d_data.dart';
import 'package:avrai_knot/services/knot/knot_3d_converter_service.dart';

/// Service for preparing 4D worldsheet data for visualization
/// 
/// **Responsibilities:**
/// - Convert KnotWorldsheet to Worldsheet4DData
/// - Extract time points from snapshots
/// - Convert fabric knots to 3D coordinates at each time point
/// - Prepare fabric invariants for visualization
class Worldsheet4DVisualizationService {
  static const String _logName = 'Worldsheet4DVisualizationService';
  
  final Knot3DConverterService _knot3dConverter;
  
  Worldsheet4DVisualizationService({
    Knot3DConverterService? knot3dConverter,
  }) : _knot3dConverter = knot3dConverter ?? Knot3DConverterService();
  
  /// Convert KnotWorldsheet to Worldsheet4DData
  /// 
  /// **Flow:**
  /// 1. Extract all time points (snapshots + initial fabric)
  /// 2. For each time point, get fabric at that time
  /// 3. Convert each user's knot to 3D coordinates
  /// 4. Create Fabric3DData with strand positions
  /// 5. Return Worldsheet4DData
  /// 
  /// **Parameters:**
  /// - `worldsheet`: The worldsheet to convert
  /// - `timeStep`: Optional time step for interpolation (if null, uses snapshots only)
  Future<Worldsheet4DData> convertTo4DData({
    required KnotWorldsheet worldsheet,
    Duration? timeStep,
  }) async {
    developer.log(
      'Converting worldsheet to 4D data: groupId=${worldsheet.groupId}, '
      'snapshots=${worldsheet.snapshots.length}',
      name: _logName,
    );
    
    try {
      // Step 1: Collect all time points
      final timePoints = <DateTime>[];
      
      // Add initial fabric time (createdAt or earliest snapshot - 1 day)
      if (worldsheet.snapshots.isNotEmpty) {
        final sortedSnapshots = List.from(worldsheet.snapshots)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final earliestTime = sortedSnapshots.first.timestamp;
        timePoints.add(earliestTime.subtract(const Duration(days: 1)));
      } else {
        timePoints.add(worldsheet.createdAt);
      }
      
      // Add all snapshot times
      for (final snapshot in worldsheet.snapshots) {
        if (!timePoints.contains(snapshot.timestamp)) {
          timePoints.add(snapshot.timestamp);
        }
      }
      
      // Add interpolated time points if timeStep is provided
      if (timeStep != null && worldsheet.snapshots.isNotEmpty) {
        final sortedSnapshots = List.from(worldsheet.snapshots)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        final startTime = sortedSnapshots.first.timestamp;
        final endTime = sortedSnapshots.last.timestamp;
        
        var currentTime = startTime.add(timeStep);
        while (currentTime.isBefore(endTime)) {
          if (!timePoints.contains(currentTime)) {
            timePoints.add(currentTime);
          }
          currentTime = currentTime.add(timeStep);
        }
      }
      
      // Sort time points
      timePoints.sort();
      
      if (timePoints.isEmpty) {
        developer.log(
          'No time points found, using current time',
          name: _logName,
        );
        timePoints.add(DateTime.now());
      }
      
      // Step 2: Convert fabric at each time point to 3D data
      final fabricDataList = <Fabric3DData>[];
      
      for (final timePoint in timePoints) {
        final fabric = worldsheet.getFabricAtTime(timePoint);
        
        if (fabric == null) {
          developer.log(
            'No fabric found at time $timePoint, skipping',
            name: _logName,
          );
          continue;
        }
        
        // Convert each user's knot to 3D coordinates
        final strandPositions = <List<Vector3>>[];
        
        for (final userKnot in fabric.userKnots) {
          try {
            final knot3d = _knot3dConverter.convertTo3D(userKnot);
            strandPositions.add(knot3d.coordinates);
          } catch (e) {
            developer.log(
              'Failed to convert knot to 3D for user ${userKnot.agentId}: $e',
              name: _logName,
            );
            // Add empty strand if conversion fails
            strandPositions.add([]);
          }
        }
        
        // Create Fabric3DData
        final fabric3dData = Fabric3DData(
          strandPositions: strandPositions,
          invariants: FabricInvariantsData(
            stability: fabric.invariants.stability,
            density: fabric.invariants.density,
            crossingNumber: fabric.invariants.crossingNumber,
          ),
          timestamp: timePoint,
        );
        
        fabricDataList.add(fabric3dData);
      }
      
      // Step 3: Create Worldsheet4DData
      final startTime = timePoints.first;
      final endTime = timePoints.last;
      
      final worldsheet4dData = Worldsheet4DData(
        timePoints: timePoints,
        fabricData: fabricDataList,
        startTime: startTime,
        endTime: endTime,
      );
      
      developer.log(
        '✅ Converted worldsheet to 4D data: ${timePoints.length} time points, '
        '${fabricDataList.length} fabric data points',
        name: _logName,
      );
      
      return worldsheet4dData;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to convert worldsheet to 4D data: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }
  
  /// Get fabric 3D data at specific time (interpolated)
  /// 
  /// Returns interpolated 3D fabric data between time points
  Future<Fabric3DData?> getFabric3DAtTime({
    required Worldsheet4DData worldsheet4d,
    required DateTime time,
  }) async {
    try {
      // Find nearest time point
      final fabricData = worldsheet4d.getFabricAtTime(time);
      
      if (fabricData != null) {
        return fabricData;
      }
      
      // If not found, interpolate between nearest time points
      if (worldsheet4d.timePoints.isEmpty) {
        return null;
      }
      
      // Find surrounding time points
      DateTime? beforeTime;
      DateTime? afterTime;
      Fabric3DData? beforeData;
      Fabric3DData? afterData;
      
      for (int i = 0; i < worldsheet4d.timePoints.length; i++) {
        if (worldsheet4d.timePoints[i].isAfter(time)) {
          afterTime = worldsheet4d.timePoints[i];
          afterData = worldsheet4d.fabricData[i];
          if (i > 0) {
            beforeTime = worldsheet4d.timePoints[i - 1];
            beforeData = worldsheet4d.fabricData[i - 1];
          }
          break;
        }
      }
      
      // Interpolate if we have both before and after
      if (beforeData != null && afterData != null && beforeTime != null && afterTime != null) {
        return _interpolateFabric3D(beforeData, afterData, beforeTime, afterTime, time);
      }
      
      return beforeData ?? afterData;
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to get fabric 3D at time: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      return null;
    }
  }
  
  /// Interpolate between two Fabric3DData points
  Fabric3DData _interpolateFabric3D(
    Fabric3DData before,
    Fabric3DData after,
    DateTime beforeTime,
    DateTime afterTime,
    DateTime targetTime,
  ) {
    // Calculate interpolation factor
    final totalDuration = afterTime.difference(beforeTime).inMilliseconds;
    final targetDuration = targetTime.difference(beforeTime).inMilliseconds;
    final factor = (targetDuration / totalDuration.clamp(1, double.maxFinite.toInt()))
        .clamp(0.0, 1.0);
    
    // Interpolate strand positions
    final maxStrands = before.strandPositions.length > after.strandPositions.length
        ? before.strandPositions.length
        : after.strandPositions.length;
    
    final interpolatedStrands = <List<Vector3>>[];
    
    for (int i = 0; i < maxStrands; i++) {
      final beforeStrand = i < before.strandPositions.length
          ? before.strandPositions[i]
          : <Vector3>[];
      final afterStrand = i < after.strandPositions.length
          ? after.strandPositions[i]
          : <Vector3>[];
      
      // Interpolate strand positions
      final maxPoints = beforeStrand.length > afterStrand.length
          ? beforeStrand.length
          : afterStrand.length;
      
      final interpolatedStrand = <Vector3>[];
      
      for (int j = 0; j < maxPoints; j++) {
        final beforePoint = j < beforeStrand.length ? beforeStrand[j] : Vector3.zero();
        final afterPoint = j < afterStrand.length ? afterStrand[j] : Vector3.zero();
        
        // Linear interpolation: lerp(a, b, t) = a + (b - a) * t
        final interpolatedPoint = beforePoint + (afterPoint - beforePoint) * factor;
        interpolatedStrand.add(interpolatedPoint);
      }
      
      interpolatedStrands.add(interpolatedStrand);
    }
    
    // Interpolate invariants
    final interpolatedInvariants = FabricInvariantsData(
      stability: (before.invariants.stability * (1 - factor) +
          after.invariants.stability * factor),
      density: (before.invariants.density * (1 - factor) +
          after.invariants.density * factor),
      crossingNumber: ((before.invariants.crossingNumber * (1 - factor) +
          after.invariants.crossingNumber * factor).round()),
    );
    
    return Fabric3DData(
      strandPositions: interpolatedStrands,
      invariants: interpolatedInvariants,
      timestamp: targetTime,
    );
  }
}
