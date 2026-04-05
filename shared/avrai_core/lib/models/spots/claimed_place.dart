import 'package:equatable/equatable.dart';

/// Represents a business's claim on a place (by Google Place ID).
///
/// One business can claim many places; one place is claimed by at most one business.
/// Used for "Claim a place" flow and "Events at your places" on the business dashboard.
class ClaimedPlace extends Equatable {
  final String id;
  final String businessId;
  final String googlePlaceId;
  final DateTime claimedAt;
  final String? verificationMethod;

  /// Per-place attraction 12D override. When non-null, used instead of
  /// business-level attraction for user-place compatibility.
  final Map<String, double>? attractionOverride;

  const ClaimedPlace({
    required this.id,
    required this.businessId,
    required this.googlePlaceId,
    required this.claimedAt,
    this.verificationMethod,
    this.attractionOverride,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'business_id': businessId,
        'google_place_id': googlePlaceId,
        'claimed_at': claimedAt.toIso8601String(),
        'verification_method': verificationMethod,
        'attraction_override':
            attractionOverride?.map((k, v) => MapEntry(k, v)),
      };

  factory ClaimedPlace.fromJson(Map<String, dynamic> json) {
    final claimedAt = json['claimed_at'];
    final override = json['attraction_override'];
    Map<String, double>? attractionOverride;
    if (override is Map) {
      attractionOverride = override.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      );
    }
    return ClaimedPlace(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      googlePlaceId: json['google_place_id'] as String,
      claimedAt: claimedAt is DateTime
          ? claimedAt
          : DateTime.parse(claimedAt as String),
      verificationMethod: json['verification_method'] as String?,
      attractionOverride: attractionOverride,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessId,
        googlePlaceId,
        claimedAt,
        verificationMethod,
        attractionOverride,
      ];
}
