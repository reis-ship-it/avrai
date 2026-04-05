// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/models/personality_profile.dart';

class DeterministicTestVibeBuilderLane {
  const DeterministicTestVibeBuilderLane._();

  static UserVibe build({
    required String userId,
    required PersonalityProfile personality,
  }) {
    final Map<String, double> dims = <String, double>{};
    for (final String d in VibeConstants.coreDimensions) {
      dims[d] =
          (personality.dimensions[d] ?? VibeConstants.defaultDimensionValue)
              .clamp(0.0, 1.0);
    }

    final double energy = ((dims['exploration_eagerness'] ?? 0.5) +
            (dims['temporal_flexibility'] ?? 0.5) +
            (dims['location_adventurousness'] ?? 0.5)) /
        3.0;
    final double social = ((dims['community_orientation'] ?? 0.5) +
            (dims['social_discovery_style'] ?? 0.5) +
            (dims['trust_network_reliance'] ?? 0.5)) /
        3.0;
    final double exploration = ((dims['exploration_eagerness'] ?? 0.5) +
            (dims['location_adventurousness'] ?? 0.5) +
            (1.0 - (dims['authenticity_preference'] ?? 0.5))) /
        3.0;

    final DateTime now = DateTime.now();
    return UserVibe(
      hashedSignature: 'test_sig_$userId',
      anonymizedDimensions: dims,
      overallEnergy: energy.clamp(0.0, 1.0),
      socialPreference: social.clamp(0.0, 1.0),
      explorationTendency: exploration.clamp(0.0, 1.0),
      createdAt: now,
      expiresAt: now.add(const Duration(days: 1)),
      privacyLevel: 1.0,
      temporalContext: 'test',
    );
  }
}
