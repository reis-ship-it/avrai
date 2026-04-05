import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_feature_extractor.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_prediction_enhancer.dart';
import 'package:avrai_runtime_os/ml/training/quantum_prediction_training_pipeline.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_satisfaction_feature_extractor.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_satisfaction_enhancer.dart';
import 'package:avrai_runtime_os/services/quantum/decoherence_tracking_service.dart';
import 'package:avrai_runtime_os/data/datasources/local/decoherence_pattern_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/decoherence_pattern_getstorage_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/decoherence_pattern_repository_impl.dart';
import 'package:avrai_runtime_os/domain/repositories/decoherence_pattern_repository.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_quantum_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/quantum/real_time_user_calling_service.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_experience_calculator.dart';
import 'package:avrai_runtime_os/services/quantum/meaningful_connection_metrics_service.dart';
import 'package:avrai_runtime_os/services/quantum/user_journey_tracking_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_outcome_learning_service.dart';
import 'package:avrai_runtime_os/services/quantum/ideal_state_learning_service.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_integration_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_metrics_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_connectivity_listener.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_production_service.dart';
import 'package:avrai_runtime_os/services/quantum/user_event_prediction_matching_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/matching/group_matching_service.dart';
import 'package:avrai_runtime_os/controllers/group_matching_controller.dart';
import 'package:avrai_runtime_os/services/matching/group_formation_service.dart';
import 'package:avrai_runtime_os/services/quantum/third_party_data_privacy_service.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/quantum/prediction_api_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';

/// Quantum Services Registration Module
///
/// Registers all quantum-related services.
/// This includes:
/// - Decoherence tracking services
/// - Quantum vibe engine
/// - Quantum entanglement services
/// - Quantum prediction and satisfaction enhancement
/// - Quantum matching controller
/// - Reservation quantum services
Future<void> registerQuantumServices(GetIt sl) async {
  const logger =
      AppLogger(defaultTag: 'DI-Quantum', minimumLevel: LogLevel.debug);
  logger.debug('⚛️ [DI-Quantum] Registering quantum services...');

  // Quantum Enhancement Implementation Plan - Phase 2.1: Decoherence Tracking
  // Register Decoherence Pattern Repository
  sl.registerLazySingleton<DecoherencePatternLocalDataSource>(
    () => DecoherencePatternGetStorageDataSource(),
  );
  sl.registerLazySingleton<DecoherencePatternRepository>(
    () => DecoherencePatternRepositoryImpl(
      localDataSource: sl<DecoherencePatternLocalDataSource>(),
    ),
  );

  // Register Decoherence Tracking Service
  sl.registerLazySingleton<DecoherenceTrackingService>(
    () => DecoherenceTrackingService(
      repository: sl<DecoherencePatternRepository>(),
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Quantum Vibe Engine (Phase 4: Quantum Analysis)
  // Enhanced with Decoherence Tracking (Phase 2.1)
  sl.registerLazySingleton(() => QuantumVibeEngine(
        decoherenceTracking: sl<DecoherenceTrackingService>(),
        featureFlags: sl<FeatureFlagService>(),
      ));

  // Phase 19: Multi-Entity Quantum Entanglement Matching System
  // Section 19.1: N-Way Quantum Entanglement Framework
  // Enhanced with String/Fabric/Worldsheet Integration + AI2AI Mesh + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton<QuantumEntanglementService>(
    () => QuantumEntanglementService(
      atomicClock: sl<AtomicClockService>(),
      knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
          ? sl<IntegratedKnotRecommendationEngine>()
          : null,
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      quantumStateKnotService: sl.isRegistered<QuantumStateKnotService>()
          ? sl<QuantumStateKnotService>()
          : null,
      stringService: sl.isRegistered<KnotEvolutionStringService>()
          ? sl<KnotEvolutionStringService>()
          : null,
      fabricService:
          sl.isRegistered<KnotFabricService>() ? sl<KnotFabricService>() : null,
      worldsheetService: sl.isRegistered<KnotWorldsheetService>()
          ? sl<KnotWorldsheetService>()
          : null,
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
    ),
  );

  // Section 19.2: Dynamic Entanglement Coefficient Optimization
  // Enhanced with AI2AI Mesh + Signal Protocol (Phase 19 Integration Enhancement for locality AI learning)
  sl.registerLazySingleton<EntanglementCoefficientOptimizer>(
    () => EntanglementCoefficientOptimizer(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
      // Knot services are accessed through entanglementService.calculateKnotCompatibilityBonus()
    ),
  );

  // Section 19.3: Location and Timing Quantum States
  sl.registerLazySingleton<LocationTimingQuantumStateService>(
    () => LocationTimingQuantumStateService(
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Section 19.12: Dimensionality Reduction for Scalability
  // Enhanced with knot/string/fabric/worldsheet reduction and vectorless schema caching
  sl.registerLazySingleton<DimensionalityReductionService>(
    () => DimensionalityReductionService(
      supabaseService:
          sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
    ),
  );

  // Section 19.4: Dynamic Real-Time User Calling System
  // Section 19.6: Meaningful Experience Calculator
  sl.registerLazySingleton<MeaningfulExperienceCalculator>(
    () => MeaningfulExperienceCalculator(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      locationTimingService: sl<LocationTimingQuantumStateService>(),
    ),
  );

  // Section 19.8: User Journey Tracking Service (registered before RealTimeUserCallingService)
  sl.registerLazySingleton<UserJourneyTrackingService>(
    () => UserJourneyTrackingService(
      atomicClock: sl<AtomicClockService>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      agentIdService: sl<AgentIdService>(),
      supabaseService: sl<SupabaseService>(),
    ),
  );

  // Section 19.4: Dynamic Real-Time User Calling System
  // Enhanced with AI2AI Mesh + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton<RealTimeUserCallingService>(
    () => RealTimeUserCallingService(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      locationTimingService: sl<LocationTimingQuantumStateService>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      agentIdService: sl<AgentIdService>(),
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      supabaseService: sl<SupabaseService>(),
      preferencesProfileService: sl<PreferencesProfileService>(),
      personalityKnotService: sl<PersonalityKnotService>(),
      meaningfulExperienceCalculator: sl<MeaningfulExperienceCalculator>(),
      journeyTrackingService: sl<UserJourneyTrackingService>(),
      stringService: sl<KnotEvolutionStringService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
      fabricService: sl<KnotFabricService>(),
      knotStorage: sl<KnotStorageService>(),
      conversationOrchestrationLane: sl.isRegistered<ConversationOrchestrationLane>()
          ? sl<ConversationOrchestrationLane>()
          : null,
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
    ),
  );

  // Section 19.7: Meaningful Connection Metrics Service
  sl.registerLazySingleton<MeaningfulConnectionMetricsService>(
    () => MeaningfulConnectionMetricsService(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      agentIdService: sl<AgentIdService>(),
      supabaseService: sl<SupabaseService>(),
      stringService: sl<KnotEvolutionStringService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
      fabricService: sl<KnotFabricService>(),
      knotStorage: sl<KnotStorageService>(),
    ),
  );

  // Section 19.9: Quantum Outcome-Based Learning Service
  sl.registerLazySingleton<QuantumOutcomeLearningService>(
    () => QuantumOutcomeLearningService(
      atomicClock: sl<AtomicClockService>(),
      successAnalysisService: sl<EventSuccessAnalysisService>(),
      meaningfulMetricsService: sl<MeaningfulConnectionMetricsService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      locationTimingService: sl<LocationTimingQuantumStateService>(),
      stringService: sl<KnotEvolutionStringService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
      knotStorage: sl<KnotStorageService>(),
      agentIdService: sl<AgentIdService>(),
    ),
  );

  // Section 19.10: Ideal State Learning Service
  sl.registerLazySingleton<IdealStateLearningService>(
    () => IdealStateLearningService(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      outcomeLearningService: sl<QuantumOutcomeLearningService>(),
    ),
  );

  // Section 19.16: AI2AI Integration with Mesh Networking
  // Quantum Matching AI Learning Service (registered before services that use it)
  // Section 19.16: AI2AI Integration (QuantumMatchingAILearningService)
  // Enhanced with String/Fabric/Worldsheet + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton<QuantumMatchingAILearningService>(
    () => QuantumMatchingAILearningService(
      atomicClock: sl<AtomicClockService>(),
      personalityLearning: sl<PersonalityLearning>(),
      agentIdService: sl<AgentIdService>(),
      storageService: sl<StorageService>(),
      // Optional: VibeConnectionOrchestrator and AdaptiveMeshNetworkingService
      // These are registered in injection_container_ai.dart but may not be available
      // The service handles null gracefully
      orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
          ? sl<VibeConnectionOrchestrator>()
          : null,
      meshService: sl.isRegistered<AdaptiveMeshNetworkingService>()
          ? sl<AdaptiveMeshNetworkingService>()
          : null,
      stringService: sl.isRegistered<KnotEvolutionStringService>()
          ? sl<KnotEvolutionStringService>()
          : null,
      fabricService:
          sl.isRegistered<KnotFabricService>() ? sl<KnotFabricService>() : null,
      worldsheetService: sl.isRegistered<KnotWorldsheetService>()
          ? sl<KnotWorldsheetService>()
          : null,
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
    ),
  );

  // Section 19.5: Quantum Matching Controller
  // Section 19.5: Quantum Matching Controller
  // Enhanced with String/Fabric/Worldsheet + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton<QuantumMatchingController>(
    () => QuantumMatchingController(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      locationTimingService: sl<LocationTimingQuantumStateService>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      agentIdService: sl<AgentIdService>(),
      preferencesProfileService: sl.isRegistered<PreferencesProfileService>()
          ? sl<PreferencesProfileService>()
          : null,
      knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
          ? sl<IntegratedKnotRecommendationEngine>()
          : null,
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      meaningfulConnectionMetricsService:
          sl.isRegistered<MeaningfulConnectionMetricsService>()
              ? sl<MeaningfulConnectionMetricsService>()
              : null,
      aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
          ? sl<QuantumMatchingAILearningService>()
          : null,
      connectivityService: sl.isRegistered<EnhancedConnectivityService>()
          ? sl<EnhancedConnectivityService>()
          : null,
      stringService: sl.isRegistered<KnotEvolutionStringService>()
          ? sl<KnotEvolutionStringService>()
          : null,
      fabricService:
          sl.isRegistered<KnotFabricService>() ? sl<KnotFabricService>() : null,
      worldsheetService: sl.isRegistered<KnotWorldsheetService>()
          ? sl<KnotWorldsheetService>()
          : null,
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
    ),
  );

  // Section 19.15: Integration with Existing Matching Systems
  // Enhanced with String/Fabric/Worldsheet + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton(() => QuantumMatchingIntegrationService(
        quantumController: sl<QuantumMatchingController>(),
        featureFlags: sl<FeatureFlagService>(),
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        stringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        fabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        worldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        encryptionService: sl.isRegistered<HybridEncryptionService>()
            ? sl<HybridEncryptionService>()
            : null,
      ));

  // Quantum Matching Metrics Service (for A/B testing)
  sl.registerLazySingleton(() => QuantumMatchingMetricsService(
        atomicClock: sl<AtomicClockService>(),
      ));

  // Section 19.16: Connectivity Listener (monitors connectivity and syncs offline matches)
  sl.registerLazySingleton<QuantumMatchingConnectivityListener>(
    () => QuantumMatchingConnectivityListener(
      connectivityService: sl.isRegistered<EnhancedConnectivityService>()
          ? sl<EnhancedConnectivityService>()
          : throw StateError(
              'EnhancedConnectivityService must be registered before QuantumMatchingConnectivityListener'),
      aiLearningService: sl<QuantumMatchingAILearningService>(),
    ),
  );

  // Section 19.17: Production Enhancements
  // Quantum Matching Production Service
  sl.registerLazySingleton(() => QuantumMatchingProductionService(
        atomicClock: sl<AtomicClockService>(),
        storageService: sl<StorageService>(),
      ));

  // Quantum Enhancement Implementation Plan - Phase 3.1: Quantum Prediction Features
  // Register Quantum Feature Extractor
  sl.registerLazySingleton<QuantumFeatureExtractor>(
    () => QuantumFeatureExtractor(
      decoherenceTracking: sl<DecoherenceTrackingService>(),
    ),
  );

  // Register Quantum Prediction Training Pipeline
  sl.registerLazySingleton<QuantumPredictionTrainingPipeline>(
    () => QuantumPredictionTrainingPipeline(),
  );

  // Register Quantum Prediction Enhancer
  sl.registerLazySingleton<QuantumPredictionEnhancer>(
    () => QuantumPredictionEnhancer(
      featureExtractor: sl<QuantumFeatureExtractor>(),
      trainingPipeline: sl<QuantumPredictionTrainingPipeline>(),
      featureFlags: sl<FeatureFlagService>(),
    ),
  );

  // Quantum Enhancement Implementation Plan - Phase 4.1: Quantum Satisfaction Enhancement
  // Register Quantum Satisfaction Feature Extractor
  sl.registerLazySingleton<QuantumSatisfactionFeatureExtractor>(
    () => QuantumSatisfactionFeatureExtractor(
      decoherenceTracking: sl<DecoherenceTrackingService>(),
    ),
  );

  // Register Quantum Satisfaction Enhancer
  sl.registerLazySingleton<QuantumSatisfactionEnhancer>(
    () => QuantumSatisfactionEnhancer(
      featureExtractor: sl<QuantumSatisfactionFeatureExtractor>(),
      featureFlags: sl<FeatureFlagService>(),
    ),
  );

  // Phase 15: Reservation System with Quantum Integration
  // Phase 15 Section 15.1: Foundation - Quantum Integration
  sl.registerLazySingleton(() => ReservationQuantumService(
        atomicClock: sl<AtomicClockService>(),
        quantumVibeEngine: sl<QuantumVibeEngine>(),
        vibeAnalyzer: sl<UserVibeAnalyzer>(),
        personalityLearning: sl<PersonalityLearning>(),
        locationTimingService: sl<LocationTimingQuantumStateService>(),
        entanglementService:
            sl<QuantumEntanglementService>(), // Optional, graceful degradation
      ));

  // Section 19.11: User Event Prediction Matching Service (renamed from HypotheticalMatchingService)
  // Enhanced with knot evolution strings, fabrics, worldsheets, and personalized fabric suitability
  // Section 19.11: Hypothetical Matching System (UserEventPredictionMatchingService)
  // Enhanced with AI2AI Mesh + Signal Protocol (Phase 19 Integration Enhancement)
  sl.registerLazySingleton<UserEventPredictionMatchingService>(
    () => UserEventPredictionMatchingService(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      eventService: sl<ExpertiseEventService>(),
      personalityLearning: sl<PersonalityLearning>(),
      stringService: sl<KnotEvolutionStringService>(),
      fabricService: sl<KnotFabricService>(),
      knotStorage: sl<KnotStorageService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
      futureCompatService: sl<FutureCompatibilityPredictionService>(),
      agentIdService: sl<AgentIdService>(),
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
    ),
  );

  // Phase 19.18: Quantum Group Matching System
  // Section GM.1: Core Group Matching Service
  sl.registerLazySingleton<GroupMatchingService>(
    () => GroupMatchingService(
      atomicClock: sl<AtomicClockService>(),
      entanglementService: sl<QuantumEntanglementService>(),
      locationTimingService: sl<LocationTimingQuantumStateService>(),
      stringService: sl<KnotEvolutionStringService>(),
      fabricService: sl<KnotFabricService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
      knotStorage: sl<KnotStorageService>(),
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      agentIdService: sl<AgentIdService>(),
      supabaseService: sl<SupabaseService>(),
    ),
  );

  // Section GM.3: Group Matching Controller
  sl.registerLazySingleton<GroupMatchingController>(
    () => GroupMatchingController(
      groupMatchingService: sl<GroupMatchingService>(),
      groupFormationService: sl<GroupFormationService>(),
      atomicClock: sl<AtomicClockService>(),
      agentIdService: sl<AgentIdService>(),
      personalityLearning: sl<PersonalityLearning>(),
      aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
          ? sl<QuantumMatchingAILearningService>()
          : null,
      connectivityService: sl.isRegistered<EnhancedConnectivityService>()
          ? sl<EnhancedConnectivityService>()
          : null,
    ),
  );

  // Section 19.13: Privacy-Protected Third-Party Data API
  // Enhanced with knot/string/fabric/worldsheet anonymization, Signal Protocol, and AI2AI mesh
  sl.registerLazySingleton<ThirdPartyDataPrivacyService>(
    () => ThirdPartyDataPrivacyService(
      atomicClock: sl<AtomicClockService>(),
      agentIdService: sl<AgentIdService>(),
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
      ai2aiExchangeSubmissionLane:
          sl.isRegistered<Ai2AiExchangeSubmissionLane>()
              ? sl<Ai2AiExchangeSubmissionLane>()
              : null,
      orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
          ? sl<VibeConnectionOrchestrator>()
          : null,
      knotStringService: sl.isRegistered<KnotEvolutionStringService>()
          ? sl<KnotEvolutionStringService>()
          : null,
    ),
  );

  // Section 19.14: Prediction API for Business Intelligence
  // Enhanced with real service calls, knot/string/fabric/worldsheet integration, Signal Protocol, and AI2AI mesh
  sl.registerLazySingleton<PredictionAPIService>(
    () => PredictionAPIService(
      atomicClock: sl<AtomicClockService>(),
      metricsService: sl<MeaningfulConnectionMetricsService>(),
      journeyService: sl<UserJourneyTrackingService>(),
      hypotheticalService: sl<UserEventPredictionMatchingService>(),
      privacyService: sl<ThirdPartyDataPrivacyService>(),
      agentIdService: sl<AgentIdService>(),
      eventService: sl<ExpertiseEventService>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      stringService: sl.isRegistered<KnotEvolutionStringService>()
          ? sl<KnotEvolutionStringService>()
          : null,
      fabricService:
          sl.isRegistered<KnotFabricService>() ? sl<KnotFabricService>() : null,
      worldsheetService: sl.isRegistered<KnotWorldsheetService>()
          ? sl<KnotWorldsheetService>()
          : null,
      encryptionService: sl.isRegistered<HybridEncryptionService>()
          ? sl<HybridEncryptionService>()
          : null,
      // Phase 1.5E: Markov engagement predictor — bridge to Phase 5
      engagementPredictor: sl.isRegistered<EngagementPhasePredictor>()
          ? sl<EngagementPhasePredictor>()
          : null,
    ),
  );

  logger.debug('✅ [DI-Quantum] Quantum services registered');
}
