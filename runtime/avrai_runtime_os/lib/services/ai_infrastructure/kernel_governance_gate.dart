// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/why/why_models.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_evidence_adapters.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_support.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';
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

class KernelGovernanceExplainedDecision {
  const KernelGovernanceExplainedDecision({
    required this.decision,
    required this.explanation,
  });

  final KernelGovernanceDecision decision;
  final WhySnapshot explanation;
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
    DefaultWhyKernelSupport? whyKernel,
    TemporalWhyEvidenceAdapter? temporalEvidenceAdapter,
    HowMechanismWhyEvidenceAdapter? howEvidenceAdapter,
    Future<UrkKernelRegistrySnapshot> Function()? snapshotLoader,
    this.nativeBridge,
    this.nativePolicy = const KernelGovernanceNativeExecutionPolicy(),
    this.nativeAudit,
    this.whenKernel,
  })  : _registryService = registryService ?? const UrkKernelRegistryService(),
        _whyKernel = whyKernel ?? const DefaultWhyKernelSupport(),
        _temporalEvidenceAdapter =
            temporalEvidenceAdapter ?? const TemporalWhyEvidenceAdapter(),
        _howEvidenceAdapter =
            howEvidenceAdapter ?? const HowMechanismWhyEvidenceAdapter(),
        _snapshotLoader = snapshotLoader;

  final UrkKernelRegistryService _registryService;
  final FeatureFlagService? featureFlagService;
  final KernelGovernanceTelemetryService? telemetryService;
  final KernelGovernanceMode defaultMode;
  final KernelGovernanceNativeInvocationBridge? nativeBridge;
  final KernelGovernanceNativeExecutionPolicy nativePolicy;
  final KernelGovernanceNativeFallbackAudit? nativeAudit;
  final WhenKernelContract? whenKernel;
  final DefaultWhyKernelSupport _whyKernel;
  final TemporalWhyEvidenceAdapter _temporalEvidenceAdapter;
  final HowMechanismWhyEvidenceAdapter _howEvidenceAdapter;
  final Future<UrkKernelRegistrySnapshot> Function()? _snapshotLoader;

  UrkKernelRegistrySnapshot? _snapshot;
  bool _snapshotLoadAttempted = false;

  Future<KernelGovernanceDecision> evaluate(
    KernelGovernanceRequest request,
  ) async {
    final mode = await _resolveMode();
    final requiredKernelIds = _requiredKernelIdsForAction(request.action);
    final snapshot = await _loadSnapshot();
    final evaluation = await _evaluateAuthority(
      request: request,
      mode: mode,
      requiredKernelIds: requiredKernelIds,
      snapshot: snapshot,
    );
    final timestamp = await _resolveDecisionTimestamp(request);
    final decisionId =
        'kgd_${request.action.name}_${timestamp.microsecondsSinceEpoch}';
    final decision = KernelGovernanceDecision(
      decisionId: decisionId,
      mode: mode,
      wouldAllow: evaluation.wouldAllow,
      servingAllowed: evaluation.servingAllowed,
      shadowBypassApplied: evaluation.shadowBypassApplied,
      reasonCodes: List<String>.unmodifiable(evaluation.reasonCodes),
      policyVersion: evaluation.policyVersion,
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

  Future<_KernelGovernanceNativeEvaluation> _evaluateAuthority({
    required KernelGovernanceRequest request,
    required KernelGovernanceMode mode,
    required List<String> requiredKernelIds,
    required UrkKernelRegistrySnapshot? snapshot,
  }) async {
    final bridge = nativeBridge;
    if (bridge != null) {
      bridge.initialize();
      if (bridge.isAvailable) {
        final response = bridge.invoke(
          syscall: 'evaluate_kernel_governance',
          payload: <String, dynamic>{
            'mode': mode.name,
            'action': _nativeActionValue(request.action),
            if (request.modelType != null) 'model_type': request.modelType,
            if (request.fromVersion != null) 'from_version': request.fromVersion,
            if (request.toVersion != null) 'to_version': request.toVersion,
            'policy_version': snapshot?.version ?? 'unknown',
            'required_kernel_ids': requiredKernelIds,
            'kernels': snapshot?.kernels
                    .map(
                      (kernel) => <String, dynamic>{
                        'kernel_id': kernel.kernelId,
                        'authority_mode': kernel.authorityMode,
                        'status': kernel.status,
                      },
                    )
                    .toList() ??
                const <Map<String, dynamic>>[],
          },
        );
        if (response['handled'] == true) {
          nativeAudit?.recordNativeHandled();
          final payload = Map<String, dynamic>.from(
            response['payload'] as Map? ?? const <String, dynamic>{},
          );
          return _KernelGovernanceNativeEvaluation(
            wouldAllow: payload['would_allow'] as bool? ?? false,
            servingAllowed: payload['serving_allowed'] as bool? ?? false,
            shadowBypassApplied:
                payload['shadow_bypass_applied'] as bool? ?? false,
            reasonCodes: ((payload['reason_codes'] as List?) ?? const [])
                .map((entry) => entry.toString())
                .toList(),
            policyVersion:
                payload['policy_version'] as String? ?? snapshot?.version ?? 'unknown',
          );
        }
        nativeAudit?.recordFallback(
          KernelGovernanceNativeFallbackReason.deferred,
        );
        nativePolicy.verifyFallbackAllowed(
          syscall: 'evaluate_kernel_governance',
          reason: KernelGovernanceNativeFallbackReason.deferred,
        );
      } else {
        nativeAudit?.recordFallback(
          KernelGovernanceNativeFallbackReason.unavailable,
        );
        nativePolicy.verifyFallbackAllowed(
          syscall: 'evaluate_kernel_governance',
          reason: KernelGovernanceNativeFallbackReason.unavailable,
        );
      }
    }

    final reasons = <String>[];
    var wouldAllow = true;

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

    if (requiredKernelIds.isNotEmpty) {
      final kernelCheck =
          await _validateKernelPresence(requiredKernelIds, snapshot: snapshot);
      if (!kernelCheck.isValid) {
        wouldAllow = false;
        reasons.addAll(kernelCheck.reasonCodes);
      }
    }

    return _KernelGovernanceNativeEvaluation(
      wouldAllow: wouldAllow,
      servingAllowed: mode == KernelGovernanceMode.shadow || wouldAllow,
      shadowBypassApplied:
          mode == KernelGovernanceMode.shadow && !wouldAllow,
      reasonCodes: reasons,
      policyVersion: snapshot?.version ?? 'unknown',
    );
  }

  Future<KernelGovernanceExplainedDecision> evaluateWithExplanation(
    KernelGovernanceRequest request,
  ) async {
    final decision = await evaluate(request);
    final explanation = _whyKernel.explain(
      WhyKernelRequest(
        goal: 'kernel_governance_${request.action.name}',
        actionRef: WhyRef(
          id: request.action.name,
          label: request.action.name,
          kind: 'kernel_governance_action',
        ),
        outcomeRef: WhyRef(
          id: decision.servingAllowed ? 'allowed' : 'blocked',
          label: decision.servingAllowed ? 'allowed' : 'blocked',
          kind: 'governance_outcome',
        ),
        queryKind: WhyQueryKind.policyAction,
        requestedPerspective: WhyRequestedPerspective.governance,
        policyContext: <String, dynamic>{
          'policyRefs': <String>[decision.policyVersion],
          'escalationThresholds': decision.reasonCodes,
        },
        evidenceBundle: WhyEvidenceBundle(
          entries: <WhyEvidence>[
            _decisionEvidence(request, decision),
            _temporalEvidenceAdapter.toWhyEvidence(
              _decisionTemporalSnapshot(request, decision),
            ),
            _howEvidenceAdapter.toWhyEvidence(
              _decisionMechanismContext(request, decision),
            ),
            ...decision.reasonCodes.map(
              (reason) => WhyEvidence(
                id: 'reason_$reason',
                label: 'governance reason: $reason',
                weight: 0.78,
                polarity: WhyEvidencePolarity.negative,
                sourceKernel: WhyEvidenceSourceKernel.policy,
                sourceSubsystem: 'kernel_governance_gate',
                durability: 'durable',
                confidence: 0.84,
                observed: true,
                inferred: false,
                provenance: decision.policyVersion,
                subjectRef: request.modelType,
                scope: request.action.name,
                tags: <String>['governance', reason],
              ),
            ),
          ],
        ),
        linkedWhatRefs: <WhyRef>[
          if ((request.modelType ?? '').isNotEmpty)
            WhyRef(
              id: request.modelType!,
              label: request.modelType,
              kind: 'model_type',
            ),
        ],
        linkedWhenRefs: <WhyRef>[
          WhyRef(
            id: decision.timestamp.toIso8601String(),
            label: decision.timestamp.toIso8601String(),
            kind: 'decision_timestamp',
          ),
        ],
        linkedHowRefs: <WhyRef>[
          WhyRef(
            id: _executionPathFromRequest(request),
            label: _executionPathFromRequest(request),
            kind: 'execution_path',
          ),
        ],
        maxCounterfactuals: 2,
        explanationDepth: 3,
      ),
    );

    return KernelGovernanceExplainedDecision(
      decision: decision,
      explanation: explanation,
    );
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
      {UrkKernelRegistrySnapshot? snapshot}) async {
    final resolvedSnapshot = snapshot ?? await _loadSnapshot();
    if (resolvedSnapshot == null) {
      return const _KernelValidationResult(
        isValid: false,
        reasonCodes: <String>['kernel_registry_unavailable'],
      );
    }

    final byId = <String, UrkKernelRecord>{
      for (final kernel in resolvedSnapshot.kernels) kernel.kernelId: kernel,
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

  Future<DateTime> _resolveDecisionTimestamp(
    KernelGovernanceRequest request,
  ) async {
    final fallbackTime = DateTime.now().toUtc();
    final kernel = whenKernel;
    if (kernel == null) {
      return fallbackTime;
    }
    try {
      final timestamp = await kernel.issueTimestamp(
        WhenTimestampRequest(
          referenceId: request.correlationId ??
              'kernel_governance_${request.action.name}',
          occurredAtUtc: fallbackTime,
          runtimeId: 'kernel_governance_gate',
          context: <String, dynamic>{
            'action': request.action.name,
            if (request.modelType != null) 'model_type': request.modelType,
          },
        ),
      );
      return timestamp.observedAtUtc;
    } catch (_) {
      return fallbackTime;
    }
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

  WhyEvidence _decisionEvidence(
    KernelGovernanceRequest request,
    KernelGovernanceDecision decision,
  ) {
    return WhyEvidence(
      id: decision.decisionId,
      label: decision.servingAllowed
          ? 'governance allowed ${request.action.name}'
          : 'governance blocked ${request.action.name}',
      weight: decision.wouldAllow ? 0.72 : 0.93,
      polarity: decision.servingAllowed
          ? WhyEvidencePolarity.positive
          : WhyEvidencePolarity.negative,
      sourceKernel: WhyEvidenceSourceKernel.policy,
      sourceSubsystem: 'kernel_governance_gate',
      durability: 'durable',
      confidence: decision.wouldAllow ? 0.76 : 0.94,
      observed: true,
      inferred: false,
      provenance: decision.policyVersion,
      timeRef: decision.timestamp.toIso8601String(),
      subjectRef: request.modelType,
      scope: decision.mode.name,
      tags: <String>[
        request.action.name,
        decision.mode.name,
        if (decision.shadowBypassApplied) 'shadow_bypass',
      ],
    );
  }

  TemporalSnapshot _decisionTemporalSnapshot(
    KernelGovernanceRequest request,
    KernelGovernanceDecision decision,
  ) {
    final instant = TemporalInstant(
      referenceTime: decision.timestamp,
      civilTime: decision.timestamp,
      timezoneId: 'UTC',
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'kernel_governance_gate',
      ),
      uncertainty: const TemporalUncertainty.zero(),
    );
    return TemporalSnapshot(
      observedAt: instant,
      recordedAt: instant,
      effectiveAt: instant,
      semanticBand: _semanticBandFor(decision.timestamp),
      lineageRef: request.correlationId ?? decision.decisionId,
    );
  }

  HowMechanismContext _decisionMechanismContext(
    KernelGovernanceRequest request,
    KernelGovernanceDecision decision,
  ) {
    final metadata = request.metadata;
    return HowMechanismContext(
      executionPath: _executionPathFromRequest(request),
      workflowStage:
          (metadata['workflowStage'] as String?) ?? 'governance_gate',
      failureMechanism: decision.reasonCodes.isEmpty
          ? null
          : (metadata['failureMechanism'] as String?) ??
              decision.reasonCodes.first,
      mechanismConfidence:
          (metadata['mechanismConfidence'] as num?)?.toDouble() ?? 0.79,
      interventionChain:
          ((metadata['interventionChain'] as List?) ?? const <dynamic>[])
              .map((entry) => entry.toString())
              .toList(),
      modelFamily: request.modelType,
    );
  }

  String _executionPathFromRequest(KernelGovernanceRequest request) {
    return (request.metadata['executionPath'] as String?) ??
        'kernel_governance_gate';
  }

  String _nativeActionValue(KernelGovernanceAction action) {
    return switch (action) {
      KernelGovernanceAction.modelSwitch => 'model_switch',
      KernelGovernanceAction.modelRollback => 'model_rollback',
      KernelGovernanceAction.modelAbTestStart => 'model_ab_test_start',
      KernelGovernanceAction.rolloutCandidateStart =>
        'rollout_candidate_start',
      KernelGovernanceAction.happinessSignalIngest =>
        'happiness_signal_ingest',
    };
  }

  SemanticTimeBand _semanticBandFor(DateTime instant) {
    final hour = instant.hour;
    if (hour >= 5 && hour < 8) {
      return SemanticTimeBand.dawn;
    }
    if (hour >= 8 && hour < 12) {
      return SemanticTimeBand.morning;
    }
    if (hour == 12) {
      return SemanticTimeBand.noon;
    }
    if (hour > 12 && hour < 17) {
      return SemanticTimeBand.afternoon;
    }
    if (hour >= 17 && hour < 19) {
      return SemanticTimeBand.dusk;
    }
    if (hour >= 19 && hour < 20) {
      return SemanticTimeBand.goldenHour;
    }
    if (hour >= 20 || hour < 5) {
      return SemanticTimeBand.night;
    }
    return SemanticTimeBand.unknown;
  }
}
