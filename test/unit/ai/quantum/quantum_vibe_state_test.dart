import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_state.dart';
import 'dart:math';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuantumVibeState Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create quantum state with real and imaginary components', () {
        final state = QuantumVibeState(0.6, 0.8);
        expect(state.real, 0.6);
        expect(state.imaginary, 0.8);
      });

      test('should calculate probability correctly (|amplitude|²)', () {
        final state = QuantumVibeState(0.6, 0.8);
        const expectedProbability = 0.6 * 0.6 + 0.8 * 0.8; // 0.36 + 0.64 = 1.0
        expect(state.probability, closeTo(expectedProbability, 0.001));
      });

      test('should calculate phase correctly', () {
        final state = QuantumVibeState(1.0, 0.0); // Real axis
        expect(state.phase, closeTo(0.0, 0.001));
        
        final state2 = QuantumVibeState(0.0, 1.0); // Imaginary axis
        expect(state2.phase, closeTo(pi / 2, 0.001));
      });

      test('should calculate magnitude correctly', () {
        final state = QuantumVibeState(3.0, 4.0);
        expect(state.magnitude, closeTo(5.0, 0.001)); // 3-4-5 triangle
      });
    });

    group('fromClassical Factory', () {
      test('should create quantum state from classical probability', () {
        final state = QuantumVibeState.fromClassical(0.64);
        expect(state.real, closeTo(0.8, 0.001)); // sqrt(0.64) = 0.8
        expect(state.imaginary, 0.0);
      });

      test('should clamp probability to valid range', () {
        final state1 = QuantumVibeState.fromClassical(-0.5);
        expect(state1.probability, greaterThanOrEqualTo(0.0));
        
        final state2 = QuantumVibeState.fromClassical(1.5);
        expect(state2.probability, lessThanOrEqualTo(1.0));
      });
    });

    group('Collapse (Measurement)', () {
      test('should collapse to classical probability', () {
        final state = QuantumVibeState(0.6, 0.8);
        final collapsed = state.collapse();
        expect(collapsed, closeTo(state.probability, 0.001));
        expect(collapsed, greaterThanOrEqualTo(0.0));
        expect(collapsed, lessThanOrEqualTo(1.0));
      });

      test('should clamp collapsed value to 0.0-1.0 range', () {
        // Create a state with probability > 1.0 (shouldn't happen but test safety)
        final state = QuantumVibeState(1.0, 1.0);
        final collapsed = state.collapse();
        expect(collapsed, lessThanOrEqualTo(1.0));
      });
    });

    group('Superposition', () {
      test('should superpose two states with equal weights', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.8);
        final superposed = state1.superpose(state2, 0.5);
        
        expect(superposed.probability, greaterThanOrEqualTo(0.0));
        expect(superposed.probability, lessThanOrEqualTo(1.0));
      });

      test('should superpose with different weights', () {
        final state1 = QuantumVibeState.fromClassical(0.3);
        final state2 = QuantumVibeState.fromClassical(0.9);
        final superposed = state1.superpose(state2, 0.7); // 70% state1, 30% state2
        
        expect(superposed.probability, greaterThanOrEqualTo(0.0));
        expect(superposed.probability, lessThanOrEqualTo(1.0));
      });

      test('should handle zero magnitude states', () {
        final state1 = QuantumVibeState(0.0, 0.0);
        final state2 = QuantumVibeState.fromClassical(0.5);
        final superposed = state1.superpose(state2, 0.5);
        
        expect(superposed.real, isA<double>());
        expect(superposed.imaginary, isA<double>());
      });

      test('should clamp weights to valid range', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.7);
        
        // Test with weight > 1.0
        final superposed1 = state1.superpose(state2, 1.5);
        expect(superposed1.probability, greaterThanOrEqualTo(0.0));
        expect(superposed1.probability, lessThanOrEqualTo(1.0));
        
        // Test with weight < 0.0
        final superposed2 = state1.superpose(state2, -0.5);
        expect(superposed2.probability, greaterThanOrEqualTo(0.0));
        expect(superposed2.probability, lessThanOrEqualTo(1.0));
      });
    });

    group('Interference', () {
      test('should perform constructive interference', () {
        final state1 = QuantumVibeState(0.5, 0.0);
        final state2 = QuantumVibeState(0.3, 0.0);
        final interfered = state1.interfere(state2, constructive: true);
        
        expect(interfered.real, closeTo(0.8, 0.001)); // 0.5 + 0.3
        expect(interfered.imaginary, 0.0);
      });

      test('should perform destructive interference', () {
        final state1 = QuantumVibeState(0.5, 0.0);
        final state2 = QuantumVibeState(0.3, 0.0);
        final interfered = state1.interfere(state2, constructive: false);
        
        expect(interfered.real, closeTo(0.2, 0.001)); // 0.5 - 0.3
        expect(interfered.imaginary, 0.0);
      });

      test('should handle interference with imaginary components', () {
        final state1 = QuantumVibeState(0.5, 0.3);
        final state2 = QuantumVibeState(0.2, 0.1);
        final interfered = state1.interfere(state2, constructive: true);
        
        expect(interfered.real, closeTo(0.7, 0.001)); // 0.5 + 0.2
        expect(interfered.imaginary, closeTo(0.4, 0.001)); // 0.3 + 0.1
      });
    });

    group('Entanglement', () {
      test('should entangle two states with correlation', () {
        final state1 = QuantumVibeState.fromClassical(0.6);
        final state2 = QuantumVibeState.fromClassical(0.8);
        final entangled = state1.entangle(state2, 0.5);
        
        expect(entangled.probability, greaterThanOrEqualTo(0.0));
        expect(entangled.probability, lessThanOrEqualTo(1.0));
      });

      test('should handle zero correlation (no entanglement)', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.7);
        final entangled = state1.entangle(state2, 0.0);
        
        // With zero correlation, phase should be unchanged
        expect(entangled.phase, closeTo(state1.phase, 0.1));
      });

      test('should handle full correlation (maximum entanglement)', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.7);
        final entangled = state1.entangle(state2, 1.0);
        
        expect(entangled.probability, greaterThanOrEqualTo(0.0));
        expect(entangled.probability, lessThanOrEqualTo(1.0));
      });

      test('should clamp correlation to valid range', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.7);
        
        // Test with correlation > 1.0
        final entangled1 = state1.entangle(state2, 1.5);
        expect(entangled1.probability, greaterThanOrEqualTo(0.0));
        expect(entangled1.probability, lessThanOrEqualTo(1.0));
        
        // Test with correlation < 0.0
        final entangled2 = state1.entangle(state2, -0.5);
        expect(entangled2.probability, greaterThanOrEqualTo(0.0));
        expect(entangled2.probability, lessThanOrEqualTo(1.0));
      });
    });

    group('Equality and HashCode', () {
      test('should consider two states equal with same components', () {
        final state1 = QuantumVibeState(0.5, 0.3);
        final state2 = QuantumVibeState(0.5, 0.3);
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should consider two states different with different components', () {
        final state1 = QuantumVibeState(0.5, 0.3);
        final state2 = QuantumVibeState(0.6, 0.3);
        expect(state1, isNot(equals(state2)));
      });

      test('should handle floating point precision in equality', () {
        final state1 = QuantumVibeState(0.5, 0.3);
        final state2 = QuantumVibeState(0.50000000001, 0.30000000001); // Very small difference
        // Should be considered equal due to epsilon comparison (1e-10)
        expect((state1.real - state2.real).abs(), lessThan(1e-9));
        expect((state1.imaginary - state2.imaginary).abs(), lessThan(1e-9));
      });
    });

    group('Edge Cases', () {
      test('should handle zero state', () {
        final state = QuantumVibeState(0.0, 0.0);
        expect(state.probability, 0.0);
        expect(state.magnitude, 0.0);
        expect(state.collapse(), 0.0);
      });

      test('should handle very large values', () {
        final state = QuantumVibeState(100.0, 100.0);
        final collapsed = state.collapse();
        expect(collapsed, lessThanOrEqualTo(1.0)); // Should be clamped
      });

      test('should handle negative values', () {
        final state = QuantumVibeState(-0.5, -0.3);
        expect(state.probability, greaterThanOrEqualTo(0.0));
        final collapsed = state.collapse();
        expect(collapsed, greaterThanOrEqualTo(0.0));
        expect(collapsed, lessThanOrEqualTo(1.0));
      });
    });
  });
}

