import 'package:flutter/material.dart';
import 'package:avrai/app.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:avrai/core/services/infrastructure/storage_health_checker.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/data/datasources/local/onboarding_completion_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/crypto/signal/signal_protocol_service.dart';
import 'package:avrai/core/services/security/signal_protocol_initialization_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/local_llm/local_llm_auto_install_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_connectivity_listener.dart';
import 'package:avrai/core/services/infrastructure/deferred_initialization_service.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_bootstrap_guard.dart';
import 'package:avrai/core/services/infrastructure/runtime/runtime_contract_registry.dart';
import 'dart:async';

void main() async {
  // Performance tracking: Start measuring startup time
  final startupStartTime = DateTime.now();

  WidgetsFlutterBinding.ensureInitialized();
  const logger = AppLogger(defaultTag: 'MAIN', minimumLevel: LogLevel.debug);

  logger.info('🚀 [MAIN] App starting...');

  // Helper function to check if data already exists
  // Uses StorageService (GetStorage) since Sembast was removed in Phase 26
  Future<bool> checkIfDataExists() async {
    try {
      // Check for existing user data via StorageService
      final storageService = di.sl<StorageService>();
      final currentUser = storageService.getString('currentUser');
      logger.debug(
          'Current user check: ${currentUser != null ? "found" : "not found"}');
      return currentUser != null;
    } catch (e) {
      logger.error('Error checking data', error: e);
      return false;
    }
  }

  try {
    // ============================================================
    // PHASE 1: CRITICAL INITIALIZATION (Must complete before UI)
    // ============================================================
    final criticalStartTime = DateTime.now();

    // Initialize Firebase (mobile and desktop; web via options)
    // Firebase is required for some core features, so we keep it in critical path
    try {
      logger.info('🔥 [MAIN] Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.info('✅ [MAIN] Firebase initialized successfully');
    } catch (e, stackTrace) {
      logger.error('❌ [MAIN] Firebase init failed', error: e);
      logger.debug('Stack trace: $stackTrace');
      // Continue - Firebase is optional for some features
    }

    // Initialize DI and backend (avra_network creates Supabase backend under the hood)
    logger.info('🔧 [MAIN] Initializing dependency injection...');
    await di.init();
    logger.info('✅ [MAIN] Dependency injection initialized.');

    // Validate runtime/host contract compatibility before app boot.
    // Fail closed if host/runtime contracts are incompatible.
    final contractReport = RuntimeBootstrapGuard.validateOrThrow();
    logger.info(
        '✅ [MAIN] Runtime contract compatibility: ${contractReport.reason}');

    // Note: AppDatabase (Drift) is initialized via DI in injection_container_device_sync.dart
    // Sembast was fully removed in Phase 26 migration.

    final criticalEndTime = DateTime.now();
    final criticalDuration = criticalEndTime.difference(criticalStartTime);
    logger.info(
        '⏱️ [MAIN] Critical initialization completed in ${criticalDuration.inMilliseconds}ms');

    // ============================================================
    // PHASE 2: SHOW UI IMMEDIATELY
    // ============================================================
    final uiStartTime = DateTime.now();
    logger.info('🎬 [MAIN] Launching app UI...');
    runApp(const SpotsApp());

    final uiEndTime = DateTime.now();
    final uiDuration = uiEndTime.difference(uiStartTime);
    final timeToFirstFrame = uiEndTime.difference(startupStartTime);
    logger.info('⏱️ [MAIN] UI launched in ${uiDuration.inMilliseconds}ms');
    logger.info(
        '⏱️ [MAIN] Time to first frame: ${timeToFirstFrame.inMilliseconds}ms');

    // ============================================================
    // PHASE 3: DEFERRED INITIALIZATION (Background, non-blocking)
    // ============================================================
    unawaited(_initializeDeferredServices(logger, checkIfDataExists));

    final totalStartupTime = DateTime.now().difference(startupStartTime);
    logger.info(
        '✅ [MAIN] App startup sequence completed. Total time: ${totalStartupTime.inMilliseconds}ms');
  } on RuntimeContractIncompatibilityException catch (e, stackTrace) {
    logger.error('❌ [MAIN] Runtime contract compatibility failed', error: e);
    logger.debug('Stack trace: $stackTrace');
    _runRuntimeContractBlockedApp(e.reason);
  } catch (e, stackTrace) {
    logger.error('❌ [MAIN] Error during app initialization', error: e);
    logger.debug('Stack trace: $stackTrace');
    // Still run the app even if there are errors
    logger.info('🔄 [MAIN] Attempting to run app despite errors...');
    runApp(const SpotsApp());
  }
}

void _runRuntimeContractBlockedApp(String reason) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Runtime Contract Incompatible',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update AVRAI Runtime or host adapter to continue.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Initialize non-critical services in the background after UI has rendered.
/// This improves perceived startup performance by showing UI immediately.
Future<void> _initializeDeferredServices(
  AppLogger logger,
  Future<bool> Function() checkIfDataExists,
) async {
  final deferredStartTime = DateTime.now();
  logger.info('🔄 [MAIN] Starting deferred service initialization...');

  final deferredInit = DeferredInitializationService();

  // Priority 1: Local LLM auto-install (lowest priority number = highest priority)
  deferredInit.addTask(
    priority: 1,
    name: 'Local LLM Auto-Install',
    initializer: () async {
      try {
        await LocalLlmAutoInstallService().maybeAutoInstall();
      } catch (e) {
        logger.debug('Local LLM auto-install failed: $e');
        // Ignore - this is best-effort
      }
    },
  );

  // Priority 2: Atomic Clock Service (important for time-sensitive features)
  deferredInit.addTask(
    priority: 2,
    name: 'Atomic Clock Service',
    initializer: () async {
      try {
        final atomicClock = di.sl<AtomicClockService>();
        final supabaseService = di.sl<SupabaseService>();
        atomicClock.configure(
          serverTimeProvider: () => supabaseService.getServerTime(),
        );
        await atomicClock.initialize();
        logger.info(
          '✅ [MAIN] AtomicClockService initialized (synchronized=${atomicClock.isSynchronized()})',
        );
      } catch (e, stackTrace) {
        logger.warn('⚠️ [MAIN] AtomicClockService init failed (non-fatal): $e');
        logger.debug('Stack trace: $stackTrace');
        rethrow; // Let deferred service handle the error
      }
    },
  );

  // Priority 3: Signal Protocol (important for secure communication)
  deferredInit.addTask(
    priority: 3,
    name: 'Signal Protocol',
    initializer: () async {
      try {
        final signalInitService = di.sl<SignalProtocolInitializationService>();
        await signalInitService.initialize();
        logger.info('✅ [MAIN] Signal Protocol initialized');

        // Best-effort: publish prekey bundle if user is authenticated
        try {
          final supabaseService = di.sl<SupabaseService>();
          final currentUser = supabaseService.currentUser;
          if (currentUser != null && currentUser.id.isNotEmpty) {
            final signalProtocol = di.sl<SignalProtocolService>();
            await signalProtocol.uploadPreKeyBundle(currentUser.id);
            logger.info(
              '✅ [MAIN] Published Signal prekey bundle for userId=${currentUser.id}',
            );
          } else {
            logger.info(
              'ℹ️ [MAIN] No authenticated user yet; skipping prekey bundle publish',
            );
          }
        } catch (e, stackTrace) {
          logger.warn('⚠️ [MAIN] Prekey bundle publish failed (non-fatal): $e');
          logger.debug('Stack trace: $stackTrace');
        }
      } catch (e, stackTrace) {
        logger.warn('⚠️ [MAIN] Signal Protocol initialization failed: $e');
        logger.debug('Stack trace: $stackTrace');
        logger.info('ℹ️ [MAIN] App will use fallback encryption (AES-256-GCM)');
        rethrow; // Let deferred service handle the error
      }
    },
  );

  // Priority 4: Storage Health Check (diagnostic, not critical)
  deferredInit.addTask(
    priority: 4,
    name: 'Storage Health Check',
    initializer: () async {
      try {
        // Only check storage if Supabase is initialized
        try {
          final client = Supabase.instance.client;
          final storageHealth = StorageHealthChecker(client);
          final results = await storageHealth.checkAllBuckets([
            'user-avatars',
            'spot-images',
            'list-images',
          ]);
          logger.info(
            '✅ [MAIN] Storage health: ${results.entries.map((e) => '${e.key}=${e.value ? 'OK' : 'FAIL'}').join(', ')}',
          );
        } catch (e) {
          logger.warn(
            '⚠️ [MAIN] Supabase not initialized, skipping storage health check: $e',
          );
        }
      } catch (e) {
        logger.warn('⚠️ [MAIN] Storage health check error: $e');
        rethrow;
      }
    },
  );

  // Priority 5: Quantum Matching Connectivity Listener
  deferredInit.addTask(
    priority: 5,
    name: 'Quantum Matching Connectivity Listener',
    initializer: () async {
      try {
        if (di.sl.isRegistered<QuantumMatchingConnectivityListener>()) {
          final connectivityListener =
              di.sl<QuantumMatchingConnectivityListener>();
          await connectivityListener.start();
          logger
              .info('✅ [MAIN] Quantum matching connectivity listener started');
        } else {
          logger.debug(
            'ℹ️ [MAIN] QuantumMatchingConnectivityListener not registered, skipping',
          );
        }
      } catch (e, stackTrace) {
        logger.warn(
            '⚠️ [MAIN] Connectivity listener init failed (non-fatal): $e');
        logger.debug('Stack trace: $stackTrace');
        rethrow;
      }
    },
  );

  // Priority 6: Demo user cleanup (maintenance, not critical)
  deferredInit.addTask(
    priority: 6,
    name: 'Demo User Cleanup',
    initializer: () async {
      try {
        logger.info('🧹 [MAIN] Clearing demo user cache and data...');
        OnboardingCompletionService.clearAllCache();
        await OnboardingCompletionService.resetOnboardingCompletion(
            'demo-user-1');

        // Clear demo user via StorageService (Phase 26: Sembast removed)
        try {
          final storageService = di.sl<StorageService>();
          await storageService.remove('demo-user-1');
          await storageService.remove('currentUser');
        } catch (_) {
          // StorageService may not be initialized yet in some startup sequences
        }

        logger.info('✅ [MAIN] Demo user cache and data cleared.');
      } catch (e) {
        logger.warn('⚠️ [MAIN] Error clearing demo user cache: $e');
        rethrow;
      }
    },
  );

  // Priority 7: Database seeding (only if needed, not critical)
  deferredInit.addTask(
    priority: 7,
    name: 'Database Seeding',
    initializer: () async {
      try {
        logger.info('🔍 [MAIN] Checking if data exists...');
        final hasData = await checkIfDataExists();
        if (!hasData) {
          logger.info(
              '🌱 [MAIN] No existing data found. Seeding skipped (Sembast seeder removed in Phase 26).');
          // TODO(Phase 1.1): Implement Drift-based seeder if demo data is needed
        } else {
          logger.info('ℹ️ [MAIN] Data already exists, skipping seeding.');
        }
      } catch (e) {
        logger.warn('⚠️ [MAIN] Error seeding database: $e');
        rethrow;
      }
    },
  );

  // Start deferred initialization (runs in background)
  await deferredInit.start();

  final deferredEndTime = DateTime.now();
  final deferredDuration = deferredEndTime.difference(deferredStartTime);
  logger.info(
    '⏱️ [MAIN] Deferred initialization completed in ${deferredDuration.inMilliseconds}ms',
  );
  logger.info(
    '📊 [MAIN] Completed tasks: ${deferredInit.completedTasks.join(", ")}',
  );
  if (deferredInit.failedTasks.isNotEmpty) {
    logger.warn(
      '⚠️ [MAIN] Failed tasks: ${deferredInit.failedTasks.join(", ")}',
    );
  }
}
