import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/device/device_capabilities.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_capability_profile.dart';

void main() {
  group('RuntimeCapabilityProfile', () {
    test('assigns full tier on high-resource devices', () {
      const caps = DeviceCapabilities(
        platform: 'ios',
        deviceModel: 'iPhone',
        osVersion: 18,
        totalRamMb: 12 * 1024,
        freeDiskMb: 128 * 1024,
        totalDiskMb: 256 * 1024,
        cpuCores: 8,
        isLowPowerMode: false,
      );

      final profile = RuntimeCapabilityProfile.fromDeviceCapabilities(caps);
      expect(profile.tier, RuntimeCapabilityTier.full);
      expect(profile.maxConcurrentGeofences, 20);
      expect(profile.geohashPrecisionCap, 8);
    });

    test('degrades to minimal in low-power mode', () {
      const caps = DeviceCapabilities(
        platform: 'android',
        deviceModel: 'Pixel',
        osVersion: 35,
        totalRamMb: 12 * 1024,
        freeDiskMb: 128 * 1024,
        totalDiskMb: 256 * 1024,
        cpuCores: 8,
        isLowPowerMode: true,
      );

      final profile = RuntimeCapabilityProfile.fromDeviceCapabilities(caps);
      expect(profile.tier, RuntimeCapabilityTier.minimal);
      expect(profile.maxConcurrentGeofences, 4);
      expect(profile.maxPlannerCandidates, 16);
      expect(profile.geohashPrecisionCap, 5);
    });
  });
}
