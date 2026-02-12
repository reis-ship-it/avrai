import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai/core/services/business/business_service.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/business_verification.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';

import 'business_service_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([BusinessAccountService])
void main() {
  group('BusinessService Tests', () {
    late BusinessService service;
    late MockBusinessAccountService mockAccountService;
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
    late UnifiedUser testCreator;

    setUp(() {
      mockAccountService = MockBusinessAccountService();
      service = BusinessService(accountService: mockAccountService);
      testCreator = ModelFactories.createTestUser(
        id: 'creator-123',
        displayName: 'Business Creator',
      );
    });

    // Removed: Property assignment tests
    // Business service tests focus on business logic (creation, verification, updates, eligibility), not property assignment

    group('createBusinessAccount', () {
      test(
          'should create business account with required fields or with all optional fields',
          () async {
        // Test business logic: business account creation with optional parameters
        final expectedBusiness1 = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.createBusinessAccount(
          creator: anyNamed('creator'),
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          description: null,
          website: null,
          location: null,
          phone: null,
          logoUrl: null,
          categories: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => expectedBusiness1);
        final business1 = await service.createBusinessAccount(
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdBy: 'creator-123',
        );
        expect(business1, isA<BusinessAccount>());
        expect(business1.name, equals('Test Business'));
        expect(business1.email, equals('test@business.com'));
        expect(business1.businessType, equals('Restaurant'));

        final expectedBusiness2 = BusinessAccount(
          id: 'business-456',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          categories: const ['Food', 'Dining'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.createBusinessAccount(
          creator: anyNamed('creator'),
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          logoUrl: null,
          categories: ['Food', 'Dining'],
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => expectedBusiness2);
        final business2 = await service.createBusinessAccount(
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Retail',
          createdBy: 'creator-123',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          categories: ['Food', 'Dining'],
        );
        expect(business2.description, equals('A test business'));
        expect(business2.website, equals('https://testbusiness.com'));
        expect(business2.location, equals('San Francisco'));
        expect(business2.phone, equals('555-1234'));
        expect(business2.categories, contains('Food'));
      });
    });

    group('verifyBusiness', () {
      test(
          'should create verification record for business, or throw exception if business not found',
          () async {
        // Test business logic: business verification with validation
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);
        final verification = await service.verifyBusiness(
          businessId: 'business-123',
          businessLicenseUrl: 'https://example.com/license.pdf',
          taxIdDocumentUrl: 'https://example.com/tax.pdf',
          legalBusinessName: 'Test Business LLC',
          taxId: '12-3456789',
          businessAddress: '123 Main St, San Francisco, CA',
          phoneNumber: '555-1234',
          websiteUrl: 'https://testbusiness.com',
        );
        expect(verification, isA<BusinessVerification>());
        expect(verification.businessAccountId, equals('business-123'));
        expect(verification.status, equals(VerificationStatus.pending));
        expect(verification.method, equals(VerificationMethod.hybrid));
        expect(verification.businessLicenseUrl,
            equals('https://example.com/license.pdf'));
        expect(verification.legalBusinessName, equals('Test Business LLC'));

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.verifyBusiness(businessId: 'business-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Business not found'),
          )),
        );
      });
    });

    group('updateBusinessInfo', () {
      test(
          'should update business account information, or throw exception if business not found',
          () async {
        // Test business logic: business information updates with validation
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Original Name',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        final updatedBusiness = business.copyWith(
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);
        when(mockAccountService.updateBusinessAccount(
          business,
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
          location: null,
          phone: null,
          categories: null,
        )).thenAnswer((_) async => updatedBusiness);
        final updated = await service.updateBusinessInfo(
          businessId: 'business-123',
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
        );
        expect(updated.name, equals('Updated Name'));
        expect(updated.description, equals('Updated description'));
        expect(updated.website, equals('https://updated.com'));

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);
        expect(
          () => service.updateBusinessInfo(businessId: 'business-123'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Business not found'),
          )),
        );
      });
    });

    group('findBusinesses', () {
      test(
          'should find businesses by category, filter by verifiedOnly flag, and respect maxResults limit',
          () async {
        // Test business logic: business search with filters
        final businesses1 = [
          BusinessAccount(
            id: 'business-1',
            name: 'Coffee Shop 1',
            email: 'shop1@coffee.com',
            businessType: 'Restaurant',
            categories: const ['Coffee'],
            location: 'San Francisco',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
          BusinessAccount(
            id: 'business-2',
            name: 'Coffee Shop 2',
            email: 'shop2@coffee.com',
            businessType: 'Restaurant',
            categories: const ['Coffee'],
            location: 'San Francisco',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        ];
        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses1);
        final found1 = await service.findBusinesses(
          category: 'Coffee',
          location: 'San Francisco',
        );
        expect(found1, isNotEmpty);
        expect(found1.every((b) => b.categories.contains('Coffee')), isTrue);

        final businesses2 = [
          BusinessAccount(
            id: 'business-1',
            name: 'Verified Business',
            email: 'verified@business.com',
            businessType: 'Restaurant',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
          BusinessAccount(
            id: 'business-2',
            name: 'Unverified Business',
            email: 'unverified@business.com',
            businessType: 'Restaurant',
            isVerified: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        ];
        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses2);
        final found2 = await service.findBusinesses(verifiedOnly: true);
        expect(found2, isNotEmpty);
        expect(found2.every((b) => b.isVerified), isTrue);

        final businesses3 = List.generate(
          10,
          (i) => BusinessAccount(
            id: 'business-$i',
            name: 'Business $i',
            email: 'business$i@test.com',
            businessType: 'Restaurant',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'creator-123',
          ),
        );
        when(mockAccountService.getBusinessAccountsByUser('system'))
            .thenAnswer((_) async => businesses3);
        final found3 = await service.findBusinesses(maxResults: 5);
        expect(found3.length, lessThanOrEqualTo(5));
      });
    });

    group('checkBusinessEligibility', () {
      test(
          'should return true for eligible business, or false if business not found, not verified, or not active',
          () async {
        // Test business logic: business eligibility checking with various conditions
        final eligibleBusiness = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => eligibleBusiness);
        final isEligible1 =
            await service.checkBusinessEligibility('business-123');
        expect(isEligible1, isTrue);

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);
        final isEligible2 =
            await service.checkBusinessEligibility('business-123');
        expect(isEligible2, isFalse);

        final unverifiedBusiness = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => unverifiedBusiness);
        final isEligible3 =
            await service.checkBusinessEligibility('business-123');
        expect(isEligible3, isFalse);

        final inactiveBusiness = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          isVerified: true,
          isActive: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => inactiveBusiness);
        final isEligible4 =
            await service.checkBusinessEligibility('business-123');
        expect(isEligible4, isFalse);
      });
    });

    group('getBusinessById', () {
      test('should return business by ID, or return null if business not found',
          () async {
        // Test business logic: business retrieval with existence checking
        final business = BusinessAccount(
          id: 'business-123',
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'creator-123',
        );
        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => business);
        final found1 = await service.getBusinessById('business-123');
        expect(found1, isNotNull);
        expect(found1?.id, equals('business-123'));

        when(mockAccountService.getBusinessAccount('business-123'))
            .thenAnswer((_) async => null);
        final found2 = await service.getBusinessById('business-123');
        expect(found2, isNull);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
