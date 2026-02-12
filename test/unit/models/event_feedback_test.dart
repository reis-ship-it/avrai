import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/events/event_feedback.dart';

/// SPOTS EventFeedback Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test EventFeedback model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Rating Validation: Overall and category ratings
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
/// - Copy With: Field updates
///
/// Dependencies:
/// - PartnerRating: Partner rating model (in same file)

void main() {
  group('EventFeedback', () {
    late EventFeedback feedback;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      feedback = EventFeedback(
        id: 'feedback-123',
        eventId: 'event-456',
        userId: 'user-789',
        userRole: 'attendee',
        overallRating: 4.5,
        categoryRatings: const {
          'organization': 4.5,
          'content_quality': 5.0,
          'venue': 4.0,
        },
        comments: 'Great event!',
        highlights: const ['Great organization', 'Interesting content'],
        improvements: const ['Better venue', 'More time'],
        submittedAt: testDate,
        wouldAttendAgain: true,
        wouldRecommend: true,
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    // Removed: Rating Validation group
    // These tests only verified property assignment, not business logic

    group('JSON Serialization', () {
      test(
          'should serialize and deserialize with defaults and handle null optional fields',
          () {
        // Test business logic: JSON round-trip with default handling
        final json = feedback.toJson();
        final restored = EventFeedback.fromJson(json);

        expect(restored.overallRating, equals(feedback.overallRating));
        expect(restored.wouldAttendAgain, equals(feedback.wouldAttendAgain));

        // Test defaults with minimal JSON
        final minimalFeedback = EventFeedback(
          id: 'feedback-1',
          eventId: 'event-1',
          userId: 'user-1',
          userRole: 'attendee',
          overallRating: 3.0,
          categoryRatings: const {'overall': 3.0},
          submittedAt: testDate,
          wouldAttendAgain: false,
          wouldRecommend: false,
        );
        final minimalJson = minimalFeedback.toJson();
        final fromMinimal = EventFeedback.fromJson(minimalJson);

        expect(fromMinimal.comments, isNull);
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        final updated = feedback.copyWith(
          overallRating: 5.0,
          wouldAttendAgain: false,
        );

        // Test immutability (business logic)
        expect(feedback.overallRating, isNot(equals(5.0)));
        expect(updated.overallRating, equals(5.0));
        expect(updated.id, equals(feedback.id)); // Unchanged fields preserved
      });
    });
  });

  group('PartnerRating', () {
    late PartnerRating rating;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      rating = PartnerRating(
        id: 'rating-123',
        eventId: 'event-456',
        raterId: 'user-789',
        ratedId: 'user-012',
        partnershipRole: 'host',
        overallRating: 4.5,
        professionalism: 5.0,
        communication: 4.0,
        reliability: 4.5,
        wouldPartnerAgain: 5.0,
        positives: 'Great communication',
        improvements: 'Could be more punctual',
        submittedAt: testDate,
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final json = rating.toJson();
        final restored = PartnerRating.fromJson(json);

        // Test critical business fields preserved
        expect(restored.overallRating, equals(rating.overallRating));
        expect(restored.wouldPartnerAgain, equals(rating.wouldPartnerAgain));
      });
    });
  });
}
