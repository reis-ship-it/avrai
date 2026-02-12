// Quantum Entity Type Enum
//
// Defines entity types for multi-entity quantum entanglement matching
// Part of Phase 19: Multi-Entity Quantum Entanglement Matching System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

/// Entity types that can participate in quantum entanglement matching
enum QuantumEntityType {
  /// Expert/User - Can create events, can be matched to events
  expert,

  /// Business - Venues, restaurants, businesses. Can create events (co-hosts, venues)
  business,

  /// Brand - Brands that sponsor events. Cannot create events (sponsors only)
  brand,

  /// Event - The event being hosted. Once created, events are separate entities
  event,

  /// User/Attendee - Users who can be matched to events
  user,

  /// Sponsor - Other sponsorships (media, tech, venue sponsors, etc.)
  sponsor,
}

/// Entity type metadata
class QuantumEntityTypeMetadata {
  /// Whether this entity type can create events
  static bool canCreateEvents(QuantumEntityType type) {
    switch (type) {
      case QuantumEntityType.expert:
      case QuantumEntityType.business:
        return true;
      case QuantumEntityType.brand:
      case QuantumEntityType.event:
      case QuantumEntityType.user:
      case QuantumEntityType.sponsor:
        return false;
    }
  }

  /// Default entity type weight for coefficient optimization
  static double getDefaultWeight(QuantumEntityType type) {
    switch (type) {
      case QuantumEntityType.expert:
        return 0.3;
      case QuantumEntityType.business:
        return 0.25;
      case QuantumEntityType.brand:
        return 0.25;
      case QuantumEntityType.event:
        return 0.2;
      case QuantumEntityType.user:
        return 0.15;
      case QuantumEntityType.sponsor:
        return 0.1;
    }
  }

  /// Role-based weight for coefficient optimization
  static double getRoleWeight(QuantumEntityType type, String role) {
    final baseWeight = getDefaultWeight(type);
    
    switch (role.toLowerCase()) {
      case 'primary':
        return baseWeight * 1.33; // 0.4 for expert
      case 'secondary':
        return baseWeight * 1.0; // 0.3 for business
      case 'sponsor':
        return baseWeight * 0.8; // 0.2 for brand
      case 'event':
        return baseWeight * 0.5; // 0.1 for event
      default:
        return baseWeight;
    }
  }
}