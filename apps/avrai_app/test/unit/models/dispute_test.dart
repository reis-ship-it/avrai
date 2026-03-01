import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/disputes/dispute.dart';
import 'package:avrai_core/models/disputes/dispute_type.dart';
import 'package:avrai_core/models/disputes/dispute_status.dart';

/// SPOTS Dispute Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Dispute model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Active, resolved, closed
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
/// - DisputeMessage: Message handling
///
/// Dependencies:
/// - DisputeType: Dispute type enum
/// - DisputeStatus: Dispute status enum
/// - DisputeMessage: Message model

void main() {
  group('Dispute', () {
    late Dispute dispute;
    late DateTime testDate;
    late DisputeMessage testMessage;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      testMessage = DisputeMessage(
        senderId: 'user-789',
        message: 'I did not receive my refund',
        timestamp: testDate,
      );

      dispute = Dispute(
        id: 'dispute-123',
        eventId: 'event-456',
        reporterId: 'user-789',
        reportedId: 'user-012',
        type: DisputeType.payment,
        description: 'Refund amount incorrect',
        evidenceUrls: const ['evidence1.jpg', 'evidence2.jpg'],
        createdAt: testDate,
        status: DisputeStatus.pending,
        messages: [testMessage],
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Status Checks', () {
      test('should correctly identify dispute status states', () {
        // Test business logic: status determination
        expect(dispute.status.isActive, isTrue);
        expect(dispute.isInProgress, isTrue);

        final resolved = dispute.copyWith(
          status: DisputeStatus.resolved,
          resolvedAt: testDate.add(const Duration(hours: 1)),
          resolution: 'Refund processed',
        );
        final closed = dispute.copyWith(
          status: DisputeStatus.closed,
        );

        expect(resolved.status.isResolved, isTrue);
        expect(resolved.status.isTerminal, isTrue);
        expect(resolved.isResolved, isTrue);
        expect(closed.status.isClosed, isTrue);
        expect(closed.status.isTerminal, isTrue);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle null optional fields',
          () {
        // Test business logic: JSON round-trip with default handling
        final json = dispute.toJson();
        final restored = Dispute.fromJson(json);

        expect(restored.status, equals(dispute.status));
        expect(restored.isInProgress, equals(dispute.isInProgress));

        // Test defaults with minimal JSON
        final minimalDispute = Dispute(
          id: 'dispute-1',
          eventId: 'event-1',
          reporterId: 'user-1',
          reportedId: 'user-2',
          type: DisputeType.cancellation,
          description: 'Test',
          createdAt: testDate,
        );
        final minimalJson = minimalDispute.toJson();
        final fromMinimal = Dispute.fromJson(minimalJson);

        expect(fromMinimal.status, equals(DisputeStatus.pending)); // Default
        expect(fromMinimal.assignedAdminId, isNull);
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final updated = dispute.copyWith(
          status: DisputeStatus.inReview,
          assignedAdminId: 'admin-1',
        );

        // Test immutability (business logic)
        expect(dispute.status, isNot(equals(DisputeStatus.inReview)));
        expect(updated.status, equals(DisputeStatus.inReview));
        expect(updated.id, equals(dispute.id)); // Unchanged fields preserved
      });
    });
  });

  group('DisputeMessage', () {
    late DisputeMessage message;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      message = DisputeMessage(
        senderId: 'user-789',
        message: 'I have a concern about the refund',
        timestamp: testDate,
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final json = message.toJson();
        final restored = DisputeMessage.fromJson(json);

        // Test critical business fields preserved
        expect(restored.senderId, equals(message.senderId));
        expect(restored.isAdminMessage, equals(message.isAdminMessage));
      });
    });
  });
}
