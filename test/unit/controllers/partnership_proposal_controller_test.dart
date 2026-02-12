import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/partnership_proposal_controller.dart';
import 'package:avrai/core/services/partnerships/partnership_service.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';

import 'partnership_proposal_controller_test.mocks.dart';

@GenerateMocks([
  PartnershipService,
  BusinessService,
])
void main() {
  group('PartnershipProposalController', () {
    late PartnershipProposalController controller;
    late MockPartnershipService mockPartnershipService;
    late MockBusinessService mockBusinessService;
    final DateTime now = DateTime.now();

    setUp(() {
      mockPartnershipService = MockPartnershipService();
      mockBusinessService = MockBusinessService();

      controller = PartnershipProposalController(
        partnershipService: mockPartnershipService,
        businessService: mockBusinessService,
      );
    });

    final testBusiness = BusinessAccount(
      id: 'business_123',
      name: 'Test Business',
      email: 'business@test.com',
      businessType: 'Restaurant',
      isVerified: true,
      createdBy: 'owner_123',
      createdAt: now,
      updatedAt: now,
    );

    final testPartnership = EventPartnership(
      id: 'partnership_123',
      eventId: 'event_123',
      userId: 'user_456',
      businessId: 'business_123',
      status: PartnershipStatus.proposed,
      vibeCompatibilityScore: 0.85,
      createdAt: now,
      updatedAt: now,
    );

    group('validate', () {
      test('should return valid result for valid input', () {
        final data = PartnershipProposalData(
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue', 'Marketing'],
        );
        final input = PartnershipProposalInput(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_123',
          data: data,
        );

        final result = controller.validate(input);

        expect(result.isValid, isTrue);
      });

      test('should return invalid result for empty eventId', () {
        final data = PartnershipProposalData();
        final input = PartnershipProposalInput(
          eventId: '',
          proposerId: 'user_456',
          businessId: 'business_123',
          data: data,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['eventId'], isNotNull);
      });

      test('should return invalid result for revenue split not totaling 100%', () {
        final revenueSplit = RevenueSplit.nWay(
          id: 'split_123',
          eventId: 'event_123',
          totalAmount: 1000.0,
          ticketsSold: 10,
          parties: const [
            SplitParty(
              partyId: 'user_456',
              type: SplitPartyType.user,
              percentage: 60.0,
            ),
            SplitParty(
              partyId: 'business_123',
              type: SplitPartyType.business,
              percentage: 30.0, // Total: 90%, not 100%
            ),
          ],
        );
        final data = PartnershipProposalData(
          revenueSplit: revenueSplit,
        );
        final input = PartnershipProposalInput(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_123',
          data: data,
        );

        final result = controller.validate(input);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['revenueSplit'], isNotNull);
      });
    });

    group('createProposal', () {
      test('should successfully create partnership proposal', () async {
        final data = PartnershipProposalData(
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
          vibeCompatibilityScore: 0.85,
        );

        when(mockBusinessService.getBusinessById('business_123'))
            .thenAnswer((_) async => testBusiness);
        when(mockPartnershipService.createPartnership(
          eventId: 'event_123',
          userId: 'user_456',
          businessId: 'business_123',
          agreement: null,
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
          venueLocation: null,
          vibeCompatibilityScore: 0.85,
        )).thenAnswer((_) async => testPartnership);

        final result = await controller.createProposal(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_123',
          data: data,
        );

        expect(result.success, isTrue);
        expect(result.partnership, isNotNull);
        expect(result.partnership?.id, equals('partnership_123'));

        verify(mockBusinessService.getBusinessById('business_123')).called(1);
        verify(mockPartnershipService.createPartnership(
          eventId: 'event_123',
          userId: 'user_456',
          businessId: 'business_123',
          agreement: null,
          type: PartnershipType.eventBased,
          sharedResponsibilities: ['Venue'],
          venueLocation: null,
          vibeCompatibilityScore: 0.85,
        )).called(1);
      });

      test('should return failure when business not found', () async {
        final data = PartnershipProposalData();

        when(mockBusinessService.getBusinessById('business_123'))
            .thenAnswer((_) async => null);

        final result = await controller.createProposal(
          eventId: 'event_123',
          proposerId: 'user_456',
          businessId: 'business_123',
          data: data,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('BUSINESS_NOT_FOUND'));
        verifyNever(mockPartnershipService.createPartnership(
          eventId: anyNamed('eventId'),
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
          agreement: anyNamed('agreement'),
          type: anyNamed('type'),
          sharedResponsibilities: anyNamed('sharedResponsibilities'),
          venueLocation: anyNamed('venueLocation'),
          vibeCompatibilityScore: anyNamed('vibeCompatibilityScore'),
        ));
      });
    });

    group('acceptProposal', () {
      test('should successfully accept partnership proposal (user)', () async {
        when(mockPartnershipService.getPartnershipById('partnership_123'))
            .thenAnswer((_) async => testPartnership);
        when(mockPartnershipService.approvePartnership(
          partnershipId: 'partnership_123',
          approvedBy: 'user_456',
        )).thenAnswer((_) async => testPartnership.copyWith(
          userApproved: true,
        ));

        final result = await controller.acceptProposal(
          partnershipId: 'partnership_123',
          acceptorId: 'user_456',
          isBusiness: false,
        );

        expect(result.success, isTrue);
        expect(result.partnership, isNotNull);

        verify(mockPartnershipService.getPartnershipById('partnership_123')).called(1);
        verify(mockPartnershipService.approvePartnership(
          partnershipId: 'partnership_123',
          approvedBy: 'user_456',
        )).called(1);
      });

      test('should return failure when partnership not found', () async {
        when(mockPartnershipService.getPartnershipById('partnership_123'))
            .thenAnswer((_) async => null);

        final result = await controller.acceptProposal(
          partnershipId: 'partnership_123',
          acceptorId: 'user_456',
          isBusiness: false,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PARTNERSHIP_NOT_FOUND'));
        verifyNever(mockPartnershipService.approvePartnership(
          partnershipId: anyNamed('partnershipId'),
          approvedBy: anyNamed('approvedBy'),
        ));
      });

      test('should return failure when user not authorized', () async {
        when(mockPartnershipService.getPartnershipById('partnership_123'))
            .thenAnswer((_) async => testPartnership);

        final result = await controller.acceptProposal(
          partnershipId: 'partnership_123',
          acceptorId: 'unauthorized_user',
          isBusiness: false,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PERMISSION_DENIED'));
        verifyNever(mockPartnershipService.approvePartnership(
          partnershipId: anyNamed('partnershipId'),
          approvedBy: anyNamed('approvedBy'),
        ));
      });
    });

    group('rejectProposal', () {
      test('should successfully reject partnership proposal', () async {
        when(mockPartnershipService.getPartnershipById('partnership_123'))
            .thenAnswer((_) async => testPartnership);
        when(mockPartnershipService.updatePartnershipStatus(
          partnershipId: 'partnership_123',
          status: PartnershipStatus.cancelled,
        )).thenAnswer((_) async => testPartnership.copyWith(
          status: PartnershipStatus.cancelled,
        ));

        final result = await controller.rejectProposal(
          partnershipId: 'partnership_123',
          rejectorId: 'user_456',
          isBusiness: false,
          reason: 'Not interested',
        );

        expect(result.success, isTrue);
        expect(result.partnership?.status, equals(PartnershipStatus.cancelled));

        verify(mockPartnershipService.getPartnershipById('partnership_123')).called(1);
        verify(mockPartnershipService.updatePartnershipStatus(
          partnershipId: 'partnership_123',
          status: PartnershipStatus.cancelled,
        )).called(1);
      });

      test('should return failure when partnership not found', () async {
        when(mockPartnershipService.getPartnershipById('partnership_123'))
            .thenAnswer((_) async => null);

        final result = await controller.rejectProposal(
          partnershipId: 'partnership_123',
          rejectorId: 'user_456',
          isBusiness: false,
        );

        expect(result.success, isFalse);
        expect(result.errorCode, equals('PARTNERSHIP_NOT_FOUND'));
        verifyNever(mockPartnershipService.updatePartnershipStatus(
          partnershipId: anyNamed('partnershipId'),
          status: anyNamed('status'),
        ));
      });
    });

    group('rollback', () {
      test('should cancel partnership on rollback', () async {
        final result = PartnershipProposalResult.success(
          partnership: testPartnership,
        );

        when(mockPartnershipService.updatePartnershipStatus(
          partnershipId: 'partnership_123',
          status: PartnershipStatus.cancelled,
        )).thenAnswer((_) async => testPartnership.copyWith(
          status: PartnershipStatus.cancelled,
        ));

        await controller.rollback(result);

        verify(mockPartnershipService.updatePartnershipStatus(
          partnershipId: 'partnership_123',
          status: PartnershipStatus.cancelled,
        )).called(1);
      });

      test('should not throw when rollback is called with failure result', () async {
        final result = PartnershipProposalResult.failure(
          error: 'Failed',
          errorCode: 'ERROR',
        );

        await controller.rollback(result);
        verifyNever(mockPartnershipService.updatePartnershipStatus(
          partnershipId: anyNamed('partnershipId'),
          status: anyNamed('status'),
        ));
      });
    });
  });
}

