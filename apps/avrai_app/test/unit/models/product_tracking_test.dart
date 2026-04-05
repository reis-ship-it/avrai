import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/payment/product_tracking.dart';
import 'package:avrai_core/models/payment/payment_status.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for ProductTracking model
void main() {
  group('ProductTracking Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor property test
    // Tests Dart constructor, not business logic

    test('should correctly calculate remaining quantity and profit margin', () {
      // Test business logic: quantity and margin calculations
      final tracking1 = ProductTracking(
        id: 'product-track-1',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        quantitySold: 15,
        quantityGivenAway: 2,
        quantityUsedInEvent: 1,
        unitPrice: 25.00,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final tracking2 = ProductTracking(
        id: 'product-track-2',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        unitPrice: 25.00,
        unitCostPrice: 15.00,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(tracking1.quantityRemaining, equals(2));
      expect(tracking2.profitMargin, equals(40.0)); // (25-15)/25 * 100
    });

    test('should serialize and deserialize with nested sales correctly', () {
      final sale = ProductSale(
        id: 'sale-123',
        productTrackingId: 'product-track-123',
        buyerId: 'buyer-456',
        quantity: 2,
        unitPrice: 25.00,
        totalAmount: 50.00,
        soldAt: testDate,
        paymentStatus: PaymentStatus.completed,
      );

      final tracking = ProductTracking(
        id: 'product-track-123',
        sponsorshipId: 'sponsor-456',
        productName: 'Premium Olive Oil',
        quantityProvided: 20,
        quantitySold: 2,
        unitPrice: 25.00,
        totalSales: 50.00,
        platformFee: 5.00,
        sales: [sale],
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = tracking.toJson();
      final restored = ProductTracking.fromJson(json);

      // Test nested structure preserved (business logic)
      expect(restored.sales.length, equals(1));
      expect(
          restored.sales.first.paymentStatus, equals(PaymentStatus.completed));
      expect(restored.totalSales, equals(50.00));
    });
  });
}
