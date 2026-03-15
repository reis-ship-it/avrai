import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';

class KernelNativeAuthorityStatus {
  const KernelNativeAuthorityStatus({
    required this.domain,
    required this.nativeBacked,
    required this.nativeRequired,
    required this.headlessReady,
    required this.status,
    required this.authorityLevel,
    required this.summary,
    required this.passed,
    this.violations = const <String>[],
    this.diagnostics = const <String, dynamic>{},
  });

  final KernelDomain domain;
  final bool nativeBacked;
  final bool nativeRequired;
  final bool headlessReady;
  final KernelHealthStatus status;
  final KernelAuthorityLevel authorityLevel;
  final String summary;
  final bool passed;
  final List<String> violations;
  final Map<String, dynamic> diagnostics;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'domain': domain.name,
        'native_backed': nativeBacked,
        'native_required': nativeRequired,
        'headless_ready': headlessReady,
        'status': status.name,
        'authority_level': authorityLevel.name,
        'summary': summary,
        'passed': passed,
        'violations': violations,
        'diagnostics': diagnostics,
      };
}

class KernelConformanceReport {
  const KernelConformanceReport({
    required this.checkedAtUtc,
    required this.passed,
    required this.statuses,
    required this.violations,
  });

  final DateTime checkedAtUtc;
  final bool passed;
  final List<KernelNativeAuthorityStatus> statuses;
  final List<String> violations;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checked_at_utc': checkedAtUtc.toUtc().toIso8601String(),
        'passed': passed,
        'statuses': statuses.map((status) => status.toJson()).toList(),
        'violations': violations,
      };
}

abstract class KernelConformanceService {
  Future<KernelConformanceReport> buildReport({bool startIfNeeded = true});
}

class DefaultKernelConformanceService implements KernelConformanceService {
  const DefaultKernelConformanceService({
    required HeadlessAvraiOsHost host,
  }) : _host = host;

  final HeadlessAvraiOsHost _host;

  @override
  Future<KernelConformanceReport> buildReport({
    bool startIfNeeded = true,
  }) async {
    if (startIfNeeded) {
      await _host.start();
    }
    final reports = await _host.healthCheck();
    final statuses = reports.map(_statusFromReport).toList();
    final violations = <String>[
      ...statuses.expand((status) => status.violations),
      ..._missingDomainViolations(statuses),
    ];
    return KernelConformanceReport(
      checkedAtUtc: DateTime.now().toUtc(),
      passed: violations.isEmpty,
      statuses: statuses,
      violations: violations,
    );
  }

  KernelNativeAuthorityStatus _statusFromReport(KernelHealthReport report) {
    final violations = <String>[
      if (report.status != KernelHealthStatus.healthy)
        '${report.domain.name}:status:${report.status.name}',
      if (!report.nativeBacked) '${report.domain.name}:native_backing_missing',
      if (!report.headlessReady) '${report.domain.name}:headless_not_ready',
      if (report.authorityLevel != KernelAuthorityLevel.authoritative)
        '${report.domain.name}:authority_not_authoritative',
    ];
    return KernelNativeAuthorityStatus(
      domain: report.domain,
      nativeBacked: report.nativeBacked,
      nativeRequired: true,
      headlessReady: report.headlessReady,
      status: report.status,
      authorityLevel: report.authorityLevel,
      summary: report.summary,
      passed: violations.isEmpty,
      violations: violations,
      diagnostics: report.diagnostics,
    );
  }

  Iterable<String> _missingDomainViolations(
    List<KernelNativeAuthorityStatus> statuses,
  ) sync* {
    final presentDomains = statuses.map((status) => status.domain).toSet();
    for (final domain in KernelDomain.values) {
      if (!presentDomains.contains(domain)) {
        yield '${domain.name}:missing_health_report';
      }
    }
  }
}
