// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
part of '../../injection_container.dart';

Future<void> _registerAppServiceLayer(AppLogger logger) async {
  // Agent ID Migration Service (for migrating plaintext mappings to encrypted)
  sl.registerLazySingleton<AgentIdMigrationService>(
    () => AgentIdMigrationService(
      supabaseService: sl<SupabaseService>(),
      encryptionService: sl<SecureMappingEncryptionService>(),
    ),
  );

  // Mapping Key Rotation Service (for rotating encryption keys)
  sl.registerLazySingleton<MappingKeyRotationService>(
    () => MappingKeyRotationService(
      supabaseService: sl<SupabaseService>(),
      encryptionService: sl<SecureMappingEncryptionService>(),
      agentIdService: sl<AgentIdService>(),
    ),
  );

  // Note: OnboardingDataService, SocialMediaVibeAnalyzer, and OnboardingPlaceListGenerator
  // are registered in AI module

  // Controllers (Phase 8.11)
  sl.registerLazySingleton(() => OnboardingFlowController(
        onboardingDataService: sl<OnboardingDataService>(),
        agentIdService: sl<AgentIdService>(),
        legalDocumentService: sl<LegalDocumentService>(),
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
      ));

  // Agent Initialization Controller (Phase 8.11)
  sl.registerLazySingleton(() => AgentInitializationController(
        socialMediaDataController: sl<SocialMediaDataCollectionController>(),
        personalityLearning: sl<PersonalityLearning>(),
        preferencesService: sl<PreferencesProfileService>(),
        placeListGenerator: sl<OnboardingPlaceListGenerator>(),
        recommendationService: sl<OnboardingRecommendationService>(),
        syncService: sl<PersonalitySyncService>(),
        agentIdService: sl<AgentIdService>(),
        atomicClock: sl<AtomicClockService>(),
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        entitySignatureService: sl.isRegistered<EntitySignatureService>()
            ? sl<EntitySignatureService>()
            : null,
      ));

  // ============================================================================
  // Locality Agents (v1) - geohash-keyed locality learning layer
  // ============================================================================
  if (!sl.isRegistered<LocalityAgentGlobalRepositoryV1>()) {
    sl.registerLazySingleton<LocalityAgentGlobalRepositoryV1>(
      () => LocalityAgentGlobalRepositoryV1(
        supabaseService: sl<SupabaseService>(),
        storage: sl<StorageService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityAgentLocalStoreV1>()) {
    sl.registerLazySingleton<LocalityAgentLocalStoreV1>(
      () => LocalityAgentLocalStoreV1(storage: sl<StorageService>()),
    );
  }
  if (!sl.isRegistered<LocalityAgentMeshCache>()) {
    sl.registerLazySingleton<LocalityAgentMeshCache>(
      () => LocalityAgentMeshCache(storage: sl<StorageService>()),
    );
  }
  if (!sl.isRegistered<LocalityAgentEngineV1>()) {
    sl.registerLazySingleton<LocalityAgentEngineV1>(
      () => LocalityAgentEngineV1(
        globalRepo: sl<LocalityAgentGlobalRepositoryV1>(),
        localStore: sl<LocalityAgentLocalStoreV1>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityAgentUpdateEmitterV1>()) {
    sl.registerLazySingleton<LocalityAgentUpdateEmitterV1>(
      () => LocalityAgentUpdateEmitterV1(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityMemory>()) {
    sl.registerLazySingleton<LocalityMemory>(
      () => LocalityMemory(storage: sl<StorageService>()),
    );
  }
  if (!sl.isRegistered<LocalityInferenceHead>()) {
    sl.registerLazySingleton<LocalityInferenceHead>(
      () => LocalityInferenceHead(
        engine: sl<LocalityAgentEngineV1>(),
        syncCoordinator: sl<LocalitySyncCoordinator>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalitySyncCoordinator>()) {
    sl.registerLazySingleton<LocalitySyncCoordinator>(
      () => LocalitySyncCoordinator(
        emitter: sl<LocalityAgentUpdateEmitterV1>(),
        globalRepository: sl<LocalityAgentGlobalRepositoryV1>(),
        meshCache: sl.isRegistered<LocalityAgentMeshCache>()
            ? sl<LocalityAgentMeshCache>()
            : null,
      ),
    );
  }
  if (!sl.isRegistered<LocalityProjectionService>()) {
    sl.registerLazySingleton<LocalityProjectionService>(
      () => LocalityProjectionService(),
    );
  }
  if (!sl.isRegistered<LocalityKernelRuntimeContext>()) {
    sl.registerLazySingleton<LocalityKernelRuntimeContext>(
      () => LocalityKernelRuntimeContext(
        agentIdService: sl<AgentIdService>(),
        geoHierarchyService: sl<GeoHierarchyService>(),
        prefs: sl.isRegistered<SharedPreferencesCompat>()
            ? sl<SharedPreferencesCompat>()
            : null,
        spotsLocalDataSource: sl<SpotsLocalDataSource>(),
        memory: sl<LocalityMemory>(),
        inferenceHead: sl<LocalityInferenceHead>(),
        syncCoordinator: sl<LocalitySyncCoordinator>(),
        projectionService: sl<LocalityProjectionService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityKernel>()) {
    sl.registerLazySingleton<LocalityKernel>(
      () => LocalityKernel.fromRuntimeContext(
        sl<LocalityKernelRuntimeContext>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityKernelContract>()) {
    sl.registerLazySingleton<LocalityKernelContract>(
      () => sl<LocalityKernel>(),
    );
  }
  if (!sl.isRegistered<LocalityAgentIngestionServiceV1>()) {
    sl.registerLazySingleton<LocalityAgentIngestionServiceV1>(
      () => LocalityAgentIngestionServiceV1(
        kernel: sl<LocalityKernelContract>(),
      ),
    );
  }
  if (!sl.isRegistered<OsGeofenceRegistrarV1>()) {
    sl.registerLazySingleton<OsGeofenceRegistrarV1>(
      () => NoopOsGeofenceRegistrarV1(),
    );
  }
  if (!sl.isRegistered<LocalityGeofencePlannerV1>()) {
    sl.registerLazySingleton<LocalityGeofencePlannerV1>(
      () => LocalityGeofencePlannerV1(
        storage: sl<StorageService>(),
        registrar: sl<OsGeofenceRegistrarV1>(),
      ),
    );
  }

  // Event Creation Controller (Phase 8.11)
  sl.registerLazySingleton(() => EventCreationController(
        eventService: sl<ExpertiseEventService>(),
        geographicScopeService: sl<GeographicScopeService>(),
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
      ));

  // Social Media Data Collection Controller (Phase 8.11)
  sl.registerLazySingleton(() => SocialMediaDataCollectionController(
        socialMediaService: sl<SocialMediaConnectionService>(),
      ));

  // Payment Processing Controller (Phase 8.11)
  if (!sl.isRegistered<PaymentProcessingController>()) {
    sl.registerLazySingleton<PaymentProcessingController>(
        () => PaymentProcessingController(
              salesTaxService: sl<SalesTaxService>(),
              paymentEventService: sl<PaymentEventService>(),
            ));
  }

  // AI Recommendation Controller (Phase 8.11)
  sl.registerLazySingleton(() => AIRecommendationController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
            ? sl<IntegratedKnotRecommendationEngine>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        personalityLearning: sl<PersonalityLearning>(),
        preferencesProfileService: sl<PreferencesProfileService>(),
        eventRecommendationService:
            sl<event_rec_service.EventRecommendationService>(),
        agentIdService: sl<AgentIdService>(),
        localityKernel: sl.isRegistered<LocalityKernelContract>()
            ? sl<LocalityKernelContract>()
            : null,
      ));

  sl.registerLazySingleton(() => BusinessOnboardingController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        businessAccountService: sl<BusinessAccountService>(),
        sharedAgentService: sl<BusinessSharedAgentService>(),
      ));

  sl.registerLazySingleton(() => EventAttendanceController(
        atomicClock: sl<AtomicClockService>(),
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        eventService: sl<ExpertiseEventService>(),
        paymentController: sl<PaymentProcessingController>(),
        preferencesService: sl<PreferencesProfileService>(),
        agentIdService: sl<AgentIdService>(),
      ));

  sl.registerLazySingleton(() => ListCreationController(
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotEngine: sl.isRegistered<IntegratedKnotRecommendationEngine>()
            ? sl<IntegratedKnotRecommendationEngine>()
            : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        listsRepository: sl<ListsRepository>(),
        atomicClock: sl<AtomicClockService>(),
      ));

  sl.registerLazySingleton(() => ProfileUpdateController(
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotStringService: sl.isRegistered<KnotEvolutionStringService>()
            ? sl<KnotEvolutionStringService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        authRepository: sl<AuthRepository>(),
        atomicClock: sl<AtomicClockService>(),
      ));

  sl.registerLazySingleton(() => EventCancellationController(
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        cancellationService: sl<CancellationService>(),
        eventService: sl<ExpertiseEventService>(),
        paymentService: sl<PaymentService>(),
      ));

  sl.registerLazySingleton(() => PartnershipProposalController(
        atomicClock: sl<AtomicClockService>(),
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        partnershipService: sl<PartnershipService>(),
        businessService: sl<BusinessService>(),
      ));

  sl.registerLazySingleton(() => CheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        paymentController: sl<PaymentProcessingController>(),
        salesTaxService: sl<SalesTaxService>(),
        legalService: sl<LegalDocumentService>(),
        eventService: sl<ExpertiseEventService>(),
      ));

  sl.registerLazySingleton(() => PartnershipCheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        paymentController: sl<PaymentProcessingController>(),
        revenueSplitService: sl<RevenueSplitService>(),
        partnershipService: sl<PartnershipService>(),
        eventService: sl<ExpertiseEventService>(),
        salesTaxService: sl<SalesTaxService>(),
      ));

  sl.registerLazySingleton(() => SponsorshipCheckoutController(
        atomicClock: sl<AtomicClockService>(),
        knotCompatibilityService:
            sl.isRegistered<CrossEntityCompatibilityService>()
                ? sl<CrossEntityCompatibilityService>()
                : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        locationTimingService:
            sl.isRegistered<LocationTimingQuantumStateService>()
                ? sl<LocationTimingQuantumStateService>()
                : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        aiLearningService: sl.isRegistered<QuantumMatchingAILearningService>()
            ? sl<QuantumMatchingAILearningService>()
            : null,
        sponsorshipService: sl<SponsorshipService>(),
        eventService: sl<ExpertiseEventService>(),
        productTrackingService: sl<ProductTrackingService>(),
      ));

  sl.registerLazySingleton(() => SyncController(
        agentIdService:
            sl.isRegistered<AgentIdService>() ? sl<AgentIdService>() : null,
        personalityKnotService: sl.isRegistered<PersonalityKnotService>()
            ? sl<PersonalityKnotService>()
            : null,
        knotStorageService: sl.isRegistered<KnotStorageService>()
            ? sl<KnotStorageService>()
            : null,
        knotFabricService: sl.isRegistered<KnotFabricService>()
            ? sl<KnotFabricService>()
            : null,
        knotWorldsheetService: sl.isRegistered<KnotWorldsheetService>()
            ? sl<KnotWorldsheetService>()
            : null,
        quantumEntanglementService:
            sl.isRegistered<QuantumEntanglementService>()
                ? sl<QuantumEntanglementService>()
                : null,
        ai2aiProtocol: sl.isRegistered<AnonymousCommunicationProtocol>()
            ? sl<AnonymousCommunicationProtocol>()
            : null,
        connectivityService: sl<EnhancedConnectivityService>(),
        personalitySyncService: sl<PersonalitySyncService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
}

void _registerAppPresentationLayer() {
  // Blocs (Register last, after all dependencies)
  sl.registerFactory(() => AuthBloc(
        signInUseCase: sl(),
        signInWithGoogleUseCase: sl(),
        signInWithAppleUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        updatePasswordUseCase: sl(),
      ));

  sl.registerFactory(() => SpotsBloc(
        getSpotsUseCase: sl(),
        getSpotsFromRespectedListsUseCase: sl(),
        createSpotUseCase: sl(),
        updateSpotUseCase: sl(),
        deleteSpotUseCase: sl(),
      ));

  sl.registerFactory(() => ListsBloc(
        getListsUseCase: sl(),
        createListUseCase: sl(),
        updateListUseCase: sl(),
        deleteListUseCase: sl(),
      ));

  // Phase 19.18: Quantum Group Matching System
  // Section GM.4: Group Matching BLoC
  sl.registerFactory(() => GroupMatchingBloc(
        controller: sl<GroupMatchingController>(),
        formationService: sl<GroupFormationService>(),
        searchRepository: sl.isRegistered<HybridSearchRepository>()
            ? sl<HybridSearchRepository>()
            : null,
      ));

  // Hybrid Search Bloc (Phase 2)
  sl.registerFactory(() => HybridSearchBloc(
        hybridSearchUseCase: sl(),
        cacheService: sl(),
        suggestionsService: sl(),
      ));
}
