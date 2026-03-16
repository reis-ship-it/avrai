// ignore_for_file: avoid_relative_lib_imports

import 'package:avrai_core/avra_core.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../engine/reality_engine/lib/reality_engine.dart';

class _UnavailableTrajectoryBridge extends TrajectoryKernelJsonNativeBridge {
  @override
  void initialize() {}

  @override
  bool get isAvailable => false;

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw StateError('native bridge should not be invoked in fallback test');
  }
}

void main() {
  group('TrajectoryKernel fallback', () {
    late TrajectoryKernel kernel;

    setUp(() {
      kernel = TrajectoryKernel(
        nativeBridge: _UnavailableTrajectoryBridge(),
        allowFallback: true,
      );
      kernel.importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );
    });

    test('keeps a process-local journal and checkpoints when native is absent',
        () {
      final subjectRef = VibeSubjectRef.personal('agent_fallback_test');
      final record = TrajectoryMutationRecord(
        recordId: 'record-1',
        subjectRef: subjectRef,
        category: 'behavior_observation',
        occurredAtUtc: DateTime.utc(2026, 3, 14, 12),
        snapshotUpdatedAtUtc: DateTime.utc(2026, 3, 14, 12),
      );
      final snapshot = VibeStateSnapshot.fromJson(<String, dynamic>{
        'subject_id': subjectRef.subjectId,
        'subject_kind': subjectRef.kind.toWireValue(),
        'updated_at_utc': DateTime.utc(2026, 3, 14, 12).toIso8601String(),
      });

      kernel.appendMutation(record: record, checkpointSnapshot: snapshot);

      final secondKernel = TrajectoryKernel(
        nativeBridge: _UnavailableTrajectoryBridge(),
        allowFallback: true,
      );
      final replayed = secondKernel.replaySubject(subjectRef: subjectRef);
      final exported = secondKernel.exportJournalWindow(limit: 64);
      final checkpoint =
          secondKernel.hydrateVibeSnapshot(subjectRef: subjectRef);
      final diagnostics = secondKernel.diagnostics();

      expect(replayed, hasLength(1));
      expect(replayed.single.recordId, record.recordId);
      expect(exported, hasLength(1));
      expect(checkpoint, isNotNull);
      expect(checkpoint!.sourceRecordIds, contains(record.recordId));
      expect(diagnostics['fallback_enabled'], isTrue);
      expect(diagnostics['mutation_count'], 1);
    });
  });
}
