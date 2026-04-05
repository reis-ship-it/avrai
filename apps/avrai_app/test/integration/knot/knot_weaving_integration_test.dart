// Knot Weaving Integration Tests
//
// Integration tests for knot weaving workflow
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 2: Knot Weaving

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  final runHeavyIntegrationTests =
      Platform.environment['RUN_HEAVY_INTEGRATION_TESTS'] == 'true';

  group('Knot Weaving Integration Tests', () {
    late PersonalityKnotService personalityKnotService;
    late KnotWeavingService knotWeavingService;
    late KnotStorageService knotStorageService;
    bool rustLibInitialized = false;

    setUpAll(() async {
      if (!runHeavyIntegrationTests) {
        return;
      }

      await setupTestStorage();

      // Initialize Rust library once for all tests
      if (!rustLibInitialized) {
        try {
          await RustLib.init();
          rustLibInitialized = true;
        } catch (e) {
          // If already initialized, that's fine
          if (!e.toString().contains('Should not initialize')) {
            rethrow;
          }
          rustLibInitialized = true;
        }
      }
    });

    setUp(() {
      personalityKnotService = PersonalityKnotService();
      knotWeavingService = KnotWeavingService(
        personalityKnotService: personalityKnotService,
      );
      knotStorageService = KnotStorageService(
        storageService: StorageService.instance,
      );
    });

    group('End-to-End Braiding Workflow', () {
      test(
          'should complete full workflow: generate knots → weave → store → retrieve',
          () async {
        // Step 1: Generate personality knots
        final profile1 =
            PersonalityProfile.initial('agent-1', userId: 'user-1');
        final profile2 =
            PersonalityProfile.initial('agent-2', userId: 'user-2');

        final knot1 = await personalityKnotService.generateKnot(profile1);
        final knot2 = await personalityKnotService.generateKnot(profile2);

        expect(knot1, isNotNull);
        expect(knot2, isNotNull);

        // Step 2: Weave knots together
        final braidedKnot = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.friendship,
        );

        expect(braidedKnot, isNotNull);
        expect(braidedKnot.knotA, equals(knot1));
        expect(braidedKnot.knotB, equals(knot2));

        // Step 3: Store braided knot
        await knotStorageService.saveBraidedKnot(
          connectionId: 'connection-1',
          braidedKnot: braidedKnot,
        );

        // Step 4: Retrieve braided knot
        final retrieved =
            await knotStorageService.getBraidedKnot('connection-1');

        expect(retrieved, isNotNull);
        expect(retrieved?.id, equals(braidedKnot.id));
        expect(retrieved?.complexity, equals(braidedKnot.complexity));
        expect(retrieved?.stability, equals(braidedKnot.stability));
        expect(retrieved?.harmonyScore, equals(braidedKnot.harmonyScore));
      });

      test(
          'should create different braided knots for different relationship types',
          () async {
        final profile1 =
            PersonalityProfile.initial('agent-3', userId: 'user-3');
        final profile2 =
            PersonalityProfile.initial('agent-4', userId: 'user-4');

        final knot1 = await personalityKnotService.generateKnot(profile1);
        final knot2 = await personalityKnotService.generateKnot(profile2);

        final friendshipBraid = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.friendship,
        );

        final romanticBraid = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.romantic,
        );

        // Different relationship types should produce different braids
        expect(friendshipBraid.relationshipType,
            equals(RelationshipType.friendship));
        expect(
            romanticBraid.relationshipType, equals(RelationshipType.romantic));
        expect(friendshipBraid.braidSequence,
            isNot(equals(romanticBraid.braidSequence)));
      });

      test('should calculate compatibility before weaving', () async {
        final profile1 =
            PersonalityProfile.initial('agent-5', userId: 'user-5');
        final profile2 =
            PersonalityProfile.initial('agent-6', userId: 'user-6');

        final knot1 = await personalityKnotService.generateKnot(profile1);
        final knot2 = await personalityKnotService.generateKnot(profile2);

        // Calculate compatibility
        final compatibility =
            await knotWeavingService.calculateWeavingCompatibility(
          knotA: knot1,
          knotB: knot2,
        );

        expect(compatibility, greaterThanOrEqualTo(0.0));
        expect(compatibility, lessThanOrEqualTo(1.0));

        // Create preview
        final preview = await knotWeavingService.previewBraiding(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.friendship,
        );

        expect(preview, isNotNull);
        expect(preview.compatibility, equals(compatibility));
      });

      test('should handle multiple braided knots for same connection',
          () async {
        final profile1 =
            PersonalityProfile.initial('agent-7', userId: 'user-7');
        final profile2 =
            PersonalityProfile.initial('agent-8', userId: 'user-8');

        final knot1 = await personalityKnotService.generateKnot(profile1);
        final knot2 = await personalityKnotService.generateKnot(profile2);

        // Create multiple braided knots with different relationship types
        final braid1 = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.friendship,
        );

        final braid2 = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.collaborative,
        );

        // Store both
        await knotStorageService.saveBraidedKnot(
          connectionId: 'connection-2',
          braidedKnot: braid1,
        );

        await knotStorageService.saveBraidedKnot(
          connectionId: 'connection-3',
          braidedKnot: braid2,
        );

        // Retrieve both
        final retrieved1 =
            await knotStorageService.getBraidedKnot('connection-2');
        final retrieved2 =
            await knotStorageService.getBraidedKnot('connection-3');

        expect(retrieved1, isNotNull);
        expect(retrieved2, isNotNull);
        expect(
            retrieved1?.relationshipType, equals(RelationshipType.friendship));
        expect(retrieved2?.relationshipType,
            equals(RelationshipType.collaborative));
      });

      test('should delete braided knot when connection is removed', () async {
        final profile1 =
            PersonalityProfile.initial('agent-9', userId: 'user-9');
        final profile2 =
            PersonalityProfile.initial('agent-10', userId: 'user-10');

        final knot1 = await personalityKnotService.generateKnot(profile1);
        final knot2 = await personalityKnotService.generateKnot(profile2);

        final braidedKnot = await knotWeavingService.weaveKnots(
          knotA: knot1,
          knotB: knot2,
          relationshipType: RelationshipType.friendship,
        );

        // Store
        await knotStorageService.saveBraidedKnot(
          connectionId: 'connection-4',
          braidedKnot: braidedKnot,
        );

        // Verify it exists
        final before = await knotStorageService.getBraidedKnot('connection-4');
        expect(before, isNotNull);

        // Delete
        await knotStorageService.deleteBraidedKnot('connection-4');

        // Verify it's gone
        final after = await knotStorageService.getBraidedKnot('connection-4');
        expect(after, isNull);
      });
    });
  }, skip: !runHeavyIntegrationTests);
}
