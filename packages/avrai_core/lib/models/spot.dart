import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../enums/spot_enums.dart';

part 'spot.g.dart';

@JsonSerializable()
class Spot extends Equatable {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String category; // Will be enum in future
  final double rating;
  final String createdBy; // User ID
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields
  final String? address;
  final String? phoneNumber;
  final String? website;
  final String? imageUrl;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final PriceLevel? priceLevel;
  final VerificationLevel verificationLevel;
  final ModerationStatus moderationStatus;
  final bool isAgeRestricted;
  final String? listId; // Associated list if any
  
  // Google Places integration
  final String? googlePlaceId; // Google Place ID for syncing with Google Maps
  final DateTime? googlePlaceIdSyncedAt; // When Google Place ID was last synced
  
  // Engagement metrics
  final int viewCount;
  final int respectCount;
  final int shareCount;
  final List<String> respectedBy; // User IDs
  
  const Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.rating = 0.0,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.phoneNumber,
    this.website,
    this.imageUrl,
    this.tags = const [],
    this.metadata = const {},
    this.priceLevel,
    this.verificationLevel = VerificationLevel.none,
    this.moderationStatus = ModerationStatus.pending,
    this.isAgeRestricted = false,
    this.listId,
    this.viewCount = 0,
    this.respectCount = 0,
    this.shareCount = 0,
    this.respectedBy = const [],
    this.googlePlaceId,
    this.googlePlaceIdSyncedAt,
  });
  
  /// Check if spot is publicly visible
  bool get isVisible => moderationStatus.isVisible && !isAgeRestricted;
  
  /// Check if spot is verified at any level
  bool get isVerified => verificationLevel != VerificationLevel.none;
  
  /// Get trust score based on verification level
  int get trustScore => verificationLevel.trustScore;
  
  /// Calculate engagement score
  double get engagementScore => 
      (viewCount * 0.1) + (respectCount * 1.0) + (shareCount * 2.0);
  
  /// Check if user has respected this spot
  bool isRespectedBy(String userId) => respectedBy.contains(userId);
  
  /// Get distance from a point (in kilometers)
  double distanceFrom(double lat, double lng) {
    const double earthRadius = 6371; // Earth's radius in km
    final double latDiff = _toRadians(lat - latitude);
    final double lngDiff = _toRadians(lng - longitude);
    
    final double a = 
        math.sin(latDiff / 2) * math.sin(latDiff / 2) +
        math.cos(_toRadians(latitude)) * math.cos(_toRadians(lat)) *
        math.sin(lngDiff / 2) * math.sin(lngDiff / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  
  double _toRadians(double degrees) => degrees * (math.pi / 180);
  
  factory Spot.fromJson(Map<String, dynamic> json) => _$SpotFromJson(json);
  Map<String, dynamic> toJson() => _$SpotToJson(this);
  
  Spot copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? category,
    double? rating,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? address,
    String? phoneNumber,
    String? website,
    String? imageUrl,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    PriceLevel? priceLevel,
    VerificationLevel? verificationLevel,
    ModerationStatus? moderationStatus,
    bool? isAgeRestricted,
    String? listId,
    int? viewCount,
    int? respectCount,
    int? shareCount,
    List<String>? respectedBy,
    String? googlePlaceId,
    DateTime? googlePlaceIdSyncedAt,
  }) {
    return Spot(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      priceLevel: priceLevel ?? this.priceLevel,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      isAgeRestricted: isAgeRestricted ?? this.isAgeRestricted,
      listId: listId ?? this.listId,
      viewCount: viewCount ?? this.viewCount,
      respectCount: respectCount ?? this.respectCount,
      shareCount: shareCount ?? this.shareCount,
      respectedBy: respectedBy ?? this.respectedBy,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      googlePlaceIdSyncedAt: googlePlaceIdSyncedAt ?? this.googlePlaceIdSyncedAt,
    );
  }
  
  @override
  List<Object?> get props => [
    id, name, description, latitude, longitude, category, rating,
    createdBy, createdAt, updatedAt, address, phoneNumber, website,
    imageUrl, tags, metadata, priceLevel, verificationLevel,
    moderationStatus, isAgeRestricted, listId, viewCount,
    respectCount, shareCount, respectedBy, googlePlaceId, googlePlaceIdSyncedAt,
  ];
  
  /// Check if spot has Google Place ID mapping
  bool get hasGooglePlaceId => googlePlaceId != null && googlePlaceId!.isNotEmpty;
  
  /// Check if Google Place ID sync is stale (older than 30 days)
  bool get isGooglePlaceIdStale {
    if (googlePlaceIdSyncedAt == null) return true;
    return DateTime.now().difference(googlePlaceIdSyncedAt!) > const Duration(days: 30);
  }
}
