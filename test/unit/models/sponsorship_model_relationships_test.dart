import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/sponsorship/sponsorship.dart';
import 'package:avrai/core/models/business/brand_account.dart';
import 'package:avrai/core/models/payment/product_tracking.dart';
import 'package:avrai/core/models/sponsorship/multi_party_sponsorship.dart';
import 'package:avrai/core/models/payment/revenue_split.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/models/events/event_partnership.dart';
import 'package:avrai/core/models/sponsorship/sponsorship_integration.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/payment/payment_status.dart';
import '../../helpers/test_helpers.dart';
import '../../fixtures/model_factories.dart';

/// Sponsorship Model Relationships Verification Tests
///
/// Agent 3: Models & Testing (Week 11)
///
/// Verifies all model relationships work correctly with payment/revenue:
/// - Sponsorship ↔ Payment relationships
/// - Sponsorship ↔ RevenueSplit relationships
/// - ProductTracking ↔ RevenueSplit relationships
/// - Multi-party relationships
/// - Brand account relationships
void main() {
  group('Sponsorship Model Relationships Verification', () {
    late DateTime testDate;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late UnifiedUser testUser;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late BusinessAccount testBusiness;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late BrandAccount testBrand;

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
      testBrand = BrandAccount(
        id: 'brand-123',
        name: 'Premium Oil Co.',
        brandType: 'Food & Beverage',
        contactEmail: 'partnerships@premiumoil.com',
        verificationStatus: BrandVerificationStatus.verified,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Payment Relationships', () {
      test('should correctly link and aggregate payments for sponsored events',
          () {
        // Test business logic: payment-sponsorship relationship and aggregation
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final payments = List.generate(
            3,
            (i) => Payment(
                  id: 'payment-$i',
                  eventId: 'event-456',
                  userId: 'user-$i',
                  amount: 75.00,
                  status: PaymentStatus.completed,
                  createdAt: testDate,
                  updatedAt: testDate,
                ));

        // Test business logic: payment aggregation
        final totalRevenue = payments
            .where((p) => p.eventId == sponsorship.eventId && p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        expect(payments.first.eventId, equals(sponsorship.eventId));
        expect(payments.first.isSuccessful, isTrue);
        expect(totalRevenue, equals(225.00));
      });
    });

    group('Revenue Split Relationships', () {
      test(
          'should correctly link revenue split to sponsorship with proper party configuration',
          () {
        // Test business logic: revenue split-sponsorship relationship
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: 1000.00,
          ticketsSold: 20,
          parties: const [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 50.0,
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 30.0,
            ),
            SplitParty(
              partyId: 'brand-123',
              type: SplitPartyType.sponsor,
              percentage: 20.0,
            ),
          ],
        );

        // Test business logic: sponsorship integration
        final includesSponsors =
            SponsorshipIntegration.revenueSplitIncludesSponsorships(
          revenueSplit,
          [sponsorship],
        );
        final sponsorParty = revenueSplit.parties.firstWhere(
          (p) => p.partyId == sponsorship.brandId,
        );

        expect(includesSponsors, isTrue);
        expect(sponsorParty.type, equals(SplitPartyType.sponsor));
        expect(sponsorParty.percentage, equals(20.0));
        expect(revenueSplit.isValid, isTrue);
      });
    });

    group('Product Tracking Relationships', () {
      test(
          'should correctly link product tracking to sponsorship with revenue distribution',
          () {
        // Test business logic: product tracking-sponsorship relationship
        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.product,
          productValue: 500.00,
          status: SponsorshipStatus.active,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final productTracking = ProductTracking(
          id: 'product-track-123',
          sponsorshipId: 'sponsor-123',
          productName: 'Premium Olive Oil',
          quantityProvided: 20,
          quantitySold: 15,
          unitPrice: 25.00,
          totalSales: 375.00,
          platformFee: 37.50,
          revenueDistribution: const {
            'brand-123': 202.50,
            'user-123': 84.38,
            'business-123': 50.62,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Test business logic: relationship and revenue tracking
        expect(productTracking.sponsorshipId, equals(sponsorship.id));
        expect(productTracking.totalSales, equals(375.00));
        expect(productTracking.revenueDistribution.containsKey('brand-123'),
            isTrue);
        expect(productTracking.netRevenue, closeTo(337.50, 0.01));
      });
    });

    group('Multi-Party Relationships', () {
      test(
          'should correctly verify multi-party sponsorship relationships and validation',
          () {
        // Test business logic: multi-party sponsorship integration
        final sponsorship1 = Sponsorship(
          id: 'sponsor-1',
          eventId: 'event-456',
          brandId: 'brand-1',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship2 = Sponsorship(
          id: 'sponsor-2',
          eventId: 'event-456',
          brandId: 'brand-2',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final multiParty = MultiPartySponsorship(
          id: 'multi-sponsor-123',
          eventId: 'event-456',
          brandIds: const ['brand-1', 'brand-2'],
          revenueSplitConfiguration: const {
            'brand-1': 60.0,
            'brand-2': 40.0,
          },
          agreementStatus: MultiPartyAgreementStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Test business logic: multi-party integration
        expect(
            SponsorshipIntegration.isPartOfMultiParty(sponsorship1, multiParty),
            isTrue);
        expect(
            SponsorshipIntegration.isPartOfMultiParty(sponsorship2, multiParty),
            isTrue);
        expect(multiParty.isRevenueSplitValid, isTrue);
      });
    });

    group('Brand Account Relationships', () {
      test('should correctly verify brand account sponsorship eligibility', () {
        // Test business logic: brand-sponsorship relationship and eligibility
        final brand = BrandAccount(
          id: 'brand-123',
          name: 'Premium Oil Co.',
          brandType: 'Food & Beverage',
          contactEmail: 'partnerships@premiumoil.com',
          verificationStatus: BrandVerificationStatus.verified,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Test business logic: sponsorship eligibility
        expect(sponsorship.brandId, equals(brand.id));
        expect(brand.isVerified, isTrue);
        expect(brand.canSponsor, isTrue);
      });
    });

    group('Complete Payment/Revenue Flow', () {
      test(
          'should correctly verify end-to-end payment to revenue split flow with sponsorships',
          () {
        // Test business logic: complete payment-revenue flow
        final partnership = EventPartnership(
          id: 'partnership-123',
          eventId: 'event-456',
          userId: 'user-123',
          businessId: 'business-123',
          status: PartnershipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final sponsorship = Sponsorship(
          id: 'sponsor-123',
          eventId: 'event-456',
          brandId: 'brand-123',
          type: SponsorshipType.financial,
          revenueSharePercentage: 20.0,
          status: SponsorshipStatus.approved,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final payments = [
          Payment(
            id: 'payment-1',
            eventId: 'event-456',
            userId: 'user-1',
            amount: 75.00,
            status: PaymentStatus.completed,
            createdAt: testDate,
            updatedAt: testDate,
          ),
          Payment(
            id: 'payment-2',
            eventId: 'event-456',
            userId: 'user-2',
            amount: 75.00,
            status: PaymentStatus.completed,
            createdAt: testDate,
            updatedAt: testDate,
          ),
        ];

        final totalRevenue = payments
            .where((p) => p.isSuccessful)
            .fold<double>(0.0, (sum, p) => sum + p.totalAmount);

        final revenueSplit = RevenueSplit.nWay(
          id: 'split-123',
          eventId: 'event-456',
          totalAmount: totalRevenue,
          ticketsSold: payments.length,
          parties: const [
            SplitParty(
              partyId: 'user-123',
              type: SplitPartyType.user,
              percentage: 50.0,
            ),
            SplitParty(
              partyId: 'business-123',
              type: SplitPartyType.business,
              percentage: 30.0,
            ),
            SplitParty(
              partyId: 'brand-123',
              type: SplitPartyType.sponsor,
              percentage: 20.0,
            ),
          ],
        );

        // Test business logic: complete flow validation
        expect(partnership.hasSponsorships([sponsorship]), isTrue);
        expect(
            SponsorshipIntegration.revenueSplitIncludesSponsorships(
                revenueSplit, [sponsorship]),
            isTrue);
        expect(revenueSplit.isValid, isTrue);
        final sponsorAmount = revenueSplit.parties
                .firstWhere((p) => p.partyId == 'brand-123')
                .amount ??
            0.0;
        expect(sponsorAmount, greaterThan(0));
      });
    });
  });
}
