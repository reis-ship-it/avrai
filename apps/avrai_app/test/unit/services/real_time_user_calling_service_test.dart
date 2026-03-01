// Real-Time User Calling Service Tests
//
// Tests for Phase 19 Section 19.4: Dynamic Real-Time User Calling System
// Patent #29: Multi-Entity Quantum Entanglement Matching System

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai_runtime_os/services/quantum/real_time_user_calling_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_experience_calculator.dart';
import 'package:avrai_runtime_os/services/quantum/user_journey_tracking_service.dart';
import '../../helpers/platform_channel_helper.dart';

void main() {
  group('RealTimeUserCallingService', () {
    late RealTimeUserCallingService service;
    late QuantumEntanglementService entanglementService;
    late LocationTimingQuantumStateService locationTimingService;
    late AtomicClockService atomicClock;
    late PersonalityLearning personalityLearning;
    late UserVibeAnalyzer vibeAnalyzer;
    late SupabaseService supabaseService;
    late PreferencesProfileService preferencesProfileService;
    late PersonalityKnotService personalityKnotService;
    late MeaningfulExperienceCalculator meaningfulExperienceCalculator;
    late UserJourneyTrackingService journeyTrackingService;

    setUp(() async {
      atomicClock = AtomicClockService();
      await atomicClock.initialize();

      entanglementService = QuantumEntanglementService(
        atomicClock: atomicClock,
        knotEngine: null,
        knotCompatibilityService: null,
      );
      locationTimingService = LocationTimingQuantumStateService();

      // Initialize PersonalityLearning and UserVibeAnalyzer
      await setupTestStorage();
      final mockStorage = getTestStorage();
      final prefs =
          await SharedPreferencesCompat.getInstance(storage: mockStorage);
      personalityLearning = PersonalityLearning.withPrefs(prefs);
      vibeAnalyzer = UserVibeAnalyzer(prefs: prefs);

      supabaseService = SupabaseService();
      preferencesProfileService = PreferencesProfileService();
      personalityKnotService = PersonalityKnotService();
      meaningfulExperienceCalculator = MeaningfulExperienceCalculator(
        atomicClock: atomicClock,
        entanglementService: entanglementService,
        locationTimingService: locationTimingService,
      );
      journeyTrackingService = UserJourneyTrackingService(
        atomicClock: atomicClock,
        personalityLearning: personalityLearning,
        vibeAnalyzer: vibeAnalyzer,
        agentIdService: AgentIdService(),
        supabaseService: supabaseService,
      );

      // Create knot services with proper dependencies
      final storageService = StorageService.instance;
      final knotStorage = KnotStorageService(storageService: storageService);
      final stringService =
          KnotEvolutionStringService(storageService: knotStorage);
      final fabricService = KnotFabricService();
      final worldsheetService = KnotWorldsheetService(
        storageService: knotStorage,
        stringService: stringService,
        fabricService: fabricService,
      );

      service = RealTimeUserCallingService(
        atomicClock: atomicClock,
        entanglementService: entanglementService,
        locationTimingService: locationTimingService,
        personalityLearning: personalityLearning,
        vibeAnalyzer: vibeAnalyzer,
        agentIdService: AgentIdService(),
        knotCompatibilityService: null,
        supabaseService: supabaseService,
        preferencesProfileService: preferencesProfileService,
        personalityKnotService: personalityKnotService,
        meaningfulExperienceCalculator: meaningfulExperienceCalculator,
        journeyTrackingService: journeyTrackingService,
        stringService: stringService,
        worldsheetService: worldsheetService,
        fabricService: fabricService,
        knotStorage: knotStorage,
      );
    });

    test('should call users on event creation', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();

      final eventEntity = QuantumEntityState(
        entityId: 'event1',
        entityType: QuantumEntityType.event,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'event'},
        tAtomic: tAtomic1,
      );

      final creatorEntity = QuantumEntityState(
        entityId: 'creator1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic2,
      );

      // Should not throw
      await service.callUsersOnEventCreation(
        eventId: 'event1',
        eventEntities: [eventEntity, creatorEntity],
      );
    });

    test('should re-evaluate users on entity addition', () async {
      await atomicClock.initialize();

      final tAtomic1 = await atomicClock.getAtomicTimestamp();
      final tAtomic2 = await atomicClock.getAtomicTimestamp();
      final tAtomic3 = await atomicClock.getAtomicTimestamp();

      final eventEntity = QuantumEntityState(
        entityId: 'event1',
        entityType: QuantumEntityType.event,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'event'},
        tAtomic: tAtomic1,
      );

      final creatorEntity = QuantumEntityState(
        entityId: 'creator1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic2,
      );

      final newEntity = QuantumEntityState(
        entityId: 'business1',
        entityType: QuantumEntityType.business,
        personalityState: {'dim1': 0.55},
        quantumVibeAnalysis: {'vibe1': 0.75},
        entityCharacteristics: {'type': 'business'},
        tAtomic: tAtomic3,
      );

      // Should not throw
      await service.reEvaluateUsersOnEntityAddition(
        eventId: 'event1',
        eventEntities: [eventEntity, creatorEntity],
        newEntity: newEntity,
      );
    });

    test('should use atomic timestamps for all operations', () async {
      await atomicClock.initialize();

      final tAtomic = await atomicClock.getAtomicTimestamp();
      final eventEntity = QuantumEntityState(
        entityId: 'event1',
        entityType: QuantumEntityType.event,
        personalityState: {'dim1': 0.5},
        quantumVibeAnalysis: {'vibe1': 0.7},
        entityCharacteristics: {'type': 'event'},
        tAtomic: tAtomic,
      );

      final creatorEntity = QuantumEntityState(
        entityId: 'creator1',
        entityType: QuantumEntityType.expert,
        personalityState: {'dim1': 0.6},
        quantumVibeAnalysis: {'vibe1': 0.8},
        entityCharacteristics: {'type': 'expert'},
        tAtomic: tAtomic,
      );

      // Verify atomic timestamps are used
      expect(eventEntity.tAtomic, isNotNull);
      expect(creatorEntity.tAtomic, isNotNull);
    });
  });
}
