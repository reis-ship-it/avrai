// Fabric Evolution Model
// 
// Represents changes in a knot fabric over time
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5: Knot Fabric for Community Representation

import 'package:equatable/equatable.dart';
import 'package:avrai_knot/models/knot/knot_fabric.dart';

/// Type of change in the fabric
enum FabricChangeType {
  /// New user joined (knot added)
  newKnot,
  
  /// User left (knot removed)
  removedKnot,
  
  /// New relationship/connection added
  relationshipAdded,
  
  /// Relationship/connection removed
  relationshipRemoved,
  
  /// Individual knot evolved (user's personality changed)
  knotEvolved,
}

/// A change in the fabric
class FabricChange extends Equatable {
  final FabricChangeType type;
  final String? userKnotId;
  final String? relationshipId;
  final Map<String, dynamic>? metadata;
  
  const FabricChange({
    required this.type,
    this.userKnotId,
    this.relationshipId,
    this.metadata,
  });
  
  @override
  List<Object?> get props => [type, userKnotId, relationshipId, metadata];

  /// Create from JSON
  factory FabricChange.fromJson(Map<String, dynamic> json) {
    return FabricChange(
      type: FabricChangeType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FabricChangeType.knotEvolved,
      ),
      userKnotId: json['userKnotId'],
      relationshipId: json['relationshipId'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'userKnotId': userKnotId,
      'relationshipId': relationshipId,
      'metadata': metadata,
    };
  }
  
  /// Get description of the change
  String get description {
    switch (type) {
      case FabricChangeType.newKnot:
        return 'User ${userKnotId ?? 'unknown'} joined';
      case FabricChangeType.removedKnot:
        return 'User ${userKnotId ?? 'unknown'} left';
      case FabricChangeType.relationshipAdded:
        return 'Relationship ${relationshipId ?? 'unknown'} added';
      case FabricChangeType.relationshipRemoved:
        return 'Relationship ${relationshipId ?? 'unknown'} removed';
      case FabricChangeType.knotEvolved:
        return 'User ${userKnotId ?? 'unknown'} knot evolved';
    }
  }
}

/// Fabric Evolution
/// 
/// Tracks how a fabric changes over time
class FabricEvolution extends Equatable {
  final KnotFabric currentFabric;
  final KnotFabric previousFabric;
  final List<FabricChange> changes;
  final double stabilityChange;
  final DateTime timestamp;
  
  const FabricEvolution({
    required this.currentFabric,
    required this.previousFabric,
    required this.changes,
    required this.stabilityChange,
    required this.timestamp,
  });
  
  /// Check if stability improved
  bool get stabilityImproved => stabilityChange > 0;
  
  /// Check if stability declined
  bool get stabilityDeclined => stabilityChange < 0;
  
  /// Get number of changes
  int get changeCount => changes.length;
  
  @override
  List<Object?> get props => [
    currentFabric,
    previousFabric,
    changes,
    stabilityChange,
    timestamp,
  ];
  
  /// Create a copy with updated fields
  FabricEvolution copyWith({
    KnotFabric? currentFabric,
    KnotFabric? previousFabric,
    List<FabricChange>? changes,
    double? stabilityChange,
    DateTime? timestamp,
  }) {
    return FabricEvolution(
      currentFabric: currentFabric ?? this.currentFabric,
      previousFabric: previousFabric ?? this.previousFabric,
      changes: changes ?? this.changes,
      stabilityChange: stabilityChange ?? this.stabilityChange,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Create from JSON
  factory FabricEvolution.fromJson(Map<String, dynamic> json) {
    return FabricEvolution(
      currentFabric: KnotFabric.fromJson(
        json['currentFabric'] as Map<String, dynamic>,
      ),
      previousFabric: KnotFabric.fromJson(
        json['previousFabric'] as Map<String, dynamic>,
      ),
      changes: (json['changes'] as List<dynamic>?)
              ?.map((c) => FabricChange.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      stabilityChange: (json['stabilityChange'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'currentFabric': currentFabric.toJson(),
      'previousFabric': previousFabric.toJson(),
      'changes': changes.map((c) => c.toJson()).toList(),
      'stabilityChange': stabilityChange,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
