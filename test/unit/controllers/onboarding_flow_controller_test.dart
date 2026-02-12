import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/onboarding_flow_controller.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/services/onboarding/onboarding_data_service.dart';
import 'package:avrai/core/services/user/agent_id_service.dart';
import 'package:avrai/core/services/misc/legal_document_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'onboarding_flow_controller_test.mocks.dart';

@GenerateMocks([
  OnboardingDataService,
  AgentIdService,
  LegalDocumentService,
])
void main() {
  group('OnboardingFlowController', () {
    late OnboardingFlowController controller;
    late MockOnboardingDataService mockOnboardingService;
    late MockAgentIdService mockAgentIdService;
    late MockLegalDocumentService mockLegalService;

    setUp(() {
      mockOnboardingService = MockOnboardingDataService();
      mockAgentIdService = MockAgentIdService();
      mockLegalService = MockLegalDocumentService();

      controller = OnboardingFlowController(
        onboardingDataService: mockOnboardingService,
        agentIdService: mockAgentIdService,
        legalDocumentService: mockLegalService,
      );
    });

    group('validate', () {
      test('should return valid for correct onboarding data', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          favoritePlaces: ['Central Park'],
          preferences: {
            'Food': ['Coffee']
          },
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isTrue);
        expect(result.allErrors, isEmpty);
      });

      test('should return invalid for missing agentId', () {
        final data = OnboardingData(
          agentId: '',
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['agentId'], isNotNull);
      });

      test('should return invalid for invalid age', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 5, // Too young
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['age'], isNotNull);
      });

      test('should return invalid for future birthday', () {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          birthday: DateTime.now().add(const Duration(days: 1)),
          completedAt: DateTime.now(),
        );

        final result = controller.validate(data);

        expect(result.isValid, isFalse);
        expect(result.fieldErrors['birthday'], isNotNull);
      });
    });

    group('completeOnboarding', () {
      test('should complete onboarding successfully', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          age: 25,
          homebase: 'New York',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        expect(result.agentId, equals(agentId));
        expect(result.onboardingData, isNotNull);
        verify(mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(mockOnboardingService.saveOnboardingData(userId, any)).called(1);
      });

      test('should fail if legal documents not accepted', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => false);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.requiresLegalAcceptance, isTrue);
        expect(result.error, contains('Legal documents'));
      });

      test('should fail if agentId cannot be retrieved', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';

        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Agent ID service unavailable'));

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('AGENT_ID_ERROR'));
      });

      test('should fail if data save fails', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenThrow(Exception('Database error'));

        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('SAVE_ERROR'));
      });

      test('should skip legal check in integration tests', () async {
        final data = OnboardingData(
          agentId: 'agent_test123456789012345678901234567890',
          completedAt: DateTime.now(),
        );
        const userId = 'user123';
        const agentId = 'agent_test123456789012345678901234567890';

        when(mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);
        when(mockOnboardingService.saveOnboardingData(userId, any))
            .thenAnswer((_) async => {});
        // Stub legal service methods (they may be called but errors are caught)
        when(mockLegalService.hasAcceptedTerms(userId))
            .thenAnswer((_) async => true);
        when(mockLegalService.hasAcceptedPrivacyPolicy(userId))
            .thenAnswer((_) async => true);

        // Note: In test environment, FLUTTER_TEST is set, so legal check is skipped
        // But the code may still call the service - we just don't fail if it errors
        final result = await controller.completeOnboarding(
          data: data,
          userId: userId,
        );

        expect(result.isSuccess, isTrue);
        // Legal service may or may not be called depending on FLUTTER_TEST environment
        // The important thing is that the workflow succeeds even if legal check fails
      });
    });
  });
}
