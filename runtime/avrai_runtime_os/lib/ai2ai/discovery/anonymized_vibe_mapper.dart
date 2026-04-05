// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
import 'package:avrai_runtime_os/ai/privacy_protection.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

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
