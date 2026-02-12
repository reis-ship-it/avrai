import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QuantumVibeEngine Tests', () {
    late QuantumVibeEngine engine;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      engine = QuantumVibeEngine();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('compileVibeDimensionsQuantum', () {
      test('should compile dimensions using quantum mathematics', () async {
        // Arrange
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: ['exploration_eagerness'],
          personalityStrength: 0.7,
          evolutionMomentum: 0.3,
          authenticityLevel: 0.8,
          confidenceLevel: 0.6,
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.7,
          explorationTendency: 0.8,
          socialEngagement: 0.6,
          spontaneityIndex: 0.7,
          consistencyScore: 0.6,
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement: 0.6,
          socialPreference: 0.7,
          leadershipTendency: 0.5,
          collaborationStyle: 0.65,
          trustNetworkStrength: 0.7,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.6,
          relationshipStability: 0.7,
          influenceReceptivity: 0.6,
          givingTendency: 0.7,
          boundaryFlexibility: 0.6,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: 0.7,
          timeOfDayInfluence: 0.5,
          weekdayInfluence: 0.5,
          seasonalInfluence: 0.5,
          contextualModifier: 1.0,
        );

        // Act
        final dimensions = await engine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Assert
        expect(dimensions, isNotNull);
        expect(dimensions.isNotEmpty, isTrue);
        
        // All dimensions should be in valid range
        dimensions.forEach((dimension, value) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        });
      });

      test('should handle default insights gracefully', () async {
        // Arrange - minimal insights
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: [],
          personalityStrength: 0.5,
          evolutionMomentum: 0.0,
          authenticityLevel: 0.5,
          confidenceLevel: 0.5,
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.5,
          explorationTendency: 0.5,
          socialEngagement: 0.5,
          spontaneityIndex: 0.5,
          consistencyScore: 0.5,
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement: 0.5,
          socialPreference: 0.5,
          leadershipTendency: 0.5,
          collaborationStyle: 0.5,
          trustNetworkStrength: 0.5,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.5,
          relationshipStability: 0.5,
          influenceReceptivity: 0.5,
          givingTendency: 0.5,
          boundaryFlexibility: 0.5,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: 0.5,
          timeOfDayInfluence: 0.5,
          weekdayInfluence: 0.5,
          seasonalInfluence: 0.5,
          contextualModifier: 1.0,
        );

        // Act
        final dimensions = await engine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Assert
        expect(dimensions, isNotNull);
        expect(dimensions.isNotEmpty, isTrue);
        
        // All dimensions should be in valid range
        dimensions.forEach((dimension, value) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        });
      });

      test('should compile all core dimensions', () async {
        // Arrange
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: [],
          personalityStrength: 0.6,
          evolutionMomentum: 0.3,
          authenticityLevel: 0.7,
          confidenceLevel: 0.6,
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.6,
          explorationTendency: 0.7,
          socialEngagement: 0.6,
          spontaneityIndex: 0.7,
          consistencyScore: 0.6,
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement: 0.6,
          socialPreference: 0.7,
          leadershipTendency: 0.5,
          collaborationStyle: 0.65,
          trustNetworkStrength: 0.7,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.6,
          relationshipStability: 0.7,
          influenceReceptivity: 0.6,
          givingTendency: 0.7,
          boundaryFlexibility: 0.6,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: 0.7,
          timeOfDayInfluence: 0.5,
          weekdayInfluence: 0.5,
          seasonalInfluence: 0.5,
          contextualModifier: 1.0,
        );

        // Act
        final dimensions = await engine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Assert - Should have all core dimensions
        expect(dimensions.containsKey('exploration_eagerness'), isTrue);
        expect(dimensions.containsKey('curation_tendency'), isTrue);
        expect(dimensions.containsKey('location_adventurousness'), isTrue);
        expect(dimensions.containsKey('authenticity_preference'), isTrue);
        expect(dimensions.containsKey('social_discovery_style'), isTrue);
        expect(dimensions.containsKey('temporal_flexibility'), isTrue);
        expect(dimensions.containsKey('community_orientation'), isTrue);
        expect(dimensions.containsKey('trust_network_reliance'), isTrue);
      });

      test('should apply entanglement between correlated dimensions', () async {
        // Arrange - High exploration should correlate with location adventurousness
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: ['exploration_eagerness'],
          personalityStrength: 0.8,
          evolutionMomentum: 0.4,
          authenticityLevel: 0.7,
          confidenceLevel: 0.7,
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.8,
          explorationTendency: 0.9, // High exploration
          socialEngagement: 0.5,
          spontaneityIndex: 0.8,
          consistencyScore: 0.6,
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement: 0.5,
          socialPreference: 0.5,
          leadershipTendency: 0.5,
          collaborationStyle: 0.5,
          trustNetworkStrength: 0.5,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.5,
          relationshipStability: 0.5,
          influenceReceptivity: 0.5,
          givingTendency: 0.5,
          boundaryFlexibility: 0.5,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: 0.7,
          timeOfDayInfluence: 0.5,
          weekdayInfluence: 0.5,
          seasonalInfluence: 0.5,
          contextualModifier: 1.0,
        );

        // Act
        final dimensions = await engine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Assert - Exploration and location adventurousness should be correlated
        expect(dimensions['exploration_eagerness'], greaterThan(0.5));
        expect(dimensions['location_adventurousness'], greaterThan(0.5));
        // They should be somewhat aligned (entangled)
        final exploration = dimensions['exploration_eagerness']!;
        final location = dimensions['location_adventurousness']!;
        expect((exploration - location).abs(), lessThan(0.3)); // Should be correlated
      });

      test('should apply decoherence from temporal insights', () async {
        // Arrange - High temporal influence should cause decoherence
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: [],
          personalityStrength: 0.6,
          evolutionMomentum: 0.3,
          authenticityLevel: 0.7,
          confidenceLevel: 0.6,
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.6,
          explorationTendency: 0.7,
          socialEngagement: 0.6,
          spontaneityIndex: 0.7,
          consistencyScore: 0.6,
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement: 0.6,
          socialPreference: 0.7,
          leadershipTendency: 0.5,
          collaborationStyle: 0.65,
          trustNetworkStrength: 0.7,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.6,
          relationshipStability: 0.7,
          influenceReceptivity: 0.6,
          givingTendency: 0.7,
          boundaryFlexibility: 0.6,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: 0.7,
          timeOfDayInfluence: 0.9, // High temporal influence
          weekdayInfluence: 0.9, // High temporal influence
          seasonalInfluence: 0.9, // High temporal influence
          contextualModifier: 1.0,
        );

        // Act
        final dimensions = await engine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Assert - Should still produce valid dimensions despite decoherence
        expect(dimensions, isNotNull);
        dimensions.forEach((dimension, value) {
          expect(value, greaterThanOrEqualTo(0.0));
          expect(value, lessThanOrEqualTo(1.0));
        });
      });
    });
  });
}

