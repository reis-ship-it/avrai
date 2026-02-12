// Phase 19 Privacy Compliance Tests
//
// Privacy compliance validation for Phase 19: Multi-Entity Quantum Entanglement Matching System
// Part of Phase 19.17: Testing, Documentation, and Production Readiness
//
// Validates:
// - GDPR compliance (no personal data exposure)
// - CCPA compliance (privacy rights)
// - Privacy audit (no userId exposure in third-party data)
// - Anonymization verification
// - AgentId-only validation

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/controllers/quantum_matching_controller.dart';
import 'package:avrai/core/services/quantum/third_party_data_privacy_service.dart';
import 'package:avrai/core/models/quantum/matching_input.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';

import 'package:avrai/injection_container.dart' as di;
import '../../helpers/platform_channel_helper.dart';
import '../../helpers/integration_test_helpers.dart';

void main() {
  group('Phase 19 Privacy Compliance Tests', () {
    late QuantumMatchingController controller;
    late ThirdPartyDataPrivacyService privacyService;

    setUpAll(() async {
      // Initialize dependency injection
      await setupTestStorage();
      await di.init();

      // Get services from DI
      controller = di.sl<QuantumMatchingController>();
      privacyService = di.sl<ThirdPartyDataPrivacyService>();
    });

    setUp(() async {
      // No-op: Sembast removed in Phase 26
    });

    group('AgentId-Only Validation', () {
      test('should use agentId exclusively, never userId in matching results', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-privacy-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-privacy-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act
        final result = await controller.execute(input);

        // Assert: Verify privacy protection
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);
        expect(result.matchingResult!.metadata, isNotNull);

        // Should have agentId, not userId
        expect(result.matchingResult!.metadata!.containsKey('agentId'), isTrue);
        expect(result.matchingResult!.metadata!.containsKey('userId'), isFalse);

        // AgentId should be different from userId
        final agentId = result.matchingResult!.metadata!['agentId'] as String;
        expect(agentId, isNot(equals(user.id)));
        expect(agentId, isNotEmpty);
      });

      test('should use agentId in all quantum entity states', () async {
        // Arrange
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-privacy-2',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-privacy-2',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act
        final result = await controller.execute(input);

        // Assert: All entities should have agentId, not userId
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);

        for (final entity in result.matchingResult!.entities) {
          // Entity should have entityId (which should be agentId for user entities)
          expect(entity.entityId, isNotNull);
          expect(entity.entityId, isNotEmpty);

          // Entity should NOT have userId in any form
          // Check that entityId is not the same as user.id (for user entities)
          if (entity.entityType.toString().contains('user')) {
            expect(entity.entityId, isNot(equals(user.id)));
          }
        }
      });
    });

    group('GDPR Compliance', () {
      test('should convert userId to agentId for privacy', () async {
        // Arrange
        final userId = 'user-gdpr-1';

        // Act: Convert userId to agentId
        final agentId = await privacyService.convertUserIdToAgentId(userId);

        // Assert: Should return agentId (different from userId)
        expect(agentId, isNotNull);
        expect(agentId, isNotEmpty);
        expect(agentId, isNot(equals(userId)));
      });

      test('should validate privacy compliance', () async {
        // Arrange: Create data that should pass privacy validation
        final compliantData = {
          'agentId': 'test-agent-id',
          'quantumState': {'dim1': 0.5},
          'compatibility': 0.8,
        };

        // Act: Validate privacy
        final validation = await privacyService.validatePrivacy(data: compliantData);

        // Assert: Should be compliant
        expect(validation.isCompliant, isTrue);
        expect(validation.violations, isEmpty);
      });

      test('should detect privacy violations', () async {
        // Arrange: Create data with privacy violations
        final nonCompliantData = {
          'userId': 'user-123', // Violation: userId exposed
          'email': 'user@example.com', // Violation: personal identifier
          'agentId': 'test-agent-id',
        };

        // Act: Validate privacy
        final validation = await privacyService.validatePrivacy(data: nonCompliantData);

        // Assert: Should detect violations
        expect(validation.isCompliant, isFalse);
        expect(validation.violations, isNotEmpty);
        expect(validation.violations.any((v) => v.contains('userId')), isTrue);
        expect(validation.violations.any((v) => v.contains('email')), isTrue);
      });
    });

    group('CCPA Compliance', () {
      test('should validate privacy for data deletion scenarios', () async {
        // Arrange: Data that should be deletable (using agentId)
        final dataToDelete = {
          'agentId': 'test-agent-ccpa-1',
          'quantumState': {'dim1': 0.5},
        };

        // Act: Validate privacy before deletion
        final validation = await privacyService.validatePrivacy(data: dataToDelete);

        // Assert: Should be compliant (can be safely deleted)
        expect(validation.isCompliant, isTrue);
        // In real implementation, would actually delete data
      });
    });

    group('Privacy Audit', () {
      test('should pass privacy audit - no userId in third-party data', () async {
        // Arrange: Create matching scenario
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-audit-1',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn, NY, USA',
        );

        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          id: 'event-audit-1',
          title: 'Coffee Tour',
          description: 'Explore coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
        );

        final input = MatchingInput(user: user, event: event);

        // Act: Execute matching
        final result = await controller.execute(input);

        // Assert: Privacy audit checks
        expect(result.isSuccess, isTrue);
        expect(result.matchingResult, isNotNull);

        // Check metadata
        final metadata = result.matchingResult!.metadata!;
        expect(metadata.containsKey('userId'), isFalse);
        expect(metadata.containsKey('agentId'), isTrue);

        // Check entities
        for (final entity in result.matchingResult!.entities) {
          // Entity should have entityId
          expect(entity.entityId, isNotNull);
          expect(entity.entityId, isNotEmpty);
        }

        // Check that no userId appears in any string representation
        final resultString = result.toString();
        // Should not contain the user's ID in any exposed format
        // (This is a basic check - full audit would be more comprehensive)
        expect(resultString.contains('user-audit-1'), isFalse);
      });
    });
  });
}
