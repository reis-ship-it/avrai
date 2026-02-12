// Hierarchical Layout Model
// 
// Represents a hierarchical layout for fabric clusters
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 5.5: Hierarchical Fabric Visualization System

import 'package:equatable/equatable.dart';
import 'package:avrai_knot/models/entity_knot.dart';
import 'package:avrai_knot/models/knot/radial_position.dart';

/// Hierarchical layout for a fabric cluster
class HierarchicalLayout extends Equatable {
  /// Center entity (highest prominence)
  final EntityKnot center;
  
  /// Positions of all entities (excluding center)
  final Map<EntityKnot, RadialPosition> positions;
  
  /// Connection strengths to center (normalized [0, 1])
  final Map<EntityKnot, double> connectionStrengths;
  
  /// Timestamp when layout was generated
  final DateTime generatedAt;

  const HierarchicalLayout({
    required this.center,
    required this.positions,
    required this.connectionStrengths,
    required this.generatedAt,
  });

  /// Get all entities in layout (center + surrounding)
  List<EntityKnot> get allEntities => [center, ...positions.keys];

  /// Get number of entities in layout
  int get entityCount => 1 + positions.length;

  @override
  List<Object?> get props => [
        center,
        positions,
        connectionStrengths,
        generatedAt,
      ];
}
