// MIGRATION_SHIM: Legacy infrastructure barrel retained temporarily while
// contracts migrate to target-root architecture slices.
/// Barrel file for infrastructure - re-exports all public APIs.
/// Generated as part of Phase 10.5 codebase reorganization.
library;

export 'ab_testing_service.dart';
export 'config_service.dart';
export 'deferred_initialization_service.dart';
export 'deployment_validator.dart';
export 'feature_flag_service.dart';
export 'logger.dart';
export 'auth/auth.dart';
export 'oauth/oauth.dart';
export 'oauth_deep_link_handler.dart';
export 'performance_monitor.dart';
export 'search_cache_service.dart';
export 'storage_health_checker.dart';
export 'storage_service.dart';
export 'supabase_service.dart';
