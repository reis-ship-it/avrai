import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_domain_consumer_state_service.dart';
import 'package:avrai_runtime_os/services/interfaces/storage_service_interface.dart';
import 'package:avrai_runtime_os/services/expertise/expertise_service.dart';
import 'package:avrai_runtime_os/services/interfaces/expertise_service_interface.dart'
    show IExpertiseService;
import 'package:avrai_runtime_os/services/infrastructure/feature_flag_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/kernel/temporal/atomic_clock_temporal_adapter.dart';
import 'package:avrai_runtime_os/kernel/temporal/native_backed_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/system_temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/temporal_kernel.dart';
import 'package:avrai_runtime_os/kernel/temporal/when_native_bridge_bindings.dart';
import 'package:avrai_runtime_os/kernel/when/when_library_manager.dart';
import 'package:avrai_runtime_os/kernel/when/when_native_priority.dart';
import 'package:avrai_runtime_os/services/geographic/geo_hierarchy_service.dart';
import 'package:avrai_runtime_os/services/geographic/route_optimization_service.dart';
import 'package:avrai_runtime_os/services/places/large_city_detection_service.dart';
import 'package:avrai_runtime_os/services/places/neighborhood_boundary_service.dart';
import 'package:avrai_runtime_os/services/geographic/geographic_scope_service.dart';
import 'package:avrai_runtime_os/services/admin/role_management_service.dart';
import 'package:avrai_runtime_os/services/community/community_validation_service.dart';
import 'package:avrai_runtime_os/services/infrastructure/performance_monitor.dart';
import 'package:avrai_runtime_os/services/security/security_validator.dart';
import 'package:avrai_runtime_os/services/infrastructure/deployment_validator.dart';
import 'package:avrai_runtime_os/services/infrastructure/search_cache_service.dart';
import 'package:avrai_runtime_os/services/ai_infrastructure/ai_search_suggestions_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:avrai_runtime_os/services/device/device_motion_service.dart';
import 'package:avrai_runtime_os/services/user/permissions_persistence_service.dart';
import 'package:avrai_runtime_os/ai/vibe_analysis_engine.dart';

// Note: storage_service.dart is imported above for StorageService class
// SharedPreferencesCompat is also imported from the same file using 'show'

/// Core Services Registration Module
///
/// Registers foundational services that other modules depend on.
/// This includes:
/// - Storage and database services
/// - Core infrastructure services
/// - Geographic services
/// - Security and validation services
Future<void> registerCoreServices(GetIt sl) async {
  const logger = AppLogger(defaultTag: 'DI-Core', minimumLevel: LogLevel.debug);
  const bool isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  const bool isSimulatedSmoke =
      String.fromEnvironment('SIMULATED_SMOKE_PLATFORM') != '';
  logger.debug('📦 [DI-Core] Registering core services...');

  // External dependencies
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => PermissionsPersistenceService());
  sl.registerLazySingleton<DeviceMotionService>(
    () => DeviceMotionService(
      skipInitForTesting: isFlutterTest || isSimulatedSmoke,
    ),
  );

  // Note: AppDatabase (Drift) is registered in injection_container_device_sync.dart
  // Sembast was fully removed in Phase 26 migration.

  // Storage Service (foundation for many services)
  final storageService = StorageService.instance;
  await storageService.init();
  // Register both interface and implementation for flexibility
  sl.registerLazySingleton<IStorageService>(() => storageService);
  sl.registerLazySingleton<StorageService>(() => storageService);
  sl.registerLazySingleton<GovernedDomainConsumerStateService>(
    () => GovernedDomainConsumerStateService(storageService: storageService),
  );
  logger.debug(
      '✅ [DI-Core] StorageService registered (interface and implementation)');

  // SharedPreferencesCompat (compat wrapper over StorageService).
  // Many legacy services still depend on this type directly.
  if (!sl.isRegistered<SharedPreferencesCompat>()) {
    final prefsCompat = await StorageService.getInstance();
    sl.registerSingleton<SharedPreferencesCompat>(prefsCompat);
    logger.debug('✅ [DI-Core] SharedPreferencesCompat registered');
  }

  // Feature Flag Service
  sl.registerLazySingleton<FeatureFlagService>(
    () => FeatureFlagService(storage: sl<StorageService>()),
  );
  logger.debug('✅ [DI-Core] FeatureFlagService registered');

  // Geographic Services
  sl.registerLazySingleton<LargeCityDetectionService>(
    () => LargeCityDetectionService(),
  );
  sl.registerLazySingleton<GeographicScopeService>(
    () => GeographicScopeService(
      largeCityService: sl<LargeCityDetectionService>(),
    ),
  );
  sl.registerLazySingleton<NeighborhoodBoundaryService>(
    () => NeighborhoodBoundaryService(
      largeCityService: sl<LargeCityDetectionService>(),
      storageService: sl<StorageService>(),
    ),
  );
  sl.registerLazySingleton<RouteOptimizationService>(
    () => RouteOptimizationService(
      governedDomainConsumerStateService:
          sl<GovernedDomainConsumerStateService>(),
    ),
  );
  logger.debug('✅ [DI-Core] Geographic services registered');

  // Expertise Service (used by many services - register interface and implementation)
  sl.registerLazySingleton<IExpertiseService>(() => ExpertiseService());
  sl.registerLazySingleton<ExpertiseService>(() => ExpertiseService());
  logger.debug(
      '✅ [DI-Core] ExpertiseService registered (interface and implementation)');

  // Phase 2: Missing Services
  // Note: RoleManagementService requires interface import - using implementation directly
  sl.registerLazySingleton(
    () => RoleManagementServiceImpl(
      storageService: sl<StorageService>(),
      prefs: sl<SharedPreferencesCompat>(),
    ),
  );
  sl.registerLazySingleton(() => CommunityValidationService(
        storageService: sl<StorageService>(),
        prefs: sl<SharedPreferencesCompat>(),
      ));
  logger.debug('✅ [DI-Core] Phase 2 services registered');

  // Patent #30: Quantum Atomic Clock System
  sl.registerLazySingleton<AtomicClockService>(() => AtomicClockService());
  logger.debug('✅ [DI-Core] AtomicClockService registered');
  if (!sl.isRegistered<WhenLibraryManager>()) {
    sl.registerLazySingleton<WhenLibraryManager>(() => WhenLibraryManager());
  }
  if (!sl.isRegistered<WhenNativeInvocationBridge>()) {
    sl.registerLazySingleton<WhenNativeInvocationBridge>(
      () => WhenNativeBridgeBindings(
        libraryManager: sl<WhenLibraryManager>(),
      ),
    );
  }
  if (!sl.isRegistered<WhenNativeExecutionPolicy>()) {
    sl.registerLazySingleton<WhenNativeExecutionPolicy>(
      () => WhenNativeExecutionPolicy(
        requireNative: !(isFlutterTest || isSimulatedSmoke),
      ),
    );
  }
  if (!sl.isRegistered<WhenNativeFallbackAudit>()) {
    sl.registerLazySingleton<WhenNativeFallbackAudit>(
      () => WhenNativeFallbackAudit(),
    );
  }
  sl.registerLazySingleton<TemporalKernel>(
    () => NativeBackedTemporalKernel(
      nativeBridge: sl<WhenNativeInvocationBridge>(),
      fallbackKernel: SystemTemporalKernel(
        clockSource: AtomicClockTemporalAdapter(
          atomicClockService: sl<AtomicClockService>(),
        ),
      ),
      policy: sl<WhenNativeExecutionPolicy>(),
      audit: sl<WhenNativeFallbackAudit>(),
    ),
  );
  logger.debug('✅ [DI-Core] TemporalKernel registered');

  // Agent ID Service (privacy protection)
  // Note: AgentIdService requires SecureMappingEncryptionService and BusinessAccountService
  // Registration deferred to main container where these dependencies are available
  logger.debug(
      '✅ [DI-Core] AgentIdService registration deferred to main container');

  // Supabase Service (if available)
  try {
    sl.registerLazySingleton<SupabaseService>(() => SupabaseService());
    logger.debug('✅ [DI-Core] SupabaseService registered');
  } catch (e) {
    logger.warn('⚠️ [DI-Core] SupabaseService registration skipped: $e');
  }

  // Geo Hierarchy Service (DB-backed geo registry + lookup helpers).
  //
  // This ties the expert geo hierarchy to `city_code` buckets and supports:
  // - event creation geo codes (city_code/locality_code)
  // - map filtering/overlays (via RPC reads)
  sl.registerLazySingleton<GeoHierarchyService>(
    () => GeoHierarchyService(
      supabaseService: sl.isRegistered<SupabaseService>()
          ? sl<SupabaseService>()
          : SupabaseService(),
    ),
  );
  logger.debug('✅ [DI-Core] GeoHierarchyService registered');

  // Performance and Validation Services
  // Note: These require SharedPreferences, so register after sharedPrefs
  sl.registerLazySingleton(() => PerformanceMonitor(
        storageService: sl<StorageService>(),
        prefs: sl<SharedPreferencesCompat>(),
      ));
  sl.registerLazySingleton(() => SecurityValidator());
  sl.registerLazySingleton(() => DeploymentValidator(
        performanceMonitor: sl<PerformanceMonitor>(),
        securityValidator: sl<SecurityValidator>(),
      ));
  logger.debug('✅ [DI-Core] Performance and validation services registered');

  // Search Services
  sl.registerLazySingleton(() => SearchCacheService());
  sl.registerLazySingleton(() => AISearchSuggestionsService());
  logger.debug('✅ [DI-Core] Search services registered');

  // UserVibeAnalyzer (depends on SharedPreferences)
  final sharedPrefsForVibe = await StorageService.getInstance();
  sl.registerLazySingleton(() => UserVibeAnalyzer(prefs: sharedPrefsForVibe));
  logger.debug('✅ [DI-Core] UserVibeAnalyzer registered');

  logger.debug('✅ [DI-Core] Core services registration complete');
}
