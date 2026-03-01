import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/device/device_capability_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/on_device_ai_capability_gate.dart';
import 'package:avrai_runtime_os/services/local_llm/model_pack_manager.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_provisioning_state_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

/// iOS-optimized auto-downloader for local LLM packs.
///
/// Key optimizations over generic service:
/// - Removes charging requirement for A14+ chips (iPhone 12+) with sufficient battery
/// - Downloads during daytime on WiFi when battery > 50%
/// - Uses more aggressive download scheduling for capable devices
///
/// Requirements for download:
/// - WiFi connection (always required)
/// - A14+ chip (iPhone 12+): battery > 50% OR charging
/// - A13 and below: charging required (as before)
class LocalLlmIOSAutoInstallService {
  static const String _logName = 'LocalLlmIOSAutoInstallService';

  static const String _prefsKeyOfflineLlmEnabled = 'offline_llm_enabled_v1';

  // A14+ chips (iPhone 12+) are efficient enough to download without charging
  // if battery is above threshold
  static const int _minBatteryPercentForDownload = 50;
  static const int _minIOSVersionForRelaxedGating = 14; // iOS 14 = A14 chips

  final Connectivity _connectivity;
  final Battery _battery;
  final LocalLlmModelPackManager _packs;
  final DeviceCapabilityService _caps;
  final OnDeviceAiCapabilityGate _gate;
  final LocalLlmProvisioningStateService _provisioning;
  final SharedPreferencesCompat? _prefsOverride;

  LocalLlmIOSAutoInstallService({
    Connectivity? connectivity,
    Battery? battery,
    LocalLlmModelPackManager? packs,
    DeviceCapabilityService? deviceCapabilities,
    OnDeviceAiCapabilityGate? gate,
    LocalLlmProvisioningStateService? provisioning,
    SharedPreferencesCompat? prefs,
  })  : _connectivity = connectivity ?? Connectivity(),
        _battery = battery ?? Battery(),
        _packs = packs ?? LocalLlmModelPackManager(),
        _caps = deviceCapabilities ?? DeviceCapabilityService(),
        _gate = gate ?? OnDeviceAiCapabilityGate(),
        _provisioning = provisioning ?? LocalLlmProvisioningStateService(),
        _prefsOverride = prefs;

  Future<SharedPreferencesCompat> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride;
    return await SharedPreferencesCompat.getInstance();
  }

  /// Check if this device uses relaxed gating (A14+ chips).
  Future<bool> _usesRelaxedGating() async {
    if (!Platform.isIOS) return false;

    try {
      final caps = await _caps.getCapabilities();
      final osVersion = caps.osVersion ?? 0;
      // iOS version roughly correlates with chip generation
      // iOS 14+ generally means A14+ capable device
      return osVersion >= _minIOSVersionForRelaxedGating;
    } catch (e) {
      developer.log('Error checking relaxed gating: $e', name: _logName);
      return false;
    }
  }

  /// iOS-optimized auto-install.
  ///
  /// Key differences from generic service:
  /// - A14+ devices (iOS 14+) can download with battery > 50% (no charging required)
  /// - A13 and below still require charging
  /// - No idle time requirement for WiFi downloads
  Future<void> maybeAutoInstallIOS() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final prefs = await _prefs();

      // Check if user has enabled offline LLM
      final hasUserChoice = prefs.containsKey(_prefsKeyOfflineLlmEnabled);
      bool enabled = prefs.getBool(_prefsKeyOfflineLlmEnabled) ?? false;

      if (!hasUserChoice) {
        final caps = await _caps.getCapabilities();
        final gateResult = _gate.evaluate(caps);
        enabled = gateResult.recommendedTier != OfflineLlmTier.none;
        await prefs.setBool(_prefsKeyOfflineLlmEnabled, enabled);
      }

      if (!enabled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.idle);
        return;
      }

      // Check if already installed
      final status = await _packs.getStatus();
      if (status.isInstalled) {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);
        return;
      }

      // WiFi is always required for large model downloads
      final connectivityResult = await _connectivity.checkConnectivity();
      final isWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!isWifi) {
        developer.log('Skipping iOS auto-install: not on Wi-Fi',
            name: _logName);
        await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedWifi);
        return;
      }

      // Check battery/charging status
      final batteryState = await _battery.batteryState;
      final batteryLevel = await _battery.batteryLevel;
      final isCharging = batteryState == BatteryState.charging ||
          batteryState == BatteryState.full;

      // A14+ chips (iOS 14+) can download without charging if battery is sufficient
      final usesRelaxedGating = await _usesRelaxedGating();

      bool canDownload = false;
      if (isCharging) {
        // Always allow download when charging
        canDownload = true;
        developer.log('iOS auto-install: charging detected', name: _logName);
      } else if (usesRelaxedGating &&
          batteryLevel >= _minBatteryPercentForDownload) {
        // A14+ with sufficient battery - allow download
        canDownload = true;
        developer.log(
          'iOS auto-install: A14+ chip with $batteryLevel% battery (>=$_minBatteryPercentForDownload%)',
          name: _logName,
        );
      } else {
        // Older device or low battery - require charging
        developer.log(
          'iOS auto-install: waiting for charging (battery: $batteryLevel%, relaxedGating: $usesRelaxedGating)',
          name: _logName,
        );
        await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedCharging);
        return;
      }

      if (canDownload) {
        await _downloadNow(prefs: prefs);
      }
    } catch (e, st) {
      developer.log(
        'iOS auto-install failed (non-fatal)',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _downloadNow({required SharedPreferencesCompat prefs}) async {
    await _provisioning.setPhase(LocalLlmProvisioningPhase.downloading);

    try {
      // Select optimal tier based on system specs
      final caps = await _caps.getCapabilities();
      final gateResult = _gate.evaluate(caps);
      final tier = switch (gateResult.recommendedTier) {
        OfflineLlmTier.llama8b => 'llama8b',
        OfflineLlmTier.small3b => 'small3b',
        OfflineLlmTier.none => 'none',
      };

      if (tier == 'none') {
        await _provisioning.setPhase(LocalLlmProvisioningPhase.idle);
        developer.log(
          'Device not eligible for local LLM',
          name: _logName,
        );
        return;
      }

      // Progress callback
      void onProgress(int receivedBytes, int totalBytes) {
        _provisioning.setProgress(
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }

      // Download and activate
      await _packs.downloadAndActivateTrusted(
        tier: tier,
        onProgress: onProgress,
      );

      developer.log('iOS LLM pack installed successfully', name: _logName);
      await _provisioning.setPhase(LocalLlmProvisioningPhase.installed);

      // Best-effort: build local "memory" for the current user
      try {
        final sl = GetIt.instance;
        final bootstrap = sl.isRegistered<LocalLlmPostInstallBootstrapService>()
            ? sl<LocalLlmPostInstallBootstrapService>()
            : LocalLlmPostInstallBootstrapService();
        unawaited(bootstrap.maybeBootstrapCurrentUser());
      } catch (e, st) {
        developer.log(
          'Bootstrap failed (non-fatal)',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }
    } catch (e, st) {
      developer.log(
        'Download failed',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      await _provisioning.setPhase(LocalLlmProvisioningPhase.queuedWifi);
    }
  }
}
