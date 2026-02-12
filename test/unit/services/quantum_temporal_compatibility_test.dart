import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';

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
      
      // Generate 100 pairs
      for (int i = 0; i < 100; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        await Future.delayed(const Duration(milliseconds: 10));
        final t2 = await clockService.getAtomicTimestamp();
        
        pairs.add([
          QuantumTemporalStateGenerator.generate(t1),
          QuantumTemporalStateGenerator.generate(t2),
        ]);
      }
      
      // Verify all compatibilities are in [0, 1] (allow small floating point errors)
      int validRangeCount = 0;
      for (final pair in pairs) {
        final compatibility = QuantumTemporalStateGenerator
            .calculateTemporalCompatibility(pair[0], pair[1]);
        
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0001)); // Allow small floating point errors
        
        if (compatibility >= 0.0 && compatibility <= 1.0001) {
          validRangeCount++;
        }
      }
      
      // 100% range validation
      expect(validRangeCount, equals(100));
    });

    test('should have perfect compatibility for identical states', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state1 = QuantumTemporalStateGenerator.generate(timestamp);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp);
      
      final compatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(state1, state2);
      
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
      
      final compatibility = QuantumTemporalStateGenerator
          .calculateTemporalCompatibility(state1, state2);
      
      // Should be lower than identical states
      expect(compatibility, lessThan(0.9));
      expect(compatibility, greaterThanOrEqualTo(0.0));
    });

    test('should verify range for 500 pairs', () async {
      int validCount = 0;
      
      for (int i = 0; i < 500; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        await Future.delayed(const Duration(microseconds: 100));
        final t2 = await clockService.getAtomicTimestamp();
        
        final state1 = QuantumTemporalStateGenerator.generate(t1);
        final state2 = QuantumTemporalStateGenerator.generate(t2);
        
        final compatibility = QuantumTemporalStateGenerator
            .calculateTemporalCompatibility(state1, state2);
        
        // Allow small floating point errors
        if (compatibility >= 0.0 && compatibility <= 1.0001) {
          validCount++;
        }
      }
      
      // 100% range validation
      expect(validCount, equals(500));
    });

    test('should verify perfect match accuracy', () async {
      int perfectMatchCount = 0;
      int totalMatches = 0;
      
      for (int i = 0; i < 50; i++) {
        final timestamp = await clockService.getAtomicTimestamp();
        final state1 = QuantumTemporalStateGenerator.generate(timestamp);
        final state2 = QuantumTemporalStateGenerator.generate(timestamp);
        
        final compatibility = QuantumTemporalStateGenerator
            .calculateTemporalCompatibility(state1, state2);
        
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
      
      for (int i = 0; i < 100; i++) {
        final t1 = await clockService.getAtomicTimestamp();
        await Future.delayed(const Duration(milliseconds: 50));
        final t2 = await clockService.getAtomicTimestamp();
        
        final state1 = QuantumTemporalStateGenerator.generate(t1);
        final state2 = QuantumTemporalStateGenerator.generate(t2);
        
        final compatibility = QuantumTemporalStateGenerator
            .calculateTemporalCompatibility(state1, state2);
        
        compatibilities.add(compatibility);
      }
      
      // Should have values in (0, 1) range (partial matches)
      final partialMatches = compatibilities
          .where((c) => c > 0.0 && c < 1.0)
          .length;
      
      expect(partialMatches, greaterThan(0));
    });
  });
}

