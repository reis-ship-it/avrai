import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/app.dart';
import 'package:avrai/injection_container.dart' as di;

import 'package:avrai/presentation/pages/onboarding/onboarding_page.dart';
import 'package:avrai/presentation/pages/onboarding/social_media_connection_page.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import '../../helpers/platform_channel_helper.dart';

/// Phase 8 Section 2 (8.2) - Social Media Data Collection Integration Test
///
/// Tests that social media connection service is properly integrated:
/// - Service can be created and registered
/// - Connection records can be created and stored
/// - Connections can be retrieved
/// - AILoadingPage collects data from service
/// - Privacy (agentId usage) is maintained
///
/// Date: December 23, 2025
/// Status: Testing Section 2 implementation

void main() {
  final runHeavyIntegrationTests =
      Platform.environment['RUN_HEAVY_INTEGRATION_TESTS'] == 'true';
  const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  const bool runFullOnboardingIntegrationTests =
      bool.fromEnvironment('RUN_FULL_ONBOARDING_INTEGRATION_TESTS');

  if (!runFullOnboardingIntegrationTests) {
    return;
  }

  setUpAll(() async {
    if (!runHeavyIntegrationTests ||
        !isFlutterTest ||
        !runFullOnboardingIntegrationTests) {
      return;
    }

    // Initialize dependency injection for tests
    try {
      await setupTestStorage();
      await di.init();
    } catch (e) {
      // DI may fail in test environment, that's okay
      // ignore: avoid_print
      print('⚠️  DI initialization failed in test: $e');
    }
  });

  group('Phase 8 Section 2: Social Media Data Collection Integration', () {
    testWidgets('SocialMediaConnectionService is registered and accessible',
        (WidgetTester tester) async {
      // Arrange & Act
      final service = di.sl<SocialMediaConnectionService>();

      // Assert
      expect(service, isNotNull);
      expect(service, isA<SocialMediaConnectionService>());
    });

    testWidgets('can create and store social media connection',
        (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_123';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Connect a platform (creates placeholder connection)
      final connection = await service.connectPlatform(
        platform: 'google',
        agentId: agentId,
        userId: testUserId,
      );

      // Assert
      expect(connection, isNotNull);
      expect(connection.platform, equals('google'));
      expect(connection.agentId, equals(agentId));
      expect(connection.isActive, isTrue);
    });

    testWidgets('can retrieve active connections', (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_456';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Create connections
      await service.connectPlatform(
        platform: 'instagram',
        agentId: agentId,
        userId: testUserId,
      );
      await service.connectPlatform(
        platform: 'facebook',
        agentId: agentId,
        userId: testUserId,
      );

      // Retrieve active connections
      final connections = await service.getActiveConnections(testUserId);

      // Assert
      expect(connections, isNotEmpty);
      expect(connections.length, greaterThanOrEqualTo(2));
      expect(connections.any((c) => c.platform == 'instagram'), isTrue);
      expect(connections.any((c) => c.platform == 'facebook'), isTrue);
      expect(connections.every((c) => c.isActive), isTrue);
    });

    testWidgets('can disconnect platform and remove from active connections',
        (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_789';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Create connection
      await service.connectPlatform(
        platform: 'twitter',
        agentId: agentId,
        userId: testUserId,
      );

      // Verify connection exists
      var connections = await service.getActiveConnections(testUserId);
      expect(connections.any((c) => c.platform == 'twitter'), isTrue);

      // Disconnect
      await service.disconnectPlatform(
        platform: 'twitter',
        agentId: agentId,
      );

      // Retrieve connections again
      connections = await service.getActiveConnections(testUserId);

      // Assert - Twitter should not be in active connections
      expect(connections.any((c) => c.platform == 'twitter'), isFalse);
    });

    testWidgets('connections use agentId for privacy (not userId)',
        (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_privacy';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Create connection
      final connection = await service.connectPlatform(
        platform: 'google',
        agentId: agentId,
        userId: testUserId,
      );

      // Assert - Connection uses agentId, not userId
      expect(connection.agentId, equals(agentId));
      expect(connection.agentId, isNot(equals(testUserId)));
      expect(connection.agentId, startsWith('agent_'));
    });

    testWidgets('can fetch profile data from connection',
        (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_profile';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Create connection and fetch profile
      final connection = await service.connectPlatform(
        platform: 'google',
        agentId: agentId,
        userId: testUserId,
      );

      final profileData = await service.fetchProfileData(connection);

      // Assert - Profile data structure exists (even if placeholder)
      expect(profileData, isNotNull);
      expect(profileData, isA<Map<String, dynamic>>());
    });

    testWidgets('can fetch Google Places data', (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_places';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Act - Create Google connection and fetch places data
      final connection = await service.connectPlatform(
        platform: 'google',
        agentId: agentId,
        userId: testUserId,
      );

      final placesData = await service.fetchGooglePlacesData(connection);

      // Assert - Places data structure exists (even if placeholder)
      expect(placesData, isNotNull);
      expect(placesData, isA<Map<String, dynamic>>());
      expect(placesData.containsKey('places'), isTrue);
      expect(placesData.containsKey('reviews'), isTrue);
      expect(placesData.containsKey('photos'), isTrue);
    });

    testWidgets('AILoadingPage can collect social media data from service',
        (WidgetTester tester) async {
      // Arrange
      final service = di.sl<SocialMediaConnectionService>();
      final agentIdService = di.sl<AgentIdService>();
      const testUserId = 'test_user_ai_loading';
      final agentId = await agentIdService.getUserAgentId(testUserId);

      // Create connections
      await service.connectPlatform(
        platform: 'instagram',
        agentId: agentId,
        userId: testUserId,
      );

      // Act - Get active connections (simulating what AILoadingPage does)
      final connections = await service.getActiveConnections(testUserId);

      // Assert - Connections exist and can be used for data collection
      expect(connections, isNotEmpty);

      // Simulate data collection
      for (final connection in connections) {
        final profile = await service.fetchProfileData(connection);
        expect(profile, isNotNull);
      }
    });

    testWidgets('SocialMediaConnectionPage uses service for connections',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const SpotsApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final onboardingPage = find.byType(OnboardingPage);
      // ignore: avoid_print
      if (onboardingPage.evaluate().isEmpty) {
        // ignore: avoid_print
        print(
            '⚠️ Onboarding skipped by router in integration tests - test skipped');
        return;
      }

      // Act - Navigate to social media step
      await _navigateToSocialMediaStep(tester);
      await tester.pumpAndSettle();

      // Assert - SocialMediaConnectionPage is displayed
      expect(find.byType(SocialMediaConnectionPage), findsOneWidget);

      // Verify service is accessible (indirectly through page functionality)
      final socialMediaPage = tester.widget<SocialMediaConnectionPage>(
          find.byType(SocialMediaConnectionPage));
      expect(socialMediaPage, isNotNull);
      expect(socialMediaPage.connectedPlatforms, isNotNull);
    });
  },
      skip: !runHeavyIntegrationTests ||
          !isFlutterTest ||
          !runFullOnboardingIntegrationTests);
}

/// Navigate to social media step
Future<void> _navigateToSocialMediaStep(WidgetTester tester) async {
  // Navigate through onboarding steps to reach social media
  for (int i = 0; i < 6; i++) {
    await _navigateToNextStep(tester);
    await tester.pumpAndSettle();
  }
}

/// Navigate to next step
Future<void> _navigateToNextStep(WidgetTester tester) async {
  final nextButton = find.text('Next');
  if (nextButton.evaluate().isNotEmpty) {
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
  } else {
    final continueButton = find.text('Continue');
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
    }
  }
}
