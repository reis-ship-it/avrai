// ignore_for_file: deprecated_member_use

import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/ai/ai2ai_learning.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/services/business/business_auth_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_god_mode_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_communication_service.dart';
import 'package:avrai_runtime_os/services/admin/forecast_kernel_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/remote_source_health_service.dart';
import 'package:avrai_runtime_os/services/admin/signature_health_admin_service.dart';
import 'package:avrai_runtime_os/services/admin/temporal_kernel_admin_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_control_plane_service.dart';
import 'package:avrai_runtime_os/kernel/service_contracts/urk_kernel_registry_service.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/services/business/business_account_service.dart';
import 'package:avrai_runtime_os/ml/predictive_analytics.dart';
import 'package:avrai_runtime_os/monitoring/connection_monitor.dart';
import 'package:avrai_runtime_os/monitoring/network_activity_monitor.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_announce_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_custody_outbox.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_interface_registry.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_route_ledger.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_credential_refresh_service.dart';
import 'package:avrai_runtime_os/services/transport/mesh/mesh_segment_revocation_store.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_runtime_state_frame_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai2ai_rendezvous_scheduler.dart';
import 'package:avrai_runtime_os/services/passive_collection/passive_dwell_reality_learning_service.dart';
import 'package:avrai_runtime_os/services/background/background_wake_execution_run_record_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_proof_store.dart';
import 'package:avrai_runtime_os/services/validation/domain_execution_field_scenario_runner.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart'
    show SharedPreferencesCompat;
import 'package:avrai_runtime_os/services/prediction/forecast_skill_ledger.dart';
import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';

/// Admin Services Registration Module
///
/// Registers all admin-related services.
/// This includes:
/// - Admin authentication services
/// - Admin communication services
/// - Admin god-mode services
/// - Connection monitoring for admin
Future<void> registerAdminServices(GetIt sl) async {
  const logger =
      AppLogger(defaultTag: 'DI-Admin', minimumLevel: LogLevel.debug);
  logger.debug('🔐 [DI-Admin] Registering admin services...');

  // Admin Services (God-Mode Admin System)
  // ConnectionMonitor is required for admin monitoring
  sl.registerLazySingleton(
      () => ConnectionMonitor(prefs: sl<SharedPreferencesCompat>()));

  // PredictiveAnalytics for admin analytics
  sl.registerLazySingleton(() => PredictiveAnalytics());

  // Note: BusinessAccountService is registered as a shared service in main container

  // AdminAuthService (authentication for admin access)
  sl.registerLazySingleton(() => AdminAuthService(
        sl<SharedPreferencesCompat>(),
        secureStorage: sl.isRegistered<FlutterSecureStorage>()
            ? sl<FlutterSecureStorage>()
            : null,
      ));

  // BusinessAuthService (business account authentication)
  sl.registerLazySingleton(
      () => BusinessAuthService(sl<SharedPreferencesCompat>()));

  // Supabase Service (kept for internal tooling/debug; app uses spots_network boundary)
  if (!sl.isRegistered<SupabaseService>()) {
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
  }

  // AdminCommunicationService (for AI2AI communication logs)
  sl.registerLazySingleton(() => AdminCommunicationService(
        connectionMonitor: sl<ConnectionMonitor>(),
        chatAnalyzer: sl.isRegistered<AI2AIChatAnalyzer>()
            ? sl<AI2AIChatAnalyzer>()
            : null,
      ));

  // AdminRuntimeGovernanceService (orchestrator for admin operations)
  // Register underlying instance as AdminGodModeService for compatibility,
  // while exposing AdminRuntimeGovernanceService as the primary interface.
  // ignore: deprecated_member_use_from_same_package
  sl.registerLazySingleton<AdminRuntimeGovernanceService>(() =>
      AdminGodModeService(
        authService: sl<AdminAuthService>(),
        communicationService: sl<AdminCommunicationService>(),
        businessService: sl<BusinessAccountService>(),
        predictiveAnalytics: sl<PredictiveAnalytics>(),
        connectionMonitor: sl<ConnectionMonitor>(),
        chatAnalyzer: sl.isRegistered<AI2AIChatAnalyzer>()
            ? sl<AI2AIChatAnalyzer>()
            : null,
        supabaseService: sl<SupabaseService>(),
        expertiseService: ExpertiseService(),
        networkActivityMonitor: sl.isRegistered<NetworkActivityMonitor>()
            ? sl<NetworkActivityMonitor>()
            : null,
        meshRouteLedger:
            sl.isRegistered<MeshRouteLedger>() ? sl<MeshRouteLedger>() : null,
        meshCustodyOutbox: sl.isRegistered<MeshCustodyOutbox>()
            ? sl<MeshCustodyOutbox>()
            : null,
        meshAnnounceLedger: sl.isRegistered<MeshAnnounceLedger>()
            ? sl<MeshAnnounceLedger>()
            : null,
        meshInterfaceRegistry: sl.isRegistered<MeshInterfaceRegistry>()
            ? sl<MeshInterfaceRegistry>()
            : null,
        meshRuntimeStateFrameService:
            sl.isRegistered<MeshRuntimeStateFrameService>()
                ? sl<MeshRuntimeStateFrameService>()
                : null,
        ai2aiRuntimeStateFrameService:
            sl.isRegistered<Ai2AiRuntimeStateFrameService>()
                ? sl<Ai2AiRuntimeStateFrameService>()
                : null,
        ai2aiRendezvousScheduler: sl.isRegistered<Ai2AiRendezvousScheduler>()
            ? sl<Ai2AiRendezvousScheduler>()
            : null,
        ambientSocialRealityLearningService:
            sl.isRegistered<AmbientSocialRealityLearningService>()
                ? sl<AmbientSocialRealityLearningService>()
                : null,
        meshCredentialRefreshService:
            sl.isRegistered<MeshSegmentCredentialRefreshService>()
                ? sl<MeshSegmentCredentialRefreshService>()
                : null,
        meshRevocationStore: sl.isRegistered<MeshSegmentRevocationStore>()
            ? sl<MeshSegmentRevocationStore>()
            : null,
        backgroundWakeRunRecordStore:
            sl.isRegistered<BackgroundWakeExecutionRunRecordStore>()
                ? sl<BackgroundWakeExecutionRunRecordStore>()
                : null,
        fieldScenarioProofStore:
            sl.isRegistered<DomainExecutionFieldScenarioProofStore>()
                ? sl<DomainExecutionFieldScenarioProofStore>()
                : null,
        fieldScenarioRunner:
            sl.isRegistered<DomainExecutionFieldScenarioRunner>()
                ? sl<DomainExecutionFieldScenarioRunner>()
                : null,
      ));

  // Backward compatibility alias for legacy callers still requesting AdminGodModeService.
  // ignore: deprecated_member_use_from_same_package
  sl.registerLazySingleton<AdminGodModeService>(
      () => sl<AdminRuntimeGovernanceService>() as AdminGodModeService);

  sl.registerLazySingleton<SignatureHealthAdminService>(
    () => SignatureHealthAdminService(
      intakeRepository: sl(),
      remoteSourceHealthService: sl.isRegistered<RemoteSourceHealthService>()
          ? sl<RemoteSourceHealthService>()
          : null,
    ),
  );

  if (!sl.isRegistered<RemoteSourceHealthService>()) {
    sl.registerLazySingleton<RemoteSourceHealthService>(
      () => RemoteSourceHealthService(
        supabaseService: sl<SupabaseService>(),
        temporalKernel:
            sl.isRegistered<TemporalKernel>() ? sl<TemporalKernel>() : null,
      ),
    );
  }

  if (sl.isRegistered<TemporalKernel>()) {
    sl.registerLazySingleton<TemporalKernelAdminService>(
      () => TemporalKernelAdminService(
        temporalKernel: sl<TemporalKernel>(),
      ),
    );
  }

  if (sl.isRegistered<ForecastSkillLedger>()) {
    sl.registerLazySingleton<ForecastKernelAdminService>(
      () => ForecastKernelAdminService(
        skillLedger: sl<ForecastSkillLedger>(),
      ),
    );
  }

  // URK kernel control-plane service (admin runtime operations).
  sl.registerLazySingleton(
    () => UrkKernelControlPlaneService(
      prefs: sl<SharedPreferencesCompat>(),
      registryService: const UrkKernelRegistryService(),
    ),
  );

  logger.debug('✅ [DI-Admin] Admin services registered');
}
