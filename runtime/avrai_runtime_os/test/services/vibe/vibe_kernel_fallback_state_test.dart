import 'package:avrai_core/avra_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

void main() {
  group('VibeKernel fallback state', () {
    late TrajectoryKernel trajectoryKernel;
    late VibeKernel vibeKernel;

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
      vibeKernel = VibeKernel(
        nativeBridge: _UnavailableVibeKernelBridge(),
        trajectoryKernel: trajectoryKernel,
        allowFallback: true,
      );
    });

    test('reset clears subject, entity, and envelope metadata state', () {
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-reset-test',
        dimensions: const <String, double>{
          'energy_preference': 0.21,
          'community_orientation': 0.76,
        },
      );
      vibeKernel.ingestEntityObservation(
        entityId: 'venue-1',
        entityType: 'venue',
        dimensions: const <String, double>{'energy_preference': 0.73},
      );
      vibeKernel.importSnapshotEnvelope(
        VibeSnapshotEnvelope(
          exportedAtUtc: DateTime.utc(2026, 3, 15, 12),
          subjectSnapshots: <VibeStateSnapshot>[
            vibeKernel.getUserSnapshot('agent-reset-test'),
          ],
          entitySnapshots: <EntityVibeSnapshot>[
            vibeKernel.getEntitySnapshot(
              entityId: 'venue-1',
              entityType: 'venue',
            ),
          ],
          migrationReceipts: const <String>['migration:test'],
          metadata: const <String, dynamic>{'source': 'fallback-test'},
          schemaVersion: 7,
        ),
      );

      VibeKernel.resetFallbackStateForTesting();

      final clearedEnvelope = vibeKernel.exportSnapshotEnvelope();
      expect(clearedEnvelope.subjectSnapshots, isEmpty);
      expect(clearedEnvelope.entitySnapshots, isEmpty);
      expect(clearedEnvelope.migrationReceipts, isEmpty);
      expect(clearedEnvelope.metadata, isEmpty);
      expect(clearedEnvelope.schemaVersion, 1);
    });

    test('reset isolates fallback state across kernel instances', () {
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-isolation-test',
        dimensions: const <String, double>{'energy_preference': 0.14},
      );

      final seeded = vibeKernel.getUserSnapshot('agent-isolation-test');
      expect(
        seeded.coreDna.dimensions['energy_preference'],
        closeTo(0.14, 0.0001),
      );

      VibeKernel.resetFallbackStateForTesting();

      final cleared = vibeKernel.getUserSnapshot('agent-isolation-test');
      expect(cleared.coreDna.dimensions, isEmpty);
      expect(cleared.confidence, closeTo(0.5, 0.0001));
    });
  });
}

class _UnavailableVibeKernelBridge extends VibeKernelJsonNativeBridge {
  @override
  bool get isAvailable => false;

  @override
  void initialize() {}

  @override
  Map<String, dynamic> invoke({
    required String syscall,
    required Map<String, dynamic> payload,
  }) {
    throw UnimplementedError('Fallback tests should not invoke native vibe.');
  }
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
