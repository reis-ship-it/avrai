import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/sponsorship/sponsorship.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Sponsorship model
/// Tests sponsorship creation, JSON serialization, status workflow, and types
void main() {
  group('Sponsorship Model Tests', () {
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

    group('Status Workflow', () {
      test(
          'should correctly identify status states and modification permissions',
          () {
        // Test business logic: status-based behavior
        final pending = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final approved = Sponsorship(
          id: 'sponsor-456',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final active = Sponsorship(
          id: 'sponsor-789',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(pending.canBeModified, isTrue);
        expect(approved.isApproved, isTrue);
        expect(active.isActive, isTrue);
        expect(active.isLocked, isTrue);
      });
    });

    group('Contribution Value Calculation', () {
      test(
          'should calculate total contribution value for different sponsorship types',
          () {
        // Test business logic: value calculation
        final financial = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final product = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.product,
          productValue: 400.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final hybrid = Sponsorship(
          id: 'sponsor-3',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.hybrid,
          contributionAmount: 300.00,
          productValue: 400.00,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(financial.totalContributionValue, equals(500.00));
        expect(product.totalContributionValue, equals(400.00));
        expect(hybrid.totalContributionValue, equals(700.00));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          contributionAmount: 500.00,
          status: SponsorshipStatus.pending,
          revenueSharePercentage: 20.0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = sponsorship.toJson();
        final restored = Sponsorship.fromJson(json);

        // Test critical business fields preserved
        expect(restored.type, equals(SponsorshipType.financial));
        expect(restored.contributionAmount, equals(500.00));
        expect(restored.totalContributionValue, equals(500.00));
        expect(restored.revenueSharePercentage, equals(20.0));
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final original = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-789',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          status: SponsorshipStatus.approved,
          contributionAmount: 600.00,
        );

        // Test immutability (business logic)
        expect(original.status, isNot(equals(SponsorshipStatus.approved)));
        expect(updated.status, equals(SponsorshipStatus.approved));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    group('SponsorshipType Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test('should parse from string with case handling and defaults', () {
        // Test business logic: string parsing with error handling
        expect(
          SponsorshipTypeExtension.fromString('financial'),
          equals(SponsorshipType.financial),
        );
        expect(
          SponsorshipTypeExtension.fromString('product'),
          equals(SponsorshipType.product),
        );
        expect(
          SponsorshipTypeExtension.fromString('hybrid'),
          equals(SponsorshipType.hybrid),
        );
        expect(
          SponsorshipTypeExtension.fromString('unknown'),
          equals(SponsorshipType.financial), // Default
        );
      });
    });

    group('SponsorshipStatus Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test('should parse from string with case handling', () {
        // Test business logic: string parsing
        expect(
          SponsorshipStatusExtension.fromString('pending'),
          equals(SponsorshipStatus.pending),
        );
        expect(
          SponsorshipStatusExtension.fromString('approved'),
          equals(SponsorshipStatus.approved),
        );
        expect(
          SponsorshipStatusExtension.fromString('active'),
          equals(SponsorshipStatus.active),
        );
      });
    });
  });
}
