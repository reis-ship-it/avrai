// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

import 'package:avrai_runtime_os/services/integrations/spotify_airgap_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/kernel/mesh/dart_mesh_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/mesh/mesh_native_priority.dart';
import 'package:avrai_runtime_os/kernel/mesh/native_backed_mesh_kernel.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/ai2ai_native_priority.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/dart_ai2ai_runtime_kernel.dart';
import 'package:avrai_runtime_os/kernel/ai2ai/native_backed_ai2ai_kernel.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/ai2ai_mesh_governance_binding_service.dart';
import 'package:avrai_runtime_os/kernel/os/domain_execution_conformance_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel_lineage_sink.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show StorageService, SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:avrai_runtime_os/services/vibe/vibe_kernel_persistence_service.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_migration_service.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';
import 'package:avrai_runtime_os/services/vibe/scoped_context_vibe_projector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/services/events/event_host_debrief_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_telemetry_service.dart';
import 'package:avrai_runtime_os/services/events/event_planning_intake_adapter.dart';
import 'package:avrai_runtime_os/services/events/beta_event_planning_suggestion_service.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/kernel/language/human_language_boundary_review_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_learning_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_chat_event_intake_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_exchange_submission_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_release_policy.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_runtime_signal_lane.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/background/ai2ai_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/background_platform_wake_bridge.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/background/headless_background_runtime_coordinator.dart';
import 'package:avrai_runtime_os/services/background/mesh_background_execution_lane.dart';
import 'package:avrai_runtime_os/services/background/passive_kernel_signal_intake_lane.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_ai2ai_exchange_transport_adapter.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_conversation_transport_adapter.dart';
import 'package:avrai_runtime_os/services/transport/legacy/legacy_protocol_codec_adapter.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_satisfaction_enhancer.dart';
import 'package:avrai_runtime_os/ai/feedback_learning.dart'
    show UserFeedbackAnalyzer;
import 'package:avrai_runtime_os/ml/nlp_processor.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_runtime_os/services/analytics/usage_pattern_tracker.dart';
import 'package:avrai_runtime_os/ai2ai/connection_log_queue.dart';
import 'package:avrai_runtime_os/ai2ai/cloud_intelligence_sync.dart';
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart';
import 'package:avrai_runtime_os/ai2ai/peer_interaction_outcome_learning_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_inbound_decode_lane.dart';
import 'dart:developer' as developer;
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
import 'package:avrai_runtime_os/p2p/federated_learning.dart';
import 'package:avrai_runtime_os/ai/continuous_learning/data_collector.dart';
import 'package:avrai_runtime_os/ai/continuous_learning/data_processor.dart';
import 'package:avrai_runtime_os/ai/continuous_learning/orchestrator.dart';
import 'package:avrai_runtime_os/ai/continuous_learning_system.dart';
import 'package:avrai_runtime_os/ai/unified_evolution_orchestrator.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai_runtime_os/ai/event_queue.dart';
import 'package:avrai_runtime_os/ai/event_logger.dart';
import 'package:avrai_runtime_os/ai/structured_facts_extractor.dart';
import 'package:avrai_runtime_os/p2p/node_manager.dart';
import 'package:avrai_runtime_os/services/infrastructure/config_service.dart';
import 'package:avrai_runtime_os/ml/onnx_dimension_scorer.dart';
import 'package:avrai_runtime_os/ml/inference_orchestrator.dart';
import 'package:avrai_runtime_os/ai/decision_coordinator.dart';
import 'package:avrai_runtime_os/ai2ai/embedding_delta_collector.dart';
import 'package:avrai_runtime_os/ai2ai/federated_learning_hooks.dart';
import 'package:avrai_runtime_os/services/user/user_name_resolution_service.dart';
import 'package:avrai_runtime_os/services/user/personality_agent_chat_service.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/chat/conversation_orchestration_lane.dart';
import 'package:avrai_runtime_os/services/chat/friend_chat_service.dart';
import 'package:avrai_runtime_os/services/community/community_chat_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/governed_mesh_packet_codec.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_validator.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_profile_resolver.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_attestation_factory.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_lifecycle_runtime_lane.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_policy.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:avrai_runtime_os/services/chat/dm_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_message_store.dart';
import 'package:avrai_runtime_os/services/community/community_sender_key_service.dart';
import 'package:avrai_runtime_os/services/signatures/builders/bundle_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/community_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/event_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/spot_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/builders/user_signature_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/community_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/bundles/performer_venue_event_bundle_builder.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_confidence_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_freshness_tracker.dart';
import 'package:avrai_runtime_os/services/signatures/signature_match_service.dart';
import 'package:avrai_runtime_os/services/signatures/signature_repository.dart';
import 'package:avrai_runtime_os/ai2ai/anonymous_communication.dart' as ai2ai;
import 'package:avrai_runtime_os/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai_runtime_os/services/business/business_business_chat_service_ai2ai.dart';
import 'package:avrai_runtime_os/services/business/business_expert_outreach_service.dart';
import 'package:avrai_runtime_os/services/business/business_business_outreach_service.dart';
import 'package:avrai_runtime_os/services/business/business_member_service.dart';
import 'package:avrai_runtime_os/services/business/business_shared_agent_service.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/community/club_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/oauth/oauth_runtime.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_community_repository.dart';
import 'package:avrai_runtime_os/data/repositories/local_community_repository.dart';
import 'package:avrai_runtime_os/data/repositories/supabase_community_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/community_repository.dart';
import 'package:avrai_runtime_os/services/user/user_anonymization_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart'
    as event_rec_service;
import 'package:avrai_runtime_os/services/events/event_matching_service.dart';
import 'package:avrai_runtime_os/services/matching/spot_vibe_matching_service.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/auth/app_auth_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/oauth/oauth_deep_link_handler.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/services/social_media/base/social_media_common_utils.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_service_factory.dart';
import 'package:avrai_runtime_os/services/social_media/platforms/google_platform_service.dart';
import 'package:avrai_runtime_os/services/social_media/platforms/instagram_platform_service.dart';
import 'package:avrai_runtime_os/services/social_media/platforms/facebook_platform_service.dart';
import 'package:avrai_runtime_os/services/social_media/platforms/twitter_platform_service.dart';
import 'package:avrai_runtime_os/services/social_media/platforms/linkedin_platform_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_insight_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_sharing_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_discovery_service.dart';
import 'package:avrai_runtime_os/services/analytics/public_profile_analysis_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_vibe_analyzer.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_suggestion_event_store.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/local_llm/local_llm_post_install_bootstrap_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/language_pattern_learning_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
import 'package:avrai_runtime_os/services/language/language_profile_diagnostics_service.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_improvement_tracking_service.dart';
import 'package:avrai_runtime_os/services/misc/action_history_service.dart';
import 'package:avrai_runtime_os/services/security/location_obfuscation_service.dart';
import 'package:avrai_runtime_os/services/security/field_encryption_service.dart';
import 'package:avrai_runtime_os/services/admin/audit_log_service.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_network/avra_network.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:avrai_runtime_os/config/supabase_config.dart';
import 'package:avrai_runtime_os/config/google_places_config.dart';
import 'package:avrai_runtime_os/services/matching/group_formation_service.dart';
import 'package:avrai_runtime_os/services/prediction/engagement_phase_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_engagement_predictor.dart';
import 'package:avrai_runtime_os/services/prediction/markov_transition_store.dart';
import 'package:avrai_runtime_os/services/prediction/swarm_prior_loader.dart';
import 'package:avrai_runtime_os/services/prediction/replay_year_completeness_service.dart';
import 'package:avrai_runtime_os/services/prediction/authoritative_replay_year_selection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_calibration_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_ensemble_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_governance_projection_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_regime_shift_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_resolution_service.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:avrai_runtime_os/services/prediction/forecast_strength_service.dart';
import 'package:avrai_runtime_os/services/prediction/governed_forecast_runtime_service.dart';
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';

import 'package:avrai_runtime_os/services/passive_collection/smart_passive_collection_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/dwell_event_intake_adapter.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/passive_collection/battery_adaptive_batch_scheduler.dart';
import 'package:avrai_runtime_os/services/passive_collection/adaptive_digestion_job.dart';
import 'package:avrai_runtime_os/services/passive_collection/archetype_learning_runtime.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/locality_federated_exchange_service.dart';
import 'package:avrai_runtime_os/services/predictive_outreach/locality_federated_exchange_job.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';
import 'package:avrai_runtime_os/services/transport/mesh/pheromone_mesh_routing_service.dart';
import 'package:avrai_runtime_os/services/security/governance_kernel_service.dart';
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';

final bool _shouldAutoScheduleAdaptiveDigestion =
    !bool.fromEnvironment('FLUTTER_TEST') &&
        String.fromEnvironment('SIMULATED_SMOKE_PLATFORM') == '';

bool _canScheduleAdaptiveDigestionJob(GetIt sl) {
  return sl.isRegistered<SmartPassiveCollectionService>() &&
      sl.isRegistered<DwellEventIntakeAdapter>() &&
      sl.isRegistered<AppDatabase>() &&
      sl.isRegistered<PheromoneMeshRoutingService>() &&
      sl.isRegistered<ArchetypeLearningRuntime>() &&
      sl.isRegistered<LanguageRuntimeService>() &&
      sl.isRegistered<SharedPreferences>();
}

bool _canScheduleLocalityFederatedExchangeJob(GetIt sl) {
  return sl.isRegistered<LocalityFederatedExchangeService>() &&
      sl.isRegistered<AppDatabase>();
}

/// AI/Network Services Registration Module
///
/// Registers all AI and network-related services.
/// This includes:
/// - Personality learning and AI services
/// - AI2AI communication services
/// - Social media services
/// - Chat services
/// - Event/spot matching services
/// - Message encryption and anonymous communication
/// - Network services (connection, discovery, advertising)
/// - Learning systems (continuous, federated)
Future<void> registerAIServices(GetIt sl) async {
  const logger = AppLogger(defaultTag: 'DI-AI', minimumLevel: LogLevel.debug);
  logger.debug('🤖 [DI-AI] Registering AI/network services...');

  // Security & Anonymization Services (Phase 7.3.5-6)
  sl.registerLazySingleton<LocationObfuscationService>(
      () => LocationObfuscationService());
  sl.registerLazySingleton<UserAnonymizationService>(
      () => UserAnonymizationService(
            locationObfuscationService: sl<LocationObfuscationService>(),
          ));
  sl.registerLazySingleton<FieldEncryptionService>(
      () => FieldEncryptionService());
  sl.registerLazySingleton<AuditLogService>(() => AuditLogService());

  // Legal Document Service (for Terms of Service and Privacy Policy acceptance)
  sl.registerLazySingleton<LegalDocumentService>(() => LegalDocumentService(
        eventService: sl<ExpertiseEventService>(),
        supabaseService: sl<SupabaseService>(),
        storage: sl<StorageService>(),
        ledger: sl<LedgerRecorderServiceV0>(),
        receipts: sl<LedgerReceiptsServiceV0>(),
      ));

  sl.registerLazySingleton<DeviceDiscoveryService>(() {
    final platform = DeviceDiscoveryFactory.createPlatformDiscovery();
    return DeviceDiscoveryService(platform: platform);
  });

  // Personality Advertising Service
  sl.registerLazySingleton<PersonalityAdvertisingService>(() {
    return PersonalityAdvertisingService();
  });

  // PersonalityLearning (Philosophy: "Always Learning With You")
  // On-device AI learning that works offline
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    return PersonalityLearning.withPrefs(prefs);
  });

  sl.registerLazySingleton<AI2AIChatAnalyzer>(() {
    final prefs = sl<SharedPreferencesCompat>();
    return AI2AIChatAnalyzer(
      prefs: prefs,
      personalityLearning: sl<PersonalityLearning>(),
    );
  });

  sl.registerLazySingleton(
    () => HumanLanguageBoundaryReviewLane(
      prefs: sl<SharedPreferencesCompat>(),
    ),
  );
  sl.registerLazySingleton<NetworkActivityMonitor>(
    () => NetworkActivityMonitor(),
  );
  sl.registerLazySingleton(
    () => const Ai2AiRuntimeStateFrameService(),
  );
  sl.registerLazySingleton(
    () => const MeshRuntimeStateFrameService(),
  );
  sl.registerLazySingleton(
    () => MeshSegmentRevocationStore(
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton(
    () => MeshSegmentRevocationPolicy(
      revocationStore: sl<MeshSegmentRevocationStore>(),
    ),
  );
  sl.registerLazySingleton(
    () => MeshSegmentCredentialRefreshService(
      storageService: sl<StorageService>(),
      revocationPolicy: sl<MeshSegmentRevocationPolicy>(),
    ),
  );
  sl.registerLazySingleton(
    () => MeshSegmentLifecycleRuntimeLane(
      refreshService: sl<MeshSegmentCredentialRefreshService>(),
    ),
  );
  sl.registerLazySingleton(
    () => DomainExecutionFieldScenarioProofStore(
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton(
    () => BackgroundWakeExecutionRunRecordStore(
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton<MeshRouteLedger>(
    () => MeshRouteLedger(),
  );
  sl.registerLazySingleton<MeshCustodyOutbox>(
    () => MeshCustodyOutbox(),
  );
  sl.registerLazySingleton<MeshInterfaceRegistry>(
    () => MeshInterfaceRegistry(cloudInterfaceAvailable: true),
  );
  sl.registerLazySingleton<MeshAnnounceLedger>(
    () => MeshAnnounceLedger(
      announceValidator: MeshAnnounceValidator(
        revocationPolicy: sl<MeshSegmentRevocationPolicy>(),
      ),
    ),
  );
  sl.registerLazySingleton(
    () => GovernedMeshPacketCodec(
      encryptionService: sl<MessageEncryptionService>(),
    ),
  );
  sl.registerLazySingleton(
    () => MeshInboundDecodeLane(
      encryptionService: sl<MessageEncryptionService>(),
    ),
  );
  sl.registerLazySingleton(
    () => MeshNativeFallbackAudit(),
  );
  sl.registerLazySingleton<MeshNativeInvocationBridge>(
    () => MeshNativeBridgeBindings(),
  );
  sl.registerLazySingleton<DartMeshRuntimeKernel>(
    () => DartMeshRuntimeKernel(
      routeLedger: sl<MeshRouteLedger>(),
      custodyOutbox: sl<MeshCustodyOutbox>(),
      announceLedger: sl<MeshAnnounceLedger>(),
      interfaceRegistry: sl<MeshInterfaceRegistry>(),
      stateFrameService: sl<MeshRuntimeStateFrameService>(),
    ),
  );
  sl.registerLazySingleton<MeshKernelFallbackSurface>(
    () => sl<DartMeshRuntimeKernel>(),
  );
  sl.registerLazySingleton<MeshKernelContract>(
    () => NativeBackedMeshKernel(
      nativeBridge: sl<MeshNativeInvocationBridge>(),
      fallback: sl<MeshKernelFallbackSurface>(),
      audit: sl<MeshNativeFallbackAudit>(),
    ),
  );
  sl.registerLazySingleton(
    () => Ai2AiNativeFallbackAudit(),
  );
  sl.registerLazySingleton<Ai2AiNativeInvocationBridge>(
    () => Ai2AiNativeBridgeBindings(),
  );
  sl.registerLazySingleton<DartAi2AiRuntimeKernel>(
    () => DartAi2AiRuntimeKernel(
      networkActivityMonitor: sl<NetworkActivityMonitor>(),
      stateFrameService: sl<Ai2AiRuntimeStateFrameService>(),
      rendezvousStore: sl<Ai2AiRendezvousStore>(),
    ),
  );
  sl.registerLazySingleton<Ai2AiKernelFallbackSurface>(
    () => sl<DartAi2AiRuntimeKernel>(),
  );
  sl.registerLazySingleton<Ai2AiKernelContract>(
    () => NativeBackedAi2AiKernel(
      nativeBridge: sl<Ai2AiNativeInvocationBridge>(),
      fallback: sl<Ai2AiKernelFallbackSurface>(),
      audit: sl<Ai2AiNativeFallbackAudit>(),
    ),
  );
  sl.registerLazySingleton<DomainExecutionConformanceService>(
    () => DefaultDomainExecutionConformanceService(
      meshKernel: sl<MeshKernelContract>(),
      ai2aiKernel: sl<Ai2AiKernelContract>(),
      encryptionService: sl<MessageEncryptionService>(),
      featureFlagService: sl.isRegistered<FeatureFlagService>()
          ? sl<FeatureFlagService>()
          : null,
    ),
  );
  sl.registerLazySingleton<LanguagePatternLearningService>(
    () => LanguagePatternLearningService(
      agentIdService: sl<AgentIdService>(),
    ),
  );
  sl.registerLazySingleton<LanguageProfileDiagnosticsService>(
    () => LanguageProfileDiagnosticsService(
      languageLearningService: sl<LanguagePatternLearningService>(),
      agentIdService: sl<AgentIdService>(),
    ),
  );

  // AI2AI Learning Service (Phase 7, Week 38)
  // Wrapper service for AI2AI learning methods UI
  sl.registerLazySingleton(
    () => AI2AILearning(
      chatAnalyzer: sl<AI2AIChatAnalyzer>(),
    ),
  );

  sl.registerLazySingleton(
    () => Ai2AiRendezvousStore(
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton(
    () => const MeshSegmentProfileResolver(),
  );
  sl.registerLazySingleton(
    () => MeshSegmentCredentialFactory(
      signatureRepository: sl.isRegistered<SignatureRepository>()
          ? sl<SignatureRepository>()
          : null,
    ),
  );
  sl.registerLazySingleton(
    () => MeshAnnounceAttestationFactory(
      signatureRepository: sl.isRegistered<SignatureRepository>()
          ? sl<SignatureRepository>()
          : null,
    ),
  );
  sl.registerLazySingleton(
    () => const Ai2AiRendezvousReleasePolicy(),
  );
  sl.registerLazySingleton(
    () => Ai2AiExchangeSubmissionLane(
      ai2aiKernel: sl<Ai2AiKernelContract>(),
      transportAdapter: sl.isRegistered<LegacyAi2AiExchangeTransportAdapter>()
          ? sl<LegacyAi2AiExchangeTransportAdapter>()
          : null,
    ),
  );
  sl.registerLazySingleton(
    () => Ai2AiRendezvousScheduler(
      store: sl<Ai2AiRendezvousStore>(),
      submissionLane: sl<Ai2AiExchangeSubmissionLane>(),
      releasePolicy: sl<Ai2AiRendezvousReleasePolicy>(),
      connectivity: sl<Connectivity>(),
      hasTrustedRoute: (peerId) async {
        final featureFlagService = sl.isRegistered<FeatureFlagService>()
            ? sl<FeatureFlagService>()
            : null;
        if (featureFlagService == null) {
          return true;
        }
        final reticulumEnabled = await featureFlagService.isEnabled(
          GovernanceFeatureFlags.reticulumMeshTransportControlPlaneV1,
          defaultValue: false,
        );
        final trustedEnforcementEnabled = reticulumEnabled &&
            await featureFlagService.isEnabled(
              GovernanceFeatureFlags.trustedMeshAnnounceEnforcementV1,
              defaultValue: false,
            );
        if (!trustedEnforcementEnabled ||
            !sl.isRegistered<MeshAnnounceLedger>()) {
          return true;
        }
        final activeAnnounces =
            sl<MeshAnnounceLedger>().activeRecords(destinationId: peerId);
        return activeAnnounces.any((record) => record.attestationId != null);
      },
    ),
  );
  sl.registerLazySingleton(
    () => Ai2AiRendezvousRuntimeSignalLane(
      scheduler: sl<Ai2AiRendezvousScheduler>(),
    ),
  );
  sl.registerLazySingleton(
    () => Ai2AiBackgroundExecutionLane(
      scheduler: sl<Ai2AiRendezvousScheduler>(),
    ),
  );
  sl.registerLazySingleton<BackgroundPlatformWakePort>(
    () => MethodChannelBackgroundPlatformWakeBridge(),
  );
  sl.registerLazySingleton(
    () => MeshBackgroundExecutionLane(
      discovery: sl<DeviceDiscoveryService>(),
      packetCodec: sl<GovernedMeshPacketCodec>(),
      routeLedger: sl<MeshRouteLedger>(),
      custodyOutbox: sl<MeshCustodyOutbox>(),
      interfaceRegistry: sl<MeshInterfaceRegistry>(),
      announceLedger: sl<MeshAnnounceLedger>(),
      localUserId: sl.isRegistered<AppAuthService>()
          ? sl<AppAuthService>().currentUserId
          : null,
      governanceBindingService:
          sl.isRegistered<Ai2AiMeshGovernanceBindingService>()
              ? sl<Ai2AiMeshGovernanceBindingService>()
              : null,
      segmentProfileResolver: sl.isRegistered<MeshSegmentProfileResolver>()
          ? sl<MeshSegmentProfileResolver>()
          : null,
      segmentCredentialFactory: sl.isRegistered<MeshSegmentCredentialFactory>()
          ? sl<MeshSegmentCredentialFactory>()
          : null,
      segmentCredentialRefreshService:
          sl.isRegistered<MeshSegmentCredentialRefreshService>()
              ? sl<MeshSegmentCredentialRefreshService>()
              : null,
      segmentRevocationStore: sl.isRegistered<MeshSegmentRevocationStore>()
          ? sl<MeshSegmentRevocationStore>()
          : null,
      announceAttestationFactory:
          sl.isRegistered<MeshAnnounceAttestationFactory>()
              ? sl<MeshAnnounceAttestationFactory>()
              : null,
    ),
  );

  sl.registerLazySingleton(
    () => Ai2AiChatEventIntakeService(
      chatAnalyzer: sl<AI2AIChatAnalyzer>(),
      humanLanguageBoundaryReviewLane: sl<HumanLanguageBoundaryReviewLane>(),
      agentIdService: sl<AgentIdService>(),
      governanceBindingService:
          sl.isRegistered<Ai2AiMeshGovernanceBindingService>()
              ? sl<Ai2AiMeshGovernanceBindingService>()
              : null,
      ai2aiKernel: sl.isRegistered<Ai2AiKernelContract>()
          ? sl<Ai2AiKernelContract>()
          : null,
      exchangeSubmissionLane: sl.isRegistered<Ai2AiExchangeSubmissionLane>()
          ? sl<Ai2AiExchangeSubmissionLane>()
          : null,
    ),
  );
  sl.registerLazySingleton(
    () => DomainExecutionFieldScenarioRunner(
      meshKernel: sl<MeshKernelContract>(),
      ai2aiKernel: sl<Ai2AiKernelContract>(),
      conformanceService: sl<DomainExecutionConformanceService>(),
      routeLedger: sl<MeshRouteLedger>(),
      custodyOutbox: sl<MeshCustodyOutbox>(),
      announceLedger: sl<MeshAnnounceLedger>(),
      interfaceRegistry: sl<MeshInterfaceRegistry>(),
      meshRuntimeStateFrameService: sl<MeshRuntimeStateFrameService>(),
      ai2aiRuntimeStateFrameService: sl<Ai2AiRuntimeStateFrameService>(),
      networkActivityMonitor: sl<NetworkActivityMonitor>(),
      discovery: sl<DeviceDiscoveryService>(),
      segmentProfileResolver: sl<MeshSegmentProfileResolver>(),
      segmentCredentialFactory: sl<MeshSegmentCredentialFactory>(),
      announceAttestationFactory: sl<MeshAnnounceAttestationFactory>(),
      meshCredentialRefreshService: sl<MeshSegmentCredentialRefreshService>(),
      meshRevocationStore: sl<MeshSegmentRevocationStore>(),
      ambientSocialRealityLearningService:
          sl<AmbientSocialRealityLearningService>(),
      ai2aiExchangeSubmissionLane: sl<Ai2AiExchangeSubmissionLane>(),
      ai2aiRendezvousScheduler: sl<Ai2AiRendezvousScheduler>(),
      proofStore: sl<DomainExecutionFieldScenarioProofStore>(),
      trustedAnnounceEnforcementEnabled: true,
    ),
  );

  // UserFeedbackAnalyzer (Philosophy: "Dynamic dimension discovery through user feedback analysis")
  // Advanced feedback learning system that extracts implicit personality dimensions
  // Enhanced with Quantum Satisfaction Enhancement (Phase 4.1)
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    final personalityLearning = sl<PersonalityLearning>();
    final quantumSatisfactionEnhancer = sl<QuantumSatisfactionEnhancer>();
    final atomicClock = sl<AtomicClockService>();
    return UserFeedbackAnalyzer(
      prefs: prefs,
      personalityLearning: personalityLearning,
      quantumSatisfactionEnhancer: quantumSatisfactionEnhancer,
      atomicClock: atomicClock,
    );
  });

  // NLPProcessor (Natural Language Processing for text analysis)
  sl.registerLazySingleton(() => NLPProcessor());

  // PersonalitySyncService (Philosophy: "Cloud sync is optional and encrypted")
  sl.registerLazySingleton(() {
    final supabaseService = sl<SupabaseService>();
    final storageService = sl<StorageService>();
    return PersonalitySyncService(
      supabaseService: supabaseService,
      storageService: storageService,
    );
  });

  // UsagePatternTracker (Philosophy: "The key adapts to YOUR usage")
  sl.registerLazySingleton(() {
    final prefs = sl<SharedPreferencesCompat>();
    return UsagePatternTracker(prefs);
  });

  sl.registerLazySingleton<ForecastKernel>(() => buildNativeForecastKernel());
  logger.debug('✅ [DI-AI] ForecastKernel registered (native-first)');

  sl.registerLazySingleton(() => const ReplayYearCompletenessService());
  logger.debug('✅ [DI-AI] ReplayYearCompletenessService registered');

  sl.registerLazySingleton(
    () => AuthoritativeReplayYearSelectionService(
      completenessService: sl<ReplayYearCompletenessService>(),
    ),
  );
  logger.debug('✅ [DI-AI] AuthoritativeReplayYearSelectionService registered');

  sl.registerLazySingleton(
    () => ForecastSkillLedger(
      prefs: sl<SharedPreferencesCompat>(),
    ),
  );
  logger.debug('✅ [DI-AI] ForecastSkillLedger registered');

  sl.registerLazySingleton(
    () => ForecastEnsembleService(
      skillLedger: sl<ForecastSkillLedger>(),
    ),
  );
  sl.registerLazySingleton(
    () => ForecastCalibrationService(
      skillLedger: sl<ForecastSkillLedger>(),
    ),
  );
  sl.registerLazySingleton(
    () => ForecastRegimeShiftService(
      skillLedger: sl<ForecastSkillLedger>(),
    ),
  );
  sl.registerLazySingleton(
    () => ForecastStrengthService(
      ensembleService: sl<ForecastEnsembleService>(),
      calibrationService: sl<ForecastCalibrationService>(),
      regimeShiftService: sl<ForecastRegimeShiftService>(),
    ),
  );
  sl.registerLazySingleton(
    () => ForecastResolutionService(
      skillLedger: sl<ForecastSkillLedger>(),
    ),
  );
  logger.debug('✅ [DI-AI] Forecast strength services registered');

  sl.registerLazySingleton(
    () => ForecastGovernanceProjectionService(
      forecastKernel: sl<ForecastKernel>(),
      temporalKernel: sl<TemporalKernel>(),
      skillLedger: sl<ForecastSkillLedger>(),
      ensembleService: sl<ForecastEnsembleService>(),
      calibrationService: sl<ForecastCalibrationService>(),
      regimeShiftService: sl<ForecastRegimeShiftService>(),
      forecastStrengthService: sl<ForecastStrengthService>(),
      forecastResolutionService: sl<ForecastResolutionService>(),
    ),
  );
  logger.debug('✅ [DI-AI] ForecastGovernanceProjectionService registered');

  sl.registerLazySingleton(
    () => GovernedForecastRuntimeService(
      forecastGovernanceProjectionService:
          sl<ForecastGovernanceProjectionService>(),
      replayYearSelectionService: sl<AuthoritativeReplayYearSelectionService>(),
    ),
  );
  logger.debug('✅ [DI-AI] GovernedForecastRuntimeService registered');

  // AI2AI Protocol (Philosophy: "The Key Works Everywhere")
  // Phase 14: Updated to use MessageEncryptionService (Signal Protocol ready)
  // Create RateLimiter with late-binding providers for battery-aware and adaptive mesh integration
  sl.registerLazySingleton(() {
    // Create RateLimiter with providers that access ConnectionOrchestrator's services
    // These providers will be called when rate limiting checks occur, allowing them
    // to access services that are initialized in ConnectionOrchestrator
    final rateLimiter = RateLimiter(
      batteryLevelProvider: () {
        try {
          // Access battery level through ConnectionOrchestrator
          // This will work even if orchestrator is created after protocol
          // Function signature: Future<int>? Function()? - can return null or Future<int>
          if (sl.isRegistered<VibeConnectionOrchestrator>()) {
            final orchestrator = sl<VibeConnectionOrchestrator>();
            // Get battery level and convert int? to int (default to 100 if null)
            // Return Future<int> (the signature allows Future<int>?)
            final future = orchestrator.getBatteryLevel().then((level) {
              return level ?? 100; // Convert int? to int
            });
            return future;
          }
          return null; // Battery level not available yet
        } catch (e) {
          // Non-fatal: rate limiting will work without battery-aware adjustments
          return null;
        }
      },
      networkDensityProvider: () {
        try {
          // Access network density through ConnectionOrchestrator
          if (sl.isRegistered<VibeConnectionOrchestrator>()) {
            final orchestrator = sl<VibeConnectionOrchestrator>();
            return orchestrator.getNetworkDensity();
          }
          return null; // Network density not available yet
        } catch (e) {
          // Non-fatal: rate limiting will work without adaptive mesh adjustments
          return null;
        }
      },
    );

    return AI2AIProtocol(
      encryptionService: sl<MessageEncryptionService>(),
      rateLimiter: rateLimiter,
      temporalLineageSink: sl.isRegistered<TemporalKernel>()
          ? TemporalKernelLineageSink(temporalKernel: sl<TemporalKernel>())
          : null,
    );
  });

  // Connection Log Queue (Philosophy: "Cloud is optional enhancement")
  sl.registerLazySingleton(
      () => ConnectionLogQueue(sl<SharedPreferencesCompat>()));

  // Cloud Intelligence Sync (Philosophy: "Cloud adds network wisdom")
  sl.registerLazySingleton(() => CloudIntelligenceSync(
        queue: sl<ConnectionLogQueue>(),
        connectivity: sl<Connectivity>(),
      ));

  if (!sl.isRegistered<AmbientSocialRealityLearningService>()) {
    sl.registerLazySingleton<AmbientSocialRealityLearningService>(
      () => AmbientSocialRealityLearningService(
        whatIngestion: sl.isRegistered<WhatRuntimeIngestionService>()
            ? sl<WhatRuntimeIngestionService>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<PeerInteractionOutcomeLearningService>()) {
    sl.registerLazySingleton<PeerInteractionOutcomeLearningService>(
      () => PeerInteractionOutcomeLearningService(
        governanceKernelService: sl.isRegistered<GovernanceKernelService>()
            ? sl<GovernanceKernelService>()
            : null,
        ambientSocialRealityLearningService:
            sl<AmbientSocialRealityLearningService>(),
      ),
    );
  }

  // VibeConnectionOrchestrator + AI2AIRealtimeService wiring
  // Philosophy: "The Key Works Everywhere" - offline AI2AI via PersonalityLearning
  sl.registerLazySingleton<VibeConnectionOrchestrator>(() {
    final connectivity = sl<Connectivity>();
    final vibeAnalyzer = sl<UserVibeAnalyzer>();
    final deviceDiscovery = sl<DeviceDiscoveryService>();
    final advertisingService = sl<PersonalityAdvertisingService>();
    final personalityLearning = sl<PersonalityLearning>();
    final legacyProtocolCodecAdapter = sl<LegacyProtocolCodecAdapter>();
    final signalKeyManager =
        sl.isRegistered<SignalKeyManager>() ? sl<SignalKeyManager>() : null;
    final ai2aiMeshGovernanceBindingService =
        sl.isRegistered<Ai2AiMeshGovernanceBindingService>()
            ? sl<Ai2AiMeshGovernanceBindingService>()
            : null;
    final meshPacketCodec = sl.isRegistered<GovernedMeshPacketCodec>()
        ? sl<GovernedMeshPacketCodec>()
        : null;
    final meshInboundDecodeLane = sl.isRegistered<MeshInboundDecodeLane>()
        ? sl<MeshInboundDecodeLane>()
        : null;
    final prefs = sl<SharedPreferencesCompat>();

    final orchestrator = VibeConnectionOrchestrator(
      vibeAnalyzer: vibeAnalyzer,
      connectivity: connectivity,
      deviceDiscovery: deviceDiscovery,
      advertisingService: advertisingService,
      personalityLearning: personalityLearning,
      peerInteractionOutcomeLearningService:
          sl<PeerInteractionOutcomeLearningService>(),
      legacyProtocolCodecAdapter: legacyProtocolCodecAdapter,
      meshPacketCodec: meshPacketCodec,
      meshInboundDecodeLane: meshInboundDecodeLane,
      signalKeyManager: signalKeyManager,
      ai2aiMeshGovernanceBindingService: ai2aiMeshGovernanceBindingService,
      ai2aiChatEventIntakeService: sl<Ai2AiChatEventIntakeService>(),
      featureFlagService: sl.isRegistered<FeatureFlagService>()
          ? sl<FeatureFlagService>()
          : null,
      prefs: prefs,
    );

    // Wire personality evolution -> advertising refresh.
    // This makes "continuous learning" visible to nearby peers when discovery is enabled.
    // Also wire to knot evolution coordinator for automatic knot regeneration and tracking.
    personalityLearning.setEvolutionCallback((userId, evolvedProfile) {
      // Fire-and-forget: we don't want to block learning on BLE/advertising operations.
      Future<void>(() async {
        // Update advertising (existing functionality)
        await orchestrator.updatePersonalityAdvertising(userId, evolvedProfile);

        // NEW: Handle knot evolution (automatic regeneration and snapshot creation)
        // Knot services are registered before AI services, so coordinator should be available
        if (sl.isRegistered<KnotEvolutionCoordinatorService>()) {
          try {
            final knotCoordinator = sl<KnotEvolutionCoordinatorService>();
            await knotCoordinator.handleProfileEvolution(
                userId, evolvedProfile);
          } catch (e) {
            // Log but don't fail - knot evolution is non-blocking
            developer.log(
              '⚠️ Failed to handle knot evolution: $e',
              name: 'injection_container_ai',
            );
          }
        }
      });
    });
    // Build realtime with orchestrator and register it for app-wide access
    // Note: RealtimeBackend is registered during backend initialization (after AI services)
    // So we check if it's available and only set realtime service if it is
    if (sl.isRegistered<RealtimeBackend>()) {
      try {
        final realtimeBackend = sl<RealtimeBackend>();
        final realtime = AI2AIBroadcastService(realtimeBackend);
        orchestrator.setRealtimeService(realtime);
        // Expose realtime service via DI for UI pages/debug tools
        if (!sl.isRegistered<AI2AIBroadcastService>()) {
          sl.registerSingleton<AI2AIBroadcastService>(realtime);
        }
      } catch (e) {
        developer.log(
          '⚠️ RealtimeBackend not available yet, VibeConnectionOrchestrator will work without realtime',
          name: 'injection_container_ai',
        );
      }
    } else {
      developer.log(
        'ℹ️ RealtimeBackend not registered yet, VibeConnectionOrchestrator will work without realtime',
        name: 'injection_container_ai',
      );
    }
    return orchestrator;
  });

  // HTTP Client (shared across datasources)
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // AI Improvement Tracking Service
  sl.registerLazySingleton(() {
    final storageService = sl<StorageService>();
    return AIImprovementTrackingService(storage: storageService.defaultStorage);
  });

  // Action History Service
  sl.registerLazySingleton(() {
    final storageService = sl<StorageService>();
    return ActionHistoryService(storage: storageService.defaultStorage);
  });

  // Contextual Personality Service
  sl.registerLazySingleton(() => ContextualPersonalityService());

  // Enhanced Connectivity Service
  sl.registerLazySingleton(() {
    final httpClient = sl<http.Client>();
    return EnhancedConnectivityService(httpClient: httpClient);
  });

  // Federated Learning System
  sl.registerLazySingleton<FederatedLearningSystem>(() {
    final storageService = sl<StorageService>();
    return FederatedLearningSystem(storage: storageService.defaultStorage);
  });

  // Continuous Learning System
  sl.registerLazySingleton<ContinuousLearningSystem>(() {
    final agentIdService = sl<AgentIdService>();
    final dataCollector = LearningDataCollector(agentIdService: agentIdService);
    final dataProcessor = LearningDataProcessor();
    final orchestrator = ContinuousLearningOrchestrator(
      dataCollector: dataCollector,
      dataProcessor: dataProcessor,
      // Perf triage: slow down in debug/dev to reduce CPU churn.
      cycleInterval: SupabaseConfig.debug
          ? const Duration(seconds: 5)
          : const Duration(seconds: 1),
    );
    return ContinuousLearningSystem(
      agentIdService: agentIdService,
      orchestrator: orchestrator,
    );
  });

  // Event Queue (offline-capable event queuing)
  sl.registerLazySingleton(() => EventQueue());

  // Event Logger (context-enriched event logging)
  sl.registerLazySingleton(() {
    final agentIdService = sl<AgentIdService>();
    final supabaseService = sl<SupabaseService>();
    final eventQueue = sl<EventQueue>();
    final learningSystem = sl<ContinuousLearningSystem>();
    return EventLogger(
      agentIdService: agentIdService,
      supabaseService: supabaseService,
      eventQueue: eventQueue,
      learningSystem: learningSystem,
    );
  });

  // Structured Facts Extractor
  sl.registerLazySingleton(() => StructuredFactsExtractor());

  // P2P Node Manager
  sl.registerLazySingleton(() => P2PNodeManager());

  // Config (must be registered before InferenceOrchestrator)
  sl.registerLazySingleton<ConfigService>(() => ConfigService(
        environment: 'development',
        supabaseUrl: SupabaseConfig.url,
        supabaseAnonKey: SupabaseConfig.anonKey,
        googlePlacesApiKey: GooglePlacesConfig.getApiKey(),
        debug: SupabaseConfig.debug,
        inferenceBackend: 'onnx',
        orchestrationStrategy: 'device_first',
      ));

  // ONNX Dimension Scorer
  sl.registerLazySingleton<OnnxDimensionScorer>(() => OnnxDimensionScorer());

  // Inference Orchestrator
  sl.registerLazySingleton(() {
    final config = sl<ConfigService>();
    final onnxScorer = sl<OnnxDimensionScorer>();
    return InferenceOrchestrator(
      onnxScorer: onnxScorer,
      config: config,
    );
  });

  // Decision Coordinator
  sl.registerLazySingleton(() {
    final orchestrator = sl<InferenceOrchestrator>();
    final config = sl<ConfigService>();
    return DecisionCoordinator(
      orchestrator: orchestrator,
      config: config,
    );
  });

  // Embedding Delta Collector
  sl.registerLazySingleton(() => EmbeddingDeltaCollector());

  // Federated Learning Hooks
  sl.registerLazySingleton(() {
    final deltaCollector = sl<EmbeddingDeltaCollector>();
    return FederatedLearningHooks(
      deltaCollector: deltaCollector,
    );
  });

  // PreferencesProfile Service (for preference learning and quantum recommendations)
  sl.registerLazySingleton<PreferencesProfileService>(
      () => PreferencesProfileService(
            storage: sl<StorageService>(),
          ));

  if (!sl.isRegistered<SignatureFreshnessTracker>()) {
    sl.registerLazySingleton<SignatureFreshnessTracker>(
      () => const SignatureFreshnessTracker(),
    );
  }
  if (!sl.isRegistered<SignatureConfidenceService>()) {
    sl.registerLazySingleton<SignatureConfidenceService>(
      () => const SignatureConfidenceService(),
    );
  }
  if (!sl.isRegistered<SignatureRepository>()) {
    sl.registerLazySingleton<SignatureRepository>(
      () => SignatureRepository(
        storageService: sl<StorageService>(),
      ),
    );
  }
  if (!sl.isRegistered<UserSignatureBuilder>()) {
    sl.registerLazySingleton<UserSignatureBuilder>(
      () => UserSignatureBuilder(
        confidenceService: sl<SignatureConfidenceService>(),
        freshnessTracker: sl<SignatureFreshnessTracker>(),
      ),
    );
  }
  if (!sl.isRegistered<SpotSignatureBuilder>()) {
    sl.registerLazySingleton<SpotSignatureBuilder>(
      () => SpotSignatureBuilder(
        confidenceService: sl<SignatureConfidenceService>(),
        freshnessTracker: sl<SignatureFreshnessTracker>(),
      ),
    );
  }
  if (!sl.isRegistered<CommunitySignatureBuilder>()) {
    sl.registerLazySingleton<CommunitySignatureBuilder>(
      () => CommunitySignatureBuilder(
        confidenceService: sl<SignatureConfidenceService>(),
        freshnessTracker: sl<SignatureFreshnessTracker>(),
      ),
    );
  }
  if (!sl.isRegistered<EventSignatureBuilder>()) {
    sl.registerLazySingleton<EventSignatureBuilder>(
      () => EventSignatureBuilder(
        confidenceService: sl<SignatureConfidenceService>(),
        freshnessTracker: sl<SignatureFreshnessTracker>(),
      ),
    );
  }
  if (!sl.isRegistered<BundleSignatureBuilder>()) {
    sl.registerLazySingleton<BundleSignatureBuilder>(
      () => BundleSignatureBuilder(
        confidenceService: sl<SignatureConfidenceService>(),
        freshnessTracker: sl<SignatureFreshnessTracker>(),
      ),
    );
  }
  if (!sl.isRegistered<PerformerVenueEventBundleBuilder>()) {
    sl.registerLazySingleton<PerformerVenueEventBundleBuilder>(
      () => PerformerVenueEventBundleBuilder(
        bundleSignatureBuilder: sl<BundleSignatureBuilder>(),
        spotSignatureBuilder: sl<SpotSignatureBuilder>(),
        userSignatureBuilder: sl<UserSignatureBuilder>(),
      ),
    );
  }
  if (!sl.isRegistered<CommunityEventBundleBuilder>()) {
    sl.registerLazySingleton<CommunityEventBundleBuilder>(
      () => CommunityEventBundleBuilder(
        bundleSignatureBuilder: sl<BundleSignatureBuilder>(),
        communitySignatureBuilder: sl<CommunitySignatureBuilder>(),
        eventSignatureBuilder: sl<EventSignatureBuilder>(),
      ),
    );
  }
  if (!sl.isRegistered<SignatureMatchService>()) {
    sl.registerLazySingleton<SignatureMatchService>(
      () => const SignatureMatchService(),
    );
  }
  if (!sl.isRegistered<RemoteSourceHealthService>()) {
    sl.registerLazySingleton<RemoteSourceHealthService>(
      () => RemoteSourceHealthService(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<EntitySignatureService>()) {
    sl.registerLazySingleton<EntitySignatureService>(
      () => EntitySignatureService(
        repository: sl<SignatureRepository>(),
        storageService: sl<StorageService>(),
        matchService: sl<SignatureMatchService>(),
        userSignatureBuilder: sl<UserSignatureBuilder>(),
        spotSignatureBuilder: sl<SpotSignatureBuilder>(),
        communitySignatureBuilder: sl<CommunitySignatureBuilder>(),
        eventSignatureBuilder: sl<EventSignatureBuilder>(),
        performerVenueEventBundleBuilder:
            sl<PerformerVenueEventBundleBuilder>(),
        communityEventBundleBuilder: sl<CommunityEventBundleBuilder>(),
        userVibeAnalyzer: sl<UserVibeAnalyzer>(),
        personalityLearning: sl<PersonalityLearning>(),
        remoteSourceHealthService: sl.isRegistered<RemoteSourceHealthService>()
            ? sl<RemoteSourceHealthService>()
            : null,
      ),
    );
  }

  // Event Recommendation Service (for AI recommendations)
  sl.registerLazySingleton<event_rec_service.EventRecommendationService>(
    () => event_rec_service.EventRecommendationService(
      eventService: sl<ExpertiseEventService>(),
      knotRecommendationEngine: sl<IntegratedKnotRecommendationEngine>(),
      personalityLearning: sl<PersonalityLearning>(),
      vibeCompatibilityService: sl<VibeCompatibilityService>(),
      agentIdService: sl<AgentIdService>(),
      knotFabricService: sl<KnotFabricService>(),
      knotStorageService: sl<KnotStorageService>(),
      entitySignatureService: sl<EntitySignatureService>(),
      whatKernel: sl.isRegistered<WhatKernelContract>()
          ? sl<WhatKernelContract>()
          : null,
      headlessOsHost: sl.isRegistered<HeadlessAvraiOsHost>()
          ? sl<HeadlessAvraiOsHost>()
          : null,
      quantumMatchingController: sl.isRegistered<QuantumMatchingController>()
          ? sl<QuantumMatchingController>()
          : null,
    ),
  );

  // Event Matching Service (for event matching signals)
  sl.registerLazySingleton<EventMatchingService>(
    () => EventMatchingService(
      knotRecommendationEngine: sl<IntegratedKnotRecommendationEngine>(),
      personalityLearning: sl<PersonalityLearning>(),
      feedbackService: sl.isRegistered<PostEventFeedbackService>()
          ? sl<PostEventFeedbackService>()
          : null,
      socialMediaConnectionService:
          sl.isRegistered<SocialMediaConnectionService>()
              ? sl<SocialMediaConnectionService>()
              : null,
    ),
  );

  // Spot Vibe Matching Service (for spot-user vibe matching)
  sl.registerLazySingleton<SpotVibeMatchingService>(
    () => SpotVibeMatchingService(
      vibeAnalyzer: sl<UserVibeAnalyzer>(),
      entityKnotService: sl<EntityKnotService>(),
      personalityKnotService: sl<PersonalityKnotService>(),
      entitySignatureService: sl<EntitySignatureService>(),
    ),
  );

  // OAuth Deep Link Handler (Phase 8.2: OAuth Implementation)
  sl.registerLazySingleton<AppAuthService>(
    () => SupabaseAppAuthService(client: Supabase.instance.client),
  );

  sl.registerLazySingleton<OAuthDeepLinkHandler>(
    () => OAuthDeepLinkHandler(),
  );
  sl.registerLazySingleton<OAuthRuntime>(
    () => sl<OAuthDeepLinkHandler>(),
  );

  // Social Media Connection Service (Phase 8.2: Social Media Data Collection)
  // Phase 1.3: Refactored to use platform-specific services
  // Register common utilities first
  sl.registerLazySingleton<SocialMediaCommonUtils>(
    () => SocialMediaCommonUtils(sl<StorageService>()),
  );

  // Register platform services
  sl.registerLazySingleton<GooglePlatformService>(
    () => GooglePlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<InstagramPlatformService>(
    () => InstagramPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<FacebookPlatformService>(
    () => FacebookPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<TwitterPlatformService>(
    () => TwitterPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );
  sl.registerLazySingleton<LinkedInPlatformService>(
    () => LinkedInPlatformService(
      storageService: sl<StorageService>(),
      commonUtils: sl<SocialMediaCommonUtils>(),
    ),
  );

  // Register factory with platform services
  sl.registerLazySingleton<SocialMediaServiceFactory>(
    () => SocialMediaServiceFactory(
      services: {
        'google': sl<GooglePlatformService>(),
        'instagram': sl<InstagramPlatformService>(),
        'facebook': sl<FacebookPlatformService>(),
        'twitter': sl<TwitterPlatformService>(),
        'linkedin': sl<LinkedInPlatformService>(),
      },
    ),
  );

  // Register main service with factory
  sl.registerLazySingleton<SocialMediaConnectionService>(
    () => SocialMediaConnectionService(
      sl<StorageService>(),
      sl<AgentIdService>(),
      sl<OAuthRuntime>(),
      serviceFactory: sl<SocialMediaServiceFactory>(),
    ),
  );

  // Social Media Insight Service (Phase 10: Personality Learning Integration)
  sl.registerLazySingleton<SocialMediaInsightService>(
    () => SocialMediaInsightService(
      storageService: sl<StorageService>(),
      connectionService: sl<SocialMediaConnectionService>(),
      vibeAnalyzer: sl<SocialMediaVibeAnalyzer>(),
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Social Media Sharing Service (Phase 10: Sharing System)
  sl.registerLazySingleton<SocialMediaSharingService>(
    () => SocialMediaSharingService(
      connectionService: sl<SocialMediaConnectionService>(),
    ),
  );

  // Social Media Discovery Service (Phase 10: Friend Discovery)
  sl.registerLazySingleton<SocialMediaDiscoveryService>(
    () => SocialMediaDiscoveryService(
      storageService: sl<StorageService>(),
      connectionService: sl<SocialMediaConnectionService>(),
      supabaseService: sl<SupabaseService>(),
    ),
  );

  // Public Profile Analysis Service (Phase 10: User-Provided Handles)
  sl.registerLazySingleton<PublicProfileAnalysisService>(
    () => PublicProfileAnalysisService(
      storageService: sl<StorageService>(),
      vibeAnalyzer: sl<SocialMediaVibeAnalyzer>(),
      insightService: sl<SocialMediaInsightService>(),
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Phase 3: Unified Chat Services
  sl.registerLazySingleton(() => UserNameResolutionService());
  sl.registerLazySingleton(() => BhamRouteLearningService());
  sl.registerLazySingleton(() =>
      BhamRoutePlanner(routeLearningService: sl<BhamRouteLearningService>()));
  sl.registerLazySingleton(() => const BhamTransportPolicy());
  sl.registerLazySingleton(() => BhamMessagingRetentionService());
  sl.registerLazySingleton(() => BhamNotificationPolicyService());
  sl.registerLazySingleton(() => DirectMatchService());
  sl.registerLazySingleton(() => AdminSupportChatService(
        routePlanner: sl<BhamRoutePlanner>(),
        routeLearningService: sl<BhamRouteLearningService>(),
        transportPolicy: sl<BhamTransportPolicy>(),
      ));
  sl.registerLazySingleton(() => EventChatService(
        routePlanner: sl<BhamRoutePlanner>(),
        routeLearningService: sl<BhamRouteLearningService>(),
        transportPolicy: sl<BhamTransportPolicy>(),
      ));
  sl.registerLazySingleton(() => PersonalityAgentChatService(
        languageRuntimeService: sl<LanguageRuntimeService>(),
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        personalityLearning: sl<PersonalityLearning>(),
        searchRepository: sl<HybridSearchRepository>(),
        headlessOsHost: sl.isRegistered<HeadlessAvraiOsHost>()
            ? sl<HeadlessAvraiOsHost>()
            : null,
      ));
  // DM blob store (payloadless realtime)
  if (!sl.isRegistered<DmMessageStore>()) {
    sl.registerLazySingleton(
        () => DmMessageStore(supabase: sl<SupabaseService>()));
  }

  // Community sender keys + message store (payloadless notify + single ciphertext)
  sl.registerLazySingleton(
      () => CommunityMessageStore(supabase: sl<SupabaseService>()));
  sl.registerLazySingleton(() => CommunitySenderKeyService(
        secureStorage: sl<FlutterSecureStorage>(),
        supabase: sl<SupabaseService>(),
        agentIdService: sl<AgentIdService>(),
        encryptionService: sl<MessageEncryptionService>(),
      ));

  sl.registerLazySingleton(() => FriendChatService(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        realtimeBackend:
            sl.isRegistered<RealtimeBackend>() ? sl<RealtimeBackend>() : null,
        atomicClock: sl<AtomicClockService>(),
        dmStore: sl<DmMessageStore>(),
        routePlanner: sl<BhamRoutePlanner>(),
        routeLearningService: sl<BhamRouteLearningService>(),
        transportPolicy: sl<BhamTransportPolicy>(),
        humanLanguageBoundaryReviewLane: sl<HumanLanguageBoundaryReviewLane>(),
        ai2aiChatEventIntakeService: sl<Ai2AiChatEventIntakeService>(),
        headlessOsHost: sl.isRegistered<HeadlessAvraiOsHost>()
            ? sl<HeadlessAvraiOsHost>()
            : null,
      ));
  sl.registerLazySingleton(() => CommunityChatService(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService: sl<AgentIdService>(),
        realtimeBackend:
            sl.isRegistered<RealtimeBackend>() ? sl<RealtimeBackend>() : null,
        atomicClock: sl<AtomicClockService>(),
        dmStore: sl<DmMessageStore>(),
        senderKeyService: sl<CommunitySenderKeyService>(),
        communityMessageStore: sl<CommunityMessageStore>(),
        routePlanner: sl<BhamRoutePlanner>(),
        routeLearningService: sl<BhamRouteLearningService>(),
        transportPolicy: sl<BhamTransportPolicy>(),
        humanLanguageBoundaryReviewLane: sl<HumanLanguageBoundaryReviewLane>(),
        ai2aiChatEventIntakeService: sl<Ai2AiChatEventIntakeService>(),
        headlessOsHost: sl.isRegistered<HeadlessAvraiOsHost>()
            ? sl<HeadlessAvraiOsHost>()
            : null,
      ));

  // Community Service (for community chat member lists)
  if (!sl.isRegistered<CommunityRepository>() &&
      sl.isRegistered<StorageService>() &&
      sl.isRegistered<FeatureFlagService>()) {
    sl.registerLazySingleton<CommunityRepository>(
        () => HybridCommunityRepository(
              local: LocalCommunityRepository(
                storageService: sl<StorageService>(),
              ),
              remote: SupabaseCommunityRepository(
                supabaseService: sl.isRegistered<SupabaseService>()
                    ? sl<SupabaseService>()
                    : SupabaseService(),
              ),
              featureFlags: sl<FeatureFlagService>(),
            ));
  }
  if (!sl.isRegistered<CommunityService>()) {
    sl.registerLazySingleton<CommunityService>(() => CommunityService(
          expansionService: GeographicExpansionService(),
          knotFabricService: sl<KnotFabricService>(),
          knotStorageService: sl<KnotStorageService>(),
          storageService:
              sl.isRegistered<StorageService>() ? sl<StorageService>() : null,
          atomicClockService: sl.isRegistered<AtomicClockService>()
              ? sl<AtomicClockService>()
              : AtomicClockService(),
          repository: sl.isRegistered<CommunityRepository>()
              ? sl<CommunityRepository>()
              : null,
          entitySignatureService: sl.isRegistered<EntitySignatureService>()
              ? sl<EntitySignatureService>()
              : null,
        ));
  }
  if (!sl.isRegistered<ClubService>()) {
    sl.registerLazySingleton<ClubService>(() => ClubService(
          communityService: sl<CommunityService>(),
          storageService:
              sl.isRegistered<StorageService>() ? sl<StorageService>() : null,
        ));
  }
  sl.registerLazySingleton(() => MessagingRuntimeService(
        personalityAgentChatService: sl<PersonalityAgentChatService>(),
        friendChatService: sl<FriendChatService>(),
        communityChatService: sl<CommunityChatService>(),
        communityService: sl<CommunityService>(),
        clubService: sl<ClubService>(),
        adminSupportChatService: sl<AdminSupportChatService>(),
        eventChatService: sl<EventChatService>(),
        directMatchService: sl<DirectMatchService>(),
        retentionService: sl<BhamMessagingRetentionService>(),
      ));

  // Anonymous Communication Protocol (Phase 14: Signal Protocol ready)
  sl.registerLazySingleton(() => ai2ai.AnonymousCommunicationProtocol(
        encryptionService: sl<MessageEncryptionService>(),
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        supabase:
            sl.isRegistered<SupabaseClient>() ? sl<SupabaseClient>() : null,
        atomicClock: sl<AtomicClockService>(),
        anonymizationService: sl<UserAnonymizationService>(),
        supabaseService:
            sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
      ));
  sl.registerLazySingleton<LegacyAi2AiExchangeTransportAdapter>(
    () => AnonymousAi2AiExchangeTransportAdapter(
      protocol: sl<ai2ai.AnonymousCommunicationProtocol>(),
    ),
  );
  sl.registerLazySingleton<LegacyConversationTransportAdapter>(
    () => AnonymousConversationTransportAdapter(
      protocol: sl<ai2ai.AnonymousCommunicationProtocol>(),
    ),
  );
  sl.registerLazySingleton<LegacyProtocolCodecAdapter>(
    () => Ai2AiProtocolCodecAdapter(
      protocol: sl<AI2AIProtocol>(),
    ),
  );
  sl.registerLazySingleton(() => ConversationOrchestrationLane(
        transportAdapter: sl<LegacyConversationTransportAdapter>(),
      ));

  // Business-Expert Chat Service (AI2AI routing)
  sl.registerLazySingleton(() => BusinessExpertChatServiceAI2AI(
        conversationOrchestrationLane: sl<ConversationOrchestrationLane>(),
        encryptionService: sl<MessageEncryptionService>(),
        businessService: sl<BusinessAccountService>(),
        agentIdService: sl<AgentIdService>(),
        humanLanguageBoundaryReviewLane: sl<HumanLanguageBoundaryReviewLane>(),
        ai2aiChatEventIntakeService: sl<Ai2AiChatEventIntakeService>(),
      ));

  // Business-Business Chat Service (AI2AI routing)
  sl.registerLazySingleton(() => BusinessBusinessChatServiceAI2AI(
        conversationOrchestrationLane: sl<ConversationOrchestrationLane>(),
        encryptionService: sl<MessageEncryptionService>(),
        businessService: sl<BusinessAccountService>(),
        agentIdService: sl<AgentIdService>(),
        humanLanguageBoundaryReviewLane: sl<HumanLanguageBoundaryReviewLane>(),
        ai2aiChatEventIntakeService: sl<Ai2AiChatEventIntakeService>(),
      ));

  // Business-Expert Outreach Service (vibe-based matching)
  sl.registerLazySingleton(() => BusinessExpertOutreachService(
        partnershipService: sl<PartnershipService>(),
        chatService: sl<BusinessExpertChatServiceAI2AI>(),
      ));

  // Business-Business Outreach Service (partnership discovery)
  sl.registerLazySingleton(() => BusinessBusinessOutreachService(
        partnershipService: sl<PartnershipService>(),
        businessService: sl<BusinessAccountService>(),
        chatService: sl<BusinessBusinessChatServiceAI2AI>(),
      ));

  // Business Member Service (multi-user support)
  sl.registerLazySingleton(() => BusinessMemberService(
        businessAccountService: sl<BusinessAccountService>(),
      ));

  // Business Shared Agent Service (neural network of agents)
  sl.registerLazySingleton(() => BusinessSharedAgentService(
        businessAccountService: sl<BusinessAccountService>(),
        memberService: sl<BusinessMemberService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));

  // Social Media Vibe Analyzer
  sl.registerLazySingleton(() => SocialMediaVibeAnalyzer());

  // Onboarding & Agent Creation Services
  sl.registerLazySingleton(() => OnboardingDataService(
        agentIdService: sl<AgentIdService>(),
        onboardingAggregationService:
            null, // Will be resolved lazily if available
      ));

  // Onboarding suggestion event store (provenance + user actions during onboarding).
  sl.registerLazySingleton(() => OnboardingSuggestionEventStore(
        agentIdService: sl<AgentIdService>(),
      ));

  // Post-install bootstrap: builds local system prompt/memory from onboarding signals.
  sl.registerLazySingleton(() => LocalLlmPostInstallBootstrapService(
        agentIdService: sl<AgentIdService>(),
        onboardingDataService: sl<OnboardingDataService>(),
        suggestionEventStore: sl<OnboardingSuggestionEventStore>(),
      ));

  // Phase 8.5: Onboarding Place List Generator
  sl.registerLazySingleton<OnboardingPlaceListGenerator>(
    () => OnboardingPlaceListGenerator(
      placesDataSource: sl<GooglePlacesDataSource>(),
    ),
  );

  // Onboarding Recommendation Service
  sl.registerLazySingleton(() => OnboardingRecommendationService(
        agentIdService: sl<AgentIdService>(),
      ));

  // Phase 19.18: Quantum Group Matching System
  // Section GM.2: Group Formation Service
  sl.registerLazySingleton<GroupFormationService>(
    () => GroupFormationService(
      deviceDiscovery: sl<DeviceDiscoveryService>(),
      atomicClock: sl<AtomicClockService>(),
      agentIdService: sl<AgentIdService>(),
      knotStorage: sl<KnotStorageService>(),
      knotCompatibilityService:
          sl.isRegistered<CrossEntityCompatibilityService>()
              ? sl<CrossEntityCompatibilityService>()
              : null,
      personalityLearning: sl<PersonalityLearning>(),
      socialDiscovery: sl.isRegistered<SocialMediaDiscoveryService>()
          ? sl<SocialMediaDiscoveryService>()
          : null,
      orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
          ? sl<VibeConnectionOrchestrator>()
          : null,
      meshService: sl.isRegistered<AdaptiveMeshNetworkingService>()
          ? sl<AdaptiveMeshNetworkingService>()
          : null,
    ),
  );

  // Unified Evolution Orchestrator
  // Coordinates all evolution-related activities across the SPOTS ecosystem
  sl.registerLazySingleton<UnifiedEvolutionOrchestrator>(() {
    final personalityLearning = sl<PersonalityLearning>();
    final agentIdService = sl<AgentIdService>();
    final knotEvolutionCoordinator =
        sl.isRegistered<KnotEvolutionCoordinatorService>()
            ? sl<KnotEvolutionCoordinatorService>()
            : null;
    final quantumMatchingLearning =
        sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null;
    final continuousLearningOrchestrator =
        sl.isRegistered<ContinuousLearningOrchestrator>()
            ? sl<ContinuousLearningOrchestrator>()
            : null;
    final ai2aiLearning =
        sl.isRegistered<AI2AILearning>() ? sl<AI2AILearning>() : null;

    return UnifiedEvolutionOrchestrator(
      personalityLearning: personalityLearning,
      agentIdService: agentIdService,
      knotEvolutionCoordinator: knotEvolutionCoordinator,
      quantumMatchingLearning: quantumMatchingLearning,
      continuousLearningOrchestrator: continuousLearningOrchestrator,
      ai2aiLearning: ai2aiLearning,
    );
  });

  // Initialize Unified Evolution Orchestrator after registration
  // This sets up the evolution callback to coordinate all evolution systems
  Future.microtask(() async {
    if (sl.isRegistered<UnifiedEvolutionOrchestrator>()) {
      try {
        final orchestrator = sl<UnifiedEvolutionOrchestrator>();
        await orchestrator.initialize();
        logger.debug('✅ [DI-AI] UnifiedEvolutionOrchestrator initialized');
      } catch (e) {
        logger.warning(
            '⚠️ [DI-AI] Failed to initialize UnifiedEvolutionOrchestrator: $e');
      }
    }
  });

  // ============================================================
  // v0.2 Physical Connection Sprint Services
  // ============================================================

  if (!sl.isRegistered<VibeKernelPersistenceService>()) {
    final persistenceService = VibeKernelPersistenceService(
      storage: sl<StorageService>(),
    );
    await persistenceService.restore();
    sl.registerSingleton<VibeKernelPersistenceService>(persistenceService);
    if (!sl.isRegistered<CanonicalVibeMigrationService>()) {
      final migrationService = CanonicalVibeMigrationService(
        storage: sl<StorageService>(),
        persistenceService: persistenceService,
      );
      await migrationService.runIfNeeded();
      sl.registerSingleton<CanonicalVibeMigrationService>(migrationService);
    }
  }

  if (!sl.isRegistered<CanonicalVibeProjectionService>()) {
    sl.registerLazySingleton<CanonicalVibeProjectionService>(
      () => CanonicalVibeProjectionService(
        agentIdService: sl<AgentIdService>(),
      ),
    );
  }

  if (!sl.isRegistered<HierarchicalLocalityVibeProjector>()) {
    sl.registerLazySingleton<HierarchicalLocalityVibeProjector>(
      () => HierarchicalLocalityVibeProjector(),
    );
  }

  if (!sl.isRegistered<ScopedContextVibeProjector>()) {
    sl.registerLazySingleton<ScopedContextVibeProjector>(
      () => ScopedContextVibeProjector(),
    );
  }

  if (!sl.isRegistered<SemanticKnowledgeStore>()) {
    sl.registerLazySingleton<SemanticKnowledgeStore>(
        () => InMemorySemanticStore());
  }

  if (!sl.isRegistered<AirGapContract>()) {
    sl.registerLazySingleton<AirGapContract>(
        () => TupleExtractionEngine(sl<SemanticKnowledgeStore>()));
  }

  if (!sl.isRegistered<EventPlanningTelemetryService>()) {
    sl.registerLazySingleton<EventPlanningTelemetryService>(
      () => EventPlanningTelemetryService(
        prefs: sl<SharedPreferencesCompat>(),
      ),
    );
  }

  if (!sl.isRegistered<EventPlanningIntakeAdapter>()) {
    sl.registerLazySingleton<EventPlanningIntakeAdapter>(
      () => EventPlanningIntakeAdapter(
        sl<AirGapContract>(),
        whatIngestion: sl.isRegistered<WhatRuntimeIngestionService>()
            ? sl<WhatRuntimeIngestionService>()
            : null,
        geoHierarchyService: sl.isRegistered<GeoHierarchyService>()
            ? sl<GeoHierarchyService>()
            : null,
        telemetryService: sl.isRegistered<EventPlanningTelemetryService>()
            ? sl<EventPlanningTelemetryService>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<BetaEventPlanningSuggestionService>()) {
    sl.registerLazySingleton<BetaEventPlanningSuggestionService>(
      () => const BetaEventPlanningSuggestionService(),
    );
  }

  if (!sl.isRegistered<EventLearningSignalService>()) {
    sl.registerLazySingleton<EventLearningSignalService>(
      () => EventLearningSignalService(
        continuousLearningSystem: sl.isRegistered<ContinuousLearningSystem>()
            ? sl<ContinuousLearningSystem>()
            : null,
        whatIngestion: sl.isRegistered<WhatRuntimeIngestionService>()
            ? sl<WhatRuntimeIngestionService>()
            : null,
        airGap: sl<AirGapContract>(),
      ),
    );
  }

  if (!sl.isRegistered<EventHostDebriefService>()) {
    sl.registerLazySingleton<EventHostDebriefService>(
      () => EventHostDebriefService(
        eventService: sl<ExpertiseEventService>(),
        successAnalysisService: sl<EventSuccessAnalysisService>(),
        learningSignalService: sl<EventLearningSignalService>(),
        telemetryService: sl.isRegistered<EventPlanningTelemetryService>()
            ? sl<EventPlanningTelemetryService>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<GovernanceKernelService>()) {
    sl.registerLazySingleton<GovernanceKernelService>(
        () => GovernanceKernelService());
  }

  if (!sl.isRegistered<PheromoneMeshRoutingService>()) {
    sl.registerLazySingleton<PheromoneMeshRoutingService>(
      () => PheromoneMeshRoutingService(
          governanceKernel: sl<GovernanceKernelService>()),
    );
  }

  if (!sl.isRegistered<SmartPassiveCollectionService>()) {
    sl.registerLazySingleton<SmartPassiveCollectionService>(
      () => SmartPassiveCollectionService(
        motionService: sl<DeviceMotionService>(),
        deviceDiscoveryService: sl<DeviceDiscoveryService>(),
      ),
    );
  }

  if (!sl.isRegistered<PassiveDwellRealityLearningService>()) {
    sl.registerLazySingleton<PassiveDwellRealityLearningService>(
      () => PassiveDwellRealityLearningService(
        ambientSocialLearningService: sl<AmbientSocialRealityLearningService>(),
      ),
    );
  }

  if (!sl.isRegistered<DwellEventIntakeAdapter>()) {
    sl.registerLazySingleton<DwellEventIntakeAdapter>(
      () => DwellEventIntakeAdapter(
        sl<AirGapContract>(),
        whatIngestion: sl.isRegistered<WhatRuntimeIngestionService>()
            ? sl<WhatRuntimeIngestionService>()
            : null,
        realityLearningService: sl<PassiveDwellRealityLearningService>(),
      ),
    );
  }
  if (!sl.isRegistered<PassiveKernelSignalIntakeLane>()) {
    sl.registerLazySingleton<PassiveKernelSignalIntakeLane>(
      () => PassiveKernelSignalIntakeLane(
        passiveCollectionService: sl<SmartPassiveCollectionService>(),
        dwellEventIntakeAdapter: sl<DwellEventIntakeAdapter>(),
      ),
    );
  }
  if (!sl.isRegistered<HeadlessBackgroundRuntimeCoordinator>()) {
    sl.registerLazySingleton<HeadlessBackgroundRuntimeCoordinator>(
      () => HeadlessBackgroundRuntimeCoordinator(
        bootstrapService: sl<HeadlessAvraiOsBootstrapService>(),
        meshLane: sl<MeshBackgroundExecutionLane>(),
        ai2aiLane: sl<Ai2AiBackgroundExecutionLane>(),
        passiveLane: sl<PassiveKernelSignalIntakeLane>(),
        segmentLifecycleLane: sl<MeshSegmentLifecycleRuntimeLane>(),
        featureFlagService: sl.isRegistered<FeatureFlagService>()
            ? sl<FeatureFlagService>()
            : null,
        platformWakePort: sl.isRegistered<BackgroundPlatformWakePort>()
            ? sl<BackgroundPlatformWakePort>()
            : null,
        runRecordStore: sl.isRegistered<BackgroundWakeExecutionRunRecordStore>()
            ? sl<BackgroundWakeExecutionRunRecordStore>()
            : null,
        ambientSocialLearningService:
            sl.isRegistered<AmbientSocialRealityLearningService>()
                ? sl<AmbientSocialRealityLearningService>()
                : null,
        connectivity: sl<Connectivity>(),
        foregroundRuntimeSignalLane:
            sl.isRegistered<Ai2AiRendezvousRuntimeSignalLane>()
                ? sl<Ai2AiRendezvousRuntimeSignalLane>()
                : null,
      ),
    );
  }

  if (!sl.isRegistered<ArchetypeLearningRuntime>()) {
    sl.registerLazySingleton<ArchetypeLearningRuntime>(
      () => KnotBackedArchetypeLearningRuntime(),
    );
  }

  if (!sl.isRegistered<BatteryAdaptiveBatchScheduler>()) {
    sl.registerLazySingleton<BatteryAdaptiveBatchScheduler>(
      () => BatteryAdaptiveBatchScheduler(),
    );
  }

  if (!sl.isRegistered<AdaptiveDigestionJob>()) {
    sl.registerLazySingleton<AdaptiveDigestionJob>(
      () => AdaptiveDigestionJob(
        sl<SmartPassiveCollectionService>(),
        sl<DwellEventIntakeAdapter>(),
        sl<AppDatabase>(),
        sl<PheromoneMeshRoutingService>(),
        sl<ArchetypeLearningRuntime>(),
        sl<LanguageRuntimeService>(),
        sl<SharedPreferences>(),
      ),
    );

    // Avoid test-time side effects when DI is being bootstrapped for integration suites.
    if (_shouldAutoScheduleAdaptiveDigestion &&
        _canScheduleAdaptiveDigestionJob(sl)) {
      Future.microtask(() {
        sl<BatteryAdaptiveBatchScheduler>()
            .scheduleJob(sl<AdaptiveDigestionJob>());
      });
    }
  }

  if (!sl.isRegistered<LocalityFederatedExchangeService>()) {
    sl.registerLazySingleton<LocalityFederatedExchangeService>(
      () => LocalityFederatedExchangeService(),
    );
  }

  if (!sl.isRegistered<LocalityFederatedExchangeJob>()) {
    sl.registerLazySingleton<LocalityFederatedExchangeJob>(
      () => LocalityFederatedExchangeJob(
        sl<LocalityFederatedExchangeService>(),
        sl<AppDatabase>(),
      ),
    );

    // Avoid test-time side effects when DI is being bootstrapped for integration suites.
    if (_shouldAutoScheduleAdaptiveDigestion &&
        _canScheduleLocalityFederatedExchangeJob(sl)) {
      Future.microtask(() {
        sl<BatteryAdaptiveBatchScheduler>()
            .scheduleJob(sl<LocalityFederatedExchangeJob>());
      });
    }
  }

  // Integrations
  if (!sl.isRegistered<SpotifyAirgapIntegrationService>()) {
    sl.registerLazySingleton<SpotifyAirgapIntegrationService>(
      () => SpotifyAirgapIntegrationService(
        airGapEngine: sl<AirGapContract>() as TupleExtractionEngine,
        knowledgeStore: sl<SemanticKnowledgeStore>(),
        whatIngestion: sl.isRegistered<WhatRuntimeIngestionService>()
            ? sl<WhatRuntimeIngestionService>()
            : null,
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
      ),
    );
  }

  // ============================================================
  // Phase 1.5E: Beta Markov Engagement Predictor
  // Bridge to Phase 5 TransitionPredictor — same interface, zero-code swap.
  // FeatureFlagService.neural_transition_predictor_enabled flips to neural
  // when Phase 5 is trained. All callers depend on EngagementPhasePredictor.
  // ============================================================

  if (!sl.isRegistered<SwarmPriorLoader>()) {
    sl.registerLazySingleton<SwarmPriorLoader>(() => SwarmPriorLoader());
  }

  if (!sl.isRegistered<MarkovTransitionStore>()) {
    sl.registerLazySingleton<MarkovTransitionStore>(
      () => MarkovTransitionStore(
        prefs: sl<SharedPreferences>(),
        priorLoader: sl<SwarmPriorLoader>(),
      ),
    );
  }

  // Register EngagementPhasePredictor via feature flag.
  // Default: MarkovEngagementPredictor (beta).
  // Phase 5 swap: register NeuralTransitionPredictor and flip
  //   FeatureFlagService.neural_transition_predictor_enabled = true.
  if (!sl.isRegistered<EngagementPhasePredictor>()) {
    sl.registerLazySingleton<EngagementPhasePredictor>(
      () => MarkovEngagementPredictor(
        store: sl<MarkovTransitionStore>(),
        atomicClock: sl<AtomicClockService>(),
      ),
    );
  }

  logger.debug('✅ [DI-AI] AI/network services registered');
}
