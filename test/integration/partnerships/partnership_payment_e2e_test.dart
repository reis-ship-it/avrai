import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/services/payment/revenue_split_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/payment/stripe_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/matching/vibe_compatibility_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_knot/services/knot/entity_knot_service.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../fixtures/integration_test_fixtures.dart';
import '../../fixtures/model_factories.dart';

// Mock dependencies
class MockStripeService extends Mock implements StripeService {}
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}
class MockBusinessService extends Mock implements BusinessService {}
class MockBusinessAccountService extends Mock implements BusinessAccountService {}

/// Partnership Payment End-to-End Integration Test
/// 
/// Agent 1: Backend & Integration (Week 8)
/// 
/// Tests complete partnership payment workflow end-to-end:
/// 1. Create partnership
/// 2. Approve partnership
/// 3. Lock revenue split
/// 4. Process payment
/// 5. Distribute payments to partners
/// 
/// **Full Workflow:**
/// - Complete partnership creation → payment → distribution flow
/// - Tests all integration points
/// - Validates revenue splits and payouts
void main() {
  group('Partnership Payment End-to-End Integration Tests', () {
    late PartnershipService partnershipService;
    late PaymentService paymentService;
    late RevenueSplitService revenueSplitService;
    late MockStripeService mockStripeService;
    late MockExpertiseEventService mockEventService;
    late MockBusinessService mockBusinessService;
    
    setUp(() {
      mockStripeService = MockStripeService();
      mockEventService = MockExpertiseEventService();
      mockBusinessService = MockBusinessService();
      
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
      
      revenueSplitService = RevenueSplitService(
        partnershipService: partnershipService,
      );
      
      paymentService = PaymentService(
        mockStripeService,
        mockEventService,
        partnershipService: partnershipService,
        revenueSplitService: revenueSplitService,
      );
      
      // Setup Stripe mock
      // Note: For getters in mocktail, we access the getter directly
      when(() => mockStripeService.isInitialized).thenReturn(true);
      when(() => mockStripeService.initializeStripe())
          .thenAnswer((_) async {
            return;
          });
    });
    
    tearDown(() {
      reset(mockStripeService);
      reset(mockEventService);
      reset(mockBusinessService);
    });
    
    group('Full Partnership Payment Workflow', () {
      test('should complete full partnership payment workflow', () async {
        // ============================================
        // STEP 1: Create Event
        // ============================================
        final scenario = IntegrationTestFixtures.eventHostingScenario();
        final event = scenario['event'] as ExpertiseEvent;
        final host = scenario['host'] as UnifiedUser;
        final attendee = ModelFactories.createTestUser();
        
        // Mock getEventById to return event (called multiple times in createPartnership and checkPartnershipEligibility)
        when(() => mockEventService.getEventById(any()))
            .thenAnswer((_) async => event);
        
        // ============================================
        // STEP 2: Create Partnership
        // ============================================
        final business = IntegrationTestHelpers.createTestBusinessAccount(
          id: 'business-1',
          name: 'Test Restaurant',
          isVerified: true,
        );
        
        // Mock getBusinessById to return business (called multiple times in createPartnership and checkPartnershipEligibility)
        when(() => mockBusinessService.getBusinessById(any()))
            .thenAnswer((_) async => business);
        
        final partnership = await partnershipService.createPartnership(
          eventId: event.id,
          userId: host.id,
          businessId: business.id,
          vibeCompatibilityScore: 0.80, // 80% compatibility
        );
        
        expect(partnership, isNotNull);
        expect(partnership.status, equals(PartnershipStatus.proposed));
        
        // ============================================
        // STEP 3: Approve Partnership
        // ============================================
        final userApproved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: host.id,
        );
        
        expect(userApproved.userApproved, isTrue);
        
        final businessApproved = await partnershipService.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: business.id,
        );
        
        expect(businessApproved.isApproved, isTrue);
        expect(businessApproved.status, equals(PartnershipStatus.locked));
        
        // ============================================
        // STEP 4: Create Revenue Split
        // ============================================
        // Note: partnershipService is a real instance, so getPartnershipById will work
        // with the partnership we just created and approved (stored in in-memory map)
        final revenueSplit = await revenueSplitService.calculateFromPartnership(
          partnershipId: businessApproved.id,
          totalAmount: 100.00,
          ticketsSold: 1,
        );
        
        expect(revenueSplit, isNotNull);
        expect(revenueSplit.partnershipId, equals(partnership.id));
        expect(revenueSplit.parties.length, equals(2)); // User + Business
        
        // ============================================
        // STEP 5: Lock Revenue Split (Pre-Event)
        // ============================================
        final lockedSplit = await revenueSplitService.lockSplit(
          revenueSplitId: revenueSplit.id,
          lockedBy: host.id,
        );
        
        expect(lockedSplit.isLocked, isTrue);
        expect(lockedSplit.lockedBy, equals(host.id));
        
        // ============================================
        // STEP 6: Process Payment
        // ============================================
        // Note: partnershipService and revenueSplitService are real instances,
        // so they will use the actual partnerships and splits we created
        // No need to mock - the real services will work with the in-memory data
        
        await paymentService.initialize();
        
        final paymentResult = await paymentService.purchaseEventTicket(
          eventId: event.id,
          userId: attendee.id,
          ticketPrice: event.price!,
          quantity: 1,
        );
        
        expect(paymentResult.isSuccess, isTrue);
        expect(paymentResult.revenueSplit, isNotNull);
        expect(paymentResult.revenueSplit!.parties.length, equals(2));
        
        // ============================================
        // STEP 7: Distribute Payments
        // ============================================
        // Note: revenueSplitService is a real instance, so getRevenueSplit will work
        // with the split we just created and locked (stored in in-memory map)
        final payoutAmounts = await revenueSplitService.distributePayments(
          revenueSplitId: lockedSplit.id,
          eventEndTime: event.endTime,
        );
        
        expect(payoutAmounts.length, equals(2));
        expect(payoutAmounts[host.id], isNotNull);
        expect(payoutAmounts[business.id], isNotNull);
        
        // ============================================
        // VERIFY: Complete Workflow
        // ============================================
        // Partnership created and approved ✅
        // Revenue split created and locked ✅
        // Payment processed ✅
        // Payments distributed ✅
        
        expect(businessApproved.isLocked, isTrue);
        expect(lockedSplit.isLocked, isTrue);
        expect(paymentResult.isSuccess, isTrue);
        expect(payoutAmounts.isNotEmpty, isTrue);
      });
      
      test('should handle 3-party partnership correctly', () async {
        // Arrange: User + Business + Sponsor
        final event = IntegrationTestHelpers.createTestEvent(
          host: IntegrationTestHelpers.createExpertUser(),
        );
        
        // Create N-way split with 3 parties
        final revenueSplit = RevenueSplit.nWay(
          id: 'split-1',
          eventId: event.id,
          totalAmount: 1000.00,
          ticketsSold: 10,
          parties: const [
            SplitParty(
              partyId: 'user-1',
              type: SplitPartyType.user,
              percentage: 40.0,
            ),
            SplitParty(
              partyId: 'business-1',
              type: SplitPartyType.business,
              percentage: 35.0,
            ),
            SplitParty(
              partyId: 'sponsor-1',
              type: SplitPartyType.sponsor,
              percentage: 25.0,
            ),
          ],
        );
        
        // Assert
        expect(revenueSplit.parties.length, equals(3));
        expect(revenueSplit.isValid, isTrue);
        
        // Verify split amounts
        // Calculation: $1000 - $100 (10% platform) - $32 (2.9% + $0.30*10 tickets) = $868
        final splitAmount = revenueSplit.splitAmount; // After fees
        expect(splitAmount, closeTo(868.00, 0.01)); // $1000 - $100 - $32
        
        // Verify party amounts (percentages of $868)
        expect(revenueSplit.parties[0].amount, closeTo(347.20, 0.01)); // 40% of $868
        expect(revenueSplit.parties[1].amount, closeTo(303.80, 0.01)); // 35% of $868
        expect(revenueSplit.parties[2].amount, closeTo(217.00, 0.01)); // 25% of $868
      });
    });
  });
}

