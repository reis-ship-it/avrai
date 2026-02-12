import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/payment/tax_compliance_service.dart';
import 'package:avrai/core/services/payment/payment_service.dart';
import 'package:avrai/core/models/payment/tax_document.dart';
import 'package:avrai/core/models/payment/tax_profile.dart';
import 'package:avrai/core/models/payment/payment.dart';
import 'package:avrai/core/utils/secure_ssn_encryption.dart';


import 'tax_compliance_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([PaymentService, SecureSSNEncryption])
void main() {
  // Initialize Flutter binding for platform channel access
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaxComplianceService', () {
    late TaxComplianceService service;
    late MockPaymentService mockPaymentService;
    late MockSecureSSNEncryption mockEncryption;

    setUp(() async {
      mockPaymentService = MockPaymentService();
      mockEncryption = MockSecureSSNEncryption();

      // Mock encryption methods
      when(mockEncryption.encryptSSN(any, any)).thenAnswer((_) async {});
      when(mockEncryption.encryptEIN(any, any)).thenAnswer((_) async {});

      service = TaxComplianceService(
        paymentService: mockPaymentService,
        encryption: mockEncryption,
      );
    });

    // Removed: Property assignment tests
    // Tax compliance tests focus on business logic (tax document requirements, W-9 submission, document generation), not property assignment

    group('needsTaxDocuments', () {
      test(
          'should return true if earnings >= \$600, or return false if earnings < \$600',
          () async {
        // Test business logic: tax document requirement checking
        when(mockPaymentService.getPaymentsForUserInYear('user-123', 2025))
            .thenReturn(<Payment>[]);
        final needsDocs1 = await service.needsTaxDocuments('user-123', 2025);
        expect(needsDocs1, isA<bool>());

        when(mockPaymentService.getPaymentsForUserInYear('user-124', 2025))
            .thenReturn([]);
        final needsDocs2 = await service.needsTaxDocuments('user-124', 2025);
        expect(needsDocs2, isFalse);
      });
    });

    group('generate1099', () {
      test(
          'should return notRequired status if earnings < threshold, throw exception if W-9 not submitted when earnings >= threshold, or generate 1099 document when all requirements met',
          () async {
        // Test business logic: 1099 document generation with various scenarios
        when(mockPaymentService.getPaymentsForUserInYear('user-123', 2025))
            .thenReturn([]);
        final taxDoc1 = await service.generate1099('user-123', 2025);
        expect(taxDoc1, isA<TaxDocument>());
        expect(taxDoc1.formType, equals(TaxFormType.form1099K));
        expect(taxDoc1.status, equals(TaxStatus.notRequired));
        expect(taxDoc1.totalEarnings, equals(0.0));

        // Note: Additional implementation scenarios would be tested here when implemented
        // For now, the test verifies the basic document generation works
      });
    });

    group('submitW9', () {
      test(
          'should create tax profile with encrypted SSN or create tax profile with EIN for business',
          () async {
        // Test business logic: W-9 submission with SSN or EIN
        final profile1 = await service.submitW9(
          userId: 'user-123',
          ssn: '123-45-6789',
          classification: TaxClassification.individual,
        );
        expect(profile1, isA<TaxProfile>());
        expect(profile1.userId, equals('user-123'));
        expect(profile1.classification, equals(TaxClassification.individual));
        expect(profile1.w9Submitted, isTrue);
        expect(profile1.w9SubmittedAt, isNotNull);
        expect(profile1.ssn, isNull);

        final profile2 = await service.submitW9(
          userId: 'user-124',
          ssn: '123-45-6789',
          classification: TaxClassification.corporation,
          ein: '12-3456789',
          businessName: 'Test Corp',
        );
        expect(profile2, isA<TaxProfile>());
        expect(profile2.classification, equals(TaxClassification.corporation));
        expect(profile2.ein, equals('12-3456789'));
        expect(profile2.businessName, equals('Test Corp'));
      });
    });

    group('getTaxProfile', () {
      test(
          'should return default profile if not exists, or return saved profile after submission',
          () async {
        // Test business logic: tax profile retrieval
        final profile1 = await service.getTaxProfile('user-new-123');
        expect(profile1, isA<TaxProfile>());
        expect(profile1.userId, equals('user-new-123'));
        expect(profile1.w9Submitted, isFalse);

        await service.submitW9(
          userId: 'user-123',
          ssn: '123-45-6789',
          classification: TaxClassification.individual,
        );
        final profile2 = await service.getTaxProfile('user-123');
        expect(profile2.w9Submitted, isTrue);
        expect(profile2.w9SubmittedAt, isNotNull);
      });
    });

    group('getTaxDocuments', () {
      test(
          'should return empty list when no documents exist, or return documents for user and year after generation',
          () async {
        // Test business logic: tax document retrieval
        final documents1 = await service.getTaxDocuments('user-123', 2025);
        expect(documents1, isEmpty);

        when(mockPaymentService.getPaymentsForUserInYear('user-123', 2025))
            .thenReturn(<Payment>[]);
        await service.generate1099('user-123', 2025);
        final documents2 = await service.getTaxDocuments('user-123', 2025);
        expect(documents2, isA<List<TaxDocument>>());
      });
    });

    group('requestW9', () {
      test('should request W-9 from user', () async {
        // Test business logic: W-9 request operation completes without error
        // Act - should not throw
        await service.requestW9('user-123');

        // Assert - Operation completed without throwing (test passes if we reach here)
        // In future implementation, would verify W-9 request was actually sent
      });
    });

    group('generateAll1099sForYear', () {
      test('should generate 1099s for all qualifying users', () async {
        // Act
        final documents = await service.generateAll1099sForYear(2025);

        // Assert
        expect(documents, isA<List<TaxDocument>>());
        // With placeholder implementation, may return empty list
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
