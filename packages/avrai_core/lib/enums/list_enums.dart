/// Types of lists in SPOTS
enum ListType {
  public,
  private,
  curated,
  collaborative,
}

extension ListTypeExtension on ListType {
  String get displayName {
    switch (this) {
      case ListType.public:
        return 'Public';
      case ListType.private:
        return 'Private';
      case ListType.curated:
        return 'Curated';
      case ListType.collaborative:
        return 'Collaborative';
    }
  }

  String get description {
    switch (this) {
      case ListType.public:
        return 'Visible to everyone';
      case ListType.private:
        return 'Only visible to you';
      case ListType.curated:
        return 'Professionally curated';
      case ListType.collaborative:
        return 'Editable by multiple users';
    }
  }

  String get icon {
    switch (this) {
      case ListType.public:
        return '🌍';
      case ListType.private:
        return '🔒';
      case ListType.curated:
        return '⭐';
      case ListType.collaborative:
        return '👥';
    }
  }
}

/// Categories for lists
enum ListCategory {
  general,
  food,
  entertainment,
  shopping,
  outdoor,
  travel,
  culture,
  health,
}

extension ListCategoryExtension on ListCategory {
  String get displayName {
    switch (this) {
      case ListCategory.general:
        return 'General';
      case ListCategory.food:
        return 'Food & Dining';
      case ListCategory.entertainment:
        return 'Entertainment';
      case ListCategory.shopping:
        return 'Shopping';
      case ListCategory.outdoor:
        return 'Outdoor Activities';
      case ListCategory.travel:
        return 'Travel';
      case ListCategory.culture:
        return 'Culture & Arts';
      case ListCategory.health:
        return 'Health & Wellness';
    }
  }

  String get emoji {
    switch (this) {
      case ListCategory.general:
        return '📋';
      case ListCategory.food:
        return '🍽️';
      case ListCategory.entertainment:
        return '🎭';
      case ListCategory.shopping:
        return '🛍️';
      case ListCategory.outdoor:
        return '🌲';
      case ListCategory.travel:
        return '✈️';
      case ListCategory.culture:
        return '🎨';
      case ListCategory.health:
        return '💪';
    }
  }
}

/// Roles within a list
enum ListRole {
  curator,      // Owner of the list
  collaborator, // Can edit the list
  member,       // Can view and contribute
  viewer,       // Can only view
}

extension ListRoleExtension on ListRole {
  String get displayName {
    switch (this) {
      case ListRole.curator:
        return 'Curator';
      case ListRole.collaborator:
        return 'Collaborator';
      case ListRole.member:
        return 'Member';
      case ListRole.viewer:
        return 'Viewer';
    }
  }

  String get description {
    switch (this) {
      case ListRole.curator:
        return 'Owner and manager of the list';
      case ListRole.collaborator:
        return 'Can edit spots in the list';
      case ListRole.member:
        return 'Can view and contribute to the list';
      case ListRole.viewer:
        return 'Can only view the list';
    }
  }

  int get permissionLevel {
    switch (this) {
      case ListRole.curator:
        return 4;
      case ListRole.collaborator:
        return 3;
      case ListRole.member:
        return 2;
      case ListRole.viewer:
        return 1;
    }
  }

  bool get canEdit {
    switch (this) {
      case ListRole.curator:
      case ListRole.collaborator:
        return true;
      case ListRole.member:
      case ListRole.viewer:
        return false;
    }
  }

  bool get canManageMembers {
    switch (this) {
      case ListRole.curator:
        return true;
      case ListRole.collaborator:
      case ListRole.member:
      case ListRole.viewer:
        return false;
    }
  }

  bool get canDelete {
    switch (this) {
      case ListRole.curator:
        return true;
      case ListRole.collaborator:
      case ListRole.member:
      case ListRole.viewer:
        return false;
    }
  }
}

/// Moderation levels for lists
enum ModerationLevel {
  relaxed,  // Minimal moderation
  standard, // Normal moderation
  strict,   // High moderation
  maximum,  // Maximum moderation
}

extension ModerationLevelExtension on ModerationLevel {
  String get displayName {
    switch (this) {
      case ModerationLevel.relaxed:
        return 'Relaxed';
      case ModerationLevel.standard:
        return 'Standard';
      case ModerationLevel.strict:
        return 'Strict';
      case ModerationLevel.maximum:
        return 'Maximum';
    }
  }

  String get description {
    switch (this) {
      case ModerationLevel.relaxed:
        return 'Minimal content filtering';
      case ModerationLevel.standard:
        return 'Normal content filtering';
      case ModerationLevel.strict:
        return 'High content filtering';
      case ModerationLevel.maximum:
        return 'Maximum content filtering';
    }
  }

  int get filterStrength {
    switch (this) {
      case ModerationLevel.relaxed:
        return 1;
      case ModerationLevel.standard:
        return 2;
      case ModerationLevel.strict:
        return 3;
      case ModerationLevel.maximum:
        return 4;
    }
  }
}
