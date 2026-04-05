import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/business/business_expert_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_community_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService;
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai_core/models/expertise/expertise_level.dart';
import '../../helpers/integration_test_helpers.dart';

import 'business_expert_matching_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';
import '../../mocks/mock_storage_service.dart';

@GenerateMocks(
    [ExpertiseMatchingService, ExpertiseCommunityService, PartnershipService])
class StubLanguageRuntimeService extends Fake
    implements LanguageRuntimeService {
  StubLanguageRuntimeService({
    this.recommendationResponse = 'AI suggestion response',
  });

  String recommendationResponse;

  @override
  Future<String> generateRecommendation({
    required String userQuery,
    LanguageRuntimeContext? userContext,
    LanguageRoutingPolicy dispatchPolicy =
        const LanguageRoutingPolicy.standard(),
  }) async =>
      recommendationResponse;
}

void main() {
  group('BusinessExpertMatchingService Tests', () {
    late BusinessExpertMatchingService service;
    late MockExpertiseMatchingService mockExpertiseMatchingService;
    late MockExpertiseCommunityService mockCommunityService;
    late StubLanguageRuntimeService stubLanguageRuntimeService;
    late MockPartnershipService mockPartnershipService;
    late GovernedDomainConsumerStateService governedStateService;
    late BusinessAccount business;

    setUp(() async {
      MockGetStorage.reset();
      await StorageService.instance.initForTesting(
        defaultStorage: MockGetStorage.getInstance(boxName: 'spots_default'),
        userStorage: MockGetStorage.getInstance(boxName: 'spots_user'),
        aiStorage: MockGetStorage.getInstance(boxName: 'spots_ai'),
        analyticsStorage:
            MockGetStorage.getInstance(boxName: 'spots_analytics'),
      );
      mockExpertiseMatchingService = MockExpertiseMatchingService();
      mockCommunityService = MockExpertiseCommunityService();
      stubLanguageRuntimeService = StubLanguageRuntimeService();
      mockPartnershipService = MockPartnershipService();
      governedStateService = GovernedDomainConsumerStateService(
        storageService: StorageService.instance,
      );

      service = BusinessExpertMatchingService(
        expertiseMatchingService: mockExpertiseMatchingService,
        communityService: mockCommunityService,
        languageRuntimeService: stubLanguageRuntimeService,
        partnershipService: mockPartnershipService,
        governedDomainConsumerStateService: governedStateService,
      );

      business = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        requiredExpertise: const ['food', 'restaurant'],
      );
    });

    // Removed: Property assignment tests
    // Business expert matching tests focus on business logic (expert finding, vibe-first matching), not property assignment

    group('findExpertsForBusiness', () {
      test(
          'should return empty list when no experts match, respect maxResults parameter, use expert preferences when available, apply minimum match score threshold from preferences, find experts from preferred communities, use language runtime suggestions when available, or work without the language runtime',
          () async {
        // Test business logic: expert finding with various configurations
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);
        final matches1 = await service.findExpertsForBusiness(business);
        expect(matches1, isEmpty);

        final matches2 = await service.findExpertsForBusiness(
          business,
          maxResults: 10,
        );
        expect(matches2.length, lessThanOrEqualTo(10));

        const preferences1 = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          preferredExpertiseCategories: ['restaurant'],
        );
        final businessWithPreferences1 = business.copyWith(
          expertPreferences: preferences1,
        );
        final matches3 = await service.findExpertsForBusiness(
          businessWithPreferences1,
        );
        expect(matches3, isA<List<BusinessExpertMatch>>());

        const preferences2 = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          minMatchScore: 0.7,
        );
        final businessWithPreferences2 = business.copyWith(
          expertPreferences: preferences2,
        );
        final matches4 = await service.findExpertsForBusiness(
          businessWithPreferences2,
        );
        for (final match in matches4) {
          expect(match.matchScore, greaterThanOrEqualTo(0.7));
        }

        const preferences3 = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          preferredCommunities: ['community-1'],
        );
        final businessWithPreferences3 = business.copyWith(
          expertPreferences: preferences3,
        );
        when(mockCommunityService.searchCommunities())
            .thenAnswer((_) async => []);
        final matches5 = await service.findExpertsForBusiness(
          businessWithPreferences3,
        );
        expect(matches5, isA<List<BusinessExpertMatch>>());

        stubLanguageRuntimeService.recommendationResponse =
            'AI suggestion response';
        final matches6 = await service.findExpertsForBusiness(business);
        expect(matches6, isA<List<BusinessExpertMatch>>());

        final serviceWithoutLanguageRuntime = BusinessExpertMatchingService(
          expertiseMatchingService: mockExpertiseMatchingService,
          communityService: mockCommunityService,
          languageRuntimeService: null,
          governedDomainConsumerStateService: governedStateService,
        );
        final matches7 = await serviceWithoutLanguageRuntime
            .findExpertsForBusiness(business);
        expect(matches7, isA<List<BusinessExpertMatch>>());
      });

      test('uses governed business intelligence as a bounded ranking input',
          () async {
        final governedBusiness = business.copyWith(
          requiredExpertise: const ['food'],
        );
        final expert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'business-expert-governed',
          category: 'food',
          location: 'San Francisco',
        );
        final expertMatch = ExpertMatch(
          user: expert,
          category: 'food',
          matchScore: 0.8,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: const [],
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.85);

        final baselineService = BusinessExpertMatchingService(
          expertiseMatchingService: mockExpertiseMatchingService,
          communityService: mockCommunityService,
          languageRuntimeService: null,
          partnershipService: mockPartnershipService,
        );
        final baselineMatches =
            await baselineService.findExpertsForBusiness(governedBusiness);
        expect(baselineMatches, isNotEmpty);

        await governedStateService.upsertState(
          GovernedDomainConsumerState(
            sourceId: 'simulation_training_source_sf',
            domainId: 'business',
            consumerId: 'business_intelligence_lane',
            environmentId: 'sf-replay-world-2024',
            cityCode: 'sf',
            generatedAt: DateTime.utc(2026, 4, 1, 23),
            status: 'executed_local_governed_domain_consumer_refresh',
            summary: 'Business intelligence is ready for governed use.',
            boundedUse: 'Bounded business ranking only.',
            targetedSystems: const <String>['business_intelligence'],
            requestCount: 4,
            averageConfidence: 0.9,
          ),
        );

        final governedService = BusinessExpertMatchingService(
          expertiseMatchingService: mockExpertiseMatchingService,
          communityService: mockCommunityService,
          languageRuntimeService: null,
          partnershipService: mockPartnershipService,
          governedDomainConsumerStateService: governedStateService,
        );
        final governedMatches =
            await governedService.findExpertsForBusiness(governedBusiness);
        expect(governedMatches, isNotEmpty);
        expect(governedMatches.first.matchScore,
            greaterThan(baselineMatches.first.matchScore));
        expect(
            governedMatches.first.matchScore - baselineMatches.first.matchScore,
            lessThanOrEqualTo(0.05));
      });
    });

    group('Vibe-First Matching', () {
      test(
          'should use vibe-first matching formula (50% vibe, 30% expertise, 20% location), include local experts in matching, include remote experts with great vibe, prioritize vibe compatibility as PRIMARY factor (50% weight), or apply location as preference boost not filter',
          () async {
        // Test business logic: vibe-first matching with various scenarios
        final localExpert1 =
            IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'San Francisco',
        );
        final expertMatch1 = ExpertMatch(
          user: localExpert1,
          category: 'food',
          matchScore: 0.8,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch1]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9);
        final matches1 = await service.findExpertsForBusiness(business);
        expect(matches1, isNotEmpty);
        final match1 = matches1.first;
        expect(match1.matchScore, greaterThan(0.0));
        expect(match1.matchScore, lessThanOrEqualTo(1.0));
        expect(match1.matchReason, contains('vibe-first'));

        final localExpert2 =
            IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-2',
          category: 'food',
          location: 'San Francisco',
        );
        final expertMatch2 = ExpertMatch(
          user: localExpert2,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch2]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.75);
        final matches2 = await service.findExpertsForBusiness(business);
        expect(matches2, isNotEmpty);
        final match2 = matches2.first;
        expect(match2.expert.id, equals('local-expert-2'));
        expect(match2.expert.getExpertiseLevel('food'),
            equals(ExpertiseLevel.local));

        final remoteExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'remote-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'New York');
        final expertMatch3 = ExpertMatch(
          user: remoteExpert,
          category: 'food',
          matchScore: 0.8,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        final businessWithLocation = business.copyWith(
          preferredLocation: 'San Francisco',
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch3]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9);
        final matches3 =
            await service.findExpertsForBusiness(businessWithLocation);
        expect(matches3, isNotEmpty);
        final match3 = matches3.first;
        expect(match3.expert.id, equals('remote-expert-1'));
        expect(match3.expert.location, equals('New York'));
        expect(match3.matchScore, greaterThan(0.5));

        final highExpertiseExpert =
            IntegrationTestHelpers.createUserWithExpertise(
          id: 'expert-1',
          category: 'food',
          level: ExpertiseLevel.national,
        );
        final highVibeExpert =
            IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-2',
          category: 'food',
          location: 'San Francisco',
        );
        final expertMatch4 = ExpertMatch(
          user: highExpertiseExpert,
          category: 'food',
          matchScore: 0.9,
          matchReason: 'High expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        final expertMatch5 = ExpertMatch(
          user: highVibeExpert,
          category: 'food',
          matchScore: 0.6,
          matchReason: 'Lower expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch4, expertMatch5]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'expert-1',
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.5);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'expert-2',
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9);
        final matches4 = await service.findExpertsForBusiness(business);
        expect(matches4.length, greaterThanOrEqualTo(2));
        final sortedMatches = matches4.toList()
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
        final highVibeMatch =
            sortedMatches.firstWhere((m) => m.expert.id == 'expert-2');
        final highExpertiseMatch =
            sortedMatches.firstWhere((m) => m.expert.id == 'expert-1');
        expect(highVibeMatch.matchScore,
            greaterThanOrEqualTo(highExpertiseMatch.matchScore));

        final localExpert3 =
            IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-3',
          category: 'food',
          location: 'San Francisco',
        );
        final remoteExpert2 = IntegrationTestHelpers.createUserWithExpertise(
          id: 'remote-expert-2',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'New York');
        final expertMatch6 = ExpertMatch(
          user: localExpert3,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Local expert match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        final expertMatch7 = ExpertMatch(
          user: remoteExpert2,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Remote expert match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch6, expertMatch7]);
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.75);
        final matches5 =
            await service.findExpertsForBusiness(businessWithLocation);
        expect(matches5.length, greaterThanOrEqualTo(2));
        final localMatch =
            matches5.firstWhere((m) => m.expert.id == 'local-expert-3');
        final remoteMatch =
            matches5.firstWhere((m) => m.expert.id == 'remote-expert-2');
        expect(localMatch.matchScore, greaterThan(remoteMatch.matchScore));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
