// Unit tests for CrossAppConsentService
//
// Tests the cross-app tracking consent management system:
// - Default consent values (opt-out model - all enabled)
// - Enabling/disabling individual data sources
// - Persistence via SharedPreferences
// - Onboarding completion tracking
// - Consent summary generation
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_core/models/misc/cross_app_learning_insight.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_app_consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrossAppConsentService', () {
    late CrossAppConsentService service;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      service = CrossAppConsentService();
      await service.initialize();
    });

    group('Default Consent Values (Opt-Out Model)', () {
      test('all data sources should be enabled by default', () async {
        // Per opt-out model, all sources default to enabled
        expect(await service.isEnabled(CrossAppDataSource.calendar), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.health), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.media), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.appUsage), isTrue);
      });

      test('getAllConsents should return all sources enabled by default',
          () async {
        final consents = await service.getAllConsents();

        expect(consents[CrossAppDataSource.calendar], isTrue);
        expect(consents[CrossAppDataSource.health], isTrue);
        expect(consents[CrossAppDataSource.media], isTrue);
        expect(consents[CrossAppDataSource.appUsage], isTrue);
      });
    });

    group('Enabling/Disabling Individual Sources', () {
      test('setEnabled should disable a specific source', () async {
        // Disable calendar
        await service.setEnabled(CrossAppDataSource.calendar, false);

        expect(await service.isEnabled(CrossAppDataSource.calendar), isFalse);
        // Others remain enabled
        expect(await service.isEnabled(CrossAppDataSource.health), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.media), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.appUsage), isTrue);
      });

      test('setEnabled should re-enable a disabled source', () async {
        // Disable then re-enable
        await service.setEnabled(CrossAppDataSource.health, false);
        expect(await service.isEnabled(CrossAppDataSource.health), isFalse);

        await service.setEnabled(CrossAppDataSource.health, true);
        expect(await service.isEnabled(CrossAppDataSource.health), isTrue);
      });

      test('setAllConsents should update all sources at once', () async {
        final newConsents = {
          CrossAppDataSource.calendar: false,
          CrossAppDataSource.health: true,
          CrossAppDataSource.media: false,
          CrossAppDataSource.appUsage: true,
        };

        await service.setAllConsents(newConsents);

        expect(await service.isEnabled(CrossAppDataSource.calendar), isFalse);
        expect(await service.isEnabled(CrossAppDataSource.health), isTrue);
        expect(await service.isEnabled(CrossAppDataSource.media), isFalse);
        expect(await service.isEnabled(CrossAppDataSource.appUsage), isTrue);
      });

      test('enableAll should enable all data sources', () async {
        // First disable some
        await service.setEnabled(CrossAppDataSource.calendar, false);
        await service.setEnabled(CrossAppDataSource.media, false);

        // Enable all
        await service.enableAll();

        final consents = await service.getAllConsents();
        expect(consents.values.every((v) => v), isTrue);
      });

      test('disableAll should disable all data sources', () async {
        await service.disableAll();

        final consents = await service.getAllConsents();
        expect(consents.values.every((v) => !v), isTrue);
      });
    });

    group('Persistence', () {
      test('consent changes should persist across service instances', () async {
        // Modify consents
        await service.setEnabled(CrossAppDataSource.calendar, false);
        await service.setEnabled(CrossAppDataSource.health, false);

        // Create new service instance (simulates app restart)
        final newService = CrossAppConsentService();
        await newService.initialize();

        // Verify persistence
        expect(
            await newService.isEnabled(CrossAppDataSource.calendar), isFalse);
        expect(await newService.isEnabled(CrossAppDataSource.health), isFalse);
        expect(await newService.isEnabled(CrossAppDataSource.media), isTrue);
        expect(await newService.isEnabled(CrossAppDataSource.appUsage), isTrue);
      });
    });

    group('Onboarding Completion', () {
      test('onboarding should not be completed initially', () async {
        expect(await service.isOnboardingCompleted(), isFalse);
      });

      test('completeOnboarding should mark onboarding as completed', () async {
        await service.completeOnboarding();
        expect(await service.isOnboardingCompleted(), isTrue);
      });

      test('onboarding completion should persist', () async {
        await service.completeOnboarding();

        // New service instance
        final newService = CrossAppConsentService();
        await newService.initialize();

        expect(await newService.isOnboardingCompleted(), isTrue);
      });
    });

    group('Consent Summary', () {
      test('getConsentSummary should return correct counts', () async {
        // Default: all 4 enabled
        var summary = await service.getConsentSummary();
        expect(summary.enabledCount, equals(4));
        expect(summary.totalCount, equals(4));
        expect(summary.allEnabled, isTrue);
        expect(summary.allDisabled, isFalse);

        // Disable 2 sources
        await service.setEnabled(CrossAppDataSource.calendar, false);
        await service.setEnabled(CrossAppDataSource.health, false);

        summary = await service.getConsentSummary();
        expect(summary.enabledCount, equals(2));
        expect(summary.allEnabled, isFalse);
        expect(summary.allDisabled, isFalse);

        // Disable all
        await service.disableAll();

        summary = await service.getConsentSummary();
        expect(summary.enabledCount, equals(0));
        expect(summary.allEnabled, isFalse);
        expect(summary.allDisabled, isTrue);
      });
    });

    group('Edge Cases', () {
      test('service should handle multiple initialize calls gracefully',
          () async {
        await service.initialize();
        await service.initialize();
        await service.initialize();

        // Should still work correctly
        expect(await service.isEnabled(CrossAppDataSource.calendar), isTrue);
      });

      test('service should handle operations before explicit initialize',
          () async {
        final uninitializedService = CrossAppConsentService();

        // Should auto-initialize on first operation
        final result =
            await uninitializedService.isEnabled(CrossAppDataSource.calendar);
        expect(result, isTrue);
      });
    });
  });
}
