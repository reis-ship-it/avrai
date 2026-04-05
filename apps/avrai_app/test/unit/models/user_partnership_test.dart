import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/user_partnership.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for UserPartnership model
/// Tests partnership creation, JSON serialization, and business logic
void main() {
  group('UserPartnership Model Tests', () {
    late DateTime testDate;
    late DateTime startDate;
    late DateTime endDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      startDate = testDate.subtract(const Duration(days: 30));
      endDate = testDate.add(const Duration(days: 30));
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('ProfilePartnershipType Enum', () {
      // Removed: Display names test - tests property values, not business logic
      test(
          'should parse from string with case handling, defaults, and null handling',
          () {
        // Test business logic: string parsing with error handling
        expect(ProfilePartnershipTypeExtension.fromString('business'),
            equals(ProfilePartnershipType.business));
        expect(ProfilePartnershipTypeExtension.fromString('brand'),
            equals(ProfilePartnershipType.brand));
        expect(ProfilePartnershipTypeExtension.fromString('company'),
            equals(ProfilePartnershipType.company));
        expect(ProfilePartnershipTypeExtension.fromString('unknown'),
            equals(ProfilePartnershipType.business)); // Default
        expect(ProfilePartnershipTypeExtension.fromString(null),
            equals(ProfilePartnershipType.business)); // Null handling
      });
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Business Logic', () {
      test('should correctly identify partnership status and ongoing state',
          () {
        // Test business logic: status and date-based logic
        const activePartnership = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );
        const completedPartnership = UserPartnership(
          id: 'partnership-456',
          type: ProfilePartnershipType.business,
          partnerId: 'business-456',
          partnerName: 'Test Business 2',
          status: PartnershipStatus.completed,
        );
        final ongoingPartnership = UserPartnership(
          id: 'partnership-789',
          type: ProfilePartnershipType.business,
          partnerId: 'business-789',
          partnerName: 'Test Business 3',
          status: PartnershipStatus.active,
          startDate: startDate,
          // endDate is null, so it's ongoing
        );

        // Test status logic (business rules)
        expect(activePartnership.isActive, isTrue);
        expect(activePartnership.isCompleted, isFalse);
        expect(completedPartnership.isCompleted, isTrue);
        expect(completedPartnership.isActive, isFalse);
        expect(ongoingPartnership.isOngoing, isTrue,
            reason:
                'Partnership with startDate but no endDate should be ongoing');
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle missing fields',
          () {
        // Test business logic: JSON round-trip with error handling
        final originalPartnership = UserPartnership(
          id: 'partnership-roundtrip',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          partnerLogoUrl: 'https://example.com/logo.png',
          status: PartnershipStatus.active,
          startDate: startDate,
          endDate: endDate,
          category: 'Food',
          vibeCompatibility: 0.85,
          eventCount: 5,
          isPublic: true,
        );

        final json = originalPartnership.toJson();
        final reconstructed = UserPartnership.fromJson(json);

        // Test round-trip (UserPartnership implements Equatable)
        expect(reconstructed, equals(originalPartnership));

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'partnership-minimal',
          'type': 'company',
          'partnerId': 'company-123',
          'partnerName': 'Test Company',
          'status': 'active',
        };
        final fromMinimal = UserPartnership.fromJson(minimalJson);
        expect(fromMinimal.eventCount, equals(0));
        expect(fromMinimal.isPublic, isTrue);
        expect(fromMinimal.partnerLogoUrl, isNull);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        const original = UserPartnership(
          id: 'partnership-123',
          type: ProfilePartnershipType.business,
          partnerId: 'business-123',
          partnerName: 'Test Business',
          status: PartnershipStatus.active,
        );

        final updated = original.copyWith(
          partnerName: 'Updated Business',
          status: PartnershipStatus.completed,
        );

        // Test immutability (business logic)
        expect(original.partnerName, isNot(equals('Updated Business')));
        expect(updated.partnerName, equals('Updated Business'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
