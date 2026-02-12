import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for RevenueSplit model
/// Tests solo event splits, N-way splits, locking, and validation
void main() {
  group('RevenueSplit Model Tests', () {
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Solo Event Revenue Split', () {
      test('should correctly calculate fees and validate totals add up', () {
        // Test business logic: fee calculation and validation
        final split1 = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );
        final split2 = RevenueSplit.calculate(
          eventId: 'event-456',
          totalAmount: 500.00,
          ticketsSold: 20,
        );

        // Platform fee: 10%
        expect(split1.platformFee, equals(10.00));
        expect(split1.platformFeePercentage, closeTo(10.0, 0.01));

        // Processing fee: 2.9% + $0.30 per transaction
        // 2.9% of $100 = $2.90
        // $0.30 * 10 tickets = $3.00
        // Total = $5.90
        expect(split1.processingFee, closeTo(5.90, 0.01));

        // Host payout: $100 - $10 - $5.90 = $84.10
        expect(split1.hostPayout, closeTo(84.10, 0.01));
        expect(split1.hostPayoutPercentage, closeTo(84.1, 0.01));

        // Validation: totals add up correctly
        final sum1 =
            split1.platformFee + split1.processingFee + split1.hostPayout!;
        final sum2 =
            split2.platformFee + split2.processingFee + split2.hostPayout!;
        expect(sum1, closeTo(100.00, 0.01));
        expect(sum2, closeTo(500.00, 0.01));
        expect(split1.isValid, isTrue);
        expect(split2.isValid, isTrue);
      });
    });

    group('N-Way Revenue Split', () {
      test('should calculate N-way split correctly', () {
        final parties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
            name: 'Expert User',
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 30.0,
            name: 'Test Restaurant',
          ),
          const SplitParty(
            partyId: 'sponsor-123',
            type: SplitPartyType.sponsor,
            percentage: 20.0,
            name: 'Sponsor Company',
          ),
        ];

        final split = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          partnershipId: 'partnership-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );

        expect(split.id, equals('split-123'));
        expect(split.eventId, equals('event-123'));
        expect(split.partnershipId, equals('partnership-123'));
        expect(split.totalAmount, equals(1000.00));
        expect(split.ticketsSold, equals(20));
        expect(split.parties, hasLength(3));

        // Platform fee: 10% = $100
        expect(split.platformFee, equals(100.00));

        // Processing fee: 2.9% + $0.30 per transaction
        // 2.9% of $1000 = $29.00
        // $0.30 * 20 tickets = $6.00
        // Total = $35.00
        expect(split.processingFee, closeTo(35.00, 0.01));

        // Split amount: $1000 - $100 - $35 = $865
        expect(split.splitAmount, closeTo(865.00, 0.01));

        // User: 50% of $865 = $432.50
        expect(split.parties[0].amount, closeTo(432.50, 0.01));
        expect(split.parties[0].percentage, equals(50.0));

        // Business: 30% of $865 = $259.50
        expect(split.parties[1].amount, closeTo(259.50, 0.01));
        expect(split.parties[1].percentage, equals(30.0));

        // Sponsor: 20% of $865 = $173.00
        expect(split.parties[2].amount, closeTo(173.00, 0.01));
        expect(split.parties[2].percentage, equals(20.0));

        expect(split.isValid, isTrue);
      });

      test(
          'should validate N-way split percentages add up to 100% and reject invalid splits',
          () {
        // Test business logic: percentage validation
        final validParties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 50.0,
          ),
        ];
        final invalidParties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 50.0,
          ),
          const SplitParty(
            partyId: 'business-123',
            type: SplitPartyType.business,
            percentage: 40.0, // Only 90% total
          ),
        ];

        final validSplit = RevenueSplit.nWay(
          id: 'split-valid',
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 5,
          parties: validParties,
        );
        final invalidSplit = RevenueSplit.nWay(
          id: 'split-invalid',
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 5,
          parties: invalidParties,
        );

        expect(validSplit.isValid, isTrue);
        expect(invalidSplit.isValid, isFalse);
      });
    });

    group('Locking Mechanism', () {
      test('should lock split and prevent double-locking', () {
        // Test business logic: locking behavior
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        expect(split.isLocked, isFalse);
        expect(split.canBeModified, isTrue);

        final locked = split.lock(lockedBy: 'user-123');

        expect(locked.isLocked, isTrue);
        expect(locked.canBeModified, isFalse);
        expect(locked.lockedBy, equals('user-123'));
        expect(locked.lockedAt, isNotNull);

        // Should prevent double-locking
        expect(
          () => locked.lock(lockedBy: 'user-456'),
          throwsStateError,
        );
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize solo and N-way splits correctly',
          () {
        // Test business logic: JSON round-trip for both split types
        final soloSplit = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        final soloJson = soloSplit.toJson();
        final restoredSolo = RevenueSplit.fromJson(soloJson);

        expect(restoredSolo.totalAmount, equals(100.00));
        expect(restoredSolo.platformFee, equals(10.00));
        expect(restoredSolo.hostPayout, closeTo(84.10, 0.01));
        expect(restoredSolo.isValid, isTrue);

        // N-way split
        final parties = [
          const SplitParty(
            partyId: 'user-123',
            type: SplitPartyType.user,
            percentage: 100.0, // Single party = 100%
            amount: 432.50,
            name: 'Expert User',
          ),
        ];

        final nWaySplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-123',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: parties,
        );

        final nWayJson = nWaySplit.toJson();
        final restoredNWay = RevenueSplit.fromJson(nWayJson);

        expect(restoredNWay.parties, hasLength(1));
        expect(restoredNWay.parties[0].partyId, equals('user-123'));
        expect(restoredNWay.parties[0].percentage, equals(100.0));
      });
    });

    // Removed: Split Party constructor and property tests
    // These tests only verified Dart constructor behavior, not business logic
    // SplitParty is tested through RevenueSplit.nWay tests above

    group('Split Party Type Extension', () {
      // Removed: Display names test - tests property values, not business logic
      test('should parse type from string with case handling and defaults', () {
        // Test business logic: string parsing with error handling
        expect(
          SplitPartyTypeExtension.fromString('user'),
          equals(SplitPartyType.user),
        );
        expect(
          SplitPartyTypeExtension.fromString('business'),
          equals(SplitPartyType.business),
        );
        expect(
          SplitPartyTypeExtension.fromString('sponsor'),
          equals(SplitPartyType.sponsor),
        );
        expect(
          SplitPartyTypeExtension.fromString('other'),
          equals(SplitPartyType.other),
        );
        expect(
          SplitPartyTypeExtension.fromString('unknown'),
          equals(SplitPartyType.user), // Default
        );
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final split = RevenueSplit.calculate(
          eventId: 'event-123',
          totalAmount: 100.00,
          ticketsSold: 10,
        );

        final updated = split.copyWith(
          isLocked: true,
          lockedBy: 'user-123',
        );

        // Test immutability (business logic)
        expect(split.isLocked, isFalse);
        expect(updated.isLocked, isTrue);
        expect(updated.eventId,
            equals(split.eventId)); // Unchanged fields preserved
      });
    });
  });
}
