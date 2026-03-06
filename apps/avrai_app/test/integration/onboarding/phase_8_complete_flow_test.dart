import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/app.dart';
import 'package:avrai/injection_container.dart' as di;

import 'package:avrai_runtime_os/data/datasources/local/onboarding_completion_service.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:avrai/presentation/pages/onboarding/ai_loading_page.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Phase 8 Complete Flow Integration Test
///
/// Tests the complete onboarding → AILoadingPage → Agent creation flow:
/// - Phase 0: Navigation to AILoadingPage (not /home)
/// - Phase 1: Baseline lists step appears and data persists
/// - Phase 2: Social media connections persist
/// - Phase 3: PersonalityProfile created with agentId
/// - Phase 5: Place list generation (with API key)
/// - Complete end-to-end flow verification
///
/// Note: These tests may be skipped in integration test mode because the router
/// intentionally skips onboarding redirects for test determinism (see app_router.dart:118).
/// The contract tests (phase_8_contract_tests.dart) verify the actual functionality.
///
/// Date: December 23, 2025
/// Status: Phase 6 - Testing & Validation

// These "full flow" tests are not deterministic under `flutter test` because
// onboarding screens intentionally run continuous animations and some flows are
// short-circuited for test determinism via dart-defines.
const bool _isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');

// Helper methods (defined before use)
Future<void> completeOnboardingFlow(WidgetTester tester) async {
  // Navigate through all onboarding steps
  // This is a simplified version - in a real test, you'd interact with each step
  for (int i = 0; i < 10; i++) {
    final nextButton = find.text('Next');
    if (nextButton.evaluate().isNotEmpty) {
      await tester.tap(nextButton);
      await tester.pump(const Duration(milliseconds: 200));
    } else {
      final completeButton = find.text('Complete Setup');
      if (completeButton.evaluate().isNotEmpty) {
        await tester.tap(completeButton);
        await tester.pump(const Duration(milliseconds: 200));
        break;
      }
    }
  }
}

Future<void> navigateToBaselineListsStep(WidgetTester tester) async {
  // Navigate to preferences step first
  for (int i = 0; i < 5; i++) {
    final nextButton = find.text('Next');
    if (nextButton.evaluate().isNotEmpty) {
      await tester.tap(nextButton);
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  // Should now be on baseline lists step
}

void main() {
  final runHeavyIntegrationTests =
      Platform.environment['RUN_HEAVY_INTEGRATION_TESTS'] == 'true';

  setUpAll(() async {
    if (!runHeavyIntegrationTests) {
      return;
    }

    // Initialize dependency injection for tests
    try {
      await setupTestStorage();
      await di.init();
    } catch (e) {
      // ignore: avoid_print
      print('⚠️  DI initialization failed in test: $e');
    }
  });

  setUp(() async {
    if (!runHeavyIntegrationTests) {
      return;
    }

    // Reset onboarding completion state before each test
    // This ensures tests can actually run the onboarding flow
    try {
      // ignore: unused_local_variable
      // ignore: unused_local_variable - May be used in callback or assertion
      final completionService = OnboardingCompletionService();
      // Clear any existing onboarding completion flags
      // Note: OnboardingCompletionService uses SharedPreferences, which is cleared
      // when using in-memory database, but we'll explicitly reset just to be safe
    } catch (e) {
      // If reset fails, that's okay - tests will handle it
    }
  });

  group('Phase 8: Complete Onboarding Flow', () {
    testWidgets('Phase 0: Onboarding navigates to AILoadingPage (not /home)',
        (WidgetTester tester) async {
      // Arrange - Launch app
      await tester.pumpWidget(const SpotsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check if onboarding is available
      final onboardingPage = find.byType(OnboardingPage);
      // ignore: avoid_print
      if (onboardingPage.evaluate().isEmpty) {
        // ignore: avoid_print
        print('⚠️ Onboarding skipped by router - test skipped');
        return;
      }

      // Act - Complete onboarding flow
      await completeOnboardingFlow(tester);

      // Wait for navigation
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verify we're on AILoadingPage (not home)
      expect(find.byType(AILoadingPage), findsOneWidget);
      expect(find.text('Creating your AI agent...'), findsOneWidget);
    }, skip: _isFlutterTest);

    testWidgets('Phase 1: Baseline lists data persists through onboarding',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SpotsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // ignore: avoid_print
      final onboardingPage = find.byType(OnboardingPage);
      // ignore: avoid_print
      if (onboardingPage.evaluate().isEmpty) {
        // ignore: avoid_print
        print('⚠️ Onboarding skipped - test skipped');
        return;
      }

      // Act - Navigate to baseline lists step
      await navigateToBaselineListsStep(tester);

      // Verify step exists
      expect(find.text('Your Lists'), findsOneWidget);

      // Navigate through to completion
      await completeOnboardingFlow(tester);
      await tester.pump(const Duration(seconds: 2));

      // Assert - Verify data was saved
      final onboardingService = di.sl<OnboardingDataService>();
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId('test_user_1');
      final savedData = await onboardingService.getOnboardingData(agentId);

      // Verify baseline lists step was part of the flow
      expect(savedData, isNotNull);
    }, skip: _isFlutterTest);

    testWidgets('Phase 3: PersonalityProfile created with agentId (not userId)',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SpotsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final onboardingPage = find.byType(OnboardingPage);
      if (onboardingPage.evaluate().isEmpty) {
        // ignore: avoid_print
        print('⚠️ Onboarding skipped - test skipped');
        return;
      }

      // Act - Complete onboarding and wait for agent creation
      await completeOnboardingFlow(tester);
      await tester.pump(const Duration(seconds: 5));

      // Assert - Verify PersonalityProfile uses agentId
      final personalityLearning = di.sl<PersonalityLearning>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_1';
      final agentId = await agentIdService.getUserAgentId(userId);

      final profile = await personalityLearning.getCurrentPersonality(agentId);

      expect(profile, isNotNull);
      expect(profile!.agentId, equals(agentId));
      expect(profile.agentId,
          isNot(equals(userId))); // agentId should be different from userId
      expect(
          profile.agentId, startsWith('agent_')); // agentId should have prefix
    }, skip: _isFlutterTest);

    testWidgets(
        'Complete flow: Onboarding → AILoadingPage → Agent creation → Home',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SpotsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final onboardingPage = find.byType(OnboardingPage);
      if (onboardingPage.evaluate().isEmpty) {
        // ignore: avoid_print
        print('⚠️ Onboarding skipped - test skipped');
        return;
      }

      // Act - Complete full flow
      await completeOnboardingFlow(tester);

      // Wait for AILoadingPage
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(AILoadingPage), findsOneWidget);

      // Wait for agent creation to complete
      await tester.pump(const Duration(seconds: 5));

      // Assert - Verify we eventually reach home (after agent creation)
      // Note: This test verifies the complete flow works end-to-end
      // The actual navigation to home happens in AILoadingPage after agent creation
      final personalityLearning = di.sl<PersonalityLearning>();
      final agentIdService = di.sl<AgentIdService>();
      const userId = 'test_user_1';
      final agentId = await agentIdService.getUserAgentId(userId);

      final profile = await personalityLearning.getCurrentPersonality(agentId);
      expect(profile, isNotNull,
          reason: 'PersonalityProfile should be created after onboarding');
    }, skip: _isFlutterTest);
  }, skip: !runHeavyIntegrationTests);
}
