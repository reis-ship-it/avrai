import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/reservation/automatic_check_in_service.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

/// Comprehensive tests for AutomaticCheckInService
void main() {
  group('AutomaticCheckInService Tests', () {
    late AutomaticCheckInService service;
    // ignore: unused_local_variable
    // ignore: unused_local_variable - May be used in callback or assertion
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = AutomaticCheckInService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Property assignment tests
    // Automatic check-in tests focus on business logic (geofence/Bluetooth triggers, check-out, visit management), not property assignment

    group('handleGeofenceTrigger', () {
      test(
          'should create automatic check-in with geofence trigger and create visit when geofence triggered',
          () async {
        // Test business logic: geofence trigger handling
        final checkIn1 = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10.0,
        );
        expect(checkIn1.id, isNotEmpty);
        expect(checkIn1.visitId, isNotEmpty);
        expect(checkIn1.geofenceTrigger, isNotNull);
        expect(checkIn1.geofenceTrigger!.locationId, equals('location-1'));
        expect(checkIn1.geofenceTrigger!.latitude, equals(40.7128));
        expect(checkIn1.geofenceTrigger!.longitude, equals(-74.0060));
        expect(checkIn1.isActive, isTrue);
        expect(checkIn1.visitCreated, isTrue);

        final checkIn2 = await service.handleGeofenceTrigger(
          userId: 'user-2',
          locationId: 'location-2',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        final visit = service.getVisit(checkIn2.visitId);
        expect(visit, isNotNull);
        expect(visit!.userId, equals('user-2'));
        expect(visit.locationId, equals('location-2'));
        expect(visit.isAutomatic, isTrue);
        expect(visit.isActive, isTrue);
      });
    });

    group('handleBluetoothTrigger', () {
      test(
          'should create automatic check-in with Bluetooth trigger and handle ai2ai connection',
          () async {
        // Test business logic: Bluetooth trigger handling with ai2ai
        final checkIn1 = await service.handleBluetoothTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          deviceId: 'device-123',
          rssi: -50,
        );
        expect(checkIn1.id, isNotEmpty);
        expect(checkIn1.visitId, isNotEmpty);
        expect(checkIn1.bluetoothTrigger, isNotNull);
        expect(checkIn1.bluetoothTrigger!.deviceId, equals('device-123'));
        expect(checkIn1.bluetoothTrigger!.rssi, equals(-50));
        expect(checkIn1.isActive, isTrue);

        final checkIn2 = await service.handleBluetoothTrigger(
          userId: 'user-2',
          locationId: 'location-2',
          deviceId: 'device-456',
          rssi: -50,
          ai2aiConnected: true,
          personalityExchanged: true,
        );
        expect(checkIn2.bluetoothTrigger!.ai2aiConnected, isTrue);
        expect(checkIn2.bluetoothTrigger!.personalityExchanged, isTrue);
      });
    });

    group('checkOut', () {
      test(
          'should check out from automatic check-in, calculate quality score based on dwell time, or return zero quality for short visits',
          () async {
        // Test business logic: check-out with quality score calculation
        final checkIn1 = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        final checkOutTime1 =
            checkIn1.checkInTime.add(const Duration(minutes: 6));
        final checkedOut1 = await service.checkOut(
          userId: 'user-1',
          checkOutTime: checkOutTime1,
        );
        expect(checkedOut1.isActive, isFalse);
        expect(checkedOut1.checkOutTime, isNotNull);
        expect(checkedOut1.dwellTime, isNotNull);
        expect(checkedOut1.qualityScore, greaterThan(0.0));

        final checkIn2 = await service.handleGeofenceTrigger(
          userId: 'user-2',
          locationId: 'location-2',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        const longDwellTime = Duration(minutes: 35);
        final checkOutTime2 = checkIn2.checkInTime.add(longDwellTime);
        final checkedOut2 = await service.checkOut(
          userId: 'user-2',
          checkOutTime: checkOutTime2,
        );
        expect(checkedOut2.qualityScore, greaterThanOrEqualTo(1.0));

        final checkIn3 = await service.handleGeofenceTrigger(
          userId: 'user-3',
          locationId: 'location-3',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        const shortDwellTime = Duration(minutes: 3);
        final checkOutTime3 = checkIn3.checkInTime.add(shortDwellTime);
        final checkedOut3 = await service.checkOut(
          userId: 'user-3',
          checkOutTime: checkOutTime3,
        );
        expect(checkedOut3.qualityScore, equals(0.0));
      });
    });

    group('getActiveCheckIns', () {
      test(
          'should return active check-ins for user, or return null when no active check-ins',
          () async {
        // Test business logic: active check-in retrieval
        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        await service.handleGeofenceTrigger(
          userId: 'user-2',
          locationId: 'location-2',
          latitude: 40.7130,
          longitude: -74.0062,
        );
        final activeCheckIn1 = service.getActiveCheckIn('user-1');
        final activeCheckIn2 = service.getActiveCheckIn('user-2');
        expect(activeCheckIn1, isNotNull);
        expect(activeCheckIn2, isNotNull);

        final activeCheckIn3 = service.getActiveCheckIn('user-3');
        expect(activeCheckIn3, isNull);
      });
    });

    group('getVisit', () {
      test('should return visit by ID, or return null for non-existent visit',
          () async {
        // Test business logic: visit retrieval
        final checkIn = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        final visit1 = service.getVisit(checkIn.visitId);
        expect(visit1, isNotNull);
        expect(visit1!.id, equals(checkIn.visitId));

        final visit2 = service.getVisit('non-existent');
        expect(visit2, isNull);
      });
    });

    group('getVisitsForUser', () {
      test('should return all visits for user', () async {
        // Test business logic: user visit retrieval
        final checkIn1 = await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );
        await service.checkOut(
          userId: 'user-1',
          checkOutTime: checkIn1.checkInTime.add(const Duration(minutes: 10)),
        );
        await service.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-2',
          latitude: 40.7130,
          longitude: -74.0062,
        );
        final visits = service.getUserVisits('user-1');
        expect(visits.length, equals(2));
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
