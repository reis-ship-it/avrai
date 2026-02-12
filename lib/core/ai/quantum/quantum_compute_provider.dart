// Quantum Compute Provider
//
// Selects the appropriate quantum compute backend based on:
// - Entity count (cloud quantum only beneficial for N >= 5)
// - Online/offline status
// - Feature flag
//
// Phase: ML Reality and Quantum Readiness - Phase 4.4

import 'dart:developer' as developer;

import 'package:avrai/core/ai/quantum/quantum_compute_backend.dart';
import 'package:avrai/core/ai/quantum/backends/classical_quantum_backend.dart';
import 'package:avrai/core/ai/quantum/backends/cloud_quantum_backend.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';

/// Provides the appropriate quantum compute backend for a given context
///
/// Selection logic:
/// - Cloud quantum is only used when ALL conditions are met:
///   1. Entity count >= 5 (classical is fine for small groups)
///   2. Device is online (cloud quantum requires network)
///   3. Quantum feature flag is enabled (safety gate)
///
/// - Otherwise, classical backend is always used (on-device, offline-capable)
///
/// This ensures:
/// - Zero behavior change for existing users (classical is default)
/// - Graceful degradation (cloud failure -> classical fallback)
/// - Controlled rollout via feature flags
class QuantumComputeProvider {
  static const String _logName = 'QuantumComputeProvider';

  /// Minimum entity count to consider cloud quantum
  /// Below this, classical computation is fast enough
  static const int cloudQuantumEntityThreshold = 5;

  final ClassicalQuantumBackend _classicalBackend;
  final CloudQuantumBackend _cloudBackend;
  final FeatureFlagService? _featureFlags;

  bool _initialized = false;

  QuantumComputeProvider({
    required ClassicalQuantumBackend classicalBackend,
    required CloudQuantumBackend cloudBackend,
    FeatureFlagService? featureFlags,
  })  : _classicalBackend = classicalBackend,
        _cloudBackend = cloudBackend,
        _featureFlags = featureFlags;

  /// The classical (on-device) backend -- always available
  ClassicalQuantumBackend get classicalBackend => _classicalBackend;

  /// The cloud quantum backend -- only used when conditions are met
  CloudQuantumBackend get cloudBackend => _cloudBackend;

  /// Initialize all backends
  Future<void> initialize() async {
    if (_initialized) return;

    developer.log('Initializing quantum compute provider', name: _logName);

    // Classical backend always initializes (loads ONNX models)
    await _classicalBackend.initialize();

    // Cloud backend just logs stub status; doesn't connect
    await _cloudBackend.initialize();

    _initialized = true;
    developer.log(
      'Quantum compute provider ready. '
      'Classical: initialized, '
      'Cloud: stub (feature-flagged)',
      name: _logName,
    );
  }

  /// Select the appropriate backend for a computation
  ///
  /// Returns the classical backend by default. Cloud quantum backend
  /// is only returned when all threshold conditions are met.
  Future<QuantumComputeBackend> getBackend({
    required int entityCount,
    required bool isOnline,
  }) async {
    // Check if cloud quantum feature is enabled
    bool quantumFeatureEnabled = false;
    if (_featureFlags != null) {
      try {
        quantumFeatureEnabled = await _featureFlags.isEnabled(
          'cloud_quantum_compute',
          defaultValue: false,
        );
      } catch (e) {
        developer.log(
          'Feature flag check failed, using classical: $e',
          name: _logName,
        );
      }
    }

    // Cloud quantum only for large groups, online, and feature-flagged
    if (entityCount >= cloudQuantumEntityThreshold &&
        isOnline &&
        quantumFeatureEnabled) {
      developer.log(
        'Selecting cloud quantum backend '
        '(entities=$entityCount, online=$isOnline, flag=$quantumFeatureEnabled)',
        name: _logName,
      );
      return _cloudBackend;
    }

    // Default: classical on-device computation
    developer.log(
      'Selecting classical backend '
      '(entities=$entityCount, online=$isOnline, flag=$quantumFeatureEnabled)',
      name: _logName,
    );
    return _classicalBackend;
  }

  /// Always get the classical backend (for operations that don't need cloud)
  QuantumComputeBackend getClassicalBackend() => _classicalBackend;

  /// Get diagnostic info about the provider state
  Map<String, dynamic> getDiagnostics() {
    return {
      'initialized': _initialized,
      'classical_backend': _classicalBackend.backendName,
      'classical_entanglement_onnx': _classicalBackend.isEntanglementOnnxLoaded,
      'classical_optimization_onnx': _classicalBackend.isOptimizationOnnxLoaded,
      'cloud_backend': _cloudBackend.backendName,
      'cloud_is_quantum': _cloudBackend.isQuantumHardware,
      'cloud_entity_threshold': cloudQuantumEntityThreshold,
    };
  }

  /// Dispose all backends
  Future<void> dispose() async {
    await _classicalBackend.dispose();
    await _cloudBackend.dispose();
    _initialized = false;
  }
}
