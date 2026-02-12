// Entity Knot Model
// 
// Represents any entity (person, event, place, company) as a topological knot
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 1.5: Universal Cross-Pollination Extension

import 'package:avrai_core/models/personality_knot.dart';

/// Entity types that can have knot representations
enum EntityType {
  person,
  event,
  place,
  company,
  brand,        // Future: brand partnerships
  sponsorship,  // Future: sponsorship relationships
}

/// Represents a knot for any entity type
/// 
/// This extends the personality knot concept to all entities in the AI2AI system,
/// enabling cross-entity compatibility calculations and network cross-pollination.
class EntityKnot {
  /// Unique identifier for the entity
  final String entityId;
  
  /// Type of entity (person, event, place, company, etc.)
  final EntityType entityType;
  
  /// The topological knot representation
  /// Reuses PersonalityKnot structure since all knots share the same invariants
  final PersonalityKnot knot;
  
  /// Entity-specific metadata
  /// Examples:
  /// - Event: category, eventType, hostId
  /// - Place: category, rating, latitude, longitude
  /// - Company: businessType, verificationStatus
  final Map<String, dynamic> metadata;
  
  /// Timestamp when knot was generated
  final DateTime createdAt;
  
  /// Timestamp when knot was last updated
  final DateTime lastUpdated;

  EntityKnot({
    required this.entityId,
    required this.entityType,
    required this.knot,
    required this.metadata,
    required this.createdAt,
    required this.lastUpdated,
  });

  /// Create from JSON
  factory EntityKnot.fromJson(Map<String, dynamic> json) {
    return EntityKnot(
      entityId: json['entityId'] ?? '',
      entityType: EntityType.values.firstWhere(
        (e) => e.toString().split('.').last == json['entityType'],
        orElse: () => EntityType.person,
      ),
      knot: PersonalityKnot.fromJson(json['knot'] as Map<String, dynamic>),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityType': entityType.toString().split('.').last,
      'knot': knot.toJson(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create copy with updated fields
  EntityKnot copyWith({
    String? entityId,
    EntityType? entityType,
    PersonalityKnot? knot,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return EntityKnot(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      knot: knot ?? this.knot,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'EntityKnot(entityId: $entityId, entityType: $entityType, '
           'crossingNumber: ${knot.invariants.crossingNumber})';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityKnot &&
          runtimeType == other.runtimeType &&
          entityId == other.entityId &&
          entityType == other.entityType &&
          knot == other.knot;

  @override
  int get hashCode => entityId.hashCode ^ entityType.hashCode ^ knot.hashCode;
}
