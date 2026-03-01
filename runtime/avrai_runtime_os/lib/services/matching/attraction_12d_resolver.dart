// Attraction 12D resolver: entity type + entity → 12D vector for compatibility.
//
// For user–business, user–event, user–place we use **attraction** semantics:
// the entity side returns "what we want to attract" (12 inverse reference
// points). Person–person and business–business use raw dimensions (similarity).

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/spots/spot_vibe.dart';
import 'package:avrai_core/models/spots/spot.dart';
import 'package:avrai_core/utils/attraction_dimensions.dart';

/// Resolves the 12D vector to use for the **entity** side in user–entity
/// compatibility. Returns **attraction** 12D (reflected/complementary) for
/// company, place, event; caller supplies raw dimensions for person.
///
/// **Policy:** User–business, user–place, user–event → attraction (this
/// resolver). Person–person, business–business → similarity (no reflection).
class Attraction12DResolver {
  /// Optional: map BusinessPatronPreferences → 12D when explicit
  /// attractionDimensions is not set. Set when patron-prefs mapping exists.
  final Map<String, double> Function(BusinessAccount)? patronPrefsTo12D;

  Attraction12DResolver({this.patronPrefsTo12D});

  /// Returns attraction 12D for a business. Prefer explicit attractionDimensions
  /// on BusinessAccount, else patronPrefsTo12D(business), else
  /// reflect(inferred from business type/categories/description).
  Map<String, double> resolveForBusiness(BusinessAccount business) {
    if (business.attractionDimensions != null &&
        business.attractionDimensions!.isNotEmpty) {
      return _ensureAllDimensions(business.attractionDimensions!);
    }
    if (patronPrefsTo12D != null) {
      final fromPrefs = patronPrefsTo12D!(business);
      if (fromPrefs.isNotEmpty) {
        return _ensureAllDimensions(fromPrefs);
      }
    }
    final inferred = _inferBusinessDimensions(business);
    return reflectDimensionsForAttraction(inferred);
  }

  /// Returns attraction 12D for an event. Uses reflect(host profile) so
  /// "event attracts complement of host." Optional: later add composite with
  /// category and partnership business.
  Map<String, double> resolveForEvent(
    ExpertiseEvent event,
    Map<String, double> hostDimensions,
  ) {
    final hostDims = _ensureAllDimensions(hostDimensions);
    return reflectDimensionsForAttraction(hostDims);
  }

  /// Returns attraction 12D for a place (Spot). When place is claimed by a
  /// business, caller can pass business attraction 12D; else reflect(inferred).
  Map<String, double> resolveForPlace(
    Spot spot, {
    Map<String, double>? businessAttraction12D,
  }) {
    if (businessAttraction12D != null && businessAttraction12D.isNotEmpty) {
      return _ensureAllDimensions(businessAttraction12D);
    }
    final inferred = _inferPlaceDimensions(spot);
    return reflectDimensionsForAttraction(inferred);
  }

  Map<String, double> _inferBusinessDimensions(BusinessAccount business) {
    final spotVibe = SpotVibe.fromSpotCharacteristics(
      spotId: business.id,
      category: business.businessType,
      tags: business.categories,
      description: business.description ?? business.name,
      rating: 0.0,
    );
    return _ensureAllDimensions(spotVibe.vibeDimensions);
  }

  Map<String, double> _inferPlaceDimensions(Spot spot) {
    final spotVibe = SpotVibe.fromSpotCharacteristics(
      spotId: spot.id,
      category: spot.category,
      tags: spot.tags,
      description: spot.description,
      rating: spot.rating,
    );
    return _ensureAllDimensions(spotVibe.vibeDimensions);
  }

  Map<String, double> _ensureAllDimensions(Map<String, double> input) {
    final dims = <String, double>{};
    for (final d in VibeConstants.coreDimensions) {
      dims[d] =
          (input[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    }
    return dims;
  }
}
