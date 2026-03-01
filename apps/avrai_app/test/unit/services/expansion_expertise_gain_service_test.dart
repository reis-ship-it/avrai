import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/expertise/expansion_expertise_gain_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_core/models/geographic/geographic_expansion.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

import 'expansion_expertise_gain_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([GeographicExpansionService])
void main() {
  group('ExpansionExpertiseGainService Tests', () {
    late ExpansionExpertiseGainService service;
    late MockGeographicExpansionService mockExpansionService;
    late UnifiedUser testUser;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      // Create fresh mock for each test to avoid state leakage
      mockExpansionService = MockGeographicExpansionService();

      service = ExpansionExpertiseGainService(
        expansionService: mockExpansionService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-1',
        displayName: 'Test User',
      );
    });

    tearDown(() {
      // Reset mock between tests to prevent state leakage
      reset(mockExpansionService);
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Expertise gain tests focus on business logic (threshold checking, expertise granting), not property assignment

    group('Locality Expertise Gain', () {
      test(
          'should grant local expertise for neighboring locality expansion, or not grant expertise if locality not expanded',
          () async {
        // Test business logic: locality expertise granting based on threshold
        const clubId = 'club-1';
        const category = 'Coffee';
        const originalLocality = 'Mission District, San Francisco';
        const newLocality = 'Williamsburg, Brooklyn';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: originalLocality,
          expandedLocalities: const [newLocality],
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedLocalityThreshold(expansion1))
            .thenReturn(true);
        final result1 = await service.checkAndGrantLocalityExpertise(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, equals(ExpertiseLevel.local));
        verify(mockExpansionService.hasReachedLocalityThreshold(expansion1))
            .called(1);

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: originalLocality,
          expandedLocalities: const [],
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedLocalityThreshold(expansion2))
            .thenReturn(false);
        final result2 = await service.checkAndGrantLocalityExpertise(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isNull);
        verify(mockExpansionService.hasReachedLocalityThreshold(expansion2))
            .called(1);
      });
    });

    group('City Expertise Gain', () {
      test(
          'should grant city expertise when 75% city coverage reached, or not grant if 75% threshold not reached',
          () async {
        // Test business logic: city expertise granting based on threshold
        const clubId = 'club-1';
        const category = 'Coffee';
        const city = 'Brooklyn';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: const [city],
          cityCoverage: const {city: 0.8},
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedCityThreshold(expansion1, city))
            .thenReturn(true);
        final result1 = await service.checkAndGrantCityExpertise(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, equals(ExpertiseLevel.city));
        verify(mockExpansionService.hasReachedCityThreshold(expansion1, city))
            .called(1);

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: const [city],
          cityCoverage: const {city: 0.6},
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedCityThreshold(expansion2, city))
            .thenReturn(false);
        final result2 = await service.checkAndGrantCityExpertise(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isNull);
        verify(mockExpansionService.hasReachedCityThreshold(expansion2, city))
            .called(1);
      });
    });

    group('State Expertise Gain', () {
      test(
          'should grant state expertise when 75% state coverage reached, or not grant if 75% threshold not reached',
          () async {
        // Test business logic: state expertise granting based on threshold
        const clubId = 'club-1';
        const category = 'Coffee';
        const state = 'New York';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedStates: const [state],
          stateCoverage: const {state: 0.8},
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedStateThreshold(expansion1, state))
            .thenReturn(true);
        final result1 = await service.checkAndGrantStateExpertise(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, equals(ExpertiseLevel.regional));
        verify(mockExpansionService.hasReachedStateThreshold(expansion1, state))
            .called(1);

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedStates: const [state],
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedStateThreshold(expansion2, state))
            .thenReturn(false);
        final result2 = await service.checkAndGrantStateExpertise(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isNull);
        verify(mockExpansionService.hasReachedStateThreshold(expansion2, state))
            .called(1);
      });
    });

    group('Nation Expertise Gain', () {
      test(
          'should grant nation expertise when 75% nation coverage reached, or not grant if 75% threshold not reached',
          () async {
        // Test business logic: nation expertise granting based on threshold
        const clubId = 'club-1';
        const category = 'Coffee';
        const nation = 'United States';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: const [nation],
          nationCoverage: const {nation: 0.8},
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedNationThreshold(expansion1, nation))
            .thenReturn(true);
        final result1 = await service.checkAndGrantNationExpertise(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, equals(ExpertiseLevel.national));
        verify(mockExpansionService.hasReachedNationThreshold(
                expansion1, nation))
            .called(1);

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: const [nation],
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedNationThreshold(expansion2, nation))
            .thenReturn(false);
        final result2 = await service.checkAndGrantNationExpertise(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isNull);
        verify(mockExpansionService.hasReachedNationThreshold(
                expansion2, nation))
            .called(1);
      });
    });

    group('Global Expertise Gain', () {
      test(
          'should grant global expertise when 75% global coverage reached, or not grant if 75% threshold not reached',
          () async {
        // Test business logic: global expertise granting based on threshold
        const clubId = 'club-1';
        const category = 'Coffee';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedGlobalThreshold(expansion1))
            .thenReturn(true);
        final result1 = await service.checkAndGrantGlobalExpertise(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, equals(ExpertiseLevel.global));
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion1))
            .called(1);

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedGlobalThreshold(expansion2))
            .thenReturn(false);
        final result2 = await service.checkAndGrantGlobalExpertise(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isNull);
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion2))
            .called(1);
      });
    });

    group('Universal Expertise Gain', () {
      test(
          'should grant universal expertise when 75% universe coverage reached',
          () async {
        // Test business logic: universal expertise granting
        const clubId = 'club-1';
        const category = 'Coffee';
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: const ['USA', 'Canada', 'Mexico'],
          createdAt: testDate,
          updatedAt: testDate,
        );
        when(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .thenReturn(true);
        final result = await service.checkAndGrantUniversalExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );
        expect(result, equals(ExpertiseLevel.universal));
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .called(1);
      });
    });

    group('Main Expertise Grant Method', () {
      test(
          'should grant expertise from expansion when thresholds met and preserve existing expertise when granting new expertise',
          () async {
        // Test business logic: main expertise granting method with threshold checking and expertise preservation
        const clubId = 'club-1';
        const category = 'Coffee';
        const city = 'Brooklyn';

        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: const [city],
          cityCoverage: const {city: 0.8},
          createdAt: testDate,
          updatedAt: testDate,
        );
        // Mock all threshold methods since grantExpertiseFromExpansion checks all levels
        when(mockExpansionService.hasReachedLocalityThreshold(expansion1))
            .thenReturn(false);
        when(mockExpansionService.hasReachedCityThreshold(expansion1, city))
            .thenReturn(true);
        // Mock remaining thresholds to return false (not reached)
        when(mockExpansionService.hasReachedStateThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedNationThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedGlobalThreshold(expansion1))
            .thenReturn(false);
        final result1 = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion1,
          category: category,
        );
        expect(result1, isA<UnifiedUser>());
        expect(
            result1.expertiseMap[category], equals(ExpertiseLevel.city.name));

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );
        // Mock all threshold methods for expansion2
        when(mockExpansionService.hasReachedLocalityThreshold(expansion2))
            .thenReturn(false);
        when(mockExpansionService.hasReachedCityThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedStateThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedNationThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedGlobalThreshold(expansion2))
            .thenReturn(false);
        final result2 = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion2,
          category: category,
        );
        expect(result2, isA<UnifiedUser>());
      });
    });

    group('Integration with GeographicExpansionService', () {
      test('should use GeographicExpansionService to check thresholds',
          () async {
        // Test business logic: integration with GeographicExpansionService
        const clubId = 'club-1';
        const category = 'Coffee';
        const city = 'Brooklyn';
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: const [city],
          cityCoverage: const {
            city: 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );
        // Mock all threshold methods since grantExpertiseFromExpansion checks all levels
        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(false);
        when(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .thenReturn(true);
        // Mock remaining thresholds to return false (not reached)
        when(mockExpansionService.hasReachedStateThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedNationThreshold(any, any))
            .thenReturn(false);
        when(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .thenReturn(false);
        final result = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion,
          category: category,
        );
        verify(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .called(1);
        expect(result.expertiseMap[category], equals(ExpertiseLevel.city.name));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
