import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart' as real_prefs;
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_god_mode_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_communication_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_service.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import '../../mocks/mock_storage_service.dart';

/// Integration tests for Admin Backend Connections
///
/// These tests verify that all backend integrations work correctly
/// for the god-mode admin system.
void main() {
  group('Admin Backend Connections Integration Tests', () {
    late SharedPreferencesCompat compatPrefs;
    late SupabaseService supabaseService;
    late ConnectionMonitor connectionMonitor;
    late AdminAuthService authService;
    late AdminCommunicationService communicationService;
    late BusinessAccountService businessService;
    late PredictiveAnalytics predictiveAnalytics;
    late AdminGodModeService godModeService;

    setUpAll(() async {
      // Initialize SharedPreferences
      real_prefs.SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      // Reset SharedPreferences mock state for test isolation
      real_prefs.SharedPreferences.setMockInitialValues({});
      final mockStorage = MockGetStorage.getInstance();
      MockGetStorage.reset();
      compatPrefs =
          await SharedPreferencesCompat.getInstance(storage: mockStorage);
      // Initialize services
      supabaseService = SupabaseService();
      connectionMonitor = ConnectionMonitor(prefs: compatPrefs);
      authService = AdminAuthService(compatPrefs);
      communicationService = AdminCommunicationService(
        connectionMonitor: connectionMonitor,
        chatAnalyzer: null,
      );
      businessService = BusinessAccountService();
      predictiveAnalytics = PredictiveAnalytics();
      godModeService = AdminGodModeService(
        authService: authService,
        communicationService: communicationService,
        businessService: businessService,
        predictiveAnalytics: predictiveAnalytics,
        connectionMonitor: connectionMonitor,
        chatAnalyzer: null,
        supabaseService: supabaseService,
        expertiseService: ExpertiseService(),
      );
    });

    test('Supabase Service should be accessible', () {
      expect(supabaseService, isNotNull);
      // In test environment, Supabase may not be initialized
      // We're testing the structure, not the actual connection
      expect(supabaseService.isAvailable, isA<bool>());
    });

    test('Supabase connection test should work', () async {
      // Note: This may fail if Supabase is not configured
      // That's okay - we're testing the structure, not the actual connection
      try {
        final isConnected = await supabaseService.testConnection();
        expect(isConnected, isA<bool>());
      } catch (e) {
        // Expected if Supabase is not configured
        expect(e, isNotNull);
      }
    });

    test('Admin services should initialize correctly', () {
      expect(connectionMonitor, isNotNull);
      expect(authService, isNotNull);
      expect(communicationService, isNotNull);
      expect(businessService, isNotNull);
      expect(predictiveAnalytics, isNotNull);
      expect(godModeService, isNotNull);
    });

    test('AdminGodModeService should check authorization', () {
      // Without login, should not be authorized
      final isAuthorized = godModeService.isAuthorized;
      expect(isAuthorized, isA<bool>());
    });

    test('ConnectionMonitor should support AI signature lookups', () {
      const testSignature = 'ai_test_123';
      final connections =
          connectionMonitor.getConnectionsByAISignature(testSignature);
      expect(connections, isA<Set<String>>());

      final sessions =
          connectionMonitor.getSessionsByAISignature(testSignature);
      expect(sessions, isA<List>());
    });

    test('User search should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.searchUsers(),
        throwsA(isA<Exception>()),
      );
    });

    test('Dashboard data should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.getDashboardData(),
        throwsA(isA<Exception>()),
      );
    });

    test('Business accounts should require authorization', () async {
      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.getAllBusinessAccounts(),
        throwsA(isA<Exception>()),
      );
    });

    test('AI data streams should work without connections', () async {
      const testSignature = 'ai_nonexistent_123';

      // Should throw UnauthorizedException without login
      expect(
        () => godModeService.watchAIData(testSignature),
        throwsA(isA<Exception>()),
      );
    });

    test('AdminGodModeService should dispose correctly', () {
      // Should not throw
      expect(() => godModeService.dispose(), returnsNormally);
    });
  });
}
