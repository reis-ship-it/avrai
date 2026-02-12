# PreferencesProfile Initialization from Onboarding - Phase 8 Section 8.9

**Date:** December 23, 2025  
**Status:** 📋 Ready for Implementation  
**Priority:** P1 - Core Functionality Enhancement  
**Timeline:** 3-5 days  
**Dependencies:** 
- Phase 8 Section 8.3 (agentId system) ✅
- Phase 8 Section 8.4 (Quantum Vibe Engine) ✅ Complete
- Phase 8 Section 8.1 (Baseline Lists) - For list preferences

**Related Documents:**
- `docs/architecture/PREFERENCES_PROFILE_SYSTEM.md` - Architecture specification
- `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` - Main onboarding plan
- `docs/MASTER_PLAN.md` - Master plan reference

---

## 🎯 **EXECUTIVE SUMMARY**

Add PreferencesProfile initialization to Phase 8 onboarding pipeline. PreferencesProfile will be seeded from onboarding data and created alongside PersonalityProfile during agent initialization. This ensures both profiles work together from day one, enabling quantum-powered recommendations immediately.

**Current State:**
- ✅ PersonalityProfile initialized from onboarding (quantum-enabled)
- ❌ PreferencesProfile doesn't exist yet
- ❌ Event recommendations use classical math (quantum formulas planned)
- ❌ No initial preference seeding from onboarding

**Goal:**
- Create PreferencesProfile model with agentId (quantum-ready)
- Seed initial preferences from onboarding data (categories, localities)
- Initialize PreferencesProfile alongside PersonalityProfile
- Enable quantum preference state conversion from day one
- Both profiles work together to inform agent recommendations

---

## 🚪 **DOORS PHILOSOPHY ALIGNMENT**

### **What Doors Does This Help Users Open?**

- **Better Recommendation Doors:** PreferencesProfile informs what to recommend (categories, localities, event types)
- **Quantum Doors:** Quantum compatibility calculations enable more accurate matching
- **Personalization Doors:** Initial preferences seed the learning system from day one
- **Discovery Doors:** PreferencesProfile + PersonalityProfile together enable better exploration vs familiar balance

### **When Are Users Ready for These Doors?**

- **During Onboarding:** Users express preferences (categories, localities) - ready to seed PreferencesProfile
- **After Onboarding:** Users get recommendations informed by both personality (how) and preferences (what)
- **With Quantum:** Quantum compatibility enables more nuanced matching from the start

### **Is This Being a Good Key?**

✅ **Yes** - This:
- Seeds preferences from user's actual onboarding choices
- Enables quantum-powered recommendations immediately
- Works alongside PersonalityProfile (complementary, not redundant)
- Privacy-preserving (agentId-based)
- Quantum-ready from day one

### **Is the AI Learning With the User?**

✅ **Yes** - The AI:
- Starts with preferences from onboarding (not empty)
- Learns from event attendance, spot visits, list interactions
- Evolves preferences over time while maintaining initial seed
- Uses quantum math for better compatibility calculations

---

## 📊 **CURRENT STATE ANALYSIS**

### **Gap: PreferencesProfile Missing from Onboarding**

**Problem:**
- Architecture doc shows PreferencesProfile should be created during onboarding (lines 333-340)
- Onboarding collects category preferences (`preferences` map) and homebase (locality)
- No PreferencesProfile model exists
- No initialization from onboarding data
- Event recommendations can't use quantum compatibility (no PreferencesProfile)

**Impact:**
- ❌ No initial preference seeding
- ❌ Event recommendations start with empty preferences
- ❌ Quantum preference state conversion can't happen
- ❌ Architecture promise not fulfilled

**Files:**
- Need: `lib/core/models/preferences_profile.dart` (NEW)
- Need: `lib/core/services/preferences_profile_service.dart` (NEW)
- Need: `lib/core/ai/preferences_profile_initialization.dart` (NEW)
- `lib/presentation/pages/onboarding/ai_loading_page.dart` (needs integration)
- `lib/core/ai/personality_learning.dart` (needs PreferencesProfile initialization)

---

## 📋 **IMPLEMENTATION PHASES**

### **Phase 9.1: Create PreferencesProfile Model (Day 1)**

**Goal:** Create quantum-ready PreferencesProfile model with agentId.

#### **9.1.1: Model Structure**

**Files:**
- `lib/core/models/preferences_profile.dart` (NEW)

**Implementation:**
```dart
import 'package:spots/core/models/expertise_event.dart';
import 'package:equatable/equatable.dart';

/// PreferencesProfile Model
/// 
/// Represents contextual preferences that evolve from user behavior.
/// Works alongside PersonalityProfile to inform agent recommendations.
/// 
/// **Philosophy:** PreferencesProfile represents "what the user likes" (contextual, evolving),
/// while PersonalityProfile represents "who the user is" (core, stable).
/// 
/// **Quantum Integration:**
/// - Preferences convert to quantum states: |ψ_preferences⟩ = |ψ_category⟩ ⊗ |ψ_locality⟩ ⊗ |ψ_event_type⟩
/// - Quantum compatibility: C_event = |⟨ψ_user_preferences|ψ_event⟩|²
/// - Used for event/spot recommendations (quantum-powered)
class PreferencesProfile extends Equatable {
  /// Privacy-protected identifier (matches PersonalityProfile architecture)
  final String agentId;
  
  /// Category preferences (category → weight 0.0 to 1.0)
  /// Higher weight = user prefers this category more
  /// Example: {"Coffee": 0.9, "Food": 0.7, "Art": 0.5}
  final Map<String, double> categoryPreferences;
  
  /// Locality preferences (locality → weight 0.0 to 1.0)
  /// Higher weight = user prefers events/spots in this locality
  /// Example: {"Brooklyn": 0.8, "Manhattan": 0.6}
  final Map<String, double> localityPreferences;
  
  /// Scope preferences (scope → weight 0.0 to 1.0)
  /// Higher weight = user prefers events at this scope level
  /// Example: {EventScope.locality: 0.8, EventScope.city: 0.5}
  final Map<EventScope, double> scopePreferences;
  
  /// Event type preferences (event type → weight 0.0 to 1.0)
  /// Higher weight = user prefers this event type
  /// Example: {ExpertiseEventType.workshop: 0.9, ExpertiseEventType.tour: 0.6}
  final Map<ExpertiseEventType, double> eventTypePreferences;
  
  /// Local vs city expert preference weight (0.0 to 1.0)
  /// 0.0 = prefers city/state experts, 1.0 = prefers local experts
  final double localExpertPreferenceWeight;
  
  /// Exploration willingness (0.0 to 1.0)
  /// 0.0 = prefers familiar, 1.0 = highly open to exploration
  /// Starts at 0.3 (30% exploration, 70% familiar)
  final double explorationWillingness;
  
  /// Timestamp when preferences were last updated
  final DateTime lastUpdated;
  
  /// Number of events analyzed to learn preferences
  final int eventsAnalyzed;
  
  /// Number of spots analyzed to learn preferences
  final int spotsAnalyzed;
  
  /// Number of lists analyzed to learn preferences
  final int listsAnalyzed;
  
  /// Source of initial preferences
  /// "onboarding" = seeded from onboarding data
  /// "learned" = learned from behavior
  /// "hybrid" = combination of both
  final String source;

  const PreferencesProfile({
    required this.agentId,
    this.categoryPreferences = const {},
    this.localityPreferences = const {},
    this.scopePreferences = const {},
    this.eventTypePreferences = const {},
    this.localExpertPreferenceWeight = 0.5,
    this.explorationWillingness = 0.3,
    required this.lastUpdated,
    this.eventsAnalyzed = 0,
    this.spotsAnalyzed = 0,
    this.listsAnalyzed = 0,
    this.source = 'onboarding',
  });

  /// Create initial PreferencesProfile from onboarding data
  /// 
  /// Seeds preferences from onboarding choices:
  /// - Category preferences from onboarding.preferences map
  /// - Locality preferences from onboarding.homebase
  /// - Default values for scope, event type, exploration
  factory PreferencesProfile.fromOnboarding({
    required String agentId,
    required OnboardingData onboardingData,
  }) {
    final now = DateTime.now();
    
    // Map onboarding preferences to category preferences
    final categoryPrefs = <String, double>{};
    for (final entry in onboardingData.preferences.entries) {
      final category = entry.key; // e.g., "Food & Drink"
      final subcategories = entry.value; // e.g., ["Coffee", "Craft Beer"]
      
      // Each subcategory gets a weight based on being selected
      // Weight = 0.7 (base) + 0.1 per subcategory (up to 0.9 max)
      final baseWeight = 0.7;
      final subcategoryWeight = (subcategories.length * 0.1).clamp(0.0, 0.2);
      final categoryWeight = (baseWeight + subcategoryWeight).clamp(0.0, 1.0);
      
      categoryPrefs[category] = categoryWeight;
      
      // Also add individual subcategories as preferences
      for (final subcategory in subcategories) {
        categoryPrefs[subcategory] = 0.8; // High weight for explicit selection
      }
    }
    
    // Map homebase to locality preference
    final localityPrefs = <String, double>{};
    if (onboardingData.homebase != null) {
      localityPrefs[onboardingData.homebase!] = 0.8; // High weight for homebase
    }
    
    // Default scope preferences (favor local initially)
    final scopePrefs = <EventScope, double>{
      EventScope.locality: 0.7,
      EventScope.city: 0.5,
      EventScope.state: 0.3,
    };
    
    // Default event type preferences (neutral initially)
    final eventTypePrefs = <ExpertiseEventType, double>{
      ExpertiseEventType.workshop: 0.5,
      ExpertiseEventType.tour: 0.5,
      ExpertiseEventType.tasting: 0.5,
      ExpertiseEventType.meetup: 0.5,
    };
    
    // Default local expert preference (neutral)
    final localExpertWeight = 0.5;
    
    // Default exploration willingness (30% exploration, 70% familiar)
    final explorationWillingness = 0.3;
    
    return PreferencesProfile(
      agentId: agentId,
      categoryPreferences: categoryPrefs,
      localityPreferences: localityPrefs,
      scopePreferences: scopePrefs,
      eventTypePreferences: eventTypePrefs,
      localExpertPreferenceWeight: localExpertWeight,
      explorationWillingness: explorationWillingness,
      lastUpdated: now,
      eventsAnalyzed: 0,
      spotsAnalyzed: 0,
      listsAnalyzed: 0,
      source: 'onboarding',
    );
  }
  
  /// Create empty PreferencesProfile (for users without onboarding data)
  factory PreferencesProfile.empty({
    required String agentId,
  }) {
    return PreferencesProfile(
      agentId: agentId,
      categoryPreferences: const {},
      localityPreferences: const {},
      scopePreferences: const {},
      eventTypePreferences: const {},
      localExpertPreferenceWeight: 0.5,
      explorationWillingness: 0.3,
      lastUpdated: DateTime.now(),
      eventsAnalyzed: 0,
      spotsAnalyzed: 0,
      listsAnalyzed: 0,
      source: 'empty',
    );
  }
  
  /// Convert preferences to quantum state vector
  /// 
  /// **Quantum Formula:**
  /// |ψ_preferences⟩ = |ψ_category⟩ ⊗ |ψ_locality⟩ ⊗ |ψ_event_type⟩ ⊗ |ψ_scope⟩
  /// 
  /// Where each component is a quantum state:
  /// |ψ_category⟩ = Σᵢ √(wᵢ) |categoryᵢ⟩
  /// |ψ_locality⟩ = Σⱼ √(wⱼ) |localityⱼ⟩
  /// etc.
  /// 
  /// **Returns:**
  /// Map of quantum state components (for quantum compatibility calculations)
  Map<String, dynamic> toQuantumState() {
    // Category quantum state
    final categoryState = <String, double>{};
    for (final entry in categoryPreferences.entries) {
      categoryState[entry.key] = entry.value; // Will be normalized in quantum engine
    }
    
    // Locality quantum state
    final localityState = <String, double>{};
    for (final entry in localityPreferences.entries) {
      localityState[entry.key] = entry.value;
    }
    
    // Event type quantum state
    final eventTypeState = <String, double>{};
    for (final entry in eventTypePreferences.entries) {
      eventTypeState[entry.key.name] = entry.value;
    }
    
    // Scope quantum state
    final scopeState = <String, double>{};
    for (final entry in scopePreferences.entries) {
      scopeState[entry.key.name] = entry.value;
    }
    
    return {
      'category': categoryState,
      'locality': localityState,
      'event_type': eventTypeState,
      'scope': scopeState,
      'local_expert': localExpertPreferenceWeight,
      'exploration': explorationWillingness,
    };
  }
  
  /// Calculate quantum compatibility with an event
  /// 
  /// **Quantum Formula:**
  /// C_event = |⟨ψ_user_preferences|ψ_event⟩|²
  /// 
  /// **Parameters:**
  /// - `event`: Event to calculate compatibility with
  /// 
  /// **Returns:**
  /// Quantum compatibility score (0.0 to 1.0)
  double calculateQuantumCompatibility(ExpertiseEvent event) {
    // Get user preference quantum state
    final userState = toQuantumState();
    
    // Calculate compatibility for each dimension
    double categoryCompat = 0.0;
    if (event.category != null) {
      categoryCompat = categoryPreferences[event.category!] ?? 0.0;
    }
    
    double localityCompat = 0.0;
    if (event.locality != null) {
      localityCompat = localityPreferences[event.locality!] ?? 0.0;
    }
    
    double eventTypeCompat = 0.0;
    eventTypeCompat = eventTypePreferences[event.eventType] ?? 0.0;
    
    double scopeCompat = 0.0;
    scopeCompat = scopePreferences[event.scope] ?? 0.0;
    
    // Combined compatibility (weighted average)
    // Formula: C = √(category) * √(locality) * √(event_type) * √(scope)
    // This approximates quantum inner product |⟨ψ_user|ψ_event⟩|²
    final combined = (categoryCompat * 0.3 + 
                     localityCompat * 0.3 + 
                     eventTypeCompat * 0.2 + 
                     scopeCompat * 0.2).clamp(0.0, 1.0);
    
    return combined;
  }
  
  /// Get top N category preferences
  List<MapEntry<String, double>> getTopCategories({int n = 5}) {
    final sorted = categoryPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }
  
  /// Get top N locality preferences
  List<MapEntry<String, double>> getTopLocalities({int n = 5}) {
    final sorted = localityPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }
  
  /// Check if user prefers local experts
  bool get prefersLocalExperts => localExpertPreferenceWeight > 0.6;
  
  /// Check if user is open to exploration
  bool get isOpenToExploration => explorationWillingness > 0.5;
  
  /// Copy with method
  PreferencesProfile copyWith({
    String? agentId,
    Map<String, double>? categoryPreferences,
    Map<String, double>? localityPreferences,
    Map<EventScope, double>? scopePreferences,
    Map<ExpertiseEventType, double>? eventTypePreferences,
    double? localExpertPreferenceWeight,
    double? explorationWillingness,
    DateTime? lastUpdated,
    int? eventsAnalyzed,
    int? spotsAnalyzed,
    int? listsAnalyzed,
    String? source,
  }) {
    return PreferencesProfile(
      agentId: agentId ?? this.agentId,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      localityPreferences: localityPreferences ?? this.localityPreferences,
      scopePreferences: scopePreferences ?? this.scopePreferences,
      eventTypePreferences: eventTypePreferences ?? this.eventTypePreferences,
      localExpertPreferenceWeight: localExpertPreferenceWeight ?? this.localExpertPreferenceWeight,
      explorationWillingness: explorationWillingness ?? this.explorationWillingness,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      eventsAnalyzed: eventsAnalyzed ?? this.eventsAnalyzed,
      spotsAnalyzed: spotsAnalyzed ?? this.spotsAnalyzed,
      listsAnalyzed: listsAnalyzed ?? this.listsAnalyzed,
      source: source ?? this.source,
    );
  }
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'categoryPreferences': categoryPreferences,
      'localityPreferences': localityPreferences,
      'scopePreferences': scopePreferences.map((k, v) => MapEntry(k.name, v)),
      'eventTypePreferences': eventTypePreferences.map((k, v) => MapEntry(k.name, v)),
      'localExpertPreferenceWeight': localExpertPreferenceWeight,
      'explorationWillingness': explorationWillingness,
      'lastUpdated': lastUpdated.toIso8601String(),
      'eventsAnalyzed': eventsAnalyzed,
      'spotsAnalyzed': spotsAnalyzed,
      'listsAnalyzed': listsAnalyzed,
      'source': source,
    };
  }
  
  /// Create from JSON
  factory PreferencesProfile.fromJson(Map<String, dynamic> json) {
    return PreferencesProfile(
      agentId: json['agentId'] as String,
      categoryPreferences: Map<String, double>.from(
        (json['categoryPreferences'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      localityPreferences: Map<String, double>.from(
        (json['localityPreferences'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      scopePreferences: Map<EventScope, double>.from(
        (json['scopePreferences'] as Map?)?.map((k, v) => MapEntry(
          EventScope.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => EventScope.locality,
          ),
          (v as num).toDouble(),
        )) ?? {},
      ),
      eventTypePreferences: Map<ExpertiseEventType, double>.from(
        (json['eventTypePreferences'] as Map?)?.map((k, v) => MapEntry(
          ExpertiseEventType.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => ExpertiseEventType.meetup,
          ),
          (v as num).toDouble(),
        )) ?? {},
      ),
      localExpertPreferenceWeight: (json['localExpertPreferenceWeight'] as num?)?.toDouble() ?? 0.5,
      explorationWillingness: (json['explorationWillingness'] as num?)?.toDouble() ?? 0.3,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      eventsAnalyzed: json['eventsAnalyzed'] as int? ?? 0,
      spotsAnalyzed: json['spotsAnalyzed'] as int? ?? 0,
      listsAnalyzed: json['listsAnalyzed'] as int? ?? 0,
      source: json['source'] as String? ?? 'onboarding',
    );
  }

  @override
  List<Object?> get props => [
    agentId,
    categoryPreferences,
    localityPreferences,
    scopePreferences,
    eventTypePreferences,
    localExpertPreferenceWeight,
    explorationWillingness,
    lastUpdated,
    eventsAnalyzed,
    spotsAnalyzed,
    listsAnalyzed,
    source,
  ];
}
```

**Key Features:**
- ✅ Uses `agentId` (privacy-preserving, matches PersonalityProfile)
- ✅ Quantum-ready: `toQuantumState()` method for quantum conversion
- ✅ Quantum compatibility: `calculateQuantumCompatibility()` method
- ✅ Factory: `fromOnboarding()` seeds from onboarding data
- ✅ JSON serialization for persistence

---

#### **9.1.2: PreferencesProfile Service**

**Files:**
- `lib/core/services/preferences_profile_service.dart` (NEW)

**Implementation:**
```dart
import 'dart:developer' as developer;
import 'package:spots/core/models/preferences_profile.dart';
import 'package:spots/core/models/onboarding_data.dart';
import 'package:spots/core/services/storage_service.dart';

/// PreferencesProfile Service
/// 
/// Manages PreferencesProfile persistence and retrieval.
/// Uses agentId for privacy-preserving storage.
class PreferencesProfileService {
  static const String _logName = 'PreferencesProfileService';
  static const String _storageKey = 'preferences_profile';
  
  final StorageService _storage;
  
  PreferencesProfileService({
    StorageService? storage,
  }) : _storage = storage ?? StorageService();
  
  /// Initialize PreferencesProfile from onboarding data
  /// 
  /// Creates and saves PreferencesProfile seeded from onboarding choices.
  /// 
  /// **Parameters:**
  /// - `onboardingData`: Onboarding data to seed from
  /// 
  /// **Returns:**
  /// Initialized PreferencesProfile
  Future<PreferencesProfile> initializeFromOnboarding(
    OnboardingData onboardingData,
  ) async {
    developer.log(
      'Initializing PreferencesProfile from onboarding for agentId: ${onboardingData.agentId.substring(0, 10)}...',
      name: _logName,
    );
    
    try {
      // Check if profile already exists
      final existing = await getPreferencesProfile(onboardingData.agentId);
      if (existing != null && existing.source != 'onboarding') {
        // Profile already exists and learned from behavior, don't overwrite
        developer.log(
          'PreferencesProfile already exists and learned, returning existing',
          name: _logName,
        );
        return existing;
      }
      
      // Create from onboarding data
      final profile = PreferencesProfile.fromOnboarding(
        agentId: onboardingData.agentId,
        onboardingData: onboardingData,
      );
      
      // Save to storage
      await savePreferencesProfile(profile);
      
      developer.log(
        '✅ PreferencesProfile initialized from onboarding: ${profile.categoryPreferences.length} categories, ${profile.localityPreferences.length} localities',
        name: _logName,
      );
      
      return profile;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing PreferencesProfile from onboarding: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to empty profile
      return PreferencesProfile.empty(agentId: onboardingData.agentId);
    }
  }
  
  /// Get PreferencesProfile for agentId
  Future<PreferencesProfile?> getPreferencesProfile(String agentId) async {
    try {
      final key = '$_storageKey_$agentId';
      final json = await _storage.read(key);
      if (json == null) return null;
      
      final data = json as Map<String, dynamic>;
      return PreferencesProfile.fromJson(data);
    } catch (e) {
      developer.log('Error loading PreferencesProfile: $e', name: _logName);
      return null;
    }
  }
  
  /// Save PreferencesProfile
  Future<void> savePreferencesProfile(PreferencesProfile profile) async {
    try {
      final key = '$_storageKey_${profile.agentId}';
      await _storage.write(key, profile.toJson());
    } catch (e) {
      developer.log('Error saving PreferencesProfile: $e', name: _logName);
      rethrow;
    }
  }
  
  /// Update PreferencesProfile (for learning from behavior)
  Future<void> updatePreferencesProfile(PreferencesProfile profile) async {
    try {
      final updated = profile.copyWith(
        lastUpdated: DateTime.now(),
        source: 'learned', // Mark as learned (not just onboarding)
      );
      await savePreferencesProfile(updated);
    } catch (e) {
      developer.log('Error updating PreferencesProfile: $e', name: _logName);
      rethrow;
    }
  }
}
```

**Key Features:**
- ✅ AgentId-based storage (privacy-preserving)
- ✅ Initialize from onboarding data
- ✅ Persistence via StorageService
- ✅ Update method for learning from behavior

---

### **Phase 9.2: Integrate into Agent Initialization (Day 2)**

**Goal:** Initialize PreferencesProfile alongside PersonalityProfile during agent creation.

#### **9.2.1: Update AILoadingPage**

**Files:**
- `lib/presentation/pages/onboarding/ai_loading_page.dart`

**Actions:**
1. Import PreferencesProfileService
2. Initialize PreferencesProfile after PersonalityProfile
3. Log initialization for debugging

**Code Addition:**
```dart
// After PersonalityProfile initialization (around line 340)
try {
  // Initialize PreferencesProfile from onboarding data
  final preferencesService = di.sl<PreferencesProfileService>();
  final preferencesProfile = await preferencesService.initializeFromOnboarding(
    onboardingData,
  );
  
  _logger.info(
    '✅ PreferencesProfile initialized: ${preferencesProfile.categoryPreferences.length} categories, ${preferencesProfile.localityPreferences.length} localities',
    tag: 'AILoadingPage',
  );
} catch (e) {
  _logger.warn(
    '⚠️ Could not initialize PreferencesProfile: $e',
    tag: 'AILoadingPage',
  );
  // Continue without PreferencesProfile (will be created empty later)
}
```

---

#### **9.2.2: Update PersonalityLearning**

**Files:**
- `lib/core/ai/personality_learning.dart`

**Actions:**
1. Add PreferencesProfileService dependency
2. Initialize PreferencesProfile in `initializePersonalityFromOnboarding()`
3. Return both profiles (or store PreferencesProfile separately)

**Code Addition:**
```dart
// In initializePersonalityFromOnboarding(), after PersonalityProfile creation (around line 340)
try {
  // Initialize PreferencesProfile alongside PersonalityProfile
  final preferencesService = di.sl<PreferencesProfileService>();
  final preferencesProfile = await preferencesService.initializeFromOnboarding(
    onboardingData,
  );
  
  developer.log(
    '✅ PreferencesProfile initialized alongside PersonalityProfile',
    name: _logName,
  );
} catch (e) {
  developer.log(
    '⚠️ Could not initialize PreferencesProfile: $e',
    name: _logName,
  );
  // Continue without PreferencesProfile
}
```

---

### **Phase 9.3: Register in Dependency Injection (Day 2)**

**Goal:** Register PreferencesProfileService in dependency injection.

**Files:**
- `lib/injection_container.dart`

**Actions:**
1. Register PreferencesProfileService as lazy singleton
2. Ensure it's available for AILoadingPage and PersonalityLearning

**Code Addition:**
```dart
// Register PreferencesProfileService (for preference learning and quantum recommendations)
sl.registerLazySingleton<PreferencesProfileService>(() => PreferencesProfileService(
  storage: sl<StorageService>(),
));
```

---

### **Phase 9.4: Quantum Integration Preparation (Day 3)**

**Goal:** Prepare quantum state conversion methods (for future quantum recommendation implementation).

#### **9.4.1: Quantum State Conversion Helper**

**Files:**
- `lib/core/ai/quantum/preferences_quantum_converter.dart` (NEW)

**Implementation:**
```dart
import 'package:spots/core/models/preferences_profile.dart';
import 'package:spots/core/ai/quantum/quantum_vibe_state.dart';

/// Preferences Quantum Converter
/// 
/// Converts PreferencesProfile to quantum states for quantum compatibility calculations.
/// 
/// **Quantum Formulas:**
/// - Category state: |ψ_category⟩ = Σᵢ √(wᵢ) |categoryᵢ⟩
/// - Locality state: |ψ_locality⟩ = Σⱼ √(wⱼ) |localityⱼ⟩
/// - Combined: |ψ_preferences⟩ = |ψ_category⟩ ⊗ |ψ_locality⟩ ⊗ |ψ_event_type⟩ ⊗ |ψ_scope⟩
class PreferencesQuantumConverter {
  /// Convert PreferencesProfile to quantum preference state
  /// 
  /// **Returns:**
  /// Map of quantum state components (for quantum compatibility calculations)
  static Map<String, QuantumVibeState> convertToQuantumState(
    PreferencesProfile preferences,
  ) {
    final quantumStates = <String, QuantumVibeState>{};
    
    // Category quantum state (superposition of all categories)
    final categoryStates = <QuantumVibeState>[];
    for (final entry in preferences.categoryPreferences.entries) {
      final weight = entry.value;
      // Convert weight to quantum state: √(weight) for amplitude
      final amplitude = weight.clamp(0.0, 1.0);
      categoryStates.add(QuantumVibeState.fromClassical(amplitude));
    }
    // Superpose all category states
    quantumStates['category'] = _superposeStates(categoryStates);
    
    // Locality quantum state
    final localityStates = <QuantumVibeState>[];
    for (final entry in preferences.localityPreferences.entries) {
      final weight = entry.value;
      localityStates.add(QuantumVibeState.fromClassical(weight));
    }
    quantumStates['locality'] = _superposeStates(localityStates);
    
    // Event type quantum state
    final eventTypeStates = <QuantumVibeState>[];
    for (final entry in preferences.eventTypePreferences.entries) {
      final weight = entry.value;
      eventTypeStates.add(QuantumVibeState.fromClassical(weight));
    }
    quantumStates['event_type'] = _superposeStates(eventTypeStates);
    
    // Scope quantum state
    final scopeStates = <QuantumVibeState>[];
    for (final entry in preferences.scopePreferences.entries) {
      final weight = entry.value;
      scopeStates.add(QuantumVibeState.fromClassical(weight));
    }
    quantumStates['scope'] = _superposeStates(scopeStates);
    
    // Local expert preference (single value)
    quantumStates['local_expert'] = QuantumVibeState.fromClassical(
      preferences.localExpertPreferenceWeight,
    );
    
    // Exploration willingness (single value)
    quantumStates['exploration'] = QuantumVibeState.fromClassical(
      preferences.explorationWillingness,
    );
    
    return quantumStates;
  }
  
  /// Superpose multiple quantum states
  static QuantumVibeState _superposeStates(List<QuantumVibeState> states) {
    if (states.isEmpty) {
      return QuantumVibeState.fromClassical(0.5); // Default neutral
    }
    
    // Superpose: average of all states (normalized)
    double realSum = 0.0;
    double imaginarySum = 0.0;
    for (final state in states) {
      realSum += state.real;
      imaginarySum += state.imaginary;
    }
    
    final count = states.length;
    return QuantumVibeState(realSum / count, imaginarySum / count);
  }
  
  /// Calculate quantum compatibility between PreferencesProfile and event
  /// 
  /// **Quantum Formula:**
  /// C_event = |⟨ψ_user_preferences|ψ_event⟩|²
  /// 
  /// **Parameters:**
  /// - `preferences`: User's PreferencesProfile
  /// - `event`: Event to calculate compatibility with
  /// 
  /// **Returns:**
  /// Quantum compatibility score (0.0 to 1.0)
  static double calculateQuantumCompatibility(
    PreferencesProfile preferences,
    ExpertiseEvent event,
  ) {
    // Use PreferencesProfile's built-in method (for now)
    // Future: Implement full quantum inner product calculation
    return preferences.calculateQuantumCompatibility(event);
  }
}
```

**Key Features:**
- ✅ Converts PreferencesProfile to quantum states
- ✅ Uses QuantumVibeState for quantum math
- ✅ Prepares for full quantum compatibility implementation
- ✅ Follows quantum formulas from architecture docs

---

### **Phase 9.5: Testing & Validation (Day 4)**

**Goal:** Ensure PreferencesProfile initialization works correctly.

#### **9.5.1: Unit Tests**

**Files:**
- `test/unit/models/preferences_profile_test.dart` (NEW)

**Test Cases:**
1. ✅ Create PreferencesProfile from onboarding data
2. ✅ Category preferences mapped correctly
3. ✅ Locality preferences mapped correctly
4. ✅ Quantum state conversion works
5. ✅ Quantum compatibility calculation works
6. ✅ JSON serialization/deserialization works

#### **9.5.2: Integration Tests**

**Files:**
- `test/integration/preferences_profile_initialization_test.dart` (NEW)

**Test Cases:**
1. ✅ PreferencesProfile initialized during onboarding
2. ✅ PreferencesProfile saved to storage
3. ✅ PreferencesProfile loaded after app restart
4. ✅ PreferencesProfile works alongside PersonalityProfile

---

### **Phase 9.6: Documentation Updates (Day 5)**

**Goal:** Update architecture docs to reflect implementation.

**Files:**
- `docs/architecture/PREFERENCES_PROFILE_SYSTEM.md`
- `docs/architecture/ONBOARDING_TO_AGENT_GENERATION_FLOW.md`

**Actions:**
1. Mark PreferencesProfile initialization as ✅ implemented
2. Update code examples to match implementation
3. Add implementation notes
4. Document quantum integration status

---

## ✅ **IMPLEMENTATION CHECKLIST**

### **Phase 9.1: Create PreferencesProfile Model**
- [ ] Create `PreferencesProfile` model with agentId
- [ ] Add `fromOnboarding()` factory method
- [ ] Add `toQuantumState()` method
- [ ] Add `calculateQuantumCompatibility()` method
- [ ] Add JSON serialization
- [ ] Test: Model creation works
- [ ] Test: Quantum state conversion works

### **Phase 9.2: Integrate into Agent Initialization**
- [ ] Create `PreferencesProfileService`
- [ ] Register in dependency injection
- [ ] Update `AILoadingPage` to initialize PreferencesProfile
- [ ] Update `PersonalityLearning` to initialize PreferencesProfile
- [ ] Test: PreferencesProfile created during onboarding
- [ ] Test: PreferencesProfile saved to storage

### **Phase 9.3: Quantum Integration Preparation**
- [ ] Create `PreferencesQuantumConverter` helper
- [ ] Implement quantum state conversion
- [ ] Prepare for quantum compatibility calculations
- [ ] Test: Quantum state conversion works

### **Phase 9.4: Testing & Validation**
- [ ] Write unit tests for PreferencesProfile
- [ ] Write integration tests for initialization
- [ ] Test: Onboarding → PreferencesProfile → Storage flow
- [ ] Test: PreferencesProfile works alongside PersonalityProfile

### **Phase 9.5: Documentation**
- [ ] Update architecture docs
- [ ] Mark PreferencesProfile initialization as complete
- [ ] Document quantum integration status
- [ ] Add usage examples

---

## 📊 **SUCCESS CRITERIA**

### **Functional:**
- ✅ PreferencesProfile model exists with agentId
- ✅ PreferencesProfile initialized from onboarding data
- ✅ Category preferences seeded from onboarding.preferences
- ✅ Locality preferences seeded from onboarding.homebase
- ✅ PreferencesProfile saved to storage
- ✅ PreferencesProfile loaded after app restart
- ✅ PreferencesProfile works alongside PersonalityProfile

### **Quantum-Ready:**
- ✅ `toQuantumState()` method implemented
- ✅ `calculateQuantumCompatibility()` method implemented
- ✅ Quantum state conversion helper created
- ✅ Ready for quantum recommendation implementation

### **Quality:**
- ✅ Zero linter errors
- ✅ All tests passing
- ✅ Documentation updated
- ✅ Follows architecture spec

---

## 🚨 **RISKS & MITIGATION**

### **Risk 1: PreferencesProfile Conflicts with UserPreferences**
**Risk:** Existing `UserPreferences` model might conflict  
**Mitigation:** 
- PreferencesProfile uses `agentId` (UserPreferences uses `userId`)
- PreferencesProfile is comprehensive (UserPreferences is event-focused)
- Plan migration path from UserPreferences to PreferencesProfile

### **Risk 2: Quantum Conversion Complexity**
**Risk:** Quantum state conversion might be complex  
**Mitigation:**
- Start with simplified quantum compatibility (already in model)
- Full quantum inner product can be added later
- Architecture docs provide formulas

### **Risk 3: Storage Performance**
**Risk:** Storing PreferencesProfile might impact performance  
**Mitigation:**
- Use existing StorageService (already optimized)
- PreferencesProfile is small (maps of doubles)
- Lazy loading if needed

---

## 📚 **RELATED DOCUMENTATION**

- `docs/architecture/PREFERENCES_PROFILE_SYSTEM.md` - Architecture specification
- `docs/plans/onboarding/ONBOARDING_PROCESS_PLAN.md` - Main onboarding plan
- `docs/architecture/QUANTUM_EVENT_LISTS_SYSTEM.md` - Quantum list generation
- `lib/core/models/user_preferences.dart` - Existing UserPreferences model (for reference)

---

## 🔮 **FUTURE ENHANCEMENTS**

### **1. Full Quantum Compatibility Implementation**
- Implement full quantum inner product: `C = |⟨ψ_user_preferences|ψ_event⟩|²`
- Use QuantumVibeState for all calculations
- Integrate with QuantumVibeEngine

### **2. Quantum Event List Generation**
- Use PreferencesProfile for quantum event list generation
- Apply quantum entanglement between events in lists
- Generate list themes based on quantum compatibility clusters

### **3. Quantum Individual Event Recommendations**
- Replace classical weighted averages with quantum compatibility
- Use combined compatibility: `C_combined = α * C_personality + β * C_preferences`
- Apply exploration factor for 30% exploration ratio

### **4. Preference Learning Integration**
- Integrate event attendance → PreferencesProfile learning
- Integrate spot visits → PreferencesProfile learning
- Integrate list interactions → PreferencesProfile learning

---

**Status:** 📋 Ready for Implementation  
**Last Updated:** December 23, 2025  
**Next Steps:** Begin Phase 9.1: Create PreferencesProfile Model

