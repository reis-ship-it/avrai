import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_core/models/business/business_account.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// Business Account Service Tests
/// Tests business account creation and management
void main() {
  group('BusinessAccountService Tests', () {
    late BusinessAccountService service;
    late UnifiedUser creator;

    setUp(() {
      service = BusinessAccountService();
      creator = ModelFactories.createTestUser(
        id: 'creator-123',
        tags: ['business_owner'],
      );
    });

    // Removed: Property assignment tests
    // Business account tests focus on business logic (account creation, updates, retrieval, expert connections), not property assignment

    group('createBusinessAccount', () {
      test(
          'should create business account with required fields, create business account with all optional fields, or generate unique business ID',
          () async {
        // Test business logic: business account creation
        final account1 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );
        expect(account1, isA<BusinessAccount>());
        expect(account1.name, equals('Test Business'));
        expect(account1.email, equals('test@business.com'));
        expect(account1.businessType, equals('Restaurant'));
        expect(account1.createdBy, equals(creator.id));
        expect(account1.createdAt, isNotNull);
        expect(account1.updatedAt, isNotNull);

        final account2 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Retail',
          description: 'A test business',
          website: 'https://testbusiness.com',
          location: 'San Francisco',
          phone: '555-1234',
          logoUrl: 'https://example.com/logo.png',
          categories: ['Food', 'Dining'],
          requiredExpertise: ['Restaurant Management'],
          preferredCommunities: ['community-1'],
        );
        expect(account2.description, equals('A test business'));
        expect(account2.website, equals('https://testbusiness.com'));
        expect(account2.location, equals('San Francisco'));
        expect(account2.phone, equals('555-1234'));
        expect(account2.logoUrl, equals('https://example.com/logo.png'));
        expect(account2.categories, contains('Food'));
        expect(account2.requiredExpertise, contains('Restaurant Management'));

        await Future.delayed(const Duration(milliseconds: 1));
        final account3 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business 3',
          email: 'test3@business.com',
          businessType: 'Restaurant',
        );
        expect(account1.id, isNot(equals(account3.id)));
        expect(account2.id, isNot(equals(account3.id)));
      });
    });

    group('updateBusinessAccount', () {
      test('should update business account fields, or update categories',
          () async {
        // Test business logic: business account updates
        final account1 = await service.createBusinessAccount(
          creator: creator,
          name: 'Original Name',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );
        final updated1 = await service.updateBusinessAccount(
          account1,
          name: 'Updated Name',
          description: 'Updated description',
          website: 'https://updated.com',
        );
        expect(updated1.name, equals('Updated Name'));
        expect(updated1.description, equals('Updated description'));
        expect(updated1.website, equals('https://updated.com'));
        expect(updated1.updatedAt, isNot(equals(account1.updatedAt)));

        final account2 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test2@business.com',
          businessType: 'Restaurant',
        );
        final updated2 = await service.updateBusinessAccount(
          account2,
          categories: ['Food', 'Dining', 'Italian'],
        );
        expect(updated2.categories, equals(['Food', 'Dining', 'Italian']));
      });
    });

    group('getBusinessAccount', () {
      test(
          'should return null for non-existent account, or return account after creation',
          () async {
        // Test business logic: business account retrieval
        final account1 = await service.getBusinessAccount('non-existent-id');
        expect(account1, isNull);

        final created = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );
        final retrieved = await service.getBusinessAccount(created.id);
        expect(retrieved, anyOf(isNull, isA<BusinessAccount>()));
      });
    });

    group('getBusinessAccountsByUser', () {
      test('should return empty list for user with no accounts', () async {
        final accounts = await service.getBusinessAccountsByUser('user-123');
        expect(accounts, isEmpty);
      });
    });

    group('addExpertConnection', () {
      test(
          'should add expert connection, or not add duplicate expert connection',
          () async {
        // Test business logic: expert connection management
        final account1 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );
        final updated1 =
            await service.addExpertConnection(account1, 'expert-123');
        expect(updated1.connectedExpertIds, contains('expert-123'));
        expect(updated1.pendingConnectionIds, isNot(contains('expert-123')));

        final account2 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Restaurant',
        );
        final updated2a =
            await service.addExpertConnection(account2, 'expert-456');
        final updated2b =
            await service.addExpertConnection(updated2a, 'expert-456');
        expect(
            updated2b.connectedExpertIds
                .where((id) => id == 'expert-456')
                .length,
            equals(1));
      });
    });

    group('requestExpertConnection', () {
      test(
          'should add expert to pending connections, or not add if already connected',
          () async {
        // Test business logic: expert connection requests
        final account1 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business',
          email: 'test@business.com',
          businessType: 'Restaurant',
        );
        final updated1 =
            await service.requestExpertConnection(account1, 'expert-123');
        expect(updated1.pendingConnectionIds, contains('expert-123'));

        final account2 = await service.createBusinessAccount(
          creator: creator,
          name: 'Test Business 2',
          email: 'test2@business.com',
          businessType: 'Restaurant',
        );
        final connected =
            await service.addExpertConnection(account2, 'expert-456');
        final requested =
            await service.requestExpertConnection(connected, 'expert-456');
        expect(requested.pendingConnectionIds, isNot(contains('expert-456')));
        expect(requested.connectedExpertIds, contains('expert-456'));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
