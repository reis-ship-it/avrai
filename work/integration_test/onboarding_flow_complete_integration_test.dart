import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:avrai/app.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/configs/firebase_options.dart';
import 'package:avrai_runtime_os/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/onboarding_completion_service.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:avrai/presentation/pages/onboarding/age_collection_page.dart';
import 'package:avrai/presentation/pages/onboarding/homebase_selection_page.dart';
import 'package:avrai/presentation/pages/onboarding/favorite_places_page.dart';
import 'package:avrai/presentation/pages/onboarding/preference_survey_page.dart';
import 'package:avrai/presentation/pages/onboarding/baseline_lists_page.dart';
import 'package:avrai/presentation/pages/onboarding/friends_respect_page.dart';
import 'package:avrai/presentation/pages/home/home_page.dart';
import 'package:avrai/presentation/pages/onboarding/onboarding_step.dart'
    show PermissionsPage;
import 'package:avrai/presentation/pages/onboarding/welcome_page.dart';
import 'package:avrai/presentation/pages/onboarding/legal_acceptance_dialog.dart';
import 'package:avrai/presentation/pages/legal/terms_of_service_page.dart';
import 'package:avrai/presentation/pages/legal/privacy_policy_page.dart';
import 'package:avrai/presentation/pages/onboarding/ai_loading_page.dart';

const String _testEmail = 'demo@avrai.app';
const String _testPassword = 'password123';
late String _testUserId;

/// avrai Complete Onboarding Flow Integration Test
///
/// Date: December 12, 2025
/// Purpose: Comprehensive end-to-end integration test for complete onboarding flow
///
/// Test Coverage:
/// - Complete onboarding flow from start to finish
/// - All 8 onboarding steps (Welcome, Permissions, Age, Homebase, Favorite Places, Preferences, Baseline Lists, Friends)
/// - Form field interactions and data entry
/// - State persistence across steps
/// - Navigation (forward and backward)
/// - Data validation
/// - Completion and transition to main app
///
/// Usage:
/// ```bash
/// flutter test integration_test/onboarding_flow_complete_integration_test.dart
/// ```
///
/// Or for device testing:
/// ```bash
/// flutter test integration_test/onboarding_flow_complete_integration_test.dart --device-id=<device-id>
/// ```

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase before dependency injection
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // Firebase initialization may fail in test environment, continue anyway
      // ignore: avoid_print
      print(
          '⚠️ Firebase initialization failed (expected in some test environments): $e');
    }

    // Initialize dependency injection for tests
    await di.init();

    // Ensure we start authenticated so the router can complete onboarding
    final authLocal = di.sl<AuthLocalDataSource>();
    final user = await authLocal.signIn(_testEmail, _testPassword);
    if (user == null) {
      throw StateError(
        'Integration test setup failed: could not sign in demo user ($_testEmail).',
      );
    }
    _testUserId = user.id;
  });

  tearDownAll(() async {
    // Wait for any pending async operations to complete
    await Future.delayed(const Duration(milliseconds: 500));
  });

  group('Complete Onboarding Flow Integration Tests', () {
    setUp(() async {
      // Each test must start with onboarding NOT completed, otherwise router goes to /home.
      await OnboardingCompletionService.resetOnboardingCompletion(_testUserId);
    });

    testWidgets('completes full onboarding flow with all steps',
        (WidgetTester tester) async {
      // Arrange - Launch app
      await tester.pumpWidget(const SpotsApp());
      await _pumpUntilFound(tester, find.byType(OnboardingPage));

      // Navigate to onboarding if not already there
      await _ensureOnOnboardingPage(tester);

      // Act & Assert - Complete onboarding flow step by step
      await _testCompleteOnboardingFlow(tester);

      // Verify we reached the home page
      await _pumpUntilFound(tester, find.byType(HomePage),
          timeout: const Duration(seconds: 30));
      expect(find.byType(OnboardingPage), findsNothing,
          reason: 'Should have left onboarding page after completion');
      expect(find.byType(HomePage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets('navigates backward and forward through onboarding steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(const SpotsApp());
      await _pumpUntilFound(tester, find.byType(OnboardingPage));
      await _ensureOnOnboardingPage(tester);

      // Move through welcome -> permissions -> age (and fill age so Next works)
      await _testWelcomeStep(tester);
      await _testPermissionsStep(tester);
      await _testAgeCollection(tester); // ends on Homebase step

      // Navigate backward
      final backButton = find.text('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pump(const Duration(milliseconds: 300));

        // Verify we're back on Age step
        expect(find.byType(AgeCollectionPage), findsOneWidget);
      }

      // Navigate forward again
      await _navigateToNextStep(
        tester,
        fromStep: find.byType(AgeCollectionPage),
        expectAfter: find.byType(HomebaseSelectionPage),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HomebaseSelectionPage), findsOneWidget);
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('preserves data when navigating between steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(const SpotsApp());
      await _pumpUntilFound(tester, find.byType(OnboardingPage));
      await _ensureOnOnboardingPage(tester);

      // Navigate to age collection step
      await _testWelcomeStep(tester);
      await _testPermissionsStep(tester);
      expect(find.byType(AgeCollectionPage), findsOneWidget);

      // Enter birthday
      await _testAgeCollection(tester);

      // We should now be on homebase
      expect(find.byType(HomebaseSelectionPage), findsOneWidget);

      // Navigate back
      final backButton = find.text('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pump(const Duration(milliseconds: 300));

        // Verify age collection page is still there (and Next is enabled)
        expect(find.byType(AgeCollectionPage), findsOneWidget);
        final nextButton = find.widgetWithText(ElevatedButton, 'Next');
        expect(nextButton, findsOneWidget);
        final button = tester.widget<ElevatedButton>(nextButton);
        expect(button.onPressed, isNotNull,
            reason: 'Next should remain enabled if birthday is preserved');
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    testWidgets('validates required fields before proceeding',
        (WidgetTester tester) async {
      await tester.pumpWidget(const SpotsApp());
      await _pumpUntilFound(tester, find.byType(OnboardingPage));
      await _ensureOnOnboardingPage(tester);

      // Navigate to age collection (required field)
      await _testWelcomeStep(tester);
      await _testPermissionsStep(tester);
      expect(find.byType(AgeCollectionPage), findsOneWidget);

      // Try to proceed without filling required field
      final nextButton = find.widgetWithText(ElevatedButton, 'Next');
      expect(nextButton, findsOneWidget);
      final button = tester.widget<ElevatedButton>(nextButton);

      // Button should be disabled if required fields are missing
      // Note: Based on code, age step requires _selectedBirthday != null
      expect(button.onPressed, isNull,
          reason:
              'Next button should be disabled when birthday is not selected');
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

/// Ensure we're on the onboarding page, navigate there if needed
Future<void> _ensureOnOnboardingPage(WidgetTester tester) async {
  // With demo auth in setUpAll, the router should redirect us into onboarding.
  await _pumpUntilSingleOnboardingPage(tester);
}

/// Test complete onboarding flow through all steps
// ignore: avoid_print
Future<void> _testCompleteOnboardingFlow(WidgetTester tester) async {
  // ignore: avoid_print
  print('🚀 Starting complete onboarding flow test...');
  // ignore: avoid_print

  // ignore: avoid_print
  // Step 1: Welcome Screen
  // ignore: avoid_print
  print('📋 Step 1: Welcome Screen');
  // ignore: avoid_print
  await _testWelcomeStep(tester);

  // Step 2: Permissions
  // ignore: avoid_print
  print('📋 Step 2: Permissions');
  await _testPermissionsStep(tester);

  // ignore: avoid_print
  // ignore: avoid_print
  // Step 3: Age Collection
  // ignore: avoid_print
  print('📋 Step 3: Age Collection');
  await _testAgeCollection(tester);
  // ignore: avoid_print
  // ignore: avoid_print

  // ignore: avoid_print
  // Step 4: Homebase Selection
  // ignore: avoid_print
  print('📋 Step 4: Homebase Selection');
  // ignore: avoid_print
  await _testHomebaseSelection(tester);

  // Step 5: Favorite Places
  // ignore: avoid_print
  print('📋 Step 5: Favorite Places');
  // ignore: avoid_print
  await _testFavoritePlaces(tester);

  // ignore: avoid_print
  // ignore: avoid_print
  // Step 6: Preferences Survey
  // ignore: avoid_print
  print('📋 Step 6: Preferences Survey');
  await _testPreferencesSurvey(tester);
  // ignore: avoid_print

  // Step 7: Baseline Lists
  // ignore: avoid_print
  // ignore: avoid_print
  print('📋 Step 7: Baseline Lists');
  await _testBaselineLists(tester);
  // ignore: avoid_print

  // Step 8: Friends & Respect
  // ignore: avoid_print
  print('📋 Step 8: Friends & Respect');
  // ignore: avoid_print
  await _testFriendsRespect(tester);

  // ignore: avoid_print
  // Complete onboarding
  // ignore: avoid_print
  print('✅ Completing onboarding...');
  await _completeOnboarding(tester);
  // ignore: avoid_print

  // ignore: avoid_print
  print('🎉 Onboarding flow completed successfully!');
}

/// Test welcome step
Future<void> _testWelcomeStep(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));

  // Onboarding step 1 is the WelcomePage (tap-anywhere-to-continue).
  expect(find.byType(OnboardingPage), findsOneWidget);
  expect(find.byType(WelcomePage), findsOneWidget);

  // Tap anywhere on the welcome page to continue
  await tester.tapAt(const Offset(200, 400));
  await tester
      .pump(const Duration(milliseconds: 600)); // fade out + page change

  // Now on permissions step
  await _pumpUntilFound(tester, find.byType(PermissionsPage));
}

/// Test permissions step
Future<void> _testPermissionsStep(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(PermissionsPage));

  expect(find.byType(PermissionsPage), findsOneWidget);

  // NOTE: Do not tap "Enable All" here; iOS permission dialogs can block tests.
  await _navigateToNextStep(
    tester,
    fromStep: find.byType(PermissionsPage),
    expectAfter: find.byType(AgeCollectionPage),
  );
}

/// Test age collection step
Future<void> _testAgeCollection(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(AgeCollectionPage));

  expect(find.byType(AgeCollectionPage), findsOneWidget);

  // AgeCollectionPage uses a Card/InkWell + showDatePicker (no TextField).
  // Open the date picker.
  final tapToSelect = find.textContaining('Tap to select your birthday');
  if (tapToSelect.evaluate().isNotEmpty) {
    await tester.tap(tapToSelect.first);
  } else {
    // Fallback: tap the card label
    await tester.tap(find.text('Birthday'));
  }
  await tester.pump(const Duration(milliseconds: 300));

  // Wait for the Material date picker to appear.
  await _pumpUntilFound(tester, find.byType(DatePickerDialog),
      timeout: const Duration(seconds: 10));

  // Pick a day that should exist in any month view.
  final day15 = find.text('15');
  expect(day15, findsWidgets);
  await tester.tap(day15.last);
  await tester.pump(const Duration(milliseconds: 200));

  // Confirm
  final okButton = find.text('OK');
  expect(okButton, findsWidgets);
  await tester.tap(okButton.last);
  await tester.pump(const Duration(milliseconds: 400));

  // Verify Next button is now enabled (birthday selected)
  final nextButton = find.widgetWithText(ElevatedButton, 'Next');
  expect(nextButton, findsOneWidget);
  final button = tester.widget<ElevatedButton>(nextButton);
  // Button should be enabled now
  expect(button.onPressed, isNotNull,
      reason: 'Next button should be enabled after selecting birthday');

  // Proceed to next step
  await _navigateToNextStep(
    tester,
    fromStep: find.byType(AgeCollectionPage),
    expectAfter: find.byType(HomebaseSelectionPage),
  );
}

/// Test homebase selection step
Future<void> _testHomebaseSelection(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(HomebaseSelectionPage));

  expect(find.byType(HomebaseSelectionPage), findsOneWidget);

  // Wait for map to load
  await tester.pump(const Duration(milliseconds: 500));

  // Try to find and interact with location input or map
  // Look for text field to enter location
  final locationFields = find.byType(TextField);
  if (locationFields.evaluate().isNotEmpty) {
    // Enter a test location
    await tester.enterText(locationFields.first, 'New York, NY');
    await tester.pump(const Duration(milliseconds: 300));

    // Tap on a suggestion if available
    final suggestions = find.textContaining('New York');
    if (suggestions.evaluate().isNotEmpty) {
      await tester.tap(suggestions.first);
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  // Alternative: Try to tap on the map to select a location
  // This is simplified - in reality, you'd need to find the map widget and tap coordinates
  final mapWidget = find.byType(HomebaseSelectionPage);
  if (mapWidget.evaluate().isNotEmpty) {
    // Tap in the center of the map (simulated location selection)
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  // Proceed to next step
  await _navigateToNextStep(
    tester,
    fromStep: find.byType(HomebaseSelectionPage),
    expectAfter: find.byType(FavoritePlacesPage),
  );
}

/// Test favorite places step
Future<void> _testFavoritePlaces(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(FavoritePlacesPage));

  expect(find.byType(FavoritePlacesPage), findsOneWidget);

  // Select at least one place from vibe categories (avoid typing search, which can
  // trigger small-viewport overflows).
  final pageScope = find.byType(FavoritePlacesPage).first;

  final nyAreaTile = find.descendant(
    of: pageScope,
    matching: find.widgetWithText(ExpansionTile, 'New York Area'),
  );
  await _pumpUntilFound(tester, nyAreaTile);
  final nyAreaTitle = find.descendant(
      of: nyAreaTile.first, matching: find.text('New York Area'));
  await tester.tap(nyAreaTitle.first);
  await tester.pump(const Duration(milliseconds: 300));

  final brooklynTile = find.descendant(
    of: pageScope,
    matching: find.widgetWithText(ExpansionTile, 'Brooklyn'),
  );
  await _pumpUntilFound(tester, brooklynTile);
  // Expand the Brooklyn city tile
  final brooklynTitle =
      find.descendant(of: brooklynTile.first, matching: find.text('Brooklyn'));
  await tester.tap(brooklynTitle.first);
  await tester.pump(const Duration(milliseconds: 500));

  // Pick a neighborhood; selection adds "Park Slope, Brooklyn" to chosen places.
  final parkSlope =
      find.descendant(of: pageScope, matching: find.text('Park Slope'));
  await _pumpUntilFound(tester, parkSlope);
  await tester.tap(parkSlope.first);
  await tester.pump(const Duration(milliseconds: 300));

  // Verify selection registered (chip should appear)
  await _pumpUntilFound(
    tester,
    find.descendant(of: pageScope, matching: find.text('Park Slope, Brooklyn')),
    timeout: const Duration(seconds: 5),
  );

  // Proceed to next step
  await _swipeToNextStep(tester,
      expectAfter: find.byType(PreferenceSurveyPage));
}

Future<void> _swipeToNextStep(
  WidgetTester tester, {
  required Finder expectAfter,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final pageView = find.byType(PageView);
  expect(pageView, findsOneWidget, reason: 'Expected onboarding PageView');
  await tester.drag(pageView, const Offset(-400, 0));
  await tester.pump(const Duration(milliseconds: 600));
  await _pumpUntilFound(tester, expectAfter, timeout: timeout);
}

/// Test preferences survey step
Future<void> _testPreferencesSurvey(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(PreferenceSurveyPage));

  expect(find.byType(PreferenceSurveyPage), findsOneWidget);

  // Select a couple preferences (FilterChips inside ExpansionTiles).
  final pageScope = find.byType(PreferenceSurveyPage);
  final foodTile = find.descendant(
    of: pageScope,
    matching: find.widgetWithText(ExpansionTile, 'Food & Drink'),
  );
  await _pumpUntilFound(tester, foodTile);
  await tester.tap(foodTile.first);
  await tester.pump(const Duration(milliseconds: 400));

  final coffeeChip = find.descendant(
    of: pageScope,
    matching: find.widgetWithText(FilterChip, 'Coffee & Tea'),
  );
  await _pumpUntilFound(tester, coffeeChip);
  await tester.tap(coffeeChip.first);
  await tester.pump(const Duration(milliseconds: 200));

  final barsChip = find.descendant(
    of: pageScope,
    matching: find.widgetWithText(FilterChip, 'Bars & Pubs'),
  );
  if (barsChip.evaluate().isNotEmpty) {
    await tester.tap(barsChip.first);
    await tester.pump(const Duration(milliseconds: 200));
  }

  // Proceed to next step (swipe is more reliable than tapping Next in tests).
  await _swipeToNextStep(tester, expectAfter: find.byType(BaselineListsPage));
}

/// Test baseline lists step
Future<void> _testBaselineLists(WidgetTester tester) async {
  await _pumpUntilFound(tester, find.byType(BaselineListsPage));

  expect(find.byType(BaselineListsPage), findsOneWidget);

  // Look for list items or add buttons
  final listTiles = find.byType(ListTile);
  final checkboxes = find.byType(Checkbox);

  // Select some baseline lists
  if (checkboxes.evaluate().isNotEmpty) {
    // Select first few lists
    for (int i = 0; i < checkboxes.evaluate().length && i < 3; i++) {
      await tester.tap(checkboxes.at(i));
      await tester.pump(const Duration(milliseconds: 200));
    }
  } else if (listTiles.evaluate().isNotEmpty) {
    // Tap on list tiles to select them
    for (int i = 0; i < listTiles.evaluate().length && i < 3; i++) {
      await tester.tap(listTiles.at(i));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  // Proceed to next step (swipe is more reliable than tapping Next in tests).
  await _swipeToNextStep(tester, expectAfter: find.byType(FriendsRespectPage));
  // ignore: avoid_print
}

/// Test friends and respect step
Future<void> _testFriendsRespect(WidgetTester tester) async {
  // ignore: avoid_print
  await _pumpUntilFound(tester, find.byType(FriendsRespectPage));

  expect(find.byType(FriendsRespectPage), findsOneWidget);
  // ignore: avoid_print

  // This step is optional. Avoid interacting with list tiles here because it can open
  // bottom-sheets/overlays that obscure the "Complete Setup" CTA in tests.
  // ignore: avoid_print

  // ignore: avoid_print
  // Ready to complete onboarding
  // ignore: avoid_print
  print('✅ Friends step completed (optional step)');
}

/// Complete onboarding and proceed to main app
Future<void> _completeOnboarding(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));

  // Look for "Complete Setup" button (last step)
  await _pumpUntilFound(tester, find.text('Complete Setup'),
      timeout: const Duration(seconds: 10));

  // Tap the onboarding CTA by key to avoid offstage duplicates.
  final cta = find.byKey(const Key('onboarding_primary_cta')).hitTestable();
  expect(cta, findsOneWidget, reason: 'Expected the onboarding primary CTA');
  final button = tester.widget<ElevatedButton>(cta.first);
  expect(button.onPressed, isNotNull,
      reason: 'Complete Setup CTA is disabled.');
  expect(
    find.descendant(of: cta.first, matching: find.text('Complete Setup')),
    findsOneWidget,
    reason: 'Expected to be on the final onboarding step (Complete Setup).',
  );

  final prevFatal = WidgetController.hitTestWarningShouldBeFatal;
  WidgetController.hitTestWarningShouldBeFatal = true;
  try {
    await tester.tap(cta.first);
  } finally {
    WidgetController.hitTestWarningShouldBeFatal = prevFatal;
  }
  await tester.pump(const Duration(milliseconds: 600));

  // If nothing happened, retry with a bottom-center tap (common in offstage-duplicate trees).
  if (find.byType(AILoadingPage).evaluate().isEmpty &&
      find.byType(LegalAcceptanceDialog).evaluate().isEmpty &&
      find.byType(HomePage).evaluate().isEmpty) {
    final viewSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    await tester.tapAt(Offset(viewSize.width / 2, viewSize.height - 40));
    await tester.pump(const Duration(milliseconds: 600));
  }

  await _handleLegalAcceptanceIfPresent(tester);

  final landedOn = await _pumpUntilAnyFound(
    tester,
    [
      find.byType(AILoadingPage),
      find.byType(HomePage),
    ],
    timeout: const Duration(seconds: 10),
  );

  // If we hit AI loading, wait for completion + redirect to home.
  if (landedOn == _PumpAnyResult.aiLoading) {
    await _pumpUntilFound(
      tester,
      find.byType(HomePage),
      timeout: const Duration(seconds: 45),
    );
  }

  expect(find.byType(OnboardingPage), findsNothing,
      reason: 'Should have left onboarding page after completion');
  expect(find.byType(HomePage), findsOneWidget);
}

enum _PumpAnyResult { aiLoading, home }

Future<_PumpAnyResult> _pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    // Order matters: return the first match in the provided list.
    for (int i = 0; i < finders.length; i++) {
      final finder = finders[i];
      try {
        if (finder.evaluate().isNotEmpty) {
          return i == 0 ? _PumpAnyResult.aiLoading : _PumpAnyResult.home;
        }
      } catch (_) {
        // Ignore transient finder errors during navigation.
      }
    }
  }
  throw TestFailure(
      'Timed out waiting for onboarding completion (ai-loading or home).');
}

Future<void> _handleLegalAcceptanceIfPresent(WidgetTester tester) async {
  // If legal acceptance is required, the onboarding completion flow blocks until accepted.
  // In most runs it won't appear at all, so bail quickly if not shown.
  final appearDeadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(appearDeadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (find.byType(LegalAcceptanceDialog).evaluate().isNotEmpty) {
      break;
    }
    if (find.byType(AILoadingPage).evaluate().isNotEmpty ||
        find.byType(HomePage).evaluate().isNotEmpty) {
      return;
    }
  }

  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));

    if (find.byType(HomePage).evaluate().isNotEmpty) {
      return;
    }
    if (find.byType(AILoadingPage).evaluate().isNotEmpty) {
      return;
    }

    final dialog = find.byType(LegalAcceptanceDialog);
    if (dialog.evaluate().isEmpty) {
      continue;
    }

    // If Terms required, open and accept.
    final termsTile = find.widgetWithText(ListTile, 'Terms of Service');
    if (termsTile.evaluate().isNotEmpty) {
      await tester.tap(termsTile.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      await _pumpUntilFound(tester, find.byType(TermsOfServicePage),
          timeout: const Duration(seconds: 10));
      final acceptTerms = find.text('I Accept the Terms of Service');
      await _pumpUntilFound(tester, acceptTerms,
          timeout: const Duration(seconds: 10));
      await tester.tap(acceptTerms.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 900));
      continue;
    }

    // If Privacy required, open and accept.
    final privacyTile = find.widgetWithText(ListTile, 'Privacy Policy');
    if (privacyTile.evaluate().isNotEmpty) {
      await tester.tap(privacyTile.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      await _pumpUntilFound(tester, find.byType(PrivacyPolicyPage),
          timeout: const Duration(seconds: 10));
      final acceptPrivacy = find.text('I Accept the Privacy Policy');
      await _pumpUntilFound(tester, acceptPrivacy,
          timeout: const Duration(seconds: 10));
      await tester.tap(acceptPrivacy.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 900));
      continue;
    }

    // If everything accepted, dialog shows Continue.
    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      return;
    }
  }
}

/// Navigate to next step in onboarding
Future<void> _navigateToNextStep(
  WidgetTester tester, {
  required Finder fromStep,
  Finder? expectAfter,
  Duration timeout = const Duration(seconds: 15),
}) async {
  // Prefer hit-testable widgets to avoid offstage duplicates.
  final step = fromStep.hitTestable();
  expect(step, findsWidgets,
      reason: 'Expected current step to be hit-testable');

  final onboarding =
      find.ancestor(of: step.first, matching: find.byType(OnboardingPage));
  expect(onboarding, findsOneWidget,
      reason: 'Expected a single OnboardingPage owning the active step');

  final cta = find.byKey(const Key('onboarding_primary_cta')).hitTestable();
  expect(cta, findsOneWidget, reason: 'Expected the onboarding primary CTA');

  final button = tester.widget<ElevatedButton>(cta);
  expect(button.onPressed, isNotNull,
      reason: 'Next button is disabled; required fields not satisfied.');

  await tester.tap(cta);
  await tester.pump(const Duration(milliseconds: 450));

  if (expectAfter == null) return;
  await _pumpUntilFound(tester, expectAfter, timeout: timeout);
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    try {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    } catch (_) {
      // Finder may temporarily become invalid during navigation/transitions.
      // Keep pumping until timeout.
    }
  }
  throw TestFailure('Timed out waiting for expected widget.');
}

Future<void> _pumpUntilSingleOnboardingPage(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
  Duration step = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    final count = find.byType(OnboardingPage).evaluate().length;
    if (count == 1) {
      return;
    }
  }
  final count = find.byType(OnboardingPage).evaluate().length;
  throw TestFailure(
    'Expected a single OnboardingPage after redirects settled, but found $count.',
  );
}
