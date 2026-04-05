# Fix Agent Creation Pipeline - Implementation Plan

**Date:** December 12, 2025  
**Status:** 📋 **PLANNING**  
**Purpose:** Comprehensive plan to fix all gaps in onboarding → agent creation → vibe analysis pipeline

---

## 🎯 **OVERVIEW**

This plan addresses all critical gaps identified in the agent creation process, ensuring that:
1. Onboarding data is persisted and used for agent initialization
2. Social media data is collected and analyzed
3. Agent is created with personalized dimensions (not defaults)
4. Quantum vibe analysis informs initial agent creation
5. All data flows properly through the pipeline

---

## 📋 **GAPS TO FIX**

### **Critical Gaps**
1. ❌ Onboarding data not used for agent initialization
2. ❌ Social media data not collected during onboarding
3. ❌ No method to initialize with onboarding data
4. ❌ Onboarding data not persisted
5. ❌ Quantum vibe analysis separate from agent creation

### **High Priority Gaps**
6. ❌ No OnboardingDataService
7. ❌ No SocialMediaVibeAnalyzer
8. ❌ No mapping from onboarding to dimensions

---

## 🔧 **IMPLEMENTATION PLAN**

### **Phase 1: Data Models and Services**

#### **Step 1.1: Create OnboardingData Model**
**File:** `lib/core/models/onboarding_data.dart`

**Purpose:** Structured representation of all onboarding data

**Implementation:**
```dart
class OnboardingData {
  final String userId;
  final int? age;
  final DateTime? birthday;
  final String? homebase;
  final List<String> favoritePlaces;
  final Map<String, List<String>> preferences;
  final List<String> baselineLists;
  final List<String> respectedFriends;
  final Map<String, bool> socialMediaConnected; // Platform -> connected status
  final DateTime completedAt;
  
  // JSON serialization
  Map<String, dynamic> toJson();
  factory OnboardingData.fromJson(Map<String, dynamic> json);
  
  // Validation
  bool get isValid;
}
```

**Dependencies:**
- None (standalone model)

**Tests:**
- JSON serialization/deserialization
- Validation logic
- Edge cases (null values, empty lists)

---

#### **Step 1.2: Create OnboardingDataService**
**File:** `lib/core/services/onboarding_data_service.dart`

**Purpose:** Persist and retrieve onboarding data

**Implementation:**
```dart
class OnboardingDataService {
  static const String _logName = 'OnboardingDataService';
  static const String _dataKeyPrefix = 'onboarding_data_';
  
  /// Save onboarding data for a user
  Future<void> saveOnboardingData(String userId, OnboardingData data);
  
  /// Get onboarding data for a user
  Future<OnboardingData?> getOnboardingData(String userId);
  
  /// Delete onboarding data for a user
  Future<void> deleteOnboardingData(String userId);
  
  /// Check if onboarding data exists
  Future<bool> hasOnboardingData(String userId);
}
```

**Storage:**
- Use Sembast database (similar to OnboardingCompletionService)
- Store in `onboardingStore` or create new `onboardingDataStore`
- Key format: `onboarding_data_{userId}`

**Dependencies:**
- `lib/data/datasources/local/sembast_database.dart`
- `lib/core/models/onboarding_data.dart`

**Tests:**
- Save/retrieve operations
- Delete operations
- Error handling (database failures)
- Concurrent access handling

---

#### **Step 1.3: Create SocialMediaVibeAnalyzer**
**File:** `lib/core/services/social_media_vibe_analyzer.dart`

**Purpose:** Analyze social media profiles for personality insights

**Implementation:**
```dart
class SocialMediaVibeAnalyzer {
  static const String _logName = 'SocialMediaVibeAnalyzer';
  
  /// Analyze social media profile for initial personality dimensions
  Future<Map<String, double>> analyzeProfileForVibe({
    required Map<String, dynamic> profileData,
    required List<Map<String, dynamic>> follows,
    required List<Map<String, dynamic>> connections,
    required String platform,
  });
  
  // Private helper methods
  Map<String, double> _analyzeProfileContent(...);
  Map<String, double> _analyzeFollows(...);
  Map<String, double> _analyzeConnections(...);
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
- Profile analysis
- Follows analysis
- Connections analysis
- Interest extraction
- Dimension mapping
- Edge cases (empty data, missing fields)

---

### **Phase 2: Personality Learning Extensions**

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
  if (homebase != null) {
    // Urban vs rural analysis
    if (_isUrbanArea(homebase)) {
      insights['location_adventurousness'] = 
          (insights['location_adventurousness'] ?? 0.5) + 0.1;
    }
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

/// Check if homebase is urban area
bool _isUrbanArea(String homebase) {
  // Simple heuristic - can be enhanced with location data
  final urbanKeywords = ['city', 'urban', 'metro', 'downtown'];
  return urbanKeywords.any((keyword) => 
      homebase.toLowerCase().contains(keyword));
}
```

**Dependencies:**
- `lib/core/constants/vibe_constants.dart`

**Tests:**
- Age mapping
- Homebase mapping
- Favorite places mapping
- Preferences mapping
- Friends mapping
- Edge cases (null values, empty data)

---

#### **Step 2.2: Add initializePersonalityFromOnboarding() Method**
**File:** `lib/core/ai/personality_learning.dart`

**Purpose:** Initialize personality with onboarding and social media data

**Implementation:**
```dart
/// Initialize personality from onboarding data including social media
Future<PersonalityProfile> initializePersonalityFromOnboarding(
  String userId, {
  Map<String, dynamic>? onboardingData,
  Map<String, dynamic>? socialMediaData,
}) async {
  developer.log(
    'Initializing personality from onboarding for user: $userId',
    name: _logName,
  );

  try {
    // Check if profile already exists
    final existingProfile = await _loadPersonalityProfile(userId);
    if (existingProfile != null && existingProfile.evolutionGeneration > 1) {
      // Profile already evolved, don't overwrite
      developer.log(
        'Profile already exists and evolved, returning existing',
        name: _logName,
      );
      return existingProfile;
    }
    
    // Start with default initial profile
    final baseProfile = PersonalityProfile.initial(userId);
    final initialDimensions = Map<String, double>.from(baseProfile.dimensions);
    final initialConfidence = Map<String, double>.from(baseProfile.dimensionConfidence);
    
    // 1. Apply onboarding data (if provided)
    if (onboardingData != null && onboardingData.isNotEmpty) {
      final onboardingInsights = _mapOnboardingToDimensions(onboardingData);
      
      developer.log(
        'Mapped onboarding data to ${onboardingInsights.length} dimension insights',
        name: _logName,
      );
      
      // Apply insights to dimensions
      onboardingInsights.forEach((dimension, value) {
        final currentValue = initialDimensions[dimension] ?? 0.5;
        // Blend: 60% onboarding, 40% default
        initialDimensions[dimension] = 
            (currentValue * 0.4 + value * 0.6).clamp(0.0, 1.0);
        
        // Set confidence based on having onboarding data
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
        
        developer.log(
          'Analyzed social media: ${socialInsights.length} dimension insights',
          name: _logName,
        );
        
        // Blend social media insights with onboarding data
        // Social media gets 40% weight, existing gets 60%
        socialInsights.forEach((dimension, socialValue) {
          final existingValue = initialDimensions[dimension] ?? 0.5;
          initialDimensions[dimension] = 
              (existingValue * 0.6 + socialValue * 0.4).clamp(0.0, 1.0);
          
          // Boost confidence with social media data
          initialConfidence[dimension] = 
              (initialConfidence[dimension] ?? 0.0) + 0.2;
        });
      } catch (e) {
        developer.log(
          'Error analyzing social media: $e',
          name: _logName,
        );
        // Continue without social media data
      }
    }
    
    // 3. Use quantum engine for final dimension calculation (if available)
    // This will be added in Phase 3 when quantum engine is implemented
    // For now, use the calculated dimensions directly
    
    // 4. Determine archetype from dimensions
    final archetype = _determineArchetypeFromDimensions(initialDimensions);
    
    // 5. Calculate initial authenticity
    final authenticity = _calculateInitialAuthenticity(
      initialDimensions,
      onboardingData,
    );
    
    // 6. Create profile with initial dimensions from onboarding + social media
    final newProfile = PersonalityProfile(
      userId: userId,
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
      },
    );
    
    await _savePersonalityProfile(newProfile);
    _currentProfile = newProfile;
    
    developer.log(
      'Created personality profile from onboarding (generation ${newProfile.evolutionGeneration})',
      name: _logName,
    );
    developer.log(
      'Archetype: ${newProfile.archetype}, Authenticity: ${newProfile.authenticity}',
      name: _logName,
    );
    
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
  
  // Boost authenticity if user selected authentic preferences
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
- `lib/core/services/social_media_vibe_analyzer.dart`
- `lib/core/models/onboarding_data.dart`
- `_mapOnboardingToDimensions()` method

**Tests:**
- Initialize with onboarding data only
- Initialize with social media data only
- Initialize with both
- Initialize with neither (fallback)
- Existing profile handling
- Error handling

---

### **Phase 3: Update Onboarding Flow**

#### **Step 3.1: Update OnboardingPage to Save Data**
**File:** `lib/presentation/pages/onboarding/onboarding_page.dart`

**Changes:**
1. Import OnboardingDataService
2. Save onboarding data before navigation
3. Track social media connection status

**Implementation:**
```dart
// Add import
import 'package:spots/core/services/onboarding_data_service.dart';
import 'package:spots/core/models/onboarding_data.dart';

// Add state variable for social media
Map<String, bool> _connectedSocialPlatforms = {};

// Update SocialMediaConnectionPage callback
case OnboardingStepType.socialMedia:
  return SocialMediaConnectionPage(
    onConnectionsChanged: (connectedPlatforms) {
      setState(() {
        _connectedSocialPlatforms = connectedPlatforms;
      });
    },
    initialConnections: _connectedSocialPlatforms,
  );

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
    
    // NEW: Save onboarding data
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      final onboardingData = OnboardingData(
        userId: userId,
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
        await onboardingService.saveOnboardingData(userId, onboardingData);
        _logger.info('✅ Saved onboarding data for user: $userId', tag: 'Onboarding');
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
      'socialMediaConnected': _connectedSocialPlatforms, // NEW
    });
  } catch (e) {
    // ... error handling ...
  }
}
```

**Dependencies:**
- `lib/core/services/onboarding_data_service.dart`
- `lib/core/models/onboarding_data.dart`

**Tests:**
- Data saving on completion
- Error handling if save fails
- Social media status tracking

---

#### **Step 3.2: Update AILoadingPage to Use Onboarding Data**
**File:** `lib/presentation/pages/onboarding/ai_loading_page.dart`

**Changes:**
1. Load onboarding data from service (or use router extra)
2. Collect social media data if connected
3. Call `initializePersonalityFromOnboarding()` instead of `initializePersonality()`

**Implementation:**
```dart
// Add imports
import 'package:spots/core/services/onboarding_data_service.dart';
import 'package:spots/core/services/social_media_connection_service.dart';
import 'package:spots/core/services/social_media_insight_service.dart';
import 'package:spots/core/services/social_media_vibe_analyzer.dart';

// Update _startLoading() method
void _startLoading() async {
  // ... existing list generation code ...
  
  // Initialize personalized agent/personality for user
  try {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;
    if (authState is Authenticated) {
      final userId = authState.user.id;
      _logger.info('🤖 Initializing personalized agent for user: $userId',
          tag: 'AILoadingPage');

      // NEW: Load onboarding data
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
          _logger.info('✅ Loaded onboarding data from storage', tag: 'AILoadingPage');
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
          _logger.info('⚠️ Using onboarding data from router extra', tag: 'AILoadingPage');
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
      
      // NEW: Collect social media data if connected
      Map<String, dynamic>? socialMediaData;
      try {
        final socialMediaService = di.sl<SocialMediaConnectionService>();
        final connections = await socialMediaService.getActiveConnections(userId);
        
        if (connections.isNotEmpty) {
          _logger.info('📱 Found ${connections.length} social media connections', 
              tag: 'AILoadingPage');
          
          // Fetch profile, follows, and connections for each platform
          final allProfileData = <String, dynamic>{};
          final allFollows = <Map<String, dynamic>>[];
          final allConnections = <Map<String, dynamic>>[];
          String? primaryPlatform;
          
          for (final connection in connections) {
            try {
              final profileData = await socialMediaService.fetchProfile(connection.id);
              final follows = await socialMediaService.fetchFollows(connection.id);
              final connections = await socialMediaService.fetchConnections(connection.id);
              
              allProfileData.addAll(profileData);
              allFollows.addAll(follows);
              allConnections.addAll(connections);
              
              if (primaryPlatform == null) {
                primaryPlatform = connection.platform;
              }
            } catch (e) {
              _logger.warn('⚠️ Error fetching data for ${connection.platform}: $e',
                  tag: 'AILoadingPage');
              // Continue with other platforms
            }
          }
          
          if (allProfileData.isNotEmpty || allFollows.isNotEmpty) {
            socialMediaData = {
              'profile': allProfileData,
              'follows': allFollows,
              'connections': allConnections,
              'platform': primaryPlatform ?? 'unknown',
            };
            
            _logger.info(
              '📱 Collected social media data: ${allFollows.length} follows, ${allConnections.length} connections',
              tag: 'AILoadingPage',
            );
          }
        }
      } catch (e) {
        _logger.warn('⚠️ Could not collect social media data: $e',
            tag: 'AILoadingPage');
        // Continue without social media data
      }
      
      // NEW: Initialize with onboarding and social media data
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
      _logger.debug('  Authenticity: ${personalityProfile.authenticity}',
          tag: 'AILoadingPage');
      _logger.debug('  Dimensions: ${personalityProfile.dimensions}',
          tag: 'AILoadingPage');
      
      // ... existing cloud sync code ...
    }
  } catch (e, stackTrace) {
    // ... error handling ...
  }
}
```

**Dependencies:**
- `lib/core/services/onboarding_data_service.dart`
- `lib/core/services/social_media_connection_service.dart`
- `lib/core/services/social_media_insight_service.dart`
- `lib/core/ai/personality_learning.dart` (with new method)

**Tests:**
- Load onboarding data from service
- Fallback to router extra
- Collect social media data
- Initialize with both data sources
- Error handling for missing services

---

### **Phase 4: Dependency Injection**

#### **Step 4.1: Register New Services**
**File:** `lib/injection_container.dart`

**Add:**
```dart
// Onboarding data service
import 'package:spots/core/services/onboarding_data_service.dart';
sl.registerLazySingleton<OnboardingDataService>(
  () => OnboardingDataService(),
);

// Social media vibe analyzer
import 'package:spots/core/services/social_media_vibe_analyzer.dart';
sl.registerLazySingleton<SocialMediaVibeAnalyzer>(
  () => SocialMediaVibeAnalyzer(),
);

// Note: SocialMediaConnectionService and SocialMediaInsightService
// should already be registered if social media integration exists
// If not, add them here
```

**Dependencies:**
- New service files

**Tests:**
- Services are registered
- Services can be retrieved
- Services are singletons

---

### **Phase 5: Database Schema (if needed)**

#### **Step 5.1: Add Onboarding Data Store**
**File:** `lib/data/datasources/local/sembast_database.dart`

**Check if onboardingStore exists, if not:**
```dart
// Add to SembastDatabase class
static final StoreRef<String, Map<String, dynamic>> onboardingDataStore =
    stringMapStoreFactory.store('onboarding_data');
```

**Or use existing onboardingStore:**
```dart
// Use existing onboardingStore with different key prefix
// Key: 'onboarding_data_{userId}' instead of 'onboarding_completed_{userId}'
```

**Dependencies:**
- Sembast database setup

**Tests:**
- Store creation
- Data persistence
- Data retrieval

---

### **Phase 6: Integration with Quantum Engine (Future)**

#### **Step 6.1: Use Quantum Engine for Initial Dimensions**
**File:** `lib/core/ai/personality_learning.dart`

**Update `initializePersonalityFromOnboarding()` to use quantum engine:**

```dart
// After collecting onboarding and social media insights
// Use quantum engine to calculate final dimensions

if (quantumEngineAvailable) {
  final quantumEngine = di.sl<QuantumVibeEngine>();
  
  // Convert insights to quantum-compatible format
  final personalityInsights = PersonalityVibeInsights(
    dominantTraits: _extractDominantTraits(initialDimensions),
    personalityStrength: 0.7, // Moderate strength from onboarding
    evolutionMomentum: 0.3, // Low (just starting)
    authenticityLevel: authenticity,
    confidenceLevel: _calculateAverageConfidence(initialConfidence),
  );
  
  // Create minimal insights for quantum compilation
  final behavioralInsights = BehavioralVibeInsights(
    activityLevel: 0.5, // Unknown initially
    explorationTendency: initialDimensions['exploration_eagerness'] ?? 0.5,
    socialEngagement: initialDimensions['community_orientation'] ?? 0.5,
    spontaneityIndex: initialDimensions['temporal_flexibility'] ?? 0.5,
    consistencyScore: 0.5, // Unknown initially
  );
  
  // ... create other insights ...
  
  // Use quantum engine to compile final dimensions
  final quantumDimensions = await quantumEngine.compileVibeDimensionsQuantum(
    personalityInsights,
    behavioralInsights,
    socialInsights,
    relationshipInsights,
    temporalInsights,
  );
  
  // Blend quantum dimensions with onboarding dimensions
  quantumDimensions.forEach((dimension, quantumValue) {
    final onboardingValue = initialDimensions[dimension] ?? 0.5;
    // 70% quantum, 30% onboarding (quantum refines onboarding)
    initialDimensions[dimension] = 
        (onboardingValue * 0.3 + quantumValue * 0.7).clamp(0.0, 1.0);
  });
}
```

**Note:** This will be implemented after quantum engine is complete (Phase 3 of quantum plan)

---

## 📊 **IMPLEMENTATION CHECKLIST**

### **Phase 1: Data Models and Services**
- [ ] Create `OnboardingData` model
- [ ] Create `OnboardingDataService`
- [ ] Create `SocialMediaVibeAnalyzer`
- [ ] Add unit tests for models
- [ ] Add unit tests for services

### **Phase 2: Personality Learning Extensions**
- [ ] Add `_mapOnboardingToDimensions()` method
- [ ] Add `initializePersonalityFromOnboarding()` method
- [ ] Add `_determineArchetypeFromDimensions()` helper
- [ ] Add `_calculateInitialAuthenticity()` helper
- [ ] Add unit tests for mapping
- [ ] Add unit tests for initialization

### **Phase 3: Update Onboarding Flow**
- [ ] Update `OnboardingPage` to save data
- [ ] Update `OnboardingPage` to track social media
- [ ] Update `AILoadingPage` to load onboarding data
- [ ] Update `AILoadingPage` to collect social media
- [ ] Update `AILoadingPage` to use new initialization method
- [ ] Add integration tests

### **Phase 4: Dependency Injection**
- [ ] Register `OnboardingDataService`
- [ ] Register `SocialMediaVibeAnalyzer`
- [ ] Verify all services are accessible

### **Phase 5: Database Schema**
- [ ] Add onboarding data store (if needed)
- [ ] Test data persistence
- [ ] Test data retrieval

### **Phase 6: Quantum Integration** (Future)
- [ ] Integrate quantum engine into initialization
- [ ] Test quantum-calculated dimensions
- [ ] Compare quantum vs classical results

---

## 🔄 **COMPLETE FIXED FLOW**

```
┌─────────────────────────────┐
│ OnboardingPage               │
│ - Collects all data          │
│ - Tracks social media        │
└────────────┬─────────────────┘
             │
             │ Save to OnboardingDataService
             ▼
┌─────────────────────────────┐
│ OnboardingDataService        │
│ - Persists to Sembast        │
│ - Stores all onboarding data│
└────────────┬─────────────────┘
             │
             │ Pass to AILoadingPage (router + service)
             ▼
┌─────────────────────────────┐
│ AILoadingPage                │
│ - Loads onboarding data     │
│ - Collects social media      │
│ - Analyzes social media      │
└────────────┬─────────────────┘
             │
             │ initializePersonalityFromOnboarding()
             │ (with onboarding + social media data)
             ▼
┌─────────────────────────────┐
│ PersonalityLearning          │
│ - Maps onboarding data       │
│ - Analyzes social media      │
│ - Calculates dimensions      │
│ - (Future: Uses quantum)     │
└────────────┬─────────────────┘
             │
             │ Create profile with calculated dimensions
             ▼
┌─────────────────────────────┐
│ PersonalityProfile           │
│ - Accurate dimensions        │
│ - Based on user data         │
│ - Personalized archetype     │
└────────────┬─────────────────┘
             │
             │ Agent created
             ▼
┌─────────────────────────────┐
│ Agent                        │
│ - Accurate initial           │
│   personality                │
│ - Reflects user choices      │
│ - Ready for matching         │
└─────────────────────────────┘
```

---

## 🧪 **TESTING STRATEGY**

### **Unit Tests**

1. **OnboardingData Model**
   - JSON serialization
   - Validation
   - Edge cases

2. **OnboardingDataService**
   - Save/retrieve operations
   - Delete operations
   - Error handling

3. **SocialMediaVibeAnalyzer**
   - Profile analysis
   - Follows analysis
   - Connections analysis
   - Dimension mapping

4. **PersonalityLearning Extensions**
   - Onboarding-to-dimensions mapping
   - Initialization with data
   - Archetype determination
   - Authenticity calculation

### **Integration Tests**

1. **End-to-End Onboarding Flow**
   - Complete onboarding
   - Verify data saved
   - Verify agent initialized with data
   - Verify dimensions are non-default

2. **Social Media Integration**
   - Connect social media
   - Verify data collected
   - Verify insights generated
   - Verify dimensions updated

3. **Error Handling**
   - Missing onboarding data
   - Missing social media data
   - Service failures
   - Database errors

### **Validation Tests**

1. **Dimension Accuracy**
   - Verify dimensions reflect onboarding choices
   - Verify dimensions reflect social media
   - Verify dimensions are in valid range (0.0-1.0)

2. **Archetype Accuracy**
   - Verify archetype matches dimensions
   - Verify archetype is not "developing" after onboarding

3. **Data Persistence**
   - Verify data persists across app restarts
   - Verify data can be retrieved
   - Verify data is used on subsequent initializations

---

## 📅 **ESTIMATED TIMELINE**

- **Phase 1 (Data Models & Services)**: 3-4 hours
- **Phase 2 (Personality Learning)**: 2-3 hours
- **Phase 3 (Onboarding Flow)**: 2-3 hours
- **Phase 4 (Dependency Injection)**: 0.5 hours
- **Phase 5 (Database Schema)**: 0.5-1 hour
- **Phase 6 (Quantum Integration)**: 1-2 hours (after quantum engine)

**Total**: ~9-14 hours

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
- [ ] Vibe analysis produces accurate results
- [ ] Matching works correctly with personalized agent
- [ ] All tests pass
- [ ] No linter errors

---

## 🔗 **DEPENDENCIES**

### **Internal Dependencies**
- `lib/data/datasources/local/sembast_database.dart`
- `lib/core/ai/personality_learning.dart`
- `lib/core/constants/vibe_constants.dart`
- `lib/core/models/personality_profile.dart`
- `lib/injection_container.dart`

### **External Dependencies**
- `sembast` (database)
- `dart:math` (for calculations)
- No new external packages required

### **Future Dependencies**
- Quantum vibe engine (Phase 6, after quantum implementation)

---

## 📝 **IMPLEMENTATION ORDER**

1. **Start with Phase 1**: Create data models and services (foundation)
2. **Then Phase 2**: Add personality learning extensions (core logic)
3. **Then Phase 3**: Update onboarding flow (integration)
4. **Then Phase 4**: Register services (dependency injection)
5. **Then Phase 5**: Database schema (if needed)
6. **Finally Phase 6**: Quantum integration (enhancement)

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
- Don't block UI during data collection

### **Privacy**
- Onboarding data stored locally only
- Social media data analyzed on-device
- No raw social media data in agent profile
- Only derived insights used

---

**Last Updated:** December 12, 2025  
**Status:** Ready for implementation

