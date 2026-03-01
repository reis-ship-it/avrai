import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/sponsorship/multi_party_sponsorship.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for MultiPartySponsorship model
void main() {
  group('MultiPartySponsorship Model Tests', () {
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
        'should correctly validate revenue split configuration and serialize correctly',
        () {
      // Test business logic: revenue split validation and JSON serialization
      final validSplit = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: const ['brand-1', 'brand-2'],
        revenueSplitConfiguration: const {
          'brand-1': 60.0,
          'brand-2': 40.0,
        },
        agreementStatus: MultiPartyAgreementStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );
      final invalidSplit = MultiPartySponsorship(
        id: 'multi-sponsor-456',
        eventId: 'event-456',
        brandIds: const ['brand-1', 'brand-2'],
        revenueSplitConfiguration: const {
          'brand-1': 60.0,
          'brand-2': 50.0, // Total > 100%
        },
        agreementStatus: MultiPartyAgreementStatus.pending,
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(validSplit.isRevenueSplitValid, isTrue);
      expect(invalidSplit.isRevenueSplitValid, isFalse);

      // Test JSON serialization
      final multiParty = MultiPartySponsorship(
        id: 'multi-sponsor-123',
        eventId: 'event-456',
        brandIds: const ['brand-1', 'brand-2'],
        revenueSplitConfiguration: const {
          'brand-1': 60.0,
          'brand-2': 40.0,
        },
        totalContributionValue: 1000.00,
        agreementStatus: MultiPartyAgreementStatus.approved,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final json = multiParty.toJson();
      final restored = MultiPartySponsorship.fromJson(json);

      expect(
          restored.isRevenueSplitValid, equals(multiParty.isRevenueSplitValid));
      expect(restored.brandCount, equals(multiParty.brandCount));
    });
  });
}
