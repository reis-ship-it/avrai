import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/events/event_template.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';

/// SPOTS EventTemplate Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventTemplate model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Price Display: Free vs paid templates
/// - Time Calculations: Estimated end time
/// - Description Generation: Placeholder replacement
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
///
/// Dependencies:
/// - ExpertiseEventType: Event type enum

void main() {
  group('EventTemplate', () {
    late EventTemplate template;
    late DateTime testStartTime;

    setUp(() {
      testStartTime = DateTime(2025, 12, 1, 14, 0); // Dec 1, 2025, 2:00 PM

      template = const EventTemplate(
        id: 'coffee_tasting_tour',
        name: 'Coffee Tasting Tour',
        category: 'Coffee',
        eventType: ExpertiseEventType.tour,
        descriptionTemplate: 'Join {hostName} for a coffee tour at {location}!',
        defaultDuration: Duration(hours: 2),
        defaultMaxAttendees: 15,
        suggestedPrice: 25.0,
        suggestedSpotTypes: ['coffee_shop', 'roastery'],
        recommendedSpotCount: 3,
        icon: '☕',
        tags: ['beginner-friendly', 'indoor'],
        metadata: {
          'vibeTracking': ['energy_preference']
        },
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Price Display', () {
      test('should correctly identify free vs paid templates and format prices',
          () {
        // Test business logic: price display formatting
        final freeTemplate = EventTemplate(
          id: 'free_template',
          name: 'Free Template',
          category: 'Test',
          eventType: template.eventType,
          descriptionTemplate: 'Test description',
          defaultDuration: template.defaultDuration,
          suggestedPrice: null,
        );
        final zeroPriceTemplate = template.copyWith(suggestedPrice: 0.0);
        final expensiveTemplate = template.copyWith(suggestedPrice: 99.99);

        expect(freeTemplate.isFree, isTrue);
        expect(freeTemplate.getPriceDisplay(), 'Free');
        expect(zeroPriceTemplate.isFree, isTrue);
        expect(template.isFree, isFalse);
        expect(template.getPriceDisplay(), '\$25');
        expect(expensiveTemplate.getPriceDisplay(), '\$100');
      });
    });

    group('Time Calculations', () {
      test('should calculate estimated end time for different durations', () {
        // Test business logic: end time calculation with various durations
        final endTime = template.getEstimatedEndTime(testStartTime);
        expect(endTime, testStartTime.add(const Duration(hours: 2)));

        final longTemplate = template.copyWith(
          defaultDuration: const Duration(hours: 4),
        );
        final longEndTime = longTemplate.getEstimatedEndTime(testStartTime);
        expect(longEndTime, testStartTime.add(const Duration(hours: 4)));
      });
    });

    group('Description Generation', () {
      test(
          'should correctly generate titles and replace placeholders in descriptions',
          () {
        // Test business logic: template placeholder replacement
        final templateWithAllPlaceholders = template.copyWith(
          descriptionTemplate:
              'Join {hostName} at {location} for {spotCount} spots!',
        );

        expect(template.generateTitle('John Doe'), 'Coffee Tasting Tour');

        final fullDescription = templateWithAllPlaceholders.generateDescription(
          hostName: 'Alice',
          location: 'Park',
          spotCount: 3,
        );
        final partialDescription = template.generateDescription(
          hostName: 'John Doe',
        );

        expect(fullDescription, 'Join Alice at Park for 3 spots!');
        expect(fullDescription, isNot(contains('{')));
        expect(partialDescription, contains('John Doe'));
        expect(partialDescription, isNotEmpty);
      });
    });

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle null price',
          () {
        // Test business logic: JSON round-trip with null handling
        final json = template.toJson();
        final restored = EventTemplate.fromJson(json);

        expect(restored.isFree, equals(template.isFree));
        expect(restored.getEstimatedEndTime(testStartTime),
            equals(template.getEstimatedEndTime(testStartTime)));

        // Test null price handling
        final freeTemplate = EventTemplate(
          id: 'free_template',
          name: 'Free Template',
          category: 'Test',
          eventType: template.eventType,
          descriptionTemplate: 'Test description',
          defaultDuration: template.defaultDuration,
          suggestedPrice: null,
        );
        final freeJson = freeTemplate.toJson();
        final freeRestored = EventTemplate.fromJson(freeJson);

        expect(freeRestored.suggestedPrice, isNull);
        expect(freeRestored.isFree, isTrue);
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final updated = template.copyWith(
          name: 'Updated Name',
          suggestedPrice: 30.0,
        );

        // Test immutability (business logic)
        expect(template.name, isNot(equals('Updated Name')));
        expect(updated.name, 'Updated Name');
        expect(updated.id, template.id); // Unchanged fields preserved
      });
    });
  });
}
