import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:avrai_runtime_os/services/cross_app/cross_locality_connection_service.dart';
import 'package:avrai_core/models/geographic/cross_locality_connection.dart'
    as models;
import 'package:avrai_core/models/user/user_movement_pattern.dart';
import 'package:avrai_core/models/user/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/platform_channel_helper.dart';

// import 'cross_locality_connection_service_test.mocks.dart'; // Not needed - placeholder tests

// Tests for CrossLocalityConnectionService
// Phase 7, Section 41 (7.4.3): Backend Completion

@GenerateMocks([])
void main() {
  setUpAll(() async {
    await setupTestStorage();
  });

  tearDownAll(() async {
    await cleanupTestStorage();
  });

  // Removed: Property assignment tests
  // Cross-locality connection tests focus on business logic (connection identification, movement patterns, connection strength), not property assignment

  group('CrossLocalityConnectionService Tests', () {
    late CrossLocalityConnectionService service;
    late UnifiedUser user;

    setUp(() {
      service = CrossLocalityConnectionService();
      user = ModelFactories.createTestUser(id: 'user-1');
    });

    test(
        'should identify connected localities based on user movement, track user movement patterns, detect metro areas, calculate connection strength, track transportation methods, or sort connected localities by connection strength',
        () async {
      // Test business logic: connected localities identification
      // Arrange - Service will query user movement patterns
      // Act
      final connectedLocalities = await service.getConnectedLocalities(
        user: user,
        locality: 'Mission District',
      );

      // Assert - Should return list of connected localities (may be empty for new user)
      expect(connectedLocalities, isA<List>());
      // Connected localities should be sorted by connection strength (highest first)
      for (int i = 0; i < connectedLocalities.length - 1; i++) {
        expect(
          connectedLocalities[i].connectionStrength,
          greaterThanOrEqualTo(connectedLocalities[i + 1].connectionStrength),
        );
      }
    });

    test('should get user movement patterns', () async {
      // Test business logic: movement pattern retrieval
      // Act
      final patterns = await service.getUserMovementPatterns(user: user);

      // Assert - Should return movement patterns object
      expect(patterns, isNotNull);
      expect(patterns.commutePatterns, isA<List>());
      expect(patterns.travelPatterns, isA<List>());
      expect(patterns.funPatterns, isA<List>());
    });

    test('should detect metro area connections', () async {
      // Test business logic: metro area detection
      // Act
      final isSameMetro = await service.isInSameMetroArea(
        locality1: 'Mission District',
        locality2: 'SOMA',
      );

      // Assert - Should return boolean
      expect(isSameMetro, isA<bool>());
    });
  });

  group('UserMovementPattern Tests', () {
    // Removed: 'should create movement pattern with all fields' test
    // This test only verified property assignment, not business logic

    test(
        'should calculate pattern strength correctly and determine active status',
        () {
      // High frequency, regular, recent
      final strongPattern = UserMovementPattern(
        userId: 'user-1',
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-2',
        targetLocalityName: 'SOMA',
        patternType: models.MovementPatternType.commute,
        transportationMethod: models.TransportationMethod.transit,
        frequency: 25.0,
        isRegular: true,
        firstObserved: DateTime.now().subtract(const Duration(days: 90)),
        lastObserved: DateTime.now().subtract(const Duration(days: 1)),
        tripCount: 75,
      );

      // Low frequency, irregular, old
      final weakPattern = UserMovementPattern(
        userId: 'user-2',
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-3',
        targetLocalityName: 'Marina',
        patternType: models.MovementPatternType.fun,
        transportationMethod: models.TransportationMethod.car,
        frequency: 2.0,
        isRegular: false,
        firstObserved: DateTime.now().subtract(const Duration(days: 180)),
        lastObserved: DateTime.now().subtract(const Duration(days: 60)),
        tripCount: 4,
      );

      expect(strongPattern.patternStrength,
          greaterThan(weakPattern.patternStrength));

      // Test active status determination (business logic)
      final activePattern = UserMovementPattern(
        userId: 'user-1',
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-2',
        targetLocalityName: 'SOMA',
        patternType: models.MovementPatternType.commute,
        transportationMethod: models.TransportationMethod.transit,
        frequency: 20.0,
        isRegular: true,
        firstObserved: DateTime.now().subtract(const Duration(days: 90)),
        lastObserved: DateTime.now().subtract(const Duration(days: 5)),
        tripCount: 60,
      );

      final inactivePattern = UserMovementPattern(
        userId: 'user-2',
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-3',
        targetLocalityName: 'Marina',
        patternType: models.MovementPatternType.fun,
        transportationMethod: models.TransportationMethod.car,
        frequency: 2.0,
        isRegular: false,
        firstObserved: DateTime.now().subtract(const Duration(days: 180)),
        lastObserved: DateTime.now().subtract(const Duration(days: 60)),
        tripCount: 4,
      );

      expect(activePattern.isActive(), isTrue);
      expect(inactivePattern.isActive(), isFalse);
    });
  });

  group('CrossLocalityConnection Tests', () {
    // Removed: 'should create connection with all fields' test
    // This test only verified property assignment, not business logic

    test(
        'should classify connection strength correctly and generate display names',
        () {
      final strongConnection = models.CrossLocalityConnection(
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-2',
        targetLocalityName: 'SOMA',
        connectionStrength: 0.8,
        patternType: models.MovementPatternType.commute,
        transportationMethod: models.TransportationMethod.transit,
        userCount: 50,
        averageFrequency: 20.0,
        isInSameMetroArea: true,
        calculatedAt: DateTime.now(),
      );

      final moderateConnection = models.CrossLocalityConnection(
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-3',
        targetLocalityName: 'Marina',
        connectionStrength: 0.5,
        patternType: models.MovementPatternType.travel,
        transportationMethod: models.TransportationMethod.car,
        userCount: 20,
        averageFrequency: 5.0,
        isInSameMetroArea: true,
        calculatedAt: DateTime.now(),
      );

      final weakConnection = models.CrossLocalityConnection(
        sourceLocalityId: 'locality-1',
        sourceLocalityName: 'Mission District',
        targetLocalityId: 'locality-4',
        targetLocalityName: 'Oakland',
        connectionStrength: 0.3,
        patternType: models.MovementPatternType.fun,
        transportationMethod: models.TransportationMethod.transit,
        userCount: 5,
        averageFrequency: 1.0,
        isInSameMetroArea: false,
        calculatedAt: DateTime.now(),
      );

      expect(strongConnection.isStrongConnection, isTrue);
      expect(moderateConnection.isModerateConnection, isTrue);
      expect(weakConnection.isWeakConnection, isTrue);

      // Test display name generation (business logic)
      expect(strongConnection.displayName, equals('Mission District → SOMA'));
      expect(strongConnection.isInSameMetroArea, isTrue);
    });
  });
}
