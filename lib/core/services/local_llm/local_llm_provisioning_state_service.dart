import 'dart:developer' as developer;

import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;

/// Coarse-grained provisioning phase for the local model pack.
///
/// We keep this intentionally simple:
/// - we expose coarse per-byte progress (received/total) for UI
/// - onboarding just needs to explain “queued vs downloading vs installed”
enum LocalLlmProvisioningPhase {
  idle,
  queuedWifi,
  queuedCharging,
  queuedIdle,
  downloading,
  installed,
  error,
}

class LocalLlmProvisioningState {
  final LocalLlmProvisioningPhase phase;
  final String? lastError;
  final int updatedAtMs;
  final LocalLlmModelPackStatus packStatus;
  final int? receivedBytes;
  final int? totalBytes;

  const LocalLlmProvisioningState({
    required this.phase,
    required this.lastError,
    required this.updatedAtMs,
    required this.packStatus,
    required this.receivedBytes,
    required this.totalBytes,
  });

  double? get progressFraction {
    final r = receivedBytes;
    final t = totalBytes;
    if (r == null || t == null || t <= 0) return null;
    return r / t;
  }
}

/// Stores and surfaces local LLM provisioning state for UI (onboarding/settings).
///
/// This is device-scoped (not per-user).
class LocalLlmProvisioningStateService {
  static const String _logName = 'LocalLlmProvisioningStateService';

  static const String _prefsKeyPhase = 'local_llm_provisioning_phase_v1';
  static const String _prefsKeyLastError = 'local_llm_provisioning_last_error_v1';
  static const String _prefsKeyUpdatedAtMs =
      'local_llm_provisioning_updated_at_ms_v1';
  static const String _prefsKeyReceivedBytes =
      'local_llm_provisioning_received_bytes_v1';
  static const String _prefsKeyTotalBytes =
      'local_llm_provisioning_total_bytes_v1';

  final LocalLlmModelPackManager _packs;
  final SharedPreferencesCompat? _prefsOverride;

  LocalLlmProvisioningStateService({
    LocalLlmModelPackManager? packs,
    SharedPreferencesCompat? prefs,
  })  : _packs = packs ?? LocalLlmModelPackManager(),
        _prefsOverride = prefs;

  Future<SharedPreferencesCompat> _prefs() async {
    if (_prefsOverride != null) return _prefsOverride;
    return await SharedPreferencesCompat.getInstance();
  }

  Future<void> setPhase(LocalLlmProvisioningPhase phase,
      {String? lastError}) async {
    try {
      final prefs = await _prefs();
      await prefs.setString(_prefsKeyPhase, phase.name);
      await prefs.setInt(
          _prefsKeyUpdatedAtMs, DateTime.now().millisecondsSinceEpoch);
      if (lastError != null) {
        await prefs.setString(_prefsKeyLastError, lastError);
      } else if (phase != LocalLlmProvisioningPhase.error) {
        await prefs.remove(_prefsKeyLastError);
      }

      // Clear progress unless actively downloading.
      if (phase != LocalLlmProvisioningPhase.downloading) {
        await prefs.remove(_prefsKeyReceivedBytes);
        await prefs.remove(_prefsKeyTotalBytes);
      }
    } catch (e, st) {
      developer.log('Failed to set provisioning phase: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> setProgress({
    required int receivedBytes,
    required int totalBytes,
  }) async {
    try {
      final prefs = await _prefs();
      await prefs.setInt(_prefsKeyReceivedBytes, receivedBytes);
      await prefs.setInt(_prefsKeyTotalBytes, totalBytes);
      await prefs.setInt(
          _prefsKeyUpdatedAtMs, DateTime.now().millisecondsSinceEpoch);
    } catch (e, st) {
      developer.log('Failed to set provisioning progress: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  Future<LocalLlmProvisioningState> getState() async {
    final prefs = await _prefs();
    final packStatus = await _packs.getStatus();
    final phaseName =
        prefs.getString(_prefsKeyPhase) ?? LocalLlmProvisioningPhase.idle.name;
    final phase = LocalLlmProvisioningPhase.values.firstWhere(
      (p) => p.name == phaseName,
      orElse: () => LocalLlmProvisioningPhase.idle,
    );
    final lastError = prefs.getString(_prefsKeyLastError);
    final updatedAtMs = prefs.getInt(_prefsKeyUpdatedAtMs) ?? 0;
    final receivedBytes = prefs.getInt(_prefsKeyReceivedBytes);
    final totalBytes = prefs.getInt(_prefsKeyTotalBytes);

    // If a pack is installed, treat “queued/idle” as installed (but preserve
    // explicit update states like downloading/error so UI can show progress).
    final effectivePhase = (packStatus.isInstalled &&
            phase != LocalLlmProvisioningPhase.downloading &&
            phase != LocalLlmProvisioningPhase.error)
        ? LocalLlmProvisioningPhase.installed
        : phase;

    return LocalLlmProvisioningState(
      phase: effectivePhase,
      lastError: effectivePhase == LocalLlmProvisioningPhase.error ? lastError : lastError,
      updatedAtMs: updatedAtMs,
      packStatus: packStatus,
      receivedBytes: effectivePhase == LocalLlmProvisioningPhase.downloading
          ? receivedBytes
          : null,
      totalBytes:
          effectivePhase == LocalLlmProvisioningPhase.downloading ? totalBytes : null,
    );
  }
}

