import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('HeadlessAvraiOsBootstrapService', () {
    test('starts the headless host once and caches health snapshot', () async {
      final host = _FakeBootstrapHeadlessHost();
      final service = HeadlessAvraiOsBootstrapService(host: host);

      final first = await service.initialize();
      final second = await service.initialize();

      expect(first.state.started, isTrue);
      expect(first.state.localityContainedInWhere, isTrue);
      expect(first.healthReports.length, 2);
      expect(service.snapshot, isNotNull);
      expect(service.lastError, isNull);
      expect(identical(first, second), isTrue);
      expect(host.startCalls, 1);
      expect(host.healthCalls, 1);
    });

    test('tryInitialize captures startup failures without throwing', () async {
      final host = _FailingBootstrapHeadlessHost();
      final service = HeadlessAvraiOsBootstrapService(host: host);

      final snapshot = await service.tryInitialize();

      expect(snapshot, isNull);
      expect(service.snapshot, isNull);
      expect(service.lastError, isNotNull);
      expect(host.startCalls, 1);
    });

    test('restores a persisted snapshot before live bootstrap refresh',
        () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'headless_avrai_os_bootstrap_restore_test',
        ),
      );
      final originalHost = _FakeBootstrapHeadlessHost();
      final originalService = HeadlessAvraiOsBootstrapService(
        host: originalHost,
        prefs: prefs,
      );

      final persistedSnapshot = await originalService.initialize();

      final restoringHost = _FailingBootstrapHeadlessHost();
      final restoringService = HeadlessAvraiOsBootstrapService(
        host: restoringHost,
        prefs: prefs,
      );
      final restoredSnapshot =
          await restoringService.restorePersistedSnapshot();

      expect(restoredSnapshot, isNotNull);
      expect(restoredSnapshot!.restoredFromPersistence, isTrue);
      expect(restoredSnapshot.state.started, isTrue);
      expect(restoredSnapshot.state.localityContainedInWhere, isTrue);
      expect(restoredSnapshot.healthReports.length, 2);
      expect(
        restoredSnapshot.startedAtUtc,
        persistedSnapshot.startedAtUtc,
      );
      expect(restoringService.snapshot, isNotNull);
      expect(restoringHost.startCalls, 0);
    });
  });
}

class _FakeBootstrapHeadlessHost implements HeadlessAvraiOsHost {
  int startCalls = 0;
  int healthCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 6),
      localityContainedInWhere: true,
      summary: 'booted',
    );
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async {
    healthCalls += 1;
    return const <KernelHealthReport>[
      KernelHealthReport(
        domain: KernelDomain.when,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'when ready',
      ),
      KernelHealthReport(
        domain: KernelDomain.where,
        status: KernelHealthStatus.healthy,
        nativeBacked: true,
        headlessReady: true,
        authorityLevel: KernelAuthorityLevel.authoritative,
        summary: 'where ready',
      ),
    ];
  }

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) {
    throw UnimplementedError();
  }
}

class _FailingBootstrapHeadlessHost implements HeadlessAvraiOsHost {
  int startCalls = 0;

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    startCalls += 1;
    throw StateError('bootstrap failed');
  }

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async =>
      const <KernelHealthReport>[];

  @override
  Future<KernelGovernanceReport> inspectGovernance({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<KernelContextBundle> resolveRuntimeExecution({
    required KernelEventEnvelope envelope,
  }) {
    throw UnimplementedError();
  }
}
