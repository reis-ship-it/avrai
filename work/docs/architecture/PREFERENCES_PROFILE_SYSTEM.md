# Preferences Profile System

**Date:** December 23, 2025  
**Last Updated:** December 23, 2025  
**Status:** ✅ **IMPLEMENTED** (Phase 8.8 complete)  
**Purpose:** Comprehensive documentation of the PreferencesProfile system, its relationship with PersonalityProfile, and integration with quantum systems

---

## 🎯 **CORE CONCEPT**

**PreferencesProfile** is a separate profile system that works in tandem with **PersonalityProfile** to inform the agent. While PersonalityProfile represents the core 12-dimensional personality (stable, resists drift), PreferencesProfile captures contextual preferences that evolve from user behavior and interactions.

### **Key Distinctions:**

| Aspect | PersonalityProfile | PreferencesProfile |
|--------|-------------------|-------------------|
| **Purpose** | Core personality dimensions (stable) | Contextual preferences (evolving) |
| **Stability** | Resists drift, preserves differences | Evolves from usage patterns |
| **Dimensions** | 12 core dimensions (exploration_eagerness, curation_tendency, etc.) | Category preferences, locality preferences, event type preferences |
| **Learning** | From user actions, AI2AI interactions, feedback | From event attendance, spot visits, list interactions, recommendations |
| **Quantum Integration** | Quantum Vibe Engine (Patent #1) | Quantum compatibility for recommendations |
| **Key** | `agentId` (privacy-preserving) | `agentId` (privacy-preserving) |

---

## 📊 **USAGE ELEMENTS THAT INFORM PREFERENCES PROFILE**

### **1. Event Interactions**

**Event Attendance:**
- **Category preferences:** Which event categories user attends (Coffee, Food, Art, Music, etc.)
- **Locality preferences:** Which localities user prefers (learned from attendance patterns)
- **Scope preferences:** Local vs City vs State events (learned from attendance)
- **Event type preferences:** Workshop vs Tour vs Tasting vs Meetup (learned from attendance)
- **Local vs City expert preference:** Whether user prefers local experts or city/state experts
- **Exploration willingness:** Balance of familiar vs exploration events attended

**Event Registration:**
- **Registration patterns:** Which events user registers for (even if not attended)
- **Cancellation patterns:** Which events user cancels (indicates preferences)
- **Price sensitivity:** Response to paid vs free events

**Event Feedback:**
- **Ratings:** Event ratings inform preference weights
- **Reviews:** Text feedback analyzed for preference signals
- **Repeat attendance:** Attending similar events indicates strong preferences

### **2. Spot Interactions**

**Spot Visits:**
- **Category preferences:** Which spot categories user visits (Food & Drink, Activities, Outdoor & Nature)
- **Locality preferences:** Which localities user visits spots in
- **Price level preferences:** Budget vs Mid-range vs Premium spots visited
- **Energy level preferences:** High-energy vs Low-energy spots visited
- **Crowd tolerance:** Crowded vs Quiet spots visited
- **Distance traveled:** Local vs distant spots (location adventurousness)

**Spot Feedback:**
- **Ratings:** Spot ratings inform preference weights
- **Reviews:** Text feedback analyzed for preference signals
- **Repeat visits:** Visiting same spots indicates strong preferences

### **3. List Interactions**

**User-Created Lists:**
- **List categories:** Categories of lists user creates (Food & Drink, Activities, etc.)
- **List themes:** Themes of lists (e.g., "Best Coffee Shops", "Weekend Activities")
- **Curation patterns:** What types of spots user curates into lists
- **List respect/follow:** Which lists user respects/follows (indicates preferences)

**AI-Generated Lists:**
- **List acceptance:** Which AI-generated lists user accepts/uses
- **List modifications:** How user modifies AI-generated lists (indicates preferences)
- **List interactions:** Which lists user views, shares, or interacts with

### **4. Recommendation Interactions**

**Individual Event Suggestions:**
- **Acceptance rate:** Which suggested events user accepts
- **Rejection patterns:** Which suggested events user rejects
- **Exploration vs Familiar:** Balance of exploration vs familiar suggestions accepted

**Individual Spot Suggestions:**
- **Acceptance rate:** Which suggested spots user accepts
- **Visit patterns:** Which suggested spots user actually visits
- **Feedback on suggestions:** Ratings/reviews of suggested spots

**List Recommendations:**
- **List acceptance:** Which recommended lists user accepts
- **List usage:** How user uses recommended lists

### **5. Social Interactions**

**Social Media Data:**
- **Category interests:** Categories from social media profiles
- **Location preferences:** Locations from social media check-ins
- **Activity patterns:** Activity patterns from social media posts

**AI2AI Interactions:**
- **Connection preferences:** Types of agents user connects with
- **Interaction patterns:** How user interacts with connected agents
- **Shared preferences:** Preferences learned from agent connections

### **6. Temporal Patterns**

**Time-Based Preferences:**
- **Time of day preferences:** Morning vs Evening vs Night preferences
- **Day of week preferences:** Weekday vs Weekend preferences
- **Seasonal preferences:** Seasonal activity patterns
- **Energy level by time:** Energy preferences vary by time of day

**Context-Based Preferences:**
- **Context preferences:** Preferences vary by context (work, leisure, social, solo)
- **Mood-based preferences:** Preferences vary by mood/energy level
- **Location-based preferences:** Preferences vary by location

---

## 🔄 **HOW PREFERENCES PROFILE AND PERSONALITY PROFILE WORK TOGETHER**

### **1. Complementary Roles**

**PersonalityProfile (Core, Stable):**
- Represents **who the user is** (core personality traits)
- Resists drift, preserves individual differences
- Informs **how** the user interacts (exploration style, social style, curation style)
- Used for **compatibility matching** (quantum compatibility with other agents)

**PreferencesProfile (Contextual, Evolving):**
- Represents **what the user likes** (contextual preferences)
- Evolves from usage patterns and interactions
- Informs **what** to recommend (categories, localities, event types)
- Used for **recommendation personalization** (quantum recommendations)

### **2. Integration Flow**

```
User Action (Event Attendance, Spot Visit, List Interaction)
    ↓
PersonalityProfile Learning
    ↓
Updates Core Dimensions (exploration_eagerness, curation_tendency, etc.)
    ↓
PreferencesProfile Learning
    ↓
Updates Contextual Preferences (category preferences, locality preferences, etc.)
    ↓
Both Profiles Inform Agent
    ↓
Quantum Compatibility Calculation (PersonalityProfile)
    ↓
Quantum Recommendation Generation (PreferencesProfile)
    ↓
Personalized Recommendations (Events, Spots, Lists)
```

### **3. Quantum Integration**

**PersonalityProfile → Quantum Compatibility:**
- Uses **Patent #1: Quantum Compatibility Calculation**
- Formula: `C = |⟨ψ_A|ψ_B⟩|²` (quantum compatibility between agents)
- Bures Distance: `D_B = √[2(1 - |⟨ψ_A|ψ_B⟩|)]`
- Used for **agent-to-agent matching** (AI2AI connections, partnerships)

**PreferencesProfile → Quantum Recommendations:**
- Converts preferences to **quantum preference states**
- Uses **quantum compatibility** for event/spot matching
- Formula: `C_event = |⟨ψ_user_preferences|ψ_event⟩|²`
- Used for **event/spot recommendations** (individual suggestions, list generation)

### **4. Combined Usage in Recommendations**

**Quantum Event Recommendations:**
1. **PersonalityProfile** → Quantum compatibility with event host (agent-to-agent)
2. **PreferencesProfile** → Quantum compatibility with event characteristics (user-to-event)
3. **Combined Score:** `C_combined = α * C_personality + β * C_preferences`
   - `α = 0.4` (personality weight)
   - `β = 0.6` (preferences weight)

**Quantum Event List Generation:**
1. **PersonalityProfile** → Grouping style (exploration vs curation)
2. **PreferencesProfile** → List content (categories, localities, event types)
3. **Quantum Entanglement:** Events in list are quantum-entangled based on both profiles

---

## 🧮 **QUANTUM INTEGRATION WITH EVENT LISTS AND INDIVIDUAL SUGGESTIONS**

### **1. PreferencesProfile → Quantum Preference States**

**Converting Preferences to Quantum States:**

```dart
// Category preferences → quantum state
|ψ_category⟩ = Σᵢ √(wᵢ) |categoryᵢ⟩

// Locality preferences → quantum state
|ψ_locality⟩ = Σⱼ √(wⱼ) |localityⱼ⟩

// Event type preferences → quantum state
|ψ_event_type⟩ = Σₖ √(wₖ) |event_typeₖ⟩

// Combined preference state
|ψ_preferences⟩ = |ψ_category⟩ ⊗ |ψ_locality⟩ ⊗ |ψ_event_type⟩
```

**Where:**
- `wᵢ` = preference weight for category i (0.0 to 1.0)
- `|categoryᵢ⟩` = quantum state vector for category i
- `⊗` = tensor product (quantum entanglement)

### **2. Quantum Event List Generation**

**Process:**
1. **Convert PreferencesProfile to quantum state:** `|ψ_user_preferences⟩`
2. **Convert each event to quantum state:** `|ψ_event⟩` (based on event characteristics)
3. **Calculate quantum compatibility:** `C = |⟨ψ_user_preferences|ψ_event⟩|²`
4. **Group events by quantum compatibility:** Events with similar compatibility scores
5. **Apply quantum entanglement:** Events in same list are quantum-entangled
6. **Generate list themes:** Based on quantum compatibility clusters

**Quantum List Formula:**
```
List_theme = {events | C_event > threshold AND C_event ≈ C_other_events_in_list}
```

**Where:**
- `C_event` = quantum compatibility between user preferences and event
- `threshold` = minimum compatibility for inclusion (e.g., 0.6)
- Events in same list have similar compatibility scores (quantum-entangled)

### **3. Individual Event Suggestions**

**Quantum Individual Event Recommendation:**

1. **Convert PreferencesProfile to quantum state:** `|ψ_user_preferences⟩`
2. **Convert event to quantum state:** `|ψ_event⟩`
3. **Calculate quantum compatibility:** `C = |⟨ψ_user_preferences|ψ_event⟩|²`
4. **Calculate relevance score:** `relevance = C * exploration_factor`
   - `exploration_factor` = 1.0 for familiar, 0.7 for exploration (30% exploration ratio)
5. **Sort by relevance:** Highest relevance first

**Combined with PersonalityProfile:**
```
C_combined = α * C_personality + β * C_preferences
```

**Where:**
- `C_personality` = quantum compatibility with event host (from PersonalityProfile)
- `C_preferences` = quantum compatibility with event characteristics (from PreferencesProfile)
- `α = 0.4`, `β = 0.6` (weights)

### **4. AI Suggestions Tab (Events Page)**

**Current State:**
- Events page has tabs based on **geographic scope** (Community, Locality, City, State, etc.)
- No "AI Suggestions" tab currently exists
- EventRecommendationService exists but not fully integrated

**Proposed "AI Suggestions" Tab:**

**Tab Structure:**
- **Tab 1:** Scope-based tabs (Community, Locality, City, State) - existing
- **Tab 2:** "AI Suggestions" - new tab powered by quantum recommendations

**AI Suggestions Tab Content:**
1. **Individual Event Suggestions:**
   - Top 10-20 events with highest quantum compatibility
   - Sorted by relevance score (quantum compatibility * exploration factor)
   - Shows: Event card, compatibility score, recommendation reason

2. **AI-Generated Event Lists:**
   - Lists generated using quantum event list generation
   - Grouped by themes (e.g., "Coffee Events Near You", "Weekend Workshops")
   - Each list contains 5-10 quantum-entangled events

3. **Exploration Opportunities:**
   - Events outside typical preferences (30% exploration ratio)
   - Quantum compatibility still calculated, but lower threshold
   - Helps users discover new categories/localities

**Quantum Math Behind AI Suggestions Tab:**

```
For each event:
  C_preferences = |⟨ψ_user_preferences|ψ_event⟩|²
  C_personality = |⟨ψ_user_personality|ψ_event_host⟩|²
  C_combined = 0.4 * C_personality + 0.6 * C_preferences
  
  relevance = C_combined * exploration_factor
  exploration_factor = 0.7 if exploration, 1.0 if familiar
  
Sort by relevance (highest first)
```

---

## 🔗 **INTEGRATION WITH AGENT ID**

### **1. AgentId-Based Architecture**

**Current State:**
- ✅ `PersonalityProfile` uses `agentId` (migrated in Phase 8.3)
- ✅ `PreferencesProfile` uses `agentId` (implemented in Phase 8.8)
- ⚠️ `UserPreferences` uses `userId` (not `agentId`) - legacy model, consider migration

**Proposed PreferencesProfile Model:**

```dart
class PreferencesProfile {
  final String agentId; // Privacy-preserving identifier
  final Map<String, double> categoryPreferences; // Category → weight
  final Map<String, double> localityPreferences; // Locality → weight
  final Map<EventScope, double> scopePreferences; // Scope → weight
  final Map<ExpertiseEventType, double> eventTypePreferences; // Event type → weight
  final double localExpertPreferenceWeight; // 0.0 to 1.0
  final double explorationWillingness; // 0.0 to 1.0
  final DateTime lastUpdated;
  final int eventsAnalyzed;
  final int spotsAnalyzed;
  final int listsAnalyzed;
}
```

### **2. Privacy-Preserving Design**

**AgentId Benefits:**
- **Privacy:** No direct user identification in preferences
- **AI2AI Compatibility:** Works seamlessly with AI2AI network
- **Consistency:** Matches PersonalityProfile architecture
- **Future-Proof:** Ready for federated learning, differential privacy

### **3. Integration with Onboarding** ✅ **IMPLEMENTED**

**Onboarding Flow:**
1. ✅ User completes onboarding → `agentId` generated
2. ✅ Initial preferences from onboarding data (categories, localities)
3. ✅ PreferencesProfile initialized in AILoadingPage after PersonalityProfile
4. ✅ PreferencesProfile saved to storage with agentId
5. ✅ PreferencesProfile ready for quantum-powered recommendations

**Implementation:**
- `PreferencesProfile.fromOnboarding()` factory method seeds preferences from onboarding choices
- Category preferences mapped from `onboarding.preferences` map
- Locality preferences mapped from `onboarding.homebase`
- Default values for scope, event type, exploration willingness
- Quantum-ready: `toQuantumState()` method available from day one
3. PreferencesProfile created with `agentId`
4. PersonalityProfile created with `agentId`
5. Both profiles work together to inform agent

---

## 📈 **LEARNING AND EVOLUTION**

### **1. Continuous Learning**

**Learning Sources:**
- **Event attendance:** Updates category, locality, scope, event type preferences
- **Spot visits:** Updates category, locality, price, energy preferences
- **List interactions:** Updates curation preferences, list category preferences
- **Recommendation feedback:** Updates preference weights based on acceptance/rejection
- **Social interactions:** Updates preferences from social media, AI2AI connections

### **2. Preference Weight Updates**

**Event Attendance:**
```dart
// Category preference update
categoryPreferences[event.category] = 
  (currentWeight * 0.9) + (attendanceSignal * 0.1)

// Locality preference update
localityPreferences[event.locality] = 
  (currentWeight * 0.9) + (attendanceSignal * 0.1)
```

**Where:**
- `attendanceSignal` = 1.0 if attended, 0.5 if registered but not attended, 0.0 if rejected
- Weight decay factor = 0.9 (preferences decay over time if not reinforced)

### **3. Exploration vs Familiar Balance**

**Exploration Willingness:**
- Starts at 0.3 (30% exploration, 70% familiar)
- Increases when user accepts exploration suggestions
- Decreases when user rejects exploration suggestions
- Used to balance familiar vs exploration recommendations

**Recommendation Strategy:**
- **70% Familiar:** Events matching strong preferences
- **30% Exploration:** Events outside typical preferences but still potentially interesting
- Quantum compatibility still calculated for exploration events (lower threshold)

---

## 🎯 **IMPLEMENTATION STATUS**

### **Current State:**

**✅ Existing:**
- `UserPreferences` model (event-focused, uses `userId`)
- `UserPreferenceLearningService` (learns from event attendance)
- `EventRecommendationService` (uses preferences for recommendations)
- Event attendance tracking (partial)

**❌ Missing:**
- Separate `PreferencesProfile` model (attached to `agentId`)
- Spot visit preference learning
- List interaction preference learning
- Quantum preference state conversion
- Quantum event list generation
- AI Suggestions tab in events page
- Event attendance → personality learning integration

### **Required Implementation:**

**Phase 1: PreferencesProfile Model**
- Create `PreferencesProfile` model with `agentId`
- Migrate from `UserPreferences` (event-focused) to `PreferencesProfile` (comprehensive)
- Include all preference types (categories, localities, scopes, event types, spots, lists)

**Phase 2: Learning Integration**
- Integrate event attendance → personality learning
- Add spot visit preference learning
- Add list interaction preference learning
- Add recommendation feedback learning

**Phase 3: Quantum Integration**
- Convert preferences to quantum states
- Implement quantum event list generation
- Implement quantum individual event suggestions
- Integrate with PersonalityProfile for combined recommendations

**Phase 4: UI Integration**
- Add "AI Suggestions" tab to events page
- Display individual event suggestions
- Display AI-generated event lists
- Show exploration opportunities

---

## 📚 **RELATED DOCUMENTATION**

- **PersonalityProfile:** `docs/architecture/ONBOARDING_TO_AGENT_GENERATION_FLOW.md`
- **Quantum Vibe Engine:** `lib/core/ai/quantum/quantum_vibe_engine.dart`
- **Event Recommendations:** `lib/core/services/event_recommendation_service.dart`
- **Preference Learning:** `lib/core/services/user_preference_learning_service.dart`
- **Patent #1:** Quantum Compatibility Calculation (`docs/patents/category_1_quantum_ai_systems/01_quantum_compatibility_calculation/`)
- **Patent #8:** Hyper-Personalized Recommendation Fusion (`docs/patents/category_4_recommendation_discovery_systems/02_hyper_personalized_recommendation/`)
- **Master Plan:** `docs/MASTER_PLAN.md` (Phase 8, Phase 19)

---

## 🔮 **FUTURE ENHANCEMENTS**

### **1. Advanced Quantum Features**
- **Quantum Entanglement:** Events in lists are quantum-entangled
- **Quantum Superposition:** Multiple preference states in superposition
- **Quantum Interference:** Constructive/destructive interference for recommendations
- **Quantum Decoherence:** Temporal effects on preference coherence

### **2. Multi-Entity Quantum Matching**
- **Phase 19:** Multi-Entity Quantum Entanglement Matching
- Event-user matching using quantum compatibility
- Multi-way matching (users, events, businesses, brands)

### **3. Differential Privacy**
- **Privacy-Preserving Learning:** Learn preferences with differential privacy
- **Epsilon Values:** Control privacy-utility tradeoff
- **Entropy Validation:** Ensure privacy guarantees

### **4. Federated Learning**
- **Distributed Learning:** Learn preferences across devices
- **Privacy-Preserving Aggregation:** Aggregate preferences without exposing individual data
- **AI2AI Network Integration:** Share preference patterns across network

---

**Last Updated:** December 23, 2025  
**Status:** 📚 Architecture Documentation - Ready for Implementation

