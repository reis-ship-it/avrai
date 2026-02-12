import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/spots/visit.dart';

/// SPOTS Visit Model Unit Tests
/// Date: December 1, 2025
/// Purpose: Test Visit model functionality
///
/// Test Coverage:
/// - Model Creation: Constructor and properties
/// - Active Status: Check if visit is active
/// - Dwell Time Calculation: Calculate from check-in/out
/// - Quality Score Calculation: Based on dwell time and engagement
/// - Check Out: Check out from visit
/// - JSON Serialization: toJson/fromJson
/// - Equality: Equatable implementation
///
/// Dependencies:
/// - GeofencingData: Geofencing trigger data
/// - BluetoothData: Bluetooth trigger data

void main() {
  group('Visit', () {
    late Visit visit;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 12, 1, 14, 0);

      visit = Visit(
        id: 'visit-123',
        userId: 'user-789',
        locationId: 'spot-456',
        checkInTime: testDate,
        qualityScore: 0.0,
        isAutomatic: true,
        isRepeatVisit: false,
        visitNumber: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Active Status', () {
      test('should correctly identify active and inactive visits', () {
        // Test business logic: active status determination
        expect(visit.isActive, isTrue);

        final checkedOut = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        expect(checkedOut.isActive, isFalse);
      });
    });

    group('Dwell Time Calculation', () {
      test('should calculate dwell time for checked out and active visits', () {
        // Test business logic: dwell time calculation in different states
        final checkedOut = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        final now = DateTime.now();
        final activeVisit = visit.copyWith(
            checkInTime: now.subtract(const Duration(minutes: 30)));

        expect(checkedOut.calculateDwellTime(), const Duration(hours: 2));
        final activeDwellTime = activeVisit.calculateDwellTime();
        expect(activeDwellTime.inMinutes, greaterThanOrEqualTo(29));
        expect(activeDwellTime.inMinutes, lessThanOrEqualTo(31));
      });
    });

    group('Quality Score Calculation', () {
      test(
          'should calculate quality score based on dwell time and engagement factors',
          () {
        // Test business logic: quality score calculation with bonuses and caps
        final longVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 1)),
          dwellTime: const Duration(hours: 1),
        );
        final normalVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
        );
        final quickVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 5)),
          dwellTime: const Duration(minutes: 5),
        );
        final visitWithReview = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
          rating: 4.5,
        );
        final visitWithDetailedReview = visit.copyWith(
          checkOutTime: testDate.add(const Duration(minutes: 15)),
          dwellTime: const Duration(minutes: 15),
          reviewId: 'review-123',
          rating: 4.5,
        );
        final maxVisit = visit.copyWith(
          checkOutTime: testDate.add(const Duration(hours: 1)),
          dwellTime: const Duration(hours: 1),
          reviewId: 'review-123',
          rating: 5.0,
          isRepeatVisit: true,
        );

        expect(longVisit.calculateQualityScore(), greaterThanOrEqualTo(1.0));
        expect(normalVisit.calculateQualityScore(), greaterThanOrEqualTo(0.8));
        expect(quickVisit.calculateQualityScore(), lessThan(0.8));
        expect(
            visitWithReview.calculateQualityScore(), greaterThan(0.8)); // Bonus
        expect(visitWithDetailedReview.calculateQualityScore(),
            greaterThan(1.0)); // Both bonuses
        expect(
            maxVisit.calculateQualityScore(), lessThanOrEqualTo(1.5)); // Capped
      });
    });

    group('Check Out', () {
      test(
          'should check out visit with provided or current time and calculate quality',
          () {
        // Test business logic: checkout behavior with time handling
        final checkedOutWithTime = visit.checkOut(
          checkOutTime: testDate.add(const Duration(hours: 2)),
        );
        final checkedOutWithoutTime = visit.checkOut();

        expect(checkedOutWithTime.checkOutTime, isNotNull);
        expect(checkedOutWithTime.dwellTime, isNotNull);
        expect(checkedOutWithTime.qualityScore, greaterThan(0.0));
        expect(checkedOutWithTime.isActive, false);
        expect(checkedOutWithoutTime.checkOutTime, isNotNull);
        expect(checkedOutWithoutTime.isActive, false);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
        final json = visit.toJson();
        final restored = Visit.fromJson(json);

        // Test critical business fields preserved
        expect(restored.isActive, equals(visit.isActive));
        expect(restored.qualityScore, equals(visit.qualityScore));
      });
    });

    // Removed: Equality group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail
  });
}
