import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/fraud/dispute_resolution_service.dart';
import 'package:avrai/core/services/expertise/expertise_event_service.dart';
import 'package:avrai/core/services/payment/refund_service.dart';
import 'package:avrai/core/models/disputes/dispute.dart';
import 'package:avrai/core/models/disputes/dispute_type.dart';
import 'package:avrai/core/models/disputes/dispute_status.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';

import 'dispute_resolution_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([
  ExpertiseEventService,
  RefundService,
])
void main() {
  group('DisputeResolutionService', () {
    late DisputeResolutionService service;
    late MockExpertiseEventService mockEventService;
    late MockRefundService mockRefundService;

    late ExpertiseEvent testEvent;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockRefundService = MockRefundService();

      // Mock getEventById to return null by default (event not found)
      // Tests can override this if they need specific events
      when(mockEventService.getEventById(any))
          .thenAnswer((_) async => null);

      service = DisputeResolutionService(
        eventService: mockEventService,
        refundService: mockRefundService,
      );

      testEvent = ExpertiseEvent(
        id: 'event-123',
        host: UnifiedUser(
          id: 'host-123',
          email: 'host@example.com',
          displayName: 'Test Host',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        title: 'Test Event',
        category: 'General',
        description: 'Test Description',
        startTime: DateTime.now().add(const Duration(days: 5)),
        endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
        maxAttendees: 50,
        attendeeCount: 10,
        eventType: ExpertiseEventType.workshop,
        isPaid: true,
        price: 25.00,
        location: 'Test Location',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    // Removed: Property assignment tests
    // Dispute resolution tests focus on business logic (dispute submission, review, resolution), not property assignment

    group('submitDispute', () {
      test(
          'should create dispute successfully or include evidence URLs if provided',
          () async {
        // Test business logic: dispute submission
        final dispute1 = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );
        expect(dispute1, isA<Dispute>());
        expect(dispute1.eventId, equals('event-123'));
        expect(dispute1.reporterId, equals('user-456'));
        expect(dispute1.reportedId, equals('user-789'));
        expect(dispute1.type, equals(DisputeType.payment));
        expect(dispute1.status, equals(DisputeStatus.pending));

        final dispute2 = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
          evidenceUrls: ['https://example.com/evidence1.jpg'],
        );
        expect(dispute2.evidenceUrls, hasLength(1));
        expect(dispute2.evidenceUrls,
            contains('https://example.com/evidence1.jpg'));
      });
    });

    group('reviewDispute', () {
      test('should update dispute status to inReview', () async {
        // Test business logic: dispute review assignment
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );
        final reviewed = await service.reviewDispute(
          disputeId: dispute.id,
          adminId: 'admin-123',
        );
        expect(reviewed.status, equals(DisputeStatus.inReview));
        expect(reviewed.assignedAdminId, equals('admin-123'));
        expect(reviewed.assignedAt, isNotNull);
      });
    });

    group('attemptAutomatedResolution', () {
      test('should auto-resolve payment disputes when possible', () async {
        // Test business logic: automated dispute resolution
        when(mockEventService.getEventById('event-123'))
            .thenAnswer((_) async => testEvent);
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Refund disagreement',
        );
        final resolved = await service.attemptAutomatedResolution(dispute.id);
        expect(resolved, isNotNull);
        expect(resolved?.status, equals(DisputeStatus.resolved));
        expect(resolved?.resolution, isNotNull);
      });
    });

    group('resolveDispute', () {
      test('should resolve dispute with resolution details', () async {
        // Test business logic: manual dispute resolution
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
        );
        final resolved = await service.resolveDispute(
          disputeId: dispute.id,
          adminId: 'admin-123',
          resolution: 'Issue resolved with full refund',
          refundAmount: 25.00,
        );
        expect(resolved.status, equals(DisputeStatus.resolved));
        expect(resolved.resolution, equals('Issue resolved with full refund'));
        expect(resolved.refundAmount, equals(25.00));
        expect(resolved.resolvedAt, isNotNull);
      });
    });

    group('getDispute', () {
      test(
          'should return dispute if exists or return null if dispute not found',
          () async {
        // Test business logic: dispute retrieval
        final dispute = await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue',
        );
        final retrieved1 = await service.getDispute(dispute.id);
        expect(retrieved1, isNotNull);
        expect(retrieved1?.id, equals(dispute.id));

        final retrieved2 = await service.getDispute('non-existent');
        expect(retrieved2, isNull);
      });
    });

    group('getDisputesForEvent', () {
      test('should return all disputes for event', () async {
        // Test business logic: dispute retrieval by event
        await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-456',
          reportedId: 'user-789',
          type: DisputeType.payment,
          description: 'Payment issue 1',
        );
        await service.submitDispute(
          eventId: 'event-123',
          reporterId: 'user-999',
          reportedId: 'user-789',
          type: DisputeType.event,
          description: 'Event quality issue',
        );
        final disputes = await service.getDisputesForEvent('event-123');
        expect(disputes, hasLength(2));
        expect(disputes.every((d) => d.eventId == 'event-123'), isTrue);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
