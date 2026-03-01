// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';

/// Feature Flag Service
///
/// Manages runtime feature flags for gradual rollout and A/B testing.
/// Supports percentage rollouts, user-based targeting, and remote control.
///
/// **Purpose:**
/// - Enable/disable features at runtime without app rebuild
/// - Gradual rollout (5% → 25% → 50% → 100%)
/// - A/B testing support
/// - Quick rollback capability
/// - User-based targeting
///
/// **Usage:**
/// ```dart
/// final featureFlags = sl<FeatureFlagService>();
///
/// if (await featureFlags.isEnabled('quantum_location_entanglement')) {
///   // Use location entanglement
/// }
/// ```
class FeatureFlagService {
  static const String _logName = 'FeatureFlagService';
  static const String _storagePrefix = 'feature_flag_';
  static const String _rolloutPrefix = 'feature_rollout_';

  final StorageService _storage;

  /// Remote feature flag configuration (can be loaded from server)
  /// Format: { 'feature_name': { 'enabled': bool, 'rolloutPercentage': double, 'targetUsers': List&lt;String&gt;? } }
  Map<String, FeatureFlagConfig> _remoteConfig = {};

  FeatureFlagService({
    required StorageService storage,
  }) : _storage = storage;

  /// Check if a feature is enabled for a specific user
  ///
  /// **Rollout Logic:**
  /// 1. Check remote config (if available)
  /// 2. Check local override (if set)
  /// 3. Check default value
  /// 4. Apply percentage rollout if configured
  ///
  /// **Parameters:**
  /// - `featureName`: Name of the feature flag
  /// - `userId`: User ID for user-based targeting and consistent rollout
  /// - `defaultValue`: Default value if flag not configured (default: false)
  ///
  /// **Returns:**
  /// `true` if feature is enabled for this user, `false` otherwise
  Future<bool> isEnabled(
    String featureName, {
    String? userId,
    bool defaultValue = false,
  }) async {
    try {
      // 1. Check remote config first (highest priority)
      final remoteConfig = _remoteConfig[featureName];
      if (remoteConfig != null) {
        return _evaluateRemoteConfig(remoteConfig, userId);
      }

      // 2. Check local override (user-set preference)
      final localOverride = await _getLocalOverride(featureName);
      if (localOverride != null) {
        return localOverride;
      }

      // 3. Check stored config (from previous remote fetch)
      final storedConfig = await _getStoredConfig(featureName);
      if (storedConfig != null) {
        return _evaluateRemoteConfig(storedConfig, userId);
      }

      // 4. Return default value
      return defaultValue;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking feature flag: $featureName',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // On error, return default value (fail-safe)
      return defaultValue;
    }
  }

  /// Set a local override for a feature flag (for testing/debugging)
  ///
  /// This takes precedence over remote config and stored config.
  Future<void> setLocalOverride(String featureName, bool enabled) async {
    try {
      final key = '$_storagePrefix$featureName';
      await _storage.setBool(key, enabled);
      developer.log(
        'Set local override for $featureName: $enabled',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error setting local override for $featureName',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Clear local override (revert to remote/stored config)
  Future<void> clearLocalOverride(String featureName) async {
    try {
      final key = '$_storagePrefix$featureName';
      await _storage.remove(key);
      developer.log(
        'Cleared local override for $featureName',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error clearing local override for $featureName',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Update remote feature flag configuration
  ///
  /// This can be called when fetching flags from a remote server.
  /// The config is stored locally for offline use.
  Future<void> updateRemoteConfig(
    Map<String, FeatureFlagConfig> config,
  ) async {
    try {
      _remoteConfig = config;

      // Store config locally for offline use
      for (final entry in config.entries) {
        await _storeConfig(entry.key, entry.value);
      }

      developer.log(
        'Updated remote config: ${config.length} flags',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating remote config',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Get all enabled features for a user
  Future<Set<String>> getEnabledFeatures({String? userId}) async {
    final enabled = <String>{};

    // Check all known feature flags
    for (final flag in QuantumFeatureFlags.allFlags) {
      if (await isEnabled(flag, userId: userId)) {
        enabled.add(flag);
      }
    }

    return enabled;
  }

  /// Evaluate remote config with rollout logic
  bool _evaluateRemoteConfig(FeatureFlagConfig config, String? userId) {
    // If explicitly disabled, return false
    if (!config.enabled) {
      return false;
    }

    // Check user targeting
    if (config.targetUsers != null && userId != null) {
      if (config.targetUsers!.contains(userId)) {
        return true; // User is in target list
      }
      // If targetUsers is set but user not in list, return false
      if (config.targetUsers!.isNotEmpty) {
        return false;
      }
    }

    // Apply percentage rollout
    if (config.rolloutPercentage < 100.0 && userId != null) {
      // Use userId hash for consistent rollout assignment
      final hash = userId.hashCode.abs();
      final assignedPercentage = (hash % 100);
      return assignedPercentage < config.rolloutPercentage;
    }

    // If rollout is 100% or no userId, return enabled status
    return config.enabled;
  }

  /// Get local override (user-set preference)
  Future<bool?> _getLocalOverride(String featureName) async {
    try {
      final key = '$_storagePrefix$featureName';
      return _storage.getBool(key);
    } catch (e) {
      return null;
    }
  }

  /// Get stored config (from previous remote fetch)
  Future<FeatureFlagConfig?> _getStoredConfig(String featureName) async {
    try {
      final key = '$_rolloutPrefix$featureName';
      final json = _storage.getObject<Map>(key);
      if (json != null) {
        return FeatureFlagConfig.fromJson(
          Map<String, dynamic>.from(json),
        );
      }
    } catch (e) {
      // Ignore errors
    }
    return null;
  }

  /// Store config locally
  Future<void> _storeConfig(
      String featureName, FeatureFlagConfig config) async {
    try {
      final key = '$_rolloutPrefix$featureName';
      await _storage.setObject(key, config.toJson());
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Feature Flag Configuration
///
/// Represents the configuration for a single feature flag.
class FeatureFlagConfig {
  /// Whether the feature is enabled
  final bool enabled;

  /// Rollout percentage (0.0 to 100.0)
  /// Used for gradual rollout
  final double rolloutPercentage;

  /// Target user IDs (optional)
  /// If set, only these users will have the feature enabled
  final List<String>? targetUsers;

  /// Feature description (for documentation)
  final String? description;

  FeatureFlagConfig({
    required this.enabled,
    this.rolloutPercentage = 100.0,
    this.targetUsers,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rolloutPercentage': rolloutPercentage,
        'targetUsers': targetUsers,
        'description': description,
      };

  factory FeatureFlagConfig.fromJson(Map<String, dynamic> json) {
    return FeatureFlagConfig(
      enabled: json['enabled'] as bool? ?? false,
      rolloutPercentage:
          (json['rolloutPercentage'] as num?)?.toDouble() ?? 100.0,
      targetUsers: json['targetUsers'] as List<String>?,
      description: json['description'] as String?,
    );
  }
}

/// Quantum Enhancement Feature Flags
///
/// Centralized definitions for all quantum enhancement feature flags.
class QuantumFeatureFlags {
  /// Phase 1: Location Entanglement Integration
  static const String locationEntanglement = 'quantum_location_entanglement';

  /// Phase 2: Decoherence Behavior Tracking
  static const String decoherenceTracking = 'quantum_decoherence_tracking';

  /// Phase 3: Quantum Prediction Features
  static const String quantumPredictionFeatures = 'quantum_prediction_features';

  /// Phase 4: Quantum Satisfaction Enhancement
  static const String quantumSatisfactionEnhancement =
      'quantum_satisfaction_enhancement';

  /// All quantum feature flags
  static const List<String> allFlags = [
    locationEntanglement,
    decoherenceTracking,
    quantumPredictionFeatures,
    quantumSatisfactionEnhancement,
  ];

  /// Default configurations for quantum features
  static Map<String, FeatureFlagConfig> getDefaultConfigs() {
    return {
      locationEntanglement: FeatureFlagConfig(
        enabled: true,
        rolloutPercentage: 0.0, // Start at 0% (disabled by default)
        description: 'Location Entanglement Integration - Phase 1',
      ),
      decoherenceTracking: FeatureFlagConfig(
        enabled: true,
        rolloutPercentage: 0.0, // Start at 0% (disabled by default)
        description: 'Decoherence Behavior Tracking - Phase 2',
      ),
      quantumPredictionFeatures: FeatureFlagConfig(
        enabled: true,
        rolloutPercentage: 0.0, // Start at 0% (disabled by default)
        description: 'Quantum Prediction Features - Phase 3',
      ),
      quantumSatisfactionEnhancement: FeatureFlagConfig(
        enabled: true,
        rolloutPercentage: 0.0, // Start at 0% (disabled by default)
        description: 'Quantum Satisfaction Enhancement - Phase 4',
      ),
    };
  }
}

/// Governance and safety feature flags.
class GovernanceFeatureFlags {
  /// Enables hard enforcement for kernel governance gates.
  /// When false, gates operate in shadow mode.
  static const String kernelGovernanceEnforce = 'kernel_governance_enforce';
}
