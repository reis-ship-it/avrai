import 'package:avrai_runtime_os/kernel/os/functional_kernel_models.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/simulation/engine/swarm_atomic_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SwarmAtomicClock', () {
    test('issues replay timestamps through the when kernel', () async {
      final whenKernel = _RecordingWhenKernel();
      final startTime = DateTime.utc(2025, 1, 1, 8);
      final clock = SwarmAtomicClock(
        whenKernel: whenKernel,
        runtimeId: 'simulation_runtime',
        temporalMode: 'historical_replay',
        branchId: 'canonical',
        runId: 'run-001',
        startTime: startTime,
      );

      final timestamp = await clock.getAtomicTimestamp();

      expect(timestamp.serverTime, startTime);
      expect(whenKernel.requests, hasLength(1));
      expect(whenKernel.requests.single.referenceId,
          'swarm:simulation_runtime_${startTime.microsecondsSinceEpoch}');
      expect(whenKernel.requests.single.occurredAtUtc, startTime);
      expect(whenKernel.requests.single.runtimeId, 'simulation_runtime');
      expect(
        whenKernel.requests.single.context,
        containsPair('temporal_mode', 'historical_replay'),
      );
      expect(whenKernel.requests.single.context, containsPair('branch_id', 'canonical'));
      expect(whenKernel.requests.single.context, containsPair('run_id', 'run-001'));
    });

    test('advancing the replay clock changes the next when request', () async {
      final whenKernel = _RecordingWhenKernel();
      final startTime = DateTime.utc(2025, 1, 1, 8);
      final clock = SwarmAtomicClock(
        whenKernel: whenKernel,
        runtimeId: 'simulation_runtime',
        startTime: startTime,
      );

      clock.tick(const Duration(minutes: 15));
      final timestamp = await clock.getAtomicTimestamp();

      expect(timestamp.serverTime, startTime.add(const Duration(minutes: 15)));
      expect(
        whenKernel.requests.single.occurredAtUtc,
        startTime.add(const Duration(minutes: 15)),
      );
    });
  });
}

class _RecordingWhenKernel extends WhenKernelFallbackSurface {
  final List<WhenTimestampRequest> requests = <WhenTimestampRequest>[];

  @override
  Future<WhenKernelSnapshot> resolveWhen(KernelEventEnvelope envelope) async {
    return WhenKernelSnapshot(
      observedAt: envelope.occurredAtUtc.toUtc(),
      effectiveAt: envelope.occurredAtUtc.toUtc(),
      expiresAt: envelope.occurredAtUtc.toUtc().add(const Duration(hours: 4)),
      freshness: 1.0,
      cadence: envelope.context['cadence'] as String?,
      recencyBucket: 'immediate',
      timingConflictFlags: const <String>[],
      temporalConfidence: 1.0,
    );
  }

  @override
  Future<WhenTimestamp> issueTimestamp(WhenTimestampRequest request) async {
    requests.add(request);
    return WhenTimestamp(
      referenceId: request.referenceId,
      observedAtUtc: request.occurredAtUtc.toUtc(),
      quantumAtomicTick: request.occurredAtUtc.toUtc().microsecondsSinceEpoch,
      confidence: 1.0,
    );
  }
}
