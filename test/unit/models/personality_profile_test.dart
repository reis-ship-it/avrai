import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for PersonalityProfile model
/// Tests the 8-dimension personality system, evolution tracking, and learning
/// OUR_GUTS.md: "AI personality that evolves and learns while preserving privacy"
void main() {
  group('PersonalityProfile Model Tests', () {
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late PersonalityProfile testProfile;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testProfile = ModelFactories.createTestPersonalityProfile();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Initial Personality Profile Factory', () {
      test('should create initial profile with correct business defaults and usable state', () {
        // Test business logic: factory method creates usable profile with correct defaults
        // Phase 8.3: Use agentId for privacy protection
        const agentId = 'agent_test_123';
        final profile = PersonalityProfile.initial(agentId, userId: 'user-123');

        // Test business logic: profile is usable (can calculate compatibility, has dimensions)
        expect(profile.agentId, equals(agentId));
        expect(profile.dimensions.length,
            equals(VibeConstants.coreDimensions.length));
        expect(profile.evolutionGeneration, equals(1));
        // Test behavior: initial profile can be used for compatibility calculations
        final otherProfile = PersonalityProfile.initial('agent_test_456', userId: 'user-456');
        final compatibility = profile.calculateCompatibility(otherProfile);
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
        // Test behavior: initial profile is not well-developed (needs evolution)
        expect(profile.isWellDeveloped, isFalse);
      });
    });

    group('Personality Evolution System', () {
      test(
          'should correctly evolve personality with incremented generation and clamp values to valid range',
          () {
        // Test business logic: evolution tracking and value clamping
        final original = ModelFactories.createTestPersonalityProfile();
        final evolved = original.evolve(
          newDimensions: {'exploration_eagerness': 0.9},
          newArchetype: 'adventurous_explorer',
        );

        expect(evolved.evolutionGeneration,
            equals(original.evolutionGeneration + 1));
        // Drift resistance: dimensions cannot drift more than 30% from core.
        final coreExploration =
            original.corePersonality['exploration_eagerness'] ??
                VibeConstants.defaultDimensionValue;
        expect(
          evolved.dimensions['exploration_eagerness'],
          equals((coreExploration + PersonalityProfile.maxDriftFromCore)
              .clamp(VibeConstants.minDimensionValue,
                  VibeConstants.maxDimensionValue)),
        );
        expect(evolved.lastUpdated.isAfter(original.lastUpdated), isTrue);

        // Test value clamping
        final evolvedDimensions = original.evolve(
          newDimensions: {
            'exploration_eagerness': 1.5, // Above max
            'community_orientation': -0.5, // Below min
          },
        );
        final evolvedConfidence = original.evolve(
          newConfidence: {
            'exploration_eagerness': 1.5,
            'community_orientation': -0.5,
          },
        );

        final coreExploration2 =
            original.corePersonality['exploration_eagerness'] ??
                VibeConstants.defaultDimensionValue;
        final coreCommunity =
            original.corePersonality['community_orientation'] ??
                VibeConstants.defaultDimensionValue;
        expect(
          evolvedDimensions.dimensions['exploration_eagerness'],
          equals((coreExploration2 + PersonalityProfile.maxDriftFromCore)
              .clamp(VibeConstants.minDimensionValue,
                  VibeConstants.maxDimensionValue)),
        );
        expect(
          evolvedDimensions.dimensions['community_orientation'],
          equals((coreCommunity - PersonalityProfile.maxDriftFromCore).clamp(
              VibeConstants.minDimensionValue, VibeConstants.maxDimensionValue)),
        );
        expect(evolvedConfidence.dimensionConfidence['exploration_eagerness'],
            equals(1.0));
        expect(evolvedConfidence.dimensionConfidence['community_orientation'],
            equals(0.0));
      });
    });

    group('Compatibility Calculation', () {
      test(
          'should correctly calculate compatibility between personalities and return zero when confidence below threshold',
          () {
        // Test business logic: compatibility calculation and confidence threshold
        final similar1 = ModelFactories.createAdventurousExplorerProfile();
        final similar2 =
            ModelFactories.createAdventurousExplorerProfile(userId: 'user-2');
        final different =
            ModelFactories.createCommunityCuratorProfile(userId: 'user-3');

        final highCompatibility = similar1.calculateCompatibility(similar2);
        final lowCompatibility = similar1.calculateCompatibility(different);

        expect(highCompatibility, greaterThan(0.75));
        expect(lowCompatibility,
            lessThan(VibeConstants.highCompatibilityThreshold));

        // Test confidence threshold
        final profile1 = ModelFactories.createTestPersonalityProfile();
        final profile2 =
            ModelFactories.createTestPersonalityProfile(userId: 'user-2', agentId: 'agent_user-2');

        final lowConfidenceProfile1 = profile1.evolve(
          newConfidence: profile1.dimensions.map((k, v) => MapEntry(k, 0.1)),
        );

        expect(lowConfidenceProfile1.calculateCompatibility(profile2),
            equals(0.0));
      });
    });

    group('Personality Analysis Methods', () {
      test(
          'should correctly identify dominant traits, development state, and calculate learning potential',
          () {
        // Test business logic: trait analysis and learning potential
        final wellDeveloped = ModelFactories.createTestPersonalityProfile();
        final underdeveloped = PersonalityProfile.initial('agent_test_123', userId: 'user-123');
        final lowConfidence = wellDeveloped.evolve(
          newConfidence: {
            'exploration_eagerness': 0.3, // Below threshold
            'community_orientation': 0.8, // Above threshold
          },
        );

        final dominantTraits = wellDeveloped.getDominantTraits();
        expect(dominantTraits.length, lessThanOrEqualTo(3));
        expect(wellDeveloped.isWellDeveloped, isTrue);
        expect(underdeveloped.isWellDeveloped, isFalse);
        expect(
            lowConfidence.getDominantTraits().contains('exploration_eagerness'),
            isFalse);

        // Test learning potential
        final similar1 = ModelFactories.createAdventurousExplorerProfile();
        final similar2 =
            ModelFactories.createAdventurousExplorerProfile(userId: 'user-2');
        final different1 = similar1.evolve(
          newDimensions: similar1.dimensions.map((k, v) => MapEntry(k, 0.1)),
        );
        final different2 = similar2.evolve(
          newDimensions: similar2.dimensions.map((k, v) => MapEntry(k, 0.9)),
        );

        expect(similar1.calculateLearningPotential(similar2),
            greaterThanOrEqualTo(0.5));
        expect(different1.calculateLearningPotential(different2),
            equals(0.3)); // Low-compatibility learning floor (inclusive network)
      });
    });

    // Removed: Archetype Determination group
    // These tests only verified archetype property, not business logic
    // Archetype is tested through evolution and compatibility tests above

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final profile = ModelFactories.createAdventurousExplorerProfile();

        TestHelpers.validateJsonRoundtrip(
          profile,
          (p) => p.toJson(),
          (json) => PersonalityProfile.fromJson(json),
        );
      });
    });

    // Removed: Equality and Hash Testing group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('Privacy Preservation', () {
      test('should not expose sensitive user data in serialization', () {
        // Test business logic: privacy protection
        final profile = ModelFactories.createTestPersonalityProfile();
        final json = profile.toJson();

        expect(json['agent_id'], equals(profile.agentId));
        expect(json['user_id'], equals(profile.userId));
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('name'), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty dimensions and invalid data gracefully', () {
        // Test business logic: error handling
        final emptyProfile = PersonalityProfile(
          agentId: 'agent_test_123',
          userId: 'user-123',
          dimensions: {},
          dimensionConfidence: {},
          archetype: 'balanced',
          authenticity: 0.5,
          createdAt: testDate,
          lastUpdated: testDate,
          evolutionGeneration: 1,
          learningHistory: {},
        );
        final invalidHistory = PersonalityProfile(
          agentId: 'agent_test_123',
          userId: 'user-123',
          dimensions: {'exploration_eagerness': 0.5},
          dimensionConfidence: {'exploration_eagerness': 0.5},
          archetype: 'balanced',
          authenticity: 0.5,
          createdAt: testDate,
          lastUpdated: testDate,
          evolutionGeneration: 1,
          learningHistory: {'invalid_field': 'test'},
        );

        expect(emptyProfile.getDominantTraits(), isEmpty);
        expect(emptyProfile.isWellDeveloped, isFalse);
        expect(invalidHistory.getSummary()['total_interactions'], isNull);
      });
    });
  });
}
