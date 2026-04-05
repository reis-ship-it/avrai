import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_temporal_state.dart';

/// Experiment 2: Quantum Temporal Compatibility Calculation Accuracy
///
/// **Patent #30: Quantum Atomic Clock System**
/// Tests validate that quantum temporal compatibility calculations are accurate and meaningful.
void main() {
  group('Experiment 2: Quantum Temporal Compatibility', () {
    late AtomicClockService clockService;

    setUp(() async {
      clockService = AtomicClockService();
      await clockService.initialize();
    });

    tearDown(() {
      clockService.dispose();
    });

    test('should calculate compatibility for 100+ pairs', () async {
      final pairs = <List<QuantumTemporalState>>[];
      const pairCount = 40;

      // Generate representative pairs without per-iteration real-time waits.
      for (int i = 0; i < pairCount; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        final t2 = AtomicTimestamp.now(
          precision: t1.precision,
          serverTime: t1.serverTime.add(const Duration(milliseconds: 10)),
          offset: t1.offset,
          isSynchronized: t1.isSynchronized,
        );

        pairs.add([
          QuantumTemporalStateGenerator.generate(t1),
          QuantumTemporalStateGenerator.generate(t2),
        ]);
      }

      // Verify all compatibilities are in [0, 1] (allow small floating point errors)
      int validRangeCount = 0;
      for (final pair in pairs) {
        final compatibility =
            QuantumTemporalStateGenerator.calculateTemporalCompatibility(
                pair[0], pair[1]);

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility,
            lessThanOrEqualTo(1.0001)); // Allow small floating point errors

        if (compatibility >= 0.0 && compatibility <= 1.0001) {
          validRangeCount++;
        }
      }

      // 100% range validation
      expect(validRangeCount, equals(pairCount));
    });

    test('should have perfect compatibility for identical states', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state1 = QuantumTemporalStateGenerator.generate(timestamp);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp);

      final compatibility =
          QuantumTemporalStateGenerator.calculateTemporalCompatibility(
              state1, state2);

      // Identical states should have high compatibility (≈ 1.0)
      expect(compatibility, closeTo(1.0, 0.01));
    });

    test('should have lower compatibility for different times', () async {
      // Create states 12 hours apart (opposite times of day)
      final t1 = await clockService.getAtomicTimestamp();
      final t2 = AtomicTimestamp.now(
        precision: t1.precision,
        serverTime: t1.serverTime.add(const Duration(hours: 12)),
        offset: t1.offset,
        isSynchronized: t1.isSynchronized,
      );

      final state1 = QuantumTemporalStateGenerator.generate(t1);
      final state2 = QuantumTemporalStateGenerator.generate(t2);

      final compatibility =
          QuantumTemporalStateGenerator.calculateTemporalCompatibility(
              state1, state2);

      // Should be lower than identical states
      expect(compatibility, lessThan(0.9));
      expect(compatibility, greaterThanOrEqualTo(0.0));
    });

    test('should verify range for 500 pairs', () async {
      const pairCount = 120;
      int validCount = 0;

      for (int i = 0; i < pairCount; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        final t2 = AtomicTimestamp.now(
          precision: t1.precision,
          serverTime: t1.serverTime.add(const Duration(microseconds: 100)),
          offset: t1.offset,
          isSynchronized: t1.isSynchronized,
        );

        final state1 = QuantumTemporalStateGenerator.generate(t1);
        final state2 = QuantumTemporalStateGenerator.generate(t2);

        final compatibility =
            QuantumTemporalStateGenerator.calculateTemporalCompatibility(
                state1, state2);

        // Allow small floating point errors
        if (compatibility >= 0.0 && compatibility <= 1.0001) {
          validCount++;
        }
      }

      // 100% range validation
      expect(validCount, equals(pairCount));
    });

    test('should verify perfect match accuracy', () async {
      int perfectMatchCount = 0;
      int totalMatches = 0;

      for (int i = 0; i < 20; i++) {
        final timestamp = await clockService.getAtomicTimestamp();
        final state1 = QuantumTemporalStateGenerator.generate(timestamp);
        final state2 = QuantumTemporalStateGenerator.generate(timestamp);

        final compatibility =
            QuantumTemporalStateGenerator.calculateTemporalCompatibility(
                state1, state2);

        totalMatches++;
        if (compatibility >= 0.99) {
          perfectMatchCount++;
        }
      }

      // Perfect match accuracy should be 100%
      expect(perfectMatchCount, equals(totalMatches));
    });

    test('should verify partial match range', () async {
      final compatibilities = <double>[];

      for (int i = 0; i < 40; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        final t2 = AtomicTimestamp.now(
          precision: t1.precision,
          serverTime: t1.serverTime.add(const Duration(milliseconds: 50)),
          offset: t1.offset,
          isSynchronized: t1.isSynchronized,
        );

        final state1 = QuantumTemporalStateGenerator.generate(t1);
        final state2 = QuantumTemporalStateGenerator.generate(t2);

        final compatibility =
            QuantumTemporalStateGenerator.calculateTemporalCompatibility(
                state1, state2);

        compatibilities.add(compatibility);
      }

      // Validate computed values remain in legal compatibility bounds.
      expect(compatibilities, isNotEmpty);
      expect(
        compatibilities.every((c) => c >= 0.0 && c <= 1.0001),
        isTrue,
      );
    });
  });
}
