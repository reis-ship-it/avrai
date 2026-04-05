import 'dart:async';

import 'package:avrai_core/models/temporal/temporal_instant.dart';
import 'package:avrai_core/models/temporal/temporal_provenance.dart';
import 'package:avrai_core/models/temporal/temporal_uncertainty.dart';

abstract class ClockSource {
  Future<TemporalInstant> now();
}

class SystemClockSource implements ClockSource {
  SystemClockSource({
    Stopwatch? monotonicStopwatch,
    this.timezoneId = 'UTC',
  }) : _monotonicStopwatch = monotonicStopwatch ?? (Stopwatch()..start());

  final Stopwatch _monotonicStopwatch;
  final String timezoneId;

  @override
  Future<TemporalInstant> now() async {
    final now = DateTime.now();
    return TemporalInstant(
      referenceTime: now.toUtc(),
      civilTime: now.toLocal(),
      timezoneId: timezoneId,
      provenance: const TemporalProvenance(
        authority: TemporalAuthority.device,
        source: 'system_clock',
      ),
      uncertainty: const TemporalUncertainty.zero(),
      monotonicTicks: _monotonicStopwatch.elapsedMicroseconds,
    );
  }
}

class FixedClockSource implements ClockSource {
  FixedClockSource(this._instant);

  TemporalInstant _instant;

  @override
  Future<TemporalInstant> now() async => _instant;

  void setInstant(TemporalInstant instant) {
    _instant = instant;
  }
}
