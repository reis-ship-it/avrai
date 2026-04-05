/// Categories for spots in SPOTS
enum SpotCategory {
  foodAndDrink,
  entertainment,
  culture,
  outdoor,
  shopping,
  health,
  education,
  services,
  other,
}

extension SpotCategoryExtension on SpotCategory {
  String get displayName {
    switch (this) {
      case SpotCategory.foodAndDrink:
        return 'Food & Drink';
      case SpotCategory.entertainment:
        return 'Entertainment';
      case SpotCategory.culture:
        return 'Culture';
      case SpotCategory.outdoor:
        return 'Outdoor';
      case SpotCategory.shopping:
        return 'Shopping';
      case SpotCategory.health:
        return 'Health';
      case SpotCategory.education:
        return 'Education';
      case SpotCategory.services:
        return 'Services';
      case SpotCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case SpotCategory.foodAndDrink:
        return '🍽️';
      case SpotCategory.entertainment:
        return '🎭';
      case SpotCategory.culture:
        return '🎨';
      case SpotCategory.outdoor:
        return '🌲';
      case SpotCategory.shopping:
        return '🛍️';
      case SpotCategory.health:
        return '🏥';
      case SpotCategory.education:
        return '📚';
      case SpotCategory.services:
        return '🔧';
      case SpotCategory.other:
        return '📍';
    }
  }
}

/// Price levels for spots
enum PriceLevel {
  free,
  low,
  moderate,
  high,
  luxury,
}

extension PriceLevelExtension on PriceLevel {
  String get displayName {
    switch (this) {
      case PriceLevel.free:
        return 'Free';
      case PriceLevel.low:
        return 'Low';
      case PriceLevel.moderate:
        return 'Moderate';
      case PriceLevel.high:
        return 'High';
      case PriceLevel.luxury:
        return 'Luxury';
    }
  }

  String get symbol {
    switch (this) {
      case PriceLevel.free:
        return 'FREE';
      case PriceLevel.low:
        return '\$';
      case PriceLevel.moderate:
        return '\$\$';
      case PriceLevel.high:
        return '\$\$\$';
      case PriceLevel.luxury:
        return '\$\$\$\$';
    }
  }

  int get level {
    switch (this) {
      case PriceLevel.free:
        return 0;
      case PriceLevel.low:
        return 1;
      case PriceLevel.moderate:
        return 2;
      case PriceLevel.high:
        return 3;
      case PriceLevel.luxury:
        return 4;
    }
  }
}

/// Verification level for spots
enum VerificationLevel {
  none,
  basic,
  verified,
  expert,
}

extension VerificationLevelExtension on VerificationLevel {
  String get displayName {
    switch (this) {
      case VerificationLevel.none:
        return 'Unverified';
      case VerificationLevel.basic:
        return 'Basic';
      case VerificationLevel.verified:
        return 'Verified';
      case VerificationLevel.expert:
        return 'Expert';
    }
  }

  String get badge {
    switch (this) {
      case VerificationLevel.none:
        return '';
      case VerificationLevel.basic:
        return '✓';
      case VerificationLevel.verified:
        return '✅';
      case VerificationLevel.expert:
        return '🏆';
    }
  }

  int get trustScore {
    switch (this) {
      case VerificationLevel.none:
        return 0;
      case VerificationLevel.basic:
        return 25;
      case VerificationLevel.verified:
        return 75;
      case VerificationLevel.expert:
        return 100;
    }
  }
}

/// Moderation status for spots
enum ModerationStatus {
  pending,
  approved,
  rejected,
  flagged,
}

extension ModerationStatusExtension on ModerationStatus {
  String get displayName {
    switch (this) {
      case ModerationStatus.pending:
        return 'Pending Review';
      case ModerationStatus.approved:
        return 'Approved';
      case ModerationStatus.rejected:
        return 'Rejected';
      case ModerationStatus.flagged:
        return 'Flagged';
    }
  }

  bool get isVisible {
    switch (this) {
      case ModerationStatus.approved:
        return true;
      case ModerationStatus.pending:
      case ModerationStatus.rejected:
      case ModerationStatus.flagged:
        return false;
    }
  }
}
