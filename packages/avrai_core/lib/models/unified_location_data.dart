import 'dart:math' as math;
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unified_location_data.g.dart';

@JsonSerializable()
class UnifiedLocationData extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? postalCode;
  final double? accuracy; // Location accuracy in meters
  final DateTime? timestamp; // When location was captured
  
  const UnifiedLocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.region,
    this.country,
    this.postalCode,
    this.accuracy,
    this.timestamp,
  });
  
  /// Create location from coordinates only
  factory UnifiedLocationData.fromCoordinates(double latitude, double longitude) {
    return UnifiedLocationData(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }
  
  /// Create location with full address information
  factory UnifiedLocationData.fromAddress({
    required double latitude,
    required double longitude,
    required String address,
    String? city,
    String? region,
    String? country,
    String? postalCode,
    double? accuracy,
  }) {
    return UnifiedLocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      region: region,
      country: country,
      postalCode: postalCode,
      accuracy: accuracy,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get full formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (region != null) parts.add(region!);
    if (country != null) parts.add(country!);
    if (postalCode != null) parts.add(postalCode!);
    
    return parts.join(', ');
  }
  
  /// Get short address (street + city)
  String get shortAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    
    return parts.join(', ');
  }
  
  /// Calculate distance to another location in kilometers
  double distanceTo(UnifiedLocationData other) {
    return _calculateHaversineDistance(
      latitude, longitude, 
      other.latitude, other.longitude,
    );
  }
  
  /// Check if location is within radius of another location
  bool isWithinRadius(UnifiedLocationData center, double radiusKm) {
    return distanceTo(center) <= radiusKm;
  }
  
  /// Check if location has address information
  bool get hasAddressInfo => address != null || city != null;
  
  /// Check if location is recent (within last hour)
  bool get isRecent {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!).inHours < 1;
  }
  
  /// Get accuracy description
  String get accuracyDescription {
    if (accuracy == null) return 'Unknown';
    if (accuracy! < 5) return 'Excellent';
    if (accuracy! < 20) return 'Good';
    if (accuracy! < 100) return 'Fair';
    return 'Poor';
  }
  
  // Haversine distance calculation
  static double _calculateHaversineDistance(
    double lat1, double lon1, 
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) => degrees * (math.pi / 180);
  
  factory UnifiedLocationData.fromJson(Map<String, dynamic> json) => 
      _$UnifiedLocationDataFromJson(json);
  Map<String, dynamic> toJson() => _$UnifiedLocationDataToJson(this);
  
  UnifiedLocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? region,
    String? country,
    String? postalCode,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return UnifiedLocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }
  
  @override
  List<Object?> get props => [
    latitude, longitude, address, city, region, country, 
    postalCode, accuracy, timestamp,
  ];
}
