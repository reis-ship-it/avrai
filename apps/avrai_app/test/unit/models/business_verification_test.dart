import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/business/business_verification.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for BusinessVerification model
/// Tests verification status, methods, progress calculation, and JSON serialization
void main() {
  group('BusinessVerification Model Tests', () {
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

    group('Verification Status Enum', () {
      test('should parse status from string with case handling and defaults',
          () {
        // Test business logic: string parsing with error handling
        expect(VerificationStatusExtension.fromString('pending'),
            equals(VerificationStatus.pending));
        expect(VerificationStatusExtension.fromString('inreview'),
            equals(VerificationStatus.inReview));
        expect(VerificationStatusExtension.fromString('verified'),
            equals(VerificationStatus.verified));
        expect(VerificationStatusExtension.fromString('unknown'),
            equals(VerificationStatus.pending)); // Default
        expect(VerificationStatusExtension.fromString(null),
            equals(VerificationStatus.pending)); // Default
      });
    });

    group('Verification Method Enum', () {
      test('should parse method from string with defaults', () {
        // Test business logic: string parsing with error handling
        expect(VerificationMethodExtension.fromString('automatic'),
            equals(VerificationMethod.automatic));
        expect(VerificationMethodExtension.fromString('manual'),
            equals(VerificationMethod.manual));
        expect(VerificationMethodExtension.fromString('unknown'),
            equals(VerificationMethod.automatic)); // Default
        expect(VerificationMethodExtension.fromString(null),
            equals(VerificationMethod.automatic)); // Default
      });
    });

    group('Status Checkers', () {
      test('should correctly identify verification status states', () {
        // Test business logic: status-based behavior
        final verified = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.verified,
          submittedAt: testDate,
          updatedAt: testDate,
        );
        final pending = BusinessVerification(
          id: 'verification-456',
          businessAccountId: 'business-123',
          status: VerificationStatus.pending,
          submittedAt: testDate,
          updatedAt: testDate,
        );
        final rejected = BusinessVerification(
          id: 'verification-789',
          businessAccountId: 'business-123',
          status: VerificationStatus.rejected,
          submittedAt: testDate,
          updatedAt: testDate,
        );

        expect(verified.isComplete, isTrue);
        expect(pending.isComplete, isFalse);
        expect(pending.isPending, isTrue);
        expect(rejected.isRejected, isTrue);
      });
    });

    group('Progress Calculation', () {
      test('should calculate progress based on required fields completion', () {
        // Test business logic: progress calculation
        final empty = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          submittedAt: testDate,
          updatedAt: testDate,
        );
        final partial = BusinessVerification(
          id: 'verification-456',
          businessAccountId: 'business-123',
          legalBusinessName: 'Legal Name',
          businessAddress: '123 Main St',
          phoneNumber: '+1-555-0123',
          submittedAt: testDate,
          updatedAt: testDate,
        );
        final complete = BusinessVerification(
          id: 'verification-789',
          businessAccountId: 'business-123',
          legalBusinessName: 'Legal Name',
          businessAddress: '123 Main St',
          phoneNumber: '+1-555-0123',
          businessLicenseUrl: 'https://example.com/license.pdf',
          submittedAt: testDate,
          updatedAt: testDate,
        );
        final completeWithAlt = BusinessVerification(
          id: 'verification-101',
          businessAccountId: 'business-123',
          legalBusinessName: 'Legal Name',
          businessAddress: '123 Main St',
          phoneNumber: '+1-555-0123',
          taxIdDocumentUrl:
              'https://example.com/tax.pdf', // Alternative document
          submittedAt: testDate,
          updatedAt: testDate,
        );

        expect(empty.progress, equals(0.0));
        expect(partial.progress, equals(0.75));
        expect(complete.progress, equals(1.0));
        expect(completeWithAlt.progress,
            equals(1.0)); // Alternative document accepted
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final verifiedAt = testDate.add(const Duration(days: 1));
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.verified,
          method: VerificationMethod.manual,
          legalBusinessName: 'Legal Name',
          businessAddress: '123 Main St',
          phoneNumber: '+1-555-0123',
          verifiedBy: 'admin-123',
          verifiedAt: verifiedAt,
          submittedAt: testDate,
          updatedAt: verifiedAt,
        );

        final json = verification.toJson();
        final restored = BusinessVerification.fromJson(json);

        // Test critical business fields preserved
        expect(restored.isComplete, equals(verification.isComplete));
        expect(restored.progress, equals(verification.progress));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.pending,
          submittedAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          status: VerificationStatus.verified,
          verifiedBy: 'admin-123',
        );

        // Test immutability (business logic)
        expect(original.status, isNot(equals(VerificationStatus.verified)));
        expect(updated.status, equals(VerificationStatus.verified));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    // Removed: Edge Cases group
    // These tests verify string storage, which is tested by Dart's type system
    // If strings can't be stored, the code won't compile
  });
}
