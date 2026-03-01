import 'package:avrai_core/constants/vibe_constants.dart';
import 'package:avrai_core/models/user/user_vibe.dart';

/// Spot Vibe Profile
///
/// CORE PHILOSOPHY: Vibe-based matching
/// - Business accounts can define their spot's unique vibe
/// - Users are "called" to spots based on vibe compatibility
/// - Spot vibe + User vibe = Better matches, happier everyone
///
/// The overall vibe of the spot (defined by business accounts) should match
/// the overall vibe of the user (known through AI2AI system).
///
/// Example: Bemelmans might have a sophisticated, art-focused, cultural vibe.
/// Users with matching vibes (sophisticated, art-loving, cultural) are "called" to it.
class SpotVibe {
  final String spotId;
  final Map<String, double>
      vibeDimensions; // Same 12 dimensions as user personality
  final String vibeDescription; // Human-readable description of the vibe
  final double overallEnergy; // 0.0 (chill) to 1.0 (high-energy)
  final double socialPreference; // 0.0 (solo) to 1.0 (social)
  final double explorationTendency; // 0.0 (familiar) to 1.0 (adventurous)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? definedBy; // Business account ID that defined this vibe

  SpotVibe({
    required this.spotId,
    required this.vibeDimensions,
    required this.vibeDescription,
    required this.overallEnergy,
    required this.socialPreference,
    required this.explorationTendency,
    required this.createdAt,
    required this.updatedAt,
    this.definedBy,
  });

  /// Create spot vibe from business account definition
  /// Business accounts can define their spot's unique vibe
  factory SpotVibe.fromBusinessDefinition({
    required String spotId,
    required Map<String, double> dimensions,
    required String description,
    required String businessAccountId,
  }) {
    final overallEnergy = _calculateOverallEnergy(dimensions);
    final socialPreference = _calculateSocialPreference(dimensions);
    final explorationTendency = _calculateExplorationTendency(dimensions);

    return SpotVibe(
      spotId: spotId,
      vibeDimensions: dimensions,
      vibeDescription: description,
      overallEnergy: overallEnergy,
      socialPreference: socialPreference,
      explorationTendency: explorationTendency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      definedBy: businessAccountId,
    );
  }

  /// Create spot vibe from inferred dimensions (fallback if no business definition)
  /// Can be inferred from spot characteristics, tags, description, etc.
  factory SpotVibe.fromSpotCharacteristics({
    required String spotId,
    required String category,
    required List<String> tags,
    required String description,
    required double rating,
  }) {
    final dimensions = _inferDimensionsFromCharacteristics(
      category,
      tags,
      description,
      rating,
    );

    final overallEnergy = _calculateOverallEnergy(dimensions);
    final socialPreference = _calculateSocialPreference(dimensions);
    final explorationTendency = _calculateExplorationTendency(dimensions);

    return SpotVibe(
      spotId: spotId,
      vibeDimensions: dimensions,
      vibeDescription: _generateVibeDescription(dimensions, category, tags),
      overallEnergy: overallEnergy,
      socialPreference: socialPreference,
      explorationTendency: explorationTendency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      definedBy: null, // Inferred, not defined by business
    );
  }

  /// Calculate vibe compatibility with a user vibe (0.0 to 1.0)
  /// Higher = better match, user should be "called" to this spot
  double calculateVibeCompatibility(UserVibe userVibe) {
    double totalSimilarity = 0.0;
    int validDimensions = 0;

    // Compare dimensions
    for (final dimension in VibeConstants.coreDimensions) {
      final spotValue = vibeDimensions[dimension];
      final userValue = userVibe.anonymizedDimensions[dimension];

      if (spotValue != null && userValue != null) {
        final similarity = 1.0 - (spotValue - userValue).abs();
        totalSimilarity += similarity;
        validDimensions++;
      }
    }

    if (validDimensions == 0) return 0.0;

    final dimensionCompatibility = totalSimilarity / validDimensions;

    // Factor in overall energy and exploration compatibility
    final energyCompatibility =
        1.0 - (overallEnergy - userVibe.overallEnergy).abs();
    final explorationCompatibility =
        1.0 - (explorationTendency - userVibe.explorationTendency).abs();
    final socialCompatibility =
        1.0 - (socialPreference - userVibe.socialPreference).abs();

    // Weighted average
    final overallCompatibility = (dimensionCompatibility * 0.5 +
            energyCompatibility * 0.2 +
            explorationCompatibility * 0.15 +
            socialCompatibility * 0.15)
        .clamp(0.0, 1.0);

    return overallCompatibility;
  }

  /// Check if this vibe should "call" a user to the spot
  /// Returns true if compatibility is high enough for recommendation
  bool shouldCallUser(UserVibe userVibe, {double threshold = 0.7}) {
    final compatibility = calculateVibeCompatibility(userVibe);
    return compatibility >= threshold;
  }

  // Helper methods

  static double _calculateOverallEnergy(Map<String, double> dimensions) {
    final energy = dimensions['energy_preference'] ?? 0.5;
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    return ((energy + exploration) / 2.0).clamp(0.0, 1.0);
  }

  static double _calculateSocialPreference(Map<String, double> dimensions) {
    final community = dimensions['community_orientation'] ?? 0.5;
    final social = dimensions['social_discovery_style'] ?? 0.5;
    return ((community + social) / 2.0).clamp(0.0, 1.0);
  }

  static double _calculateExplorationTendency(Map<String, double> dimensions) {
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final novelty = dimensions['novelty_seeking'] ?? 0.5;
    return ((exploration + novelty) / 2.0).clamp(0.0, 1.0);
  }

  static Map<String, double> _inferDimensionsFromCharacteristics(
    String category,
    List<String> tags,
    String description,
    double rating,
  ) {
    final dimensions = <String, double>{};
    final combinedText =
        '$category ${tags.join(' ')} $description'.toLowerCase();

    // Infer dimensions from characteristics
    // This is a fallback - business accounts should define their vibe explicitly

    // Exploration eagerness
    if (combinedText.contains('new') ||
        combinedText.contains('unique') ||
        combinedText.contains('hidden') ||
        combinedText.contains('gem')) {
      dimensions['exploration_eagerness'] = 0.8;
    } else {
      dimensions['exploration_eagerness'] = 0.5;
    }

    // Community orientation
    if (combinedText.contains('community') ||
        combinedText.contains('group') ||
        combinedText.contains('social') ||
        combinedText.contains('meetup')) {
      dimensions['community_orientation'] = 0.8;
    } else {
      dimensions['community_orientation'] = 0.5;
    }

    // Authenticity preference
    if (combinedText.contains('authentic') ||
        combinedText.contains('local') ||
        combinedText.contains('artisan') ||
        combinedText.contains('craft')) {
      dimensions['authenticity_preference'] = 0.8;
    } else if (combinedText.contains('popular') ||
        combinedText.contains('trendy')) {
      dimensions['authenticity_preference'] = 0.3;
    } else {
      dimensions['authenticity_preference'] = 0.5;
    }

    // Energy preference
    if (combinedText.contains('energetic') ||
        combinedText.contains('lively') ||
        combinedText.contains('vibrant') ||
        combinedText.contains('bustling')) {
      dimensions['energy_preference'] = 0.8;
    } else if (combinedText.contains('chill') ||
        combinedText.contains('relaxed') ||
        combinedText.contains('quiet') ||
        combinedText.contains('calm')) {
      dimensions['energy_preference'] = 0.2;
    } else {
      dimensions['energy_preference'] = 0.5;
    }

    // Cultural value (for art, museums, etc.)
    if (combinedText.contains('art') ||
        combinedText.contains('culture') ||
        combinedText.contains('museum') ||
        combinedText.contains('gallery') ||
        combinedText.contains('sophisticated') ||
        combinedText.contains('refined')) {
      dimensions['authenticity_preference'] = 0.9; // High cultural value
    }

    // Set defaults for other dimensions
    for (final dimension in VibeConstants.coreDimensions) {
      if (!dimensions.containsKey(dimension)) {
        dimensions[dimension] = 0.5; // Neutral default
      }
    }

    return dimensions;
  }

  static String _generateVibeDescription(
    Map<String, double> dimensions,
    String category,
    List<String> tags,
  ) {
    final parts = <String>[];

    if (dimensions['energy_preference'] != null &&
        dimensions['energy_preference']! > 0.7) {
      parts.add('high-energy');
    } else if (dimensions['energy_preference'] != null &&
        dimensions['energy_preference']! < 0.3) {
      parts.add('chill');
    }

    if (dimensions['community_orientation'] != null &&
        dimensions['community_orientation']! > 0.7) {
      parts.add('community-focused');
    }

    if (dimensions['authenticity_preference'] != null &&
        dimensions['authenticity_preference']! > 0.7) {
      parts.add('authentic');
    }

    if (tags.contains('art') ||
        tags.contains('cultural') ||
        tags.contains('sophisticated')) {
      parts.add('culturally rich');
    }

    if (parts.isEmpty) {
      return 'Welcoming $category';
    }

    return parts.join(', ');
  }
}
