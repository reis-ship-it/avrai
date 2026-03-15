import 'package:flutter_test/flutter_test.dart';

import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../helpers/platform_channel_helper.dart';

void main() {
  group('HeadlessAvraiOsAvailabilityService', () {
    test('returns restored availability before live startup refresh', () async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'headless_os_availability_restored_test',
        ),
      );
      final seedingBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeAvailabilityHeadlessHost(),
        prefs: prefs,
      );
      await seedingBootstrap.initialize();

      final restoredBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeAvailabilityHeadlessHost(),
        prefs: prefs,
      );
      await restoredBootstrap.restorePersistedSnapshot();
      final service = HeadlessAvraiOsAvailabilityService(
        bootstrapService: restoredBootstrap,
      );

      final snapshot = await service.currentAvailability();

      expect(snapshot.available, isTrue);
      expect(snapshot.liveReady, isFalse);
      expect(snapshot.restoredReady, isTrue);
      expect(snapshot.localityContainedInWhere, isTrue);
      expect(snapshot.kernelCount, 2);
      expect(snapshot.summary, 'Headless AVRAI OS restored');
    });

    test('emits live readiness after bootstrap initializes', () async {
      final bootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeAvailabilityHeadlessHost(),
      );
      final service = HeadlessAvraiOsAvailabilityService(
        bootstrapService: bootstrap,
      );

      final snapshots = <HeadlessAvraiOsAvailabilitySnapshot>[];
      final subscription = service.watchAvailability().listen(snapshots.add);

      await bootstrap.initialize();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(
        snapshots.any((entry) => entry.liveReady && entry.available),
        isTrue,
      );
    });
  });
}

class _FakeAvailabilityHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'headless live',
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
