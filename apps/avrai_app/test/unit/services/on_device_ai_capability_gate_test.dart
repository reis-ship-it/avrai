import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/device/device_capabilities.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/on_device_ai_capability_gate.dart';

void main() {
  test('Gate rejects when RAM/disk are unknown', () {
    final gate = OnDeviceAiCapabilityGate();
    final res = gate.evaluate(const DeviceCapabilities(
      platform: 'android',
      deviceModel: 'Test',
      osVersion: 34,
      totalRamMb: null,
      freeDiskMb: null,
      totalDiskMb: null,
      cpuCores: 8,
      isLowPowerMode: false,
    ));
    expect(res.eligible, isFalse);
  });

  test('Gate accepts mid tier for 8GB RAM + 10GB free', () {
    final gate = OnDeviceAiCapabilityGate();
    final res = gate.evaluate(const DeviceCapabilities(
      platform: 'android',
      deviceModel: 'Test',
      osVersion: 34,
      totalRamMb: 8192,
      freeDiskMb: 12288,
      totalDiskMb: 256000,
      cpuCores: 8,
      isLowPowerMode: false,
    ));
    expect(res.eligible, isTrue);
    expect(res.recommendedTier, OfflineLlmTier.llama8b);
    expect(res.allowOnDeviceLoraTraining, isTrue);
  });
}
