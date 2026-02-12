/// Expertise levels as defined in OUR_GUTS.md
/// Represents geographic scope of expertise recognition
enum ExpertiseLevel {
  local,      // Neighborhood level
  city,       // City level
  regional,   // Regional level
  national,   // National level
  global,     // Global level
  universal;  // Universal recognition

  /// Get display name for the level
  String get displayName {
    switch (this) {
      case ExpertiseLevel.local:
        return 'Local';
      case ExpertiseLevel.city:
        return 'City';
      case ExpertiseLevel.regional:
        return 'Regional';
      case ExpertiseLevel.national:
        return 'National';
      case ExpertiseLevel.global:
        return 'Global';
      case ExpertiseLevel.universal:
        return 'Universal';
    }
  }

  /// Get description of what this level means
  String get description {
    switch (this) {
      case ExpertiseLevel.local:
        return 'Neighborhood-level expertise';
      case ExpertiseLevel.city:
        return 'City-level expertise';
      case ExpertiseLevel.regional:
        return 'Regional-level expertise';
      case ExpertiseLevel.national:
        return 'National-level expertise';
      case ExpertiseLevel.global:
        return 'Global-level expertise';
      case ExpertiseLevel.universal:
        return 'Universal recognition';
    }
  }

  /// Get emoji representation for UI
  String get emoji {
    switch (this) {
      case ExpertiseLevel.local:
        return '🏘️';
      case ExpertiseLevel.city:
        return '🏙️';
      case ExpertiseLevel.regional:
        return '🗺️';
      case ExpertiseLevel.national:
        return '🌎';
      case ExpertiseLevel.global:
        return '🌍';
      case ExpertiseLevel.universal:
        return '✨';
    }
  }

  /// Parse from string (for JSON/API)
  static ExpertiseLevel? fromString(String? value) {
    if (value == null) return null;
    try {
      return ExpertiseLevel.values.firstWhere(
        (level) => level.name == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get next level (for progress tracking)
  ExpertiseLevel? get nextLevel {
    switch (this) {
      case ExpertiseLevel.local:
        return ExpertiseLevel.city;
      case ExpertiseLevel.city:
        return ExpertiseLevel.regional;
      case ExpertiseLevel.regional:
        return ExpertiseLevel.national;
      case ExpertiseLevel.national:
        return ExpertiseLevel.global;
      case ExpertiseLevel.global:
        return ExpertiseLevel.universal;
      case ExpertiseLevel.universal:
        return null; // Highest level
    }
  }

  /// Check if this level is higher than another
  bool isHigherThan(ExpertiseLevel other) {
    return index > other.index;
  }

  /// Check if this level is lower than another
  bool isLowerThan(ExpertiseLevel other) {
    return index < other.index;
  }
}

