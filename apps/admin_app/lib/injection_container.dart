import 'package:get_it/get_it.dart';
import 'package:avrai_admin_app/auth/auth_bloc.dart';
import 'package:avrai_admin_app/bootstrap/runtime_bootstrap.dart';
import 'package:avrai_admin_app/bootstrap/engine_bootstrap.dart';
import 'package:avrai_admin_app/bootstrap/app_bootstrap.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_core.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_payment.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_admin.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_knot.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_quantum.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_ai.dart';
import 'package:avrai_admin_app/di/registrars/injection_container_predictive_outreach.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/kernel/locality/legacy/dart_locality_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/locality/legacy/disabled_locality_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/locality/legacy/where_kernel_ingestion_adapter.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_prior_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_cloud_update_gateway.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_inference_head.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_infrastructure_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_memory.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_library_manager.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_admin_diagnostics_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_priority.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_sync_payload_builder.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_native_training_bridge.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_projection_service.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_runtime_context.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_syscall_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_where_kernel_adapter.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_transport_support.dart';
import 'package:avrai_runtime_os/kernel/locality/locality_training_contract.dart';
import 'package:avrai_runtime_os/kernel/locality/synthetic_locality_training_service.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_orchestrator.dart';
import 'package:avrai_runtime_os/kernel/os/functional_kernel_os.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_host.dart';
import 'package:avrai_runtime_os/kernel/os/headless_avrai_os_bootstrap_service.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_prong_ports.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_admin_service.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_conformance_service.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_outcome_attribution_lane.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_bundle_store.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_incident_recorder.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_root_cause_index.dart';
import 'package:avrai_runtime_os/kernel/os/kernel_telemetry_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/headless_avrai_os_availability_service.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/kernel/who/legacy/dart_who_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/legacy/disabled_who_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/who/who_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/who/who_library_manager.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_priority.dart';
import 'package:avrai_runtime_os/kernel/who/who_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_priority.dart';
import 'package:avrai_runtime_os/kernel/what/what_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_ingestion_service.dart';
import 'package:avrai_runtime_os/kernel/what/what_runtime_recovery_service.dart';
import 'package:avrai_runtime_os/kernel/when/legacy/dart_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/when/legacy/disabled_when_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/when/when_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/when/when_library_manager.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/how/legacy/dart_how_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/how/legacy/disabled_how_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/how/how_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/how/how_library_manager.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_priority.dart';
import 'package:avrai_runtime_os/kernel/how/how_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/why/legacy/dart_why_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/why/legacy/disabled_why_fallback_kernel.dart';
import 'package:avrai_runtime_os/kernel/why/why_kernel_contract.dart';
import 'package:avrai_runtime_os/kernel/why/why_library_manager.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_kernel_stub.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_priority.dart';
import 'package:avrai_runtime_os/kernel/why/why_native_startup_gate.dart';
import 'package:avrai_runtime_os/kernel/what/what_kernel_bootstrap.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';

// Database
// Note: AppDatabase (Drift) is initialized in registerDeviceSyncServices() (injection_container_device_sync.dart)

// Auth
import 'package:avrai_runtime_os/data/datasources/remote/auth_remote_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/auth_remote_datasource_impl.dart';
import 'package:avrai_runtime_os/data/datasources/local/auth_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/auth_drift_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/auth_repository_impl.dart';
import 'package:avrai_runtime_os/domain/repositories/auth_repository.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_apple_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_in_with_google_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_up_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/sign_out_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/auth/update_password_usecase.dart';

// Spots
import 'package:avrai_runtime_os/data/datasources/remote/spots_remote_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/spots_remote_datasource_impl.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/spots_drift_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/spots_repository_impl.dart';
import 'package:avrai_runtime_os/domain/repositories/spots_repository.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/get_spots_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/get_spots_from_respected_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/create_spot_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/update_spot_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/spots/delete_spot_usecase.dart';

// Lists
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/lists_remote_datasource_impl.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_local_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/local/lists_drift_datasource.dart';
import 'package:avrai_runtime_os/data/repositories/lists_repository_impl.dart';
import 'package:avrai_runtime_os/domain/repositories/lists_repository.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/get_lists_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/create_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/update_list_usecase.dart';
import 'package:avrai_runtime_os/domain/usecases/lists/delete_list_usecase.dart';
import 'package:avrai_runtime_os/services/lists/list_analytics_service.dart';
import 'package:avrai_runtime_os/services/lists/list_sync_service.dart';

// Hybrid Search (Phase 2: External Data Integration)
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/openstreetmap_datasource.dart';
import 'package:avrai_runtime_os/data/datasources/remote/openstreetmap_datasource_impl.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_search_repository.dart';
import 'package:avrai_runtime_os/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:avrai_runtime_os/controllers/reservation_creation_controller.dart';

// Phase 2: Missing Services
import 'package:avrai_runtime_os/services/admin/role_management_service.dart';
import 'package:avrai_core/models/user/user_role.dart';
// Note: SearchCacheService, AISearchSuggestionsService, CommunityValidationService,
// PerformanceMonitor, SecurityValidator, and DeploymentValidator are now registered
// in registerCoreServices() (injection_container_core.dart)
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_search_suggestions_service.dart';

// Patent #30: Quantum Atomic Clock System
import 'package:avrai_core/services/atomic_clock_service.dart';

// Organic Spot Discovery (learns locations from behavior patterns)
import 'package:avrai_runtime_os/services/places/organic_spot_discovery_service.dart';

// Patent #31: Topological Knot Theory for Personality Representation
// Note: Most knot services are registered in registerKnotServices() (injection_container_knot.dart)
// Import only services needed in main container (for CommunityService dependencies)
import 'package:avrai_runtime_os/runtime_api.dart';
// Quantum Enhancement Implementation Plan - Phase 2.1: Decoherence Tracking
// Quantum Enhancement Implementation Plan - Phase 3.1: Quantum Prediction Features
// Quantum Enhancement Implementation Plan - Phase 4.1: Quantum Satisfaction Enhancement
// Feature Flag System
// Supabase Backend Integration
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/network/enhanced_connectivity_service.dart';
// Note: LargeCityDetectionService, NeighborhoodBoundaryService, and GeographicScopeService
// are now registered in registerCoreServices() (injection_container_core.dart)
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
// Business Chat Services (AI2AI routing)
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_recorder_service_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/ledger_receipts_service_v0.dart';
import 'package:avrai_runtime_os/services/ledgers/proof_run_service_v0.dart';
import 'package:avrai_runtime_os/services/business/business_shared_agent_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
// Onboarding & Agent Creation Services (Phase 1: Foundation)
import 'package:avrai_runtime_os/services/onboarding/onboarding_data_service.dart';
import 'package:avrai_runtime_os/services/network/edge_function_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_aggregation_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_enrichment_service.dart';
import 'package:avrai_runtime_os/services/social_media/social_media_connection_service.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_place_list_generator.dart';
import 'package:avrai_runtime_os/services/onboarding/onboarding_recommendation_service.dart';
import 'package:avrai_runtime_os/services/matching/preferences_profile_service.dart';
import 'package:avrai_runtime_os/services/events/event_recommendation_service.dart'
    as event_rec_service;
// Controllers (Phase 8.11)
import 'package:avrai_runtime_os/controllers/onboarding_flow_controller.dart';
import 'package:avrai_runtime_os/controllers/agent_initialization_controller.dart';
import 'package:avrai_runtime_os/controllers/event_creation_controller.dart';
import 'package:avrai_runtime_os/controllers/social_media_data_collection_controller.dart';
import 'package:avrai_runtime_os/controllers/payment_processing_controller.dart';
import 'package:avrai_runtime_os/controllers/ai_recommendation_controller.dart';
import 'package:avrai_runtime_os/controllers/business_onboarding_controller.dart';
import 'package:avrai_runtime_os/controllers/event_attendance_controller.dart';
import 'package:avrai_runtime_os/controllers/list_creation_controller.dart';
import 'package:avrai_runtime_os/controllers/checkout_controller.dart';
import 'package:avrai_runtime_os/controllers/event_cancellation_controller.dart';
import 'package:avrai_runtime_os/controllers/partnership_checkout_controller.dart';
import 'package:avrai_runtime_os/controllers/partnership_proposal_controller.dart';
import 'package:avrai_runtime_os/controllers/profile_update_controller.dart';
import 'package:avrai_runtime_os/controllers/sponsorship_checkout_controller.dart';
import 'package:avrai_runtime_os/services/events/cancellation_service.dart';
import 'package:avrai_runtime_os/services/payment/tax_document_storage_service.dart';
import 'package:avrai_runtime_os/services/fraud/dispute_resolution_service.dart';
import 'package:avrai_runtime_os/services/disputes/dispute_evidence_storage_service.dart';
import 'package:avrai_runtime_os/controllers/sync_controller.dart';
import 'package:avrai_runtime_os/ai/quantum/quantum_vibe_engine.dart';

// Phase 19: Multi-Entity Quantum Entanglement Matching System

// Phase 15: Reservation System with Quantum Integration
import 'package:avrai_runtime_os/services/reservation/reservation_quantum_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_recommendation_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_availability_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_ticket_queue_service.dart';
// Phase 6.2 Enhancement: Knot Theory Integration
import 'package:avrai_runtime_os/services/reservation/reservation_rate_limit_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_cancellation_policy_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_dispute_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_notification_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_waitlist_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_analytics_service.dart';
import 'package:avrai_runtime_os/services/business/business_reservation_analytics_service.dart';
import 'package:avrai_runtime_os/services/recommendations/recommendation_telemetry_service.dart';
// Phase 10.1: Multi-layered Check-In System
import 'package:avrai_runtime_os/services/reservation/reservation_proximity_service.dart';
import 'package:avrai_runtime_os/services/device/wifi_fingerprint_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_check_in_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_calendar_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_recurrence_service.dart';
import 'package:avrai_runtime_os/services/reservation/reservation_sharing_service.dart';
import 'package:avrai_runtime_os/ai/event_logger.dart';
import 'package:avrai_runtime_os/services/quantum/quantum_matching_ai_learning_service.dart';
// Phase 10.1: AI2AI Mesh Integration
import 'package:avrai_runtime_os/ai2ai/connection_orchestrator.dart'
    show VibeConnectionOrchestrator;
import 'package:avrai_runtime_os/services/transport/ble/adaptive_mesh_networking_service.dart';
import 'package:avrai_runtime_os/services/network/rate_limiting_service.dart';
import 'package:avrai_runtime_os/services/events/event_learning_signal_service.dart';
import 'package:avrai_runtime_os/services/events/event_success_analysis_service.dart';
import 'package:avrai_runtime_os/controllers/quantum_matching_controller.dart';
import 'package:avrai_runtime_os/services/events/post_event_feedback_service.dart';
import 'package:http/http.dart' as http;
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
// Device Discovery & Advertising
// Single integration boundary
import 'package:avrai_network/avra_network.dart';
import 'package:avrai_runtime_os/config/supabase_config.dart';
// ML (cloud-only, simplified)
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai_runtime_os/ml/embedding_cloud_client.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/llm_service.dart';
import 'package:avrai_runtime_os/services/language/language_runtime_service.dart';
// Google Places integration
import 'package:avrai_runtime_os/services/places/google_places_cache_service.dart';
import 'package:avrai_runtime_os/services/places/google_place_id_finder_service_new.dart';
import 'package:avrai_runtime_os/services/places/google_places_sync_service.dart';
import 'package:avrai_runtime_os/data/datasources/remote/google_places_datasource_new_impl.dart';
import 'package:avrai_runtime_os/config/google_places_config.dart';
import 'package:avrai_runtime_os/services/intake/air_gap_normalizer.dart';
import 'package:avrai_runtime_os/services/intake/entity_fit_router.dart';
import 'package:avrai_runtime_os/services/intake/organizer_sync_connection_advisor.dart';
import 'package:avrai_runtime_os/services/intake/source_intake_orchestrator.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/signatures/entity_signature_service.dart';

// Admin Services (God-Mode Admin System)
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/services/business/business_service.dart';
// Payment Processing - Agent 1: Payment Processing & Revenue
import 'package:avrai_runtime_os/services/payment/payment_service.dart';
import 'package:avrai_runtime_os/services/payment/payment_event_service.dart';
import 'package:avrai_runtime_os/services/payment/revenue_split_service.dart';
import 'package:avrai_runtime_os/services/payment/refund_service.dart';
import 'package:avrai_runtime_os/services/partnerships/partnership_service.dart';
import 'package:avrai_runtime_os/services/business/sponsorship_service.dart';
import 'package:avrai_runtime_os/services/payment/product_tracking_service.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_event_service.dart';
import 'package:avrai_runtime_os/services/misc/legal_document_service.dart';
import 'package:avrai_runtime_os/services/payment/sales_tax_service.dart';
import 'package:avrai_runtime_os/services/matching/personality_sync_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_expansion_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/ai/facts_index.dart';
import 'package:avrai_runtime_os/data/repositories/hybrid_community_repository.dart';
import 'package:avrai_runtime_os/data/repositories/local_community_repository.dart';
import 'package:avrai_runtime_os/data/repositories/supabase_community_repository.dart';
import 'package:avrai_runtime_os/domain/repositories/community_repository.dart';
// Phase 12: Neural Network Implementation
import 'package:avrai_runtime_os/services/calling_score/calling_score_data_collector.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_calculator.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_baseline_metrics.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_training_data_preparer.dart';
import 'package:avrai_runtime_os/services/calling_score/calling_score_ab_testing_service.dart';
import 'package:avrai_runtime_os/ml/calling_score_neural_model.dart';
import 'package:avrai_runtime_os/services/behavior/behavior_assessment_service.dart';
import 'package:avrai_runtime_os/ml/outcome_prediction_model.dart';
import 'package:avrai_runtime_os/services/recommendations/outcome_prediction_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_gate.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_native_priority.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/kernel_governance_telemetry_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/model_version_manager.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/online_learning_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/model_retraining_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_session_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_protocol_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_platform_bridge_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_rust_wrapper_bindings.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_initialization_service.dart';
import 'package:avrai_runtime_os/services/security/hybrid_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/signal_protocol_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/secure_mapping_encryption_service.dart';
import 'package:avrai_runtime_os/services/security/security_trigger_ingress_service.dart';
import 'package:avrai_runtime_os/services/user/agent_id_migration_service.dart';
import 'package:avrai_runtime_os/services/security/mapping_key_rotation_service.dart';
import 'package:avrai_runtime_os/services/locality_agents/locality_geofence_planner.dart';
import 'package:avrai_runtime_os/services/locality_agents/os_geofence_registrar.dart';

part 'di/registrars/runtime_service_registrar.dart';
part 'di/registrars/engine_service_registrar.dart';
part 'di/registrars/app_service_registrar.dart';

final sl = GetIt.instance;

Future<void> init() async {
  const logger = AppLogger(defaultTag: 'DI', minimumLevel: LogLevel.debug);
  logger.info('🔧 [DI] Starting dependency injection initialization...');

  // Register core services first (foundational services that other modules depend on)
  // This includes: Connectivity, PermissionsPersistenceService,
  // StorageService, FeatureFlagService, Geographic services, CommunityValidationService,
  // AtomicClockService, PerformanceMonitor, SecurityValidator, DeploymentValidator,
  // SearchCacheService, AISearchSuggestionsService, UserVibeAnalyzer, and SharedPreferencesCompat
  await RuntimeBootstrap.initialize(
    sl: sl,
    registerRuntimeServices: () => registerCoreServices(sl),
  );
  logger.debug('✅ [DI] Core services registered');

  await _registerRuntimeServiceLayer(logger);

  // Note: CommunityService will be registered after Knot module (it has optional Knot dependencies)
  // Note: EventSuccessAnalysisService will be registered after Payment module (it needs PaymentService)

  // ============================================================================
  // DOMAIN MODULES
  // ============================================================================
  // Register domain-specific services in dependency order
  // See PHASE_1_7_REFACTORING_PLAN.md for details

  await _registerEngineServiceLayer(logger);

  // ============================================================================
  // INFRASTRUCTURE SERVICES (NOT in domain modules)
  // ============================================================================
  // Note: These services are foundational infrastructure and remain in main container

  await _registerAppServiceLayer(logger);
  LocalityNativeStartupGate.ensureReady(
    nativeBridge: sl<LocalityNativeInvocationBridge>(),
    policy: sl<LocalityNativeExecutionPolicy>(),
  );
  WhatNativeStartupGate.ensureReady(
    nativeBridge: sl<WhatNativeInvocationBridge>(),
    policy: sl<WhatNativeExecutionPolicy>(),
  );
  WhoNativeStartupGate.ensureReady(
    nativeBridge: sl<WhoNativeInvocationBridge>(),
    policy: sl<WhoNativeExecutionPolicy>(),
  );
  WhenNativeStartupGate.ensureReady(
    nativeBridge: sl<WhenNativeInvocationBridge>(),
    policy: sl<WhenNativeExecutionPolicy>(),
  );
  HowNativeStartupGate.ensureReady(
    nativeBridge: sl<HowNativeInvocationBridge>(),
    policy: sl<HowNativeExecutionPolicy>(),
  );
  WhyNativeStartupGate.ensureReady(
    nativeBridge: sl<WhyNativeInvocationBridge>(),
    policy: sl<WhyNativeExecutionPolicy>(),
  );

  // Note: OnboardingRecommendationService, PreferencesProfileService, EventRecommendationService,
  // EventMatchingService, SpotVibeMatchingService, OAuthDeepLinkHandler, SocialMediaConnectionService,
  // and related social media services are registered in AI module

  // Note: Quantum services are registered in Quantum module

  // Note: MessageEncryptionService is now registered BEFORE AI services (moved up to fix dependency order)
  // Note: AI/network services (chat services, business services, admin services, payment services,
  // AI learning services, etc.) are registered in their respective domain modules

  // ============================================================================
  // BACKEND INITIALIZATION
  // ============================================================================
  // Backend (Single Integration Boundary): initialize and expose avra_network
  try {
    logger.info('🔌 [DI] Initializing Supabase backend...');

    if (!SupabaseConfig.isValid) {
      logger
          .warn('⚠️ [DI] SupabaseConfig is invalid. URL or anonKey is empty.');
      logger.warn(
          '⚠️ [DI] Make sure to run with --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...');
      throw Exception('Supabase configuration is invalid');
    }

    final backend = await BackendFactory.create(
      BackendConfig.supabase(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        serviceRoleKey: SupabaseConfig.serviceRoleKey.isNotEmpty
            ? SupabaseConfig.serviceRoleKey
            : null,
        name: 'Supabase',
        isDefault: true,
      ),
    );
    logger.info('✅ [DI] Supabase backend created successfully');

    // Expose the unified backend and its components
    logger.debug('📝 [DI] Registering backend components...');
    sl.registerSingleton<BackendInterface>(backend);
    sl.registerLazySingleton<AuthBackend>(() => backend.auth);
    sl.registerLazySingleton<DataBackend>(() => backend.data);
    sl.registerLazySingleton<RealtimeBackend>(() => backend.realtime);
    logger.debug('✅ [DI] Backend components registered');

    // Register Supabase Client for language runtime services
    try {
      logger.debug('🤖 [DI] Registering language runtime service...');
      // Only register if Supabase is initialized
      try {
        final supabaseClient = Supabase.instance.client;
        sl.registerLazySingleton<SupabaseClient>(() => supabaseClient);

        // Register Edge Function Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => EdgeFunctionService(
              client: supabaseClient,
            ));
        logger.debug('✅ [DI] EdgeFunctionService registered');

        // Register Onboarding Aggregation Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => OnboardingAggregationService(
              edgeFunctionService: sl<EdgeFunctionService>(),
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] OnboardingAggregationService registered');

        // Register Social Enrichment Service (Phase 11 Section 4: Edge Mesh Functions)
        sl.registerLazySingleton(() => SocialEnrichmentService(
              edgeFunctionService: sl<EdgeFunctionService>(),
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] SocialEnrichmentService registered');

        // Register FactsIndex (Phase 11 Section 5: Retrieval + LLM Fusion)
        // Requires SupabaseClient to be available
        sl.registerLazySingleton(() => FactsIndex(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] FactsIndex registered');

        // Register Calling Score Data Collector (Phase 12 Section 1: Foundation & Data Collection)
        // Note: Register BehaviorAssessmentService first (if not already registered)
        if (!sl.isRegistered<BehaviorAssessmentService>()) {
          sl.registerLazySingleton<BehaviorAssessmentService>(
              () => BehaviorAssessmentService());
          logger.debug('✅ [DI] BehaviorAssessmentService registered');
        }

        // Register Calling Score Data Collector
        sl.registerLazySingleton(() => CallingScoreDataCollector(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
              enabled:
                  true, // Enable data collection for neural network training
            ));
        logger.debug('✅ [DI] CallingScoreDataCollector registered');

        // Register Calling Score Baseline Metrics (Phase 12 Section 1.2: Baseline Metrics)
        sl.registerLazySingleton(() => CallingScoreBaselineMetrics(
              supabase: supabaseClient,
            ));
        logger.debug('✅ [DI] CallingScoreBaselineMetrics registered');

        // Register Calling Score Neural Model (Phase 12 Section 2.1: Calling Score Prediction Model)
        // Register ModelVersionManager (Phase 12 Section 3.2.2: Model Versioning)
        sl.registerLazySingleton(() => const UrkKernelRegistryService());
        logger.debug('✅ [DI] UrkKernelRegistryService registered');
        sl.registerLazySingleton(() => KernelGovernanceTelemetryService(
              prefs: sl<SharedPreferencesCompat>(),
            ));
        logger.debug('✅ [DI] KernelGovernanceTelemetryService registered');
        sl.registerLazySingleton(() => RecommendationTelemetryService(
              prefs: sl<SharedPreferencesCompat>(),
            ));
        logger.debug('✅ [DI] RecommendationTelemetryService registered');
        sl.registerLazySingleton(() => KernelGovernanceGate(
              registryService: sl<UrkKernelRegistryService>(),
              featureFlagService: sl<FeatureFlagService>(),
              telemetryService: sl<KernelGovernanceTelemetryService>(),
              defaultMode: KernelGovernanceMode.enforce,
              nativeBridge: KernelGovernanceNativeBridgeBindings(),
              nativePolicy: const KernelGovernanceNativeExecutionPolicy(
                  requireNative: true),
              whenKernel: sl<WhenKernelContract>(),
            ));
        logger.debug('✅ [DI] KernelGovernanceGate registered');
        sl.registerLazySingleton(() => ModelVersionManager(
              kernelGovernanceGate: sl<KernelGovernanceGate>(),
            ));
        logger.debug('✅ [DI] ModelVersionManager registered');

        // Register ModelRetrainingService (Phase 12 Section 3.2.1: Backend Integration)
        sl.registerLazySingleton(() => ModelRetrainingService(
              versionManager: sl<ModelVersionManager>(),
            ));
        logger.debug('✅ [DI] ModelRetrainingService registered');

        // Register OnlineLearningService (Phase 12 Section 3.2.1: Continuous Learning)
        sl.registerLazySingleton(() => OnlineLearningService(
              supabase: supabaseClient,
              dataCollector: sl<CallingScoreDataCollector>(),
              versionManager: sl<ModelVersionManager>(),
              retrainingService: sl<ModelRetrainingService>(),
            ));
        logger.debug('✅ [DI] OnlineLearningService registered');

        sl.registerLazySingleton(() => CallingScoreNeuralModel());
        logger.debug('✅ [DI] CallingScoreNeuralModel registered');

        // Register Calling Score Training Data Preparer (Phase 12 Section 2.1)
        sl.registerLazySingleton(() => CallingScoreTrainingDataPreparer(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
              neuralModel: sl<CallingScoreNeuralModel>(),
            ));
        logger.debug('✅ [DI] CallingScoreTrainingDataPreparer registered');

        // Register Calling Score A/B Testing Service (Phase 12 Section 2.3: A/B Testing Framework)
        sl.registerLazySingleton(() => CallingScoreABTestingService(
              supabase: supabaseClient,
              agentIdService: sl<AgentIdService>(),
            ));
        logger.debug('✅ [DI] CallingScoreABTestingService registered');

        // Register Outcome Prediction Model (Phase 12 Section 3.1: Outcome Prediction Model)
        sl.registerLazySingleton(() => OutcomePredictionModel());
        logger.debug('✅ [DI] OutcomePredictionModel registered');

        // Register Outcome Prediction Service (Phase 12 Section 3.1: Outcome Prediction Model)
        sl.registerLazySingleton(() => OutcomePredictionService(
              model: sl<OutcomePredictionModel>(),
              supabase: supabaseClient,
              dataCollector: sl<CallingScoreDataCollector>(),
            ));
        logger.debug('✅ [DI] OutcomePredictionService registered');

        // Register Calling Score Calculator (Phase 12: Neural Network Implementation)
        // Phase 12 Section 2.2: Hybrid calling score calculation
        // Phase 12 Section 2.3: A/B testing integration
        // Phase 12 Section 3.1: Outcome prediction integration
        sl.registerLazySingleton(() => CallingScoreCalculator(
              behaviorAssessment: sl<BehaviorAssessmentService>(),
              dataCollector: sl<CallingScoreDataCollector>(),
              neuralModel:
                  sl<CallingScoreNeuralModel>(), // Optional: Hybrid calculation
              abTestingService:
                  sl<CallingScoreABTestingService>(), // Optional: A/B testing
              outcomePredictionService: sl<
                  OutcomePredictionService>(), // Optional: Outcome prediction
            ));
        logger.debug(
            '✅ [DI] CallingScoreCalculator registered (with neural model, A/B testing, and outcome prediction support)');

        // Register Signal Protocol Services (Phase 14: Signal Protocol Implementation - Option 1)
        sl.registerLazySingleton(() => SignalFFIBindings());
        logger.debug('✅ [DI] SignalFFIBindings registered');

        // Register Platform Bridge Bindings (Phase 14: Platform Bridge)
        // Must be registered before Rust Wrapper and Store Callbacks
        sl.registerLazySingleton(() => SignalPlatformBridgeBindings());
        logger.debug('✅ [DI] SignalPlatformBridgeBindings registered');

        // Register Rust Wrapper Bindings (Phase 14: Rust Wrapper)
        // Must be registered before Store Callbacks
        sl.registerLazySingleton(() => SignalRustWrapperBindings());
        logger.debug('✅ [DI] SignalRustWrapperBindings registered');

        sl.registerLazySingleton(() => SignalKeyManager(
              secureStorage: sl<FlutterSecureStorage>(),
              ffiBindings: sl<SignalFFIBindings>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] SignalKeyManager registered');

        sl.registerLazySingleton(() => SignalSessionManager(
              storage: sl<SecureSignalStorage>(),
              ffiBindings: sl<SignalFFIBindings>(),
              keyManager: sl<SignalKeyManager>(),
            ));
        logger.debug('✅ [DI] SignalSessionManager registered');

        // Register Store Callbacks (Phase 14: Store Callbacks)
        // Requires Platform Bridge and Rust Wrapper
        sl.registerLazySingleton(() => SignalFFIStoreCallbacks(
              keyManager: sl<SignalKeyManager>(),
              sessionManager: sl<SignalSessionManager>(),
              ffiBindings: sl<SignalFFIBindings>(),
              rustWrapper: sl<SignalRustWrapperBindings>(),
              platformBridge: sl<SignalPlatformBridgeBindings>(),
            ));
        logger.debug('✅ [DI] SignalFFIStoreCallbacks registered');

        sl.registerLazySingleton(() => SignalProtocolService(
              ffiBindings: sl<SignalFFIBindings>(),
              storeCallbacks: sl<SignalFFIStoreCallbacks>(),
              keyManager: sl<SignalKeyManager>(),
              sessionManager: sl<SignalSessionManager>(),
              atomicClock: sl<AtomicClockService>(),
            ));
        logger.debug('✅ [DI] SignalProtocolService registered');

        // Register Signal Protocol Initialization Service (Phase 14)
        // Pass dependencies for proper initialization sequence
        sl.registerLazySingleton(() => SignalProtocolInitializationService(
              signalProtocol: sl<SignalProtocolService>(),
              platformBridge: sl<SignalPlatformBridgeBindings>(),
              rustWrapper: sl<SignalRustWrapperBindings>(),
              storeCallbacks: sl<SignalFFIStoreCallbacks>(),
            ));
        logger.debug('✅ [DI] SignalProtocolInitializationService registered');

        // Register Reservation Services (Phase 15: Reservation System with Quantum Integration)
        // Phase 15 Section 15.1: Foundation - Quantum Integration
        sl.registerLazySingleton(() => ReservationQuantumService(
              atomicClock: sl<AtomicClockService>(),
              quantumVibeEngine: sl<QuantumVibeEngine>(),
              vibeAnalyzer: sl<UserVibeAnalyzer>(),
              personalityLearning: sl<PersonalityLearning>(),
              locationTimingService: sl<LocationTimingQuantumStateService>(),
              entanglementService: sl<
                  QuantumEntanglementService>(), // Optional, graceful degradation
            ));
        logger.debug('✅ [DI] ReservationQuantumService registered');

        sl.registerLazySingleton(() => ReservationService(
              atomicClock: sl<AtomicClockService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              refundService:
                  sl.isRegistered<RefundService>() ? sl<RefundService>() : null,
              cancellationPolicyService:
                  sl.isRegistered<ReservationCancellationPolicyService>()
                      ? sl<ReservationCancellationPolicyService>()
                      : null,
              // Phase 7.1: Analytics Integration
              analyticsService: sl.isRegistered<ReservationAnalyticsService>()
                  ? sl<ReservationAnalyticsService>()
                  : null,
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
            ));
        logger.debug('✅ [DI] ReservationService registered');

        sl.registerLazySingleton(() => ReservationRecommendationService(
              quantumService: sl<ReservationQuantumService>(),
              atomicClock: sl<AtomicClockService>(),
              entanglementService: sl.isRegistered<QuantumEntanglementService>()
                  ? sl<QuantumEntanglementService>()
                  : null, // Optional, graceful degradation
              eventService: sl.isRegistered<ExpertiseEventService>()
                  ? sl<ExpertiseEventService>()
                  : null,
              agentIdService: sl.isRegistered<AgentIdService>()
                  ? sl<AgentIdService>()
                  : null,
              languageRuntimeService: sl.isRegistered<LanguageRuntimeService>()
                  ? sl<LanguageRuntimeService>()
                  : null, // Phase 6.2: AI-powered suggestions
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null, // Phase 6.2: User preferences
              aiSearchService: sl.isRegistered<AISearchSuggestionsService>()
                  ? sl<AISearchSuggestionsService>()
                  : null, // Phase 6.2: Suggestion patterns
              reservationService: sl.isRegistered<ReservationService>()
                  ? sl<ReservationService>()
                  : null, // Phase 6.2: Past reservations
              // Phase 6.2 Enhancement: Knot Theory Integration
              knotService: sl.isRegistered<PersonalityKnotService>()
                  ? sl<PersonalityKnotService>()
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
              knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
                  ? sl<IntegratedKnotRecommendationEngine>()
                  : null,
            ));
        logger.debug('✅ [DI] ReservationRecommendationService registered');

        // Register Reservation Analytics Service (Phase 7.1)
        sl.registerLazySingleton(() => ReservationAnalyticsService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              // Phase 7.1 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              atomicClock: sl.isRegistered<AtomicClockService>()
                  ? sl<AtomicClockService>()
                  : null,
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              quantumService: sl.isRegistered<ReservationQuantumService>()
                  ? sl<ReservationQuantumService>()
                  : null,
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null,
            ));
        logger.debug('✅ [DI] ReservationAnalyticsService registered');

        // Register Business Reservation Analytics Service (Phase 7.2)
        sl.registerLazySingleton(() => BusinessReservationAnalyticsService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              rateLimitService: sl.isRegistered<ReservationRateLimitService>()
                  ? sl<ReservationRateLimitService>()
                  : null,
              waitlistService: sl.isRegistered<ReservationWaitlistService>()
                  ? sl<ReservationWaitlistService>()
                  : null,
              availabilityService:
                  sl.isRegistered<ReservationAvailabilityService>()
                      ? sl<ReservationAvailabilityService>()
                      : null,
              eventLogger:
                  sl.isRegistered<EventLogger>() ? sl<EventLogger>() : null,
              // Phase 7.2 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
              stringService: sl.isRegistered<KnotEvolutionStringService>()
                  ? sl<KnotEvolutionStringService>()
                  : null,
              fabricService: sl.isRegistered<KnotFabricService>()
                  ? sl<KnotFabricService>()
                  : null,
              worldsheetService: sl.isRegistered<KnotWorldsheetService>()
                  ? sl<KnotWorldsheetService>()
                  : null,
              atomicClock: sl.isRegistered<AtomicClockService>()
                  ? sl<AtomicClockService>()
                  : null,
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              quantumService: sl.isRegistered<ReservationQuantumService>()
                  ? sl<ReservationQuantumService>()
                  : null,
              personalityLearning: sl.isRegistered<PersonalityLearning>()
                  ? sl<PersonalityLearning>()
                  : null,
            ));
        logger.debug('✅ [DI] BusinessReservationAnalyticsService registered');

        // Register Reservation Creation Controller (Phase 15.1.2.5)
        sl.registerLazySingleton(() => ReservationCreationController(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              quantumController: sl<QuantumMatchingController>(),
              agentIdService: sl<AgentIdService>(),
              atomicClock: sl<AtomicClockService>(),
              availabilityService:
                  sl.isRegistered<ReservationAvailabilityService>()
                      ? sl<ReservationAvailabilityService>()
                      : null,
              rateLimitService: sl.isRegistered<ReservationRateLimitService>()
                  ? sl<ReservationRateLimitService>()
                  : null,
              ticketQueueService:
                  sl.isRegistered<ReservationTicketQueueService>()
                      ? sl<ReservationTicketQueueService>()
                      : null,
            ));
        logger.debug('✅ [DI] ReservationCreationController registered');

        // Register Reservation Availability Service (Phase 15.1.4)
        sl.registerLazySingleton(() => ReservationAvailabilityService(
              reservationService: sl<ReservationService>(),
              eventService: sl<ExpertiseEventService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationAvailabilityService registered');

        // Register Reservation Ticket Queue Service (Phase 15.1.3)
        sl.registerLazySingleton(() => ReservationTicketQueueService(
              atomicClock: sl<AtomicClockService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationTicketQueueService registered');

        // Register Rate Limiting Service (if not already registered)
        if (!sl.isRegistered<RateLimitingService>()) {
          sl.registerLazySingleton(() => RateLimitingService());
          logger.debug('✅ [DI] RateLimitingService registered');
        }

        // Register Reservation Rate Limit Service (Phase 15.1.8) - CRITICAL GAP FIX
        sl.registerLazySingleton(() => ReservationRateLimitService(
              rateLimitingService: sl<RateLimitingService>(),
              agentIdService: sl<AgentIdService>(),
              reservationService: sl<ReservationService>(),
            ));
        logger.debug('✅ [DI] ReservationRateLimitService registered');

        // Register Reservation Cancellation Policy Service (Phase 15.1.5)
        sl.registerLazySingleton(() => ReservationCancellationPolicyService(
              reservationService: sl<ReservationService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
            ));
        logger.debug('✅ [DI] ReservationCancellationPolicyService registered');

        // Register Reservation Dispute Service (Phase 15.1.6)
        sl.registerLazySingleton(() => ReservationDisputeService(
              reservationService: sl<ReservationService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              paymentService: sl.isRegistered<PaymentService>()
                  ? sl<PaymentService>()
                  : null,
              refundService:
                  sl.isRegistered<RefundService>() ? sl<RefundService>() : null,
            ));
        logger.debug('✅ [DI] ReservationDisputeService registered');

        // Register Reservation Notification Service (Phase 15.1.7)
        sl.registerLazySingleton(() => ReservationNotificationService(
              supabaseService: sl<SupabaseService>(),
              storageService: sl<StorageService>(),
            ));
        logger.debug('✅ [DI] ReservationNotificationService registered');

        // Register Reservation Waitlist Service (Phase 15.1.9) - CRITICAL GAP FIX
        sl.registerLazySingleton(() => ReservationWaitlistService(
              atomicClock: sl<AtomicClockService>(),
              agentIdService: sl<AgentIdService>(),
              storageService: sl<StorageService>(),
              supabaseService: sl<SupabaseService>(),
              notificationService:
                  sl.isRegistered<ReservationNotificationService>()
                      ? sl<ReservationNotificationService>()
                      : null,
            ));
        logger.debug('✅ [DI] ReservationWaitlistService registered');

        // Phase 10.1: Multi-layered Check-In System Services
        // Register Reservation Proximity Service (no dependencies)
        sl.registerLazySingleton(() => ReservationProximityService());
        logger.debug('✅ [DI] ReservationProximityService registered');

        // Register WiFi Fingerprint Service (no dependencies)
        sl.registerLazySingleton(() => WiFiFingerprintService());
        logger.debug('✅ [DI] WiFiFingerprintService registered');

        // Register Reservation Check-In Service (Phase 10.1: Full knot/quantum/AI2AI integration)
        sl.registerLazySingleton(() => ReservationCheckInService(
              reservationService: sl<ReservationService>(),
              proximityService: sl<ReservationProximityService>(),
              wifiService: sl<WiFiFingerprintService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
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
              // Optional AI2AI mesh learning (graceful degradation if not available)
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              // Optional Signal Protocol services (graceful degradation if not available)
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              orchestrator: sl.isRegistered<VibeConnectionOrchestrator>()
                  ? sl<VibeConnectionOrchestrator>()
                  : null,
              meshService: sl.isRegistered<AdaptiveMeshNetworkingService>()
                  ? sl<AdaptiveMeshNetworkingService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationCheckInService registered (Phase 10.1: Full integration)');

        // Register Reservation Calendar Service (Phase 10.2: Calendar integration with full AVRAI integration)
        sl.registerLazySingleton(() => ReservationCalendarService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
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
              // Optional AI2AI mesh learning (graceful degradation if not available)
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              // Optional Signal Protocol services (graceful degradation if not available)
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationCalendarService registered (Phase 10.2: Full AVRAI integration)');

        // Phase 10.3: Recurring Reservations Service
        sl.registerLazySingleton(() => ReservationRecurrenceService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
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
              // Optional AI2AI services
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
              // Optional analytics
              analyticsService: sl.isRegistered<ReservationAnalyticsService>()
                  ? sl<ReservationAnalyticsService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationRecurrenceService registered (Phase 10.3: Full AVRAI integration)');

        // Phase 10.4: Reservation Sharing & Transfer Service
        sl.registerLazySingleton(() => ReservationSharingService(
              reservationService: sl<ReservationService>(),
              quantumService: sl<ReservationQuantumService>(),
              agentIdService: sl<AgentIdService>(),
              personalityLearning: sl<PersonalityLearning>(),
              atomicClock: sl<AtomicClockService>(),
              // Optional knot services (graceful degradation if not available)
              knotOrchestrator: sl.isRegistered<KnotOrchestratorService>()
                  ? sl<KnotOrchestratorService>()
                  : null,
              knotStorage: sl.isRegistered<KnotStorageService>()
                  ? sl<KnotStorageService>()
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
              // Optional AI2AI services
              aiLearningService:
                  sl.isRegistered<QuantumMatchingAILearningService>()
                      ? sl<QuantumMatchingAILearningService>()
                      : null,
              encryptionService: sl.isRegistered<HybridEncryptionService>()
                  ? sl<HybridEncryptionService>()
                  : null,
            ));
        logger.debug(
            '✅ [DI] ReservationSharingService registered (Phase 10.4: Full AVRAI integration)');

        // Register the legacy language runtime adapter. Kernel consumers should
        // prefer the language-kernel stack for semantics.
        sl.registerLazySingleton<LanguageRuntimeService>(
            () => LanguageRuntimeService(
                  supabaseClient,
                  connectivity: sl<Connectivity>(),
                ));
        sl.registerLazySingleton<LLMService>(
            () => sl<LanguageRuntimeService>());
        logger.debug('✅ [DI] Language runtime service registered');
      } catch (e) {
        logger.warn(
            '⚠️ [DI] Supabase not initialized, skipping language runtime registration');
      }
    } catch (e, stackTrace) {
      logger
          .warn('⚠️ [DI] Language runtime registration failed (optional): $e');
      logger.debug('Stack trace: $stackTrace');
      // Language runtime optional - app can work without it
    }
  } catch (e, stackTrace) {
    logger.error('❌ [DI] Backend initialization failed', error: e);
    logger.debug('Stack trace: $stackTrace');
    // Continue without backend on web if initialization fails
  }

  logger.info('✅ [DI] Dependency injection initialization complete');

  // ===========================
  // Cloud Embeddings (Simplified - No ONNX)
  // ===========================
  // Note: Embeddings are now cloud-only via Supabase Edge Function
  // ONNX infrastructure removed - use Gemini/cloud embeddings instead
  try {
    // Only register if Supabase is initialized
    try {
      final supabaseClient = Supabase.instance.client;
      sl.registerLazySingleton<EmbeddingCloudClient>(
          () => EmbeddingCloudClient(client: supabaseClient));
    } catch (_) {
      logger.warn(
          '⚠️ [DI] Supabase not initialized, skipping EmbeddingCloudClient registration');
    }
  } catch (_) {
    // Embeddings optional - app works without them
  }

  _registerAppPresentationLayer();
}
