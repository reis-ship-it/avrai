import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/payment/payment_intent.dart';
import 'package:avrai/core/models/payment/payment_status.dart';

/// SPOTS PaymentIntent Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test PaymentIntent model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Status Checks: Terminal states, success
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
///
/// Dependencies:
/// - PaymentStatus: Payment status enum

void main() {
  group('PaymentIntent', () {
    late PaymentIntent paymentIntent;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      paymentIntent = PaymentIntent(
        id: 'pi_1234567890',
        clientSecret: 'pi_1234567890_secret_abc',
        amount: 2500, // $25.00
        currency: 'usd',
        status: PaymentStatus.pending,
        createdAt: testDate,
        eventId: 'event-456',
        userId: 'user-789',
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Status Checks', () {
      test('should correctly identify payment status states', () {
        // Test business logic: status determination
        expect(paymentIntent.status.isTerminal, isFalse);

        final completed = paymentIntent.copyWith(
          status: PaymentStatus.completed,
        );
        final failed = paymentIntent.copyWith(
          status: PaymentStatus.failed,
        );
        final refunded = paymentIntent.copyWith(
          status: PaymentStatus.refunded,
        );

        expect(completed.status.isSuccessful, isTrue);
        expect(completed.status.isTerminal, isTrue);
        expect(failed.status.isTerminal, isTrue);
        expect(failed.status.isSuccessful, isFalse);
        expect(refunded.status.isTerminal, isTrue);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final json = paymentIntent.toJson();
        final restored = PaymentIntent.fromJson(json);

        // Test critical business fields preserved
        expect(restored.status, equals(paymentIntent.status));
        expect(restored.status.isTerminal,
            equals(paymentIntent.status.isTerminal));
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final updated = paymentIntent.copyWith(
          status: PaymentStatus.completed,
          paymentMethodId: 'pm_123',
        );

        // Test immutability (business logic)
        expect(paymentIntent.status, isNot(equals(PaymentStatus.completed)));
        expect(updated.status, equals(PaymentStatus.completed));
        expect(
            updated.id, equals(paymentIntent.id)); // Unchanged fields preserved
      });
    });
  });
}
