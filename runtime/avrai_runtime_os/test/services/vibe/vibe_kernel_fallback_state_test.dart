import 'package:avrai_core/avra_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

void main() {
  group('VibeKernel fallback state', () {
    late TrajectoryKernel trajectoryKernel;

    setUp(() {
      VibeKernel.resetFallbackStateForTesting();
      TrajectoryKernel.resetFallbackStateForTesting();
      trajectoryKernel = TrajectoryKernel(
        nativeBridge: _UnavailableTrajectoryKernelBridge(),
        allowFallback: true,
      );
      trajectoryKernel.importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );
    });

    test('reset remains a safe compatibility no-op beside trajectory fallback',
        () {
      final subjectRef = VibeSubjectRef.personal('agent-reset-test');
      final record = TrajectoryMutationRecord(
        recordId: 'record-1',
        subjectRef: subjectRef,
        category: 'behavior_observation',
        occurredAtUtc: DateTime.utc(2026, 3, 15, 12),
        snapshotUpdatedAtUtc: DateTime.utc(2026, 3, 15, 12),
      );
      final snapshot = VibeStateSnapshot.fromJson(<String, dynamic>{
        'subject_id': subjectRef.subjectId,
        'subject_kind': subjectRef.kind.toWireValue(),
        'updated_at_utc': DateTime.utc(2026, 3, 15, 12).toIso8601String(),
      });

      trajectoryKernel.appendMutation(
        record: record,
        checkpointSnapshot: snapshot,
      );

      VibeKernel.resetFallbackStateForTesting();

      final replayed = trajectoryKernel.replaySubject(subjectRef: subjectRef);
      expect(replayed, hasLength(1));
      expect(replayed.single.recordId, record.recordId);
    });

    test('trajectory reset isolates fallback state across instances', () {
      final subjectRef = VibeSubjectRef.personal('agent-isolation-test');
      final record = TrajectoryMutationRecord(
        recordId: 'record-reset',
        subjectRef: subjectRef,
        category: 'behavior_observation',
        occurredAtUtc: DateTime.utc(2026, 3, 15, 13),
        snapshotUpdatedAtUtc: DateTime.utc(2026, 3, 15, 13),
      );
      final snapshot = VibeStateSnapshot.fromJson(<String, dynamic>{
        'subject_id': subjectRef.subjectId,
        'subject_kind': subjectRef.kind.toWireValue(),
        'updated_at_utc': DateTime.utc(2026, 3, 15, 13).toIso8601String(),
      });

      trajectoryKernel.appendMutation(
        record: record,
        checkpointSnapshot: snapshot,
      );

      final seededKernel = TrajectoryKernel(
        nativeBridge: _UnavailableTrajectoryKernelBridge(),
        allowFallback: true,
      );
      expect(seededKernel.replaySubject(subjectRef: subjectRef), hasLength(1));

      TrajectoryKernel.resetFallbackStateForTesting();

      final clearedKernel = TrajectoryKernel(
        nativeBridge: _UnavailableTrajectoryKernelBridge(),
        allowFallback: true,
      );
      expect(clearedKernel.replaySubject(subjectRef: subjectRef), isEmpty);
      expect(clearedKernel.hydrateVibeSnapshot(subjectRef: subjectRef), isNull);
      expect(clearedKernel.diagnostics()['mutation_count'], 0);
      expect(clearedKernel.diagnostics()['checkpoint_count'], 0);
    });
  });
}

class _UnavailableTrajectoryKernelBridge
    extends TrajectoryKernelJsonNativeBridge {
  @override
  bool get isAvailable => false;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError(
      'Fallback tests should not invoke native trajectory.',
    );
  }
}
