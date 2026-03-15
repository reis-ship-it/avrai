import 'functional_kernel_models.dart';
import 'kernel_root_cause_index.dart';
import 'kernel_telemetry_service.dart';

class KernelAdminSummary {
  const KernelAdminSummary({
    required this.telemetry,
    required this.latestEntries,
  });

  final KernelTelemetrySnapshot telemetry;
  final List<RootCauseIndexEntry> latestEntries;
}

abstract class KernelAdminService {
  KernelAdminSummary summarize({int limit = 20});
  List<RootCauseIndexEntry> listByRootCauseType(
    WhyRootCauseType rootCauseType, {
    int limit = 20,
  });
}

class DefaultKernelAdminService implements KernelAdminService {
  const DefaultKernelAdminService({
    required KernelTelemetryService telemetryService,
    required KernelRootCauseIndex rootCauseIndex,
  })  : _telemetryService = telemetryService,
        _rootCauseIndex = rootCauseIndex;

  final KernelTelemetryService _telemetryService;
  final KernelRootCauseIndex _rootCauseIndex;

  @override
  KernelAdminSummary summarize({int limit = 20}) {
    return KernelAdminSummary(
      telemetry: _telemetryService.snapshot(),
      latestEntries: _rootCauseIndex.listAll(limit: limit),
    );
  }

  @override
  List<RootCauseIndexEntry> listByRootCauseType(
    WhyRootCauseType rootCauseType, {
    int limit = 20,
  }) {
    return _rootCauseIndex.listByRootCauseType(
      rootCauseType,
      limit: limit,
    );
  }
}
