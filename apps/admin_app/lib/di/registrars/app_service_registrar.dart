// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
part of '../../injection_container.dart';

Future<void> _registerAppServiceLayer(AppLogger logger) async {
  const bool isFlutterTest = bool.fromEnvironment('FLUTTER_TEST');
  const bool useDartLocalityFallback = isFlutterTest;

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
  // Where Kernel - geohash-keyed "where" runtime layer
  // ============================================================================
  if (!sl.isRegistered<LocalityCloudPriorGateway>()) {
    sl.registerLazySingleton<LocalityCloudPriorGateway>(
      () => LocalityCloudPriorGateway(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityCloudUpdateGateway>()) {
    sl.registerLazySingleton<LocalityCloudUpdateGateway>(
      () => LocalityCloudUpdateGateway(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (useDartLocalityFallback && !sl.isRegistered<LocalityMemory>()) {
    sl.registerLazySingleton<LocalityMemory>(
      () => LocalityMemory(storage: sl<StorageService>()),
    );
  }
  if (!sl.isRegistered<LocalityInfrastructureBridge>()) {
    sl.registerLazySingleton<LocalityInfrastructureBridge>(
      () => LocalityInfrastructureBridge(
        cloudPriorGateway: sl<LocalityCloudPriorGateway>(),
        cloudUpdateGateway: sl<LocalityCloudUpdateGateway>(),
        memory: useDartLocalityFallback && sl.isRegistered<LocalityMemory>()
            ? sl<LocalityMemory>()
            : null,
      ),
    );
  }
  if (useDartLocalityFallback && !sl.isRegistered<LocalityInferenceHead>()) {
    sl.registerLazySingleton<LocalityInferenceHead>(
      () => LocalityInferenceHead(
        memory: sl<LocalityMemory>(),
        infrastructureBridge: sl<LocalityInfrastructureBridge>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityNativeSyncPayloadBuilder>()) {
    sl.registerLazySingleton<LocalityNativeSyncPayloadBuilder>(
      () => LocalityNativeSyncPayloadBuilder(
        infrastructureBridge: sl<LocalityInfrastructureBridge>(),
      ),
    );
  }
  if (useDartLocalityFallback && !sl.isRegistered<LocalityTransportSupport>()) {
    sl.registerLazySingleton<LocalityTransportSupport>(
      () => LocalityTransportSupport(
        infrastructureBridge: sl<LocalityInfrastructureBridge>(),
      ),
    );
  }
  if (useDartLocalityFallback &&
      !sl.isRegistered<LocalityProjectionService>()) {
    sl.registerLazySingleton<LocalityProjectionService>(
      () => LocalityProjectionService(),
    );
  }
  if (useDartLocalityFallback &&
      !sl.isRegistered<LocalityKernelRuntimeContext>()) {
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
        transportSupport: sl<LocalityTransportSupport>(),
        projectionService: sl<LocalityProjectionService>(),
        trainingContract: sl<LocalityTrainingContract>(),
      ),
    );
  }
  if (useDartLocalityFallback &&
      !sl.isRegistered<DartLocalityFallbackKernel>()) {
    sl.registerLazySingleton<DartLocalityFallbackKernel>(
      () => DartLocalityFallbackKernel.fromRuntimeContext(
        sl<LocalityKernelRuntimeContext>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityWhereProviderFallbackSurface>()) {
    sl.registerLazySingleton<LocalityWhereProviderFallbackSurface>(
      () => useDartLocalityFallback
          ? sl<DartLocalityFallbackKernel>()
          : const DisabledLocalityFallbackKernel(),
    );
  }
  if (!sl.isRegistered<LocalityWhereProviderContract>()) {
    sl.registerLazySingleton<LocalityWhereProviderContract>(
      () => sl<LocalityNativeKernelStub>(),
    );
  }
  if (!sl.isRegistered<WhereKernelContract>()) {
    sl.registerLazySingleton<WhereKernelContract>(
      () => LocalityWhereKernelAdapter(
        provider: sl<LocalityWhereProviderContract>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityLibraryManager>()) {
    sl.registerLazySingleton<LocalityLibraryManager>(
      () => LocalityLibraryManager(),
    );
  }
  if (!sl.isRegistered<LocalityNativeInvocationBridge>()) {
    sl.registerLazySingleton<LocalityNativeInvocationBridge>(
      () => LocalityNativeBridgeBindings(
        libraryManager: sl<LocalityLibraryManager>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityNativeExecutionPolicy>()) {
    sl.registerLazySingleton<LocalityNativeExecutionPolicy>(
      () => LocalityNativeExecutionPolicy(
        requireNative: !useDartLocalityFallback,
      ),
    );
  }
  if (!sl.isRegistered<LocalityNativeFallbackAudit>()) {
    sl.registerLazySingleton<LocalityNativeFallbackAudit>(
      () => LocalityNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<InProcessLocalitySyscallTransport>()) {
    sl.registerLazySingleton<InProcessLocalitySyscallTransport>(
      () => InProcessLocalitySyscallTransport(
        delegate: sl<LocalityWhereProviderFallbackSurface>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalitySyscallTransport>()) {
    sl.registerLazySingleton<LocalitySyscallTransport>(
      () => FfiPreferredLocalitySyscallTransport(
        nativeBridge: sl<LocalityNativeInvocationBridge>(),
        fallbackTransport: sl<InProcessLocalitySyscallTransport>(),
        policy: sl<LocalityNativeExecutionPolicy>(),
        audit: sl<LocalityNativeFallbackAudit>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityNativeKernelStub>()) {
    sl.registerLazySingleton<LocalityNativeKernelStub>(
      () => LocalityNativeKernelStub(
        transport: sl<LocalitySyscallTransport>(),
        agentIdService: sl<AgentIdService>(),
        syncPayloadBuilder: sl<LocalityNativeSyncPayloadBuilder>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityNativeAdminDiagnosticsBridge>()) {
    sl.registerLazySingleton<LocalityNativeAdminDiagnosticsBridge>(
      () => LocalityNativeAdminDiagnosticsBridge(
        nativeBridge: sl<LocalityNativeInvocationBridge>(),
        fallbackKernel: sl<LocalityWhereProviderFallbackSurface>(),
        policy: sl<LocalityNativeExecutionPolicy>(),
        audit: sl<LocalityNativeFallbackAudit>(),
      ),
    );
  }
  if (!sl.isRegistered<LocalityTrainingContract>()) {
    sl.registerLazySingleton<LocalityTrainingContract>(
      () => LocalityNativeTrainingBridge(
        nativeBridge: sl<LocalityNativeInvocationBridge>(),
        fallback: const SyntheticLocalityTrainingService(),
        policy: sl<LocalityNativeExecutionPolicy>(),
        audit: sl<LocalityNativeFallbackAudit>(),
      ),
    );
  }
  await registerWhatKernelServices(sl);
  if (sl.isRegistered<WhatRuntimeRecoveryService>()) {
    await sl<WhatRuntimeRecoveryService>().recoverForCurrentUserIfAvailable();
  }

  if (!sl.isRegistered<WhereKernelIngestionAdapter>()) {
    sl.registerLazySingleton<WhereKernelIngestionAdapter>(
      () => WhereKernelIngestionAdapter(
        kernel: sl<WhereKernelContract>(),
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

  // ============================================================================
  // Standalone Functional Kernel OS
  // ============================================================================
  if (!sl.isRegistered<WhoKernelFallbackSurface>()) {
    sl.registerLazySingleton<WhoKernelFallbackSurface>(
      () => isFlutterTest
          ? const DartWhoFallbackKernel()
          : const DisabledWhoFallbackKernel(),
    );
  }
  if (!sl.isRegistered<WhoLibraryManager>()) {
    sl.registerLazySingleton<WhoLibraryManager>(() => WhoLibraryManager());
  }
  if (!sl.isRegistered<WhoNativeInvocationBridge>()) {
    sl.registerLazySingleton<WhoNativeInvocationBridge>(
      () => WhoNativeBridgeBindings(libraryManager: sl<WhoLibraryManager>()),
    );
  }
  if (!sl.isRegistered<WhoNativeExecutionPolicy>()) {
    sl.registerLazySingleton<WhoNativeExecutionPolicy>(
      () => WhoNativeExecutionPolicy(requireNative: !isFlutterTest),
    );
  }
  if (!sl.isRegistered<WhoNativeFallbackAudit>()) {
    sl.registerLazySingleton<WhoNativeFallbackAudit>(
      () => WhoNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<WhoKernelContract>()) {
    sl.registerLazySingleton<WhoKernelContract>(
      () => WhoNativeKernelStub(
        nativeBridge: sl<WhoNativeInvocationBridge>(),
        fallback: sl<WhoKernelFallbackSurface>(),
        policy: sl<WhoNativeExecutionPolicy>(),
        audit: sl<WhoNativeFallbackAudit>(),
      ),
    );
  }

  if (!sl.isRegistered<WhenKernelFallbackSurface>()) {
    sl.registerLazySingleton<WhenKernelFallbackSurface>(
      () => isFlutterTest
          ? const DartWhenFallbackKernel()
          : const DisabledWhenFallbackKernel(),
    );
  }
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
      () => WhenNativeExecutionPolicy(requireNative: !isFlutterTest),
    );
  }
  if (!sl.isRegistered<WhenNativeFallbackAudit>()) {
    sl.registerLazySingleton<WhenNativeFallbackAudit>(
      () => WhenNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<WhenKernelContract>()) {
    sl.registerLazySingleton<WhenKernelContract>(
      () => WhenNativeKernelStub(
        nativeBridge: sl<WhenNativeInvocationBridge>(),
        fallback: sl<WhenKernelFallbackSurface>(),
        policy: sl<WhenNativeExecutionPolicy>(),
        audit: sl<WhenNativeFallbackAudit>(),
      ),
    );
  }

  if (!sl.isRegistered<HowKernelFallbackSurface>()) {
    sl.registerLazySingleton<HowKernelFallbackSurface>(
      () => isFlutterTest
          ? const DartHowFallbackKernel()
          : const DisabledHowFallbackKernel(),
    );
  }
  if (!sl.isRegistered<HowLibraryManager>()) {
    sl.registerLazySingleton<HowLibraryManager>(() => HowLibraryManager());
  }
  if (!sl.isRegistered<HowNativeInvocationBridge>()) {
    sl.registerLazySingleton<HowNativeInvocationBridge>(
      () => HowNativeBridgeBindings(libraryManager: sl<HowLibraryManager>()),
    );
  }
  if (!sl.isRegistered<HowNativeExecutionPolicy>()) {
    sl.registerLazySingleton<HowNativeExecutionPolicy>(
      () => HowNativeExecutionPolicy(requireNative: !isFlutterTest),
    );
  }
  if (!sl.isRegistered<HowNativeFallbackAudit>()) {
    sl.registerLazySingleton<HowNativeFallbackAudit>(
      () => HowNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<HowKernelContract>()) {
    sl.registerLazySingleton<HowKernelContract>(
      () => HowNativeKernelStub(
        nativeBridge: sl<HowNativeInvocationBridge>(),
        fallback: sl<HowKernelFallbackSurface>(),
        policy: sl<HowNativeExecutionPolicy>(),
        audit: sl<HowNativeFallbackAudit>(),
      ),
    );
  }

  if (!sl.isRegistered<WhyKernelFallbackSurface>()) {
    sl.registerLazySingleton<WhyKernelFallbackSurface>(
      () => isFlutterTest
          ? const DartWhyFallbackKernel()
          : const DisabledWhyFallbackKernel(),
    );
  }
  if (!sl.isRegistered<WhyLibraryManager>()) {
    sl.registerLazySingleton<WhyLibraryManager>(() => WhyLibraryManager());
  }
  if (!sl.isRegistered<WhyNativeInvocationBridge>()) {
    sl.registerLazySingleton<WhyNativeInvocationBridge>(
      () => WhyNativeBridgeBindings(libraryManager: sl<WhyLibraryManager>()),
    );
  }
  if (!sl.isRegistered<WhyNativeExecutionPolicy>()) {
    sl.registerLazySingleton<WhyNativeExecutionPolicy>(
      () => WhyNativeExecutionPolicy(requireNative: !isFlutterTest),
    );
  }
  if (!sl.isRegistered<WhyNativeFallbackAudit>()) {
    sl.registerLazySingleton<WhyNativeFallbackAudit>(
      () => WhyNativeFallbackAudit(),
    );
  }
  if (!sl.isRegistered<WhyKernelContract>()) {
    sl.registerLazySingleton<WhyKernelContract>(
      () => WhyNativeKernelStub(
        nativeBridge: sl<WhyNativeInvocationBridge>(),
        fallback: sl<WhyKernelFallbackSurface>(),
        policy: sl<WhyNativeExecutionPolicy>(),
        audit: sl<WhyNativeFallbackAudit>(),
      ),
    );
  }

  if (!sl.isRegistered<KernelBundleStore>()) {
    sl.registerLazySingleton<KernelBundleStore>(
      () => InMemoryKernelBundleStore(
        rootCauseIndex: sl<KernelRootCauseIndex>(),
        telemetryService: sl<KernelTelemetryService>(),
      ),
    );
  }
  if (!sl.isRegistered<KernelRootCauseIndex>()) {
    sl.registerLazySingleton<KernelRootCauseIndex>(
      () => InMemoryKernelRootCauseIndex(),
    );
  }
  if (!sl.isRegistered<KernelTelemetryService>()) {
    sl.registerLazySingleton<KernelTelemetryService>(
      () => InMemoryKernelTelemetryService(),
    );
  }
  if (!sl.isRegistered<FunctionalKernelOs>()) {
    sl.registerLazySingleton<FunctionalKernelOs>(
      () => FunctionalKernelOrchestrator(
        whoKernel: sl<WhoKernelContract>(),
        whatKernel: sl<WhatKernelContract>(),
        whenKernel: sl<WhenKernelContract>(),
        spatialWhereKernel: sl<WhereKernelContract>(),
        howKernel: sl<HowKernelContract>(),
        whyKernel: sl<WhyKernelContract>(),
        bundleStore: sl<KernelBundleStore>(),
      ),
    );
  }
  if (!sl.isRegistered<FunctionalKernelProngPorts>()) {
    sl.registerLazySingleton<FunctionalKernelProngPorts>(
      () => FunctionalKernelProngPorts(
        kernelOs: sl<FunctionalKernelOs>(),
        whoKernel: sl<WhoKernelContract>(),
        whatKernel: sl<WhatKernelContract>(),
        whenKernel: sl<WhenKernelContract>(),
        whereKernel: sl<WhereKernelContract>(),
        howKernel: sl<HowKernelContract>(),
        whyKernel: sl<WhyKernelContract>(),
      ),
    );
  }
  if (!sl.isRegistered<ModelTruthPort>()) {
    sl.registerLazySingleton<ModelTruthPort>(
      () => sl<FunctionalKernelProngPorts>(),
    );
  }
  if (!sl.isRegistered<RealityModelPort>()) {
    sl.registerLazySingleton<RealityModelPort>(
      () => KernelBackedRealityModelPort(
        modelTruthPort: sl<ModelTruthPort>(),
        fallback: DefaultRealityModelPort(),
      ),
    );
  }
  if (!sl.isRegistered<RuntimeExecutionPort>()) {
    sl.registerLazySingleton<RuntimeExecutionPort>(
      () => sl<FunctionalKernelProngPorts>(),
    );
  }
  if (!sl.isRegistered<TrustGovernancePort>()) {
    sl.registerLazySingleton<TrustGovernancePort>(
      () => sl<FunctionalKernelProngPorts>(),
    );
  }
  if (!sl.isRegistered<HeadlessAvraiOsHost>()) {
    sl.registerLazySingleton<HeadlessAvraiOsHost>(
      () => DefaultHeadlessAvraiOsHost(
        modelTruthPort: sl<ModelTruthPort>(),
        runtimeExecutionPort: sl<RuntimeExecutionPort>(),
        trustGovernancePort: sl<TrustGovernancePort>(),
        whoKernel: sl<WhoKernelContract>(),
        whatKernel: sl<WhatKernelContract>(),
        whenKernel: sl<WhenKernelContract>(),
        whereKernel: sl<WhereKernelContract>(),
        howKernel: sl<HowKernelContract>(),
        whyKernel: sl<WhyKernelContract>(),
      ),
    );
  }
  if (!sl.isRegistered<HeadlessAvraiOsBootstrapService>()) {
    sl.registerLazySingleton<HeadlessAvraiOsBootstrapService>(
      () => HeadlessAvraiOsBootstrapService(
        host: sl<HeadlessAvraiOsHost>(),
        prefs: sl.isRegistered<SharedPreferencesCompat>()
            ? sl<SharedPreferencesCompat>()
            : null,
      ),
    );
  }
  if (!sl.isRegistered<HeadlessAvraiOsAvailabilityService>()) {
    sl.registerLazySingleton<HeadlessAvraiOsAvailabilityService>(
      () => HeadlessAvraiOsAvailabilityService(
        bootstrapService: sl<HeadlessAvraiOsBootstrapService>(),
      ),
    );
  }
  if (!sl.isRegistered<KernelOutcomeAttributionLane>()) {
    sl.registerLazySingleton<KernelOutcomeAttributionLane>(
      () => DefaultKernelOutcomeAttributionLane(
        functionalKernelOs: sl<FunctionalKernelOs>(),
      ),
    );
  }
  if (!sl.isRegistered<KernelIncidentRecorder>()) {
    sl.registerLazySingleton<KernelIncidentRecorder>(
      () => DefaultKernelIncidentRecorder(
        functionalKernelOs: sl<FunctionalKernelOs>(),
        securityTriggerIngressService:
            sl.isRegistered<SecurityTriggerIngressService>()
                ? sl<SecurityTriggerIngressService>()
                : null,
      ),
    );
  }
  if (!sl.isRegistered<KernelAdminService>()) {
    sl.registerLazySingleton<KernelAdminService>(
      () => DefaultKernelAdminService(
        telemetryService: sl<KernelTelemetryService>(),
        rootCauseIndex: sl<KernelRootCauseIndex>(),
      ),
    );
  }
  if (!sl.isRegistered<KernelConformanceService>()) {
    sl.registerLazySingleton<KernelConformanceService>(
      () => DefaultKernelConformanceService(
        host: sl<HeadlessAvraiOsHost>(),
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
        eventLearningSignalService:
            sl.isRegistered<EventLearningSignalService>()
                ? sl<EventLearningSignalService>()
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
        whereKernel: sl.isRegistered<WhereKernelContract>()
            ? sl<WhereKernelContract>()
            : null,
        headlessOsHost: sl.isRegistered<HeadlessAvraiOsHost>()
            ? sl<HeadlessAvraiOsHost>()
            : null,
        functionalKernelOs: sl.isRegistered<FunctionalKernelOs>()
            ? sl<FunctionalKernelOs>()
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
        whatRuntimeIngestionService:
            sl.isRegistered<WhatRuntimeIngestionService>()
                ? sl<WhatRuntimeIngestionService>()
                : null,
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
        connectivityService: sl<EnhancedConnectivityService>(),
        personalitySyncService: sl<PersonalitySyncService>(),
        personalityLearning: sl<PersonalityLearning>(),
      ));
}

void _registerAppPresentationLayer() {
  // Admin app only resolves AuthBloc from DI. Consumer app blocs stay out of
  // the standalone admin package.
  sl.registerFactory(() => AuthBloc(
        signInUseCase: sl(),
        signInWithGoogleUseCase: sl(),
        signInWithAppleUseCase: sl(),
        signUpUseCase: sl(),
        signOutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        updatePasswordUseCase: sl(),
      ));
}
