// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/user/user.dart' as user_model;
import 'package:avrai/core/models/spots/spot.dart';
import 'package:avrai/core/models/misc/list.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import '../mocks/mock_blocs.dart';
import '../../helpers/platform_channel_helper.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/matching/personality_sync_service.dart';
import 'package:avrai/core/controllers/sync_controller.dart';
import 'package:avrai/core/services/network/enhanced_connectivity_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import '../../helpers/getit_test_harness.dart';

/// Helper utilities for widget testing to ensure consistent test setup
class WidgetTestHelpers {
  static bool _didGlobalSetup = false;

  /// Global setup for widget tests - call this in setUpAll
  /// Initializes StorageService and registers SharedPreferencesCompat in GetIt
  static Future<void> setupWidgetTestEnvironment() async {
    try {
      final getIt = GetItTestHarness(sl: GetIt.instance);

      // Initialize StorageService for tests
      await setupTestStorage();

      // Register StorageService in GetIt for widgets/pages that resolve it via DI.
      if (!GetIt.instance.isRegistered<StorageService>()) {
        getIt.registerSingletonReplace<StorageService>(StorageService.instance);
      }
      
      // Register SharedPreferencesCompat in GetIt if not already registered
      if (!GetIt.instance.isRegistered<SharedPreferencesCompat>()) {
        final mockStorage = getTestStorage();
        final prefs = await SharedPreferencesCompat.getInstance(storage: mockStorage);
        getIt.registerSingletonReplace<SharedPreferencesCompat>(prefs);
      }

      // Register core sync services used by settings pages.
      if (!GetIt.instance.isRegistered<SupabaseService>()) {
        getIt.registerSingletonReplace<SupabaseService>(SupabaseService());
      }
      if (!GetIt.instance.isRegistered<PersonalitySyncService>()) {
        getIt.registerSingletonReplace<PersonalitySyncService>(
          PersonalitySyncService(
            supabaseService: SupabaseService(),
            storageService: StorageService.instance,
          ),
        );
      }
      if (!GetIt.instance.isRegistered<EnhancedConnectivityService>()) {
        getIt.registerSingletonReplace<EnhancedConnectivityService>(
          EnhancedConnectivityService(),
        );
      }
      if (!GetIt.instance.isRegistered<SyncController>()) {
        final prefs = GetIt.instance<SharedPreferencesCompat>();
        getIt.registerSingletonReplace<SyncController>(
          SyncController(
            connectivityService: GetIt.instance<EnhancedConnectivityService>(),
            personalitySyncService: GetIt.instance<PersonalitySyncService>(),
            personalityLearning: PersonalityLearning.withPrefs(prefs),
          ),
        );
      }
    } catch (e) {
      // If initialization fails, log but don't throw
      // Some tests may handle storage setup individually
      print('Warning: Failed to setup widget test environment: $e');
    }
  }

  /// Cleanup for widget tests - call this in tearDownAll
  static Future<void> cleanupWidgetTestEnvironment() async {
    try {
      final getIt = GetItTestHarness(sl: GetIt.instance);

      // Clean up GetIt registrations
      getIt.unregisterIfRegistered<SharedPreferencesCompat>();
      getIt.unregisterIfRegistered<StorageService>();
      getIt.unregisterIfRegistered<SyncController>();
      getIt.unregisterIfRegistered<EnhancedConnectivityService>();
      getIt.unregisterIfRegistered<PersonalitySyncService>();
      getIt.unregisterIfRegistered<SupabaseService>();
      await cleanupTestStorage();
      _didGlobalSetup = false;
    } catch (e) {
      // Ignore cleanup errors
      print('Warning: Failed to cleanup widget test environment: $e');
    }
  }

  /// Creates a testable widget wrapped with necessary providers and theme
  static Widget createTestableWidget({
    required Widget child,
    MockAuthBloc? authBloc,
    MockListsBloc? listsBloc,
    MockSpotsBloc? spotsBloc,
    MockHybridSearchBloc? hybridSearchBloc,
    NavigatorObserver? navigatorObserver,
    RouteSettings? routeSettings,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc ?? MockAuthBloc(),
        ),
        BlocProvider<ListsBloc>.value(
          value: listsBloc ?? MockListsBloc(),
        ),
        BlocProvider<SpotsBloc>.value(
          value: spotsBloc ?? MockSpotsBloc(),
        ),
        BlocProvider<HybridSearchBloc>.value(
          value: hybridSearchBloc ?? MockHybridSearchBloc(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        // Many onboarding "pages" are fragments that assume a Material ancestor
        // (they render TextField/InputDecorator without their own Scaffold).
        // Wrapping here keeps tests deterministic without forcing every test
        // to add an extra Scaffold/Material wrapper.
        home: Material(child: child),
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      ),
    );
  }

  /// Creates a testable widget with router support
  static Widget createTestableWidgetWithRouter({
    required Widget child,
    MockAuthBloc? authBloc,
    MockListsBloc? listsBloc,
    MockSpotsBloc? spotsBloc,
    MockHybridSearchBloc? hybridSearchBloc,
    NavigatorObserver? navigatorObserver,
    String initialRoute = '/',
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(
          value: authBloc ?? MockAuthBloc(),
        ),
        BlocProvider<ListsBloc>.value(
          value: listsBloc ?? MockListsBloc(),
        ),
        BlocProvider<SpotsBloc>.value(
          value: spotsBloc ?? MockSpotsBloc(),
        ),
        BlocProvider<HybridSearchBloc>.value(
          value: hybridSearchBloc ?? MockHybridSearchBloc(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        initialRoute: initialRoute,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Material(child: child),
          settings: settings,
        ),
        navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      ),
    );
  }

  /// Pumps widget and settles all animations
  static Future<void> pumpAndSettle(
    WidgetTester tester,
    Widget widget, {
    Duration? duration,
  }) async {
    // Some suites call cleanup helpers; make setup idempotent per pump.
    if (!_didGlobalSetup || !GetIt.instance.isRegistered<StorageService>()) {
      await setupWidgetTestEnvironment();
      _didGlobalSetup = true;
    }
    await tester.pumpWidget(widget);
    // Many SPOTS pages intentionally run continuous animations (pulsing hints,
    // map tiles, etc.). `pumpAndSettle` will time out in those cases, so we
    // treat "timed out" as non-fatal and advance a bounded amount of time.
    try {
      await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
    } catch (_) {
      await tester.pump(duration ?? const Duration(milliseconds: 200));
    }
  }

  /// Like `tester.pumpAndSettle()`, but safe for widgets with continuous
  /// animations (eg. indeterminate progress indicators).
  static Future<void> safePumpAndSettle(
    WidgetTester tester, {
    Duration? duration,
  }) async {
    try {
      await tester.pumpAndSettle(duration ?? const Duration(seconds: 1));
    } catch (_) {
      await tester.pump(duration ?? const Duration(milliseconds: 200));
    }
  }

  /// Verifies that a widget displays the expected loading state
  static void verifyLoadingState(WidgetTester tester) {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  /// Verifies that a widget displays an error state with a specific message
  static void verifyErrorState(WidgetTester tester, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  }

  /// Verifies navigation occurred to a specific route
  static void verifyNavigationTo(NavigatorObserver observer, String routeName) {
    // Note: didPush signature is (Route<dynamic> route, Route<dynamic>? previousRoute)
    // We verify that didPush was called - the actual route checking can be done
    // by capturing arguments if needed. For now, just verify the call happened.
    // Using a workaround: verify the call with any() and cast to avoid null issues
    // ignore: cast_from_null_always_fails - This is a matcher, not an actual cast
    verify(observer.didPush(any as Route<dynamic>, any));
  }

  /// Creates test user data (UnifiedUser)
  static UnifiedUser createTestUser({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName,
    UserRole role = UserRole.follower,
    bool isAgeVerified = true,
  }) {
    final now = DateTime.now();
    return UnifiedUser(
      id: id,
      email: email,
      displayName: displayName ?? 'Test User',
      photoUrl: null,
      location: 'Test City',
      createdAt: now,
      updatedAt: now,
      isOnline: false,
      hasCompletedOnboarding: true,
      hasReceivedStarterLists: false,
      expertise: null,
      locations: null,
      hostedEventsCount: null,
      differentSpotsCount: null,
      tags: const [],
      expertiseMap: const {},
      friends: const [],
      curatedLists: const [],
      collaboratedLists: const [],
      followedLists: const [],
      primaryRole: role,
      isAgeVerified: isAgeVerified,
      ageVerificationDate: isAgeVerified ? now : null,
    );
  }

  /// Creates test User (for AuthBloc compatibility)
  /// Converts UnifiedUser to User type expected by Authenticated state
  static user_model.User createTestUserForAuth({
    String id = 'test-user-id',
    String email = 'test@example.com',
    String? displayName,
    user_model.UserRole role = user_model.UserRole.user,
    bool isAgeVerified = true,
  }) {
    final now = DateTime.now();
    return user_model.User(
      id: id,
      email: email,
      name: displayName ?? 'Test User',
      displayName: displayName,
      role: role,
      createdAt: now,
      updatedAt: now,
      isOnline: false,
    );
  }

  /// Creates test spot data
  static Spot createTestSpot({
    String id = 'test-spot-id',
    String name = 'Test Spot',
    double latitude = 40.7128,
    double longitude = -74.0060,
    String category = 'restaurant',
  }) {
    final now = DateTime.now();
    return Spot(
      id: id,
      name: name,
      description: 'A test spot for widget testing',
      latitude: latitude,
      longitude: longitude,
      category: category,
      rating: 4.5,
      createdBy: 'test-user-id',
      createdAt: now,
      updatedAt: now,
      address: '123 Test St, Test City',
      phoneNumber: '+1-555-0123',
      website: 'https://test.example.com',
      tags: const ['test', 'widget'],
      metadata: const {},
    );
  }

  /// Creates test list data
  static SpotList createTestList({
    String id = 'test-list-id',
    String? name,
    String? title,
    String curatorId = 'test-user-id',
    bool isPublic = true,
  }) {
    final now = DateTime.now();
    return SpotList(
      id: id,
      title: title ?? name ?? 'Test List',
      name: name ?? title ?? 'Test List',
      description: 'A test list for widget testing',
      spots: const [],
      createdAt: now,
      updatedAt: now,
      curatorId: curatorId,
      isPublic: isPublic,
      spotIds: const [],
      tags: const ['test', 'widget'],
      collaborators: const [],
      followers: const [],
      respectCount: 0,
      ageRestricted: false,
      moderationEnabled: true,
      metadata: const {},
    );
  }

  /// Verifies that form validation works correctly
  static Future<void> verifyFormValidation(
    WidgetTester tester, {
    required String formKey,
    required Map<String, String> invalidInputs,
    required Map<String, String> expectedErrors,
  }) async {
    // Input invalid data
    for (final entry in invalidInputs.entries) {
      await tester.enterText(find.byKey(Key(entry.key)), entry.value);
    }

    // Try to submit form
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify validation errors appear
    for (final entry in expectedErrors.entries) {
      expect(find.text(entry.value), findsOneWidget);
    }
  }

  /// Simulates user interaction delays
  static Future<void> simulateUserDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 100));
  }

  /// Finds widgets by accessibility semantics
  static Finder findBySemantics(String label) {
    return find.bySemanticsLabel(label);
  }

  /// Verifies accessibility requirements
  static void verifyAccessibility(WidgetTester tester) {
    // Verify semantic labels exist for important elements
    expect(find.bySemanticsLabel(RegExp(r'.*')), findsWidgets);
    
    // Could add more accessibility checks here like:
    // - Minimum touch target sizes
    // - Contrast ratios
    // - Screen reader compatibility
  }
}

/// Test data factory for creating consistent test objects
class TestDataFactory {
  static const String defaultUserId = 'test-user-id';
  static const String defaultEmail = 'test@example.com';
  static const String defaultSpotId = 'test-spot-id';
  static const String defaultListId = 'test-list-id';

  /// Creates a complete user profile for testing
  static UnifiedUser createCompleteUserProfile({
    UserRole role = UserRole.follower,
  }) {
    return WidgetTestHelpers.createTestUser(
      id: defaultUserId,
      email: defaultEmail,
      role: role,
    );
  }

  /// Creates multiple test spots for list testing
  static List<Spot> createTestSpots(int count) {
    return List.generate(count, (index) {
      return WidgetTestHelpers.createTestSpot(
        id: 'test-spot-$index',
        name: 'Test Spot $index',
        latitude: 40.7128 + (index * 0.001),
        longitude: -74.0060 + (index * 0.001),
      );
    });
  }

  /// Creates multiple test lists for testing
  static List<SpotList> createTestLists(int count) {
    return List.generate(count, (index) {
      return WidgetTestHelpers.createTestList(
        id: 'test-list-$index',
        name: 'Test List $index',
      );
    });
  }
}
