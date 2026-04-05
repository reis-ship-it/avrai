import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avrai/presentation/widgets/common/headless_os_status_banner.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;

import '../../../helpers/platform_channel_helper.dart';

void main() {
  group('HeadlessOsStatusBanner', () {
    testWidgets('renders restored status details', (tester) async {
      final prefs = await SharedPreferencesCompat.getInstance(
        storage: getTestStorage(
          boxName: 'headless_os_status_banner_restored',
        ),
      );
      final seedingBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeBannerHeadlessHost(),
        prefs: prefs,
      );
      await seedingBootstrap.initialize();
      final restoredBootstrap = HeadlessAvraiOsBootstrapService(
        host: _FakeBannerHeadlessHost(),
        prefs: prefs,
      );
      await restoredBootstrap.restorePersistedSnapshot();
      final service = HeadlessAvraiOsAvailabilityService(
        bootstrapService: restoredBootstrap,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HeadlessOsStatusBanner(service: service),
          ),
        ),
      );
      await tester.pump();

      expect(
          find.byKey(const Key('headless_os_status_banner')), findsOneWidget);
      expect(find.text('Headless AVRAI OS restored'), findsOneWidget);
      expect(find.textContaining('locality in where'), findsOneWidget);
    });
  });
}

class _FakeBannerHeadlessHost implements HeadlessAvraiOsHost {
  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 7),
      localityContainedInWhere: true,
      summary: 'headless banner',
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
