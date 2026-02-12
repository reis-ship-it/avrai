/// Structured Facts Model
/// 
/// Represents distilled facts extracted from user interactions.
/// These facts are used to provide context to LLM models.
/// Phase 11 Section 5: Retrieval + LLM Fusion
class StructuredFacts {
  /// User traits/preferences extracted from interactions
  /// Example: ["prefers_coffee", "explorer", "community-focused"]
  final List<String> traits;
  
  /// Place IDs that the user has interacted with
  final List<String> places;
  
  /// Social graph connections/interactions
  /// Example: ["attended_event_123", "friend_user_456"]
  final List<String> socialGraph;
  
  /// Timestamp when facts were extracted
  final DateTime timestamp;
  
  StructuredFacts({
    required this.traits,
    required this.places,
    required this.socialGraph,
    required this.timestamp,
  });
  
  /// Create empty facts
  factory StructuredFacts.empty() {
    return StructuredFacts(
      traits: [],
      places: [],
      socialGraph: [],
      timestamp: DateTime.now(),
    );
  }
  
  /// Merge with another StructuredFacts instance
  StructuredFacts merge(StructuredFacts other) {
    final mergedTraits = <String>{...traits, ...other.traits};
    final mergedPlaces = <String>{...places, ...other.places};
    final mergedSocialGraph = <String>{...socialGraph, ...other.socialGraph};
    
    return StructuredFacts(
      traits: mergedTraits.toList(),
      places: mergedPlaces.toList(),
      socialGraph: mergedSocialGraph.toList(),
      timestamp: timestamp.isAfter(other.timestamp) ? timestamp : other.timestamp,
    );
  }
  
  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'traits': traits,
    'places': places,
    'social_graph': socialGraph,
    'timestamp': timestamp.toIso8601String(),
  };
  
  /// Create from JSON
  factory StructuredFacts.fromJson(Map<String, dynamic> json) {
    return StructuredFacts(
      traits: List<String>.from(json['traits'] ?? []),
      places: List<String>.from(json['places'] ?? []),
      socialGraph: List<String>.from(json['social_graph'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  /// Create a copy with modified fields
  StructuredFacts copyWith({
    List<String>? traits,
    List<String>? places,
    List<String>? socialGraph,
    DateTime? timestamp,
  }) {
    return StructuredFacts(
      traits: traits ?? this.traits,
      places: places ?? this.places,
      socialGraph: socialGraph ?? this.socialGraph,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  String toString() {
    return 'StructuredFacts(traits: ${traits.length}, places: ${places.length}, socialGraph: ${socialGraph.length}, timestamp: $timestamp)';
  }
}
