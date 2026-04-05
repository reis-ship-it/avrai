import 'dart:async';
import 'dart:developer' as developer;

import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/misc/governance_inspection.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/where/where_kernel_outputs.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_governed_runtime_registry_service.dart';

/// Legacy adapter that forwards onboarding and visit events into the where
/// kernel.
class WhereKernelIngestionAdapter {
  static const String _logName = 'WhereKernelIngestionAdapter';

  final WhereKernelContract _kernel;
  final UrkGovernedRuntimeRegistryService? _governedRuntimeRegistryService;

  WhereKernelIngestionAdapter({
    required WhereKernelContract kernel,
    UrkGovernedRuntimeRegistryService? governedRuntimeRegistryService,
  })  : _kernel = kernel,
        _governedRuntimeRegistryService = governedRuntimeRegistryService ??
            (GetIt.instance.isRegistered<UrkGovernedRuntimeRegistryService>()
                ? GetIt.instance<UrkGovernedRuntimeRegistryService>()
                : null);

  Future<void> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'onboarding_seed',
  }) async {
    try {
      final localityState = await _kernel.seedHomebase(
        userId: userId,
        agentId: agentId,
        latitude: latitude,
        longitude: longitude,
        cityCode: cityCode,
        source: source,
      );
      await _registerLocalityRuntimeBinding(
        userId: userId,
        agentId: agentId,
        localityState: localityState,
        cityCode: cityCode,
      );
      developer.log(
        'Delegated homebase seed to WhereKernelContract',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Failed delegating homebase seed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> ingestVisit({
    required String userId,
    required Visit visit,
    required String source,
  }) async {
    try {
      await _kernel.observeVisit(
        userId: userId,
        visit: visit,
        source: source,
      );
      developer.log(
        'Delegated visit ingestion to WhereKernelContract',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Kernel-backed visit ingestion failed: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  static WhereKernelIngestionAdapter? tryGetFromDI() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<WhereKernelIngestionAdapter>()) return null;
    return sl<WhereKernelIngestionAdapter>();
  }

  Future<void> _registerLocalityRuntimeBinding({
    required String userId,
    required String agentId,
    required WhereState localityState,
    String? cityCode,
  }) async {
    final registry = _governedRuntimeRegistryService;
    if (registry == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final runtimeIds =
        UrkGovernedRuntimeRegistryService.canonicalLocalityRuntimeIds(
      userId: userId,
      agentId: agentId,
      localityTokenId: localityState.activeToken.id,
      cityCode: cityCode,
      topAlias: localityState.topAlias,
    );
    for (final runtimeId in runtimeIds) {
      await registry.upsertBinding(
        UrkGovernedRuntimeBinding(
          runtimeId: runtimeId,
          stratum: GovernanceStratum.locality,
          userId: userId,
          aiSignature: null,
          agentId: agentId,
          source: 'locality_homebase_seed',
          updatedAt: AtomicTimestamp.now(
            precision: TimePrecision.millisecond,
            isSynchronized: true,
            serverTime: now,
          ),
        ),
      );
    }
  }
}
