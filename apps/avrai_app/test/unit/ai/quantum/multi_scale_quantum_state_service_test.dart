/// avrai MultiScaleQuantumStateService Service Tests
/// Date: January 27, 2026
/// Purpose: Test MultiScaleQuantumStateService functionality
///
/// Test Coverage:
/// - Core Methods: generateMultiScaleStates, combineScales, getStateForContext
/// - Error Handling: Invalid inputs, edge cases
///
/// Dependencies:
/// - AtomicClockService (mocked)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:avrai_runtime_os/ai/quantum/multi_scale_quantum_state_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/models/multi_scale_quantum_state.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/utils/vibe_constants.dart';

class MockAtomicClockService extends Mock implements AtomicClockService {}

/// Builds a valid PersonalityProfile for tests. Uses avrai 12 dimensions.
/// [dimensions] overrides default; [dimensionConfidence] defaults to 0.8 for each key in dimensions.
PersonalityProfile _testProfile({
  String agentId = 'test-agent-123',
  Map<String, double>? dimensions,
  Map<String, double>? dimensionConfidence,
}) {
  final dims = dimensions ??
      {
        for (final d in VibeConstants.coreDimensions) d: 0.5,
      };
  final conf = dimensionConfidence ??
      {
        for (final d in dims.keys) d: 0.8,
      };
  final now = DateTime.now();
  return PersonalityProfile(
    agentId: agentId,
    dimensions: dims,
    dimensionConfidence: conf,
    archetype: 'balanced',
    authenticity: 0.6,
    createdAt: now,
    lastUpdated: now,
    evolutionGeneration: 1,
    learningHistory: {
      'total_interactions': 0,
      'successful_ai2ai_connections': 0,
      'learning_sources': <String>[],
      'evolution_milestones': <DateTime>[],
    },
  );
}

void main() {
  group('MultiScaleQuantumStateService', () {
    late MultiScaleQuantumStateService service;
    late MockAtomicClockService mockAtomicClock;

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      service = MultiScaleQuantumStateService(
        atomicClock: mockAtomicClock,
      );

      // Setup atomic clock mock
      when(() => mockAtomicClock.getAtomicTimestamp()).thenAnswer(
        (_) async => AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: DateTime.now(),
          localTime: DateTime.now().toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: true,
        ),
      );
    });

    group('generateMultiScaleStates', () {
      test(
          'should generate multi-scale states with short-term, long-term, and contextual states',
          () async {
        // Arrange
        final profile = _testProfile();

        // Act
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );

        // Assert - Should generate all scale types
        expect(multiScaleState.entityId, equals(profile.agentId));
        expect(multiScaleState.shortTerm!.personalityState, isNotEmpty);
        expect(multiScaleState.longTerm!.personalityState, isNotEmpty);
        expect(multiScaleState.contextual, isNotEmpty);
        expect(multiScaleState.contextual.containsKey(ContextualScale.general),
            isTrue);
      });

      test('should generate contextual states when contextual data provided',
          () async {
        // Arrange
        final profile = _testProfile();
        final workDims = {
          for (final d in VibeConstants.coreDimensions) d: 0.5,
          'curation_tendency': 0.8,
          'trust_network_reliance': 0.8,
        };
        final socialDims = {
          for (final d in VibeConstants.coreDimensions) d: 0.5,
          'community_orientation': 0.9,
          'energy_preference': 0.9,
        };
        final contextualData = {
          ContextualScale.work: _testProfile(
            agentId: profile.agentId,
            dimensions: workDims,
          ),
          ContextualScale.social: _testProfile(
            agentId: profile.agentId,
            dimensions: socialDims,
          ),
        };

        // Act
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
          contextualData: contextualData,
        );

        // Assert - Should include all contextual scales
        expect(multiScaleState.contextual.containsKey(ContextualScale.work),
            isTrue);
        expect(multiScaleState.contextual.containsKey(ContextualScale.social),
            isTrue);
        expect(multiScaleState.contextual.containsKey(ContextualScale.general),
            isTrue);
      });

      test('should use historical data for long-term state when provided',
          () async {
        // Arrange
        final profile = _testProfile();
        final historicalDims = {
          for (final d in VibeConstants.coreDimensions) d: 0.5,
          'exploration_eagerness': 0.4,
          'community_orientation': 0.5,
        };
        final historicalData = [
          _testProfile(
            agentId: profile.agentId,
            dimensions: historicalDims,
          ),
        ];

        // Act
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
          historicalData: historicalData,
        );

        // Assert - Should generate long-term and short-term from historical data
        expect(multiScaleState.longTerm!.personalityState, isNotEmpty);
        expect(multiScaleState.shortTerm!.personalityState, isNotEmpty);
      });
    });

    group('combineScales', () {
      test('should combine scales using weighted superposition', () async {
        // Arrange
        final profile = _testProfile();
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );
        final weights = ScaleWeights(
          shortTermWeight: 0.3,
          longTermWeight: 0.5,
          contextualWeight: 0.2,
        );

        // Act
        final combined = await service.combineScales(
          multiScaleState: multiScaleState,
          weights: weights,
        );

        // Assert - Should return combined quantum state (12 avrai dimensions)
        expect(combined.personalityState, isNotEmpty);
        expect(combined.personalityState.length,
            equals(VibeConstants.coreDimensions.length));
        for (final value in combined.personalityState.values) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        }
      });

      test('should use specific context when provided', () async {
        // Arrange
        final profile = _testProfile();
        final contextualData = {
          ContextualScale.work: _testProfile(
            agentId: profile.agentId,
            dimensions: profile.dimensions,
          ),
        };
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
          contextualData: contextualData,
        );
        final weights = ScaleWeights(
          shortTermWeight: 0.3,
          longTermWeight: 0.5,
          contextualWeight: 0.2,
        );

        // Act
        final combined = await service.combineScales(
          multiScaleState: multiScaleState,
          weights: weights,
          context: ContextualScale.work,
        );

        // Assert - Should use work context
        expect(combined.personalityState, isNotEmpty);
        expect(combined.personalityState.length,
            equals(VibeConstants.coreDimensions.length));
      });
    });

    group('getStateForContext', () {
      test(
          'model getStateForContext returns general context from multi-scale state',
          () async {
        // Arrange
        final profile = _testProfile();
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );

        // Act - Model's getStateForContext (service always adds general)
        final generalState =
            multiScaleState.getStateForContext(ContextualScale.general);

        // Assert - general context exists and has personality state
        expect(generalState!.personalityState, isNotEmpty);
      });

      test(
          'service getStateForContext returns contextual state when no weights',
          () async {
        // Arrange
        final profile = _testProfile();
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );

        // Act - Service API: no weights → returns contextual state directly
        final state = await service.getStateForContext(
          multiScaleState: multiScaleState,
          context: ContextualScale.general,
        );

        // Assert
        expect(state.personalityState, isNotEmpty);
        expect(state.entityId, equals(profile.agentId));
      });

      test('service getStateForContext combines scales when weights provided',
          () async {
        // Arrange
        final profile = _testProfile();
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );
        final weights = ScaleWeights(
          shortTermWeight: 0.3,
          longTermWeight: 0.5,
          contextualWeight: 0.2,
        );

        // Act - Service API: weights → delegates to combineScales
        final state = await service.getStateForContext(
          multiScaleState: multiScaleState,
          context: ContextualScale.general,
          weights: weights,
        );

        // Assert
        expect(state.personalityState, isNotEmpty);
        expect(state.personalityState.length,
            equals(VibeConstants.coreDimensions.length));
      });
    });

    group('Error Handling', () {
      test('should handle profile with incomplete dimensions', () async {
        // Arrange - only 2 avrai dimensions; service uses whatever dimensions exist
        final partialDims = {
          VibeConstants.coreDimensions[0]: 0.5,
          VibeConstants.coreDimensions[1]: 0.6,
        };
        final profile = _testProfile(dimensions: partialDims);

        // Act
        final multiScaleState = await service.generateMultiScaleStates(
          profile: profile,
        );

        // Assert - Should handle incomplete dimensions gracefully
        expect(multiScaleState.shortTerm!.personalityState, isNotEmpty);
        expect(multiScaleState.longTerm!.personalityState, isNotEmpty);
      });
    });
  });
}
