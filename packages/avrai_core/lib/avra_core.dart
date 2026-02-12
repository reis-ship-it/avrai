// AVRA Core Library
// Main export file for core models, enums, and interfaces

// Enums
export 'enums/user_enums.dart';
export 'enums/spot_enums.dart';
export 'enums/list_enums.dart';

// Models
export 'models/user.dart';
export 'models/spot.dart';
export 'models/spot_list.dart';
export 'models/user_vibe.dart';
export 'models/community.dart';
export 'models/mood_state.dart';
export 'models/unified_location_data.dart';
export 'models/social_context.dart';

// Repository interfaces
export 'repositories/auth_repository.dart';
export 'repositories/spots_repository.dart';
export 'repositories/lists_repository.dart';

// Common utilities
export 'utils/validation.dart';
export 'utils/constants.dart';
export 'utils/vibe_constants.dart';
export 'utils/attraction_dimensions.dart';

// Core services
export 'services/atomic_clock_service.dart';
export 'services/community_reader.dart';
export 'services/key_value_store.dart';
export 'services/logger.dart';

// Core models
export 'models/atomic_timestamp.dart';

// Quantum models (moved from avrai_quantum)
export 'models/quantum_entity_type.dart';
export 'models/quantum_entity_state.dart';

// Personality models (moved from avrai_ai/avrai_knot)
export 'models/contextual_personality.dart';
export 'models/personality_knot.dart';
export 'models/personality_profile.dart';
