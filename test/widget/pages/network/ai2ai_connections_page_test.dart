/// Tests for AI2AI Connections Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI - Integration Tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/core/models/quantum/connection_metrics.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;
import 'package:avrai/presentation/pages/network/ai2ai_connections_page.dart';
import '../../../helpers/platform_channel_helper.dart';

void main() {
  setUpAll(() {});

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('AI2AIConnectionsPage Integration', () {
    // Removed: Property assignment tests
    // AI2AI connections page tests focus on business logic (page rendering, tab navigation, discovery toggle, settings navigation, network statistics, info dialog), not property assignment

    testWidgets(
        'should render page with all tabs, show discovery tab status and actions, navigate between tabs, toggle discovery, navigate to settings, show network statistics correctly, or open info dialog',
        (tester) async {
      // Test business logic: AI2AI connections page display and interactions
      await _setupMockServices();
      await tester.pumpWidget(
        const MaterialApp(
          home: AI2AIConnectionsPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI2AI Network'), findsOneWidget);
      expect(find.text('Discovery'), findsOneWidget);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('AI Connections'), findsOneWidget);
      expect(find.text('Discovery Inactive'), findsOneWidget);
      expect(find.text('Start Discovery'), findsOneWidget);
      expect(find.text('Network Statistics'), findsOneWidget);

      await tester.tap(find.text('Devices'));
      await tester.pumpAndSettle();
      expect(find.text('Discovery is off'), findsOneWidget);
      await tester.tap(find.text('AI Connections'));
      await tester.pumpAndSettle();
      expect(find.text('No Active AI Connections'), findsOneWidget);

      // Toggle discovery from the Discovery tab (button is not visible on other tabs).
      await tester.tap(find.text('Discovery'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start Discovery'));
      await tester.pumpAndSettle();
      expect(find.text('Discovery Active'), findsOneWidget);
      expect(find.text('Stop Discovery'), findsOneWidget);

      await tester.tap(find.byTooltip('Discovery Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Discovery Settings'), findsWidgets);
      // Navigate back to the discovery tab for the info dialog link.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('How Discovery Works'));
      await tester.tap(find.text('How Discovery Works'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('AI2AI Discovery'), findsOneWidget);
      expect(find.textContaining('Your AI broadcasts'), findsOneWidget);
    });
  });
}

/// Helper to setup mock services
Future<void> _setupMockServices() async {
  await setupTestStorage();
  final mockDiscovery = MockDeviceDiscoveryService();
  final prefs = await SharedPreferencesCompat.getInstance(storage: getTestStorage());
  final mockOrchestrator = MockVibeConnectionOrchestrator(prefs: prefs);

  GetIt.instance.registerSingleton<DeviceDiscoveryService>(mockDiscovery);
  GetIt.instance
      .registerSingleton<VibeConnectionOrchestrator>(mockOrchestrator);
}

/// Mock DeviceDiscoveryService
class MockDeviceDiscoveryService extends DeviceDiscoveryService {
  List<DiscoveredDevice> _devices = [];

  MockDeviceDiscoveryService() : super(platform: null);

  void setDevices(List<DiscoveredDevice> devices) {
    _devices = devices;
  }

  @override
  Future<void> startDiscovery({
    Duration scanInterval = const Duration(seconds: 5),
    Duration scanWindow = const Duration(seconds: 4),
    Duration deviceTimeout = const Duration(minutes: 2),
  }) async {
  }

  @override
  void stopDiscovery() {
  }

  @override
  List<DiscoveredDevice> getDiscoveredDevices() {
    return _devices;
  }

  @override
  DiscoveredDevice? getDevice(String deviceId) {
    return _devices.where((d) => d.deviceId == deviceId).firstOrNull;
  }
}

/// Mock VibeConnectionOrchestrator
class MockVibeConnectionOrchestrator extends VibeConnectionOrchestrator {
  List<ConnectionMetrics> _connections = [];

  MockVibeConnectionOrchestrator({required super.prefs})
      : super(
          vibeAnalyzer: UserVibeAnalyzer(prefs: prefs),
          connectivity: Connectivity(),
        );

  void setConnections(List<ConnectionMetrics> connections) {
    _connections = connections;
  }

  @override
  List<ConnectionMetrics> getActiveConnections() {
    return _connections;
  }

  // NOTE: This is a lightweight harness used only to provide stable UI data.
}
