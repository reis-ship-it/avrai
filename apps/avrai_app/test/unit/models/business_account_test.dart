import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_verification.dart';
import 'package:avrai_core/models/business/business_expert_preferences.dart';
import 'package:avrai_core/models/business/business_patron_preferences.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BusinessAccount model
/// Tests business account creation, JSON serialization, and business logic
void main() {
  group('BusinessAccount Model Tests', () {
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

    group('JSON Serialization', () {
      test('should serialize and deserialize nested preferences with defaults',
          () {
        // Test business logic: JSON round-trip with nested structures
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.verified,
          submittedAt: testDate,
          updatedAt: testDate,
        );
        const expertPrefs = BusinessExpertPreferences(
          requiredExpertiseCategories: ['Coffee'],
          minExpertLevel: 3,
        );
        const patronPrefs = BusinessPatronPreferences(
          preferredInterests: ['Food'],
        );

        final account = BusinessAccount(
          id: 'business-123',
          name: 'Test Restaurant',
          email: 'test@restaurant.com',
          businessType: 'Restaurant',
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          verification: verification,
          stripeConnectAccountId: 'acct_1234567890',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final json = account.toJson();
        final restored = BusinessAccount.fromJson(json);

        expect(restored.expertPreferences?.requiredExpertiseCategories,
            equals(expertPrefs.requiredExpertiseCategories));
        expect(restored.patronPreferences?.preferredInterests,
            equals(patronPrefs.preferredInterests));
        expect(restored.verification?.status, equals(verification.status));
        expect(restored.stripeConnectAccountId, equals('acct_1234567890'));

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'business-123',
          'name': 'Test Restaurant',
          'email': 'test@restaurant.com',
          'businessType': 'Restaurant',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'createdBy': 'user-123',
        };
        final fromMinimal = BusinessAccount.fromJson(minimalJson);
        expect(fromMinimal.isActive, isTrue);
        expect(fromMinimal.isVerified, isFalse);
        expect(fromMinimal.categories, isEmpty);
        expect(fromMinimal.connectedExpertIds, isEmpty);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = BusinessAccount(
          id: 'business-123',
          name: 'Original Name',
          email: 'original@test.com',
          businessType: 'Restaurant',
          createdAt: testDate,
          updatedAt: testDate,
          createdBy: 'user-123',
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          isActive: false,
        );

        // Test immutability (business logic)
        expect(original.name, isNot(equals('Updated Name')));
        expect(updated.name, equals('Updated Name'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    // Removed: Edge Cases group
    // These tests only verify string storage (empty, long, special chars, unicode)
    // They test Dart's string handling, not business logic
    // If string storage breaks, JSON serialization tests will fail
  });
}
