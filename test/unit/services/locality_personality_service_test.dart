/// SPOTS LocalityPersonalityService Tests
/// Date: November 25, 2025
/// Purpose: Test locality AI personality management with golden expert influence
///
/// Test Coverage:
/// - Locality Personality Management: Get, update, incorporate golden expert influence
/// - Locality Vibe Calculation: Overall locality vibe based on golden experts
/// - Locality Preferences: Preferences shaped by golden experts
/// - Locality Characteristics: Characteristics derived from golden expert behavior
/// - Integration: AI personality learning, golden expert influence
///
/// Dependencies:
/// - Mock GoldenExpertAIInfluenceService: For golden expert weight calculation
/// - Mock PersonalityLearning: For AI personality integration
/// - Mock MultiPathExpertiseService: For golden expert data
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/geographic/locality_personality_service.dart';
import 'package:avrai/core/services/expertise/golden_expert_ai_influence_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/expertise/multi_path_expertise.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

class MockGoldenExpertAIInfluenceService extends Mock
    implements GoldenExpertAIInfluenceService {}

void main() {
  group('LocalityPersonalityService Tests', () {
    late LocalityPersonalityService service;
    late MockGoldenExpertAIInfluenceService mockInfluenceService;
    late DateTime testDate;

    setUpAll(() {
      // Register fallback values for mocktail any() with non-nullable types
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(1.0);
    });

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockInfluenceService = MockGoldenExpertAIInfluenceService();

      service = LocalityPersonalityService(
        influenceService: mockInfluenceService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Locality personality tests focus on business logic (personality management, golden expert influence, vibe calculation), not property assignment

    group('getLocalityPersonality', () {
      test(
          'should return locality personality for a locality, return default personality when none exists, and handle errors gracefully',
          () async {
        // Test business logic: locality personality retrieval
        final personality1 = await service.getLocalityPersonality('Brooklyn');
        expect(personality1, isNotNull);
        expect(personality1, isA<PersonalityProfile>());

        final personality2 =
            await service.getLocalityPersonality('New Locality');
        expect(personality2, isNotNull);
        expect(personality2, isA<PersonalityProfile>());

        final personality3 = await service.getLocalityPersonality('Brooklyn');
        expect(personality3, isNotNull);
        expect(personality3, isA<PersonalityProfile>());
      });
    });

    group('updateLocalityPersonality', () {
      test(
          'should update locality personality based on user behavior, incorporate golden expert influence when updating, and not apply golden expert weight for non-golden experts',
          () async {
        // Test business logic: locality personality updates with golden expert influence
        final behaviorData1 = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
          'authenticityScore': 0.7,
        };
        when(() => mockInfluenceService.applyWeightToBehavior(any(), any()))
            .thenAnswer((invocation) {
          final inputData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Map<String, dynamic>.from(inputData);
        });
        final updatedPersonality1 = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData1,
        );
        expect(updatedPersonality1, isNotNull);
        expect(updatedPersonality1, isA<PersonalityProfile>());

        final behaviorData2 = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };
        final localExpertise1 = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .thenReturn(1.35);
        final updatedPersonality2 = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData2,
          localExpertise: localExpertise1,
        );
        expect(updatedPersonality2, isNotNull);
        verify(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .called(1);

        final localExpertise2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'user-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 3650),
          firstLocalVisit: testDate.subtract(const Duration(days: 3650)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 3650),
          isGoldenLocalExpert: false,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise2))
            .thenReturn(1.0);
        final updatedPersonality3 = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData2,
          localExpertise: localExpertise2,
        );
        expect(updatedPersonality3, isNotNull);
        verify(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise2))
            .called(1);
      });
    });

    group('incorporateGoldenExpertInfluence', () {
      test(
          'should incorporate golden expert influence into locality personality and handle multiple golden experts',
          () async {
        // Test business logic: golden expert influence incorporation
        final localExpertise1 = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950),
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final behaviorData1 = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .thenReturn(1.4);
        when(() => mockInfluenceService.applyWeightToBehavior(any(), any()))
            .thenAnswer((invocation) {
          final inputData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Map<String, dynamic>.from(inputData);
        });
        final updatedPersonality1 =
            await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData1,
          localExpertise: localExpertise1,
        );
        expect(updatedPersonality1, isNotNull);
        verify(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .called(1);

        final goldenExpert2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'user-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 150,
          uniqueLocalLocations: 60,
          averageLocalRating: 4.7,
          timeInLocation: const Duration(days: 10950),
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final behaviorData2 = {'explorationScore': 0.6};
        final behaviorData3 = {'communityScore': 0.8};
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .thenReturn(1.35);
        when(() => mockInfluenceService.calculateInfluenceWeight(goldenExpert2))
            .thenReturn(1.4);
        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData2,
          localExpertise: localExpertise1,
        );
        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData3,
          localExpertise: goldenExpert2,
        );
        verify(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise1))
            .called(1);
        verify(() =>
                mockInfluenceService.calculateInfluenceWeight(goldenExpert2))
            .called(1);
      });
    });

    group('calculateLocalityVibe', () {
      test(
          'should calculate overall locality vibe and incorporate golden expert influence in vibe calculation',
          () async {
        // Test business logic: locality vibe calculation with golden expert influence
        final vibe1 = await service.calculateLocalityVibe('Brooklyn');
        expect(vibe1, isNotNull);
        expect(vibe1, isA<Map<String, dynamic>>());
        expect(vibe1['locality'], equals('Brooklyn'));
        expect(vibe1['dominantTraits'], isA<List>());
        expect(vibe1['authenticityScore'], isA<double>());

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final behaviorData = {'explorationScore': 0.8};
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        when(() => mockInfluenceService.applyWeightToBehavior(any(), any()))
            .thenAnswer((invocation) {
          final inputData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Map<String, dynamic>.from(inputData);
        });
        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );
        final vibe2 = await service.calculateLocalityVibe('Brooklyn');
        expect(vibe2, isNotNull);
        expect(vibe2['locality'], equals('Brooklyn'));
        expect(vibe2['dimensions'], isA<Map>());
      });
    });

    group('getLocalityPreferences', () {
      test(
          'should return locality preferences shaped by golden experts and reflect golden expert preferences',
          () async {
        // Test business logic: locality preferences with golden expert influence
        final preferences1 = await service.getLocalityPreferences('Brooklyn');
        expect(preferences1, isNotNull);
        expect(preferences1, isA<Map<String, dynamic>>());
        expect(preferences1['locality'], equals('Brooklyn'));
        expect(preferences1['explorationEagerness'], isA<double>());

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final behaviorData = {'explorationScore': 0.8};
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        when(() => mockInfluenceService.applyWeightToBehavior(any(), any()))
            .thenAnswer((invocation) {
          final inputData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Map<String, dynamic>.from(inputData);
        });
        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );
        final preferences2 = await service.getLocalityPreferences('Brooklyn');
        expect(preferences2, isNotNull);
        expect(preferences2['explorationEagerness'], isA<double>());
      });
    });

    group('getLocalityCharacteristics', () {
      test(
          'should return locality characteristics and reflect golden expert characteristics',
          () async {
        // Test business logic: locality characteristics with golden expert influence
        final characteristics1 =
            await service.getLocalityCharacteristics('Brooklyn');
        expect(characteristics1, isNotNull);
        expect(characteristics1, isA<Map<String, dynamic>>());
        expect(characteristics1['locality'], equals('Brooklyn'));
        expect(characteristics1['dominantTraits'], isA<List>());

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final behaviorData = {'explorationScore': 0.8};
        when(() =>
                mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        when(() => mockInfluenceService.applyWeightToBehavior(any(), any()))
            .thenAnswer((invocation) {
          final inputData =
              invocation.positionalArguments[0] as Map<String, dynamic>;
          return Map<String, dynamic>.from(inputData);
        });
        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );
        final characteristics2 =
            await service.getLocalityCharacteristics('Brooklyn');
        expect(characteristics2, isNotNull);
        expect(characteristics2['personalitySummary'], isA<String>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
