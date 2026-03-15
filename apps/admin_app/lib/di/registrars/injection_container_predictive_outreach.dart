// ignore: dangling_library_doc_comments
/// Predictive Outreach Services Dependency Injection
///
/// Registers all predictive proactive outreach services.
/// Part of Predictive Proactive Outreach System

import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_expert_outreach_service.dart';
import 'package:avrai_runtime_os/services/business/business_business_outreach_service.dart';
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/expertise/expert_recommendations_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/future_compatibility_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/temporal_quantum_compatibility_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/fabric_stability_prediction_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/evolution_pattern_analysis_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/ai2ai_outreach_communication_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/community_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/group_formation_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/event_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/business_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/club_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/expert_proactive_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/list_suggestion_outreach_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/outreach_queue_processor.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/batch_outreach_processor.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/background_outreach_scheduler.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/silent_notification_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/outreach_history_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/outreach_preferences_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/compatibility_cache_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/predictive_signals_cache_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/batch_processing_optimization_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';

/// Register all predictive outreach services
Future<void> registerPredictiveOutreachServices(GetIt sl) async {
  const logger = AppLogger(
    defaultTag: 'DI-PredictiveOutreach',
    minimumLevel: LogLevel.debug,
  );
  logger.debug(
      '📦 [DI-PredictiveOutreach] Registering predictive outreach services...');

  // Phase 1: Core Predictive Services
  sl.registerLazySingleton(() => FutureCompatibilityPredictionService(
        stringService: sl<KnotEvolutionStringService>(),
        knotStorage: sl<KnotStorageService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] FutureCompatibilityPredictionService registered');

  sl.registerLazySingleton(() => TemporalQuantumCompatibilityService(
        entanglementService: sl<QuantumEntanglementService>(),
        stringService: sl<KnotEvolutionStringService>(),
        personalityLearning: sl<PersonalityLearning>(),
        atomicClock: sl<AtomicClockService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] TemporalQuantumCompatibilityService registered');

  sl.registerLazySingleton(() => FabricStabilityPredictionService(
        fabricService: sl<KnotFabricService>(),
        worldsheetService: sl<KnotWorldsheetService>(),
        knotStorage: sl<KnotStorageService>(),
        stringService: sl<KnotEvolutionStringService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] FabricStabilityPredictionService registered');

  sl.registerLazySingleton(() => EvolutionPatternAnalysisService(
        stringService: sl<KnotEvolutionStringService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] EvolutionPatternAnalysisService registered');

  // Phase 3: AI2AI Communication Service
  sl.registerLazySingleton(() => AI2AIOutreachCommunicationService(
        conversationOrchestrationLane: sl<ConversationOrchestrationLane>(),
        hybridEncryption: sl.isRegistered<HybridEncryptionService>()
            ? sl<HybridEncryptionService>()
            : null,
        signalProtocol: sl.isRegistered<SignalProtocolEncryptionService>()
            ? sl<SignalProtocolEncryptionService>()
            : null,
        atomicClock: sl<AtomicClockService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] AI2AIOutreachCommunicationService registered');

  // Phase 2: Outreach Services
  sl.registerLazySingleton(() => CommunityProactiveOutreachService(
        communityService: sl<CommunityService>(),
        fabricService: sl<KnotFabricService>(),
        worldsheetService: sl<KnotWorldsheetService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        fabricStabilityService: sl<FabricStabilityPredictionService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] CommunityProactiveOutreachService registered');

  sl.registerLazySingleton(() => GroupFormationOutreachService(
        knotCommunityService: sl<KnotCommunityService>(),
        fabricService: sl<KnotFabricService>(),
        worldsheetService: sl<KnotWorldsheetService>(),
        knotOrchestrator: sl<KnotOrchestratorService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        fabricStabilityService: sl<FabricStabilityPredictionService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] GroupFormationOutreachService registered');

  sl.registerLazySingleton(() => EventProactiveOutreachService(
        eventService: sl<ExpertiseEventService>(),
        matchingService: sl<EventMatchingService>(),
        recommendationService: sl<EventRecommendationService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] EventProactiveOutreachService registered');

  sl.registerLazySingleton(() => BusinessProactiveOutreachService(
        businessService: sl<BusinessAccountService>(),
        businessExpertOutreach: sl<BusinessExpertOutreachService>(),
        businessBusinessOutreach: sl<BusinessBusinessOutreachService>(),
        eventService: sl<ExpertiseEventService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] BusinessProactiveOutreachService registered');

  sl.registerLazySingleton(() => ClubProactiveOutreachService(
        clubService: sl<ClubService>(),
        communityService: sl<CommunityService>(),
        eventService: sl<ExpertiseEventService>(),
        fabricService: sl<KnotFabricService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        fabricStabilityService: sl<FabricStabilityPredictionService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] ClubProactiveOutreachService registered');

  sl.registerLazySingleton(() => ExpertProactiveOutreachService(
        businessExpertOutreach: sl<BusinessExpertOutreachService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] ExpertProactiveOutreachService registered');

  sl.registerLazySingleton(() => ListSuggestionOutreachService(
        onboardingRecommendationService: sl<OnboardingRecommendationService>(),
        expertRecommendationsService: sl<ExpertRecommendationsService>(),
        futureCompatService: sl<FutureCompatibilityPredictionService>(),
        temporalQuantumService: sl<TemporalQuantumCompatibilityService>(),
        evolutionPatternService: sl<EvolutionPatternAnalysisService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] ListSuggestionOutreachService registered');

  // Phase 4: Background Orchestration
  sl.registerLazySingleton(() => OutreachQueueProcessor(
        supabaseService: sl<SupabaseService>(),
        ai2aiCommunication: sl<AI2AIOutreachCommunicationService>(),
      ));
  logger.debug('✅ [DI-PredictiveOutreach] OutreachQueueProcessor registered');

  sl.registerLazySingleton(() => BatchOutreachProcessor(
        communityOutreach: sl<CommunityProactiveOutreachService>(),
        groupOutreach: sl<GroupFormationOutreachService>(),
        eventOutreach: sl<EventProactiveOutreachService>(),
        businessOutreach: sl<BusinessProactiveOutreachService>(),
        clubOutreach: sl<ClubProactiveOutreachService>(),
        expertOutreach: sl<ExpertProactiveOutreachService>(),
        listOutreach: sl<ListSuggestionOutreachService>(),
        queueProcessor: sl<OutreachQueueProcessor>(),
        supabaseService: sl<SupabaseService>(),
      ));
  logger.debug('✅ [DI-PredictiveOutreach] BatchOutreachProcessor registered');

  sl.registerLazySingleton(() => BackgroundOutreachScheduler(
        queueProcessor: sl<OutreachQueueProcessor>(),
        batchProcessor: sl<BatchOutreachProcessor>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] BackgroundOutreachScheduler registered');

  // Phase 5: Notification & Delivery
  sl.registerLazySingleton(() => SilentNotificationService(
        supabaseService: sl<SupabaseService>(),
        queueProcessor: sl<OutreachQueueProcessor>(),
      ));
  logger
      .debug('✅ [DI-PredictiveOutreach] SilentNotificationService registered');

  sl.registerLazySingleton(() => OutreachHistoryService(
        supabaseService: sl<SupabaseService>(),
      ));
  logger.debug('✅ [DI-PredictiveOutreach] OutreachHistoryService registered');

  sl.registerLazySingleton(() => OutreachPreferencesService(
        supabaseService: sl<SupabaseService>(),
      ));
  logger
      .debug('✅ [DI-PredictiveOutreach] OutreachPreferencesService registered');

  // Phase 6: Scalability Services
  sl.registerLazySingleton(() => CompatibilityCacheService(
        supabaseService: sl<SupabaseService>(),
      ));
  logger
      .debug('✅ [DI-PredictiveOutreach] CompatibilityCacheService registered');

  sl.registerLazySingleton(() => PredictiveSignalsCacheService(
        supabaseService: sl<SupabaseService>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] PredictiveSignalsCacheService registered');

  sl.registerLazySingleton(() => BatchProcessingOptimizationService(
        batchProcessor: sl<BatchOutreachProcessor>(),
      ));
  logger.debug(
      '✅ [DI-PredictiveOutreach] BatchProcessingOptimizationService registered');

  logger.debug(
      '✅ [DI-PredictiveOutreach] All predictive outreach services registered');
}
