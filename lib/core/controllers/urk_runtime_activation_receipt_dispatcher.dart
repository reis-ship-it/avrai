import 'dart:developer' as developer;

import 'package:avrai/core/controllers/urk_kernel_activation_engine_contract.dart';
import 'package:avrai/core/services/admin/urk_kernel_control_plane_service.dart';
import 'package:avrai/core/services/admin/urk_kernel_registry_service.dart';
import 'package:get_it/get_it.dart';

class UrkRuntimeActivationReceiptDispatcher {
  UrkRuntimeActivationReceiptDispatcher({
    required UrkKernelControlPlaneService controlPlaneService,
    UrkKernelRegistryService registryService = const UrkKernelRegistryService(),
    UrkKernelActivationEngine activationEngine =
        const UrkKernelActivationEngine(),
  })  : _controlPlaneService = controlPlaneService,
        _registryService = registryService,
        _activationEngine = activationEngine;

  static const String _logName = 'UrkRuntimeActivationReceiptDispatcher';

  final UrkKernelControlPlaneService _controlPlaneService;
  final UrkKernelRegistryService _registryService;
  final UrkKernelActivationEngine _activationEngine;

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
