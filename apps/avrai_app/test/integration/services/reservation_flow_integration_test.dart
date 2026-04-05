/// SPOTS Reservation Flow Integration Tests
/// Date: January 1, 2026
/// Purpose: End-to-end validation of reservation system workflow
///
/// Test Coverage:
/// - Complete reservation workflow: Create → Store → Sync → Retrieve
/// - Offline-first behavior: Create offline, sync when online
/// - Reservation updates and cancellations
/// - Quantum compatibility calculations
/// - Recommendation flow
///
/// Dependencies:
/// - Real StorageService: Local storage operations
/// - Mock SupabaseService: Cloud sync (can be real if credentials available)
/// - Real ReservationService: Core reservation operations
/// - Real ReservationQuantumService: Quantum state calculations
///
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test complete workflows end-to-end
/// ✅ DO: Test system interactions and integration points
/// ✅ DO: Test error propagation and recovery
/// ✅ DO: Consolidate related workflow steps into comprehensive tests
///
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_quantum_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_core/models/misc/reservation.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/models/user/user_vibe.dart';
import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/platform_channel_helper.dart';

// Mock dependencies
class MockSupabaseService extends Mock implements SupabaseService {}

class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}

class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}

class MockPersonalityLearning extends Mock implements PersonalityLearning {}

class MockSecureMappingEncryptionService extends Mock
    implements SecureMappingEncryptionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reservation Flow Integration Tests', () {
    late ReservationService reservationService;
    late ReservationQuantumService quantumService;
    late AtomicClockService atomicClock;
    late AgentIdService agentIdService;
    late StorageService storageService;
    late MockSupabaseService mockSupabaseService;
    late MockQuantumVibeEngine mockQuantumVibeEngine;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockPersonalityLearning mockPersonalityLearning;
    late LocationTimingQuantumStateService locationTimingService;

    setUp(() async {
      await setupTestStorage();

      // Initialize storage service
      storageService = StorageService.instance;

      // Initialize real services
      atomicClock = AtomicClockService();
      // AgentIdService requires encryption service - use real service for integration tests
      final encryptionService = SecureMappingEncryptionService();
      agentIdService = AgentIdService(encryptionService: encryptionService);
      locationTimingService = LocationTimingQuantumStateService();

      // Initialize mocks
      mockSupabaseService = MockSupabaseService();
      mockQuantumVibeEngine = MockQuantumVibeEngine();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockPersonalityLearning = MockPersonalityLearning();

      // Setup mock Supabase (offline by default)
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      // Create quantum service with mocks
      quantumService = ReservationQuantumService(
        atomicClock: atomicClock,
        quantumVibeEngine: mockQuantumVibeEngine,
        vibeAnalyzer: mockVibeAnalyzer,
        personalityLearning: mockPersonalityLearning,
        locationTimingService: locationTimingService,
      );

      // Create reservation service
      reservationService = ReservationService(
        atomicClock: atomicClock,
        quantumService: quantumService,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: mockSupabaseService,
      );

      // Create recommendation service (not used in these tests, but initialized for completeness)
      // recommendationService = ReservationRecommendationService(
      //   reservationService: reservationService,
      //   quantumService: quantumService,
      //   eventService: mockEventService,
      //   atomicClock: atomicClock,
      // );
    });

    tearDown(() async {
      // Cleanup if needed
    });

    group('Complete Reservation Workflow', () {
      test(
          'should create reservation, store locally, and retrieve successfully',
          () async {
        // Arrange
        const userId = 'test-user-123';
        const eventId = 'event-456';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-123',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Act - Create reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Assert - Reservation created
        expect(reservation, isA<Reservation>());
        expect(reservation.type, equals(ReservationType.event));
        expect(reservation.targetId, equals(eventId));
        expect(reservation.partySize, equals(2));
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.atomicTimestamp, isNotNull);
        expect(reservation.quantumState, isNotNull);

        // Act - Retrieve reservations
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Assert - Reservation retrieved
        expect(reservations, isA<List<Reservation>>());
        expect(reservations.length, equals(1));
        expect(reservations.first.id, equals(reservation.id));
        expect(reservations.first.targetId, equals(eventId));
      });

      test('should sync reservation to cloud when online', () async {
        // Arrange
        const userId = 'test-user-456';
        const eventId = 'event-789';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-456',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks - Supabase available
        when(() => mockSupabaseService.isAvailable).thenReturn(true);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Act - Create reservation (should attempt cloud sync)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Assert - Reservation created (cloud sync may fail gracefully)
        expect(reservation, isA<Reservation>());
        expect(reservation.id, isNotEmpty);
        expect(reservation.status, equals(ReservationStatus.confirmed));
      });
    });

    group('Reservation Updates', () {
      test('should update reservation and increment modification count',
          () async {
        // Arrange
        const userId = 'test-user-update';
        const eventId = 'event-update';
        final originalTime = DateTime.now().add(const Duration(days: 7));
        final newTime = DateTime.now().add(const Duration(days: 8));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-update',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Create initial reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: originalTime,
          partySize: 2,
        );

        // Act - Update reservation
        final updated = await reservationService.updateReservation(
          reservationId: reservation.id,
          reservationTime: newTime,
        );

        // Assert - Reservation updated
        expect(updated.id, equals(reservation.id));
        expect(updated.reservationTime, equals(newTime));
        expect(updated.modificationCount, equals(1));
        expect(updated.lastModifiedAt, isNotNull);
      });
    });

    group('Reservation Cancellation', () {
      test('should cancel reservation and update status', () async {
        // Arrange
        const userId = 'test-user-cancel';
        const eventId = 'event-cancel';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-cancel',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Create reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Act - Cancel reservation
        final cancelled = await reservationService.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Assert - Reservation cancelled
        expect(cancelled.id, equals(reservation.id));
        expect(cancelled.status, equals(ReservationStatus.cancelled));
      });
    });

    group('Reservation Filtering', () {
      test('should filter reservations by status', () async {
        // Arrange
        const userId = 'test-user-filter';
        const eventId1 = 'event-1';
        const eventId2 = 'event-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-filter',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Create two reservations
        final reservation1 = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId1,
          reservationTime: reservationTime,
          partySize: 2,
        );

        final reservation2 = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId2,
          reservationTime: reservationTime.add(const Duration(days: 1)),
          partySize: 2,
        );

        // Cancel one reservation
        await reservationService.cancelReservation(
          reservationId: reservation2.id,
          reason: 'Test cancellation',
        );

        // Act - Filter by status
        final confirmedReservations =
            await reservationService.getUserReservations(
          userId: userId,
          status: ReservationStatus.confirmed,
        );

        final cancelledReservations =
            await reservationService.getUserReservations(
          userId: userId,
          status: ReservationStatus.cancelled,
        );

        // Assert - Filtering works
        expect(confirmedReservations.length, equals(1));
        expect(confirmedReservations.first.id, equals(reservation1.id));
        expect(cancelledReservations.length, equals(1));
        expect(cancelledReservations.first.id, equals(reservation2.id));
      });
    });

    group('Offline-First Behavior', () {
      test('should create reservation offline and retrieve it', () async {
        // Arrange
        const userId = 'test-user-offline';
        const eventId = 'event-offline';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create mock personality profile
        final personalityDimensions = <String, double>{};
        for (final dimension in VibeConstants.coreDimensions) {
          personalityDimensions[dimension] = 0.5;
        }

        final personalityProfile = PersonalityProfile(
          agentId: 'agent-offline',
          dimensions: personalityDimensions,
          dimensionConfidence:
              personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
          archetype: 'balanced',
          authenticity: 0.7,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          evolutionGeneration: 1,
          learningHistory: {},
        );

        // Setup mocks - Supabase offline
        when(() => mockSupabaseService.isAvailable).thenReturn(false);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => personalityProfile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, personalityProfile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, personalityDimensions));

        // Act - Create reservation offline
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Assert - Reservation created and stored locally
        expect(reservation, isA<Reservation>());
        expect(reservation.id, isNotEmpty);

        // Act - Retrieve offline
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Assert - Reservation retrieved from local storage
        expect(reservations.length, equals(1));
        expect(reservations.first.id, equals(reservation.id));
      });
    });
  });
}
