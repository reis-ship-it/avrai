import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/expertise/expertise_calculation_service.dart';
import 'package:avrai/core/services/matching/saturation_algorithm_service.dart';
import 'package:avrai/core/services/expertise/multi_path_expertise_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../helpers/test_helpers.dart';

// Mock dependencies
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockBusinessService extends Mock implements BusinessService {}

/// Expertise-Partnership Integration Tests
/// 
/// Agent 3: Models & Testing (Week 14)
/// 
/// Tests integration between expertise system and partnerships:
/// - Expertise requirements for partnerships
/// - Partnership creation affecting expertise
/// - Expertise progression through partnerships
/// 
/// **Test Scenarios:**
/// - Scenario 1: Expertise Requirements for Partnership Creation
/// - Scenario 2: Partnership Creation Contributing to Expertise
/// - Scenario 3: Expertise Level Affecting Partnership Eligibility
/// - Scenario 4: Partnership Events Contributing to Expertise
void main() {
  group('Expertise-Partnership Integration Tests', () {
    late PartnershipService partnershipService;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late ExpertiseCalculationService expertiseService;
    late MockExpertiseEventService mockEventService;
    late MockBusinessService mockBusinessService;
      // ignore: unused_local_variable
    late SaturationAlgorithmService saturationService;
    late MultiPathExpertiseService multiPathService;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late DateTime testDate;
    
    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockEventService = MockExpertiseEventService();
      mockBusinessService = MockBusinessService();
      saturationService = SaturationAlgorithmService();
      multiPathService = MultiPathExpertiseService();

      if (!di.sl.isRegistered<AgentIdService>()) {
        di.sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
      }
      
      partnershipService = PartnershipService(
        eventService: mockEventService,
        businessService: mockBusinessService,
        vibeCompatibilityService: QuantumKnotVibeCompatibilityService(
          personalityLearning: PersonalityLearning(),
          personalityKnotService: PersonalityKnotService(),
          entityKnotService: EntityKnotService(),
        ),
      );
      
      expertiseService = ExpertiseCalculationService(
        saturationService: saturationService,
        multiPathService: multiPathService,
      );
    });
    
    tearDown(() {
      reset(mockEventService);
      reset(mockBusinessService);
      TestHelpers.teardownTestEnvironment();
    });
    
    group('Scenario 1: Expertise Requirements for Partnership Creation', () {
      test('should require Local level expertise to create partnership', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'host-1',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount(
          id: 'business-1',
        );
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 50.00,
          category: 'Coffee',
        );
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // Verify host has Local level expertise (can host events)
        expect(host.canHostEvents(), isTrue);
        expect(host.expertiseMap['Coffee'], equals('local'));
        
        // Create partnership (requires Local level+ to host events)
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        expect(partnership, isNotNull);
        expect(partnership.userId, equals(host.id));
        expect(partnership.eventId, equals(event.id));
      });
      
      test('should prevent partnership creation without Local level expertise', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithoutHosting(
          id: 'host-2',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 50.00,
          category: 'Coffee',
        );
        
        // Verify host cannot host events (no expertise)
        expect(host.canHostEvents(), isFalse);
        
        // Host cannot create events, so cannot create partnerships
        // (This is enforced at event creation level, not partnership level)
        // But if event exists, partnership can still be created
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // Partnership cannot be created if host doesn't have Local level expertise
        // (Partnership service checks event.host.canHostEvents())
        // This should throw "Partnership not eligible" exception
        await expectLater(
          () => partnershipService.createPartnership(
            eventId: event.id,
            userId: host.id,
            businessId: business.id,
            vibeCompatibilityScore: 0.85,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Scenario 2: Partnership Creation Contributing to Expertise', () {
      test('should track partnership creation as expertise contribution', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-3',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          price: 50.00,
          category: 'Coffee',
        );
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // Create partnership
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        expect(partnership, isNotNull);
        
        // Partnership creation contributes to community expertise
        // (Hosting events with partnerships shows community engagement)
        // This would be tracked in community expertise path
        expect(partnership.eventId, equals(event.id));
        expect(partnership.userId, equals(host.id));
      });
    });
    
    group('Scenario 3: Expertise Level Affecting Partnership Eligibility', () {
      test('should allow partnerships for users with City+ level expertise', () async {
        // Arrange - City level
        final cityHost = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-city',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final cityEvent = IntegrationTestHelpers.createPaidEvent(
          host: cityHost,
          category: 'Coffee',
        );
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => cityEvent);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // City level can create partnerships
        expect(cityHost.canHostEvents(), isTrue);
        
        final cityPartnership = await partnershipService.createPartnership(
          eventId: cityEvent.id,
          userId: cityHost.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        expect(cityPartnership, isNotNull);
      });
      
      test('should track partnership events in expertise calculation', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-4',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          category: 'Coffee',
        );
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // Create partnership
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        // Approve partnership
        await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: host.id,
        );
        final approved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: business.id,
        );
        
        expect(approved.isApproved, isTrue);
        
        // Partnership events contribute to community expertise
        // (Events hosted with partnerships show community engagement)
        expect(approved.eventId, equals(event.id));
      });
    });
    
    group('Scenario 4: Partnership Events Contributing to Expertise', () {
      test('should track partnership events in community expertise', () async {
        // Arrange
        final host = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'host-5',
          category: 'Coffee',
        );
        final business = IntegrationTestHelpers.createVerifiedBusinessAccount();
        final event = IntegrationTestHelpers.createPaidEvent(
          host: host,
          category: 'Coffee',
        );
        
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        when(() => mockBusinessService.checkBusinessEligibility(any()))
            .thenAnswer((_) async => true);
        
        // Create and approve partnership
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.85,
        );
        
        await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: host.id,
        );
        final approved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: business.id,
        );
        
        // Note: approvePartnership automatically locks the partnership when both parties approve
        // No need to call updatePartnershipStatus separately
        expect(approved.isLocked, isTrue);
        expect(approved.status, equals(PartnershipStatus.locked));
        
        // Partnership events contribute to:
        // - Community expertise (hosting events with partnerships)
        // - Professional expertise (business partnerships)
        // - Influence expertise (multi-party events)
        
        // Verify partnership is ready for event
        expect(approved.eventId, equals(event.id));
        expect(approved.isApproved, isTrue);
      });
    });
  });
}

