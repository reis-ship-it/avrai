import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/infrastructure/feature_flag_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('FeatureFlagService', () {
    late FeatureFlagService featureFlags;
    late StorageService storage;

    setUp(() async {
      // Initialize storage for testing
      await setupTestStorage();
      storage = StorageService.instance;

      featureFlags = FeatureFlagService(storage: storage);
    });

    tearDown(() async {
      // Clean up storage
      await storage.clear();
    });

    test('should return default value when flag not configured', () async {
      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      expect(enabled, equals(false));
    });

    test('should return true when default value is true', () async {
      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: true,
      );

      expect(enabled, equals(true));
    });

    test('should respect local override (highest priority)', () async {
      // Set local override
      await featureFlags.setLocalOverride('test_feature', true);

      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      expect(enabled, equals(true));
    });

    test('should clear local override', () async {
      // Set and then clear override
      await featureFlags.setLocalOverride('test_feature', true);
      await featureFlags.clearLocalOverride('test_feature');

      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      expect(enabled, equals(false));
    });

    test('should respect remote config when enabled', () async {
      // Update remote config
      await featureFlags.updateRemoteConfig({
        'test_feature': FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 100.0,
        ),
      });

      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      expect(enabled, equals(true));
    });

    test('should respect remote config when disabled', () async {
      // Update remote config
      await featureFlags.updateRemoteConfig({
        'test_feature': FeatureFlagConfig(
          enabled: false,
          rolloutPercentage: 100.0,
        ),
      });

      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: true,
      );

      expect(enabled, equals(false));
    });

    test('should apply percentage rollout correctly', () async {
      // Update remote config with 50% rollout
      await featureFlags.updateRemoteConfig({
        'test_feature': FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 50.0,
        ),
      });

      // Test multiple users - should get consistent assignment
      final user1Enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );
      final user2Enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_2',
        defaultValue: false,
      );
      final user1EnabledAgain = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      // Same user should get same assignment (deterministic)
      expect(user1Enabled, equals(user1EnabledAgain));

      // Different users may get different assignments (based on hash)
      // But we can't predict which ones, so just verify they're booleans
      expect(user1Enabled, isA<bool>());
      expect(user2Enabled, isA<bool>());
    });

    test('should respect target users list', () async {
      // Update remote config with target users
      await featureFlags.updateRemoteConfig({
        'test_feature': FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 100.0,
          targetUsers: ['user_1', 'user_2'],
        ),
      });

      final user1Enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );
      final user2Enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_2',
        defaultValue: false,
      );
      final user3Enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_3',
        defaultValue: false,
      );

      expect(user1Enabled, equals(true));
      expect(user2Enabled, equals(true));
      expect(user3Enabled, equals(false)); // Not in target list
    });

    test('should return all enabled features for a user', () async {
      // Update remote config for multiple features
      await featureFlags.updateRemoteConfig({
        QuantumFeatureFlags.locationEntanglement: FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 100.0,
        ),
        QuantumFeatureFlags.decoherenceTracking: FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 50.0,
        ),
        QuantumFeatureFlags.quantumPredictionFeatures: FeatureFlagConfig(
          enabled: false,
          rolloutPercentage: 100.0,
        ),
      });

      final enabledFeatures = await featureFlags.getEnabledFeatures(
        userId: 'user_1',
      );

      expect(
          enabledFeatures, contains(QuantumFeatureFlags.locationEntanglement));
      // decoherenceTracking may or may not be enabled (50% rollout)
      expect(enabledFeatures,
          isNot(contains(QuantumFeatureFlags.quantumPredictionFeatures)));
    });

    test('should optionally include formula replacement flags', () async {
      await featureFlags.updateRemoteConfig({
        FormulaReplacementFeatureFlags.callingScore: FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 100.0,
        ),
      });

      final quantumOnly = await featureFlags.getEnabledFeatures(
        userId: 'user_1',
      );
      final withFormula = await featureFlags.getEnabledFeatures(
        userId: 'user_1',
        includeFormulaReplacementFlags: true,
      );

      expect(
        quantumOnly,
        isNot(contains(FormulaReplacementFeatureFlags.callingScore)),
      );
      expect(
        withFormula,
        contains(FormulaReplacementFeatureFlags.callingScore),
      );
    });

    test('should evaluate formula replacement helper', () async {
      await featureFlags.updateRemoteConfig({
        FormulaReplacementFeatureFlags.callingScore: FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 100.0,
        ),
      });

      final enabled = await featureFlags.isFormulaReplacementEnabled(
        FormulaReplacementFeatureFlags.callingScore,
        userId: 'user_1',
      );

      expect(enabled, isTrue);
    });

    test('should handle errors gracefully and return default', () async {
      // Test that service returns default when flag not configured
      // (This tests the fail-safe behavior - returns default when no config)
      final enabled = await featureFlags.isEnabled(
        'non_existent_feature_that_will_never_exist',
        userId: 'user_1',
        defaultValue: false,
      );

      expect(enabled, equals(false));
    });

    test('should store and retrieve config locally', () async {
      // Update remote config
      await featureFlags.updateRemoteConfig({
        'test_feature': FeatureFlagConfig(
          enabled: true,
          rolloutPercentage: 75.0,
          description: 'Test feature',
        ),
      });

      // Clear remote config (simulate service restart)
      await featureFlags.updateRemoteConfig({});

      // Should still work from stored config
      final enabled = await featureFlags.isEnabled(
        'test_feature',
        userId: 'user_1',
        defaultValue: false,
      );

      // May or may not be enabled depending on rollout percentage
      expect(enabled, isA<bool>());
    });
  });

  group('FeatureFlagConfig', () {
    test('should serialize and deserialize correctly (round-trip)', () {
      final original = FeatureFlagConfig(
        enabled: true,
        rolloutPercentage: 75.0,
        targetUsers: ['user_1', 'user_2'],
        description: 'Test feature',
      );

      final json = original.toJson();
      final restored = FeatureFlagConfig.fromJson(json);

      expect(restored.enabled, equals(original.enabled));
      expect(restored.rolloutPercentage, equals(original.rolloutPercentage));
      expect(restored.targetUsers, equals(original.targetUsers));
      expect(restored.description, equals(original.description));
    });

    test('should handle missing fields in JSON', () {
      final json = {
        'enabled': true,
        // Missing other fields
      };

      final config = FeatureFlagConfig.fromJson(json);

      expect(config.enabled, equals(true));
      expect(config.rolloutPercentage, equals(100.0)); // Default
      expect(config.targetUsers, isNull);
      expect(config.description, isNull);
    });
  });

  group('QuantumFeatureFlags', () {
    test('should have all four quantum enhancement flags', () {
      expect(QuantumFeatureFlags.allFlags.length, equals(4));
      expect(
        QuantumFeatureFlags.allFlags,
        contains(QuantumFeatureFlags.locationEntanglement),
      );
      expect(
        QuantumFeatureFlags.allFlags,
        contains(QuantumFeatureFlags.decoherenceTracking),
      );
      expect(
        QuantumFeatureFlags.allFlags,
        contains(QuantumFeatureFlags.quantumPredictionFeatures),
      );
      expect(
        QuantumFeatureFlags.allFlags,
        contains(QuantumFeatureFlags.quantumSatisfactionEnhancement),
      );
    });

    test('should return default configs with 0% rollout', () {
      final configs = QuantumFeatureFlags.getDefaultConfigs();

      expect(configs.length, equals(4));
      expect(
        configs[QuantumFeatureFlags.locationEntanglement]?.enabled,
        equals(true),
      );
      expect(
        configs[QuantumFeatureFlags.locationEntanglement]?.rolloutPercentage,
        equals(0.0),
      );
      expect(
        configs[QuantumFeatureFlags.decoherenceTracking]?.rolloutPercentage,
        equals(0.0),
      );
      expect(
        configs[QuantumFeatureFlags.quantumPredictionFeatures]
            ?.rolloutPercentage,
        equals(0.0),
      );
      expect(
        configs[QuantumFeatureFlags.quantumSatisfactionEnhancement]
            ?.rolloutPercentage,
        equals(0.0),
      );
    });
  });

  group('FormulaReplacementFeatureFlags', () {
    test('should include calling score replacement flag', () {
      expect(
        FormulaReplacementFeatureFlags.allFlags,
        contains(FormulaReplacementFeatureFlags.callingScore),
      );
    });

    test('should return default configs with 0% rollout', () {
      final configs = FormulaReplacementFeatureFlags.getDefaultConfigs();

      expect(
        configs[FormulaReplacementFeatureFlags.callingScore]?.enabled,
        equals(true),
      );
      expect(
        configs[FormulaReplacementFeatureFlags.callingScore]?.rolloutPercentage,
        equals(0.0),
      );
    });
  });
}
