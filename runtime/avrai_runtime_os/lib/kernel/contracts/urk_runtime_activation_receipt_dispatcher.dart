// MIGRATION_SHIM: LEGACY_PATH_GUARD TEMPORARY UNTIL TARGET-ROOT MIGRATION
import 'dart:developer' as developer;

import 'package:avrai_runtime_os/kernel/contracts/urk_kernel_activation_engine_contract.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_control_plane_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/services/intake/intake_models.dart';
import 'package:avrai_runtime_os/services/intake/upward_air_gap_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:get_it/get_it.dart';

class UrkRuntimeActivationReceiptDispatcher {
  UrkRuntimeActivationReceiptDispatcher({
    required UrkKernelControlPlaneService controlPlaneService,
    UrkKernelRegistryService registryService = const UrkKernelRegistryService(),
    UrkKernelActivationEngine activationEngine =
        const UrkKernelActivationEngine(),
    GovernedUpwardLearningIntakeService? governedUpwardLearningIntakeService,
  })  : _controlPlaneService = controlPlaneService,
        _registryService = registryService,
        _activationEngine = activationEngine,
        _governedUpwardLearningIntakeService =
            governedUpwardLearningIntakeService ??
                (GetIt.I.isRegistered<GovernedUpwardLearningIntakeService>()
                    ? GetIt.I<GovernedUpwardLearningIntakeService>()
                    : null);

  static const String _logName = 'UrkRuntimeActivationReceiptDispatcher';

  final UrkKernelControlPlaneService _controlPlaneService;
  final UrkKernelRegistryService _registryService;
  final UrkKernelActivationEngine _activationEngine;
  final GovernedUpwardLearningIntakeService?
      _governedUpwardLearningIntakeService;

  List<UrkKernelActivationRule>? _cachedRules;

  Future<UrkKernelActivationReceipt?> dispatch({
    required String requestId,
    required String trigger,
    required UrkPrivacyMode privacyMode,
    required String actor,
    required String reason,
  }) async {
    try {
      final rules = await _loadRules();
      final controlPlane = await _controlPlaneService.listKernels();
      final activeKernelIds = controlPlane
          .where(
            (record) =>
                record.state.state == UrkKernelRuntimeState.active ||
                record.state.state == UrkKernelRuntimeState.shadow,
          )
          .map((record) => record.kernel.kernelId)
          .toSet();

      final receipt = _activationEngine.evaluate(
        request: UrkKernelActivationRequest(
          requestId: requestId,
          trigger: trigger,
          privacyMode: privacyMode,
          activeKernels: activeKernelIds,
        ),
        rules: rules,
      );

      for (final decision in receipt.decisions) {
        if (!decision.activated) {
          continue;
        }
        await _controlPlaneService.recordActivationReceipt(
          kernelId: decision.kernelId,
          requestId: requestId,
          actor: actor,
          reason: '$reason:${decision.reason}',
        );
      }
      await _stageKernelOfflineEvidenceReceipt(
        requestId: requestId,
        trigger: trigger,
        privacyMode: privacyMode,
        actor: actor,
        reason: reason,
        receipt: receipt,
      );
      return receipt;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to dispatch activation receipt: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<List<UrkKernelActivationRule>> _loadRules() async {
    final cached = _cachedRules;
    if (cached != null) {
      return cached;
    }
    final snapshot = await _registryService.loadSnapshot();
    final kernelIds = snapshot.kernels.map((kernel) => kernel.kernelId).toSet();
    final rules = snapshot.kernels.map((kernel) {
      return UrkKernelActivationRule(
        kernelId: kernel.kernelId,
        activationTriggers: kernel.activationTriggers,
        privacyModes: kernel.privacyModes.map(_modeFromRegistry).toList(),
        // Registry dependency values may include non-kernel references
        // (for example milestone IDs). Only enforce kernel-to-kernel deps.
        dependencies: kernel.dependencies
            .where(kernelIds.contains)
            .toList(growable: false),
      );
    }).toList(growable: false);
    _cachedRules = rules;
    return rules;
  }

  UrkPrivacyMode _modeFromRegistry(String mode) {
    switch (mode) {
      case 'local_sovereign':
        return UrkPrivacyMode.localSovereign;
      case 'private_mesh':
        return UrkPrivacyMode.privateMesh;
      case 'federated_cloud':
        return UrkPrivacyMode.federatedCloud;
      case 'multi_mode':
      default:
        return UrkPrivacyMode.multiMode;
    }
  }

  Future<void> _stageKernelOfflineEvidenceReceipt({
    required String requestId,
    required String trigger,
    required UrkPrivacyMode privacyMode,
    required String actor,
    required String reason,
    required UrkKernelActivationReceipt receipt,
  }) async {
    final governedService = _governedUpwardLearningIntakeService;
    if (governedService == null || receipt.decisions.isEmpty) {
      return;
    }

    final observedAtUtc = DateTime.now().toUtc();
    final activatedKernelIds = receipt.decisions
        .where((decision) => decision.activated)
        .map((decision) => decision.kernelId)
        .toSet()
        .toList()
      ..sort();
    final blockedKernelIds = receipt.decisions
        .where((decision) => !decision.activated)
        .map((decision) => decision.kernelId)
        .toSet()
        .toList()
      ..sort();
    final boundedEvidence = <String, dynamic>{
      'trigger': trigger,
      'privacyMode': privacyMode.name,
      'actor': actor,
      'reason': reason,
      'decisionCount': receipt.decisions.length,
      'activatedCount': activatedKernelIds.length,
      'blockedCount': blockedKernelIds.length,
      'decisions': receipt.decisions
          .map(
            (decision) => <String, dynamic>{
              'kernelId': decision.kernelId,
              'activated': decision.activated,
              'reason': decision.reason,
            },
          )
          .toList(growable: false),
    };
    final signalTags = <String>[
      'event_type:activation_dispatch_receipt',
      'source:urk_runtime_activation_receipt_dispatcher',
      'trigger:$trigger',
      'privacy_mode:${privacyMode.name}',
      'activated_count:${activatedKernelIds.length}',
    ];

    final receiptEnvelope = KernelOfflineEvidenceReceipt(
      receiptId: 'urk_dispatch_$requestId',
      receiptKind: 'activation_dispatch_receipt',
      sourceSystem: 'urk_runtime_activation_receipt_dispatcher',
      sourcePlane: 'runtime_dispatcher',
      observedAtUtc: observedAtUtc,
      requestId: requestId,
      lineageRef: 'dispatch:$requestId',
      actorScope: 'runtime_dispatcher',
      boundedEvidence: boundedEvidence,
      temporalLineage: <String, dynamic>{
        'originOccurredAtUtc': observedAtUtc.toIso8601String(),
        'dispatcherEvaluatedAtUtc': observedAtUtc.toIso8601String(),
      },
      signalTags: signalTags,
    );
    final airGapArtifact = const UpwardAirGapService().issueArtifact(
      originPlane: 'runtime_dispatcher',
      sourceKind: 'kernel_offline_evidence_receipt_intake',
      sourceScope: 'kernel',
      destinationCeiling: 'reality_model_agent',
      issuedAtUtc: DateTime.now().toUtc(),
      pseudonymousActorRef: 'kernel:runtime_dispatcher',
      sanitizedPayload: <String, dynamic>{
        'receiptId': receiptEnvelope.receiptId,
        'receiptKind': receiptEnvelope.receiptKind,
        'sourceSystem': receiptEnvelope.sourceSystem,
        'requestId': requestId,
        'trigger': trigger,
        'privacyMode': privacyMode.name,
        'activatedKernelIds': activatedKernelIds,
      },
    );

    try {
      await governedService.stageKernelOfflineEvidenceReceiptIntake(
        ownerUserId: 'kernel_runtime_dispatcher',
        receipt: receiptEnvelope,
        airGapArtifact: airGapArtifact,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to stage URK dispatch receipt into governed upward learning: $error',
        name: _logName,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

UrkRuntimeActivationReceiptDispatcher?
    resolveDefaultUrkRuntimeActivationDispatcher() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<UrkKernelControlPlaneService>()) {
    return null;
  }
  return UrkRuntimeActivationReceiptDispatcher(
    controlPlaneService: sl<UrkKernelControlPlaneService>(),
  );
}
