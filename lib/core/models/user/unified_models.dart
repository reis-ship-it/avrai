// Unified Models for SPOTS
// Date: August 1, 2025
// Purpose: Resolve type conflicts across AI/ML modules

import 'dart:math' as math;

/// Unified UserAction enum to resolve type conflicts
enum UserAction {
  spotVisit,
  listCreate,
  feedbackGiven,
  spotRespect,
  listRespect,
  profileUpdate,
  locationChange,
  searchQuery,
  filterApplied,
  mapInteraction,
  onboardingComplete,
  aiInteraction,
  communityJoin,
  eventAttend,
  recommendationAccept,
  recommendationReject,
}

/// Unified UserAction class for compatibility with existing code
class UnifiedUserAction {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final UnifiedLocation? location;
  final UnifiedSocialContext socialContext;
  
  const UnifiedUserAction({
    required this.type,
    required this.timestamp,
    required this.metadata,
    this.location,
    required this.socialContext,
  });

  factory UnifiedUserAction.fromJson(Map<String, dynamic> json) {
    return UnifiedUserAction(
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      location: json['location'] != null 
          ? UnifiedLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      socialContext: UnifiedSocialContext.fromJson(json['socialContext'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'location': location?.toJson(),
      'socialContext': socialContext.toJson(),
    };
  }
}

/// Unified User model
class UnifiedUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> preferences;
  final List<String> homebases;
  final int experienceLevel;
  final List<String> pins;
  final String? role; // optional to satisfy legacy tests
  final bool? isActive; // legacy param in tests
  // Legacy fields used by some tests
  final List<String> curatedLists = const [];
  final List<String> collaboratedLists = const [];
  final List<String> followedLists = const [];

  const UnifiedUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.preferences,
    required this.homebases,
    required this.experienceLevel,
    required this.pins,
    this.role,
    this.isActive,
    dynamic personalityProfile,
  });

  factory UnifiedUser.fromJson(Map<String, dynamic> json) {
    return UnifiedUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      homebases: List<String>.from(json['homebases'] ?? []),
      experienceLevel: json['experienceLevel'] as int? ?? 0,
      pins: List<String>.from(json['pins'] ?? []),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
      'homebases': homebases,
      'experienceLevel': experienceLevel,
      'pins': pins,
      'role': role,
    };
  }

  UnifiedUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    List<String>? homebases,
    int? experienceLevel,
    List<String>? pins,
    String? role,
  }) {
    return UnifiedUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      homebases: homebases ?? this.homebases,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      pins: pins ?? this.pins,
      role: role ?? this.role,
    );
  }
}

/// Unified Location model
class UnifiedLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final DateTime? timestamp;
  final double? accuracy;
  final double? altitude;
  final double? speed;

  const UnifiedLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.timestamp,
    this.accuracy,
    this.altitude,
    this.speed,
  });

  factory UnifiedLocation.fromJson(Map<String, dynamic> json) {
    return UnifiedLocation(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postalCode'] as String?,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : null,
      accuracy: json['accuracy'] as double?,
      altitude: json['altitude'] as double?,
      speed: json['speed'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'timestamp': timestamp?.toIso8601String(),
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
    };
  }

  double distanceTo(UnifiedLocation other) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = latitude * math.pi / 180;
    final double lat2Rad = other.latitude * math.pi / 180;
    final double deltaLat = (other.latitude - latitude) * math.pi / 180;
    final double deltaLon = (other.longitude - longitude) * math.pi / 180;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

/// Unified SocialContext model
class UnifiedSocialContext {
  final List<String> nearbyUsers;
  final List<String> friends;
  final List<String> communityMembers;
  final Map<String, dynamic> socialMetrics;
  final DateTime timestamp;
  final String? eventId;
  final String? groupId;

  const UnifiedSocialContext({
    required this.nearbyUsers,
    required this.friends,
    required this.communityMembers,
    required this.socialMetrics,
    required this.timestamp,
    this.eventId,
    this.groupId,
  });

  factory UnifiedSocialContext.fromJson(Map<String, dynamic> json) {
    return UnifiedSocialContext(
      nearbyUsers: List<String>.from(json['nearbyUsers'] ?? []),
      friends: List<String>.from(json['friends'] ?? []),
      communityMembers: List<String>.from(json['communityMembers'] ?? []),
      socialMetrics: Map<String, dynamic>.from(json['socialMetrics'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventId: json['eventId'] as String?,
      groupId: json['groupId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nearbyUsers': nearbyUsers,
      'friends': friends,
      'communityMembers': communityMembers,
      'socialMetrics': socialMetrics,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
      'groupId': groupId,
    };
  }
}

/// Unified AI/ML Models
class UnifiedAIModel {
  final String id;
  final String name;
  final String version;
  final Map<String, dynamic> parameters;
  final DateTime lastUpdated;
  final double accuracy;
  final String status;

  const UnifiedAIModel({
    required this.id,
    required this.name,
    required this.version,
    required this.parameters,
    required this.lastUpdated,
    required this.accuracy,
    required this.status,
  });

  factory UnifiedAIModel.fromJson(Map<String, dynamic> json) {
    return UnifiedAIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      accuracy: json['accuracy'] as double? ?? 0.0,
      status: json['status'] as String? ?? 'inactive',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'parameters': parameters,
      'lastUpdated': lastUpdated.toIso8601String(),
      'accuracy': accuracy,
      'status': status,
    };
  }
}

/// Orchestration Event for AI Master Orchestrator
class OrchestrationEvent {
  final String eventType;
  final double value;
  final DateTime timestamp;
  
  const OrchestrationEvent({
    required this.eventType,
    required this.value,
    required this.timestamp,
  });

  factory OrchestrationEvent.fromJson(Map<String, dynamic> json) {
    return OrchestrationEvent(
      eventType: json['eventType'] as String,
      value: json['value'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
