import 'package:avrai_runtime_os/services/background/background_execution_models.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';

typedef PassiveCollectionStarter = void Function();
typedef PassiveDwellEventFlusher = List<DwellEvent> Function();
typedef PassiveDwellEventIngester = Future<void> Function(List<DwellEvent>);

class PassiveKernelSignalIntakeResult {
  const PassiveKernelSignalIntakeResult({
    required this.ingestedDwellEventCount,
  });

  final int ingestedDwellEventCount;
}

class PassiveKernelSignalIntakeLane {
  PassiveKernelSignalIntakeLane({
    required SmartPassiveCollectionService passiveCollectionService,
    required DwellEventIntakeAdapter dwellEventIntakeAdapter,
    PassiveCollectionStarter? startCollection,
    PassiveDwellEventFlusher? flushDwellEvents,
    PassiveDwellEventIngester? ingestDwellEvents,
  })  : _startCollection = startCollection ?? passiveCollectionService.start,
        _flushDwellEvents = flushDwellEvents ??
            passiveCollectionService.flushForBatchProcessing,
        _ingestDwellEvents =
            ingestDwellEvents ?? dwellEventIntakeAdapter.ingestBatch;
  final PassiveCollectionStarter _startCollection;
  final PassiveDwellEventFlusher _flushDwellEvents;
  final PassiveDwellEventIngester _ingestDwellEvents;

  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _startCollection();
  }

  Future<PassiveKernelSignalIntakeResult> handleWake({
    required BackgroundWakeReason reason,
    required BackgroundCapabilitySnapshot capabilities,
  }) async {
    if (!_started) {
      await start();
    }
    if (!_shouldFlush(reason)) {
      return const PassiveKernelSignalIntakeResult(ingestedDwellEventCount: 0);
    }
    final dwellEvents = _flushDwellEvents();
    if (dwellEvents.isEmpty) {
      return const PassiveKernelSignalIntakeResult(ingestedDwellEventCount: 0);
    }
    await _ingestDwellEvents(dwellEvents);
    return PassiveKernelSignalIntakeResult(
      ingestedDwellEventCount: dwellEvents.length,
    );
  }

  bool _shouldFlush(BackgroundWakeReason reason) {
    switch (reason) {
      case BackgroundWakeReason.bootCompleted:
      case BackgroundWakeReason.backgroundTaskWindow:
      case BackgroundWakeReason.bleEncounter:
      case BackgroundWakeReason.significantLocation:
      case BackgroundWakeReason.trustedAnnounceRefresh:
        return true;
      case BackgroundWakeReason.connectivityWifi:
      case BackgroundWakeReason.segmentRefreshWindow:
        return false;
    }
  }
}
