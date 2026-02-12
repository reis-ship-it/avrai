import 'package:equatable/equatable.dart';
import 'package:avrai/core/models/expertise/expertise_event.dart';
import 'package:avrai/core/models/user/onboarding_data.dart';
import 'package:avrai/core/models/user/user_preferences.dart';

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
/// 
/// **Phase 8.8:** Initialized from onboarding data, quantum-ready from day one
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
  /// "empty" = created without onboarding data
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
      const baseWeight = 0.7;
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
    if (onboardingData.homebase != null && onboardingData.homebase!.isNotEmpty) {
      localityPrefs[onboardingData.homebase!] = 0.8; // High weight for homebase
    }
    
    // Default scope preferences (favor local initially)
    final scopePrefs = <EventScope, double>{
      EventScope.locality: 0.7,
      EventScope.city: 0.5,
      EventScope.state: 0.3,
      EventScope.nation: 0.2,
      EventScope.globe: 0.1,
      EventScope.universe: 0.1,
      EventScope.community: 0.6,
      EventScope.clubs: 0.4,
    };
    
    // Default event type preferences (neutral initially)
    final eventTypePrefs = <ExpertiseEventType, double>{
      ExpertiseEventType.workshop: 0.5,
      ExpertiseEventType.tour: 0.5,
      ExpertiseEventType.tasting: 0.5,
      ExpertiseEventType.meetup: 0.5,
      ExpertiseEventType.walk: 0.5,
      ExpertiseEventType.lecture: 0.5,
    };
    
    // Default local expert preference (neutral)
    const localExpertWeight = 0.5;
    
    // Default exploration willingness (30% exploration, 70% familiar)
    const explorationWillingness = 0.3;
    
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
    // Calculate compatibility for each dimension
    double categoryCompat = 0.0;
    if (event.category.isNotEmpty) {
      // Check both category name and subcategories
      categoryCompat = categoryPreferences[event.category] ?? 0.0;
      // If no direct match, check if any subcategory matches
      if (categoryCompat == 0.0) {
        for (final pref in categoryPreferences.keys) {
          if (event.category.toLowerCase().contains(pref.toLowerCase()) ||
              pref.toLowerCase().contains(event.category.toLowerCase())) {
            categoryCompat = categoryPreferences[pref] ?? 0.0;
            break;
          }
        }
      }
    }
    
    double localityCompat = 0.0;
    if (event.location != null && event.location!.isNotEmpty) {
      // Check if event location matches any preferred locality
      for (final locality in localityPreferences.keys) {
        if (event.location!.toLowerCase().contains(locality.toLowerCase()) ||
            locality.toLowerCase().contains(event.location!.toLowerCase())) {
          localityCompat = localityPreferences[locality] ?? 0.0;
          break;
        }
      }
    }
    
    double eventTypeCompat = 0.0;
    eventTypeCompat = eventTypePreferences[event.eventType] ?? 0.0;
    
    // Determine scope from event (if available)
    // For now, default to locality scope
    double scopeCompat = scopePreferences[EventScope.locality] ?? 0.0;
    
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

