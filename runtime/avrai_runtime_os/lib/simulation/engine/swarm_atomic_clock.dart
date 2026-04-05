import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';

/// A specialized implementation of AtomicClockService for the Swarm Simulation.
///
/// Allows precise control over the forward progression of time to simulate
/// days, weeks, and seasons without waiting in real time.
class SwarmAtomicClock extends AtomicClockService {
  DateTime _simulationTime;
  final WhenKernelContract _whenKernel;
  final String _runtimeId;
  final String _temporalMode;
  final String? _branchId;
  final String? _runId;

  SwarmAtomicClock({
    required WhenKernelContract whenKernel,
    required String runtimeId,
    DateTime? startTime,
    String temporalMode = 'historical_replay',
    String? branchId,
    String? runId,
  })  : _whenKernel = whenKernel,
        _runtimeId = runtimeId,
        _temporalMode = temporalMode,
        _branchId = branchId,
        _runId = runId,
        _simulationTime = startTime ?? DateTime.utc(2026, 3, 1, 6, 0, 0);

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
    final whenTimestamp = await _whenKernel.issueTimestamp(
      WhenTimestampRequest(
        referenceId:
            'swarm:${_runtimeId}_${_simulationTime.microsecondsSinceEpoch}',
        occurredAtUtc: _simulationTime.toUtc(),
        runtimeId: _runtimeId,
        context: <String, dynamic>{
          'temporal_mode': _temporalMode,
          'source': 'swarm_atomic_clock',
          if (_branchId != null) 'branch_id': _branchId,
          if (_runId != null) 'run_id': _runId,
        },
      ),
    );

    final observedAt = whenTimestamp.observedAtUtc.toUtc();
    return AtomicTimestamp.now(
      precision: TimePrecision.millisecond,
      serverTime: observedAt,
      localTime: observedAt,
      timezoneId: 'UTC',
      offset: Duration.zero,
      isSynchronized: true,
    );
  }
}
