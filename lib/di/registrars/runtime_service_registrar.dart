// MIGRATION_SHIM: M10-P10-6 REMOVE_BY:M10-P10-7
part of '../../injection_container.dart';

Future<void> _registerRuntimeServiceLayer(AppLogger logger) async {
  // Data Sources - Local (Offline-First)
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthDriftDataSource());
  sl.registerLazySingleton<SpotsLocalDataSource>(() => SpotsDriftDataSource());
  sl.registerLazySingleton<ListsLocalDataSource>(() => ListsDriftDataSource());

  // Data Sources - Remote (Optional, for online features)
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl());
  sl.registerLazySingleton<SpotsRemoteDataSource>(
      () => SpotsRemoteDataSourceImpl());
  sl.registerLazySingleton<ListsRemoteDataSource>(
      () => ListsRemoteDataSourceImpl());

  // Tax document storage (middle-ground):
  // - Prefer Supabase Storage (private, per-user bucket) for new uploads.
  // - Keep Firebase Analytics intact; Firebase Storage remains supported for legacy URLs.
  if (!sl.isRegistered<TaxDocumentStorageService>()) {
    sl.registerLazySingleton<TaxDocumentStorageService>(
      () => TaxDocumentStorageService(
        supabaseService: sl.isRegistered<SupabaseService>()
            ? sl<SupabaseService>()
            : SupabaseService(),
        useSupabase: true,
        // We don't inject FirebaseStorage here to keep DI safe in runtimes where Firebase isn't initialized.
        // Legacy Firebase URLs can still be opened by URL launcher, and Firebase Storage can be wired later if needed.
        useFirebase: true,
      ),
    );
  }

  // Paperwork documents (retention-locked):
  // - Dispute evidence uploads go into `paperwork-documents` bucket (private)
  if (!sl.isRegistered<DisputeEvidenceStorageService>()) {
    sl.registerLazySingleton<DisputeEvidenceStorageService>(
      () => DisputeEvidenceStorageService(
        supabaseService: sl<SupabaseService>(),
        ledger: sl<LedgerRecorderServiceV0>(),
      ),
    );
  }

  // Disputes (in-memory v0). Must be a singleton so submission + status pages
  // can read the same dispute state in this temporary implementation.
  if (!sl.isRegistered<DisputeResolutionService>()) {
    sl.registerLazySingleton<DisputeResolutionService>(
      () => DisputeResolutionService(
        eventService: sl<ExpertiseEventService>(),
      ),
    );
  }

  // Google Places Cache Service (for offline caching)
  sl.registerLazySingleton<GooglePlacesCacheService>(
      () => GooglePlacesCacheService());

  // Get Google Places API key from config
  final googlePlacesApiKey = GooglePlacesConfig.getApiKey();
  if (googlePlacesApiKey.isEmpty) {
    logger.warn(
      '⚠️ [DI] GOOGLE_PLACES_API_KEY is not set; Google Places calls will return empty results until provided via --dart-define',
    );
  }

  // Google Place ID Finder Service (New API)
  sl.registerLazySingleton<GooglePlaceIdFinderServiceNew>(
      () => GooglePlaceIdFinderServiceNew(
            apiKey: googlePlacesApiKey.isNotEmpty
                ? googlePlacesApiKey
                : 'demo_key', // Fallback for development
          ));

  // External Data Sources - Using New Places API (New)
  sl.registerLazySingleton<GooglePlacesDataSource>(
      () => GooglePlacesDataSourceNewImpl(
            apiKey: googlePlacesApiKey.isNotEmpty
                ? googlePlacesApiKey
                : 'demo_key', // Fallback for development
            httpClient: sl<http.Client>(),
            cacheService: sl<GooglePlacesCacheService>(),
          ));
  sl.registerLazySingleton<OpenStreetMapDataSource>(
      () => OpenStreetMapDataSourceImpl(
            httpClient: sl<http.Client>(),
          ));

  // Google Places Sync Service (using New API)
  sl.registerLazySingleton<GooglePlacesSyncService>(
      () => GooglePlacesSyncService(
            placeIdFinderNew: sl<GooglePlaceIdFinderServiceNew>(),
            cacheService: sl<GooglePlacesCacheService>(),
            googlePlacesDataSource: sl<GooglePlacesDataSource>(),
            spotsLocalDataSource: sl<SpotsLocalDataSource>(),
            connectivity: sl<Connectivity>(),
          ));

  // Organic Spot Discovery Service (learns hidden locations from behavior)
  // Detects patterns in unmatched visits (parks, garages, hidden gems)
  // and clusters them into discovery candidates. Integrates with mesh for
  // community validation and with the learning pipeline for personality evolution.
  sl.registerLazySingleton<OrganicSpotDiscoveryService>(
      () => OrganicSpotDiscoveryService(
            atomicClock: sl<AtomicClockService>(),
          ));

  // Repositories (Register first)
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<SpotsRepository>(
    () => SpotsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  sl.registerLazySingleton<ListsRepository>(
    () => ListsRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
    ),
  );

  // Hybrid Search Repository (Phase 2) - Always available for offline search
  sl.registerLazySingleton(() => HybridSearchRepository(
        localDataSource: sl<SpotsLocalDataSource>(),
        remoteDataSource: sl<SpotsRemoteDataSource>(),
        googlePlacesDataSource: sl<GooglePlacesDataSource>(),
        osmDataSource: sl<OpenStreetMapDataSource>(),
        googlePlacesCache: sl<GooglePlacesCacheService>(),
        connectivity: sl<Connectivity>(),
      ));

  // Auth Use cases (Register after repositories)
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePasswordUseCase(sl()));

  // Spots Use cases (Register after repositories)
  sl.registerLazySingleton(() => GetSpotsUseCase(sl()));
  sl.registerLazySingleton(() => GetSpotsFromRespectedListsUseCase(sl()));
  sl.registerLazySingleton(() => CreateSpotUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSpotUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSpotUseCase(sl()));

  // Lists Use cases (Register after repositories)
  sl.registerLazySingleton(() => GetListsUseCase(sl()));
  sl.registerLazySingleton(() => CreateListUseCase(sl()));
  sl.registerLazySingleton(() => UpdateListUseCase(sl()));
  sl.registerLazySingleton(() => DeleteListUseCase(sl()));

  // Hybrid Search Use case (Phase 2)
  sl.registerLazySingleton(() => HybridSearchUseCase(sl()));

  // Services (Search services, StorageService, FeatureFlagService, Geographic services,
  // CommunityValidationService, AtomicClockService, UserVibeAnalyzer, and SharedPreferencesCompat
  // are now registered in registerCoreServices())

  // Phase 2: Missing Services
  // Register Phase 2 services (dependencies first)
  // Note: CommunityValidationService is registered in registerCoreServices()
  sl.registerLazySingleton<RoleManagementService>(
      () => RoleManagementServiceImpl(
            storageService: sl<StorageService>(),
            prefs: sl<SharedPreferencesCompat>(),
          ));

  // ============================================================================
  // SHARED FOUNDATIONAL SERVICES
  // ============================================================================
  // Register shared services that are used by multiple domain modules
  // These must be registered before domain modules are called
  // See PHASE_1_7_SHARED_SERVICES_ANALYSIS.md for details
  logger.debug('🔗 [DI] Registering shared foundational services...');

  // 1. BusinessAccountService (foundational - used by Payment, Admin, AI)
  sl.registerLazySingleton(() => BusinessAccountService());
  logger.debug('✅ [DI] BusinessAccountService registered (shared)');

  // ============================================================================
  // LEDGER PREREQS (must be registered before Event/Payment modules)
  // ============================================================================
  // These are needed early because v0 ledger writers are now called by foundational services
  // (events, partnerships, communities) and must not depend on late registration ordering.
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      ),
    );
  }
  if (!sl.isRegistered<SecureMappingEncryptionService>()) {
    sl.registerLazySingleton<SecureMappingEncryptionService>(
      () => SecureMappingEncryptionService(
        secureStorage: sl<FlutterSecureStorage>(),
      ),
    );
  }
  if (!sl.isRegistered<AgentIdService>()) {
    sl.registerLazySingleton(() => AgentIdService(
          encryptionService: sl<SecureMappingEncryptionService>(),
          businessService: sl<BusinessAccountService>(),
        ));
  }
  if (!sl.isRegistered<LedgerRecorderServiceV0>()) {
    sl.registerLazySingleton<LedgerRecorderServiceV0>(
      () => LedgerRecorderServiceV0(
        supabaseService: sl<SupabaseService>(),
        agentIdService: sl<AgentIdService>(),
        storage: sl<StorageService>(),
      ),
    );
  }
  if (!sl.isRegistered<LedgerReceiptsServiceV0>()) {
    sl.registerLazySingleton<LedgerReceiptsServiceV0>(
      () => LedgerReceiptsServiceV0(
        supabaseService: sl<SupabaseService>(),
      ),
    );
  }
  if (!sl.isRegistered<ProofRunServiceV0>()) {
    // Debug-only: skeptic-proof bundle receipts + export.
    sl.registerLazySingleton<ProofRunServiceV0>(
      () => ProofRunServiceV0(
        ledger: sl<LedgerRecorderServiceV0>(),
        supabase: sl<SupabaseService>(),
        prefs: sl<SharedPreferencesCompat>(),
      ),
    );
  }

  // 2. BusinessService (depends on BusinessAccountService)
  sl.registerLazySingleton<BusinessService>(() => BusinessService(
        accountService: sl<BusinessAccountService>(),
      ));
  logger.debug('✅ [DI] BusinessService registered (shared)');

  // 3. ExpertiseEventService (foundational event service - used by Payment, AI)
  sl.registerLazySingleton<ExpertiseEventService>(() => ExpertiseEventService(
        ledgerRecorder: sl<LedgerRecorderServiceV0>(),
      ));
  logger.debug('✅ [DI] ExpertiseEventService registered (shared)');

  logger.debug(
      '✅ [DI] Shared foundational services registered (BusinessAccountService, BusinessService, ExpertiseEventService)');
}
