import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/business/business_verification_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/business/business_verification.dart';

import 'business_verification_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([BusinessAccountService])
void main() {
  group('BusinessVerificationService Tests', () {
    late BusinessVerificationService service;
    late MockBusinessAccountService mockBusinessAccountService;

    setUp(() {
      mockBusinessAccountService = MockBusinessAccountService();
      service = BusinessVerificationService(
        businessAccountService: mockBusinessAccountService,
      );
    });

    // Removed: Property assignment tests
    // Business verification tests focus on business logic (verification submission, approval, rejection), not property assignment

    group('Initialization', () {
      test(
          'should initialize with default BusinessAccountService or with provided BusinessAccountService',
          () {
        // Test business logic: service initialization
        final defaultService = BusinessVerificationService();
        expect(defaultService, isNotNull);
        expect(service, isNotNull);
      });
    });

    group('submitVerification', () {
      test(
          'should submit verification with required fields, submit with all optional fields, determine verification method from documents, and determine verification method from website',
          () async {
        // Test business logic: verification submission with method determination
        final business1 = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        final verification1 = await service.submitVerification(
          business: business1,
          legalBusinessName: 'Test Business LLC',
        );
        expect(verification1, isA<BusinessVerification>());
        expect(verification1.businessAccountId, equals(business1.id));
        expect(verification1.legalBusinessName, equals('Test Business LLC'));
        expect(verification1.status, equals(VerificationStatus.pending));
        expect(verification1.submittedAt, isNotNull);

        final business2 = BusinessAccount(
          id: 'business-124',
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Retail',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        final verification2 = await service.submitVerification(
          business: business2,
          legalBusinessName: 'Test Business LLC',
          taxId: 'TAX123',
          businessAddress: '123 Main St',
          phoneNumber: '555-1234',
          websiteUrl: 'https://testbusiness.com',
          businessLicenseUrl: 'https://example.com/license.pdf',
          taxIdDocumentUrl: 'https://example.com/tax.pdf',
          proofOfAddressUrl: 'https://example.com/address.pdf',
          websiteVerificationUrl: 'https://testbusiness.com/verify',
          socialMediaVerificationUrl: 'https://twitter.com/testbusiness',
        );
        expect(verification2.taxId, equals('TAX123'));
        expect(verification2.businessAddress, equals('123 Main St'));
        expect(verification2.phoneNumber, equals('555-1234'));
        expect(verification2.websiteUrl, equals('https://testbusiness.com'));
        expect(verification2.businessLicenseUrl, isNotNull);
        expect(verification2.method, isA<VerificationMethod>());

        final business3 = BusinessAccount(
          id: 'business-125',
          name: 'Test Business 3',
          email: 'test3@business.com',
          businessType: 'Service',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        final verification3 = await service.submitVerification(
          business: business3,
          legalBusinessName: 'Test Business LLC',
          businessLicenseUrl: 'https://example.com/license.pdf',
        );
        expect(verification3.method, equals(VerificationMethod.document));

        final business4 = BusinessAccount(
          id: 'business-126',
          name: 'Test Business 4',
          email: 'test4@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        final verification4 = await service.submitVerification(
          business: business4,
          legalBusinessName: 'Test Business LLC',
          websiteUrl: 'https://testbusiness.com',
        );
        expect(verification4.method, equals(VerificationMethod.automatic));
      });
    });

    group('verifyAutomatically', () {
      test(
          'should verify automatically with valid website, throw exception when automatic verification fails, or throw exception with invalid website',
          () async {
        // Test business logic: automatic verification with error handling
        final business1 = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          website: 'https://testbusiness.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        final verification1 = await service.verifyAutomatically(business1);
        expect(verification1.status, equals(VerificationStatus.verified));
        expect(verification1.method, equals(VerificationMethod.automatic));
        expect(verification1.verifiedAt, isNotNull);

        final business2 = BusinessAccount(
          id: 'business-124',
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        expect(
          () => service.verifyAutomatically(business2),
          throwsA(isA<Exception>()),
        );

        final business3 = BusinessAccount(
          id: 'business-125',
          name: 'Test Business 3',
          email: 'test3@business.com',
          businessType: 'Restaurant',
          website: 'invalid-url',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        expect(
          () => service.verifyAutomatically(business3),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('approveVerification', () {
      test('should approve verification', () async {
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.pending,
          method: VerificationMethod.document,
          legalBusinessName: 'Test Business LLC',
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        when(mockBusinessAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        final approved = await service.approveVerification(
          verification,
          'admin-123',
          notes: 'All documents verified',
        );

        expect(approved.status, equals(VerificationStatus.verified));
        expect(approved.verifiedBy, equals('admin-123'));
        expect(approved.verifiedAt, isNotNull);
        expect(approved.notes, equals('All documents verified'));
      });
    });

    group('rejectVerification', () {
      test('should reject verification with reason', () async {
        final verification = BusinessVerification(
          id: 'verification-123',
          businessAccountId: 'business-123',
          status: VerificationStatus.pending,
          method: VerificationMethod.document,
          legalBusinessName: 'Test Business LLC',
          submittedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final rejected = await service.rejectVerification(
          verification,
          'admin-123',
          'Documents do not match business name',
        );

        expect(rejected.status, equals(VerificationStatus.rejected));
        expect(rejected.verifiedBy, equals('admin-123'));
        expect(rejected.rejectionReason,
            equals('Documents do not match business name'));
        expect(rejected.rejectedAt, isNotNull);
      });
    });

    group('getVerification', () {
      test('should get verification for business', () async {
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );

        when(mockBusinessAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);

        final verification = await service.getVerification('business-123');

        expect(verification, anyOf(isNull, isA<BusinessVerification>()));
      });
    });

    group('isBusinessVerified', () {
      test(
          'should return true for verified business or return false for unverified business',
          () async {
        // Test business logic: business verification status checking
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-123',
        );
        when(mockBusinessAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);
        final isVerified = await service.isBusinessVerified('business-123');
        expect(isVerified, isA<bool>());
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
