// Platform-specific integration test for iOS
// Tests Rust FFI integration on iOS platform

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/runtime_api.dart';

void main() {
  final runNativeKnotPlatformTests =
      Platform.environment['RUN_KNOT_PLATFORM_TESTS'] == 'true';
  if (!runNativeKnotPlatformTests || !Platform.isIOS) {
    test(
      'Knot Math iOS integration tests are skipped by default',
      () {},
    );
    return;
  }

  group('Knot Math iOS Integration', () {
    late PersonalityKnotService service;

    setUpAll(() async {
      // Initialize Rust library for iOS
      // Note: This will load the actual .a library on iOS
      try {
        await RustLib.init();
      } catch (e) {
        // If already initialized or in test mode, that's fine
        if (!e.toString().contains('Should not initialize')) {
          rethrow;
        }
      }
    });

    setUp(() {
      service = PersonalityKnotService();
    });

    test('should load Rust library on iOS', () {
      // ignore: invalid_use_of_internal_member - Testing internal RustLib instance
      expect(RustLib.instance, isNotNull);
    });

    test('should generate knot on iOS', () async {
      final profile = PersonalityProfile.initial(
        'ios_test_agent',
        userId: 'ios_test_user',
      );

      final knot = await service.generateKnot(profile);

      expect(knot, isNotNull);
      expect(knot.agentId, equals('ios_test_agent'));
      expect(knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
    });

    test('should calculate compatibility on iOS', () async {
      final profile1 = PersonalityProfile.initial(
        'ios_test_agent_1',
        userId: 'ios_test_user_1',
      );
      final profile2 = PersonalityProfile.initial(
        'ios_test_agent_2',
        userId: 'ios_test_user_2',
      );

      final knot1 = await service.generateKnot(profile1);
      final knot2 = await service.generateKnot(profile2);

      final compatibility = await service.calculateCompatibility(knot1, knot2);

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });
  });
}
