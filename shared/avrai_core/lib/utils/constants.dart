/// Core constants for SPOTS application
class CoreConstants {
  // Validation limits
  static const int maxSpotNameLength = 100;
  static const int maxSpotDescriptionLength = 500;
  static const int maxListTitleLength = 100;
  static const int maxListDescriptionLength = 1000;
  static const int maxUserNameLength = 50;
  static const int maxUserBioLength = 200;
  static const int minPasswordLength = 8;

  // Geographic limits
  static const double maxLatitude = 90.0;
  static const double minLatitude = -90.0;
  static const double maxLongitude = 180.0;
  static const double minLongitude = -180.0;
  static const double defaultSearchRadiusKm = 50.0;
  static const double maxSearchRadiusKm = 200.0;

  // Rating limits
  static const double minRating = 0.0;
  static const double maxRating = 5.0;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache durations
  static const Duration defaultCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 5);

  // Vibe settings
  static const Duration vibeExpirationDuration = Duration(hours: 24);
  static const double defaultPrivacyLevel = 0.8;

  // List limits
  static const int maxSpotsPerList = 200;
  static const int maxCollaboratorsPerList = 20;
  static const int maxTagsPerSpot = 10;
  static const int maxTagsPerList = 5;

  // Media limits
  static const int maxImageFileSizeMB = 10;
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Rate limiting
  static const int maxSpotsPerUserPerDay = 50;
  static const int maxListsPerUserPerDay = 10;
  static const int maxRespectsPerUserPerDay = 100;

  // Error messages
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Please enter a valid email address';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordTooShortError =
      'Password must be at least 8 characters';
  static const String nameRequiredError = 'Name is required';
  static const String spotNameRequiredError = 'Spot name is required';
  static const String spotDescriptionRequiredError =
      'Spot description is required';
  static const String listTitleRequiredError = 'List title is required';
  static const String locationRequiredError = 'Location is required';
  static const String invalidCoordinatesError = 'Invalid coordinates';

  // Success messages
  static const String spotCreatedSuccess = 'Spot created successfully';
  static const String spotUpdatedSuccess = 'Spot updated successfully';
  static const String spotDeletedSuccess = 'Spot deleted successfully';
  static const String listCreatedSuccess = 'List created successfully';
  static const String listUpdatedSuccess = 'List updated successfully';
  static const String listDeletedSuccess = 'List deleted successfully';
  static const String profileUpdatedSuccess = 'Profile updated successfully';

  // Feature flags
  static const bool enableVibeMatching = true;
  static const bool enableOfflineMode = true;
  static const bool enableAI2AIFeatures = true;
  static const bool enableLocationSharing = true;
  static const bool enablePushNotifications = true;

  // AI2AI constants
  static const double minCompatibilityThreshold = 0.3;
  static const double goodCompatibilityThreshold = 0.6;
  static const double excellentCompatibilityThreshold = 0.8;

  // Privacy levels
  static const double maxPrivacyLevel = 1.0;
  static const double minPrivacyLevel = 0.0;
  static const double moderatePrivacyLevel = 0.5;
  static const double highPrivacyLevel = 0.8;
}

/// API endpoints (placeholder - will be moved to network module)
class ApiConstants {
  static const String baseUrl = 'https://api.avrai.app';
  static const String apiVersion = 'v1';

  // Auth endpoints
  static const String signIn = '/auth/signin';
  static const String signUp = '/auth/signup';
  static const String signOut = '/auth/signout';
  static const String refreshToken = '/auth/refresh';

  // Spots endpoints
  static const String spots = '/spots';
  static const String spotsNearby = '/spots/nearby';
  static const String spotsSearch = '/spots/search';
  static const String spotsPopular = '/spots/popular';
  static const String spotsTrending = '/spots/trending';

  // Lists endpoints
  static const String lists = '/lists';
  static const String listsPublic = '/lists/public';
  static const String listsSearch = '/lists/search';
  static const String listsPopular = '/lists/popular';
  static const String listsTrending = '/lists/trending';

  // Users endpoints
  static const String users = '/users';
  static const String usersProfile = '/users/profile';
  static const String usersNearby = '/users/nearby';

  // AI2AI endpoints
  static const String vibeMatching = '/ai2ai/vibe-matching';
  static const String vibeUpdate = '/ai2ai/vibe-update';
  static const String recommendations = '/ai2ai/recommendations';
}

/// Database constants
class DatabaseConstants {
  // Table names
  static const String usersTable = 'users';
  static const String spotsTable = 'spots';
  static const String listsTable = 'lists';
  static const String userVibesTable = 'user_vibes';
  static const String userActionsTable = 'user_actions';

  // Database version
  static const int databaseVersion = 1;
  static const String databaseName = 'spots.db';
}

/// Asset paths
class AssetConstants {
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String logoPath = '${imagesPath}logo.png';
  static const String placeholderImage = '${imagesPath}placeholder.png';
  static const String defaultAvatar = '${imagesPath}default_avatar.png';
}
