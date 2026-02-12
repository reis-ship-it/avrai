/// OUR_GUTS.md: "AI2AI personality learning with complete privacy preservation"
/// Vibe Constants for AI2AI Personality Learning Network
///
/// This file lives in `spots_core` so that non-app packages can depend on it
/// without importing `package:avrai/...` (the app).
class VibeConstants {
  // ======= CONNECTION THRESHOLDS =======
  /// High compatibility threshold for deep AI2AI learning
  static const double highCompatibilityThreshold = 0.8;

  /// Medium compatibility threshold for moderate AI2AI interaction
  static const double mediumCompatibilityThreshold = 0.5;

  /// Low compatibility threshold for basic AI2AI awareness
  static const double lowCompatibilityThreshold = 0.2;

  /// Minimum compatibility for any AI2AI connection
  static const double minimumCompatibilityThreshold = 0.1;

  // ======= LEARNING RATES =======
  /// Rate at which personality dimensions evolve from user behavior
  static const double personalityLearningRate = 0.1;

  /// Rate at which new dimensions are discovered from feedback
  static const double dimensionLearningRate = 0.05;

  /// Rate at which AI2AI interactions influence personality
  static const double ai2aiLearningRate = 0.03;

  /// Rate at which cloud patterns influence local personality
  static const double cloudLearningRate = 0.02;

  // ======= PRIVACY SETTINGS =======
  /// Days after which vibe signatures expire and are regenerated
  static const int vibeSignatureExpiryDays = 30;

  /// Level of differential privacy noise added to vibe signatures
  static const double privacyNoiseLevel = 0.02;

  /// Maximum entropy allowed in personality fingerprints
  static const double maxEntropyThreshold = 0.95;

  /// Minimum anonymization required for AI2AI communication
  static const double minAnonymizationLevel = 0.98;

  // ======= CORE PERSONALITY DIMENSIONS =======
  /// The 12 foundational personality dimensions from VIBE_CODING
  /// Philosophy: "Understanding which doors resonate with you"
  /// Expanded from 8 to 12 for more precise spot and community matching
  static const List<String> coreDimensions = [
    // Original 8 dimensions
    'exploration_eagerness', // How eager for new discovery
    'community_orientation', // Preference for social vs solo experiences
    'authenticity_preference', // Preference for authentic vs curated experiences
    'social_discovery_style', // How they prefer to discover through others
    'temporal_flexibility', // Spontaneous vs planned approach
    'location_adventurousness', // How far they're willing to travel
    'curation_tendency', // How much they curate for others
    'trust_network_reliance', // How much they rely on trusted connections
    // NEW: 4 additional dimensions (Phase 2: Philosophy Implementation)
    'energy_preference', // Chill/relaxed (0.0) ↔ High-energy/active (1.0)
    'novelty_seeking', // Familiar/routine (0.0) ↔ Always new (1.0)
    'value_orientation', // Budget-conscious (0.0) ↔ Premium/luxury (1.0)
    'crowd_tolerance', // Quiet/intimate (0.0) ↔ Bustling/popular (1.0)
  ];

  // ======= DIMENSION VALUE RANGES =======
  /// All personality dimensions operate on 0.0 to 1.0 scale
  static const double minDimensionValue = 0.0;
  static const double maxDimensionValue = 1.0;
  static const double defaultDimensionValue = 0.5;

  // ======= AI2AI CONNECTION PARAMETERS =======
  /// Maximum number of simultaneous AI2AI connections
  static const int maxSimultaneousConnections = 12;

  /// Minimum duration for meaningful AI2AI interaction (seconds)
  static const int minInteractionDurationSeconds = 30;

  /// Maximum duration for single AI2AI interaction (seconds)
  static const int maxInteractionDurationSeconds = 300;

  /// Cooldown period between AI2AI connections (seconds)
  static const int connectionCooldownSeconds = 60;

  // ======= VIBE ANALYSIS PARAMETERS =======
  /// Minimum number of user actions needed for personality analysis
  static const int minActionsForAnalysis = 10;

  /// Number of recent actions to consider for personality evolution
  static const int recentActionsWindow = 100;

  /// Weight given to recent actions vs historical actions
  static const double recentActionsWeight = 0.7;

  /// Confidence threshold for personality dimension certainty
  static const double personalityConfidenceThreshold = 0.6;

  // ======= DIMENSION DESCRIPTIONS =======
  /// Human-readable descriptions for each dimension (for UI/admin tools)
  static const Map<String, String> dimensionDescriptions = {
    'exploration_eagerness':
        'How eager for discovering new places and experiences',
    'community_orientation': 'Preference for social vs solo experiences',
    'authenticity_preference':
        'Preference for authentic vs curated experiences',
    'social_discovery_style': 'How they prefer to discover through others',
    'temporal_flexibility': 'Spontaneous vs planned approach to activities',
    'location_adventurousness': 'How far willing to travel for experiences',
    'curation_tendency': 'How much they curate and share for others',
    'trust_network_reliance': 'How much they rely on trusted connections',
    'energy_preference':
        'Preference for chill/relaxed vs high-energy/active experiences',
    'novelty_seeking': 'Preference for new places vs returning to favorites',
    'value_orientation': 'Budget-conscious vs premium/luxury preferences',
    'crowd_tolerance':
        'Preference for quiet/intimate vs bustling/popular places',
  };

  // ======= NETWORK TOPOLOGY LIMITS =======
  /// Maximum depth for AI2AI learning propagation
  static const int maxLearningPropagationDepth = 3;

  /// Maximum number of AI personalities in local network
  static const int maxLocalNetworkSize = 50;

  /// Minimum network density for effective learning
  static const double minNetworkDensity = 0.3;

  // ======= PERFORMANCE OPTIMIZATION =======
  /// Maximum processing time for vibe analysis (milliseconds)
  static const int maxVibeAnalysisTimeMs = 500;

  /// Maximum processing time for AI2AI connection establishment (milliseconds)
  static const int maxConnectionEstablishmentTimeMs = 1000;

  /// Batch size for processing multiple vibe analyses
  static const int vibeAnalysisBatchSize = 5;

  /// Cache duration for vibe analysis results (minutes)
  static const int vibeAnalysisCacheDurationMinutes = 15;

  // ======= QUALITY METRICS =======
  /// Minimum learning effectiveness score for continuing AI2AI connection
  static const double minLearningEffectiveness = 0.4;

  /// Minimum AI pleasure score for positive interaction outcome
  static const double minAIPleasureScore = 0.6;

  /// Maximum noise tolerance in personality signals
  static const double maxPersonalityNoiseThreshold = 0.15;

  // ======= ARCHETYPE CONFIGURATIONS =======
  /// Personality archetypes based on dimension combinations
  static const Map<String, Map<String, double>> personalityArchetypes = {
    'adventurous_explorer': {
      'exploration_eagerness': 0.9,
      'location_adventurousness': 0.8,
      'temporal_flexibility': 0.7,
      'community_orientation': 0.6,
    },
    'community_curator': {
      'community_orientation': 0.9,
      'curation_tendency': 0.8,
      'trust_network_reliance': 0.7,
      'authenticity_preference': 0.8,
    },
    'authentic_seeker': {
      'authenticity_preference': 0.9,
      'exploration_eagerness': 0.7,
      'social_discovery_style': 0.6,
      'community_orientation': 0.5,
    },
    'social_connector': {
      'social_discovery_style': 0.9,
      'community_orientation': 0.8,
      'trust_network_reliance': 0.7,
      'curation_tendency': 0.6,
    },
    'spontaneous_wanderer': {
      'temporal_flexibility': 0.9,
      'exploration_eagerness': 0.8,
      'location_adventurousness': 0.7,
      'authenticity_preference': 0.6,
    },
  };

  // ======= ERROR HANDLING =======
  /// Maximum retry attempts for failed AI2AI connections
  static const int maxConnectionRetryAttempts = 3;

  /// Backoff multiplier for retry attempts
  static const double retryBackoffMultiplier = 2.0;

  /// Timeout for personality learning operations (seconds)
  static const int personalityLearningTimeoutSeconds = 30;

  // ======= DEBUGGING & MONITORING =======
  /// Enable detailed logging for vibe analysis
  static const bool enableVibeAnalysisLogging = true;

  /// Enable AI2AI connection monitoring
  static const bool enableConnectionMonitoring = true;

  /// Enable personality evolution tracking
  static const bool enablePersonalityEvolutionTracking = true;

  /// Sample rate for network analytics (0.0 to 1.0)
  static const double networkAnalyticsSampleRate = 0.1;

  // ======= SECURITY PARAMETERS =======
  /// Salt length for personality hash generation
  static const int personalityHashSaltLength = 32;

  /// Number of hash iterations for vibe signature generation
  static const int vibeHashIterations = 10000;

  /// Minimum entropy bits required for secure personality fingerprint
  static const int minEntropyBits = 128;

  /// Maximum age of cryptographic keys (days)
  static const int maxCryptoKeyAgeDays = 90;
}
