import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_root_cause_index.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_telemetry_service.dart';

abstract class KernelBundleStore {
  Future<void> put(KernelBundleRecord record);
  KernelBundleRecord? getByEventId(String eventId);
  List<KernelBundleRecord> listRecent({int limit = 100});
}

class InMemoryKernelBundleStore implements KernelBundleStore {
  InMemoryKernelBundleStore({
    KernelRootCauseIndex? rootCauseIndex,
    KernelTelemetryService? telemetryService,
  })  : _rootCauseIndex = rootCauseIndex,
        _telemetryService = telemetryService;

  final Map<String, KernelBundleRecord> _recordsByEventId =
      <String, KernelBundleRecord>{};
  final List<KernelBundleRecord> _records = <KernelBundleRecord>[];
  final KernelRootCauseIndex? _rootCauseIndex;
  final KernelTelemetryService? _telemetryService;

  @override
  KernelBundleRecord? getByEventId(String eventId) =>
      _recordsByEventId[eventId];

  @override
  List<KernelBundleRecord> listRecent({int limit = 100}) {
    return _records.take(limit).toList(growable: false);
  }

  @override
  Future<void> put(KernelBundleRecord record) async {
    _recordsByEventId[record.eventId] = record;
    _records.removeWhere((entry) => entry.eventId == record.eventId);
    _records.insert(0, record);
    await _rootCauseIndex?.index(record);
    await _telemetryService?.record(record);
  }
}
