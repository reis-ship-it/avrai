// Attraction dimension utilities for business/event/place compatibility.
//
// User dimensions = "what I seek"; entity (business/event/place) dimensions =
// "what we want to attract". Reflection converts raw inferred dimensions to
// attraction 12D so user–entity compatibility uses complementary fit (lock-and-key).

import 'package:avrai_core/utils/vibe_constants.dart';

/// Reflects raw 12D dimensions into attraction 12D: a_d = 1 - b_d for each
/// core dimension. Used for business, event, and place entities so that
/// compatibility with a user is complementary (high when user seeks X and
/// entity offers 1-X).
///
/// **Contract:** Input and output use [VibeConstants.coreDimensions] keys.
/// Values are clamped to [0.0, 1.0].
Map<String, double> reflectDimensionsForAttraction(Map<String, double> raw) {
  final result = <String, double>{};
  for (final d in VibeConstants.coreDimensions) {
    final v = (raw[d] ?? VibeConstants.defaultDimensionValue).clamp(0.0, 1.0);
    result[d] = (1.0 - v).clamp(0.0, 1.0);
  }
  return result;
}
