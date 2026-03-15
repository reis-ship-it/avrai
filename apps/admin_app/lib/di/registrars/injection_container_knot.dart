import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/storage_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_runtime_os/services/admin/admin_auth_service.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/services/user/agent_id_service.dart';
import 'package:avrai_runtime_os/services/admin/knot_admin_service.dart';
import 'package:avrai_runtime_os/services/device/wearable_data_service.dart';
import 'package:avrai_runtime_os/services/community/community_service.dart';

/// Knot Services Registration Module
///
/// Registers all knot theory-related services (Patent #31).
/// This includes:
/// - Core knot services (PersonalityKnotService, EntityKnotService)
/// - Knot storage and caching
/// - Knot compatibility and weaving
/// - Knot visualization services
/// - Knot recommendation engine
/// - Knot admin services
Future<void> registerKnotServices(GetIt sl) async {
  const logger = AppLogger(defaultTag: 'DI-Knot', minimumLevel: LogLevel.debug);
  logger.debug('🎗️ [DI-Knot] Registering knot services...');

  // Patent #31: Topological Knot Theory for Personality Representation
  // Register Knot Storage Service (must be registered before PersonalityKnotService)
  sl.registerLazySingleton<KnotStorageService>(
    () => KnotStorageService(storageService: sl<StorageService>()),
  );

  // Register Knot Cache Service (for performance optimization)
  sl.registerLazySingleton<KnotCacheService>(
    () => KnotCacheService(),
  );

  // Register Personality Knot Service (core knot generation)
  sl.registerLazySingleton<PersonalityKnotService>(
    () => PersonalityKnotService(),
  );

  // Register Entity Knot Service (knots for all entity types)
  sl.registerLazySingleton<EntityKnotService>(
    () => EntityKnotService(
      personalityKnotService: sl<PersonalityKnotService>(),
    ),
  );

  // Register Cross-Entity Compatibility Service
  sl.registerLazySingleton<CrossEntityCompatibilityService>(
    () => CrossEntityCompatibilityService(
      knotService: sl<PersonalityKnotService>(),
    ),
  );

  // Register QuantumStateKnotService (QuantumEntityState → EntityKnot bridge)
  sl.registerLazySingleton<QuantumStateKnotService>(
    () => QuantumStateKnotService(),
  );

  // Register Network Cross-Pollination Service
  sl.registerLazySingleton<NetworkCrossPollinationService>(
    () => NetworkCrossPollinationService(
      compatibilityService: sl<CrossEntityCompatibilityService>(),
    ),
  );

  // Register Knot Weaving Service (Phase 2: Knot Weaving)
  sl.registerLazySingleton<KnotWeavingService>(
    () => KnotWeavingService(
      personalityKnotService: sl<PersonalityKnotService>(),
    ),
  );

  // Register Dynamic Knot Service (Phase 4: Dynamic Knots)
  sl.registerLazySingleton<DynamicKnotService>(
    () => DynamicKnotService(),
  );

  // Register Wearable Data Service (Phase 4: Dynamic Knots with Wearables)
  sl.registerLazySingleton<WearableDataService>(
    () => WearableDataService(
      dynamicKnotService: sl<DynamicKnotService>(),
    ),
  );

  // Register Knot Fabric Service (Phase 5: Knot Fabric for Community Representation)
  sl.registerLazySingleton<KnotFabricService>(
    () => KnotFabricService(),
  );

  // Register Phase 5.5: Hierarchical Fabric Visualization System
  // Register Prominence Calculator
  sl.registerLazySingleton<ProminenceCalculator>(
    () => ProminenceCalculator(
      atomicClock: sl<AtomicClockService>(),
    ),
  );

  // Register Glue Visualization Service
  sl.registerLazySingleton<GlueVisualizationService>(
    () => GlueVisualizationService(
      compatibilityService: sl<CrossEntityCompatibilityService>(),
    ),
  );

  // Register Hierarchical Layout Service
  sl.registerLazySingleton<HierarchicalLayoutService>(
    () => HierarchicalLayoutService(
      prominenceCalculator: sl<ProminenceCalculator>(),
      compatibilityService: sl<CrossEntityCompatibilityService>(),
    ),
  );

  // Register Integrated Knot Recommendation Engine (Phase 6: Integrated Recommendations)
  sl.registerLazySingleton<IntegratedKnotRecommendationEngine>(
    () => IntegratedKnotRecommendationEngine(
      knotService: sl<PersonalityKnotService>(),
    ),
  );

  // Register Knot Evolution Coordinator Service (Knot Evolution Tracking for String Generation)
  // Note: AgentIdService is registered in main container, resolve it here
  sl.registerLazySingleton<KnotEvolutionCoordinatorService>(
    () {
      // Resolve AgentIdService from main container (registered before knot services)
      final agentIdService = sl<AgentIdService>();
      return KnotEvolutionCoordinatorService(
        knotService: sl<PersonalityKnotService>(),
        storageService: sl<KnotStorageService>(),
        getAgentId: (userId) => agentIdService.getUserAgentId(userId),
      );
    },
  );
  logger.debug('✅ [DI-Knot] KnotEvolutionCoordinatorService registered');

  // Register Knot Evolution String Service (Knot Evolution Tracking for String Generation)
  sl.registerLazySingleton<KnotEvolutionStringService>(
    () => KnotEvolutionStringService(
      storageService: sl<KnotStorageService>(),
    ),
  );
  logger.debug('✅ [DI-Knot] KnotEvolutionStringService registered');

  // Register Knot Worldsheet Service (2D plane representation for groups)
  sl.registerLazySingleton<KnotWorldsheetService>(
    () => KnotWorldsheetService(
      storageService: sl<KnotStorageService>(),
      stringService: sl<KnotEvolutionStringService>(),
      fabricService:
          sl<KnotFabricService>(), // Required for constructor but not used yet
    ),
  );
  logger.debug('✅ [DI-Knot] KnotWorldsheetService registered');

  // Register Knot Orchestrator Service (High-level orchestrator for all knot operations)
  sl.registerLazySingleton<KnotOrchestratorService>(
    () => KnotOrchestratorService(
      knotService: sl<PersonalityKnotService>(),
      storageService: sl<KnotStorageService>(),
      coordinator: sl<KnotEvolutionCoordinatorService>(),
      stringService: sl<KnotEvolutionStringService>(),
      fabricService: sl<KnotFabricService>(),
      worldsheetService: sl<KnotWorldsheetService>(),
    ),
  );
  logger.debug('✅ [DI-Knot] KnotOrchestratorService registered');

  // Register Phase 7: Audio & Privacy Services
  // Register Knot Audio Service
  sl.registerLazySingleton<WavetableKnotAudioService>(
    () => WavetableKnotAudioService(),
  );

  // Register Knot Privacy Service
  sl.registerLazySingleton<KnotPrivacyService>(
    () => KnotPrivacyService(),
  );

  // Register Knot Data API Service (Phase 8: Data Sale & Research Integration)
  // Must be registered before KnotAdminService
  sl.registerLazySingleton<KnotDataAPI>(
    () => KnotDataAPI(
      knotStorageService: sl<KnotStorageService>(),
      privacyService: sl<KnotPrivacyService>(),
    ),
  );

  // Register Knot Community Service (Phase 3: Onboarding Integration)
  // Must be registered after PersonalityKnotService and KnotStorageService
  sl.registerLazySingleton<KnotCommunityService>(
    () => KnotCommunityService(
      personalityKnotService: sl<PersonalityKnotService>(),
      knotStorageService: sl<KnotStorageService>(),
      communityService: sl<CommunityService>(),
    ),
  );

  // Register Knot Admin Service (Phase 9: Admin Knot Visualizer)
  // Must be registered after KnotDataAPI
  sl.registerLazySingleton<KnotAdminService>(
    () => KnotAdminService(
      knotStorageService: sl<KnotStorageService>(),
      knotDataAPI: sl<KnotDataAPI>(),
      knotService: sl<PersonalityKnotService>(),
      adminAuthService: sl<AdminAuthService>(),
    ),
  );

  logger.debug('✅ [DI-Knot] Knot services registered');
}
