import 'package:avrai/core/ai/privacy_protection.dart';
import 'package:avrai/core/models/user/user_vibe.dart';

class AnonymizedVibeMapper {
  const AnonymizedVibeMapper._();

  static UserVibe toUserVibe(AnonymizedVibeData anonymizedData) {
    final metrics = anonymizedData.anonymizedMetrics;

    return UserVibe(
      hashedSignature: anonymizedData.vibeSignature,
      anonymizedDimensions: anonymizedData.noisyDimensions,
      overallEnergy: metrics.energy,
      socialPreference: metrics.social,
      explorationTendency: metrics.exploration,
      createdAt: anonymizedData.createdAt,
      expiresAt: anonymizedData.expiresAt,
      privacyLevel: anonymizedData.anonymizationQuality,
      temporalContext: anonymizedData.temporalContextHash,
    );
  }
}
