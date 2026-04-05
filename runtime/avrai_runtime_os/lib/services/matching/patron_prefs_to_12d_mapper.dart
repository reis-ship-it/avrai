// Maps BusinessPatronPreferences to 12D attraction vector (12 inverse reference points).
// Used when a business has no explicit attractionDimensions; produces attraction 12D
// from preferredVibePreferences, preferredSpendingLevel, preferredPersonalityTraits, etc.

import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_patron_preferences.dart';

/// Maps patron preferences to a 12D vector (same keys as [VibeConstants.coreDimensions]).
/// Values are attraction semantics: "how much we want to attract / offer" on each axis.
/// Returns empty map if prefs are null or effectively empty.
Map<String, double> patronPrefsTo12D(BusinessAccount business) {
  final prefs = business.patronPreferences;
  if (prefs == null || prefs.isEmpty) return const {};

  final dims = <String, double>{};
  for (final d in VibeConstants.coreDimensions) {
    dims[d] = VibeConstants.defaultDimensionValue;
  }

  // Spending → value_orientation (value_tier_offer)
  if (prefs.preferredSpendingLevel != null) {
    switch (prefs.preferredSpendingLevel!) {
      case SpendingLevel.budget:
        dims['value_orientation'] = 0.2;
        break;
      case SpendingLevel.midRange:
        dims['value_orientation'] = 0.5;
        break;
      case SpendingLevel.premium:
        dims['value_orientation'] = 0.8;
        break;
      case SpendingLevel.any:
        dims['value_orientation'] = 0.5;
        break;
    }
  }

  // Vibe keywords → dimensions
  final vibe = prefs.preferredVibePreferences;
  if (vibe != null && vibe.isNotEmpty) {
    final lower = vibe.map((s) => s.toLowerCase()).toList();
    if (lower.any((s) => s.contains('casual') || s.contains('chill'))) {
      dims['energy_preference'] = 0.3;
    }
    if (lower.any((s) => s.contains('upscale') || s.contains('premium'))) {
      dims['value_orientation'] = (dims['value_orientation']! + 0.7) / 2;
    }
    if (lower.any((s) => s.contains('trendy') || s.contains('new'))) {
      dims['novelty_seeking'] = 0.7;
    }
    if (lower.any((s) => s.contains('cozy') || s.contains('quiet'))) {
      dims['crowd_tolerance'] = 0.2;
    }
    if (lower.any((s) => s.contains('bustling') || s.contains('lively'))) {
      dims['crowd_tolerance'] = 0.8;
      dims['energy_preference'] = 0.7;
    }
  }

  // Personality traits → dimensions
  final traits = prefs.preferredPersonalityTraits;
  if (traits != null && traits.isNotEmpty) {
    final lower = traits.map((s) => s.toLowerCase()).toList();
    if (lower.any((s) => s.contains('outgoing') || s.contains('social'))) {
      dims['community_orientation'] = 0.8;
    }
    if (lower.any((s) => s.contains('quiet') || s.contains('introvert'))) {
      dims['community_orientation'] = 0.2;
    }
    if (lower.any((s) => s.contains('adventurous') || s.contains('explorer'))) {
      dims['exploration_eagerness'] = 0.8;
      dims['location_adventurousness'] = 0.7;
    }
    if (lower.any((s) => s.contains('authentic') || s.contains('genuine'))) {
      dims['authenticity_preference'] = 0.8;
    }
  }

  // Social styles → community_orientation
  final styles = prefs.preferredSocialStyles;
  if (styles != null && styles.isNotEmpty) {
    final lower = styles.map((s) => s.toLowerCase()).toList();
    if (lower.any((s) => s.contains('group') || s.contains('social'))) {
      dims['community_orientation'] =
          (dims['community_orientation']! + 0.8) / 2;
    }
    if (lower.any((s) => s.contains('solo') || s.contains('solo'))) {
      dims['community_orientation'] =
          (dims['community_orientation']! + 0.2) / 2;
    }
  }

  // Clamp all to [0, 1]
  for (final k in dims.keys.toList()) {
    dims[k] = (dims[k] ?? 0.5).clamp(0.0, 1.0);
  }

  return dims;
}
