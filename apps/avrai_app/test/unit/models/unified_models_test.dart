import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_core/models/user/unified_models.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Unified Models
/// Tests UnifiedUserAction, UnifiedAIModel, and OrchestrationEvent
void main() {
  group('Unified Models Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: UserAction Enum Tests group
    // These tests only verified enum definition and property values, not business logic
    // Enum values and string representations are implementation details

    group('UnifiedUserAction Model Tests', () {
      test(
          'should serialize and deserialize with defaults and handle missing optional fields',
          () {
        // Test business logic: JSON round-trip with default handling
        final originalAction = ModelFactories.createTestUserAction(
          type: 'search_query',
          metadata: {
            'query': 'italian restaurants',
            'filters': ['rating>4', 'price<3']
          },
        );

        final json = originalAction.toJson();
        final reconstructed = UnifiedUserAction.fromJson(json);

        expect(reconstructed.type, equals(originalAction.type));
        expect(reconstructed.timestamp, equals(originalAction.timestamp));
        expect(reconstructed.metadata, equals(originalAction.metadata));

        // Test defaults with minimal JSON
        final minimalJson = {
          'type': 'map_interaction',
          'timestamp': testDate.toIso8601String(),
          'socialContext': {
            'nearbyUsers': [],
            'friends': [],
            'communityMembers': ['local'],
            'socialMetrics': {},
            'timestamp': testDate.toIso8601String(),
          },
        };
        final fromMinimal = UnifiedUserAction.fromJson(minimalJson);

        expect(fromMinimal.metadata, isEmpty);
        expect(fromMinimal.location, isNull);
        expect(fromMinimal.socialContext.communityMembers, contains('local'));
      });
    });

    group('UnifiedAIModel Tests', () {
      test(
          'should serialize and deserialize complex parameters with defaults and handle missing optional fields',
          () {
        // Test business logic: JSON round-trip with nested structures and default handling
        final originalModel = UnifiedAIModel(
          id: 'roundtrip-model',
          name: 'Roundtrip Test Model',
          version: '1.5.2',
          parameters: {
            'nested': {
              'deep': {'value': 'test'}
            },
            'array': [1, 2, 3],
            'boolean': true,
            'architecture': {
              'layers': [128, 64, 32, 8],
              'activation': 'relu',
            },
          },
          lastUpdated: testDate,
          accuracy: 0.89,
          status: 'testing',
        );

        final json = originalModel.toJson();
        final reconstructed = UnifiedAIModel.fromJson(json);

        expect(reconstructed.id, equals(originalModel.id));
        expect(reconstructed.parameters, equals(originalModel.parameters));
        expect(reconstructed.accuracy, equals(originalModel.accuracy));

        // Test defaults with minimal JSON
        final minimalJson = {
          'id': 'minimal-model',
          'name': 'Minimal Model',
          'version': '1.0.0',
          'lastUpdated': testDate.toIso8601String(),
        };
        final fromMinimal = UnifiedAIModel.fromJson(minimalJson);

        expect(fromMinimal.parameters, isEmpty);
        expect(fromMinimal.accuracy, equals(0.0));
        expect(fromMinimal.status, equals('inactive'));
      });
    });

    group('OrchestrationEvent Tests', () {
      test(
          'should serialize and deserialize, accept any numeric value, and preserve timestamp precision',
          () {
        // Test business logic: JSON round-trip, no value bounds, timestamp precision
        final originalEvent = OrchestrationEvent(
          eventType: 'ai_model_performance_metric',
          value: 0.9456,
          timestamp: testDate,
        );

        final json = originalEvent.toJson();
        final reconstructed = OrchestrationEvent.fromJson(json);

        expect(reconstructed.eventType, equals(originalEvent.eventType));
        expect(reconstructed.value, equals(originalEvent.value));
        expect(reconstructed.timestamp, equals(originalEvent.timestamp));

        // Test value bounds and timestamp precision
        final events = [
          OrchestrationEvent(
              eventType: 'minimum', value: 0.0, timestamp: testDate),
          OrchestrationEvent(
              eventType: 'negative', value: -0.5, timestamp: testDate),
          OrchestrationEvent(
              eventType: 'large', value: 100.0, timestamp: testDate),
          OrchestrationEvent(
            eventType: 'precise_time',
            value: 0.8,
            timestamp: DateTime(2025, 6, 15, 14, 30, 45, 123, 456),
          ),
        ];

        expect(events[0].value, equals(0.0));
        expect(events[1].value, equals(-0.5)); // No bounds enforcement
        expect(events[2].value, equals(100.0)); // No bounds enforcement
        expect(events[3].timestamp.microsecond,
            equals(456)); // Precision preserved
      });
    });

    group('Integration Tests', () {
      test('should validate event chronology in sequences', () {
        // Test business logic: events maintain chronological order
        final events = [
          OrchestrationEvent(
            eventType: 'start',
            value: 0.0,
            timestamp: testDate,
          ),
          OrchestrationEvent(
            eventType: 'middle',
            value: 0.5,
            timestamp: testDate.add(const Duration(minutes: 5)),
          ),
          OrchestrationEvent(
            eventType: 'end',
            value: 1.0,
            timestamp: testDate.add(const Duration(minutes: 10)),
          ),
        ];

        // Verify chronological order (business logic validation)
        for (int i = 1; i < events.length; i++) {
          expect(events[i].timestamp.isAfter(events[i - 1].timestamp), isTrue,
              reason: 'Events should maintain chronological order');
        }
      });
    });

    group('Edge Cases and Error Handling', () {
      test(
          'should handle empty collections, extreme values, and preserve special characters and unicode in strings',
          () {
        // Test business logic: edge case handling and string preservation
        final action = UnifiedUserAction(
          type: 'empty_metadata_action',
          timestamp: testDate,
          metadata: {},
          socialContext: UnifiedSocialContext(
            nearbyUsers: [],
            friends: [],
            communityMembers: ['test'],
            socialMetrics: {},
            timestamp: testDate,
          ),
        );
        final model = UnifiedAIModel(
          id: 'empty-params',
          name: 'Empty Parameters Model',
          version: '1.0.0',
          parameters: {},
          lastUpdated: testDate,
          accuracy: 0.0,
          status: 'inactive',
        );
        final event = OrchestrationEvent(
          eventType: 'extreme_value',
          value: double.maxFinite,
          timestamp: testDate,
        );
        final unicodeAction = UnifiedUserAction(
          type: 'special_chars_test_🚀',
          timestamp: testDate,
          metadata: {
            'unicode_text': 'Hello 世界 🌍',
            'special_chars': r'@#$%^&*()_+-=[]{}|;:,.<>?',
          },
          socialContext: UnifiedSocialContext(
            nearbyUsers: [],
            friends: [],
            communityMembers: ['unicode_test_ñáéíóú'],
            socialMetrics: {'test': 0.5},
            timestamp: testDate,
          ),
        );

        expect(action.metadata, isEmpty);
        expect(model.parameters, isEmpty);
        expect(event.value, equals(double.maxFinite));
        expect(unicodeAction.type, contains('🚀'));
        expect(unicodeAction.metadata['unicode_text'], contains('世界'));
        expect(unicodeAction.socialContext.communityMembers.first,
            contains('ñáéíóú'));
      });
    });
  });
}

// Note: Using UnifiedLocation from unified_models.dart
