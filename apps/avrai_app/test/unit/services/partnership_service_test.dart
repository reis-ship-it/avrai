import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/business/business_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import 'package:avrai_core/models/payment/revenue_split.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'partnership_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([ExpertiseEventService, BusinessService])
void main() {
  if (!di.sl.isRegistered<AgentIdService>()) {
    di.sl.registerLazySingleton<AgentIdService>(() => AgentIdService());
  }

  final VibeCompatibilityService vibeCompatibilityService =
      QuantumKnotVibeCompatibilityService(
    personalityLearning: PersonalityLearning(),
    personalityKnotService: PersonalityKnotService(),
    entityKnotService: EntityKnotService(),
  );

  group('PartnershipService Tests', () {
    late PartnershipService service;
    late MockExpertiseEventService mockEventService;
    late MockBusinessService mockBusinessService;
    late UnifiedUser testUser;
    late BusinessAccount testBusiness;
    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockBusinessService = MockBusinessService();

      service = PartnershipService(
        eventService: mockEventService,
        businessService: mockBusinessService,
        vibeCompatibilityService: vibeCompatibilityService,
      );

      // Create test user with Local-level expertise (can host events)
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Test User',
      );
      // Add expertise to make user eligible (expertiseMap uses string values)
      testUser = testUser.copyWith(
        expertiseMap: {
          'Coffee': 'city',
        },
      );

      // Create test business
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        isVerified: true,
        isActive: true,
        categories: const ['Coffee'],
        location: 'San Francisco',
      );

      // Create test event
      testEvent = ExpertiseEvent(
        id: 'event-123',
        title: 'Test Event',
        description: 'A test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: testUser,
        startTime: DateTime.now().add(const Duration(days: 7)),
        endTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Partnership creation tests focus on business logic (validation, agreement handling), not property assignment

    group('createPartnership', () {
      test(
          'should create partnership with valid inputs and agreement terms, or throw exception for invalid inputs (event not found, business not found, not eligible, compatibility below threshold)',
          () async {
        // Test business logic: partnership creation with validation and agreement handling
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        // Test successful creation
        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );
        expect(partnership, isA<EventPartnership>());
        expect(partnership.status, equals(PartnershipStatus.proposed));
        expect(partnership.vibeCompatibilityScore, equals(0.75));

        // Test with agreement terms (use different event ID since service only allows one partnership per event)
        final revenueSplit = [
          const SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 50.0,
              name: 'User'),
          const SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 50.0,
              name: 'Business'),
        ];
        final agreement = PartnershipAgreement(
          id: 'agreement-1',
          partnershipId: 'partnership-1',
          terms: {'revenueSplit': revenueSplit.map((p) => p.toJson()).toList()},
          agreedAt: DateTime.now(),
          agreedBy: 'user-123',
        );
        // Use different event ID to avoid "Partnership not eligible" error (one partnership per event)
        when(mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent.copyWith(id: 'event-456'));
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);
        final partnershipWithAgreement = await service.createPartnership(
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          agreement: agreement,
          vibeCompatibilityScore: 0.80,
        );
        expect(partnershipWithAgreement.agreement, isNotNull);

        // Test error cases (use different event IDs to avoid "Partnership not eligible" from previous successful creation)
        // Error case 1: Event not found
        when(mockEventService.getEventById('event-error-1'))
            .thenAnswer((_) async => null);
        await expectLater(
          service.createPartnership(
            eventId: 'event-error-1',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('Event not found'))),
        );

        // Error case 2: Business not found
        when(mockEventService.getEventById('event-error-2'))
            .thenAnswer((_) async => testEvent.copyWith(id: 'event-error-2'));
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => null);
        await expectLater(
          service.createPartnership(
            eventId: 'event-error-2',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('Business not found'))),
        );

        // Error case 3: Business not verified
        final unverifiedBusiness = testBusiness.copyWith(isVerified: false);
        when(mockEventService.getEventById('event-error-3'))
            .thenAnswer((_) async => testEvent.copyWith(id: 'event-error-3'));
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => unverifiedBusiness);
        await expectLater(
          service.createPartnership(
            eventId: 'event-error-3',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.75,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Partnership not eligible'))),
        );

        // Error case 4: Compatibility below threshold
        when(mockEventService.getEventById('event-error-4'))
            .thenAnswer((_) async => testEvent.copyWith(id: 'event-error-4'));
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);
        await expectLater(
          service.createPartnership(
            eventId: 'event-error-4',
            userId: 'user-123',
            businessId: 'business-123',
            vibeCompatibilityScore: 0.65, // Below 70% threshold
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Compatibility below 70% threshold'))),
        );
      });
    });

    group('getPartnershipsForEvent', () {
      test('should return partnerships for event or empty list if none exist',
          () async {
        // Test business logic: partnership retrieval with empty case handling
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        final partnerships = await service.getPartnershipsForEvent('event-123');
        expect(partnerships, isNotEmpty);
        expect(partnerships.first.id, equals(partnership.id));

        expect(await service.getPartnershipsForEvent('event-none'), isEmpty);
      });
    });

    group('getPartnershipById', () {
      test('should return partnership by ID or null if not found', () async {
        // Test business logic: partnership retrieval with existence checking
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final created = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        final partnership = await service.getPartnershipById(created.id);
        expect(partnership, isNotNull);
        expect(partnership?.id, equals(created.id));

        expect(await service.getPartnershipById('nonexistent-id'), isNull);
      });
    });

    group('updatePartnershipStatus', () {
      test(
          'should update partnership status correctly, or throw exception if partnership not found or status transition is invalid',
          () async {
        // Test business logic: status updates with validation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        final updated = await service.updatePartnershipStatus(
          partnershipId: partnership.id,
          status: PartnershipStatus.negotiating,
        );
        expect(updated.status, equals(PartnershipStatus.negotiating));
        expect(updated.updatedAt.isAfter(partnership.updatedAt), isTrue);

        // Test error cases
        expect(
          () => service.updatePartnershipStatus(
            partnershipId: 'nonexistent-id',
            status: PartnershipStatus.negotiating,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Partnership not found'))),
        );

        expect(
          () => service.updatePartnershipStatus(
            partnershipId: partnership.id,
            status:
                PartnershipStatus.completed, // Invalid transition from proposed
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Invalid status transition'))),
        );
      });
    });

    group('approvePartnership', () {
      test(
          'should approve partnership by user or business, lock when both approve, or throw exception if invalid approver',
          () async {
        // Test business logic: partnership approval with locking and validation
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        final partnership = await service.createPartnership(
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );

        // Test user approval
        final userApproved = await service.approvePartnership(
          partnershipId: partnership.id,
          approvedBy: 'user-123',
        );
        expect(userApproved.userApproved, isTrue);
        expect(userApproved.businessApproved, isFalse);

        // Test business approval - use different event ID (service only allows one partnership per event)
        final testEvent2 = testEvent.copyWith(id: 'event-456');
        when(mockEventService.getEventById('event-456'))
            .thenAnswer((_) async => testEvent2);
        final partnership2 = await service.createPartnership(
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );
        final businessApproved = await service.approvePartnership(
          partnershipId: partnership2.id,
          approvedBy: 'business-123',
        );
        expect(businessApproved.userApproved, isFalse);
        expect(businessApproved.businessApproved, isTrue);

        // Test locking when both approve - use different event ID
        final testEvent3 = testEvent.copyWith(id: 'event-789');
        when(mockEventService.getEventById('event-789'))
            .thenAnswer((_) async => testEvent3);
        final partnership3 = await service.createPartnership(
          eventId: 'event-789',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );
        await service.approvePartnership(
            partnershipId: partnership3.id, approvedBy: 'user-123');
        final locked = await service.approvePartnership(
            partnershipId: partnership3.id, approvedBy: 'business-123');
        expect(locked.userApproved, isTrue);
        expect(locked.businessApproved, isTrue);
        expect(locked.status, equals(PartnershipStatus.locked));

        // Test invalid approver - use different event ID
        final testEvent4 = testEvent.copyWith(id: 'event-999');
        when(mockEventService.getEventById('event-999'))
            .thenAnswer((_) async => testEvent4);
        final partnership4 = await service.createPartnership(
          eventId: 'event-999',
          userId: 'user-123',
          businessId: 'business-123',
          vibeCompatibilityScore: 0.75,
        );
        expect(
          () => service.approvePartnership(
              partnershipId: partnership4.id, approvedBy: 'invalid-user'),
          throwsA(isA<Exception>().having(
              (e) => e.toString(), 'message', contains('Invalid approver'))),
        );
      });
    });

    group('checkPartnershipEligibility', () {
      test(
          'should return true for eligible partnership, or false if event not found, event already started, or business not verified',
          () async {
        // Test business logic: eligibility checking with various failure cases
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => testBusiness);
        when(mockBusinessService.checkBusinessEligibility('business-123'))
            .thenAnswer((_) async => true);

        expect(
          await service.checkPartnershipEligibility(
            userId: 'user-123',
            businessId: 'business-123',
            eventId: 'event-123',
          ),
          isTrue,
        );

        // Test failure cases
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => null);
        expect(
          await service.checkPartnershipEligibility(
            userId: 'user-123',
            businessId: 'business-123',
            eventId: 'event-123',
          ),
          isFalse,
        );

        final pastEvent = testEvent.copyWith(
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          endTime: DateTime.now().subtract(const Duration(hours: 23)),
        );
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => pastEvent);
        expect(
          await service.checkPartnershipEligibility(
            userId: 'user-123',
            businessId: 'business-123',
            eventId: 'event-123',
          ),
          isFalse,
        );

        final unverifiedBusiness = testBusiness.copyWith(isVerified: false);
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        when(mockBusinessService.getBusinessById('business-123'))
            .thenAnswer((_) async => unverifiedBusiness);
        expect(
          await service.checkPartnershipEligibility(
            userId: 'user-123',
            businessId: 'business-123',
            eventId: 'event-123',
          ),
          isFalse,
        );
      });
    });

    group('calculateVibeCompatibility', () {
      test('should return compatibility score', () async {
        // Act
        final compatibility = await service.calculateVibeCompatibility(
          userId: 'user-123',
          businessId: 'business-123',
        );

        // Assert
        expect(compatibility, isA<double>());
        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
