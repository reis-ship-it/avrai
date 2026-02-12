import 'package:get_it/get_it.dart';
import 'package:avrai/core/services/infrastructure/logger.dart';
import 'package:avrai/core/services/admin/admin_auth_service.dart';
import 'package:avrai/core/services/business/business_auth_service.dart';
import 'package:avrai/core/services/admin/admin_god_mode_service.dart';
import 'package:avrai/core/services/admin/admin_communication_service.dart';
import 'package:avrai/core/services/business/business_account_service.dart';
import 'package:avrai/core/ml/predictive_analytics.dart';
import 'package:avrai/core/monitoring/connection_monitor.dart';
import 'package:avrai/core/services/expertise/expertise_service.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart' show SharedPreferencesCompat;

/// Admin Services Registration Module
/// 
/// Registers all admin-related services.
/// This includes:
/// - Admin authentication services
/// - Admin communication services
/// - Admin god-mode services
/// - Connection monitoring for admin
Future<void> registerAdminServices(GetIt sl) async {
  const logger = AppLogger(defaultTag: 'DI-Admin', minimumLevel: LogLevel.debug);
  logger.debug('🔐 [DI-Admin] Registering admin services...');

  // Admin Services (God-Mode Admin System)
  // ConnectionMonitor is required for admin monitoring
  sl.registerLazySingleton(
      () => ConnectionMonitor(prefs: sl<SharedPreferencesCompat>()));

  // PredictiveAnalytics for admin analytics
  sl.registerLazySingleton(() => PredictiveAnalytics());

  // Note: BusinessAccountService is registered as a shared service in main container

  // AdminAuthService (authentication for admin access)
  sl.registerLazySingleton(
      () => AdminAuthService(sl<SharedPreferencesCompat>()));

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
        chatAnalyzer: null, // Optional - can be registered later if needed
      ));

  // AdminGodModeService (orchestrator for admin operations)
  sl.registerLazySingleton(() => AdminGodModeService(
        authService: sl<AdminAuthService>(),
        communicationService: sl<AdminCommunicationService>(),
        businessService: sl<BusinessAccountService>(),
        predictiveAnalytics: sl<PredictiveAnalytics>(),
        connectionMonitor: sl<ConnectionMonitor>(),
        chatAnalyzer: null, // Optional - can be registered later if needed
        supabaseService: sl<SupabaseService>(),
        expertiseService: ExpertiseService(),
      ));

  logger.debug('✅ [DI-Admin] Admin services registered');
}
