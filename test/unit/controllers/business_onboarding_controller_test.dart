import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:avrai/core/controllers/business_onboarding_controller.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/services/business/business_shared_agent_service.dart';
import 'package:avrai/core/models/business/business_account.dart';
import 'package:avrai/core/models/business/business_expert_preferences.dart';
import 'package:avrai/core/models/business/business_patron_preferences.dart';

import 'business_onboarding_controller_test.mocks.dart';

@GenerateMocks([
  BusinessAccountService,
  BusinessSharedAgentService,
])
void main() {
  group('BusinessOnboardingController', () {
    late BusinessOnboardingController controller;
    late MockBusinessAccountService mockBusinessAccountService;
    late MockBusinessSharedAgentService mockSharedAgentService;

    late BusinessAccount testBusinessAccount;
    final DateTime now = DateTime.now();

    setUp(() {
      mockBusinessAccountService = MockBusinessAccountService();
      mockSharedAgentService = MockBusinessSharedAgentService();

      controller = BusinessOnboardingController(
        businessAccountService: mockBusinessAccountService,
        sharedAgentService: mockSharedAgentService,
      );

      testBusinessAccount = BusinessAccount(
        id: 'business_123',
        name: 'Test Business',
        email: 'test@business.com',
        businessType: 'Restaurant',
        createdAt: now,
        updatedAt: now,
        createdBy: 'user_123',
        isActive: true,
        isVerified: false,
        connectedExpertIds: const [],
        members: const [],
      );
    });

    group('validate', () {
      test('should return valid result for valid input', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: false,
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
      });

      test('should return valid result with warning for shared agent without team members', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: true,
          teamMembers: [],
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, contains('Shared agent enabled but no team members added'));
      });

      test('should return valid result for shared agent with team members', () {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: true,
          teamMembers: ['user_1', 'user_2'],
        );

        // Act
        final result = controller.validate(data);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isEmpty);
      });
    });

    group('completeBusinessOnboarding', () {
      test('should successfully complete onboarding without shared agent', () async {
        // Arrange
        const expertPrefs = BusinessExpertPreferences(
          preferredExpertiseCategories: ['Coffee'],
          minExpertLevel: 3,
        );
        const patronPrefs = BusinessPatronPreferences(
          preferredVibePreferences: ['Cozy', 'Social'],
        );

        final data = BusinessOnboardingData(
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          setupSharedAgent: false,
        );

        final updatedAccount = testBusinessAccount.copyWith(
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.businessAccount?.expertPreferences, equals(expertPrefs));
        expect(result.businessAccount?.patronPreferences, equals(patronPrefs));
        expect(result.sharedAgentId, isNull);

        verify(mockBusinessAccountService.getBusinessAccount('business_123')).called(1);
        verify(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: expertPrefs,
          patronPreferences: patronPrefs,
          requiredExpertise: null,
          preferredCommunities: null,
        )).called(1);
        verifyNever(mockSharedAgentService.initializeSharedAgent(any));
      });

      test('should successfully complete onboarding with shared agent', () async {
        // Arrange
        final data = BusinessOnboardingData(
          setupSharedAgent: true,
          teamMembers: ['user_1', 'user_2'],
        );

        final updatedAccount = testBusinessAccount.copyWith(
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);
        when(mockSharedAgentService.initializeSharedAgent('business_123'))
            .thenAnswer((_) async => 'agent_456');

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
        expect(result.sharedAgentId, equals('agent_456'));

        verify(mockSharedAgentService.initializeSharedAgent('business_123')).called(1);
      });

      test('should return failure for non-existent business account', () async {
        // Arrange
        final data = BusinessOnboardingData();

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => null);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Business account not found'));
        expect(result.errorCode, equals('BUSINESS_NOT_FOUND'));

        verify(mockBusinessAccountService.getBusinessAccount('business_123')).called(1);
        verifyNever(mockBusinessAccountService.updateBusinessAccount(
          any,
          expertPreferences: anyNamed('expertPreferences'),
          patronPreferences: anyNamed('patronPreferences'),
          requiredExpertise: anyNamed('requiredExpertise'),
          preferredCommunities: anyNamed('preferredCommunities'),
        ));
      });

      test('should return failure when update business account fails', () async {
        // Arrange
        final data = BusinessOnboardingData(
          expertPreferences: const BusinessExpertPreferences(),
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: anyNamed('expertPreferences'),
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenThrow(Exception('Update failed'));

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Failed to update business account'));
        expect(result.errorCode, equals('UPDATE_FAILED'));
      });

      test('should return partial success when shared agent initialization fails', () async {
        // Arrange
        final data = BusinessOnboardingData(
          setupSharedAgent: true,
        );

        final updatedAccount = testBusinessAccount.copyWith(
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);
        when(mockSharedAgentService.initializeSharedAgent('business_123'))
            .thenThrow(Exception('Agent init failed'));

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue); // Still success, but with warning
        expect(result.businessAccount, isNotNull);
        expect(result.sharedAgentId, isNull);
        expect(result.warning, contains('shared AI agent setup failed'));
      });

      test('should update business account with required expertise and preferred communities', () async {
        // Arrange
        final data = BusinessOnboardingData(
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
        );

        final updatedAccount = testBusinessAccount.copyWith(
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
          updatedAt: now,
        );

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: ['Coffee', 'Food'],
          preferredCommunities: ['community_1', 'community_2'],
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.completeBusinessOnboarding(
          businessId: 'business_123',
          data: data,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount?.requiredExpertise, containsAll(['Coffee', 'Food']));
        expect(result.businessAccount?.preferredCommunities, containsAll(['community_1', 'community_2']));
      });
    });

    group('execute (WorkflowController interface)', () {
      test('should execute workflow via execute method', () async {
        // Arrange
        final data = BusinessOnboardingData(
          businessId: 'business_123',
          setupSharedAgent: false,
        );

        final updatedAccount = testBusinessAccount.copyWith(updatedAt: now);

        when(mockBusinessAccountService.getBusinessAccount('business_123'))
            .thenAnswer((_) async => testBusinessAccount);
        when(mockBusinessAccountService.updateBusinessAccount(
          testBusinessAccount,
          expertPreferences: null,
          patronPreferences: null,
          requiredExpertise: null,
          preferredCommunities: null,
        )).thenAnswer((_) async => updatedAccount);

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isTrue);
        expect(result.businessAccount, isNotNull);
      });

      test('should return failure when businessId is missing', () async {
        // Arrange
        final data = BusinessOnboardingData(
          // businessId is null
        );

        // Act
        final result = await controller.execute(data);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('Business ID is required'));
        expect(result.errorCode, equals('VALIDATION_ERROR'));
      });
    });

    group('rollback', () {
      test('should not throw when rollback is called', () async {
        // Arrange
        final result = BusinessOnboardingResult.success(
          businessAccount: testBusinessAccount,
        );

        // Act & Assert
        expect(() => controller.rollback(result), returnsNormally);
        await controller.rollback(result);
      });
    });
  });
}
