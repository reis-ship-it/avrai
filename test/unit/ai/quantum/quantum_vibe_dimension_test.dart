import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_dimension.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_state.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuantumVibeDimension Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create dimension with all required fields', () {
        final state = QuantumVibeState.fromClassical(0.7);
        final dimension = QuantumVibeDimension(
          dimension: 'exploration_eagerness',
          state: state,
          confidence: 0.8,
        );
        
        expect(dimension.dimension, 'exploration_eagerness');
        expect(dimension.state, state);
        expect(dimension.confidence, 0.8);
      });

      test('should use default confidence when not provided', () {
        final state = QuantumVibeState.fromClassical(0.5);
        final dimension = QuantumVibeDimension(
          dimension: 'test_dimension',
          state: state,
        );
        
        expect(dimension.confidence, 0.5);
      });

      test('should throw assertion error for invalid confidence', () {
        final state = QuantumVibeState.fromClassical(0.5);
        
        expect(
          () => QuantumVibeDimension(
            dimension: 'test',
            state: state,
            confidence: 1.5, // Invalid: > 1.0
          ),
          throwsA(isA<AssertionError>()),
        );
        
        expect(
          () => QuantumVibeDimension(
            dimension: 'test',
            state: state,
            confidence: -0.5, // Invalid: < 0.0
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Measurement', () {
      test('should measure (collapse) to classical value', () {
        final state = QuantumVibeState.fromClassical(0.64);
        final dimension = QuantumVibeDimension(
          dimension: 'test_dimension',
          state: state,
        );
        
        final measured = dimension.measure();
        expect(measured, closeTo(0.64, 0.001));
        expect(measured, greaterThanOrEqualTo(0.0));
        expect(measured, lessThanOrEqualTo(1.0));
      });

      test('should get probability without collapsing', () {
        final state = QuantumVibeState.fromClassical(0.81);
        final dimension = QuantumVibeDimension(
          dimension: 'test_dimension',
          state: state,
        );
        
        final probability1 = dimension.probability;
        final probability2 = dimension.probability; // Should be same (no collapse)
        
        expect(probability1, closeTo(0.81, 0.001));
        expect(probability2, closeTo(0.81, 0.001));
        expect(probability1, equals(probability2));
      });
    });

    group('State Access', () {
      test('should access phase from state', () {
        final state = QuantumVibeState(1.0, 0.0);
        final dimension = QuantumVibeDimension(
          dimension: 'test',
          state: state,
        );
        
        expect(dimension.phase, closeTo(0.0, 0.001));
      });

      test('should access magnitude from state', () {
        final state = QuantumVibeState(3.0, 4.0);
        final dimension = QuantumVibeDimension(
          dimension: 'test',
          state: state,
        );
        
        expect(dimension.magnitude, closeTo(5.0, 0.001));
      });
    });

    group('CopyWith', () {
      test('should create copy with updated fields', () {
        final originalState = QuantumVibeState.fromClassical(0.5);
        final original = QuantumVibeDimension(
          dimension: 'original_dimension',
          state: originalState,
          confidence: 0.6,
        );
        
        final newState = QuantumVibeState.fromClassical(0.8);
        final copy = original.copyWith(
          dimension: 'new_dimension',
          state: newState,
          confidence: 0.9,
        );
        
        expect(copy.dimension, 'new_dimension');
        expect(copy.state, newState);
        expect(copy.confidence, 0.9);
      });

      test('should preserve original values when fields not provided', () {
        final originalState = QuantumVibeState.fromClassical(0.5);
        final original = QuantumVibeDimension(
          dimension: 'original_dimension',
          state: originalState,
          confidence: 0.6,
        );
        
        final newState = QuantumVibeState.fromClassical(0.8);
        final copy = original.copyWith(state: newState);
        
        expect(copy.dimension, original.dimension);
        expect(copy.state, newState);
        expect(copy.confidence, original.confidence);
      });
    });

    group('Equality and HashCode', () {
      test('should consider two dimensions equal with same values', () {
        final state1 = QuantumVibeState.fromClassical(0.5);
        final state2 = QuantumVibeState.fromClassical(0.5);
        final dimension1 = QuantumVibeDimension(
          dimension: 'test',
          state: state1,
          confidence: 0.7,
        );
        final dimension2 = QuantumVibeDimension(
          dimension: 'test',
          state: state2,
          confidence: 0.7,
        );
        
        expect(dimension1, equals(dimension2));
        expect(dimension1.hashCode, equals(dimension2.hashCode));
      });

      test('should consider two dimensions different with different dimension names', () {
        final state = QuantumVibeState.fromClassical(0.5);
        final dimension1 = QuantumVibeDimension(
          dimension: 'dimension1',
          state: state,
        );
        final dimension2 = QuantumVibeDimension(
          dimension: 'dimension2',
          state: state,
        );
        
        expect(dimension1, isNot(equals(dimension2)));
      });

      test('should consider two dimensions different with different confidence', () {
        final state = QuantumVibeState.fromClassical(0.5);
        final dimension1 = QuantumVibeDimension(
          dimension: 'test',
          state: state,
          confidence: 0.6,
        );
        final dimension2 = QuantumVibeDimension(
          dimension: 'test',
          state: state,
          confidence: 0.7,
        );
        
        expect(dimension1, isNot(equals(dimension2)));
      });
    });
  });
}

