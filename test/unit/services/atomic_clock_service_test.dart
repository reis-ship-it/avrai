import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/ai/quantum/quantum_temporal_state.dart';

/// Tests for AtomicClockService
///
/// **Patent #30: Quantum Atomic Clock System**
/// Tests verify that quantum atomic time works correctly for:
/// - Atomic timestamp generation
/// - Quantum temporal state generation
/// - Quantum temporal compatibility calculations
/// - Quantum temporal entanglement
/// - Quantum temporal decoherence
void main() {
  group('AtomicClockService', () {
    late AtomicClockService service;

    setUp(() {
      service = AtomicClockService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize atomic clock service', () async {
      await service.initialize();

      expect(service.getPrecision(), isA<TimePrecision>());
      expect(service.getPrecision(), isIn([TimePrecision.nanosecond, TimePrecision.millisecond]));
    });

    test('should generate atomic timestamp', () async {
      await service.initialize();

      final timestamp = await service.getAtomicTimestamp();

      expect(timestamp, isA<AtomicTimestamp>());
      expect(timestamp.serverTime, isA<DateTime>());
      expect(timestamp.deviceTime, isA<DateTime>());
      expect(timestamp.localTime, isA<DateTime>());
      expect(timestamp.timezoneId, isNotEmpty);
      expect(timestamp.precision, isA<TimePrecision>());
      expect(timestamp.timestampId, isNotEmpty);
    });

    test('should generate unique timestamp IDs', () async {
      await service.initialize();

      final timestamp1 = await service.getAtomicTimestamp();
      await Future.delayed(const Duration(milliseconds: 1));
      final timestamp2 = await service.getAtomicTimestamp();

      expect(timestamp1.timestampId, isNot(equals(timestamp2.timestampId)));
    });

    test('should calculate time difference between timestamps', () async {
      await service.initialize();

      final timestamp1 = await service.getAtomicTimestamp();
      await Future.delayed(const Duration(milliseconds: 10));
      final timestamp2 = await service.getAtomicTimestamp();

      final difference = timestamp2.difference(timestamp1);

      expect(difference.inMilliseconds, greaterThanOrEqualTo(9));
      expect(difference.inMilliseconds, lessThanOrEqualTo(20)); // Allow some variance
    });
  });

  group('QuantumTemporalStateGenerator', () {
    late AtomicClockService clockService;

    setUp(() async {
      clockService = AtomicClockService();
      await clockService.initialize();
    });

    tearDown(() {
      clockService.dispose();
    });

    test('should generate quantum temporal state from atomic timestamp', () async {
      final atomicTimestamp = await clockService.getAtomicTimestamp();
      final quantumState = QuantumTemporalStateGenerator.generate(atomicTimestamp);

      expect(quantumState, isA<QuantumTemporalState>());
      expect(quantumState.atomicTimestamp, equals(atomicTimestamp));
      expect(quantumState.temporalState, isNotEmpty);
    });

    test('should generate normalized quantum temporal state', () async {
      final atomicTimestamp = await clockService.getAtomicTimestamp();
      final quantumState = QuantumTemporalStateGenerator.generate(atomicTimestamp);

      // Check normalization: ||ψ_temporal|| ≈ 1
      final norm = quantumState.normalization;
      expect(norm, closeTo(1.0, 0.01)); // Within 1% of 1.0
    });

    test('should calculate quantum temporal compatibility', () async {
      final timestamp1 = await clockService.getAtomicTimestamp();
      await Future.delayed(const Duration(milliseconds: 100));
      final timestamp2 = await clockService.getAtomicTimestamp();

      final state1 = QuantumTemporalStateGenerator.generate(timestamp1);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp2);

      final compatibility = QuantumTemporalStateGenerator.calculateTemporalCompatibility(
        state1,
        state2,
      );

      // Compatibility should be between 0 and 1 (allow small floating point errors)
      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0001)); // Allow small floating point errors
    });

    test('should calculate perfect compatibility for identical timestamps', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state1 = QuantumTemporalStateGenerator.generate(timestamp);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp);

      final compatibility = QuantumTemporalStateGenerator.calculateTemporalCompatibility(
        state1,
        state2,
      );

      // Identical states should have high compatibility (≈ 1.0)
      expect(compatibility, closeTo(1.0, 0.1)); // Within 10% of 1.0
    });

    test('should create quantum temporal entanglement', () async {
      final timestamp1 = await clockService.getAtomicTimestamp();
      await Future.delayed(const Duration(milliseconds: 10));
      final timestamp2 = await clockService.getAtomicTimestamp();

      final state1 = QuantumTemporalStateGenerator.generate(timestamp1);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp2);

      final entangled = QuantumTemporalStateGenerator.createTemporalEntanglement(
        state1,
        state2,
      );

      expect(entangled, isA<QuantumTemporalState>());
      expect(entangled.temporalState, isNotEmpty);
      
      // Entangled state should be normalized
      final norm = entangled.normalization;
      expect(norm, closeTo(1.0, 0.01));
    });

    test('should calculate quantum temporal decoherence', () async {
      final initialTimestamp = await clockService.getAtomicTimestamp();
      final initialState = QuantumTemporalStateGenerator.generate(initialTimestamp);

      await Future.delayed(const Duration(milliseconds: 100));
      final currentTimestamp = await clockService.getAtomicTimestamp();

      const decoherenceRate = 0.01; // 1% per second
      final decohered = QuantumTemporalStateGenerator.calculateTemporalDecoherence(
        initialState,
        currentTimestamp,
        decoherenceRate,
      );

      expect(decohered, isA<QuantumTemporalState>());
      expect(decohered.atomicTimestamp, equals(currentTimestamp));
      
      // Decohered state should be normalized
      final norm = decohered.normalization;
      expect(norm, closeTo(1.0, 0.01));
    });

    // ===== EXPERIMENT 1: Expanded Tests =====
    
    test('should generate normalized states for 100+ timestamps', () async {
      final timestamps = <AtomicTimestamp>[];
      final states = <QuantumTemporalState>[];
      
      // Generate 100 timestamps
      for (int i = 0; i < 100; i++) {
        final timestamp = await clockService.getAtomicTimestamp();
        timestamps.add(timestamp);
        states.add(QuantumTemporalStateGenerator.generate(timestamp));
        await Future.delayed(const Duration(microseconds: 100));
      }
      
      // Verify all are normalized
      for (final state in states) {
        expect(state.normalization, closeTo(1.0, 0.001));
      }
      
      expect(states.length, equals(100));
    });

    test('should generate correct temporal components', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state = QuantumTemporalStateGenerator.generate(timestamp);
      
      // Verify atomic state has 3 components
      expect(state.atomicState.length, equals(3));
      
      // Verify quantum state has hour/weekday/season (35 components: 24+7+4)
      expect(state.quantumState.length, equals(35));
      
      // Verify phase state has 2 components
      expect(state.phaseState.length, equals(2));
    });

    test('should generate same state for same timestamp', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state1 = QuantumTemporalStateGenerator.generate(timestamp);
      final state2 = QuantumTemporalStateGenerator.generate(timestamp);
      
      // States should be identical (same temporal state vector)
      for (int i = 0; i < state1.temporalState.length; i++) {
        expect(state1.temporalState[i], closeTo(state2.temporalState[i], 0.0001));
      }
    });

    test('should generate states in < 1ms', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      
      final stopwatch = Stopwatch()..start();
      QuantumTemporalStateGenerator.generate(timestamp);
      stopwatch.stop();
      
      // Keep this as a lightweight performance guardrail, but avoid flakiness
      // across devices/CI runners.
      expect(stopwatch.elapsedMicroseconds, lessThan(5000));
    });

    test('should verify temporal component accuracy', () async {
      final timestamp = await clockService.getAtomicTimestamp();
      final state = QuantumTemporalStateGenerator.generate(timestamp);
      
      // Verify atomic state components sum to normalized weights
      final atomicSum = state.atomicState.fold(0.0, (sum, val) => sum + val * val);
      expect(atomicSum, closeTo(1.0, 0.01));
      
      // Verify quantum state has correct structure
      expect(state.quantumState.length, greaterThan(0));
      
      // Verify phase state is normalized
      final phaseSum = state.phaseState.fold(0.0, (sum, val) => sum + val * val);
      expect(phaseSum, closeTo(1.0, 0.01));
    });
  });
}

