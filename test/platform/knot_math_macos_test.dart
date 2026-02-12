// Platform-specific integration test for macOS
// Tests Rust FFI integration on macOS platform

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/bridge/knot_math_bridge.dart/frb_generated.dart';

void main() {
  group('Knot Math macOS Integration', () {
    late PersonalityKnotService service;

    setUpAll(() async {
      // Initialize Rust library for macOS
      // Note: This will load the actual .dylib library on macOS
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

    test('should load Rust library on macOS', () {
      // ignore: invalid_use_of_internal_member - Testing internal RustLib instance
      expect(RustLib.instance, isNotNull);
    });

    test('should generate knot on macOS', () async {
      final profile = PersonalityProfile.initial(
        'macos_test_agent',
        userId: 'macos_test_user',
      );

      final knot = await service.generateKnot(profile);

      expect(knot, isNotNull);
      expect(knot.agentId, equals('macos_test_agent'));
      expect(knot.invariants.crossingNumber, greaterThanOrEqualTo(0));
    });

    test('should calculate compatibility on macOS', () async {
      final profile1 = PersonalityProfile.initial(
        'macos_test_agent_1',
        userId: 'macos_test_user_1',
      );
      final profile2 = PersonalityProfile.initial(
        'macos_test_agent_2',
        userId: 'macos_test_user_2',
      );

      final knot1 = await service.generateKnot(profile1);
      final knot2 = await service.generateKnot(profile2);

      final compatibility = await service.calculateCompatibility(knot1, knot2);

      expect(compatibility, greaterThanOrEqualTo(0.0));
      expect(compatibility, lessThanOrEqualTo(1.0));
    });
  });
}
