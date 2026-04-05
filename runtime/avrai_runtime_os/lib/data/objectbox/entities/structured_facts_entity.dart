import 'dart:convert';

import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for StructuredFacts
///
/// Stores distilled facts extracted from user interactions.
/// Used to provide context to LLM models.
///
/// Phase 26: Multi-Device Storage Migration
@Entity()
class StructuredFactsEntity {
  /// ObjectBox ID (auto-assigned)
  @Id()
  int id = 0;

  /// Agent/User ID (unique per agent)
  @Unique()
  String? agentId;

  /// User traits/preferences as JSON array
  /// Example: ["prefers_coffee", "explorer", "community-focused"]
  String? traitsJson;

  /// Place IDs as JSON array
  String? placesJson;

  /// Social graph connections as JSON array
  /// Example: ["attended_event_123", "friend_user_456"]
  String? socialGraphJson;

  /// Extraction timestamp
  @Property(type: PropertyType.date)
  DateTime? timestamp;

  /// Last update timestamp
  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  /// Cloud sync timestamp
  @Property(type: PropertyType.date)
  DateTime? syncedAt;

  /// Whether this needs to be synced
  bool pendingSync;

  StructuredFactsEntity({
    this.id = 0,
    this.agentId,
    this.traitsJson,
    this.placesJson,
    this.socialGraphJson,
    this.timestamp,
    this.updatedAt,
    this.syncedAt,
    this.pendingSync = false,
  });

  /// Get traits as list
  List<String> get traits {
    if (traitsJson == null || traitsJson!.isEmpty) return [];
    try {
      final list = jsonDecode(traitsJson!) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Set traits
  set traits(List<String> value) {
    traitsJson = jsonEncode(value);
  }

  /// Get places as list
  List<String> get places {
    if (placesJson == null || placesJson!.isEmpty) return [];
    try {
      final list = jsonDecode(placesJson!) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Set places
  set places(List<String> value) {
    placesJson = jsonEncode(value);
  }

  /// Get social graph as list
  List<String> get socialGraph {
    if (socialGraphJson == null || socialGraphJson!.isEmpty) return [];
    try {
      final list = jsonDecode(socialGraphJson!) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Set social graph
  set socialGraph(List<String> value) {
    socialGraphJson = jsonEncode(value);
  }

  /// Convert to JSON for export
  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'traits': traits,
        'places': places,
        'social_graph': socialGraph,
        'timestamp': timestamp?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };

  /// Create from JSON
  factory StructuredFactsEntity.fromJson(Map<String, dynamic> json) {
    return StructuredFactsEntity(
      agentId: json['agent_id'] as String?,
      traitsJson: json['traits'] != null ? jsonEncode(json['traits']) : null,
      placesJson: json['places'] != null ? jsonEncode(json['places']) : null,
      socialGraphJson: json['social_graph'] != null
          ? jsonEncode(json['social_graph'])
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      syncedAt: json['synced_at'] != null
          ? DateTime.parse(json['synced_at'] as String)
          : null,
    );
  }

  /// Create from domain StructuredFacts
  factory StructuredFactsEntity.fromDomain({
    required String agentId,
    required List<String> traits,
    required List<String> places,
    required List<String> socialGraph,
    required DateTime timestamp,
  }) {
    return StructuredFactsEntity(
      agentId: agentId,
      traitsJson: jsonEncode(traits),
      placesJson: jsonEncode(places),
      socialGraphJson: jsonEncode(socialGraph),
      timestamp: timestamp,
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
  }

  /// Merge with another facts entity
  StructuredFactsEntity merge(StructuredFactsEntity other) {
    final mergedTraits = <String>{...traits, ...other.traits};
    final mergedPlaces = <String>{...places, ...other.places};
    final mergedSocialGraph = <String>{...socialGraph, ...other.socialGraph};

    return StructuredFactsEntity(
      id: id,
      agentId: agentId,
      traitsJson: jsonEncode(mergedTraits.toList()),
      placesJson: jsonEncode(mergedPlaces.toList()),
      socialGraphJson: jsonEncode(mergedSocialGraph.toList()),
      timestamp:
          (timestamp?.isAfter(other.timestamp ?? DateTime(1970)) ?? false)
              ? timestamp
              : other.timestamp,
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
  }
}
