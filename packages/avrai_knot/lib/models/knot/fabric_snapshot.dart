// Fabric Snapshot Model
// 
// Represents a snapshot of a knot fabric at a specific point in time
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase: Knot Orchestration & Worldsheet Generation

import 'package:avrai_knot/models/knot/knot_fabric.dart';
import 'package:avrai_knot/models/knot/fabric_evolution.dart';

/// Fabric Snapshot
/// 
/// Represents a discrete snapshot of a fabric at a specific time
/// Similar to KnotSnapshot but for groups/fabrics
class FabricSnapshot {
  /// Timestamp of snapshot
  final DateTime timestamp;
  
  /// Fabric at this time
  final KnotFabric fabric;
  
  /// Reason for snapshot (member joined, left, fabric evolved, etc.)
  final String? reason;
  
  /// Fabric evolution data (if this snapshot represents an evolution)
  final FabricEvolution? evolution;
  
  FabricSnapshot({
    required this.timestamp,
    required this.fabric,
    this.reason,
    this.evolution,
  });
  
  /// Create from JSON
  factory FabricSnapshot.fromJson(Map<String, dynamic> json) {
    return FabricSnapshot(
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      fabric: KnotFabric.fromJson(json['fabric'] as Map<String, dynamic>),
      reason: json['reason'],
      evolution: json['evolution'] != null
          ? FabricEvolution.fromJson(json['evolution'] as Map<String, dynamic>)
          : null,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'fabric': fabric.toJson(),
      'reason': reason,
      'evolution': evolution?.toJson(),
    };
  }
}
