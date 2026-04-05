import 'dart:async';

import 'package:avrai_core/avra_core.dart';

class AtomicClockTemporalAdapter implements ClockSource {
  AtomicClockTemporalAdapter({
    required AtomicClockService atomicClockService,
    Stopwatch? monotonicStopwatch,
  })  : _atomicClockService = atomicClockService,
        _monotonicStopwatch = monotonicStopwatch ?? (Stopwatch()..start());

  final AtomicClockService _atomicClockService;
  final Stopwatch _monotonicStopwatch;

  @override
  Future<TemporalInstant> now() async {
    final atomic = await _atomicClockService.getAtomicTimestamp();
    return TemporalInstant(
      referenceTime: atomic.serverTime.toUtc(),
      civilTime: atomic.localTime,
      timezoneId: atomic.timezoneId,
      provenance: TemporalProvenance(
        authority: atomic.isSynchronized
            ? TemporalAuthority.synchronizedServer
            : TemporalAuthority.device,
        source: 'atomic_clock_service',
      ),
      uncertainty: TemporalUncertainty(
        window: atomic.offset.abs(),
        confidence: atomic.isSynchronized ? 0.95 : 0.5,
      ),
      monotonicTicks: _monotonicStopwatch.elapsedMicroseconds,
      atomicTimestamp: atomic,
    );
  }
}
