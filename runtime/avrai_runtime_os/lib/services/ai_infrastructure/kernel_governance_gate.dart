// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_telemetry_service.dart';

part 'kernel_governance_gate_models.dart';

enum KernelGovernanceMode {
  shadow,
  enforce,
}

enum KernelGovernanceAction {
  modelSwitch,
  modelRollback,
  modelAbTestStart,
  rolloutCandidateStart,
  happinessSignalIngest,
}

class KernelGovernanceRequest {
  const KernelGovernanceRequest({
    required this.action,
    this.modelType,
    this.fromVersion,
    this.toVersion,
    this.correlationId,
    this.metadata = const <String, dynamic>{},
  });

  final KernelGovernanceAction action;
  final String? modelType;
  final String? fromVersion;
  final String? toVersion;
  final String? correlationId;
  final Map<String, dynamic> metadata;
}

class KernelGovernanceDecision {
  const KernelGovernanceDecision({
    required this.decisionId,
    required this.mode,
    required this.wouldAllow,
    required this.servingAllowed,
    required this.shadowBypassApplied,
    required this.reasonCodes,
    required this.policyVersion,
    required this.timestamp,
    this.correlationId,
  });

  final String decisionId;
  final KernelGovernanceMode mode;
  final bool wouldAllow;
  final bool servingAllowed;
  final bool shadowBypassApplied;
  final List<String> reasonCodes;
  final String policyVersion;
  final DateTime timestamp;
  final String? correlationId;
}

class KernelGovernanceGate {
  static const String _logName = 'KernelGovernanceGate';
  static const String featureFlagEnforce =
      GovernanceFeatureFlags.kernelGovernanceEnforce;

  KernelGovernanceGate({
    UrkKernelRegistryService? registryService,
    this.featureFlagService,
    this.telemetryService,
    this.defaultMode = KernelGovernanceMode.shadow,
    Future<UrkKernelRegistrySnapshot> Function()? snapshotLoader,
  })  : _registryService = registryService ?? const UrkKernelRegistryService(),
        _snapshotLoader = snapshotLoader;

  final UrkKernelRegistryService _registryService;
  final FeatureFlagService? featureFlagService;
  final KernelGovernanceTelemetryService? telemetryService;
  final KernelGovernanceMode defaultMode;
  final Future<UrkKernelRegistrySnapshot> Function()? _snapshotLoader;

  UrkKernelRegistrySnapshot? _snapshot;
  bool _snapshotLoadAttempted = false;

  Future<KernelGovernanceDecision> evaluate(
    KernelGovernanceRequest request,
  ) async {
    final mode = await _resolveMode();
    final reasons = <String>[];
    bool wouldAllow = true;

    if ((request.modelType ?? '').isEmpty &&
        request.action != KernelGovernanceAction.happinessSignalIngest) {
      wouldAllow = false;
      reasons.add('missing_model_type');
    }

    if (request.action == KernelGovernanceAction.modelSwitch &&
        request.toVersion != null &&
        request.toVersion!.isEmpty) {
      wouldAllow = false;
      reasons.add('missing_target_version');
    }

    if (request.action == KernelGovernanceAction.rolloutCandidateStart &&
        ((request.fromVersion ?? '').isEmpty ||
            (request.toVersion ?? '').isEmpty)) {
      wouldAllow = false;
      reasons.add('invalid_rollout_versions');
    }

    if (request.fromVersion != null &&
        request.toVersion != null &&
        request.fromVersion == request.toVersion) {
      wouldAllow = false;
      reasons.add('no_version_change');
    }

    final requiredKernelIds = _requiredKernelIdsForAction(request.action);
    if (requiredKernelIds.isNotEmpty) {
      final kernelCheck = await _validateKernelPresence(requiredKernelIds);
      if (!kernelCheck.isValid) {
        wouldAllow = false;
        reasons.addAll(kernelCheck.reasonCodes);
      }
    }

    final servingAllowed = mode == KernelGovernanceMode.shadow || wouldAllow;
    final shadowBypassApplied =
        mode == KernelGovernanceMode.shadow && !wouldAllow;
    final timestamp = DateTime.now().toUtc();
    final decisionId =
        'kgd_${request.action.name}_${timestamp.microsecondsSinceEpoch}';
    final decision = KernelGovernanceDecision(
      decisionId: decisionId,
      mode: mode,
      wouldAllow: wouldAllow,
      servingAllowed: servingAllowed,
      shadowBypassApplied: shadowBypassApplied,
      reasonCodes: List<String>.unmodifiable(reasons),
      policyVersion: _snapshot?.version ?? 'unknown',
      timestamp: timestamp,
      correlationId: request.correlationId,
    );

    if (!decision.servingAllowed || decision.shadowBypassApplied) {
      developer.log(
        'Decision action=${request.action.name} mode=${decision.mode.name} '
        'allow=${decision.servingAllowed} decision_id=${decision.decisionId} '
        'corr=${decision.correlationId ?? "-"} reasons=${decision.reasonCodes.join(",")}',
        name: _logName,
      );
    }
    if (telemetryService != null) {
      try {
        await telemetryService!.recordDecision(
          KernelGovernanceTelemetryEvent(
            timestamp: decision.timestamp,
            decisionId: decision.decisionId,
            action: request.action.name,
            mode: decision.mode.name,
            wouldAllow: decision.wouldAllow,
            servingAllowed: decision.servingAllowed,
            shadowBypassApplied: decision.shadowBypassApplied,
            reasonCodes: decision.reasonCodes,
            policyVersion: decision.policyVersion,
            correlationId: decision.correlationId,
            modelType: request.modelType,
            fromVersion: request.fromVersion,
            toVersion: request.toVersion,
          ),
        );
      } catch (_) {
        // Best-effort telemetry persistence.
      }
    }

    return decision;
  }

  Future<KernelGovernanceMode> _resolveMode() async {
    if (featureFlagService == null) {
      return defaultMode;
    }
    try {
      final enforce = await featureFlagService!.isEnabled(
        featureFlagEnforce,
        defaultValue: defaultMode == KernelGovernanceMode.enforce,
      );
      return enforce
          ? KernelGovernanceMode.enforce
          : KernelGovernanceMode.shadow;
    } catch (_) {
      return defaultMode;
    }
  }

  List<String> _requiredKernelIdsForAction(KernelGovernanceAction action) {
    switch (action) {
      case KernelGovernanceAction.modelSwitch:
      case KernelGovernanceAction.modelRollback:
      case KernelGovernanceAction.modelAbTestStart:
      case KernelGovernanceAction.rolloutCandidateStart:
        return const <String>[
          'urk_learning_update_governance',
          'urk_kernel_promotion_lifecycle',
        ];
      case KernelGovernanceAction.happinessSignalIngest:
        return const <String>['urk_learning_update_governance'];
    }
  }

  Future<_KernelValidationResult> _validateKernelPresence(
    List<String> requiredKernelIds,
  ) async {
    final snapshot = await _loadSnapshot();
    if (snapshot == null) {
      return const _KernelValidationResult(
        isValid: false,
        reasonCodes: <String>['kernel_registry_unavailable'],
      );
    }

    final byId = <String, UrkKernelRecord>{
      for (final kernel in snapshot.kernels) kernel.kernelId: kernel,
    };
    final reasonCodes = <String>[];
    for (final kernelId in requiredKernelIds) {
      final kernel = byId[kernelId];
      if (kernel == null) {
        reasonCodes.add('missing_$kernelId');
        continue;
      }
      if (kernel.authorityMode != 'enforced' &&
          kernel.authorityMode != 'shadow') {
        reasonCodes.add('invalid_authority_mode_$kernelId');
      }
      if (kernel.status != 'done') {
        reasonCodes.add('kernel_not_done_$kernelId');
      }
    }
    return _KernelValidationResult(
      isValid: reasonCodes.isEmpty,
      reasonCodes: reasonCodes,
    );
  }

  Future<UrkKernelRegistrySnapshot?> _loadSnapshot() async {
    if (_snapshot != null) {
      return _snapshot;
    }
    if (_snapshotLoadAttempted) {
      return null;
    }
    _snapshotLoadAttempted = true;
    try {
      _snapshot = _snapshotLoader != null
          ? await _snapshotLoader()
          : await _registryService.loadSnapshot();
      return _snapshot;
    } catch (_) {
      return null;
    }
  }
}
