import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_conformance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KernelConformanceService', () {
    test('passes when all seven kernels are authoritative and healthy',
        () async {
      final service = DefaultKernelConformanceService(
        host: _StubHost(_authoritativeReports),
      );

      final report = await service.buildReport();

      expect(report.passed, isTrue);
      expect(report.statuses, hasLength(7));
      expect(report.violations, isEmpty);
    });

    test('fails when a kernel is transitional or missing', () async {
      final service = DefaultKernelConformanceService(
        host: _StubHost(<KernelHealthReport>[
          ..._authoritativeReports
              .where((report) => report.domain != KernelDomain.why),
          const KernelHealthReport(
            domain: KernelDomain.when,
            status: KernelHealthStatus.healthy,
            nativeBacked: true,
            headlessReady: true,
            authorityLevel: KernelAuthorityLevel.transitional,
            summary: 'when transitional',
          ),
        ]),
      );

      final report = await service.buildReport();

      expect(report.passed, isFalse);
      expect(report.violations, contains('when:authority_not_authoritative'));
      expect(report.violations, contains('why:missing_health_report'));
    });
  });
}

const List<KernelHealthReport> _authoritativeReports = <KernelHealthReport>[
  KernelHealthReport(
    domain: KernelDomain.who,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'who',
  ),
  KernelHealthReport(
    domain: KernelDomain.what,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'what',
  ),
  KernelHealthReport(
    domain: KernelDomain.when,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'when',
  ),
  KernelHealthReport(
    domain: KernelDomain.where,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'where',
  ),
  KernelHealthReport(
    domain: KernelDomain.how,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'how',
  ),
  KernelHealthReport(
    domain: KernelDomain.why,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'why',
  ),
  KernelHealthReport(
    domain: KernelDomain.vibe,
    status: KernelHealthStatus.healthy,
    nativeBacked: true,
    headlessReady: true,
    authorityLevel: KernelAuthorityLevel.authoritative,
    summary: 'vibe',
  ),
];

class _StubHost implements HeadlessAvraiOsHost {
  _StubHost(this._reports);

  final List<KernelHealthReport> _reports;

  @override
  Future<RealityKernelFusionInput> buildModelTruth({
    required KernelEventEnvelope envelope,
    required KernelWhyRequest whyRequest,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<KernelHealthReport>> healthCheck() async => _reports;

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

  @override
  Future<HeadlessAvraiOsHostState> start() async {
    return HeadlessAvraiOsHostState(
      started: true,
      startedAtUtc: DateTime.utc(2026, 3, 10, 12),
      localityContainedInWhere: true,
      summary: 'started',
    );
  }
}
