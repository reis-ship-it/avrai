// TODO(Phase 0.5.0): Remove this suppression after AI2AIProtocol callers migrate to DNAEncoderService.
// ignore_for_file: deprecated_member_use

// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
part of '../../injection_container.dart';

Future<void> _registerEngineServiceLayer(AppLogger logger) async {
  // 1. Knot Services (no domain dependencies)
  await EngineBootstrap.initialize(
    sl: sl,
    registerEngineServices: () => registerKnotServices(sl),
  );
  logger.debug('✅ [DI] Knot services registered');

  // Community repository (local-first, optional Supabase sync behind feature flag).
  if (!sl.isRegistered<CommunityRepository>()) {
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
    logger.debug('✅ [DI] CommunityRepository registered (hybrid)');
  }

  // Register CommunityService after Knot module (it has optional Knot dependencies)
  sl.registerLazySingleton(() => CommunityService(
        expansionService: GeographicExpansionService(),
        knotFabricService: sl<KnotFabricService>(),
        knotStorageService: sl<KnotStorageService>(),
        storageService: sl<StorageService>(),
        atomicClockService: sl<AtomicClockService>(),
        repository: sl<CommunityRepository>(),
        ledgerRecorder: sl<LedgerRecorderServiceV0>(),
        entitySignatureService: sl.isRegistered<EntitySignatureService>()
            ? sl<EntitySignatureService>()
            : null,
      ));
  logger
      .debug('✅ [DI] CommunityService registered (shared, after Knot module)');

  if (!sl.isRegistered<AirGapNormalizer>()) {
    sl.registerLazySingleton<AirGapNormalizer>(() => const AirGapNormalizer());
  }
  if (!sl.isRegistered<EntityFitRouter>()) {
    sl.registerLazySingleton<EntityFitRouter>(() => const EntityFitRouter());
  }
  if (!sl.isRegistered<OrganizerSyncConnectionAdvisor>()) {
    sl.registerLazySingleton<OrganizerSyncConnectionAdvisor>(
      () => const OrganizerSyncConnectionAdvisor(),
    );
  }
  if (!sl.isRegistered<SourceIntakeOrchestrator>()) {
    sl.registerLazySingleton<SourceIntakeOrchestrator>(
      () => SourceIntakeOrchestrator(
        normalizer: sl<AirGapNormalizer>(),
        fitRouter: sl<EntityFitRouter>(),
        repository: sl<UniversalIntakeRepository>(),
        eventService: sl<ExpertiseEventService>(),
        communityService: sl<CommunityService>(),
        spotsLocalDataSource: sl<SpotsLocalDataSource>(),
        atomicClockService: sl<AtomicClockService>(),
        entitySignatureService: sl.isRegistered<EntitySignatureService>()
            ? sl<EntitySignatureService>()
            : null,
        remoteSourceHealthService: sl.isRegistered<RemoteSourceHealthService>()
            ? sl<RemoteSourceHealthService>()
            : null,
      ),
    );
  }

  // 2. Payment Services (depends on BusinessService, ExpertiseEventService)
  await registerPaymentServices(sl);
  logger.debug('✅ [DI] Payment services registered');

  // Register PostEventFeedbackService (needed by EventSuccessAnalysisService)
  // Note: PartnershipService is optional, so we check if it's registered
  sl.registerLazySingleton(() => PostEventFeedbackService(
        eventService: sl<ExpertiseEventService>(),
        partnershipService: sl.isRegistered<PartnershipService>()
            ? sl<PartnershipService>()
            : null,
      ));
  logger.debug(
      '✅ [DI] PostEventFeedbackService registered (shared, after Payment module)');

  // Register EventSuccessAnalysisService (depends on ExpertiseEventService, PostEventFeedbackService, optional PaymentService)
  sl.registerLazySingleton(() => EventSuccessAnalysisService(
        eventService: sl<ExpertiseEventService>(),
        feedbackService: sl<PostEventFeedbackService>(),
        paymentService: sl<PaymentService>(), // Optional, from Payment module
      ));
  logger.debug(
      '✅ [DI] EventSuccessAnalysisService registered (shared, after Payment module)');

  // 3. Quantum Services (depends on Knot services, EventSuccessAnalysisService)
  await EngineBootstrap.initialize(
    sl: sl,
    registerEngineServices: () => registerQuantumServices(sl),
  );
  logger.debug('✅ [DI] Quantum services registered');

  // Message Encryption Service (Phase 14.4: Signal Protocol Integration)
  // MUST be registered BEFORE AI services (AI2AIProtocol depends on it)
  // Uses HybridEncryptionService which tries Signal Protocol first, falls back to AES-256-GCM
  sl.registerLazySingleton<MessageEncryptionService>(
    () {
      final supabaseService = sl<SupabaseService>();
      final atomicClock = sl<AtomicClockService>();

      // Create Signal Protocol Encryption Service (will be used if Signal Protocol is available)
      // Note: SignalProtocolService is registered later in backend initialization, so check if registered
      SignalProtocolEncryptionService? signalProtocolEncryptionService;
      if (sl.isRegistered<SignalProtocolService>()) {
        try {
          final signalProtocolService = sl<SignalProtocolService>();
          signalProtocolEncryptionService = SignalProtocolEncryptionService(
            signalProtocol: signalProtocolService,
            supabaseService: supabaseService,
            atomicClock: atomicClock,
          );
        } catch (e) {
          logger.warn(
              '⚠️ [DI] Signal Protocol Encryption Service creation failed: $e');
          signalProtocolEncryptionService = null;
        }
      } else {
        logger.debug(
            'ℹ️ [DI] SignalProtocolService not registered yet, MessageEncryptionService will use AES-256-GCM fallback');
      }

      // Create hybrid service that tries Signal Protocol first, falls back to AES-256-GCM
      return HybridEncryptionService(
        signalProtocolService: signalProtocolEncryptionService,
      );
    },
  );
  logger.debug('✅ [DI] MessageEncryptionService registered');

  // 4. AI Services (depends on Knot, Quantum, and Payment services via PartnershipService)
  await EngineBootstrap.initialize(
    sl: sl,
    registerEngineServices: () => registerAIServices(sl),
  );
  logger.debug('✅ [DI] AI services registered');

  // 5. Admin Services (depends on BusinessAccountService, may depend on AI services)
  await registerAdminServices(sl);
  logger.debug('✅ [DI] Admin services registered');

  // 6. Predictive Outreach Services (depends on AI, Knot, Quantum services)
  await AppBootstrap.initialize(
    sl: sl,
    registerAppServices: () => registerPredictiveOutreachServices(sl),
  );
  logger.debug('✅ [DI] Predictive outreach services registered');
}
