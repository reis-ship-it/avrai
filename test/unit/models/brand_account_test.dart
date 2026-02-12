import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/business/brand_account.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BrandAccount model
void main() {
  group('BrandAccount Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    test(
        'should enforce verification requirements for sponsorship and serialize correctly',
        () {
      // Test business logic: verification and JSON serialization
      final unverifiedBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        createdAt: testDate,
        updatedAt: testDate,
      );
      final verifiedBrand = BrandAccount(
        id: 'brand-456',
        name: 'Verified Brand',
        brandType: 'Food & Beverage',
        contactEmail: 'contact@verified.com',
        verificationStatus: BrandVerificationStatus.verified,
        stripeConnectAccountId: 'acct_1234567890',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Test business rules
      expect(unverifiedBrand.canSponsor, isFalse);
      expect(verifiedBrand.canSponsor, isTrue);

      // Test JSON serialization
      final json = verifiedBrand.toJson();
      final restored = BrandAccount.fromJson(json);
      expect(restored.id, equals(verifiedBrand.id));
      expect(restored.categories, equals(verifiedBrand.categories));
      expect(restored.isVerified, equals(verifiedBrand.isVerified));
    });
  });
}
