import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/events/event_template_service.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/unified_user.dart';
import 'package:avrai/core/models/spots/spot.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

/// SPOTS EventTemplateService Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventTemplateService functionality
///
/// Test Coverage:
/// - Template Retrieval: Get all templates, by category, by type
/// - Template Filtering: Business templates, expert templates
/// - Template Search: Keyword search functionality
/// - Event Creation: Create events from templates
/// - Category Management: Get template categories
///
/// Dependencies:
/// - EventTemplate: Template model
/// - ExpertiseEvent: Event model
/// - UnifiedUser: User model

void main() {
  group('EventTemplateService', () {
    late EventTemplateService service;
    late UnifiedUser host;
    late List<Spot> testSpots;

    setUp(() {
      service = EventTemplateService();
      host = ModelFactories.createTestUser(
        id: 'host-1',
        displayName: 'Test Host',
      );
      testSpots = [
        ModelFactories.createTestSpot(name: 'Coffee Shop 1'),
        ModelFactories.createTestSpot(name: 'Coffee Shop 2'),
      ];
    });

    // Removed: Property assignment tests
    // Template retrieval tests focus on business logic (filtering, case insensitivity), not property assignment

    group('Template Retrieval', () {
      test(
          'should return all templates, get template by ID or null if not found, and filter by category and type with case-insensitive matching',
          () {
        // Test business logic: template retrieval with filtering and case insensitivity
        final allTemplates = service.getAllTemplates();
        expect(allTemplates, isNotEmpty);
        expect(allTemplates.length, greaterThan(10));

        final template = service.getTemplate('coffee_tasting_tour');
        expect(template, isNotNull);
        expect(template?.id, 'coffee_tasting_tour');
        expect(service.getTemplate('non_existent_template'), isNull);

        final coffeeTemplates1 = service.getTemplatesByCategory('Coffee');
        final coffeeTemplates2 = service.getTemplatesByCategory('coffee');
        expect(coffeeTemplates1, isNotEmpty);
        expect(
            coffeeTemplates1.every((t) => t.category.toLowerCase() == 'coffee'),
            true);
        expect(coffeeTemplates1.length, coffeeTemplates2.length);

        final tourTemplates =
            service.getTemplatesByType(ExpertiseEventType.tour);
        expect(tourTemplates, isNotEmpty);
        expect(
            tourTemplates.every((t) => t.eventType == ExpertiseEventType.tour),
            true);
      });
    });

    group('Template Filtering', () {
      test('should get business templates and expert templates (non-business)',
          () {
        // Test business logic: template filtering by business/expert type
        final businessTemplates = service.getBusinessTemplates();
        expect(businessTemplates, isNotEmpty);
        expect(
            businessTemplates.every((t) => t.metadata['businessOnly'] == true),
            true);

        final expertTemplates = service.getExpertTemplates();
        expect(expertTemplates, isNotEmpty);
        expect(expertTemplates.every((t) => t.metadata['businessOnly'] != true),
            true);
      });
    });

    group('Template Search', () {
      test(
          'should search templates by name, category, and tags with case-insensitive matching, or return empty list for no matches',
          () {
        // Test business logic: template search with multiple search types and case insensitivity
        final nameResults = service.searchTemplates('coffee');
        expect(nameResults, isNotEmpty);
        expect(nameResults.any((t) => t.name.toLowerCase().contains('coffee')),
            true);

        final categoryResults = service.searchTemplates('food');
        expect(categoryResults, isNotEmpty);
        expect(
            categoryResults
                .any((t) => t.category.toLowerCase().contains('food')),
            true);

        final tagResults = service.searchTemplates('beginner');
        expect(tagResults, isNotEmpty);
        expect(
            tagResults.any((t) =>
                t.tags.any((tag) => tag.toLowerCase().contains('beginner'))),
            true);

        expect(service.searchTemplates('nonexistentquery12345'), isEmpty);

        final results1 = service.searchTemplates('COFFEE');
        final results2 = service.searchTemplates('coffee');
        expect(results1.length, results2.length);
      });
    });

    group('Event Creation', () {
      test(
          'should create event from template with default values and support custom parameters (title, description, spots, max attendees, price)',
          () {
        // Test business logic: event creation with defaults and custom overrides
        final template = service.getTemplate('coffee_tasting_tour')!;
        final startTime = DateTime.now().add(const Duration(days: 7));

        // Test default values
        final defaultEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
        );
        expect(defaultEvent, isA<ExpertiseEvent>());
        expect(defaultEvent.category, template.category);
        expect(defaultEvent.eventType, template.eventType);
        expect(defaultEvent.host.id, host.id);
        expect(defaultEvent.startTime, startTime);
        expect(defaultEvent.maxAttendees, template.defaultMaxAttendees);
        expect(defaultEvent.price, template.suggestedPrice);

        // Test custom title
        final titleEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customTitle: 'My Custom Coffee Tour',
        );
        expect(titleEvent.title, 'My Custom Coffee Tour');

        // Test custom description
        final descEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customDescription: 'A custom event description',
        );
        expect(descEvent.description, 'A custom event description');

        // Test selected spots
        final spotsEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          selectedSpots: testSpots,
        );
        expect(spotsEvent.spots.length, testSpots.length);

        // Test custom max attendees
        final maxEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customMaxAttendees: 30,
        );
        expect(maxEvent.maxAttendees, 30);

        // Test custom price (paid)
        final paidEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customPrice: 50.0,
        );
        expect(paidEvent.price, 50.0);
        expect(paidEvent.isPaid, true);

        // Test free event from paid template
        final freeEvent = service.createEventFromTemplate(
          template: template,
          host: host,
          startTime: startTime,
          customPrice: 0.0,
        );
        expect(freeEvent.price, 0.0);
        expect(freeEvent.isPaid, false);
      });
    });

    group('Category Management', () {
      test('should return all categories with correct structure', () {
        // Test business logic: category retrieval with structure validation
        final categories = service.getCategories();
        expect(categories, isNotEmpty);
        expect(categories.length, greaterThan(5));
        for (final category in categories) {
          expect(category.id, isNotEmpty);
          expect(category.name, isNotEmpty);
          expect(category.icon, isNotEmpty);
        }
      });
    });

    group('Default Templates', () {
      test(
          'should have default templates including coffee tasting tour, bookstore walk, and business templates',
          () {
        // Test business logic: default template availability
        final coffeeTemplate = service.getTemplate('coffee_tasting_tour');
        expect(coffeeTemplate, isNotNull);
        expect(coffeeTemplate?.category, 'Coffee');
        expect(coffeeTemplate?.eventType, ExpertiseEventType.tour);

        final bookstoreTemplate = service.getTemplate('bookstore_walk');
        expect(bookstoreTemplate, isNotNull);
        expect(bookstoreTemplate?.category, 'Books');
        expect(bookstoreTemplate?.isFree, true);

        final businessTemplates = service.getBusinessTemplates();
        expect(businessTemplates.length, greaterThan(0));
        final grandOpening = service.getTemplate('grand_opening');
        expect(grandOpening, isNotNull);
        expect(grandOpening?.metadata['businessOnly'], true);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
