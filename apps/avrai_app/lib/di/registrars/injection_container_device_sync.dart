import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';
import 'package:get_it/get_it.dart';

import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/infrastructure/supabase_service.dart';
import 'package:avrai_runtime_os/crypto/signal/device_registration_service.dart';
import 'package:avrai_runtime_os/crypto/signal/signal_key_manager.dart';
import 'package:avrai_runtime_os/crypto/signal/secure_signal_storage.dart';
import 'package:avrai_runtime_os/services/device_link/auto_device_link_service.dart';
import 'package:avrai_runtime_os/services/device_link/numeric_code_service.dart';
import 'package:avrai_runtime_os/services/device_link/push_pairing_service.dart';
import 'package:avrai_runtime_os/services/device_link/secure_bypass_service.dart';
import 'package:avrai_runtime_os/services/device_link/history_transfer_service.dart';
import 'package:avrai_runtime_os/services/device_link/session_transfer_service.dart';
import 'package:avrai_runtime_os/services/device_sync/sync_state_service.dart';
import 'package:avrai_runtime_os/data/database/app_database.dart';
import 'package:avrai_runtime_os/data/objectbox/objectbox_store.dart';

/// Device Sync and Storage Migration Services Registration Module
///
/// Registers services for Phase 26: Multi-Device Sync and Storage Migration.
///
/// **Services Registered:**
/// - AppDatabase (Drift)
/// - ObjectBoxStore
/// - SecureSignalStorage
/// - DeviceRegistrationService (enhanced)
/// - Device Link Services (AutoDeviceLinkService, NumericCodeService, etc.)
/// - SyncStateService
/// - HistoryTransferService
/// - SessionTransferService
/// - StorageMigrationService
Future<void> registerDeviceSyncServices(GetIt sl) async {
  const logger = AppLogger(
    defaultTag: 'DI-DeviceSync',
    minimumLevel: LogLevel.debug,
  );
  logger.debug('📱 [DI-DeviceSync] Registering Phase 26 services...');

  // ============================================================
  // STORAGE LAYER
  // ============================================================

  // Drift Database (SQLite)
  if (!sl.isRegistered<AppDatabase>()) {
    sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
    logger.debug('✅ [DI-DeviceSync] AppDatabase (Drift) registered');
  }

  // ObjectBox Store
  if (!sl.isRegistered<ObjectBoxStore>()) {
    final objectBoxStore = ObjectBoxStore.instance;
    // Note: ObjectBoxStore.initialize() should be called during app startup
    sl.registerLazySingleton<ObjectBoxStore>(() => objectBoxStore);
    logger.debug('✅ [DI-DeviceSync] ObjectBoxStore registered');
  }

  // Secure Signal Storage
  if (!sl.isRegistered<SecureSignalStorage>()) {
    sl.registerLazySingleton<SecureSignalStorage>(
      () => SecureSignalStorage(
        secureStorage: const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] SecureSignalStorage registered');
  }

  // ============================================================
  // DEVICE REGISTRATION
  // ============================================================

  // Device Registration Service (enhanced with Supabase persistence)
  if (!sl.isRegistered<DeviceRegistrationService>()) {
    sl.registerLazySingleton<DeviceRegistrationService>(
      () => DeviceRegistrationService(
        keyManager: sl<SignalKeyManager>(),
        supabaseService:
            sl.isRegistered<SupabaseService>() ? sl<SupabaseService>() : null,
        secureStorage: const FlutterSecureStorage(
          aOptions: AndroidOptions(),
        ),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] DeviceRegistrationService registered');
  }

  // ============================================================
  // DEVICE LINK SERVICES
  // ============================================================

  // Auto Device Link Service (Same-Account Login)
  if (!sl.isRegistered<AutoDeviceLinkService>()) {
    sl.registerLazySingleton<AutoDeviceLinkService>(
      () => AutoDeviceLinkService(
        supabaseService: sl<SupabaseService>(),
        deviceRegistrationService: sl<DeviceRegistrationService>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] AutoDeviceLinkService registered');
  }

  // Numeric Code Service
  if (!sl.isRegistered<NumericCodeService>()) {
    sl.registerLazySingleton<NumericCodeService>(
      () => NumericCodeService(
        supabaseService: sl<SupabaseService>(),
        deviceRegistrationService: sl<DeviceRegistrationService>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] NumericCodeService registered');
  }

  // Push Pairing Service
  if (!sl.isRegistered<PushPairingService>()) {
    sl.registerLazySingleton<PushPairingService>(
      () => PushPairingService(
        supabaseService: sl<SupabaseService>(),
        deviceRegistrationService: sl<DeviceRegistrationService>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] PushPairingService registered');
  }

  // Secure Bypass Service
  if (!sl.isRegistered<SecureBypassService>()) {
    sl.registerLazySingleton<SecureBypassService>(
      () => SecureBypassService(
        supabaseService: sl<SupabaseService>(),
        deviceRegistrationService: sl<DeviceRegistrationService>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] SecureBypassService registered');
  }

  // ============================================================
  // SYNC AND TRANSFER SERVICES
  // ============================================================

  // Sync State Service
  if (!sl.isRegistered<SyncStateService>()) {
    sl.registerLazySingleton<SyncStateService>(
      () => SyncStateService(
        supabaseService: sl<SupabaseService>(),
        deviceRegistrationService: sl<DeviceRegistrationService>(),
        database: sl.isRegistered<AppDatabase>() ? sl<AppDatabase>() : null,
      ),
    );
    logger.debug('✅ [DI-DeviceSync] SyncStateService registered');
  }

  // History Transfer Service
  if (!sl.isRegistered<HistoryTransferService>()) {
    sl.registerLazySingleton<HistoryTransferService>(
      () => HistoryTransferService(
        database: sl<AppDatabase>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] HistoryTransferService registered');
  }

  // Session Transfer Service
  if (!sl.isRegistered<SessionTransferService>()) {
    sl.registerLazySingleton<SessionTransferService>(
      () => SessionTransferService(
        secureStorage: sl<SecureSignalStorage>(),
      ),
    );
    logger.debug('✅ [DI-DeviceSync] SessionTransferService registered');
  }

  logger.debug('📱 [DI-DeviceSync] All Phase 26 services registered');
}
