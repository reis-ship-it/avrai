/// Attribution for a recommendation explaining why it was suggested
///
/// Provides transparency into the recommendation algorithm by showing:
/// - Primary reason for the recommendation
/// - Component scores breakdown
/// - Contributing factors
/// - Cross-app learning influence (if applicable)
class RecommendationAttribution {
  /// Primary reason for the recommendation (displayed prominently)
  final String primaryReason;

  /// Breakdown of component scores that contributed to the recommendation
  final Map<String, double> componentScores;

  /// List of factors that influenced the recommendation
  final List<AttributionFactor> factors;

  /// Cross-app learning influence, if any
  final CrossAppInfluence? crossAppInfluence;

  /// Overall relevance score (0.0-1.0)
  final double relevanceScore;

  const RecommendationAttribution({
    required this.primaryReason,
    required this.componentScores,
    required this.factors,
    this.crossAppInfluence,
    required this.relevanceScore,
  });

  /// Whether this recommendation was influenced by cross-app learning
  bool get hasCrossAppInfluence => crossAppInfluence != null;

  /// Get a short attribution summary (1-2 lines)
  String get shortSummary {
    if (crossAppInfluence != null) {
      return crossAppInfluence!.summary;
    }
    return primaryReason;
  }

  /// Get the top contributing factors
  List<AttributionFactor> getTopFactors(int count) {
    final sorted = List<AttributionFactor>.from(factors)
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return sorted.take(count).toList();
  }

  /// Create from component scores (helper for services)
  factory RecommendationAttribution.fromScores({
    required double vibeCompatibility,
    double? locationCompatibility,
    double? timingCompatibility,
    double? knotBonus,
    CrossAppInfluence? crossAppInfluence,
  }) {
    final factors = <AttributionFactor>[];
    final scores = <String, double>{};

    // Vibe compatibility
    if (vibeCompatibility > 0) {
      scores['vibe'] = vibeCompatibility;
      factors.add(AttributionFactor(
        name: 'vibe_match',
        description: _getVibeDescription(vibeCompatibility),
        weight: vibeCompatibility,
        icon: 0,
      ));
    }

    // Location compatibility
    if (locationCompatibility != null && locationCompatibility > 0) {
      scores['location'] = locationCompatibility;
      factors.add(AttributionFactor(
        name: 'location',
        description: 'Near your current location',
        weight: locationCompatibility,
        icon: 0,
      ));
    }

    // Timing compatibility
    if (timingCompatibility != null && timingCompatibility > 0) {
      scores['timing'] = timingCompatibility;
      factors.add(AttributionFactor(
        name: 'timing',
        description: 'Good time to visit',
        weight: timingCompatibility,
        icon: 0,
      ));
    }

    // Knot bonus
    if (knotBonus != null && knotBonus > 0) {
      scores['knot'] = knotBonus;
      factors.add(AttributionFactor(
        name: 'community',
        description: 'Popular in your community',
        weight: knotBonus,
        icon: 0,
      ));
    }

    // Determine primary reason
    final primaryReason = _determinePrimaryReason(
      vibeCompatibility,
      locationCompatibility,
      timingCompatibility,
      knotBonus,
      crossAppInfluence,
    );

    // Calculate overall relevance
    final totalWeight = scores.values.fold(0.0, (sum, v) => sum + v);
    final relevanceScore =
        scores.isNotEmpty ? totalWeight / scores.length : 0.0;

    return RecommendationAttribution(
      primaryReason: primaryReason,
      componentScores: scores,
      factors: factors,
      crossAppInfluence: crossAppInfluence,
      relevanceScore: relevanceScore.clamp(0.0, 1.0),
    );
  }

  static String _getVibeDescription(double compatibility) {
    if (compatibility > 0.9) {
      return 'Perfect vibe match';
    } else if (compatibility > 0.75) {
      return 'Great vibe match';
    } else if (compatibility > 0.6) {
      return 'Good vibe match';
    } else {
      return 'Matches your vibe';
    }
  }

  static String _determinePrimaryReason(
    double vibeCompatibility,
    double? locationCompatibility,
    double? timingCompatibility,
    double? knotBonus,
    CrossAppInfluence? crossAppInfluence,
  ) {
    // If cross-app learning contributed, prioritize that
    if (crossAppInfluence != null) {
      return crossAppInfluence.summary;
    }

    // Otherwise, use the highest scoring factor
    final scores = {
      'vibe': vibeCompatibility,
      'location': locationCompatibility ?? 0,
      'timing': timingCompatibility ?? 0,
      'community': knotBonus ?? 0,
    };

    final topFactor =
        scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    switch (topFactor) {
      case 'vibe':
        return _getVibeDescription(vibeCompatibility);
      case 'location':
        return 'Near your location';
      case 'timing':
        return 'Good time to visit';
      case 'community':
        return 'Popular in your community';
      default:
        return 'Recommended for you';
    }
  }
}

/// A single factor that contributed to a recommendation
class AttributionFactor {
  /// Internal name of the factor
  final String name;

  /// Human-readable description
  final String description;

  /// Weight/contribution of this factor (0.0-1.0)
  final double weight;

  /// Icon to display for this factor
  final int icon;

  const AttributionFactor({
    required this.name,
    required this.description,
    required this.weight,
    required this.icon,
  });

  /// Percentage contribution (0-100)
  int get percentageContribution => (weight * 100).round();
}

/// Information about how cross-app learning influenced a recommendation
class CrossAppInfluence {
  /// Data sources that contributed to this recommendation
  final List<CrossAppDataSource> contributingSources;

  /// Human-readable summary of the influence
  final String summary;

  /// Detailed explanation (optional)
  final String? detailedExplanation;

  /// Confidence level of the cross-app influence (0.0-1.0)
  final double confidence;

  const CrossAppInfluence({
    required this.contributingSources,
    required this.summary,
    this.detailedExplanation,
    this.confidence = 0.7,
  });

  /// Get icons for the contributing sources
  List<String> get sourceIcons {
    return contributingSources.map((s) => s.icon).toList();
  }

  /// Create from a single source
  factory CrossAppInfluence.fromSource(
    CrossAppDataSource source,
    String reason,
  ) {
    return CrossAppInfluence(
      contributingSources: [source],
      summary: reason,
    );
  }

  /// Create from multiple sources
  factory CrossAppInfluence.fromSources(
    List<CrossAppDataSource> sources,
    String reason, {
    String? details,
  }) {
    return CrossAppInfluence(
      contributingSources: sources,
      summary: reason,
      detailedExplanation: details,
    );
  }

  /// Calendar-based influence
  factory CrossAppInfluence.fromCalendar(String reason) {
    return CrossAppInfluence(
      contributingSources: [CrossAppDataSource.calendar],
      summary: reason,
    );
  }

  /// Health-based influence
  factory CrossAppInfluence.fromHealth(String reason) {
    return CrossAppInfluence(
      contributingSources: [CrossAppDataSource.health],
      summary: reason,
    );
  }

  /// Music/media-based influence
  factory CrossAppInfluence.fromMedia(String reason) {
    return CrossAppInfluence(
      contributingSources: [CrossAppDataSource.media],
      summary: reason,
    );
  }

  /// App usage-based influence
  factory CrossAppInfluence.fromAppUsage(String reason) {
    return CrossAppInfluence(
      contributingSources: [CrossAppDataSource.appUsage],
      summary: reason,
    );
  }
}

/// Types of cross-app data sources used for learning
enum CrossAppDataSource {
  calendar,
  health,
  media,
  appUsage,
  location,
  contacts,
  browserHistory,
  external,
}

/// Extensions for cross-app data source
extension CrossAppDataSourceExtension on CrossAppDataSource {
  String get icon {
    switch (this) {
      case CrossAppDataSource.calendar:
        return 'calendar';
      case CrossAppDataSource.health:
        return 'health';
      case CrossAppDataSource.media:
        return 'media';
      case CrossAppDataSource.appUsage:
        return 'appUsage';
      case CrossAppDataSource.location:
        return 'location';
      case CrossAppDataSource.contacts:
        return 'contacts';
      case CrossAppDataSource.browserHistory:
        return 'browserHistory';
      case CrossAppDataSource.external:
        return 'external';
    }
  }
}
