import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/user/preferences_profile.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/user_preferences.dart';
import 'package:avrai/core/models/user/unified_user.dart';

/// PreferencesProfile Model Unit Tests
///
/// Tests for PreferencesProfile model:
/// - Model creation from onboarding data
/// - Category preferences mapping
/// - Locality preferences mapping
/// - Quantum state conversion
/// - Quantum compatibility calculation
/// - JSON serialization/deserialization
///
/// Date: December 23, 2025
/// Status: Phase 8.8 - PreferencesProfile Initialization

void main() {
  group('PreferencesProfile Model', () {
    test('should create PreferencesProfile from onboarding data', () {
      // Arrange
      final onboardingData = OnboardingData(
        agentId: 'agent_test_123',
        age: 28,
        homebase: 'San Francisco, CA',
        favoritePlaces: ['Golden Gate Park', 'Mission District'],
        preferences: {
          'Food & Drink': ['Coffee', 'Craft Beer'],
          'Activities': ['Hiking', 'Live Music'],
        },
        baselineLists: ['My Coffee Spots'],
        completedAt: DateTime.now(),
      );

      // Act
      final profile = PreferencesProfile.fromOnboarding(
        agentId: 'agent_test_123',
        onboardingData: onboardingData,
      );

      // Assert
      expect(profile.agentId, equals('agent_test_123'));
      expect(profile.categoryPreferences, isNotEmpty);
      expect(profile.localityPreferences, isNotEmpty);
      expect(profile.localityPreferences['San Francisco, CA'], equals(0.8));
      expect(profile.source, equals('onboarding'));
    });

    test('should map category preferences from onboarding data', () {
      // Arrange
      final onboardingData = OnboardingData(
        agentId: 'agent_test_123',
        preferences: {
          'Food & Drink': ['Coffee', 'Craft Beer'],
          'Activities': ['Hiking'],
        },
        completedAt: DateTime.now(),
      );

      // Act
      final profile = PreferencesProfile.fromOnboarding(
        agentId: 'agent_test_123',
        onboardingData: onboardingData,
      );

      // Assert
      expect(profile.categoryPreferences['Food & Drink'], greaterThan(0.7));
      expect(profile.categoryPreferences['Coffee'], equals(0.8));
      expect(profile.categoryPreferences['Craft Beer'], equals(0.8));
      expect(profile.categoryPreferences['Activities'], greaterThan(0.7));
      expect(profile.categoryPreferences['Hiking'], equals(0.8));
    });

    test('should map locality preferences from homebase', () {
      // Arrange
      final onboardingData = OnboardingData(
        agentId: 'agent_test_123',
        homebase: 'Brooklyn, NY',
        completedAt: DateTime.now(),
      );

      // Act
      final profile = PreferencesProfile.fromOnboarding(
        agentId: 'agent_test_123',
        onboardingData: onboardingData,
      );

      // Assert
      expect(profile.localityPreferences['Brooklyn, NY'], equals(0.8));
    });

    test('should convert preferences to quantum state', () {
      // Arrange
      final profile = PreferencesProfile(
        agentId: 'agent_test_123',
        categoryPreferences: const {'Coffee': 0.9, 'Food': 0.7},
        localityPreferences: const {'Brooklyn': 0.8},
        lastUpdated: DateTime.now(),
      );

      // Act
      final quantumState = profile.toQuantumState();

      // Assert
      expect(quantumState, isA<Map<String, dynamic>>());
      expect(quantumState['category'], isA<Map<String, double>>());
      expect(quantumState['locality'], isA<Map<String, double>>());
      expect(quantumState['category']['Coffee'], equals(0.9));
      expect(quantumState['locality']['Brooklyn'], equals(0.8));
      expect(quantumState['local_expert'], equals(0.5));
      expect(quantumState['exploration'], equals(0.3));
    });

    test('should calculate quantum compatibility with event', () {
      // Arrange
      final profile = PreferencesProfile(
        agentId: 'agent_test_123',
        categoryPreferences: const {'Coffee': 0.9},
        localityPreferences: const {'Brooklyn': 0.8},
        eventTypePreferences: const {ExpertiseEventType.workshop: 0.7},
        scopePreferences: const {EventScope.locality: 0.8},
        lastUpdated: DateTime.now(),
      );

      final now = DateTime.now();
      final event = ExpertiseEvent(
        id: 'event_1',
        title: 'Coffee Workshop',
        description: 'Learn about coffee',
        category: 'Coffee',
        eventType: ExpertiseEventType.workshop,
        host: UnifiedUser(
          id: 'user_1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: now,
          updatedAt: now,
        ),
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 2)),
        location: 'Brooklyn',
        createdAt: now,
        updatedAt: now,
      );

      // Act
      final compatibility = profile.calculateQuantumCompatibility(event);

      // Assert
      expect(compatibility, greaterThan(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });

    test('should serialize and deserialize correctly (round-trip)', () {
      // Arrange
      final original = PreferencesProfile(
        agentId: 'agent_test_123',
        categoryPreferences: const {'Coffee': 0.9, 'Food': 0.7},
        localityPreferences: const {'Brooklyn': 0.8},
        scopePreferences: const {EventScope.locality: 0.7, EventScope.city: 0.5},
        eventTypePreferences: const {ExpertiseEventType.workshop: 0.8},
        localExpertPreferenceWeight: 0.6,
        explorationWillingness: 0.4,
        lastUpdated: DateTime(2025, 12, 23),
        eventsAnalyzed: 10,
        spotsAnalyzed: 5,
        listsAnalyzed: 3,
        source: 'onboarding',
      );

      // Act
      final json = original.toJson();
      final restored = PreferencesProfile.fromJson(json);

      // Assert - Test business logic: round-trip preserves all data
      expect(restored, equals(original));
      // Verify JSON structure is correct for storage/transmission
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('agentId'), isTrue);
      expect(json.containsKey('categoryPreferences'), isTrue);
      expect(json.containsKey('localityPreferences'), isTrue);
    });

    test('should get top categories', () {
      // Arrange
      final profile = PreferencesProfile(
        agentId: 'agent_test_123',
        categoryPreferences: const {
          'Coffee': 0.9,
          'Food': 0.7,
          'Art': 0.5,
          'Music': 0.8,
          'Hiking': 0.6,
        },
        lastUpdated: DateTime.now(),
      );

      // Act
      final topCategories = profile.getTopCategories(n: 3);

      // Assert
      expect(topCategories.length, equals(3));
      expect(topCategories[0].key, equals('Coffee'));
      expect(topCategories[0].value, equals(0.9));
      expect(topCategories[1].key, equals('Music'));
      expect(topCategories[1].value, equals(0.8));
    });

    test('should check if user prefers local experts', () {
      // Arrange
      final profileLocal = PreferencesProfile(
        agentId: 'agent_test_123',
        localExpertPreferenceWeight: 0.7,
        lastUpdated: DateTime.now(),
      );

      final profileCity = PreferencesProfile(
        agentId: 'agent_test_124',
        localExpertPreferenceWeight: 0.4,
        lastUpdated: DateTime.now(),
      );

      // Act & Assert
      expect(profileLocal.prefersLocalExperts, isTrue);
      expect(profileCity.prefersLocalExperts, isFalse);
    });

    test('should check if user is open to exploration', () {
      // Arrange
      final profileExplorer = PreferencesProfile(
        agentId: 'agent_test_123',
        explorationWillingness: 0.7,
        lastUpdated: DateTime.now(),
      );

      final profileFamiliar = PreferencesProfile(
        agentId: 'agent_test_124',
        explorationWillingness: 0.3,
        lastUpdated: DateTime.now(),
      );

      // Act & Assert
      expect(profileExplorer.isOpenToExploration, isTrue);
      expect(profileFamiliar.isOpenToExploration, isFalse);
    });

    test('should create empty PreferencesProfile with correct defaults and behavior', () {
      // Act
      final profile = PreferencesProfile.empty(agentId: 'agent_test_123');

      // Assert - Test business logic: empty profile has correct defaults and behavior
      expect(profile.agentId, equals('agent_test_123'));
      expect(profile.categoryPreferences, isEmpty);
      expect(profile.localityPreferences, isEmpty);
      expect(profile.source, equals('empty'));
      // Test behavior: empty profile methods work correctly
      expect(profile.getTopCategories(n: 5), isEmpty);
      expect(profile.prefersLocalExperts, isFalse); // Default weight is 0.5, threshold is 0.5
      expect(profile.isOpenToExploration, isFalse); // Default willingness is 0.3, threshold is 0.5
    });
  });
}

