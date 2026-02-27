import 'package:avrai/core/services/device/device_capabilities.dart';

enum RuntimeCapabilityTier {
  minimal,
  constrained,
  standard,
  full,
}

/// Runtime capability profile used by planners/orchestrators for safe degradation.
class RuntimeCapabilityProfile {
  final String platform;
  final RuntimeCapabilityTier tier;
  final bool supportsBle;
  final bool supportsWifi;
  final bool supportsP2p;
  final bool supportsAi2AiMesh;
  final int maxConcurrentGeofences;
  final int maxPlannerCandidates;
  final int geohashPrecisionCap;

  const RuntimeCapabilityProfile({
    required this.platform,
    required this.tier,
    required this.supportsBle,
    required this.supportsWifi,
    required this.supportsP2p,
    required this.supportsAi2AiMesh,
    required this.maxConcurrentGeofences,
    required this.maxPlannerCandidates,
    required this.geohashPrecisionCap,
  });

  factory RuntimeCapabilityProfile.fromDeviceCapabilities(
    DeviceCapabilities caps, {
    bool supportsBle = true,
    bool supportsWifi = true,
    bool supportsP2p = true,
    bool supportsAi2AiMesh = true,
  }) {
    final ram = caps.totalRamMb ?? 0;
    final cores = caps.cpuCores;
    final lowPower = caps.isLowPowerMode;

    final tier = switch ((ram, cores, lowPower)) {
      (_, _, true) => RuntimeCapabilityTier.minimal,
      (>= 8 * 1024, >= 8, false) => RuntimeCapabilityTier.full,
      (>= 6 * 1024, >= 6, false) => RuntimeCapabilityTier.standard,
      (>= 4 * 1024, >= 4, false) => RuntimeCapabilityTier.constrained,
      _ => RuntimeCapabilityTier.minimal,
    };

    return RuntimeCapabilityProfile(
      platform: caps.platform,
      tier: tier,
      supportsBle: supportsBle,
      supportsWifi: supportsWifi,
      supportsP2p: supportsP2p,
      supportsAi2AiMesh: supportsAi2AiMesh,
      maxConcurrentGeofences: _maxGeofencesForTier(tier),
      maxPlannerCandidates: _maxPlannerCandidatesForTier(tier),
      geohashPrecisionCap: _geohashPrecisionCapForTier(tier),
    );
  }

  static int _maxGeofencesForTier(RuntimeCapabilityTier tier) {
    return switch (tier) {
      RuntimeCapabilityTier.full => 20,
      RuntimeCapabilityTier.standard => 12,
      RuntimeCapabilityTier.constrained => 8,
      RuntimeCapabilityTier.minimal => 4,
    };
  }

  static int _maxPlannerCandidatesForTier(RuntimeCapabilityTier tier) {
    return switch (tier) {
      RuntimeCapabilityTier.full => 128,
      RuntimeCapabilityTier.standard => 64,
      RuntimeCapabilityTier.constrained => 32,
      RuntimeCapabilityTier.minimal => 16,
    };
  }

  static int _geohashPrecisionCapForTier(RuntimeCapabilityTier tier) {
    return switch (tier) {
      RuntimeCapabilityTier.full => 8,
      RuntimeCapabilityTier.standard => 7,
      RuntimeCapabilityTier.constrained => 6,
      RuntimeCapabilityTier.minimal => 5,
    };
  }
}
