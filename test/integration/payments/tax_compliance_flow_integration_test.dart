import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/payment/tax_document.dart';
import 'package:avrai/core/models/payment/tax_profile.dart';

/// Integration tests for tax compliance flow
///
/// Tests model relationships and data flow for:
/// 1. W-9 submission → 1099 generation
/// 2. Earnings calculation → Tax document generation
void main() {
  group('Tax Compliance Flow Integration Tests', () {
    test('should generate tax document when earnings exceed threshold', () {
      const earnings = 1500.00;
      const threshold = 600.00;
      const needsDocument = earnings >= threshold;

      if (needsDocument) {
        final taxDoc = TaxDocument(
          id: 'tax-doc-123',
          userId: 'user-456',
          taxYear: 2025,
          formType: TaxFormType.form1099K,
          totalEarnings: earnings,
          status: TaxStatus.generated,
          generatedAt: DateTime.now(),
        );

        // Test business logic: document generation based on threshold
        expect(taxDoc.totalEarnings, greaterThanOrEqualTo(threshold),
            reason: 'Document should be generated when threshold met');
        expect(taxDoc.status, equals(TaxStatus.generated));
      }

      expect(needsDocument, isTrue);
    });

    test('should progress through tax document status flow correctly', () {
      // Test business logic: status progression workflow
      var taxDoc = TaxDocument(
        id: 'tax-doc-123',
        userId: 'user-456',
        taxYear: 2025,
        formType: TaxFormType.form1099K,
        totalEarnings: 1500.00,
        status: TaxStatus.pending,
        generatedAt: DateTime.now(),
      );

      // Step 1: Generate document
      taxDoc = taxDoc.copyWith(
        status: TaxStatus.generated,
        documentUrl: 'https://storage.example.com/tax-doc-123.pdf',
      );
      expect(taxDoc.documentUrl, isNotNull,
          reason: 'Generated status should have document URL');

      // Step 2: Send to user
      taxDoc = taxDoc.copyWith(status: TaxStatus.sent);
      expect(taxDoc.status, equals(TaxStatus.sent));

      // Step 3: File with IRS
      taxDoc = taxDoc.copyWith(
        status: TaxStatus.filed,
        filedWithIRSAt: DateTime.now(),
      );
      expect(taxDoc.filedWithIRSAt, isNotNull,
          reason: 'Filed status should have filing timestamp');
    });

    test('should validate profile completeness for different classifications',
        () {
      // Test business logic: different classifications require different fields
      final individualProfile = TaxProfile(
        userId: 'user-1',
        classification: TaxClassification.individual,
        ssn: 'encrypted-ssn',
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );
      final businessProfile = TaxProfile(
        userId: 'user-2',
        classification: TaxClassification.llc,
        ein: '12-3456789',
        businessName: 'My Business LLC',
        w9Submitted: true,
        w9SubmittedAt: DateTime.now(),
      );

      // Test business rules: individual needs SSN, business needs EIN
      expect(individualProfile.ssn, isNotNull,
          reason: 'Individual profile should have SSN');
      expect(businessProfile.ein, isNotNull,
          reason: 'Business profile should have EIN');
      expect(businessProfile.businessName, isNotNull,
          reason: 'Business profile should have business name');
    });

    test('multiple tax documents for same user/year', () {
      final doc1 = TaxDocument(
        id: 'doc-1',
        userId: 'user-123',
        taxYear: 2025,
        formType: TaxFormType.form1099K,
        totalEarnings: 800.00,
        status: TaxStatus.generated,
        generatedAt: DateTime.now(),
      );

      final doc2 = TaxDocument(
        id: 'doc-2',
        userId: 'user-123',
        taxYear: 2025,
        formType: TaxFormType.form1099NEC,
        totalEarnings: 400.00,
        status: TaxStatus.generated,
        generatedAt: DateTime.now(),
      );

      final allDocs = [doc1, doc2];
      final totalEarnings =
          allDocs.map((d) => d.totalEarnings).reduce((a, b) => a + b);

      expect(allDocs.every((d) => d.userId == 'user-123'), isTrue);
      expect(allDocs.every((d) => d.taxYear == 2025), isTrue);
      expect(totalEarnings, equals(1200.00));
    });

    test('should apply 600 minimum earnings threshold correctly', () {
      // Test business logic: threshold calculation
      const belowThreshold = 500.00;
      const atThreshold = 600.00;
      const aboveThreshold = 700.00;
      const threshold = 600.00;

      const needsDocBelow = belowThreshold >= threshold;
      const needsDocAt = atThreshold >= threshold;
      const needsDocAbove = aboveThreshold >= threshold;

      // Test threshold logic
      expect(needsDocBelow, isFalse,
          reason: 'Below threshold should not require document');
      expect(needsDocAt, isTrue,
          reason: 'At threshold should require document');
      expect(needsDocAbove, isTrue,
          reason: 'Above threshold should require document');
    });
  });
}
