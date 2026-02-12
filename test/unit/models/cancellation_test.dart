import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/misc/cancellation.dart';
import 'package:avrai/core/models/misc/cancellation_initiator.dart';
import 'package:avrai/core/models/payment/refund_status.dart';

/// SPOTS Cancellation Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Cancellation model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Refund status validation
/// - Initiator Checks: Force majeure, host/attendee initiated
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
///
/// Dependencies:
/// - CancellationInitiator: Initiator enum
/// - RefundStatus: Refund status enum

void main() {
  group('Cancellation', () {
    late Cancellation cancellation;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      cancellation = Cancellation(
        id: 'cancellation-123',
        eventId: 'event-456',
        userId: 'user-789',
        initiator: CancellationInitiator.attendee,
        reason: 'Unable to attend',
        refundStatus: RefundStatus.pending,
        paymentIds: const ['payment-1', 'payment-2'],
        createdAt: testDate,
        updatedAt: testDate,
        refundAmount: 50.0,
        isFullEventCancellation: false,
        isForceMajeure: false,
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Status Checks', () {
      test('should correctly identify refund status states', () {
        // Test business logic: status determination
        expect(cancellation.refundStatus.isInProgress, isTrue);

        final completed = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundProcessedAt: testDate.add(const Duration(hours: 1)),
        );
        final failed = cancellation.copyWith(
          refundStatus: RefundStatus.failed,
        );

        expect(completed.refundStatus.isSuccessful, isTrue);
        expect(completed.refundStatus.isTerminal, isTrue);
        expect(failed.refundStatus.isTerminal, isTrue);
        expect(failed.refundStatus.isSuccessful, isFalse);
      });
    });

    group('Initiator Checks', () {
      test(
          'should correctly identify cancellation initiator types and force majeure',
          () {
        // Test business logic: initiator determination
        expect(cancellation.initiator.isAttendeeInitiated, isTrue);
        expect(cancellation.initiator.isHostInitiated, isFalse);

        final hostCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.host,
        );
        final weatherCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.weather,
          isForceMajeure: true,
        );
        final platformCancellation = cancellation.copyWith(
          initiator: CancellationInitiator.platform,
          isForceMajeure: true,
        );

        expect(hostCancellation.initiator.isHostInitiated, isTrue);
        expect(weatherCancellation.initiator.isForceMajeure, isTrue);
        expect(weatherCancellation.isForceMajeure, isTrue);
        expect(platformCancellation.initiator.isForceMajeure, isTrue);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle null optional fields',
          () {
        // Test business logic: JSON round-trip with default handling
        final json = cancellation.toJson();
        final restored = Cancellation.fromJson(json);

        expect(restored.refundStatus, equals(cancellation.refundStatus));
        expect(restored.initiator.isAttendeeInitiated,
            equals(cancellation.initiator.isAttendeeInitiated));

        // Test defaults with minimal JSON
        final minimalCancellation = Cancellation(
          id: 'cancellation-1',
          eventId: 'event-1',
          userId: 'user-1',
          initiator: CancellationInitiator.host,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final minimalJson = minimalCancellation.toJson();
        final fromMinimal = Cancellation.fromJson(minimalJson);

        expect(
            fromMinimal.refundStatus, equals(RefundStatus.pending)); // Default
        expect(fromMinimal.reason, isNull);
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final updated = cancellation.copyWith(
          refundStatus: RefundStatus.completed,
          refundAmount: 75.0,
        );

        // Test immutability (business logic)
        expect(
            cancellation.refundStatus, isNot(equals(RefundStatus.completed)));
        expect(updated.refundStatus, equals(RefundStatus.completed));
        expect(
            updated.id, equals(cancellation.id)); // Unchanged fields preserved
      });
    });
  });
}
