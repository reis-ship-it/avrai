# Quantum Vibe Analysis to AI Agent Creation Plan

**Date:** December 12, 2025  
**Last Updated:** December 15, 2025 (agentId integration)  
**Status:** 📋 **MASTER PLAN - READY FOR IMPLEMENTATION**  
**Purpose:** Unified implementation plan integrating onboarding, agent creation, social media, and quantum vibe analysis

**🔐 CRITICAL:** This plan follows Master Plan Phase 7.3 (Security Implementation) requirements:
- ✅ All models/services use `agentId` (not `userId`) for internal tracking
- ✅ Services convert `userId → agentId` internally for privacy protection
- ✅ Aligns with Phase 12 Social Media Integration (uses agentId)

---

## 🎯 **OVERVIEW**

This master plan integrates all components needed to:
1. **Fix agent creation pipeline** - Use onboarding data to create personalized agents
2. **Integrate social media** - Analyze social profiles (including Google) for personality insights
3. **Generate real place lists** - Use Google Maps Places API to create personalized lists
4. **Provide recommendations** - Suggest lists and accounts to follow based on onboarding
5. **Implement quantum vibe analysis** - Use quantum math for accurate vibe calculations
6. **Connect everything** - Complete flow from onboarding → agent → vibe analysis

---

## 📊 **CURRENT STATE ANALYSIS**

### **What's Broken**

1. ❌ **Agent Creation**: Agents created with default values (0.5) ignoring onboarding
2. ❌ **Onboarding Data**: Collected but never used or persisted
3. ❌ **Social Media**: Connected but not analyzed or integrated
4. ❌ **Vibe Analysis**: Uses generic agent profiles, not personalized
5. ❌ **Quantum Math**: Not yet implemented

### **What We're Building**

1. ✅ **Personalized Agent Creation**: Agents reflect user's onboarding choices
2. ✅ **Onboarding Data Integration**: Data persisted and used for initialization
3. ✅ **Social Media Analysis**: Profiles analyzed for personality insights (including Google)
4. ✅ **Google Profile Integration**: Google saved places, reviews, photos analyzed for vibe
5. ✅ **Real Place Lists**: Google Maps Places API generates personalized lists
6. ✅ **Smart Recommendations**: Lists and accounts recommended based on onboarding
7. ✅ **Quantum Vibe Analysis**: Advanced math for accurate vibe calculations
8. ✅ **Complete Pipeline**: Onboarding → Agent → Vibe Analysis all connected

---

## 🔐 **AGENT ID SYSTEM (MANDATORY)**

### **agentId vs userId - Critical Understanding**

**This plan follows Master Plan Phase 7.3 (Security Implementation) requirements:**
- ✅ All new models/services MUST use `agentId` (not `userId`) for internal tracking
- ✅ `agentId` is privacy-protected, anonymous identifier for AI2AI network
- ✅ `userId` is used only in UI layer and authentication
- ✅ Services convert `userId → agentId` internally

**What is agentId?**
- Format: `agent_[32+ character base64url string]`
- Cryptographically secure (256 bits entropy)
- Cannot be reverse-engineered to userId
- Used for: AI2AI network, personality profiles, vibe analysis, all privacy-protected operations
- Service: `AgentIdService.getUserAgentId(userId)` converts userId → agentId

**What is userId?**
- Authenticated user identifier from auth system
- Used for: UI layer, authentication, database queries
- Should NOT be used in: AI2AI network, personality profiles, internal tracking

**Pattern: Dual Identity System**
```
UI Layer (userId)
    ↓
Service Layer (converts userId → agentId)
    ↓
Storage/Network (agentId)
```

**All services in this plan:**
- Accept `userId` in public API (for UI compatibility)
- Convert to `agentId` internally using `AgentIdService`
- Store/operate using `agentId` for privacy protection

---

## 🏗️ **ARCHITECTURE OVERVIEW**

### **Complete Data Flow**

```
┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING PHASE                         │
│                                                             │
│  OnboardingPage                                             │
│  ├─ Collects: age, homebase, favorite places, preferences  │
│  ├─ Tracks: social media connections                       │
│  └─ Saves: OnboardingDataService                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ OnboardingData persisted
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    AGENT INITIALIZATION                      │
│                                                             │
│  AILoadingPage                                              │
│  ├─ Loads: OnboardingData from service                     │
│  ├─ Collects: Social media profiles, follows, connections │
│  └─ Calls: initializePersonalityFromOnboarding()          │
│                                                             │
│  PersonalityLearning                                        │
│  ├─ Maps: OnboardingData → dimension values                │
│  ├─ Analyzes: SocialMediaVibeAnalyzer → insights          │
│  ├─ Calculates: QuantumVibeEngine → final dimensions       │
│  └─ Creates: PersonalityProfile with personalized dims     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Personalized PersonalityProfile
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    VIBE ANALYSIS                            │
│                                                             │
│  UserVibeAnalyzer                                          │
│  ├─ Compiles: Personality + Behavioral + Social + etc.     │
│  ├─ Uses: QuantumVibeEngine for calculations               │
│  ├─ Produces: 12 dimension scores (0.0-1.0)               │
│  └─ Generates: UserVibe for matching                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ UserVibe with accurate dimensions
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    MATCHING & RECOMMENDATIONS               │
│                                                             │
│  ├─ User-to-User Matching                                  │
│  ├─ Spot Recommendations                                   │
│  ├─ List Generation                                        │
│  └─ AI2AI Connections                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 **IMPLEMENTATION PHASES**

### **Phase 1: Foundation - Data Models & Services** (3-4 hours)

**Goal:** Create infrastructure for data persistence and analysis

#### **Step 1.1: Create OnboardingData Model**
**File:** `lib/core/models/onboarding_data.dart`

**Purpose:** Structured representation of all onboarding data (privacy-protected with agentId)

**Implementation:**
```dart
class OnboardingData {
  final String agentId; // ✅ Privacy-protected identifier (not userId)
  final int? age;
  final DateTime? birthday;
  final String? homebase;
  final List<String> favoritePlaces;
  final Map<String, List<String>> preferences;
  final List<String> baselineLists;
  final List<String> respectedFriends;
  final Map<String, bool> socialMediaConnected;
  final DateTime completedAt;
  
  OnboardingData({
    required this.agentId, // ✅ Uses agentId
    this.age,
    this.birthday,
    this.homebase,
    this.favoritePlaces = const [],
    this.preferences = const {},
    this.baselineLists = const [],
    this.respectedFriends = const [],
    this.socialMediaConnected = const {},
    required this.completedAt,
  });
  
  Map<String, dynamic> toJson();
  factory OnboardingData.fromJson(Map<String, dynamic> json);
  bool get isValid;
}
```

**Dependencies:** None (model only, agentId provided by service layer)

**Tests:** JSON serialization, validation, edge cases, agentId format validation

---

#### **Step 1.2: Create OnboardingDataService**
**File:** `lib/core/services/onboarding_data_service.dart`

**Purpose:** Persist and retrieve onboarding data (converts userId → agentId internally)

**Implementation:**
```dart
class OnboardingDataService {
  static const String _logName = 'OnboardingDataService';
  static const String _dataKeyPrefix = 'onboarding_data_';
  
  final AgentIdService _agentIdService;
  final SembastDatabase _database;
  
  OnboardingDataService({
    AgentIdService? agentIdService,
    SembastDatabase? database,
  }) : _agentIdService = agentIdService ?? AgentIdService(),
       _database = database ?? SembastDatabase.instance;
  
  /// Save onboarding data (accepts userId, converts to agentId internally)
  Future<void> saveOnboardingData(String userId, OnboardingData data) async {
    try {
      // Convert userId → agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      // Ensure data uses agentId (not userId)
      final dataWithAgentId = OnboardingData(
        agentId: agentId, // ✅ Use agentId
        age: data.age,
        birthday: data.birthday,
        homebase: data.homebase,
        favoritePlaces: data.favoritePlaces,
        preferences: data.preferences,
        baselineLists: data.baselineLists,
        respectedFriends: data.respectedFriends,
        socialMediaConnected: data.socialMediaConnected,
        completedAt: data.completedAt,
      );
      
      // Store using agentId as key
      final store = stringMapStoreFactory.store('onboarding_data');
      await store.record('$_dataKeyPrefix$agentId').put(
        _database.database,
        dataWithAgentId.toJson(),
      );
    } catch (e) {
      developer.log('Error saving onboarding data: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Get onboarding data (accepts userId, converts to agentId internally)
  Future<OnboardingData?> getOnboardingData(String userId) async {
    try {
      // Convert userId → agentId
      final agentId = await _agentIdService.getUserAgentId(userId);
      
      // Retrieve using agentId
      final store = stringMapStoreFactory.store('onboarding_data');
      final data = await store.record('$_dataKeyPrefix$agentId').get(_database.database);
      
      if (data == null) return null;
      
      return OnboardingData.fromJson(data);
    } catch (e) {
      developer.log('Error getting onboarding data: $e', name: _logName);
      return null;
    }
  }
  
  /// Delete onboarding data (accepts userId, converts to agentId internally)
  Future<void> deleteOnboardingData(String userId) async {
    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final store = stringMapStoreFactory.store('onboarding_data');
      await store.record('$_dataKeyPrefix$agentId').delete(_database.database);
    } catch (e) {
      developer.log('Error deleting onboarding data: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Check if onboarding data exists (accepts userId, converts to agentId internally)
  Future<bool> hasOnboardingData(String userId) async {
    final data = await getOnboardingData(userId);
    return data != null;
  }
}
```

**Storage:** Sembast `onboarding_data` store (uses agentId as key)

**Dependencies:**
- `lib/core/services/agent_id_service.dart` (✅ NEW - converts userId → agentId)
- `lib/data/datasources/local/sembast_database.dart`
- `lib/core/models/onboarding_data.dart`

**Tests:** Save/retrieve/delete operations, userId → agentId conversion, error handling, agentId format validation

---

#### **Step 1.3: Create SocialMediaVibeAnalyzer**
**File:** `lib/core/services/social_media_vibe_analyzer.dart`

**Purpose:** Analyze social media profiles (including Google) for personality insights

**Implementation:**
```dart
class SocialMediaVibeAnalyzer {
  static const String _logName = 'SocialMediaVibeAnalyzer';
  
  /// Analyze social media profile for initial personality dimensions
  /// Supports: Instagram, Facebook, Twitter, LinkedIn, TikTok, Google
  Future<Map<String, double>> analyzeProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    required List<Map<String, dynamic>> connections,
    required String platform, // 'instagram', 'facebook', 'twitter', 'linkedin', 'tiktok', 'google'
  });
  
  /// Analyze Google profile specifically
  /// Google profile includes: saved places, reviews, photos, location history
  Future<Map<String, double>> analyzeGoogleProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> savedPlaces,
    required List<Map<String, dynamic>> reviews,
    required List<Map<String, dynamic>> photos,
    String? locationHistory,
  });
  
  // Private helper methods
  Map<String, double> _analyzeProfileContent(...);
  Map<String, double> _analyzeFollows(...);
  Map<String, double> _analyzeConnections(...);
  Map<String, double> _analyzeGoogleSavedPlaces(...); // NEW
  Map<String, double> _analyzeGoogleReviews(...); // NEW
  Map<String, double> _analyzeGooglePhotos(...); // NEW
  Map<String, double> _aggregateInsights(...);
  List<String> _extractInterests(...);
  String _categorizeInterest(...);
  void _applyInterestToDimensions(...);
  List<String> _extractKeywords(...);
  bool _hasAuthenticKeywords(...);
}
```

**Dependencies:**
- `lib/core/constants/vibe_constants.dart` (for dimension names)

**Tests:**
- Profile analysis (all platforms including Google)
- Follows analysis
- Connections analysis
- Google saved places analysis (NEW)
- Google reviews analysis (NEW)
- Google photos analysis (NEW)
- Interest extraction
- Dimension mapping
- Edge cases (empty data, missing fields)

---

#### **Step 1.4: Create OnboardingPlaceListGenerator**
**File:** `lib/core/services/onboarding_place_list_generator.dart`

**Purpose:** Generate real place lists using Google Maps Places API based on onboarding data

**Implementation:**
```dart
class OnboardingPlaceListGenerator {
  static const String _logName = 'OnboardingPlaceListGenerator';
  
  final GooglePlacesDataSource _placesDataSource;
  final String? _apiKey;
  
  /// Generate personalized place lists based on onboarding data
  Future<List<GeneratedPlaceList>> generatePlaceLists({
    required Map<String, dynamic> onboardingData,
    required String homebase,
    double? latitude,
    double? longitude,
    int maxLists = 5,
  });
  
  /// Generate list for a specific category
  Future<GeneratedPlaceList> generateListForCategory({
    required String category,
    required String homebase,
    double? latitude,
    double? longitude,
    required List<String> preferences,
    int maxPlaces = 20,
  });
  
  /// Search places using Google Maps Places API
  Future<List<Spot>> searchPlacesForCategory({
    required String category,
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type, // restaurant, cafe, bar, park, etc.
  });
  
  // Private helper methods
  List<String> _extractCategoriesFromPreferences(...);
  String _buildSearchQuery(...);
  String _mapPreferenceToPlaceType(...);
  List<Spot> _filterAndRankPlaces(...);
  GeneratedPlaceList _createListFromPlaces(...);
}

class GeneratedPlaceList {
  final String name;
  final String description;
  final List<Spot> places;
  final String category;
  final double relevanceScore; // 0.0-1.0
  final Map<String, dynamic> metadata;
}
```

**Dependencies:**
- `lib/data/datasources/remote/google_places_datasource.dart`
- `lib/core/models/spot.dart`

**Tests:**
- List generation from onboarding data
- Category-based list generation
- Place search and filtering
- Relevance scoring
- Edge cases (no preferences, invalid location)

---

#### **Step 1.5: Create OnboardingRecommendationService**
**File:** `lib/core/services/onboarding_recommendation_service.dart`

**Purpose:** Recommend lists and accounts to follow based on onboarding data

**Implementation:**
```dart
class OnboardingRecommendationService {
  static const String _logName = 'OnboardingRecommendationService';
  
  final AgentIdService _agentIdService;
  
  OnboardingRecommendationService({
    AgentIdService? agentIdService,
  }) : _agentIdService = agentIdService ?? AgentIdService();
  
  /// Get recommended lists to follow based on onboarding
  /// Accepts userId from UI layer, converts to agentId internally
  Future<List<ListRecommendation>> getRecommendedLists({
    required String userId, // ✅ Accept userId from UI
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    // Convert userId → agentId for privacy-protected operations
    final agentId = await _agentIdService.getUserAgentId(userId);
    
    // Use agentId for internal operations (matching, compatibility, etc.)
    // ...
  }
  
  /// Get recommended accounts to follow based on onboarding
  /// Accepts userId from UI layer, converts to agentId internally
  Future<List<AccountRecommendation>> getRecommendedAccounts({
    required String userId, // ✅ Accept userId from UI
    required Map<String, dynamic> onboardingData,
    required Map<String, double> personalityDimensions,
    int maxRecommendations = 10,
  }) async {
    // Convert userId → agentId for privacy-protected operations
    final agentId = await _agentIdService.getUserAgentId(userId);
    
    // Use agentId for internal operations (matching, compatibility, etc.)
    // ...
  }
  
  /// Calculate compatibility score between user and list/account
  double calculateCompatibility({
    required Map<String, double> userDimensions,
    required Map<String, double> listDimensions,
  });
  
  // Private helper methods
  List<ListRecommendation> _findListsByPreferences(...);
  List<ListRecommendation> _findListsByHomebase(...);
  List<ListRecommendation> _findListsByArchetype(...);
  List<AccountRecommendation> _findAccountsByInterests(...);
  List<AccountRecommendation> _findAccountsByLocation(...);
  double _calculateVibeMatch(...);
}

class ListRecommendation {
  final String listId;
  final String listName;
  final String curatorName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this list matches
  final Map<String, dynamic> metadata;
}

class AccountRecommendation {
  final String accountId;
  final String accountName;
  final String displayName;
  final String description;
  final double compatibilityScore; // 0.0-1.0
  final List<String> matchingReasons; // Why this account matches
  final Map<String, dynamic> metadata;
}
```

**Dependencies:**
- `lib/core/services/agent_id_service.dart` (✅ NEW - converts userId → agentId)
- `lib/core/ai/personality_learning.dart` (for personality dimensions)
- `lib/core/models/list.dart` (for list data)
- `lib/core/models/user.dart` (for account data)

**Tests:**
- List recommendations based on preferences
- List recommendations based on homebase
- List recommendations based on archetype
- Account recommendations based on interests
- Account recommendations based on location
- Compatibility score calculation
- Edge cases (no matches, empty onboarding data)

---

### **Phase 2: Agent Initialization - Personality Learning Extensions** (2-3 hours)

**Goal:** Add methods to initialize personality from onboarding and social media data

#### **Step 2.1: Add Onboarding-to-Dimensions Mapping**
**File:** `lib/core/ai/personality_learning.dart`

**Purpose:** Convert onboarding data to personality dimension values

**Implementation:**
```dart
/// Map onboarding data to personality dimensions
Map<String, double> _mapOnboardingToDimensions(
  Map<String, dynamic> onboardingData,
) {
  final insights = <String, double>{};
  
  // Age adjustments
  final age = onboardingData['age'] as int?;
  if (age != null) {
    if (age < 25) {
      insights['exploration_eagerness'] = 0.6;
      insights['temporal_flexibility'] = 0.65;
    } else if (age > 45) {
      insights['authenticity_preference'] = 0.65;
      insights['trust_network_reliance'] = 0.6;
    }
  }
  
  // Homebase → location dimensions
  final homebase = onboardingData['homebase'] as String?;
  if (homebase != null && _isUrbanArea(homebase)) {
    insights['location_adventurousness'] = 
        (insights['location_adventurousness'] ?? 0.5) + 0.1;
  }
  
  // Favorite places → exploration, location adventurousness
  final favoritePlaces = onboardingData['favoritePlaces'] as List<dynamic>? ?? [];
  if (favoritePlaces.length > 5) {
    insights['exploration_eagerness'] = 
        (insights['exploration_eagerness'] ?? 0.5) + 0.1;
    insights['location_adventurousness'] = 
        (insights['location_adventurousness'] ?? 0.5) + 0.12;
  }
  
  // Preferences mapping
  final preferences = onboardingData['preferences'] as Map<String, dynamic>? ?? {};
  
  // Food & Drink → curation, authenticity
  if (preferences.containsKey('Food & Drink')) {
    final foodPrefs = preferences['Food & Drink'] as List<dynamic>? ?? [];
    if (foodPrefs.isNotEmpty) {
      insights['curation_tendency'] = 
          (insights['curation_tendency'] ?? 0.5) + 0.05;
      insights['authenticity_preference'] = 
          (insights['authenticity_preference'] ?? 0.5) + 0.03;
    }
  }
  
  // Activities → exploration, social
  if (preferences.containsKey('Activities')) {
    final activityPrefs = preferences['Activities'] as List<dynamic>? ?? [];
    if (activityPrefs.isNotEmpty) {
      insights['exploration_eagerness'] = 
          (insights['exploration_eagerness'] ?? 0.5) + 0.08;
      insights['social_discovery_style'] = 
          (insights['social_discovery_style'] ?? 0.5) + 0.05;
    }
  }
  
  // Outdoor & Nature → location adventurousness, exploration
  if (preferences.containsKey('Outdoor & Nature')) {
    final outdoorPrefs = preferences['Outdoor & Nature'] as List<dynamic>? ?? [];
    if (outdoorPrefs.isNotEmpty) {
      insights['location_adventurousness'] = 
          (insights['location_adventurousness'] ?? 0.5) + 0.1;
      insights['exploration_eagerness'] = 
          (insights['exploration_eagerness'] ?? 0.5) + 0.08;
    }
  }
  
  // Social preferences → community orientation, social discovery
  if (preferences.containsKey('Social')) {
    final socialPrefs = preferences['Social'] as List<dynamic>? ?? [];
    if (socialPrefs.isNotEmpty) {
      insights['community_orientation'] = 
          (insights['community_orientation'] ?? 0.5) + 0.1;
      insights['social_discovery_style'] = 
          (insights['social_discovery_style'] ?? 0.5) + 0.08;
    }
  }
  
  // Friends/Respected Lists → community orientation, trust network
  final respectedFriends = onboardingData['respectedFriends'] as List<dynamic>? ?? [];
  if (respectedFriends.isNotEmpty) {
    insights['community_orientation'] = 
        (insights['community_orientation'] ?? 0.5) + 0.08;
    insights['trust_network_reliance'] = 
        (insights['trust_network_reliance'] ?? 0.5) + 0.06;
  }
  
  // Clamp all values to valid range
  insights.forEach((key, value) {
    insights[key] = value.clamp(0.0, 1.0);
  });
  
  return insights;
}
```

**Dependencies:**
- `lib/core/constants/vibe_constants.dart`

**Tests:** Age mapping, homebase mapping, preferences mapping, edge cases

---

#### **Step 2.2: Add initializePersonalityFromOnboarding() Method**
**File:** `lib/core/ai/personality_learning.dart`

**Purpose:** Initialize personality with onboarding and social media data

**Implementation:**
```dart
/// Initialize personality from onboarding data including social media
/// Accepts userId from UI layer, converts to agentId internally for privacy protection
Future<PersonalityProfile> initializePersonalityFromOnboarding(
  String userId, { // ✅ Accept userId from UI
  Map<String, dynamic>? onboardingData,
  Map<String, dynamic>? socialMediaData,
}) async {
  // Convert userId → agentId for privacy protection
  final agentIdService = AgentIdService();
  final agentId = await agentIdService.getUserAgentId(userId);
  
  developer.log(
    'Initializing personality from onboarding for user: $userId (agentId: $agentId)',
    name: _logName,
  );

  try {
    // Check if profile already exists (using agentId)
    // Note: PersonalityProfile may still use userId internally until Phase 7.3 migration
    // For now, we'll use userId but prepare for agentId migration
    final existingProfile = await _loadPersonalityProfile(userId);
    if (existingProfile != null && existingProfile.evolutionGeneration > 1) {
      // Profile already evolved, don't overwrite
      return existingProfile;
    }
    
    // Start with default initial profile
    // TODO: Update PersonalityProfile.initial() to accept agentId after Phase 7.3 migration
    final baseProfile = PersonalityProfile.initial(userId);
    final initialDimensions = Map<String, double>.from(baseProfile.dimensions);
    final initialConfidence = Map<String, double>.from(baseProfile.dimensionConfidence);
    
    // 1. Apply onboarding data (if provided)
    if (onboardingData != null && onboardingData.isNotEmpty) {
      final onboardingInsights = _mapOnboardingToDimensions(onboardingData);
      
      // Apply insights to dimensions (60% onboarding, 40% default)
      onboardingInsights.forEach((dimension, value) {
        final currentValue = initialDimensions[dimension] ?? 0.5;
        initialDimensions[dimension] = 
            (currentValue * 0.4 + value * 0.6).clamp(0.0, 1.0);
        initialConfidence[dimension] = 0.3; // Some confidence from onboarding
      });
    }
    
    // 2. Apply social media insights (if provided)
    if (socialMediaData != null && socialMediaData.isNotEmpty) {
      try {
        final analyzer = SocialMediaVibeAnalyzer();
        final socialInsights = await analyzer.analyzeProfileForVibe(
          profileData: socialMediaData['profile'] ?? {},
          follows: socialMediaData['follows'] ?? [],
          connections: socialMediaData['connections'] ?? [],
          platform: socialMediaData['platform'] ?? 'unknown',
        );
        
        // Blend social media insights (40% social, 60% existing)
        socialInsights.forEach((dimension, socialValue) {
          final existingValue = initialDimensions[dimension] ?? 0.5;
          initialDimensions[dimension] = 
              (existingValue * 0.6 + socialValue * 0.4).clamp(0.0, 1.0);
          initialConfidence[dimension] = 
              (initialConfidence[dimension] ?? 0.0) + 0.2;
        });
      } catch (e) {
        developer.log('Error analyzing social media: $e', name: _logName);
        // Continue without social media data
      }
    }
    
    // 3. Use quantum engine for final dimension calculation (Phase 4)
    // For now, use calculated dimensions directly
    
    // 4. Determine archetype from dimensions
    final archetype = _determineArchetypeFromDimensions(initialDimensions);
    
    // 5. Calculate initial authenticity
    final authenticity = _calculateInitialAuthenticity(
      initialDimensions,
      onboardingData,
    );
    
    // 6. Create profile with initial dimensions
    // TODO: Update to use agentId after PersonalityProfile migration (Phase 7.3)
    // For now, use userId but log agentId for tracking
    final newProfile = PersonalityProfile(
      userId: userId, // TODO: Change to agentId after Phase 7.3 migration
      dimensions: initialDimensions,
      dimensionConfidence: initialConfidence,
      archetype: archetype,
      authenticity: authenticity,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      evolutionGeneration: 1,
      learningHistory: {
        'total_interactions': 0,
        'successful_ai2ai_connections': 0,
        'learning_sources': [
          if (onboardingData != null) 'onboarding',
          if (socialMediaData != null) 'social_media',
        ],
        'evolution_milestones': [DateTime.now()],
        'onboarding_data_used': onboardingData != null,
        'social_media_data_used': socialMediaData != null,
        'agent_id': agentId, // ✅ Store agentId in learning history for tracking
      },
    );
    
    await _savePersonalityProfile(newProfile);
    _currentProfile = newProfile;
    
    developer.log('✅ Personality initialized with agentId: $agentId', name: _logName);
    return newProfile;
  } catch (e) {
    developer.log('Error initializing from onboarding: $e', name: _logName);
    // Fallback to default
    return PersonalityProfile.initial(userId);
  }
}

/// Determine archetype from initial dimensions
String _determineArchetypeFromDimensions(Map<String, double> dimensions) {
  final exploration = dimensions['exploration_eagerness'] ?? 0.5;
  final social = dimensions['social_discovery_style'] ?? 0.5;
  final energy = (dimensions['exploration_eagerness'] ?? 0.5) +
                 (dimensions['temporal_flexibility'] ?? 0.5) +
                 (dimensions['location_adventurousness'] ?? 0.5);
  final avgEnergy = energy / 3.0;
  
  if (exploration >= 0.8 && avgEnergy >= 0.7) {
    return 'adventurous_explorer';
  }
  if (social >= 0.8 && avgEnergy >= 0.6) {
    return 'social_connector';
  }
  if (exploration <= 0.3 && social >= 0.7) {
    return 'community_curator';
  }
  if (exploration >= 0.7 && social <= 0.4) {
    return 'authentic_seeker';
  }
  if (avgEnergy >= 0.8) {
    return 'spontaneous_wanderer';
  }
  
  return 'balanced_explorer';
}

/// Calculate initial authenticity from dimensions and onboarding
double _calculateInitialAuthenticity(
  Map<String, double> dimensions,
  Map<String, dynamic>? onboardingData,
) {
  var authenticity = dimensions['authenticity_preference'] ?? 0.5;
  
  if (onboardingData != null) {
    final preferences = onboardingData['preferences'] as Map<String, dynamic>? ?? {};
    if (preferences.containsKey('Authentic') || 
        preferences.containsKey('Local')) {
      authenticity = (authenticity + 0.1).clamp(0.0, 1.0);
    }
  }
  
  return authenticity;
}
```

**Dependencies:**
- `lib/core/services/agent_id_service.dart` (✅ NEW - converts userId → agentId)
- `lib/core/services/social_media_vibe_analyzer.dart`
- `_mapOnboardingToDimensions()` method

**Tests:** Initialize with onboarding only, social media only, both, neither, error handling, userId → agentId conversion

---

### **Phase 3: Onboarding Flow Integration** (2-3 hours)

**Goal:** Update onboarding pages to save data and use new initialization

#### **Step 3.1: Update OnboardingPage**
**File:** `lib/presentation/pages/onboarding/onboarding_page.dart`

**Changes:**
1. Import OnboardingDataService and OnboardingData
2. Track social media connection status
3. Save onboarding data before navigation

**Key Changes:**
```dart
// Add imports
import 'package:spots/core/services/onboarding_data_service.dart';
import 'package:spots/core/models/onboarding_data.dart';

// Add state variable
Map<String, bool> _connectedSocialPlatforms = {};

// Update _completeOnboarding()
void _completeOnboarding() async {
  try {
    // ... existing code ...
    
    // Calculate age
    int? age;
    if (_selectedBirthday != null) {
      final now = DateTime.now();
      age = now.year - _selectedBirthday!.year;
      if (now.month < _selectedBirthday!.month ||
          (now.month == _selectedBirthday!.month &&
              now.day < _selectedBirthday!.day)) {
        age--;
      }
    }
    
      // Save onboarding data
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final userId = authState.user.id;
        
        // Get agentId for onboarding data
        final agentIdService = di.sl<AgentIdService>();
        final agentId = await agentIdService.getUserAgentId(userId);
        
        final onboardingData = OnboardingData(
          agentId: agentId, // ✅ Use agentId (privacy-protected)
          age: age,
          birthday: _selectedBirthday,
          homebase: _selectedHomebase,
          favoritePlaces: _favoritePlaces,
          preferences: _preferences,
          baselineLists: _baselineLists,
          respectedFriends: _respectedFriends,
          socialMediaConnected: _connectedSocialPlatforms,
          completedAt: DateTime.now(),
        );
        
        try {
          final onboardingService = di.sl<OnboardingDataService>();
          // Service accepts userId but converts to agentId internally
          await onboardingService.saveOnboardingData(userId, onboardingData);
          _logger.info('✅ Saved onboarding data (agentId: $agentId)', tag: 'Onboarding');
        } catch (e) {
          _logger.error('❌ Failed to save onboarding data: $e', tag: 'Onboarding');
          // Continue anyway - data will be passed via router
        }
      }
    
    // Navigate to AI loading page
    router.go('/ai-loading', extra: {
      'userName': "User",
      'birthday': _selectedBirthday?.toIso8601String(),
      'age': age,
      'homebase': _selectedHomebase,
      'favoritePlaces': _favoritePlaces,
      'preferences': _preferences,
      'baselineLists': _baselineLists,
      'socialMediaConnected': _connectedSocialPlatforms,
    });
  } catch (e) {
    // ... error handling ...
  }
}
```

**Dependencies:**
- `lib/core/services/onboarding_data_service.dart`
- `lib/core/models/onboarding_data.dart`

---

#### **Step 3.2: Update AILoadingPage**
**File:** `lib/presentation/pages/onboarding/ai_loading_page.dart`

**Changes:**
1. Load onboarding data from service (fallback to router extra)
2. Collect social media data if connected
3. Call `initializePersonalityFromOnboarding()` instead of `initializePersonality()`

**Key Changes:**
```dart
// Add imports
import 'package:spots/core/services/onboarding_data_service.dart';
import 'package:spots/core/services/social_media_connection_service.dart';
import 'package:spots/core/services/social_media_insight_service.dart';
import 'package:spots/core/services/onboarding_place_list_generator.dart'; // NEW
import 'package:spots/core/services/onboarding_recommendation_service.dart'; // NEW

// Update _startLoading() method
void _startLoading() async {
  // ... existing list generation code ...
  
  // Initialize personalized agent
  try {
    final authState = authBloc.state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      
      // Load onboarding data
      Map<String, dynamic>? onboardingDataMap;
      try {
        final onboardingService = di.sl<OnboardingDataService>();
        final onboardingData = await onboardingService.getOnboardingData(userId);
        
        if (onboardingData != null) {
          onboardingDataMap = {
            'age': onboardingData.age,
            'birthday': onboardingData.birthday?.toIso8601String(),
            'homebase': onboardingData.homebase,
            'favoritePlaces': onboardingData.favoritePlaces,
            'preferences': onboardingData.preferences,
            'baselineLists': onboardingData.baselineLists,
            'respectedFriends': onboardingData.respectedFriends,
          };
        } else {
          // Fallback: Use data from router extra
          onboardingDataMap = {
            'age': widget.age,
            'birthday': widget.birthday?.toIso8601String(),
            'homebase': widget.homebase,
            'favoritePlaces': widget.favoritePlaces,
            'preferences': widget.preferences,
            'baselineLists': widget.baselineLists,
          };
        }
      } catch (e) {
        _logger.warn('⚠️ Could not load onboarding data: $e', tag: 'AILoadingPage');
        // Fallback to router extra
        onboardingDataMap = {
          'age': widget.age,
          'birthday': widget.birthday?.toIso8601String(),
          'homebase': widget.homebase,
          'favoritePlaces': widget.favoritePlaces,
          'preferences': widget.preferences,
          'baselineLists': widget.baselineLists,
        };
      }
      
      // Collect social media data if connected (including Google)
      // Note: Phase 12 Social Media Integration uses agentId
      Map<String, dynamic>? socialMediaData;
      try {
        final agentIdService = di.sl<AgentIdService>();
        final agentId = await agentIdService.getUserAgentId(userId);
        
        final socialMediaService = di.sl<SocialMediaConnectionService>();
        // Phase 12 uses agentId for connections (privacy-protected)
        final connections = await socialMediaService.getActiveConnections(agentId);
        
        if (connections.isNotEmpty) {
          // Fetch profile, follows, and connections for each platform
          final allProfileData = <String, dynamic>{};
          final allFollows = <Map<String, dynamic>>[];
          final allConnections = <Map<String, dynamic>>[];
          final googleSavedPlaces = <Map<String, dynamic>>[]; // NEW
          final googleReviews = <Map<String, dynamic>>[]; // NEW
          final googlePhotos = <Map<String, dynamic>>[]; // NEW
          String? primaryPlatform;
          
          for (final connection in connections) {
            try {
              final profileData = await socialMediaService.fetchProfile(connection.id);
              final follows = await socialMediaService.fetchFollows(connection.id);
              final connections = await socialMediaService.fetchConnections(connection.id);
              
              // NEW: Handle Google profile data
              if (connection.platform == 'google') {
                final savedPlaces = await socialMediaService.fetchGoogleSavedPlaces(connection.id);
                final reviews = await socialMediaService.fetchGoogleReviews(connection.id);
                final photos = await socialMediaService.fetchGooglePhotos(connection.id);
                
                googleSavedPlaces.addAll(savedPlaces);
                googleReviews.addAll(reviews);
                googlePhotos.addAll(photos);
              }
              
              allProfileData.addAll(profileData);
              allFollows.addAll(follows);
              allConnections.addAll(connections);
              
              if (primaryPlatform == null) {
                primaryPlatform = connection.platform;
              }
            } catch (e) {
              _logger.warn('⚠️ Error fetching data for ${connection.platform}: $e',
                  tag: 'AILoadingPage');
            }
          }
          
          if (allProfileData.isNotEmpty || allFollows.isNotEmpty || 
              googleSavedPlaces.isNotEmpty) {
            socialMediaData = {
              'profile': allProfileData,
              'follows': allFollows,
              'connections': allConnections,
              'platform': primaryPlatform ?? 'unknown',
              // NEW: Google-specific data
              if (googleSavedPlaces.isNotEmpty) 'googleSavedPlaces': googleSavedPlaces,
              if (googleReviews.isNotEmpty) 'googleReviews': googleReviews,
              if (googlePhotos.isNotEmpty) 'googlePhotos': googlePhotos,
            };
          }
        }
      } catch (e) {
        _logger.warn('⚠️ Could not collect social media data: $e', tag: 'AILoadingPage');
      }
      
      // Initialize with onboarding and social media data
      final personalityLearning = di.sl<PersonalityLearning>();
      final personalityProfile = await personalityLearning
          .initializePersonalityFromOnboarding(
        userId,
        onboardingData: onboardingDataMap,
        socialMediaData: socialMediaData,
      );

      _logger.info(
          '✅ Personalized agent initialized (generation ${personalityProfile.evolutionGeneration})',
          tag: 'AILoadingPage');
      _logger.debug('  Archetype: ${personalityProfile.archetype}',
          tag: 'AILoadingPage');
      _logger.debug('  Dimensions: ${personalityProfile.dimensions}',
          tag: 'AILoadingPage');
      
      // NEW: Generate place lists from Google Maps Places API
      try {
        final placeListGenerator = di.sl<OnboardingPlaceListGenerator>();
        final homebase = onboardingDataMap?['homebase'] ?? widget.homebase ?? '';
        
        // TODO: Get latitude/longitude from location service or geocoding
        final generatedLists = await placeListGenerator.generatePlaceLists(
          onboardingData: onboardingDataMap ?? {},
          homebase: homebase,
          latitude: null, // TODO: Get from location service
          longitude: null, // TODO: Get from location service
          maxLists: 5,
        );
        
        _logger.info('📍 Generated ${generatedLists.length} place lists from onboarding',
            tag: 'AILoadingPage');
        
        // Save generated lists for user
        // TODO: Save to user's lists using ListService
        for (final list in generatedLists) {
          _logger.debug('  List: ${list.name} (${list.places.length} places, relevance: ${list.relevanceScore})',
              tag: 'AILoadingPage');
        }
      } catch (e) {
        _logger.warn('⚠️ Could not generate place lists: $e', tag: 'AILoadingPage');
        // Continue without place lists
      }
      
      // NEW: Get recommendations for lists and accounts to follow
      try {
        final recommendationService = di.sl<OnboardingRecommendationService>();
        
        final recommendedLists = await recommendationService.getRecommendedLists(
          userId: userId,
          onboardingData: onboardingDataMap ?? {},
          personalityDimensions: personalityProfile.dimensions,
          maxRecommendations: 10,
        );
        
        final recommendedAccounts = await recommendationService.getRecommendedAccounts(
          userId: userId,
          onboardingData: onboardingDataMap ?? {},
          personalityDimensions: personalityProfile.dimensions,
          maxRecommendations: 10,
        );
        
        _logger.info(
          '💡 Found ${recommendedLists.length} list recommendations and ${recommendedAccounts.length} account recommendations',
          tag: 'AILoadingPage',
        );
        
        // TODO: Display recommendations to user after onboarding completes
        // Store recommendations for later display
        for (final listRec in recommendedLists) {
          _logger.debug('  List: ${listRec.listName} (compatibility: ${listRec.compatibilityScore})',
              tag: 'AILoadingPage');
        }
        for (final accountRec in recommendedAccounts) {
          _logger.debug('  Account: ${accountRec.accountName} (compatibility: ${accountRec.compatibilityScore})',
              tag: 'AILoadingPage');
        }
      } catch (e) {
        _logger.warn('⚠️ Could not get recommendations: $e', tag: 'AILoadingPage');
        // Continue without recommendations
      }
    }
  } catch (e, stackTrace) {
    // ... error handling ...
  }
}
```

**Dependencies:**
- `lib/core/services/agent_id_service.dart` (✅ NEW - converts userId → agentId)
- `lib/core/services/onboarding_data_service.dart`
- `lib/core/services/social_media_connection_service.dart` (uses agentId per Phase 12)
- `lib/core/services/onboarding_place_list_generator.dart` (NEW)
- `lib/core/services/onboarding_recommendation_service.dart` (NEW)
- `lib/core/ai/personality_learning.dart` (with new method)

---

### **Phase 4: Quantum Vibe Engine Implementation** (2-3 hours)

**Goal:** Implement quantum-based mathematics for vibe analysis

#### **Step 4.1: Create Quantum State Model**
**File:** `lib/core/ai/quantum/quantum_vibe_state.dart`

**Purpose:** Core quantum state representation

**Implementation:**
```dart
/// Quantum state representation for vibe dimensions
/// Uses complex probability amplitudes instead of classical probabilities
class QuantumVibeState {
  final double real;      // Real component of amplitude
  final double imaginary; // Imaginary component of amplitude

  QuantumVibeState(this.real, this.imaginary);

  /// Probability of this state (|amplitude|²)
  double get probability => real * real + imaginary * imaginary;

  /// Phase of the quantum state
  double get phase => atan2(imaginary, real);

  /// Magnitude of the amplitude
  double get magnitude => sqrt(real * real + imaginary * imaginary);

  /// Create from classical probability (collapsed state)
  factory QuantumVibeState.fromClassical(double probability) {
    final magnitude = sqrt(probability.clamp(0.0, 1.0));
    return QuantumVibeState(magnitude, 0.0);
  }

  /// Collapse to classical probability (measurement)
  double collapse() => probability.clamp(0.0, 1.0);

  /// Quantum superposition: combine two states
  QuantumVibeState superpose(QuantumVibeState other, double weight) {
    final w1 = sqrt(weight);
    final w2 = sqrt(1.0 - weight);
    final newReal = w1 * real + w2 * other.real;
    final newImaginary = w1 * imaginary + w2 * other.imaginary;
    final magnitude = sqrt(newReal * newReal + newImaginary * newImaginary);
    if (magnitude > 0.0) {
      return QuantumVibeState(newReal / magnitude, newImaginary / magnitude);
    }
    return QuantumVibeState(0.0, 0.0);
  }

  /// Quantum interference: add amplitudes (constructive/destructive)
  QuantumVibeState interfere(QuantumVibeState other, {bool constructive = true}) {
    if (constructive) {
      return QuantumVibeState(real + other.real, imaginary + other.imaginary);
    } else {
      return QuantumVibeState(real - other.real, imaginary - other.imaginary);
    }
  }

  /// Quantum entanglement: correlate with another state
  QuantumVibeState entangle(QuantumVibeState other, double correlation) {
    final phaseDiff = (phase - other.phase) * correlation;
    final newPhase = phase + phaseDiff;
    return QuantumVibeState(
      magnitude * cos(newPhase),
      magnitude * sin(newPhase),
    );
  }
}
```

**Dependencies:** `dart:math`

**Tests:** Probability calculation, superposition, interference, entanglement, collapse

---

#### **Step 4.2: Create Quantum Dimension Wrapper**
**File:** `lib/core/ai/quantum/quantum_vibe_dimension.dart`

**Purpose:** Quantum dimension wrapper with confidence

**Implementation:**
```dart
/// Quantum vibe dimension state
class QuantumVibeDimension {
  final String dimension;
  final QuantumVibeState state;
  final double confidence; // Measurement confidence

  QuantumVibeDimension({
    required this.dimension,
    required this.state,
    this.confidence = 0.5,
  });

  /// Measure (collapse) to classical value
  double measure() => state.collapse();

  /// Get probability without collapsing
  double get probability => state.probability;
}
```

**Dependencies:** `quantum_vibe_state.dart`

**Tests:** Measurement, probability access

---

#### **Step 4.3: Create Quantum Vibe Engine**
**File:** `lib/core/ai/quantum/quantum_vibe_engine.dart`

**Purpose:** Quantum compilation engine for vibe dimensions

**Key Methods:**
```dart
class QuantumVibeEngine {
  /// Compile vibe dimensions using quantum mathematics
  Future<Map<String, double>> compileVibeDimensionsQuantum(
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal,
    {List<SocialMediaInsights>? socialMediaProfiles},
  );
  
  // Helper methods
  QuantumVibeState _quantumSuperpose(List<QuantumVibeState> states, List<double> weights);
  QuantumVibeState _quantumInterfere(List<QuantumVibeState> states, List<double> weights, {bool constructive});
  QuantumVibeState _createEntangledNetwork(List<QuantumVibeState> states, List<double> weights);
  double _calculateTunnelingProbability(QuantumVibeState exploration, QuantumVibeState momentum);
  QuantumVibeState _applyDecoherence(QuantumVibeState state, double decoherenceFactor);
  double _calculateTemporalPhase(TemporalVibeInsights temporal);
  bool _areAligned(List<QuantumVibeState> states);
  double _calculateQuantumConfidence(List<QuantumVibeState> states);
  List<QuantumVibeState> _convertSocialMediaToQuantumStates(List<SocialMediaInsights> profiles);
  QuantumVibeState _superposeSocialMediaProfiles(List<SocialMediaInsights> profiles);
}
```

**Dependencies:**
- `quantum_vibe_state.dart`
- `quantum_vibe_dimension.dart`
- `vibe_analysis_engine.dart` (for insight types)

**Tests:** Quantum compilation for all dimensions, superposition, interference, entanglement, tunneling, decoherence

---

#### **Step 4.4: Integrate Quantum Engine into Agent Initialization**
**File:** `lib/core/ai/personality_learning.dart`

**Update `initializePersonalityFromOnboarding()` to use quantum engine:**

```dart
// After collecting onboarding and social media insights
// Use quantum engine for final dimension calculation

if (quantumEngineAvailable) {
  final quantumEngine = di.sl<QuantumVibeEngine>();
  
  // Convert insights to quantum-compatible format
  final personalityInsights = PersonalityVibeInsights(
    dominantTraits: _extractDominantTraits(initialDimensions),
    personalityStrength: 0.7,
    evolutionMomentum: 0.3,
    authenticityLevel: authenticity,
    confidenceLevel: _calculateAverageConfidence(initialConfidence),
  );
  
  final behavioralInsights = BehavioralVibeInsights(
    activityLevel: 0.5,
    explorationTendency: initialDimensions['exploration_eagerness'] ?? 0.5,
    socialEngagement: initialDimensions['community_orientation'] ?? 0.5,
    spontaneityIndex: initialDimensions['temporal_flexibility'] ?? 0.5,
    consistencyScore: 0.5,
  );
  
  // ... create other insights ...
  
  // Use quantum engine to compile final dimensions
  final quantumDimensions = await quantumEngine.compileVibeDimensionsQuantum(
    personalityInsights,
    behavioralInsights,
    socialInsights,
    relationshipInsights,
    temporalInsights,
    socialMediaProfiles: socialMediaProfilesList,
  );
  
  // Blend quantum dimensions with onboarding dimensions (70% quantum, 30% onboarding)
  quantumDimensions.forEach((dimension, quantumValue) {
    final onboardingValue = initialDimensions[dimension] ?? 0.5;
    initialDimensions[dimension] = 
        (onboardingValue * 0.3 + quantumValue * 0.7).clamp(0.0, 1.0);
  });
}
```

**Dependencies:** `QuantumVibeEngine`

---

#### **Step 4.5: Update UserVibeAnalyzer to Use Quantum Engine**
**File:** `lib/core/ai/vibe_analysis_engine.dart`

**Changes:**
1. Add import for quantum engine
2. Add feature flag for quantum vs classical
3. Update `_compileVibeDimensions()` to call quantum engine when enabled

**Implementation:**
```dart
// Add at top
import 'package:spots/core/ai/quantum/quantum_vibe_engine.dart';

// Add feature flag
static const bool _useQuantumVibeAnalysis = true;

// Update _compileVibeDimensions
Future<Map<String, double>> _compileVibeDimensions(...) async {
  if (_useQuantumVibeAnalysis) {
    final quantumEngine = QuantumVibeEngine();
    
    // Collect social media profiles if available
    List<SocialMediaInsights>? socialMediaProfiles;
    try {
      final socialMediaService = di.sl<SocialMediaConnectionService>();
      final connections = await socialMediaService.getActiveConnections(userId);
      
      if (connections.isNotEmpty) {
        final insightService = di.sl<SocialMediaInsightService>();
        socialMediaProfiles = await insightService.getInsightsForUser(userId);
      }
    } catch (e) {
      developer.log('Could not load social media profiles: $e', name: _logName);
    }
    
    return await quantumEngine.compileVibeDimensionsQuantum(
      personality,
      behavioral,
      social,
      relationship,
      temporal,
      socialMediaProfiles: socialMediaProfiles,
    );
  }
  
  // Fallback to classical
  return await _compileVibeDimensionsClassical(...);
}
```

**Dependencies:** `QuantumVibeEngine`

---

#### **Step 4.6: Update UserVibe Model for Quantum Compatibility**
**File:** `lib/core/models/user_vibe.dart`

**Add quantum compatibility calculation:**

```dart
// Add import
import 'package:spots/core/ai/quantum/quantum_vibe_state.dart';

/// Quantum-based compatibility calculation
double calculateVibeCompatibilityQuantum(UserVibe other) {
  if (isExpired || other.isExpired) return 0.0;

  // Convert dimensions to quantum states
  final myQuantumStates = <String, QuantumVibeState>{};
  final otherQuantumStates = <String, QuantumVibeState>{};

  for (final dimension in VibeConstants.coreDimensions) {
    final myValue = anonymizedDimensions[dimension] ?? 0.5;
    final otherValue = other.anonymizedDimensions[dimension] ?? 0.5;
    myQuantumStates[dimension] = QuantumVibeState.fromClassical(myValue);
    otherQuantumStates[dimension] = QuantumVibeState.fromClassical(otherValue);
  }

  // Calculate quantum overlap (inner product)
  var totalOverlap = 0.0;
  int validDimensions = 0;

  for (final dimension in VibeConstants.coreDimensions) {
    final myState = myQuantumStates[dimension]!;
    final otherState = otherQuantumStates[dimension]!;
    final overlap = myState.real * otherState.real +
                   myState.imaginary * otherState.imaginary;
    final compatibilityProb = overlap * overlap;
    totalOverlap += compatibilityProb;
    validDimensions++;
  }

  if (validDimensions == 0) return 0.0;
  final dimensionCompatibility = totalOverlap / validDimensions;

  // Quantum entanglement between energy and exploration
  final energyState1 = QuantumVibeState.fromClassical(overallEnergy);
  final energyState2 = QuantumVibeState.fromClassical(other.overallEnergy);
  final energyOverlap = (energyState1.real * energyState2.real +
                         energyState1.imaginary * energyState2.imaginary).abs();

  final explorationState1 = QuantumVibeState.fromClassical(explorationTendency);
  final explorationState2 = QuantumVibeState.fromClassical(other.explorationTendency);
  final explorationOverlap = (explorationState1.real * explorationState2.real +
                              explorationState1.imaginary * explorationState2.imaginary).abs();

  // Quantum superposition of compatibility aspects
  final finalCompatibility = QuantumVibeState.fromClassical(dimensionCompatibility)
      .superpose(QuantumVibeState.fromClassical(energyOverlap), 0.6)
      .superpose(QuantumVibeState.fromClassical(explorationOverlap), 0.7);

  return finalCompatibility.collapse().clamp(0.0, 1.0);
}

// Update existing method to optionally use quantum
double calculateVibeCompatibility(UserVibe other, {bool useQuantum = false}) {
  if (useQuantum) {
    return calculateVibeCompatibilityQuantum(other);
  }
  // Existing classical implementation
}
```

**Dependencies:** `QuantumVibeState`

---

### **Phase 5: Dependency Injection & Constants** (0.5-1 hour)

**Goal:** Register all services and add constants

#### **Step 5.1: Register Services**
**File:** `lib/injection_container.dart`

**Add:**
```dart
// Agent ID Service (required for userId → agentId conversion)
import 'package:spots/core/services/agent_id_service.dart';
sl.registerLazySingleton<AgentIdService>(
  () => AgentIdService(),
);

// Onboarding data service (uses AgentIdService internally)
import 'package:spots/core/services/onboarding_data_service.dart';
sl.registerLazySingleton<OnboardingDataService>(
  () => OnboardingDataService(
    agentIdService: sl<AgentIdService>(), // ✅ Inject AgentIdService
  ),
);

// Social media vibe analyzer
import 'package:spots/core/services/social_media_vibe_analyzer.dart';
sl.registerLazySingleton<SocialMediaVibeAnalyzer>(
  () => SocialMediaVibeAnalyzer(),
);

// Onboarding place list generator
import 'package:spots/core/services/onboarding_place_list_generator.dart';
sl.registerLazySingleton<OnboardingPlaceListGenerator>(
  () => OnboardingPlaceListGenerator(
    placesDataSource: sl<GooglePlacesDataSource>(),
    apiKey: sl<String>(instanceName: 'googlePlacesApiKey'), // TODO: Add to config
  ),
);

// Onboarding recommendation service (uses AgentIdService internally)
import 'package:spots/core/services/onboarding_recommendation_service.dart';
sl.registerLazySingleton<OnboardingRecommendationService>(
  () => OnboardingRecommendationService(
    agentIdService: sl<AgentIdService>(), // ✅ Inject AgentIdService
  ),
);

// Quantum vibe engine
import 'package:spots/core/ai/quantum/quantum_vibe_engine.dart';
sl.registerLazySingleton<QuantumVibeEngine>(
  () => QuantumVibeEngine(),
);
```

---

#### **Step 5.2: Add Quantum Constants**
**File:** `lib/core/constants/vibe_constants.dart`

**Add:**
```dart
// Quantum vibe analysis constants
static const bool enableQuantumVibeAnalysis = true;
static const double quantumTunnelingBarrierWidth = 0.5;
static const double quantumDecoherenceRate = 0.1;
static const double quantumEntanglementCorrelation = 0.8;

// Social media platform weights for quantum superposition
static const Map<String, double> socialMediaPlatformWeights = {
  'instagram': 0.4,
  'facebook': 0.3,
  'twitter': 0.3,
  'linkedin': 0.2,
  'tiktok': 0.2,
};
```

---

## 📊 **IMPLEMENTATION CHECKLIST**

### **Phase 1: Foundation** (4-5 hours)
- [ ] Create `OnboardingData` model (uses `agentId` ✅)
- [ ] Create `OnboardingDataService` (converts `userId → agentId` ✅)
- [ ] Create `SocialMediaVibeAnalyzer` (with Google support)
- [ ] Create `OnboardingPlaceListGenerator` (NEW)
- [ ] Create `OnboardingRecommendationService` (NEW)
- [ ] Register `AgentIdService` in dependency injection ✅
- [ ] Add unit tests for models (including agentId format validation)
- [ ] Add unit tests for services (including userId → agentId conversion)

### **Phase 2: Agent Initialization** (2-3 hours)
- [ ] Add `_mapOnboardingToDimensions()` method
- [ ] Add `initializePersonalityFromOnboarding()` method (converts `userId → agentId` ✅)
- [ ] Add `_determineArchetypeFromDimensions()` helper
- [ ] Add `_calculateInitialAuthenticity()` helper
- [ ] Integrate `AgentIdService` for userId → agentId conversion ✅
- [ ] Add unit tests for mapping
- [ ] Add unit tests for initialization (including agentId conversion)

### **Phase 3: Onboarding Flow** (3-4 hours)
- [ ] Update `OnboardingPage` to save data
- [ ] Update `OnboardingPage` to track social media (including Google)
- [ ] Update `AILoadingPage` to load onboarding data
- [ ] Update `AILoadingPage` to collect social media (including Google)
- [ ] Update `AILoadingPage` to generate place lists from Google Maps (NEW)
- [ ] Update `AILoadingPage` to get recommendations (NEW)
- [ ] Update `AILoadingPage` to use new initialization method
- [ ] Add integration tests

### **Phase 4: Quantum Engine** (2-3 hours)
- [ ] Create `QuantumVibeState` class
- [ ] Create `QuantumVibeDimension` class
- [ ] Create `QuantumVibeEngine` class
- [ ] Integrate quantum engine into agent initialization
- [ ] Update `UserVibeAnalyzer` to use quantum engine
- [ ] Update `UserVibe` for quantum compatibility
- [ ] Add unit tests for quantum math
- [ ] Add integration tests

### **Phase 5: Dependency Injection** (0.5-1 hour)
- [ ] Register `AgentIdService` (✅ NEW - required for all services)
- [ ] Register `OnboardingDataService` (with `AgentIdService` dependency ✅)
- [ ] Register `SocialMediaVibeAnalyzer`
- [ ] Register `OnboardingPlaceListGenerator` (NEW)
- [ ] Register `OnboardingRecommendationService` (NEW)
- [ ] Register `QuantumVibeEngine`
- [ ] Add quantum constants
- [ ] Verify all services are accessible
- [ ] Verify userId → agentId conversion works in all services

---

## 🔄 **COMPLETE INTEGRATED FLOW**

```
┌─────────────────────────────────────────────────────────────┐
│                    ONBOARDING PHASE                         │
│                                                             │
│  OnboardingPage                                             │
│  ├─ Collects: age, homebase, favorite places, preferences │
│  ├─ Tracks: social media connections                       │
│  └─ Saves: OnboardingDataService                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ OnboardingData persisted
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    AGENT INITIALIZATION                      │
│                                                             │
│  AILoadingPage                                              │
│  ├─ Loads: OnboardingData from service                     │
│  ├─ Collects: Social media profiles, follows, connections │
│  └─ Calls: initializePersonalityFromOnboarding()          │
│                                                             │
│  PersonalityLearning                                        │
│  ├─ Maps: OnboardingData → dimension values                │
│  ├─ Analyzes: SocialMediaVibeAnalyzer → insights          │
│  ├─ Calculates: QuantumVibeEngine → final dimensions       │
│  └─ Creates: PersonalityProfile with personalized dims     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Personalized PersonalityProfile
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    VIBE ANALYSIS                            │
│                                                             │
│  UserVibeAnalyzer                                          │
│  ├─ Compiles: Personality + Behavioral + Social + etc.     │
│  ├─ Uses: QuantumVibeEngine for calculations               │
│  ├─ Integrates: Social media profiles (quantum superposition)│
│  ├─ Produces: 12 dimension scores (0.0-1.0)               │
│  └─ Generates: UserVibe for matching                       │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ UserVibe with accurate dimensions
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    MATCHING & RECOMMENDATIONS               │
│                                                             │
│  ├─ User-to-User Matching (quantum compatibility)          │
│  ├─ Spot Recommendations                                   │
│  ├─ List Generation                                        │
│  └─ AI2AI Connections                                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧪 **TESTING STRATEGY**

**Focus:** Business logic only - No UI/widget tests

### **Test Organization Structure**

Following clean architecture and feature-based organization:

```
test/unit/
├── models/
│   └── onboarding_data_test.dart
├── services/
│   ├── onboarding_data_service_test.dart
│   ├── social_media_vibe_analyzer_test.dart
│   ├── onboarding_place_list_generator_test.dart
│   ├── onboarding_recommendation_service_test.dart
│   └── quantum_vibe_engine_test.dart
├── ai/
│   ├── personality_learning_test.dart
│   └── quantum/
│       ├── quantum_vibe_state_test.dart
│       └── quantum_vibe_dimension_test.dart
└── integration/
    └── agent_creation_pipeline_test.dart
```

### **Unit Tests - Business Logic Only**

#### **1. Model Tests** (`test/unit/models/`)

**File:** `test/unit/models/onboarding_data_test.dart`

**Test Structure:**
```dart
void main() {
  group('OnboardingData', () {
    group('JSON Serialization', () {
      test('toJson returns valid JSON structure', () {
        // Test JSON serialization
      });
      
      test('fromJson creates valid OnboardingData instance', () {
        // Test JSON deserialization
      });
      
      test('fromJson handles null values correctly', () {
        // Test null handling
      });
    });
    
    group('Validation', () {
      test('isValid returns true for valid data', () {
        // Test validation logic
      });
      
      test('isValid returns false for invalid data', () {
        // Test invalid cases
      });
    });
  });
}
```

**Test Cases:**
- JSON serialization/deserialization
- Validation logic
- Edge cases (null values, empty lists)
- Data integrity

---

#### **2. Service Tests** (`test/unit/services/`)

**File:** `test/unit/services/onboarding_data_service_test.dart`

**Test Structure:**
```dart
void main() {
  group('OnboardingDataService', () {
    late OnboardingDataService service;
    late Database testDb;
    
    setUp(() async {
      SembastDatabase.useInMemoryForTests();
      testDb = await SembastDatabase.database;
      service = OnboardingDataService();
    });
    
    tearDown(() async {
      await SembastDatabase.resetForTests();
    });
    
    group('saveOnboardingData', () {
      test('saves onboarding data successfully', () async {
        // Test save operation
      });
      
      test('overwrites existing data when saving again', () async {
        // Test update behavior
      });
      
      test('handles database errors gracefully', () async {
        // Test error handling
      });
    });
    
    group('getOnboardingData', () {
      test('retrieves saved onboarding data', () async {
        // Test retrieval
      });
      
      test('returns null when data does not exist', () async {
        // Test missing data
      });
    });
    
    group('deleteOnboardingData', () {
      test('deletes onboarding data successfully', () async {
        // Test deletion
      });
    });
  });
}
```

**Test Cases:**
- Save/retrieve/delete operations
- Error handling (database failures)
- Concurrent access handling
- Data persistence across operations

---

**File:** `test/unit/services/social_media_vibe_analyzer_test.dart`

**Test Structure:**
```dart
void main() {
  group('SocialMediaVibeAnalyzer', () {
    late SocialMediaVibeAnalyzer analyzer;
    
    setUp(() {
      analyzer = SocialMediaVibeAnalyzer();
    });
    
    group('analyzeProfileForVibe', () {
      test('analyzes Instagram profile correctly', () async {
        // Test Instagram analysis
      });
      
      test('analyzes Facebook profile correctly', () async {
        // Test Facebook analysis
      });
      
      test('analyzes Google profile correctly', () async {
        // Test Google analysis (NEW)
      });
      
      test('handles empty profile data', () async {
        // Test edge case
      });
      
      test('extracts interests from profile', () async {
        // Test interest extraction
      });
      
      test('maps interests to dimensions correctly', () async {
        // Test dimension mapping
      });
    });
    
    group('analyzeGoogleProfileForVibe', () {
      test('analyzes Google saved places for location preferences', () async {
        // Test saved places analysis (NEW)
      });
      
      test('analyzes Google reviews for authenticity preferences', () async {
        // Test reviews analysis (NEW)
      });
      
      test('analyzes Google photos for exploration patterns', () async {
        // Test photos analysis (NEW)
      });
      
      test('handles empty Google data', () async {
        // Test edge case (NEW)
      });
    });
    
    group('analyzeFollows', () {
      test('analyzes follows list for personality insights', () async {
        // Test follows analysis
      });
      
      test('handles empty follows list', () async {
        // Test edge case
      });
    });
    
    group('analyzeConnections', () {
      test('analyzes connections for social patterns', () async {
        // Test connections analysis
      });
    });
  });
}
```

**Test Cases:**
- Profile analysis for each platform (including Google)
- Google saved places analysis (NEW)
- Google reviews analysis (NEW)
- Google photos analysis (NEW)
- Follows analysis
- Connections analysis
- Interest extraction
- Dimension mapping
- Edge cases (empty data, missing fields)

---

**File:** `test/unit/services/onboarding_place_list_generator_test.dart`

**Test Structure:**
```dart
void main() {
  group('OnboardingPlaceListGenerator', () {
    late OnboardingPlaceListGenerator generator;
    late MockGooglePlacesDataSource mockPlacesDataSource;
    
    setUp(() {
      mockPlacesDataSource = MockGooglePlacesDataSource();
      generator = OnboardingPlaceListGenerator(
        placesDataSource: mockPlacesDataSource,
        apiKey: 'test_api_key',
      );
    });
    
    group('generatePlaceLists', () {
      test('generates lists based on onboarding preferences', () async {
        // Test list generation from preferences
      });
      
      test('generates lists based on homebase location', () async {
        // Test location-based generation
      });
      
      test('generates multiple lists for different categories', () async {
        // Test multi-list generation
      });
      
      test('handles missing preferences gracefully', () async {
        // Test edge case
      });
    });
    
    group('generateListForCategory', () {
      test('generates list for food category', () async {
        // Test category-specific generation
      });
      
      test('filters and ranks places by relevance', () async {
        // Test ranking logic
      });
    });
    
    group('searchPlacesForCategory', () {
      test('searches places using Google Maps API', () async {
        // Test API integration
      });
      
      test('handles API errors gracefully', () async {
        // Test error handling
      });
    });
  });
}
```

**Test Cases:**
- List generation from onboarding data
- Category-based list generation
- Place search and filtering
- Relevance scoring
- Edge cases (no preferences, invalid location)

---

**File:** `test/unit/services/onboarding_recommendation_service_test.dart`

**Test Structure:**
```dart
void main() {
  group('OnboardingRecommendationService', () {
    late OnboardingRecommendationService service;
    
    setUp(() {
      service = OnboardingRecommendationService();
    });
    
    group('getRecommendedLists', () {
      test('recommends lists based on preferences', () async {
        // Test preference-based recommendations
      });
      
      test('recommends lists based on homebase', () async {
        // Test location-based recommendations
      });
      
      test('recommends lists based on archetype', () async {
        // Test archetype-based recommendations
      });
      
      test('calculates compatibility scores correctly', () async {
        // Test compatibility calculation
      });
      
      test('returns empty list when no matches found', () async {
        // Test edge case
      });
    });
    
    group('getRecommendedAccounts', () {
      test('recommends accounts based on interests', () async {
        // Test interest-based recommendations
      });
      
      test('recommends accounts based on location', () async {
        // Test location-based recommendations
      });
      
      test('calculates compatibility scores correctly', () async {
        // Test compatibility calculation
      });
    });
    
    group('calculateCompatibility', () {
      test('calculates high compatibility for matching dimensions', () {
        // Test compatibility logic
      });
      
      test('calculates low compatibility for mismatched dimensions', () {
        // Test mismatch handling
      });
    });
  });
}
```

**Test Cases:**
- List recommendations based on preferences
- List recommendations based on homebase
- List recommendations based on archetype
- Account recommendations based on interests
- Account recommendations based on location
- Compatibility score calculation
- Edge cases (no matches, empty onboarding data)

---

**File:** `test/unit/services/quantum_vibe_engine_test.dart`

**Test Structure:**
```dart
void main() {
  group('QuantumVibeEngine', () {
    late QuantumVibeEngine engine;
    
    setUp(() {
      engine = QuantumVibeEngine();
    });
    
    group('compileVibeDimensionsQuantum', () {
      test('compiles all 12 dimensions correctly', () async {
        // Test dimension compilation
      });
      
      test('handles missing insight data gracefully', () async {
        // Test error handling
      });
      
      test('integrates social media profiles correctly', () async {
        // Test social media integration
      });
    });
    
    group('quantumSuperpose', () {
      test('superposes multiple states correctly', () {
        // Test superposition
      });
      
      test('maintains probability conservation', () {
        // Test probability conservation
      });
    });
    
    group('quantumInterfere', () {
      test('constructive interference increases probability', () {
        // Test constructive interference
      });
      
      test('destructive interference decreases probability', () {
        // Test destructive interference
      });
    });
    
    group('quantumEntangle', () {
      test('entangles correlated dimensions', () {
        // Test entanglement
      });
    });
    
    group('quantumTunneling', () {
      test('calculates tunneling probability correctly', () {
        // Test tunneling
      });
    });
    
    group('quantumDecoherence', () {
      test('applies decoherence correctly', () {
        // Test decoherence
      });
    });
  });
}
```

**Test Cases:**
- Quantum compilation for all dimensions
- Superposition with multiple states
- Interference patterns (constructive/destructive)
- Entangled network creation
- Tunneling probability calculation
- Decoherence application
- Temporal phase shifts
- Confidence calculations
- Edge cases (empty states, zero weights)

---

#### **3. AI/Personality Learning Tests** (`test/unit/ai/`)

**File:** `test/unit/ai/personality_learning_test.dart`

**Test Structure:**
```dart
void main() {
  group('PersonalityLearning', () {
    late PersonalityLearning personalityLearning;
    
    setUp(() {
      SembastDatabase.useInMemoryForTests();
      personalityLearning = PersonalityLearning();
    });
    
    tearDown(() async {
      await SembastDatabase.resetForTests();
    });
    
    group('_mapOnboardingToDimensions', () {
      test('maps age to dimension adjustments correctly', () {
        // Test age mapping
      });
      
      test('maps homebase to location dimensions', () {
        // Test homebase mapping
      });
      
      test('maps favorite places to exploration dimensions', () {
        // Test favorite places mapping
      });
      
      test('maps preferences to various dimensions', () {
        // Test preferences mapping
      });
      
      test('maps friends to community dimensions', () {
        // Test friends mapping
      });
      
      test('clamps all values to valid range (0.0-1.0)', () {
        // Test value clamping
      });
    });
    
    group('initializePersonalityFromOnboarding', () {
      test('initializes with onboarding data only', () async {
        // Test onboarding-only initialization
      });
      
      test('initializes with social media data only', () async {
        // Test social media-only initialization
      });
      
      test('initializes with both onboarding and social media data', () async {
        // Test combined initialization
      });
      
      test('falls back to default when no data provided', () async {
        // Test fallback behavior
      });
      
      test('does not overwrite existing evolved profile', () async {
        // Test existing profile handling
      });
      
      test('creates profile with non-default dimensions', () async {
        // Test dimension accuracy
      });
      
      test('determines archetype correctly from dimensions', () async {
        // Test archetype determination
      });
      
      test('calculates authenticity correctly', () async {
        // Test authenticity calculation
      });
      
      test('handles errors gracefully', () async {
        // Test error handling
      });
    });
    
    group('_determineArchetypeFromDimensions', () {
      test('returns adventurous_explorer for high exploration and energy', () {
        // Test archetype logic
      });
      
      test('returns social_connector for high social and energy', () {
        // Test archetype logic
      });
      
      test('returns balanced_explorer as default', () {
        // Test default archetype
      });
    });
  });
}
```

**Test Cases:**
- Onboarding-to-dimensions mapping
- Initialization with various data combinations
- Archetype determination
- Authenticity calculation
- Error handling
- Edge cases

---

#### **4. Quantum Math Tests** (`test/unit/ai/quantum/`)

**File:** `test/unit/ai/quantum/quantum_vibe_state_test.dart`

**Test Structure:**
```dart
void main() {
  group('QuantumVibeState', () {
    group('Probability Calculation', () {
      test('calculates probability correctly from amplitude', () {
        // Test |amplitude|² calculation
      });
      
      test('probability is always between 0.0 and 1.0', () {
        // Test probability bounds
      });
    });
    
    group('Superposition', () {
      test('superposes two states correctly', () {
        // Test superposition
      });
      
      test('maintains probability conservation in superposition', () {
        // Test conservation
      });
    });
    
    group('Interference', () {
      test('constructive interference increases probability', () {
        // Test constructive interference
      });
      
      test('destructive interference decreases probability', () {
        // Test destructive interference
      });
    });
    
    group('Entanglement', () {
      test('entangles states with correlation', () {
        // Test entanglement
      });
    });
    
    group('Collapse', () {
      test('collapses to classical probability correctly', () {
        // Test measurement/collapse
      });
    });
  });
}
```

**Test Cases:**
- Probability calculation from amplitude
- Superposition of two states
- Constructive interference
- Destructive interference
- Entanglement correlation
- Collapse to classical probability
- Phase calculations

---

**File:** `test/unit/ai/quantum/quantum_vibe_dimension_test.dart`

**Test Structure:**
```dart
void main() {
  group('QuantumVibeDimension', () {
    group('Measurement', () {
      test('measure() collapses to classical value', () {
        // Test measurement
      });
      
      test('probability getter returns without collapsing', () {
        // Test probability access
      });
    });
  });
}
```

---

### **Integration Tests - Business Logic Flows** (`test/integration/`)

**File:** `test/integration/agent_creation_pipeline_test.dart`

**Test Structure:**
```dart
void main() {
  group('Agent Creation Pipeline Integration', () {
    late OnboardingDataService onboardingService;
    late PersonalityLearning personalityLearning;
    late SocialMediaVibeAnalyzer socialMediaAnalyzer;
    
    setUp(() async {
      SembastDatabase.useInMemoryForTests();
      onboardingService = OnboardingDataService();
      personalityLearning = PersonalityLearning();
      socialMediaAnalyzer = SocialMediaVibeAnalyzer();
    });
    
    tearDown(() async {
      await SembastDatabase.resetForTests();
    });
    
    group('End-to-End Agent Initialization', () {
      test('complete flow: onboarding → agent initialization → dimensions', () async {
        // 1. Save onboarding data
        // 2. Initialize agent with onboarding data
        // 3. Verify dimensions are non-default
        // 4. Verify archetype is accurate
      });
      
      test('complete flow with social media integration', () async {
        // 1. Save onboarding data
        // 2. Provide social media data
        // 3. Initialize agent with both
        // 4. Verify dimensions reflect both sources
      });
      
      test('quantum engine integration produces accurate dimensions', () async {
        // 1. Initialize agent
        // 2. Compile vibe with quantum engine
        // 3. Verify quantum calculations
        // 4. Compare with classical (if needed)
      });
    });
    
    group('Data Flow Validation', () {
      test('onboarding data persists and retrieves correctly', () async {
        // Test persistence
      });
      
      test('agent dimensions reflect onboarding choices', () async {
        // Test dimension accuracy
      });
      
      test('social media insights integrate correctly', () async {
        // Test social media integration
      });
    });
  });
}
```

**Test Cases:**
- End-to-end onboarding → agent initialization
- Social media integration flow
- Quantum vibe analysis integration
- Data persistence validation
- Dimension accuracy validation

---

### **Test Quality Standards**

Following SPOTS testing standards:

1. **Performance Targets**
   - Unit tests: <5ms average execution time
   - Integration tests: <2000ms average execution time

2. **Naming Conventions**
   ```dart
   // ✅ GOOD: Descriptive, behavior-focused
   test('maps age to dimension adjustments correctly', () {});
   test('initializes with onboarding data only', () async {});
   
   // ❌ BAD: Vague, implementation-focused
   test('test mapping', () {});
   test('test init', () {});
   ```

3. **Test Organization**
   - Group related tests using `group()`
   - Use descriptive test names
   - One assertion per test (when possible)
   - Clear setup/teardown

4. **Mock Strategy**
   - Mock external dependencies (database, services)
   - Use real implementations for business logic
   - Isolate units under test

5. **Coverage Goals**
   - >90% line coverage for business logic
   - >85% branch coverage
   - 100% coverage for critical paths

---

### **Test Execution**

**Run all business logic tests:**
```bash
flutter test test/unit/
```

**Run specific test groups:**
```bash
flutter test test/unit/services/onboarding_data_service_test.dart
flutter test test/unit/ai/personality_learning_test.dart
flutter test test/unit/ai/quantum/
```

**Run integration tests:**
```bash
flutter test test/integration/agent_creation_pipeline_test.dart
```

---

## 📅 **ESTIMATED TIMELINE**

- **Phase 1 (Foundation)**: 4-5 hours (added Google support, place lists, recommendations)
- **Phase 2 (Agent Initialization)**: 2-3 hours
- **Phase 3 (Onboarding Flow)**: 3-4 hours (added place list generation, recommendations)
- **Phase 4 (Quantum Engine)**: 2-3 hours
- **Phase 5 (Dependency Injection)**: 0.5-1 hour

**Total**: ~12-16 hours

---

## 🎯 **SUCCESS CRITERIA**

After implementation, verify:

- [ ] Onboarding data is persisted to storage
- [ ] Onboarding data can be retrieved
- [ ] Agent initialization accepts onboarding data
- [ ] Agent initialization accepts social media data
- [ ] Onboarding data maps to dimension values correctly
- [ ] Social media data maps to dimension values correctly
- [ ] Initial personality profile has non-default values
- [ ] Initial dimensions reflect user's onboarding choices
- [ ] Initial dimensions reflect social media insights
- [ ] Agent archetype is accurate (not "developing")
- [ ] Quantum vibe analysis produces accurate results
- [ ] Quantum calculations show improvements over classical
- [ ] Social media profiles are superposed correctly
- [ ] Matching works correctly with personalized agent
- [ ] All tests pass
- [ ] No linter errors

---

## 🔗 **DEPENDENCIES**

### **Internal Dependencies**
- `lib/data/datasources/local/sembast_database.dart`
- `lib/core/ai/personality_learning.dart`
- `lib/core/ai/vibe_analysis_engine.dart`
- `lib/core/constants/vibe_constants.dart`
- `lib/core/models/personality_profile.dart`
- `lib/core/models/user_vibe.dart`
- `lib/injection_container.dart`

### **External Dependencies**
- `sembast` (database)
- `dart:math` (for quantum calculations)
- No new external packages required

---

## 🚨 **CRITICAL NOTES**

### **Backward Compatibility**
- Existing users without onboarding data should still work
- Fallback to default initialization if data missing
- Don't break existing agent initialization

### **Error Handling**
- All operations should handle errors gracefully
- Log errors but don't block agent creation
- Fallback to default initialization on errors

### **Performance**
- Onboarding data loading should be fast (< 100ms)
- Social media data collection should be async
- Quantum calculations should complete in < 100ms
- Don't block UI during data collection

### **Privacy**
- Onboarding data stored locally only
- Social media data analyzed on-device
- No raw social media data in agent profile
- Only derived insights used

---

## 📝 **IMPLEMENTATION ORDER**

1. **Start with Phase 1**: Create data models and services (foundation)
2. **Then Phase 2**: Add personality learning extensions (core logic)
3. **Then Phase 3**: Update onboarding flow (integration)
4. **Then Phase 4**: Implement quantum engine (enhancement)
5. **Finally Phase 5**: Register services (dependency injection)

**Note:** Phases 1-3 can be done in parallel with Phase 4, but Phase 4 should be completed before integrating quantum into agent initialization.

---

## 📚 **RELATED DOCUMENTS**

This master plan integrates:
- `QUANTUM_VIBE_ANALYSIS_IMPLEMENTATION_PLAN.md` - Quantum implementation details
- `QUANTUM_VIBE_MATHEMATICS_EXPLANATION.md` - Quantum math explanation
- `QUANTUM_VIBE_CALCULATIONS_EXPLAINED.md` - What quantum calculates
- `AGENT_CREATION_GAP_ANALYSIS.md` - Gap analysis
- `FIX_AGENT_CREATION_PIPELINE_PLAN.md` - Original fix plan

---

## 🔐 **AGENT ID INTEGRATION SUMMARY**

### **What Changed (December 15, 2025 Update)**

1. **OnboardingData Model**: Now uses `agentId` instead of `userId` for privacy protection
2. **OnboardingDataService**: Converts `userId → agentId` internally, stores using agentId
3. **PersonalityLearning**: Accepts `userId` from UI, converts to `agentId` internally
4. **Social Media Integration**: Uses `agentId` (aligns with Phase 12)
5. **OnboardingRecommendationService**: Converts `userId → agentId` internally
6. **All Services**: Accept `userId` in public API, convert to `agentId` for internal operations

### **Why This Matters**

- ✅ **Privacy Protection**: agentId cannot be reverse-engineered to userId
- ✅ **AI2AI Network**: All AI2AI communication uses agentId (anonymous)
- ✅ **Master Plan Compliance**: Follows Phase 7.3 Security Implementation requirements
- ✅ **Future-Proof**: Ready for PersonalityProfile migration to agentId (Phase 7.3)

### **Implementation Pattern**

```
UI Layer (userId from auth)
    ↓
Service Layer (AgentIdService.getUserAgentId(userId))
    ↓
Storage/Network (agentId - privacy-protected)
```

### **Testing Requirements**

- ✅ Test userId → agentId conversion in all services
- ✅ Verify agentId format validation
- ✅ Test storage/retrieval using agentId
- ✅ Verify no userId leaks in AI2AI network operations

---

**Last Updated:** December 15, 2025 (agentId integration)  
**Status:** Master plan ready for implementation

