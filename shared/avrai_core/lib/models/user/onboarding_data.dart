/// OnboardingData Model
///
/// Represents all data collected during user onboarding.
/// Uses agentId (not userId) for privacy protection per Master Plan Phase 7.3.
///
/// This data is used to initialize the user's AI agent personality profile.
class OnboardingData {
  /// Privacy-protected identifier (not userId)
  /// Format: agent_[32+ character base64url string]
  final String agentId;

  /// User's age (calculated from birthday if provided)
  final int? age;

  /// User's birthday
  final DateTime? birthday;

  /// User's primary location/homebase
  final String? homebase;

  /// List of favorite places the user mentioned
  final List<String> favoritePlaces;

  /// User preferences organized by category
  /// Example: {"Food & Drink": ["Coffee", "Craft Beer"], "Activities": ["Hiking"]}
  final Map<String, List<String>> preferences;

  /// Baseline lists the user wants to start with
  final List<String> baselineLists;

  /// Open-ended text responses for the conversational AI onboarding (Air Gapped SLM digestion)
  /// Example: {"coffee": "I love small dark roasts", "about_me": "I'm a grungy techie"}
  final Map<String, String> openResponses;

  /// Respected friends/connections the user mentioned
  final List<String> respectedFriends;

  /// Social media platforms connected during onboarding
  /// Example: {"google": true, "instagram": false}
  final Map<String, bool> socialMediaConnected;

  /// When onboarding was completed
  final DateTime completedAt;

  /// Personality dimension values derived from onboarding responses
  final Map<String, double>? dimensionValues;

  /// Confidence scores for each personality dimension
  final Map<String, double>? dimensionConfidence;

  /// Whether the user accepted the Terms of Service
  final bool tosAccepted;

  /// Whether the user accepted the Privacy Policy
  final bool privacyAccepted;

  /// Whether dimension values have been computed from onboarding
  bool get hasDimensionValues =>
      dimensionValues != null && dimensionValues!.isNotEmpty;

  OnboardingData({
    required this.agentId,
    this.age,
    this.birthday,
    this.homebase,
    this.favoritePlaces = const [],
    this.preferences = const {},
    this.baselineLists = const [],
    this.openResponses = const {},
    this.respectedFriends = const [],
    this.socialMediaConnected = const {},
    required this.completedAt,
    this.dimensionValues,
    this.dimensionConfidence,
    this.tosAccepted = false,
    this.privacyAccepted = false,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'age': age,
      'birthday': birthday?.toIso8601String(),
      'homebase': homebase,
      'favoritePlaces': favoritePlaces,
      'preferences': preferences,
      'baselineLists': baselineLists,
      'openResponses': openResponses,
      'respectedFriends': respectedFriends,
      'socialMediaConnected': socialMediaConnected,
      'completedAt': completedAt.toIso8601String(),
      'dimensionValues': dimensionValues,
      'dimensionConfidence': dimensionConfidence,
      'tosAccepted': tosAccepted,
      'privacyAccepted': privacyAccepted,
    };
  }

  /// Create from JSON
  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      agentId: json['agentId'] as String,
      age: json['age'] as int?,
      birthday: json['birthday'] != null
          ? DateTime.parse(json['birthday'] as String)
          : null,
      homebase: json['homebase'] as String?,
      favoritePlaces: List<String>.from(json['favoritePlaces'] ?? []),
      preferences: (json['preferences'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              List<String>.from(value as List? ?? []),
            ),
          ) ??
          {},
      baselineLists: List<String>.from(json['baselineLists'] ?? []),
      openResponses: (json['openResponses'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          ) ??
          {},
      respectedFriends: List<String>.from(json['respectedFriends'] ?? []),
      socialMediaConnected: (json['socialMediaConnected'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value as bool? ?? false,
            ),
          ) ??
          {},
      completedAt: DateTime.parse(json['completedAt'] as String),
      dimensionValues: (json['dimensionValues'] as Map?)?.map(
        (key, value) => MapEntry(
          key.toString(),
          (value as num).toDouble(),
        ),
      ),
      dimensionConfidence: (json['dimensionConfidence'] as Map?)?.map(
        (key, value) => MapEntry(
          key.toString(),
          (value as num).toDouble(),
        ),
      ),
      tosAccepted: json['tosAccepted'] as bool? ?? false,
      privacyAccepted: json['privacyAccepted'] as bool? ?? false,
    );
  }

  /// Create a copy with updated fields
  OnboardingData copyWith({
    String? agentId,
    int? age,
    DateTime? birthday,
    Object? homebase = const _Sentinel(),
    List<String>? favoritePlaces,
    Map<String, List<String>>? preferences,
    List<String>? baselineLists,
    Map<String, String>? openResponses,
    List<String>? respectedFriends,
    Map<String, bool>? socialMediaConnected,
    DateTime? completedAt,
    Map<String, double>? dimensionValues,
    Map<String, double>? dimensionConfidence,
    bool? tosAccepted,
    bool? privacyAccepted,
  }) {
    return OnboardingData(
      agentId: agentId ?? this.agentId,
      age: age ?? this.age,
      birthday: birthday ?? this.birthday,
      homebase: homebase is _Sentinel ? this.homebase : homebase as String?,
      favoritePlaces: favoritePlaces ?? this.favoritePlaces,
      preferences: preferences ?? this.preferences,
      baselineLists: baselineLists ?? this.baselineLists,
      openResponses: openResponses ?? this.openResponses,
      respectedFriends: respectedFriends ?? this.respectedFriends,
      socialMediaConnected: socialMediaConnected ?? this.socialMediaConnected,
      completedAt: completedAt ?? this.completedAt,
      dimensionValues: dimensionValues ?? this.dimensionValues,
      dimensionConfidence: dimensionConfidence ?? this.dimensionConfidence,
      tosAccepted: tosAccepted ?? this.tosAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    );
  }

  /// Validate that the onboarding data is valid
  bool get isValid {
    // agentId must be present and in correct format
    if (agentId.isEmpty || !agentId.startsWith('agent_')) {
      return false;
    }

    // completedAt must be present
    if (completedAt.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return false; // Can't be in the future (with 1 day tolerance)
    }

    // If age is provided, it should be reasonable
    if (age != null && (age! < 13 || age! > 120)) {
      return false;
    }

    // If birthday is provided, it should be in the past
    if (birthday != null && birthday!.isAfter(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// Convert to a map for use in agent initialization
  /// This is used by PersonalityLearning to map onboarding data to dimensions
  Map<String, dynamic> toAgentInitializationMap() {
    return {
      'age': age,
      'birthday': birthday?.toIso8601String(),
      'homebase': homebase,
      'favoritePlaces': favoritePlaces,
      'preferences': preferences,
      'baselineLists': baselineLists,
      'openResponses': openResponses,
      'respectedFriends': respectedFriends,
      'socialMediaConnected': socialMediaConnected,
    };
  }

  @override
  String toString() {
    return 'OnboardingData(agentId: ${agentId.substring(0, 10)}..., age: $age, homebase: $homebase, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingData &&
        other.agentId == agentId &&
        other.age == age &&
        other.birthday == birthday &&
        other.homebase == homebase &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      agentId,
      age,
      birthday,
      homebase,
      completedAt,
    );
  }
}

/// Sentinel class for copyWith nullable handling
class _Sentinel {
  const _Sentinel();
}
