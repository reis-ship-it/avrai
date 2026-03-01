import 'package:get_it/get_it.dart';
import 'package:avrai_runtime_os/services/infrastructure/logger.dart';
import 'package:avrai_runtime_os/services/matching/attraction_12d_resolver.dart';
import 'package:avrai_runtime_os/services/matching/patron_prefs_to_12d_mapper.dart';
import 'package:avrai_runtime_os/services/matching/vibe_compatibility_service.dart';
import 'package:avrai_runtime_os/ai/personality_learning.dart';
import 'package:avrai_runtime_os/runtime_api.dart';
import 'package:avrai_runtime_os/ai/quantum/multi_scale_quantum_state_service.dart';

/// Compatibility Services Registration Module
///
/// Registers vibe/compatibility services used across payment, AI, quantum, and
/// business modules. Separated from payment so compatibility logic has no
/// payment-specific dependencies.
///
/// **Services:**
/// - Attraction12DResolver: entity → attraction 12D for user–business/event/place
/// - VibeCompatibilityService: quantum + knot compatibility scoring
///
/// **Dependencies:** PersonalityLearning, knot services (from Knot module).
/// **Consumers:** PartnershipService, SponsorshipService, EventRecommendationService,
/// GroupMatchingService, BusinessPlaceKnotService.
Future<void> registerCompatibilityServices(GetIt sl) async {
  const logger =
      AppLogger(defaultTag: 'DI-Compatibility', minimumLevel: LogLevel.debug);
  logger.debug('🔗 [DI-Compatibility] Registering compatibility services...');

  // Attraction 12D resolver: entity → attraction 12D for user–business/event/place.
  sl.registerLazySingleton<Attraction12DResolver>(
    () => Attraction12DResolver(patronPrefsTo12D: patronPrefsTo12D),
  );

  // Truthful vibe compatibility service (quantum + knot).
  // Phase 2: Enhanced with MultiScaleQuantumStateService
  sl.registerLazySingleton<VibeCompatibilityService>(
    () => QuantumKnotVibeCompatibilityService(
      personalityLearning: sl<PersonalityLearning>(),
      personalityKnotService: sl<PersonalityKnotService>(),
      entityKnotService: sl<EntityKnotService>(),
      attractionResolver: sl<Attraction12DResolver>(),
      multiScaleService: sl.isRegistered<MultiScaleQuantumStateService>()
          ? sl<MultiScaleQuantumStateService>()
          : null,
    ),
  );

  logger.debug('✅ [DI-Compatibility] Compatibility services registered');
}
