import 'package:avrai/core/services/device/device_capabilities.dart';

enum OfflineLlmTier {
  none,
  small3b,
  llama8b,
}

class OnDeviceAiGateResult {
  final bool eligible;
  final OfflineLlmTier recommendedTier;
  final bool allowOnDeviceLoraTraining;
  final List<String> reasons;

  const OnDeviceAiGateResult({
    required this.eligible,
    required this.recommendedTier,
    required this.allowOnDeviceLoraTraining,
    required this.reasons,
  });
}

/// Device capability gate for offline LLM download + scheduled LoRA training.
///
/// **Mid-to-high only strategy:** we intentionally set a higher bar.
class OnDeviceAiCapabilityGate {
  // Baseline thresholds (mid/high range target).
  static const int _minRamMbFor3b = 6 * 1024;
  static const int _minRamMbFor8b = 8 * 1024;

  static const int _minFreeDiskMbFor3b = 6 * 1024;
  // Llama 3.1 8B + CoreML package + safety headroom.
  static const int _minFreeDiskMbFor8b = 12 * 1024;

  static const int _minCpuCores = 6;

  OnDeviceAiGateResult evaluate(DeviceCapabilities caps) {
    final reasons = <String>[];

    // Web: supported later (WASM/WebGPU variance); keep it off for now.
    if (caps.platform == 'web') {
      return const OnDeviceAiGateResult(
        eligible: false,
        recommendedTier: OfflineLlmTier.none,
        allowOnDeviceLoraTraining: false,
        reasons: <String>[
          'Offline LLM is disabled on web for now (performance varies by browser/GPU).',
        ],
      );
    }

    if (caps.isLowPowerMode) {
      reasons.add('Low Power Mode is enabled (training and heavy inference should be avoided).');
    }

    final ram = caps.totalRamMb;
    final freeDisk = caps.freeDiskMb;

    if (ram == null) {
      reasons.add('Could not read device RAM; assuming not eligible.');
      return OnDeviceAiGateResult(
        eligible: false,
        recommendedTier: OfflineLlmTier.none,
        allowOnDeviceLoraTraining: false,
        reasons: reasons,
      );
    }
    if (freeDisk == null) {
      reasons.add('Could not read free storage; assuming not eligible.');
      return OnDeviceAiGateResult(
        eligible: false,
        recommendedTier: OfflineLlmTier.none,
        allowOnDeviceLoraTraining: false,
        reasons: reasons,
      );
    }

    if (caps.cpuCores > 0 && caps.cpuCores < _minCpuCores) {
      reasons.add('CPU core count appears low for offline LLM performance.');
    }

    // Pick tier based on resources.
    OfflineLlmTier tier = OfflineLlmTier.none;
    if (ram >= _minRamMbFor8b && freeDisk >= _minFreeDiskMbFor8b) {
      tier = OfflineLlmTier.llama8b;
    } else if (ram >= _minRamMbFor3b && freeDisk >= _minFreeDiskMbFor3b) {
      tier = OfflineLlmTier.small3b;
    } else {
      reasons.add(
        'Device below baseline for offline LLM (need ~${_minRamMbFor3b}MB RAM and ~${_minFreeDiskMbFor3b}MB free).',
      );
      tier = OfflineLlmTier.none;
    }

    final eligible = tier != OfflineLlmTier.none && !caps.isLowPowerMode;

    // LoRA training is heavier than inference; require higher bar.
    final allowLoraTraining =
        eligible && tier == OfflineLlmTier.llama8b && ram >= _minRamMbFor8b;

    if (eligible && tier == OfflineLlmTier.small3b) {
      reasons.add('Eligible for offline inference (small model).');
      reasons.add('LoRA training disabled on this tier (use memory + small learner model).');
    }
    if (eligible && tier == OfflineLlmTier.llama8b) {
      reasons.add('Eligible for offline inference (mid model).');
      if (allowLoraTraining) {
        reasons.add('Eligible for scheduled LoRA training (charging + idle only).');
      }
    }
    if (!eligible && caps.isLowPowerMode) {
      reasons.add('Disable Low Power Mode to enable offline AI training.');
    }

    return OnDeviceAiGateResult(
      eligible: eligible,
      recommendedTier: tier,
      allowOnDeviceLoraTraining: allowLoraTraining,
      reasons: reasons,
    );
  }
}

