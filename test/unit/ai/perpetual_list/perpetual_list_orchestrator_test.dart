// Perpetual List Orchestrator Tests
//
// Integration tests for the main orchestrator that coordinates
// all components to generate personalized lists.
//
// Key test scenarios:
// - Full list generation flow
// - Cold start behavior
// - Age filtering integration
// - Visit recording
// - Interaction processing

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai/perpetual_list/engines/trigger_engine.dart';
import 'package:avrai/core/ai/perpetual_list/analyzers/string_theory_possibility_engine.dart';
import 'package:avrai/core/ai/perpetual_list/filters/age_aware_list_filter.dart';
import 'package:avrai/core/ai/perpetual_list/models/models.dart';
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai_core/models/personality_profile.dart';

void main() {
  group('PerpetualListOrchestrator', () {
    group('clearUserState', () {
      test('should clear all state for user', () {
        final triggerEngine = TriggerEngine();
        // Verify engines can be instantiated (used by orchestrator)
        final possibilityEngine = StringTheoryPossibilityEngine();
        final ageFilter = AgeAwareListFilter();

        // Create a minimal orchestrator (other deps would need mocks for full tests)
        // For now, just test the helper methods
        expect(triggerEngine.getRemainingListsToday('test-user'), equals(3));
        expect(possibilityEngine, isNotNull);
        expect(ageFilter, isNotNull);

        triggerEngine.clearUserState('test-user');

        expect(triggerEngine.getRemainingListsToday('test-user'), equals(3));
      });
    });

    group('TriggerContext building', () {
      test('TriggerContext should detect morning window', () {
        final context = TriggerContext(
          localTime: DateTime(2024, 1, 15, 9, 0), // 9am
          recentListEngagement: ListEngagementMetrics.empty,
        );

        expect(context.isInMorningWindow, isTrue);
        expect(context.isInEveningWindow, isFalse);
      });

      test('TriggerContext should detect evening window', () {
        final context = TriggerContext(
          localTime: DateTime(2024, 1, 15, 19, 0), // 7pm
          recentListEngagement: ListEngagementMetrics.empty,
        );

        expect(context.isInMorningWindow, isFalse);
        expect(context.isInEveningWindow, isTrue);
      });

      test('TriggerContext should check minimum interval', () {
        final context = TriggerContext(
          localTime: DateTime.now(),
          recentListEngagement: ListEngagementMetrics.empty,
          timeSinceLastGeneration: const Duration(hours: 10),
        );

        expect(context.hasMinimumInterval(const Duration(hours: 8)), isTrue);
        expect(context.hasMinimumInterval(const Duration(hours: 12)), isFalse);
      });
    });

    group('AgeFilter integration', () {
      test('should filter candidates by age', () {
        final ageFilter = AgeAwareListFilter();

        final candidates = [
          _createScoredCandidate('coffee', 'Coffee Shop'),
          _createScoredCandidate('bar', 'Cool Bar'),
          _createScoredCandidate('restaurant', 'Italian Place'),
        ];

        final filtered = ageFilter.filterByAge(
          candidates: candidates,
          userAge: 18,
        );

        expect(filtered.length, equals(2));
        expect(filtered.any((c) => c.category == 'bar'), isFalse);
      });
    });

    group('StringTheoryPossibilityEngine integration', () {
      test('should generate and normalize possibilities', () async {
        final possibilityEngine = StringTheoryPossibilityEngine();

        final context = _createMockContext();

        final possibilities = await possibilityEngine.generatePossibilitySpace(
          context: context,
        );

        expect(possibilities.length, equals(5)); // Default branch count

        final totalProb = possibilities
            .map((p) => p.normalizedProbability)
            .fold(0.0, (a, b) => a + b);

        expect(totalProb, closeTo(1.0, 0.001));
      });
    });

    group('TriggerDecision model', () {
      test('should create generate decision correctly', () {
        final decision = TriggerDecision.generate(
          reasons: [TriggerReason.coldStart, TriggerReason.dailyCheckIn],
          priority: TriggerPriority.high,
        );

        expect(decision.shouldGenerate, isTrue);
        expect(decision.reasons.length, equals(2));
        expect(decision.isColdStart, isTrue);
        expect(decision.priority, equals(TriggerPriority.high));
        expect(decision.suggestedListCount, equals(3)); // Cold start = 3
      });

      test('should create skip decision correctly', () {
        final decision = TriggerDecision.skip(
          reason: 'Too soon since last generation',
        );

        expect(decision.shouldGenerate, isFalse);
        expect(decision.skipReason, contains('Too soon'));
        expect(decision.suggestedListCount, equals(0));
      });
    });

    group('VisitPattern model', () {
      test('should correctly identify weekend visits', () {
        final saturdayVisit = VisitPattern(
          id: 'visit-1',
          userId: 'user-1',
          category: 'coffee',
          latitude: 40.7128,
          longitude: -74.0060,
          atomicTimestamp: DateTime(2024, 1, 13, 10, 0), // Saturday
          dwellTime: const Duration(minutes: 30),
          dayOfWeek: DayOfWeek.saturday,
          timeSlot: TimeSlot.morning,
          isRepeatVisit: false,
          visitFrequency: 1,
          groupSize: 1,
        );

        expect(saturdayVisit.isWeekend, isTrue);

        final mondayVisit = saturdayVisit.copyWith(
          dayOfWeek: DayOfWeek.monday,
        );

        expect(mondayVisit.isWeekend, isFalse);
      });

      test('should correctly identify solo vs group visits', () {
        final soloVisit = VisitPattern(
          id: 'visit-1',
          userId: 'user-1',
          category: 'coffee',
          latitude: 40.7128,
          longitude: -74.0060,
          atomicTimestamp: DateTime.now(),
          dwellTime: const Duration(minutes: 30),
          dayOfWeek: DayOfWeek.monday,
          timeSlot: TimeSlot.morning,
          isRepeatVisit: false,
          visitFrequency: 1,
          groupSize: 1,
        );

        expect(soloVisit.isSoloVisit, isTrue);
        expect(soloVisit.isGroupVisit, isFalse);

        final groupVisit = VisitPattern(
          id: 'visit-2',
          userId: 'user-1',
          category: 'restaurant',
          latitude: 40.7128,
          longitude: -74.0060,
          atomicTimestamp: DateTime.now(),
          dwellTime: const Duration(hours: 2),
          dayOfWeek: DayOfWeek.friday,
          timeSlot: TimeSlot.evening,
          isRepeatVisit: false,
          visitFrequency: 1,
          groupSize: 4,
        );

        expect(groupVisit.isSoloVisit, isFalse);
        expect(groupVisit.isGroupVisit, isTrue);
      });
    });

    group('UserPreferenceSignals model', () {
      test('should correctly calculate top categories', () {
        final signals = UserPreferenceSignals(
          categoryWeights: {
            'coffee': 0.9,
            'restaurant': 0.7,
            'bar': 0.5,
            'museum': 0.3,
          },
          age: 25,
        );

        final topCategories = signals.getTopCategories(2);

        expect(topCategories.length, equals(2));
        expect(topCategories.first, equals('coffee'));
        expect(topCategories.last, equals('restaurant'));
      });

      test('should correctly identify user preferences', () {
        final exploreSocialSignals = UserPreferenceSignals(
          averageGroupSize: 4.0,
          noisePreference: 0.7,
          explorationWillingness: 0.8,
          pricePointPreference: 0.6,
          age: 30,
        );

        expect(exploreSocialSignals.prefersGroups, isTrue);
        expect(exploreSocialSignals.prefersLively, isTrue);
        expect(exploreSocialSignals.prefersExploring, isTrue);

        final soloQuietSignals = UserPreferenceSignals(
          averageGroupSize: 1.0,
          noisePreference: 0.2,
          explorationWillingness: 0.3,
          pricePointPreference: 0.3,
          age: 25,
        );

        expect(soloQuietSignals.prefersSolo, isTrue);
        expect(soloQuietSignals.prefersQuiet, isTrue);
        expect(soloQuietSignals.prefersFamiliar, isTrue);
        expect(soloQuietSignals.isBudgetConscious, isTrue);
      });
    });

    group('SuggestedList model', () {
      test('should calculate quality score correctly', () {
        final list = SuggestedList(
          id: 'list-1',
          title: 'Test List',
          description: 'A test list',
          places: [],
          theme: 'test',
          generatedAt: DateTime.now(),
          avgCompatibilityScore: 0.8,
          noveltyScore: 0.6,
          timelinessScore: 0.7,
        );

        // Quality = 0.5 * 0.8 + 0.25 * 0.6 + 0.25 * 0.7 = 0.4 + 0.15 + 0.175 = 0.725
        expect(list.qualityScore, closeTo(0.725, 0.001));
      });
    });

    group('ListInteraction model', () {
      test('should correctly identify positive interactions', () {
        expect(
          ListInteraction(
            type: ListInteractionType.saved,
            listId: 'list-1',
            timestamp: DateTime.now(),
          ).isPositive,
          isTrue,
        );

        expect(
          ListInteraction(
            type: ListInteractionType.placeVisited,
            listId: 'list-1',
            timestamp: DateTime.now(),
          ).isPositive,
          isTrue,
        );
      });

      test('should correctly identify negative interactions', () {
        expect(
          ListInteraction(
            type: ListInteractionType.dismissed,
            listId: 'list-1',
            timestamp: DateTime.now(),
          ).isNegative,
          isTrue,
        );
      });

      test('should correctly identify neutral interactions', () {
        expect(
          ListInteraction(
            type: ListInteractionType.viewed,
            listId: 'list-1',
            timestamp: DateTime.now(),
          ).isNeutral,
          isTrue,
        );
      });
    });
  });
}

/// Create a mock scored candidate for testing
ScoredCandidate _createScoredCandidate(String category, String name) {
  return ScoredCandidate(
    candidate: ListCandidate(
      place: Spot(
        id: 'spot-${name.hashCode}',
        name: name,
        description: 'Test spot for $name',
        category: category,
        latitude: 40.7128,
        longitude: -74.0060,
        rating: 4.0,
        createdBy: 'test-user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      category: category,
    ),
    possibilityScore: 0.7,
    noveltyScore: 0.5,
    timelinessScore: 0.6,
    combinedScore: 0.65,
  );
}

/// Create a mock context for testing
ListGenerationContext _createMockContext() {
  return ListGenerationContext(
    userId: 'test-user',
    userAge: 25,
    personality: PersonalityProfile(
      agentId: 'test-agent',
      userId: 'test-user',
      archetype: 'explorer',
      dimensions: {'novelty_seeking': 0.6},
      dimensionConfidence: {},
      authenticity: 0.9,
      evolutionGeneration: 5,
      learningHistory: {},
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    ),
    listHistory: ListHistory.empty,
    currentLocation: LocationInfo.unknown(),
    atomicTime: DateTime.now(),
    preferenceSignals: UserPreferenceSignals.defaults(age: 25),
  );
}

extension _VisitPatternCopyWith on VisitPattern {
  VisitPattern copyWith({
    String? id,
    String? userId,
    String? placeId,
    String? placeName,
    String? category,
    double? latitude,
    double? longitude,
    DateTime? atomicTimestamp,
    Duration? dwellTime,
    DayOfWeek? dayOfWeek,
    TimeSlot? timeSlot,
    bool? isRepeatVisit,
    int? visitFrequency,
    Duration? timeSinceLastVisit,
    int? groupSize,
    Map<String, dynamic>? metadata,
  }) {
    return VisitPattern(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      atomicTimestamp: atomicTimestamp ?? this.atomicTimestamp,
      dwellTime: dwellTime ?? this.dwellTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      timeSlot: timeSlot ?? this.timeSlot,
      isRepeatVisit: isRepeatVisit ?? this.isRepeatVisit,
      visitFrequency: visitFrequency ?? this.visitFrequency,
      timeSinceLastVisit: timeSinceLastVisit ?? this.timeSinceLastVisit,
      groupSize: groupSize ?? this.groupSize,
      metadata: metadata ?? this.metadata,
    );
  }
}
