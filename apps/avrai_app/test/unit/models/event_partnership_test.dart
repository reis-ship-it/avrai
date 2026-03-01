import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/events/event_partnership.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/business/business_account.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for EventPartnership model
/// Tests partnership creation, JSON serialization, status workflow, and agreement locking
void main() {
  group('EventPartnership Model Tests', () {
    late DateTime testDate;
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late UnifiedUser testUser;
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late BusinessAccount testBusiness;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      testUser = ModelFactories.createTestUser(
        id: 'user-123',
        displayName: 'Expert User',
      );
      testBusiness = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: testDate,
        updatedAt: testDate,
        createdBy: 'user-123',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Status Workflow', () {
      test(
          'should correctly identify status states and modification permissions',
          () {
        // Test business logic: status-based behavior
        final pending = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final locked = EventPartnership(
          id: 'partnership-456',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.locked,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final active = EventPartnership(
          id: 'partnership-789',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(pending.canBeModified, isTrue);
        expect(locked.isLocked, isTrue);
        expect(locked.canBeModified, isFalse);
        expect(active.isActive, isTrue);
        expect(active.isLocked, isTrue);
      });
    });

    group('Approval Logic', () {
      test('should correctly determine approval status based on both parties',
          () {
        // Test business logic: approval determination
        final partial = EventPartnership(
          id: 'partnership-1',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          userApproved: true,
          businessApproved: false,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final approved = EventPartnership(
          id: 'partnership-2',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          userApproved: true,
          businessApproved: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(partial.userApproved, isTrue);
        expect(partial.businessApproved, isFalse);
        expect(partial.isApproved, isFalse);
        expect(approved.isApproved, isTrue);
      });
    });

    // Removed: Vibe Compatibility group
    // These tests only checked property assignment, not business logic

    group('JSON Serialization', () {
      test('should serialize and deserialize with nested agreement correctly',
          () {
        final agreement = PartnershipAgreement(
          id: 'agreement-123',
          partnershipId: 'partnership-123',
          terms: const {'revenueSplit': '50/50'},
          agreedAt: testDate,
          agreedBy: 'user-123',
        );

        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.proposed,
          agreement: agreement,
          userApproved: true,
          businessApproved: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = partnership.toJson();
        final restored = EventPartnership.fromJson(json);

        // Test nested structure and business logic preserved
        expect(restored.agreement, isNotNull);
        expect(restored.agreement!.terms, equals({'revenueSplit': '50/50'}));
        expect(restored.isApproved, isTrue);
        expect(restored.status, equals(PartnershipStatus.proposed));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-123',
          userId: 'user-123',
          businessId: 'business-123',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = partnership.copyWith(
          status: PartnershipStatus.approved,
          userApproved: true,
          businessApproved: true,
        );

        // Test immutability and business logic
        expect(partnership.isApproved, isFalse);
        expect(updated.isApproved, isTrue);
        expect(
            updated.id, equals(partnership.id)); // Unchanged fields preserved
      });
    });

    // Removed: Partnership Agreement constructor and property tests
    // These tests only verified Dart constructor behavior, not business logic
    // PartnershipAgreement is tested through EventPartnership JSON tests above

    group('Partnership Status Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test('should parse status from string with case handling and defaults',
          () {
        // Test business logic: string parsing with error handling
        expect(
          PartnershipStatusExtension.fromString('pending'),
          equals(PartnershipStatus.pending),
        );
        expect(
          PartnershipStatusExtension.fromString('proposed'),
          equals(PartnershipStatus.proposed),
        );
        expect(
          PartnershipStatusExtension.fromString('locked'),
          equals(PartnershipStatus.locked),
        );
        expect(
          PartnershipStatusExtension.fromString('unknown'),
          equals(PartnershipStatus.pending), // Default
        );
      });
    });

    group('Partnership Type Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test('should parse type from string with case handling and defaults', () {
        // Test business logic: string parsing with error handling
        expect(
          PartnershipTypeExtension.fromString('eventBased'),
          equals(PartnershipType.eventBased),
        );
        expect(
          PartnershipTypeExtension.fromString('ongoing'),
          equals(PartnershipType.ongoing),
        );
        expect(
          PartnershipTypeExtension.fromString('exclusive'),
          equals(PartnershipType.exclusive),
        );
        expect(
          PartnershipTypeExtension.fromString('unknown'),
          equals(PartnershipType.eventBased), // Default
        );
      });
    });
  });
}
