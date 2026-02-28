// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
// Model Version Manager for Phase 12: Neural Network Implementation
// Section 3.2.2: Model Versioning
// Manages model version switching, A/B testing, and rollback

import 'dart:developer' as developer;
import 'package:avrai/core/ml/model_version_registry.dart';
import 'package:avrai/core/ml/model_version_info.dart';
import 'package:avrai/core/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai/core/services/ai_infrastructure/model_safety_supervisor.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

/// Model Version Manager
///
/// Handles model version switching, A/B testing, and rollback operations.
/// Integrates with remote configuration for dynamic version management.
class ModelVersionManager {
  static const String _logName = 'ModelVersionManager';
  SharedPreferencesCompat? _prefs;
  final KernelGovernanceGate? _kernelGovernanceGate;

  ModelVersionManager({
    KernelGovernanceGate? kernelGovernanceGate,
  }) : _kernelGovernanceGate = kernelGovernanceGate;

  Future<SharedPreferencesCompat> _getPrefs() async {
    _prefs ??= await SharedPreferencesCompat.getInstance();
    return _prefs!;
  }

  /// Switch active calling score model version
  ///
  /// **Parameters:**
  /// - `newVersion`: Version to switch to (e.g., 'v2.0-real')
  ///
  /// **Returns:**
  /// True if switch was successful, false if version doesn't exist
  Future<bool> switchCallingScoreVersion(String newVersion) async {
    if (!ModelVersionRegistry.hasVersion(newVersion,
        modelType: 'calling_score')) {
      developer.log(
        'Calling score version $newVersion not found in registry',
        name: _logName,
      );
      return false;
    }

    final previousVersion = ModelVersionRegistry.activeCallingScoreVersion;
    final correlationId =
        'mvm_switch_calling_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final gateDecision = await _evaluateGovernance(
      KernelGovernanceRequest(
        action: KernelGovernanceAction.modelSwitch,
        modelType: 'calling_score',
        fromVersion: previousVersion,
        toVersion: newVersion,
        correlationId: correlationId,
      ),
    );
    if (!gateDecision.servingAllowed) {
      developer.log(
        'Blocked calling_score switch by kernel governance: '
        '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );
      return false;
    }
    final success =
        ModelVersionRegistry.setActiveCallingScoreVersion(newVersion);

    if (success) {
      developer.log(
        'Switched calling score model: $previousVersion → $newVersion decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );

      try {
        final prefs = await _getPrefs();
        await ModelSafetySupervisor(
          prefs: prefs,
          kernelGovernanceGate: _kernelGovernanceGate,
        ).startRolloutCandidate(
          modelType: 'calling_score',
          fromVersion: previousVersion,
          toVersion: newVersion,
        );
      } catch (_) {
        // Ignore.
      }

      // TODO: Update remote config if available
      // await _updateRemoteConfig('calling_score', newVersion);
    }

    return success;
  }

  /// Switch active outcome prediction model version
  ///
  /// **Parameters:**
  /// - `newVersion`: Version to switch to (e.g., 'v2.0-real')
  ///
  /// **Returns:**
  /// True if switch was successful, false if version doesn't exist
  Future<bool> switchOutcomeVersion(String newVersion) async {
    if (!ModelVersionRegistry.hasVersion(newVersion, modelType: 'outcome')) {
      developer.log(
        'Outcome prediction version $newVersion not found in registry',
        name: _logName,
      );
      return false;
    }

    final previousVersion = ModelVersionRegistry.activeOutcomeVersion;
    final correlationId =
        'mvm_switch_outcome_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final gateDecision = await _evaluateGovernance(
      KernelGovernanceRequest(
        action: KernelGovernanceAction.modelSwitch,
        modelType: 'outcome',
        fromVersion: previousVersion,
        toVersion: newVersion,
        correlationId: correlationId,
      ),
    );
    if (!gateDecision.servingAllowed) {
      developer.log(
        'Blocked outcome switch by kernel governance: '
        '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );
      return false;
    }
    final success = ModelVersionRegistry.setActiveOutcomeVersion(newVersion);

    if (success) {
      developer.log(
        'Switched outcome prediction model: $previousVersion → $newVersion decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );

      try {
        final prefs = await _getPrefs();
        await ModelSafetySupervisor(
          prefs: prefs,
          kernelGovernanceGate: _kernelGovernanceGate,
        ).startRolloutCandidate(
          modelType: 'outcome',
          fromVersion: previousVersion,
          toVersion: newVersion,
        );
      } catch (_) {
        // Ignore.
      }

      // TODO: Update remote config if available
      // await _updateRemoteConfig('outcome', newVersion);
    }

    return success;
  }

  /// Rollback to previous calling score version
  ///
  /// **Returns:**
  /// Previous version if rollback successful, null otherwise
  Future<String?> rollbackCallingScoreVersion() async {
    // TODO: Implement version history tracking
    // For now, rollback to a known safe version
    final currentVersion = ModelVersionRegistry.activeCallingScoreVersion;

    // If current is v1.0-hybrid, can't rollback (it's the first)
    if (currentVersion == 'v1.0-hybrid') {
      developer.log(
        'Cannot rollback: $currentVersion is the first version',
        name: _logName,
      );
      return null;
    }

    // Rollback to v1.0-hybrid as safe fallback
    final success = await switchCallingScoreVersion('v1.0-hybrid');
    return success ? 'v1.0-hybrid' : null;
  }

  /// Rollback to previous outcome prediction version
  ///
  /// **Returns:**
  /// Previous version if rollback successful, null otherwise
  Future<String?> rollbackOutcomeVersion() async {
    final currentVersion = ModelVersionRegistry.activeOutcomeVersion;

    if (currentVersion == 'v1.0-hybrid') {
      developer.log(
        'Cannot rollback: $currentVersion is the first version',
        name: _logName,
      );
      return null;
    }

    final success = await switchOutcomeVersion('v1.0-hybrid');
    return success ? 'v1.0-hybrid' : null;
  }

  /// Get version weight (with remote config override support)
  ///
  /// **Parameters:**
  /// - `version`: Version to get weight for
  /// - `modelType`: 'calling_score' or 'outcome'
  ///
  /// **Returns:**
  /// Weight for this version (0.0-1.0)
  Future<double> getVersionWeight(
    String version, {
    String modelType = 'calling_score',
  }) async {
    // Get base weight from registry
    double weight =
        ModelVersionRegistry.getVersionWeight(version, modelType: modelType);

    // TODO: Check remote config for weight override
    // final remoteWeight = await _fetchRemoteWeight(version, modelType);
    // if (remoteWeight != null) {
    //   weight = remoteWeight;
    // }

    return weight;
  }

  /// Update version weight (for dynamic weight adjustment)
  ///
  /// **Parameters:**
  /// - `version`: Version to update
  /// - `weight`: New weight (0.0-1.0)
  /// - `modelType`: 'calling_score' or 'outcome'
  Future<void> updateVersionWeight(
    String version,
    double weight, {
    String modelType = 'calling_score',
  }) async {
    weight = weight.clamp(0.0, 1.0);

    final versionInfo = modelType == 'calling_score'
        ? ModelVersionRegistry.getCallingScoreVersion(version)
        : ModelVersionRegistry.getOutcomeVersion(version);

    if (versionInfo != null) {
      // Update current weight
      versionInfo.currentWeight = weight;

      developer.log(
        'Updated $modelType version $version weight to ${(weight * 100).toStringAsFixed(1)}%',
        name: _logName,
      );

      // TODO: Update remote config if available
      // await _updateRemoteWeight(version, weight, modelType);
    }
  }

  /// Start A/B test for a new version
  ///
  /// **Parameters:**
  /// - `version`: Version to A/B test
  /// - `trafficPercentage`: Percentage of traffic to send to new version (0.0-1.0)
  /// - `modelType`: 'calling_score' or 'outcome'
  Future<void> startABTest(
    String version,
    double trafficPercentage, {
    String modelType = 'calling_score',
  }) async {
    trafficPercentage = trafficPercentage.clamp(0.0, 1.0);
    final correlationId =
        'mvm_abtest_${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final gateDecision = await _evaluateGovernance(
      KernelGovernanceRequest(
        action: KernelGovernanceAction.modelAbTestStart,
        modelType: modelType,
        toVersion: version,
        correlationId: correlationId,
        metadata: <String, dynamic>{
          'traffic_percentage': trafficPercentage,
        },
      ),
    );
    if (!gateDecision.servingAllowed) {
      developer.log(
        'Blocked AB test start for $modelType/$version: '
        '${gateDecision.reasonCodes.join(",")} decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );
      return;
    }

    final versionInfo = modelType == 'calling_score'
        ? ModelVersionRegistry.getCallingScoreVersion(version)
        : ModelVersionRegistry.getOutcomeVersion(version);

    if (versionInfo != null) {
      versionInfo.abTestTrafficPercentage = trafficPercentage;
      versionInfo.abTestStartDate = DateTime.now();

      developer.log(
        'Started A/B test for $modelType version $version: ${(trafficPercentage * 100).toStringAsFixed(1)}% traffic decision_id=${gateDecision.decisionId} corr=$correlationId',
        name: _logName,
      );
    }
  }

  /// Get A/B test status for a version
  ///
  /// **Returns:**
  /// A/B test traffic percentage (null if not in A/B test)
  double? getABTestTraffic(String version,
      {String modelType = 'calling_score'}) {
    final versionInfo = modelType == 'calling_score'
        ? ModelVersionRegistry.getCallingScoreVersion(version)
        : ModelVersionRegistry.getOutcomeVersion(version);

    return versionInfo?.abTestTrafficPercentage;
  }

  /// Register a new model version
  ///
  /// **Parameters:**
  /// - `versionInfo`: Model version information
  /// - `modelType`: 'calling_score' or 'outcome'
  Future<void> registerVersion(
    ModelVersionInfo versionInfo, {
    String modelType = 'calling_score',
  }) async {
    if (modelType == 'calling_score') {
      ModelVersionRegistry.registerCallingScoreVersion(versionInfo);
    } else {
      ModelVersionRegistry.registerOutcomeVersion(versionInfo);
    }

    developer.log(
      'Registered $modelType version: ${versionInfo.version}',
      name: _logName,
    );
  }

  Future<KernelGovernanceDecision> _evaluateGovernance(
    KernelGovernanceRequest request,
  ) async {
    if (_kernelGovernanceGate == null) {
      return KernelGovernanceDecision(
        decisionId: 'kgd_none',
        mode: KernelGovernanceMode.shadow,
        wouldAllow: true,
        servingAllowed: true,
        shadowBypassApplied: false,
        reasonCodes: const <String>['no_kernel_gate_configured'],
        policyVersion: 'none',
        timestamp: DateTime.now().toUtc(),
        correlationId: request.correlationId,
      );
    }
    return _kernelGovernanceGate.evaluate(request);
  }
}
