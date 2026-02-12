// Knot Worldsheet Model
// 
// Represents a 2D plane/worldsheet for group evolution
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Orchestration & Worldsheet Generation
//
// Mathematical representation: Σ(σ, τ, t) = F(t)
// Where:
// - σ = spatial parameter (position along each individual string/user)
// - τ = group parameter (which user/strand in the fabric)
// - t = time parameter
// - Σ(σ, τ, t) = fabric configuration at time t
// - F(t) = the KnotFabric at time t

import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_snapshot.dart';
import 'package:avrai_knot/models/knot/fabric_invariants.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/worldsheet_evolution_dynamics.dart';
import 'package:avrai_knot/utils/polynomial_interpolation.dart';

/// Worldsheet representation of group evolution
/// 
/// Represents continuous evolution of a group fabric: Σ(σ, τ, t) = F(t)
/// This is a 2D surface where:
/// - One dimension (σ) represents individual user evolution (strings)
/// - One dimension (τ) represents group composition (which users)
/// - Time (t) represents temporal evolution
class KnotWorldsheet {
  /// Group identifier
  final String groupId;
  
  /// Initial fabric (at t=0 or earliest snapshot)
  final KnotFabric initialFabric;
  
  /// Evolution snapshots (discrete points in time)
  final List<FabricSnapshot> snapshots;
  
  /// Individual user strings (map from agentId to KnotString)
  /// These represent the σ dimension (individual evolution)
  final Map<String, KnotString> userStrings;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Last updated timestamp
  final DateTime lastUpdated;
  
  KnotWorldsheet({
    required this.groupId,
    required this.initialFabric,
    required this.snapshots,
    required this.userStrings,
    required this.createdAt,
    required this.lastUpdated,
  });
  
  /// Get fabric at any time t (interpolated between snapshots)
  /// 
  /// Uses linear interpolation between nearest snapshots
  /// If t is before first snapshot, returns initial fabric
  /// If t is after last snapshot, extrapolates using evolution dynamics
  KnotFabric? getFabricAtTime(DateTime t) {
    if (snapshots.isEmpty) {
      return initialFabric;
    }
    
    // Sort snapshots by timestamp
    final sortedSnapshots = List<FabricSnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Check if before first snapshot
    if (t.isBefore(sortedSnapshots.first.timestamp)) {
      return initialFabric;
    }
    
    // Check if after last snapshot (extrapolate using evolution dynamics)
    if (t.isAfter(sortedSnapshots.last.timestamp)) {
      return _extrapolateFabric(sortedSnapshots, t);
    }
    
    // Find surrounding snapshots
    FabricSnapshot? before;
    FabricSnapshot? after;
    
    for (int i = 0; i < sortedSnapshots.length; i++) {
      if (sortedSnapshots[i].timestamp.isAfter(t)) {
        after = sortedSnapshots[i];
        if (i > 0) {
          before = sortedSnapshots[i - 1];
        } else {
          before = null;
        }
        break;
      }
    }
    
    // If exactly on a snapshot
    if (before != null && before.timestamp == t) {
      return before.fabric;
    }
    if (after != null && after.timestamp == t) {
      return after.fabric;
    }
    
    // Interpolate between snapshots using polynomial interpolation
    if (before != null && after != null) {
      return _interpolateFabricPolynomial(before, after, t);
    }
    
    return null;
  }
  
  /// Get individual user's string within the worldsheet
  /// 
  /// Returns the KnotString for a specific user (σ dimension)
  KnotString? getUserString(String agentId) {
    return userStrings[agentId];
  }
  
  /// Get cross-section at time t (all users at that moment)
  /// 
  /// Returns list of PersonalityKnots for all users at time t
  /// This is a "slice" through the worldsheet at a specific time
  List<PersonalityKnot> getCrossSectionAtTime(DateTime t) {
    final knots = <PersonalityKnot>[];
    
    for (final entry in userStrings.entries) {
      final knot = entry.value.getKnotAtTime(t);
      if (knot != null) {
        knots.add(knot);
      }
    }
    
    return knots;
  }
  
  /// Get all user IDs in the worldsheet
  List<String> get userIds => userStrings.keys.toList();
  
  /// Get time span of worldsheet
  Duration get timeSpan {
    if (snapshots.isEmpty) {
      return Duration.zero;
    }
    
    final sortedSnapshots = List<FabricSnapshot>.from(snapshots)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return sortedSnapshots.last.timestamp
        .difference(sortedSnapshots.first.timestamp);
  }
  
  /// Interpolate fabric between two snapshots using polynomial interpolation
  /// 
  /// Uses cubic spline interpolation for smooth fabric evolution
  KnotFabric _interpolateFabricPolynomial(
    FabricSnapshot before,
    FabricSnapshot after,
    DateTime targetTime,
  ) {
    final fabric1 = before.fabric;
    final fabric2 = after.fabric;
    final t1 = before.timestamp;
    final t2 = after.timestamp;
    
    // Calculate interpolation factor (0.0 = fabric1, 1.0 = fabric2)
    final totalDuration = t2.difference(t1).inMilliseconds;
    final targetDuration = targetTime.difference(t1).inMilliseconds;
    final factor = (targetDuration / totalDuration.clamp(1, double.maxFinite.toInt()))
        .clamp(0.0, 1.0);
    
    // Interpolate fabric invariants using cubic spline
    final jones1 = fabric1.invariants.jonesPolynomial.coefficients;
    final jones2 = fabric2.invariants.jonesPolynomial.coefficients;
    final interpolatedJones = cubicSplineInterpolateList(jones1, jones2, factor);
    
    final alexander1 = fabric1.invariants.alexanderPolynomial.coefficients;
    final alexander2 = fabric2.invariants.alexanderPolynomial.coefficients;
    final interpolatedAlexander = cubicSplineInterpolateList(alexander1, alexander2, factor);
    
    // Interpolate scalar properties using cubic spline
    final interpolatedCrossingNumber = cubicSplineInterpolateScalar(
      [fabric1.invariants.crossingNumber.toDouble(), 
       fabric2.invariants.crossingNumber.toDouble()],
      factor,
    ).round();
    
    final interpolatedDensity = cubicSplineInterpolateScalar(
      [fabric1.invariants.density, fabric2.invariants.density],
      factor,
    );
    
    final interpolatedStability = cubicSplineInterpolateScalar(
      [fabric1.invariants.stability, fabric2.invariants.stability],
      factor,
    );
    
    // Interpolate user knots (simplified - use first fabric's knots)
    // In a full implementation, would interpolate each user's knot individually
    final interpolatedUserKnots = fabric1.userKnots; // Simplified
    
    // Interpolate braid data (simplified)
    final interpolatedBraid = fabric1.braid; // Simplified - would interpolate braid data
    
    return KnotFabric(
      fabricId: fabric1.fabricId,
      userKnots: interpolatedUserKnots,
      braid: interpolatedBraid,
      invariants: FabricInvariants(
        jonesPolynomial: Polynomial(interpolatedJones),
        alexanderPolynomial: Polynomial(interpolatedAlexander),
        crossingNumber: interpolatedCrossingNumber,
        density: interpolatedDensity,
        stability: interpolatedStability,
      ),
      createdAt: fabric1.createdAt,
      updatedAt: targetTime,
    );
  }
  
  /// Extrapolate fabric beyond last snapshot using evolution dynamics
  /// 
  /// Uses evolution dynamics to predict future fabric state
  KnotFabric _extrapolateFabric(List<FabricSnapshot> sortedSnapshots, DateTime t) {
    if (sortedSnapshots.length < 2) {
      // Not enough history for extrapolation
      return sortedSnapshots.last.fabric;
    }
    
    final lastSnapshot = sortedSnapshots.last;
    final secondLastSnapshot = sortedSnapshots[sortedSnapshots.length - 2];
    
    // Calculate evolution rate
    final dynamics = WorldsheetEvolutionDynamics();
    final evolutionRate = dynamics.calculateEvolutionRate(
      secondLastSnapshot,
      lastSnapshot,
    );
    
    // Predict future state
    return dynamics.predictFabricState(
      currentFabric: lastSnapshot.fabric,
      currentTime: lastSnapshot.timestamp,
      futureTime: t,
      evolutionRate: evolutionRate,
      historySnapshots: sortedSnapshots,
    );
  }
  
  /// Create from JSON
  factory KnotWorldsheet.fromJson(Map<String, dynamic> json) {
    return KnotWorldsheet(
      groupId: json['groupId'] ?? '',
      initialFabric: KnotFabric.fromJson(
        json['initialFabric'] as Map<String, dynamic>,
      ),
      snapshots: (json['snapshots'] as List<dynamic>?)
              ?.map((s) => FabricSnapshot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      userStrings: {}, // TODO: Implement KnotString serialization
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'initialFabric': initialFabric.toJson(),
      'snapshots': snapshots.map((s) => s.toJson()).toList(),
      'userStrings': {}, // TODO: Implement KnotString serialization
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
