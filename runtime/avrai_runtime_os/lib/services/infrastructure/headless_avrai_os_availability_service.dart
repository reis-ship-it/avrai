import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';

class HeadlessAvraiOsAvailabilitySnapshot {
  const HeadlessAvraiOsAvailabilitySnapshot({
    required this.available,
    required this.liveReady,
    required this.restoredReady,
    required this.localityContainedInWhere,
    required this.kernelCount,
    required this.summary,
    this.startedAtUtc,
  });

  final bool available;
  final bool liveReady;
  final bool restoredReady;
  final bool localityContainedInWhere;
  final int kernelCount;
  final String summary;
  final DateTime? startedAtUtc;

  bool get isRestoredOnly => restoredReady && !liveReady;
}

class HeadlessAvraiOsAvailabilityService {
  const HeadlessAvraiOsAvailabilityService({
    required HeadlessAvraiOsBootstrapService bootstrapService,
  }) : _bootstrapService = bootstrapService;

  final HeadlessAvraiOsBootstrapService _bootstrapService;

  Future<HeadlessAvraiOsAvailabilitySnapshot> currentAvailability({
    bool restoreIfNeeded = true,
  }) async {
    if (restoreIfNeeded && _bootstrapService.snapshot == null) {
      await _bootstrapService.restorePersistedSnapshot();
    }
    return _snapshotFromBootstrap();
  }

  Stream<HeadlessAvraiOsAvailabilitySnapshot> watchAvailability({
    bool restoreIfNeeded = true,
  }) async* {
    yield await currentAvailability(restoreIfNeeded: restoreIfNeeded);
    yield* _bootstrapService.snapshotStream
        .map((_) => _snapshotFromBootstrap());
  }

  HeadlessAvraiOsAvailabilitySnapshot _snapshotFromBootstrap() {
    final snapshot = _bootstrapService.snapshot;
    final liveSnapshot = _bootstrapService.liveSnapshot;
    final restoredSnapshot = _bootstrapService.restoredSnapshot;
    if (snapshot == null) {
      return const HeadlessAvraiOsAvailabilitySnapshot(
        available: false,
        liveReady: false,
        restoredReady: false,
        localityContainedInWhere: false,
        kernelCount: 0,
        summary: 'Headless AVRAI OS not ready yet',
      );
    }

    return HeadlessAvraiOsAvailabilitySnapshot(
      available: true,
      liveReady: liveSnapshot != null,
      restoredReady: restoredSnapshot != null,
      localityContainedInWhere: snapshot.state.localityContainedInWhere,
      kernelCount: snapshot.healthReports.length,
      summary: liveSnapshot != null
          ? 'Headless AVRAI OS live'
          : restoredSnapshot != null
              ? 'Headless AVRAI OS restored'
              : 'Headless AVRAI OS ready',
      startedAtUtc: snapshot.startedAtUtc,
    );
  }
}
