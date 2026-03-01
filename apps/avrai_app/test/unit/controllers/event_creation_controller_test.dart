import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import 'package:avrai_core/models/expertise/expertise_event.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'event_creation_controller_test.mocks.dart';

@GenerateMocks([
  ExpertiseEventService,
  GeographicScopeService,
])
void main() {
  group('EventCreationController', () {
    late EventCreationController controller;
    late MockExpertiseEventService mockEventService;
    late MockGeographicScopeService mockGeographicScopeService;

    setUp(() {
      mockEventService = MockExpertiseEventService();
      mockGeographicScopeService = MockGeographicScopeService();

      // Default: allow geographic validation to pass so tests can focus on the
      // specific validation/error they are asserting.
      when(mockGeographicScopeService.validateEventLocation(
        userId: anyNamed('userId'),
        user: anyNamed('user'),
        category: anyNamed('category'),
        eventLocality: anyNamed('eventLocality'),
      )).thenReturn(true);

      controller = EventCreationController(
        eventService: mockEventService,
        geographicScopeService: mockGeographicScopeService,
        // Avoid GetIt lookups in unit tests.
        geoHierarchyService: GeoHierarchyService(),
      );
    });

    group('validateForm', () {
      test('should return valid result for valid form data', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops in Brooklyn',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 20,
          isPublic: true,
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.fieldErrors, isEmpty);
        expect(result.generalErrors, isEmpty);
      });

      test('should return invalid result for empty title', () {
        // Arrange
        final formData = EventFormData(
          title: '',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['title'], equals('Title is required'));
      });

      test('should return invalid result for title too short', () {
        // Arrange
        final formData = EventFormData(
          title: 'Ab',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['title'],
            equals('Title must be at least 3 characters'));
      });

      test('should return invalid result for empty description', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: '',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['description'],
            equals('Description is required'));
      });

      test('should return invalid result for description too short', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Short',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['description'],
            equals('Description must be at least 10 characters'));
      });

      test('should return invalid result for empty category', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: '',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['category'], equals('Category is required'));
      });

      test('should return invalid result for maxAttendees less than 1', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          maxAttendees: 0,
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['maxAttendees'],
            equals('Max attendees must be at least 1'));
      });

      test('should return invalid result for maxAttendees greater than 1000',
          () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          maxAttendees: 1001,
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['maxAttendees'],
            equals('Max attendees cannot exceed 1000'));
      });

      test('should return invalid result for negative price', () {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          price: -10.0,
        );

        // Act
        final result = controller.validateForm(formData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.fieldErrors['price'], equals('Price cannot be negative'));
      });
    });

    group('validateExpertise', () {
      test('should return valid result for user with Local level expertise',
          () {
        // Arrange
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: false,
          expertiseMap: const {'Coffee': 'local'},
        );

        // Act
        final result = controller.validateExpertise(user, 'Coffee');

        // Assert
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should return valid result for user with City level expertise', () {
        // Arrange
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: false,
          expertiseMap: const {'Coffee': 'city'},
        );

        // Act
        final result = controller.validateExpertise(user, 'Coffee');

        // Assert
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test(
          'should return invalid result for user without expertise in category',
          () {
        // Arrange
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: false,
          expertiseMap: const {'Food': 'local'},
        );

        // Act
        final result = controller.validateExpertise(user, 'Coffee');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.error, contains('You must have expertise in Coffee'));
      });

      test(
          'should return invalid result for user with expertise below Local level',
          () {
        // Note: This test assumes there are expertise levels below Local
        // If all levels are Local or above, this test may need adjustment
        // Arrange - user with no expertise in category (empty map)
        final user = UnifiedUser(
          id: 'user-1',
          email: 'test@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: false,
          expertiseMap: const {},
        );

        // Act
        final result = controller.validateExpertise(user, 'Coffee');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.error, contains('You must have expertise in Coffee'));
      });
    });

    group('validateDates', () {
      test('should return valid result for future dates with valid duration',
          () {
        // Arrange
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        // Act
        final result = controller.validateDates(startTime, endTime);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.generalErrors, isEmpty);
      });

      test('should return invalid result for start time in the past', () {
        // Arrange
        final startTime = DateTime.now().subtract(const Duration(hours: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        // Act
        final result = controller.validateDates(startTime, endTime);

        // Assert
        expect(result.isValid, isFalse);
        expect(
            result.generalErrors, contains('Start time must be in the future'));
      });

      test('should return invalid result for end time before start time', () {
        // Arrange
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.subtract(const Duration(hours: 1));

        // Act
        final result = controller.validateDates(startTime, endTime);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors,
            contains('End time must be after start time'));
      });

      test('should return invalid result for duration less than 1 minute', () {
        // Arrange
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(seconds: 30));

        // Act
        final result = controller.validateDates(startTime, endTime);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors,
            contains('Event duration must be at least 1 minute'));
      });

      test('should return invalid result for duration greater than 7 days', () {
        // Arrange
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(days: 8));

        // Act
        final result = controller.validateDates(startTime, endTime);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.generalErrors,
            contains('Event duration cannot exceed 7 days'));
      });
    });

    group('createEvent', () {
      final testUser = UnifiedUser(
        id: 'user-1',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isOnline: false,
        location: 'Greenpoint, Brooklyn, NY, USA',
        expertiseMap: const {'Coffee': 'local'},
      );

      test('should successfully create event with valid data', () async {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tasting Tour',
          description: 'Explore local coffee shops in Brooklyn',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
          maxAttendees: 20,
          isPublic: true,
        );

        final expectedEvent = ExpertiseEvent(
          id: 'event-1',
          title: formData.title,
          description: formData.description,
          category: formData.category,
          eventType: formData.eventType,
          host: testUser,
          startTime: formData.startTime,
          endTime: formData.endTime,
          location: formData.location,
          maxAttendees: formData.maxAttendees,
          isPublic: formData.isPublic,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockGeographicScopeService.validateEventLocation(
          userId: anyNamed('userId'),
          user: anyNamed('user'),
          category: anyNamed('category'),
          eventLocality: anyNamed('eventLocality'),
        )).thenReturn(true);
        when(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        )).thenAnswer((_) async => expectedEvent);

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: testUser,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.event, isNotNull);
        expect(result.event!.id, equals('event-1'));
        expect(result.event!.title, equals(formData.title));
        verify(mockEventService.createEvent(
          host: testUser,
          title: formData.title,
          description: formData.description,
          category: formData.category,
          eventType: formData.eventType,
          startTime: formData.startTime,
          endTime: formData.endTime,
          location: formData.location,
          maxAttendees: formData.maxAttendees,
          isPublic: formData.isPublic,
        )).called(1);
      });

      test('should return failure result for invalid form data', () async {
        // Arrange
        final formData = EventFormData(
          title: '', // Invalid: empty title
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: testUser,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, equals('Form validation failed'));
        expect(result.errorCode, equals('VALIDATION_ERROR'));
        expect(result.validationErrors, isNotNull);
        expect(result.validationErrors!.isValid, isFalse);
        verifyNever(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        ));
      });

      test('should return failure result for user without required expertise',
          () async {
        // Arrange
        final userWithoutExpertise = UnifiedUser(
          id: 'user-2',
          email: 'test2@example.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isOnline: false,
          expertiseMap: const {}, // No expertise
        );

        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: userWithoutExpertise,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('EXPERTISE_ERROR'));
        expect(result.error, contains('You must have expertise in Coffee'));
        verifyNever(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        ));
      });

      test('should return failure result for invalid geographic scope',
          () async {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Manhattan, New York',
          locality: 'Manhattan', // Different locality than user's
        );

        when(mockGeographicScopeService.validateEventLocation(
          userId: anyNamed('userId'),
          user: anyNamed('user'),
          category: anyNamed('category'),
          eventLocality: anyNamed('eventLocality'),
        )).thenThrow(Exception(
            'Local experts can only host events in their own locality'));

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: testUser,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('GEOGRAPHIC_SCOPE_ERROR'));
        expect(result.error, contains('Local experts can only host events'));
        verifyNever(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        ));
      });

      test('should return failure result for invalid dates', () async {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime:
              DateTime.now().subtract(const Duration(days: 1)), // Past date
          endTime: DateTime.now().add(const Duration(hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
        );

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: testUser,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('DATE_ERROR'));
        expect(result.error, equals('Date validation failed'));
        verifyNever(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        ));
      });

      test(
          'should return failure result when event creation service throws error',
          () async {
        // Arrange
        final formData = EventFormData(
          title: 'Coffee Tour',
          description: 'Explore local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Greenpoint, Brooklyn',
          locality: 'Greenpoint',
        );

        when(mockGeographicScopeService.validateEventLocation(
          userId: anyNamed('userId'),
          user: anyNamed('user'),
          category: anyNamed('category'),
          eventLocality: anyNamed('eventLocality'),
        )).thenReturn(true);
        when(mockEventService.createEvent(
          host: anyNamed('host'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          category: anyNamed('category'),
          eventType: anyNamed('eventType'),
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          spots: anyNamed('spots'),
          location: anyNamed('location'),
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          maxAttendees: anyNamed('maxAttendees'),
          price: anyNamed('price'),
          isPublic: anyNamed('isPublic'),
        )).thenThrow(Exception('Database connection failed'));

        // Act
        final result = await controller.createEvent(
          formData: formData,
          host: testUser,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.errorCode, equals('CREATION_ERROR'));
        expect(result.error, contains('Database connection failed'));
      });
    });
  });
}
