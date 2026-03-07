import 'dart:async';
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai_core/models/spots/visit.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_kernel.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';

/// Ingests visits/check-ins into LocalityAgents (v1).
///
/// Responsibilities:
/// - compatibility adapter for the kernel-owned locality subsystem
/// - preserve the legacy public API while the rest of the codebase is migrated
@Deprecated('Use LocalityKernel as the canonical locality runtime surface.')
class LocalityAgentIngestionServiceV1 {
  static const String _logName = 'LocalityAgentIngestionServiceV1';
  final LocalityKernelContract _kernel;

  LocalityAgentIngestionServiceV1({
    required LocalityKernelContract kernel,
  }) : _kernel = kernel;

  /// Seed the homebase LocalityAgent during onboarding.
  ///
  /// This primes caches and creates a minimal backend update record (best-effort).
  Future<void> seedHomebase({
    required String userId,
    required String agentId,
    required double latitude,
    required double longitude,
    String? cityCode,
    String source = 'onboarding_seed',
  }) async {
    try {
      await _kernel.seedHomebase(
        userId: userId,
        agentId: agentId,
        latitude: latitude,
        longitude: longitude,
        cityCode: cityCode,
        source: source,
      );
      developer.log(
        'Delegated homebase seed to LocalityKernel',
        name: _logName,
      );
    } catch (e, st) {
      developer.log('Failed delegating homebase seed: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Ingest a completed visit into the locality agent system.
  ///
  /// Best-effort; failures should not block checkout flows.
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
        'Delegated visit ingestion to LocalityKernel',
        name: _logName,
      );
    } catch (e, st) {
      developer.log('Kernel-backed visit ingestion failed: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Convenience getter for use sites that don't have DI access.
  static LocalityAgentIngestionServiceV1? tryGetFromDI() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<LocalityAgentIngestionServiceV1>()) return null;
    return sl<LocalityAgentIngestionServiceV1>();
  }
}
