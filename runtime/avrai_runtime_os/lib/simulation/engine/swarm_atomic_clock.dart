import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// A specialized implementation of AtomicClockService for the Swarm Simulation.
///
/// Allows precise control over the forward progression of time to simulate
/// days, weeks, and seasons without waiting in real time.
class SwarmAtomicClock extends AtomicClockService {
  DateTime _simulationTime;

  SwarmAtomicClock({DateTime? startTime})
      : _simulationTime = startTime ?? DateTime(2026, 3, 1, 6, 0, 0);

  /// Fast forwards the simulation time by the specified duration.
  void tick(Duration duration) {
    _simulationTime = _simulationTime.add(duration);
  }

  /// Sets the simulation to an exact specific time.
  void setTime(DateTime time) {
    _simulationTime = time;
  }

  @override
  Future<AtomicTimestamp> getAtomicTimestamp() async {
    // In the simulation, we strictly return the simulation time
    // instead of DateTime.now().
    return AtomicTimestamp.now(
      precision: TimePrecision.millisecond,
      serverTime: _simulationTime,
      localTime: _simulationTime,
      timezoneId: 'UTC', // Simulation runs in UTC baseline
      offset: Duration.zero,
      isSynchronized: true,
    );
  }
}
