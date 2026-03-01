# User-AI Interaction Update Plan

**Date:** December 16, 2025, 10:42 AM CST  
**Status:** 📋 Ready for Implementation  
**Priority:** HIGH  
**Timeline:** 6-8 weeks  
**Purpose:** Comprehensive plan for implementing layered AI inference, learning loop closure, and user interaction enhancement

---

## 🚪 **DOORS PHILOSOPHY ALIGNMENT**

### **What Doors Does This Help Users Open?**

This update opens doors to:
- **Better AI Understanding:** AI learns from every interaction, showing doors that truly resonate
- **Faster, More Private Responses:** On-device processing means doors appear instantly, even offline
- **Richer Context:** AI understands not just what you do, but when, where, and why
- **Meaningful Connections:** Learning system helps AI2AI connections find people who open similar doors
- **Life Enrichment:** Continuous learning means the AI gets better at showing you doors that lead to meaning, fulfillment, and happiness

### **When Are Users Ready for These Doors?**

- **Immediate:** On-device inference works right away (privacy, speed)
- **Gradual:** Learning system improves over time as it observes patterns
- **Contextual:** Different doors appear based on time, location, social context
- **Receptive Moments:** AI learns when you're open to new doors vs. when you want familiar ones

### **Is This Being a Good Key?**

✅ **Yes** - This update:
- Preserves privacy (on-device processing)
- Works offline (doors appear anywhere)
- Learns authentically (from real actions, not assumptions)
- Adapts to individual usage patterns
- Enhances real-world experiences (not replaces them)

### **Is the AI Learning With the User?**

✅ **Yes** - This update:
- Processes every interaction in real-time
- Updates personality dimensions continuously
- Learns from social and community patterns
- Improves recommendations based on what doors users actually open
- Feeds back into agent generation pipeline

---

## 🎯 **EXECUTIVE SUMMARY**

This plan implements a comprehensive User-AI interaction system that:

1. **Layered Inference Path:** ONNX orchestrator for privacy-sensitive scoring locally, Gemini for higher-level reasoning
2. **Supabase Edge Mesh:** Small, focused edge functions for onboarding aggregation, social enrichment, and LLM generation
3. **Retrieval + LLM Fusion:** Deterministic layer converts interactions into structured facts, feeds distilled context to Gemini
4. **Federated Learning:** AI2AI hooks collect anonymized embedding deltas for on-device personalization
5. **Decision Fabric:** Coordinator service chooses optimal pathway (offline/online, local/cloud) in real-time
6. **Micro Event Instrumentation:** Structured events (list_view_started, respect_tap, scroll_depth) with rich context
7. **Schema Hooks:** Complete Supabase queries for social and community data
8. **Learning Loop Closure:** Real-time model updates from interaction events
9. **Context Enrichment:** Time, location, weather, social context in all events
10. **Learning Quality Monitoring:** Analytics dashboards and feedback loops

**Result:** Fast, private, context-aware AI that learns continuously and opens doors that truly resonate.

---

## 🔗 **RAG AI2AI + Federated + Offline-First**

Implemented per plan `rag_ai2ai_federated_offline-first`. Key pieces:

- **RAGContextBuilder** (`lib/core/ai/rag_context_builder.dart`): Unified context builder. Uses FactsIndex, NetworkCueRetrieval, RetrievalBiasService, PersonalityLearning, UserVibeAnalyzer, LanguagePatternLearningService, AI2AIContextProvider. Produces `LLMContext` with facts, network cues, personality, vibe, ai2aiInsights, connectionMetrics, languageStyle.
- **AIA2AIContextProvider** (`lib/core/ai/ai2ai_context_provider.dart`): Supplies AI2AI insights (from `RagAi2AiInsightsStore`) and connection metrics for RAG. Metrics may be null when offline.
- **RAG-in-AI2AI:** Business–expert and business–business chat services remain relay-only. When adding LLM-backed features, use `RAGContextBuilder.buildContextForAI2AIActor` (or equivalent) with clear data boundaries: actor-specific facts/cues only, no cross-party user facts, anonymized network cues.
- **Storage:** `structured_facts:{agentId}`, `network_retrieval_cues_v1`, `federated_priors_cache_v1`, `rag_ai2ai_insights_v1`, `rag_feedback_signals_v1` (all in `spots_ai` box). See plan for sync and offline behaviour.

---

## **Answer Layer (RAG-as-Answer + Bypass + Conversation Preferences)**

Implemented per plan *RAG wiring, RAG-as-answer, bypass, and conversation preferences*. Summary:

- **Default path:** RAG-as-answer is first choice. Flow: **Scope** → **Bypass** → **Retrieve** → **Merge** → **Format** → return. Uses `ScopeClassifier`, `BypassIntentDetector`, `RetrievalService`, `RAGFormatter`, and `AnswerLayerOrchestrator`.
- **Scope:** `ScopeClassifier` rule-based v1. Out-of-scope (general knowledge, math, current events) → refuse/redirect. In-scope → continue.
- **Bypass:** Users can bypass RAG-as-answer by e.g. “tell me more”, “continue”, “go deeper”. `BypassIntentDetector` detects; we skip RAG-as-answer and use `generateWithContext` / `chat` with full RAG context so the model can elaborate.
- **Formatting:** Templates first; optional LLM format with strict “no new facts” instructions. Fallback: template-only (bullet list). Empty retrieval → fixed “not enough” message; partial → caveat + template.
- **RAG feedback:** RAG and bypass turns recorded via `RAGSignalsCollector` (`usedBypass`, `retrievedFactGroups`, etc.). Feedback wires into `RetrievalBiasService` (local weights) and optional federated sync.
- **Conversation preferences:** `ConversationPreferenceStore` holds per-user `bypassRate`, `totalRagTurns`, `totalBypassTurns`. Updated after each RAG or bypass turn. Fetched by `RAGContextBuilder` and attached to `LLMContext` as `conversationPreferences` so larger/cloud models can adapt. Stored in `spots_ai` under `conversation_prefs_{userId}`.
- **Sharing for larger models:** `conversationPreferences` is included in `LLMContext` and thus in context sent to cloud/local LLMs. Merging into `PersonalityProfile.learningHistory['conversation_preferences']` for personality sync is optional follow-up.
- **Optional federated RAG feedback:** When `rag_feedback_in_federated_sync` prefs flag is enabled, device-level aggregates (`retrieved_group_counts`, `network_cues_used`, `search_used`) are sent in the federated-sync payload. Edge function stores them in `rag_feedback_aggregates_v1` (no PII).

---

## 📊 **CURRENT STATE ANALYSIS**

### ✅ **What Exists:**

1. **ContinuousLearningSystem** (`lib/core/ai/continuous_learning_system.dart`)
   - ✅ Framework exists with 10 learning dimensions
   - ✅ Data collection methods (location, weather, time) implemented
   - ❌ `processUserInteraction()`, `trainModel()`, `updateModelRealtime()` are stubs
   - ❌ `_collectSocialData()`, `_collectCommunityData()`, `_collectAppUsageData()` are stubs

2. **Inference Infrastructure**
   - ✅ ConfigService supports `device_first` orchestration strategy
   - ✅ ONNX backend stub exists (`lib/core/ml/onnx_backend_stub.dart`)
   - ✅ Cloud embedding client exists
   - ❌ ONNX currently disabled (cloud-only mode)
   - ❌ No InferenceOrchestrator implementation

3. **Supabase Edge Functions**
   - ✅ Edge function infrastructure exists
   - ✅ Coordinator function exists
   - ✅ Embeddings function exists
   - ❌ No onboarding aggregation function
   - ❌ No social enrichment function
   - ❌ No LLM generation function

4. **OnboardingDataService**
   - ✅ Service exists and saves data to Sembast
   - ✅ Uses agentId for privacy protection
   - ❌ No realtime event triggers to edge functions
   - ❌ No integration with learning system

5. **LLM Service**
   - ✅ LLMService exists (`lib/core/services/llm_service.dart`)
   - ✅ Supabase edge function integration
   - ❌ No structured context preparation
   - ❌ No retrieval-augmented generation

### ❌ **What's Missing:**

1. **Layered Inference Path**
   - No ONNX orchestrator implementation
   - No device-first strategy logic
   - No dimension scoring on-device

2. **Edge Mesh Functions**
   - No onboarding aggregation function
   - No social data enrichment function
   - No LLM generation function with context

3. **Learning Loop**
   - No real-time interaction processing
   - No model training from events
   - No dimension weight updates

4. **Event Instrumentation**
   - No structured event logging
   - No context field enrichment
   - No event persistence

5. **Schema Integration**
   - No Supabase queries for social data
   - No Supabase queries for community data
   - No event storage schema

---

## 🏗️ **ARCHITECTURE OVERVIEW**

### **Layered AI Stack (Enhanced with Phase 11 Integrations)**

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interaction                        │
│  (Respect tap, list view, scroll, dwell time, etc.)       │
└──────────────────────┬────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────┐
        │  Event Instrumentation Layer  │
        │  • Structured events          │
        │  • Context enrichment         │
        │  • Offline queue              │
        └──────────────┬─────────────────┘
                       │
        ┌──────────────┴─────────────────┐
        │                                │
        ▼                                ▼
┌───────────────────┐        ┌──────────────────────┐
│  On-Device Layer  │        │   Edge/Cloud Layer    │
│  (ONNX + Rules)   │        │  (Supabase + Gemini)  │
│  • Real-time bias │        │  • LLM Generation     │
│    updates (NEW)  │        │  • Social Enrichment  │
└─────────┬─────────┘        └──────────┬────────────┘
          │                             │
          ▼                             ▼
┌─────────────────────────┐  ┌──────────────────────────┐
│  ContinuousLearning     │  │  Edge Functions Mesh     │
│  System                 │  │  • Onboarding Agg        │
│  • Dimension scoring    │  │  • Social Enrichment     │
│  • Real-time updates    │  │  • LLM Generation        │
│  • Offline processing   │  └──────────┬───────────────┘
│  • AI2AI mesh (NEW)     │             │
│  • Chat learning (NEW)  │             │
└─────────┬───────────────┘             │
          │                              │
          ├──────────────────────────────┤
          │                              │
          ▼                              ▼
┌──────────────────────┐    ┌────────────────────────┐
│  AI2AI Mesh Network  │    │  Decision Fabric       │
│  (Bluetooth)         │    │  (Pathway Coordinator) │
│  • Learning insights │    │  • Offline mesh (NEW)  │
│  • Mesh propagation  │    │  • Context-aware       │
│  • ONNX updates      │    └──────────┬─────────────┘
└──────────┬───────────┘               │
           │                           │
           └───────────┬───────────────┘
                       │
                       ▼
              ┌──────────────────────┐
              │  PersonalityProfile  │
              │  (Updated Dimensions)│
              │  • ONNX biases       │
              │  • Mesh learning     │
              │  • Chat insights     │
              └──────────────────────┘
```

### **Data Flow**

1. **User Interaction** → Structured event with context
2. **Event Queue** → Local (Sembast/Isar) + Sync to Supabase when online
3. **On-Device Processing** → ONNX dimension scoring → Immediate UI updates
4. **Edge Processing** → Supabase functions → Social/community enrichment
5. **LLM Processing** → Structured facts → Gemini → Rich narrative
6. **Learning Update** → Dimension weights → PersonalityProfile
7. **ONNX Update** → Real-time bias updates from interactions (Phase 11 Enhancement)
8. **Mesh Propagation** → Significant updates sent to AI2AI mesh (Phase 11 Enhancement)
9. **Mesh Learning** → AI2AI insights received → ONNX updates (Phase 11 Enhancement)
10. **Conversation Learning** → Chat analysis → Dimension updates (Phase 11 Enhancement)
11. **Feedback Loop** → Updated profile → Better recommendations

---

## 📋 **IMPLEMENTATION PHASES**

### **Phase 1: Event Instrumentation & Schema Hooks (Week 1-2)**

**Goal:** Instrument micro events and complete schema hooks for data collection.

#### **1.1: Structured Event System**

**Files:**
- `lib/core/ai/interaction_events.dart` (NEW)
- `lib/core/ai/event_logger.dart` (NEW)
- `lib/core/ai/event_queue.dart` (NEW)

**Implementation:**

```dart
// lib/core/ai/interaction_events.dart
class InteractionEvent {
  final String eventType; // list_view_started, respect_tap, scroll_depth, etc.
  final Map<String, dynamic> parameters; // list_id, category, dwell_time, etc.
  final InteractionContext context; // time, location, weather, social
  final DateTime timestamp;
  final String? agentId; // Privacy-protected user identifier
}

class InteractionContext {
  final DateTime timeOfDay;
  final LocationData? location;
  final WeatherData? weather;
  final SocialContext? social; // Who's nearby, AI2AI connections
  final AppContext? app; // Current screen, previous actions
}
```

**Events to Instrument:**
- `list_view_started` (list_id, category, source)
- `list_view_duration` (list_id, duration_ms)
- `respect_tap` (target_type, target_id, context)
- `scroll_depth` (list_id, depth_percentage, scroll_velocity)
- `dwell_time` (spot_id, duration_ms, interaction_type)
- `search_performed` (query, results_count, selected_result)
- `spot_visited` (spot_id, visit_duration, check_in)
- `event_attended` (event_id, attendance_duration)

**Integration Points:**
- Add event logging to `ListDetailPage`, `SpotDetailPage`, `SearchPage`
- Add event logging to respect buttons, scroll listeners
- Add event logging to navigation transitions

#### **1.2: Complete Schema Hooks**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)

**Implementation:**

```dart
// Complete _collectSocialData()
Future<List<dynamic>> _collectSocialData() async {
  try {
    final supabase = Supabase.instance.client;
    final agentId = await _agentIdService.getUserAgentId(userId);
    
    // Query user_respects
    final respects = await supabase
        .from('user_respects')
        .select('*, spots(*), lists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    
    // Query user_follows
    final follows = await supabase
        .from('user_follows')
        .select('*, followed_user:users!user_follows_followed_user_id_fkey(*)')
        .eq('follower_id', userId)
        .limit(50);
    
    // Query comments/shares
    final comments = await supabase
        .from('comments')
        .select('*, spot:spots(*), list:lists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    
    final shares = await supabase
        .from('shares')
        .select('*, spot:spots(*), list:lists(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    
    return [
      ...respects.map((r) => {'type': 'respect', 'data': r}),
      ...follows.map((f) => {'type': 'follow', 'data': f}),
      ...comments.map((c) => {'type': 'comment', 'data': c}),
      ...shares.map((s) => {'type': 'share', 'data': s}),
    ];
  } catch (e) {
    developer.log('Error collecting social data: $e', name: _logName);
    return [];
  }
}

// Complete _collectCommunityData()
Future<List<dynamic>> _collectCommunityData() async {
  try {
    final supabase = Supabase.instance.client;
    
    // Query user_respects aggregated
    final respectedLists = await supabase
        .from('lists')
        .select('*, respects:user_respects(count)')
        .gt('respect_count', 0)
        .order('respect_count', ascending: false)
        .limit(20);
    
    // Query community interactions
    final interactions = await supabase
        .from('community_interactions')
        .select('*, user:users(*), spot:spots(*), list:lists(*)')
        .order('created_at', ascending: false)
        .limit(50);
    
    // Query trending spots/lists
    final trendingSpots = await supabase
        .from('spots')
        .select('*, respects:user_respects(count)')
        .order('respect_count', ascending: false)
        .limit(20);
    
    return [
      ...respectedLists.map((l) => {'type': 'respected_list', 'data': l}),
      ...interactions.map((i) => {'type': 'interaction', 'data': i}),
      ...trendingSpots.map((s) => {'type': 'trending_spot', 'data': s}),
    ];
  } catch (e) {
    developer.log('Error collecting community data: $e', name: _logName);
    return [];
  }
}

// Complete _collectAppUsageData()
Future<List<dynamic>> _collectAppUsageData() async {
  try {
    final supabase = Supabase.instance.client;
    final agentId = await _agentIdService.getUserAgentId(userId);
    
    // Query interaction_events table (created in Phase 1.1)
    final events = await supabase
        .from('interaction_events')
        .select('*')
        .eq('agent_id', agentId)
        .order('timestamp', ascending: false)
        .limit(100);
    
    // Aggregate by event type
    final aggregated = <String, Map<String, dynamic>>{};
    for (final event in events) {
      final type = event['event_type'] as String;
      if (!aggregated.containsKey(type)) {
        aggregated[type] = {
          'event_type': type,
          'count': 0,
          'total_duration': 0,
          'last_occurrence': event['timestamp'],
        };
      }
      aggregated[type]!['count']++;
      if (event['parameters']?['duration_ms'] != null) {
        aggregated[type]!['total_duration'] += event['parameters']['duration_ms'];
      }
    }
    
    return aggregated.values.toList();
  } catch (e) {
    developer.log('Error collecting app usage data: $e', name: _logName);
    return [];
  }
}
```

**Database Schema (Supabase Migration):**

```sql
-- Create interaction_events table
CREATE TABLE interaction_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id TEXT NOT NULL, -- Privacy-protected identifier
  event_type TEXT NOT NULL, -- list_view_started, respect_tap, etc.
  parameters JSONB NOT NULL, -- Flexible event parameters
  context JSONB, -- time, location, weather, social context
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for efficient queries
CREATE INDEX idx_interaction_events_agent_id ON interaction_events(agent_id);
CREATE INDEX idx_interaction_events_timestamp ON interaction_events(timestamp DESC);
CREATE INDEX idx_interaction_events_type ON interaction_events(event_type);

-- Enable RLS (Row Level Security)
ALTER TABLE interaction_events ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own events (via agentId)
CREATE POLICY "Users can view own events"
  ON interaction_events
  FOR SELECT
  USING (agent_id = current_setting('app.current_agent_id', true));
```

**Deliverables:**
- ✅ Structured event system with context enrichment
- ✅ Event queue with offline support
- ✅ Complete schema hooks for social/community/app usage data
- ✅ Database migration for interaction_events table
- ✅ Integration with UI components

---

### **Phase 2: Learning Loop Closure (Week 2-3)**

**Goal:** Implement real-time learning from interactions, closing the loop from events to dimension updates.

#### **2.1: Implement processUserInteraction()**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)

**Implementation:**

```dart
Future<void> processUserInteraction(Map<String, dynamic> payload) async {
  try {
    final eventType = payload['event_type'] as String;
    final parameters = payload['parameters'] as Map<String, dynamic>? ?? {};
    final context = payload['context'] as Map<String, dynamic>? ?? {};
    
    // Map event to learning dimensions
    final dimensionUpdates = <String, double>{};
    
    switch (eventType) {
      case 'respect_tap':
        // Respecting a "coffee spots" list bumps community_evolution and personalization_depth
        final targetType = parameters['target_type'] as String?;
        if (targetType == 'list') {
          final category = parameters['category'] as String?;
          dimensionUpdates['community_evolution'] = 0.05;
          dimensionUpdates['personalization_depth'] = 0.03;
          
          // Category-specific learning
          if (category != null) {
            dimensionUpdates['user_preference_understanding'] = 0.02;
          }
        }
        break;
        
      case 'list_view_duration':
        // Longer dwell time indicates interest
        final duration = parameters['duration_ms'] as int? ?? 0;
        if (duration > 30000) { // 30 seconds
          dimensionUpdates['user_preference_understanding'] = 0.04;
          dimensionUpdates['recommendation_accuracy'] = 0.02;
        }
        break;
        
      case 'scroll_depth':
        // Deep scrolling indicates engagement
        final depth = parameters['depth_percentage'] as double? ?? 0.0;
        if (depth > 0.8) {
          dimensionUpdates['user_preference_understanding'] = 0.03;
        }
        break;
        
      case 'spot_visited':
        // Visiting a spot indicates recommendation success
        dimensionUpdates['recommendation_accuracy'] = 0.05;
        dimensionUpdates['location_intelligence'] = 0.03;
        break;
        
      case 'event_attended':
        // Attending events indicates community engagement
        dimensionUpdates['community_evolution'] = 0.08;
        dimensionUpdates['social_dynamics'] = 0.05;
        break;
    }
    
    // Apply context modifiers
    final timeOfDay = context['time_of_day'] as String?;
    final location = context['location'] as Map<String, dynamic>?;
    final weather = context['weather'] as Map<String, dynamic>?;
    
    // Time-based learning (e.g., morning coffee preferences)
    if (timeOfDay == 'morning' && eventType == 'spot_visited') {
      dimensionUpdates['temporal_patterns'] = 0.02;
    }
    
    // Location-based learning
    if (location != null) {
      dimensionUpdates['location_intelligence'] = 
          (dimensionUpdates['location_intelligence'] ?? 0.0) + 0.01;
    }
    
    // Weather-based learning
    if (weather != null) {
      final conditions = weather['conditions'] as String?;
      if (conditions == 'Rain' && eventType == 'spot_visited') {
        dimensionUpdates['temporal_patterns'] = 0.01;
      }
    }
    
    // Update dimension weights
    for (final entry in dimensionUpdates.entries) {
      final current = _currentLearningState[entry.key] ?? 0.5;
      final learningRate = _learningRates[entry.key] ?? 0.1;
      final newValue = (current + (entry.value * learningRate)).clamp(0.0, 1.0);
      _currentLearningState[entry.key] = newValue;
      
      // Record learning event
      _recordLearningEvent(
        entry.key,
        entry.value,
        LearningData.empty(), // Will be enriched in next cycle
      );
    }
    
    // Trigger real-time model update
    await updateModelRealtime(payload);
    
    developer.log(
      'Processed interaction: $eventType → ${dimensionUpdates.length} dimension updates',
      name: _logName,
    );
  } catch (e) {
    developer.log('Error processing user interaction: $e', name: _logName);
  }
}
```

#### **2.2: Implement trainModel()**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)

**Implementation:**

```dart
Future<void> trainModel(dynamic data) async {
  try {
    // Collect recent interaction history
    final recentEvents = await _collectRecentInteractions(limit: 100);
    
    // Group by dimension
    final dimensionData = <String, List<Map<String, dynamic>>>{};
    for (final event in recentEvents) {
      final updates = await _calculateDimensionUpdates(event);
      for (final entry in updates.entries) {
        if (!dimensionData.containsKey(entry.key)) {
          dimensionData[entry.key] = [];
        }
        dimensionData[entry.key]!.add({
          'event': event,
          'update': entry.value,
        });
      }
    }
    
    // Train each dimension
    for (final entry in dimensionData.entries) {
      final dimension = entry.key;
      final trainingData = entry.value;
      
      // Calculate average improvement
      final avgImprovement = trainingData
          .map((d) => d['update'] as double)
          .reduce((a, b) => a + b) / trainingData.length;
      
      // Update dimension weight
      final current = _currentLearningState[dimension] ?? 0.5;
      final learningRate = _learningRates[dimension] ?? 0.1;
      final newValue = (current + (avgImprovement * learningRate)).clamp(0.0, 1.0);
      _currentLearningState[dimension] = newValue;
      
      // Update improvement metrics
      _improvementMetrics[dimension] = avgImprovement;
      
      developer.log(
        'Trained dimension $dimension: $current → $newValue (improvement: $avgImprovement)',
        name: _logName,
      );
    }
    
    // Save updated state
    await _saveLearningState();
  } catch (e) {
    developer.log('Error training model: $e', name: _logName);
  }
}

Future<List<Map<String, dynamic>>> _collectRecentInteractions({int limit = 100}) async {
  try {
    final supabase = Supabase.instance.client;
    final agentId = await _agentIdService.getUserAgentId(userId);
    
    final events = await supabase
        .from('interaction_events')
        .select('*')
        .eq('agent_id', agentId)
        .order('timestamp', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(events);
  } catch (e) {
    developer.log('Error collecting recent interactions: $e', name: _logName);
    return [];
  }
}

Future<Map<String, double>> _calculateDimensionUpdates(Map<String, dynamic> event) async {
  // Reuse logic from processUserInteraction()
  // This is a helper to calculate updates without applying them
  final payload = {
    'event_type': event['event_type'],
    'parameters': event['parameters'] ?? {},
    'context': event['context'] ?? {},
  };
  
  // Calculate updates (same logic as processUserInteraction)
  // Return map of dimension → update value
  return {}; // Simplified - full implementation in processUserInteraction
}
```

#### **2.3: Implement updateModelRealtime()**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)
- `lib/core/ai/personality_learning.dart` (UPDATE - feed back to PersonalityProfile)

**Implementation:**

```dart
Future<void> updateModelRealtime(Map<String, dynamic> payload) async {
  try {
    // Get current PersonalityProfile
    final personalityService = GetIt.instance<PersonalityLearning>();
    final currentProfile = await personalityService.getPersonalityProfile(agentId);
    
    if (currentProfile == null) {
      developer.log('No personality profile found for realtime update', name: _logName);
      return;
    }
    
    // Map learning state to personality dimensions
    final dimensionMap = {
      'user_preference_understanding': 'exploration_eagerness',
      'location_intelligence': 'location_adventurousness',
      'temporal_patterns': 'temporal_flexibility',
      'social_dynamics': 'community_orientation',
      'community_evolution': 'community_orientation',
      'recommendation_accuracy': 'trust_network_reliance',
      'personalization_depth': 'authenticity_preference',
    };
    
    // Update personality dimensions based on learning state
    final updatedDimensions = Map<String, double>.from(currentProfile.dimensions);
    for (final entry in _currentLearningState.entries) {
      final personalityDim = dimensionMap[entry.key];
      if (personalityDim != null) {
        // Blend: 70% current, 30% learning update
        final current = updatedDimensions[personalityDim] ?? 0.5;
        final learning = entry.value;
        final blended = (current * 0.7) + (learning * 0.3);
        updatedDimensions[personalityDim] = blended.clamp(0.0, 1.0);
      }
    }
    
    // Update PersonalityProfile
    final updatedProfile = PersonalityProfile(
      agentId: currentProfile.agentId,
      dimensions: updatedDimensions,
      archetype: currentProfile.archetype, // May update based on dimension changes
      authenticity: currentProfile.authenticity,
      createdAt: currentProfile.createdAt,
      updatedAt: DateTime.now(),
    );
    
    // Save updated profile
    await personalityService.updatePersonalityProfile(updatedProfile);
    
    developer.log(
      'Updated PersonalityProfile with ${_currentLearningState.length} learning dimensions',
      name: _logName,
    );
  } catch (e) {
    developer.log('Error updating model realtime: $e', name: _logName);
  }
}
```

**Deliverables:**
- ✅ `processUserInteraction()` fully implemented
- ✅ `trainModel()` fully implemented
- ✅ `updateModelRealtime()` fully implemented
- ✅ Integration with PersonalityProfile
- ✅ Real-time dimension updates from interactions

---

### **Phase 3: Layered Inference Path (Week 3-4)**

**Goal:** Implement ONNX orchestrator for device-first inference, with Gemini fallback for complex reasoning.

#### **3.1: InferenceOrchestrator Implementation**

**Files:**
- `lib/core/ml/inference_orchestrator.dart` (NEW)
- `lib/core/ml/onnx_dimension_scorer.dart` (NEW)
- `lib/injection_container.dart` (UPDATE - re-enable ONNX)

**Implementation:**

```dart
// lib/core/ml/inference_orchestrator.dart
class InferenceOrchestrator {
  final OnnxDimensionScorer? onnxScorer;
  final LLMService llmService;
  final ConfigService config;
  
  InferenceOrchestrator({
    this.onnxScorer,
    required this.llmService,
    required this.config,
  });
  
  /// Orchestrates inference based on strategy
  Future<InferenceResult> infer({
    required Map<String, dynamic> input,
    required InferenceStrategy strategy,
  }) async {
    switch (strategy) {
      case InferenceStrategy.deviceFirst:
        return await _deviceFirstInference(input);
      case InferenceStrategy.edgePrefetch:
        return await _edgePrefetchInference(input);
      case InferenceStrategy.cloudOnly:
        return await _cloudOnlyInference(input);
    }
  }
  
  /// Device-first: ONNX for dimension math, Gemini for reasoning
  Future<InferenceResult> _deviceFirstInference(Map<String, dynamic> input) async {
    try {
      // Step 1: ONNX dimension scoring (privacy-sensitive, fast)
      Map<String, double> dimensionScores = {};
      if (onnxScorer != null) {
        dimensionScores = await onnxScorer!.scoreDimensions(input);
      } else {
        // Fallback to rule-based scoring
        dimensionScores = _ruleBasedDimensionScoring(input);
      }
      
      // Step 2: Check if Gemini expansion needed
      final needsExpansion = _needsGeminiExpansion(input, dimensionScores);
      
      if (needsExpansion) {
        // Step 3: Prepare structured context for Gemini
        final structuredContext = _prepareStructuredContext(input, dimensionScores);
        
        // Step 4: Call Gemini with distilled context
        final geminiResponse = await llmService.chat(
          messages: [
            {
              'role': 'system',
              'content': 'You are a helpful assistant for SPOTS. Use the provided dimension scores and context to provide recommendations.',
            },
            {
              'role': 'user',
              'content': _buildPrompt(input, structuredContext),
            },
          ],
          context: structuredContext,
        );
        
        return InferenceResult(
          dimensionScores: dimensionScores,
          reasoning: geminiResponse,
          source: InferenceSource.hybrid, // ONNX + Gemini
        );
      } else {
        // ONNX-only result
        return InferenceResult(
          dimensionScores: dimensionScores,
          reasoning: null,
          source: InferenceSource.device, // ONNX only
        );
      }
    } catch (e) {
      // Fallback to cloud-only
      return await _cloudOnlyInference(input);
    }
  }
  
  bool _needsGeminiExpansion(Map<String, dynamic> input, Map<String, double> scores) {
    // Heuristics for when to use Gemini:
    // 1. Complex query (natural language, multiple intents)
    // 2. Low confidence scores (need reasoning)
    // 3. User explicitly requests narrative/explanation
    // 4. Context requires social/community insights
    
    final query = input['query'] as String? ?? '';
    final hasComplexQuery = query.length > 50 || query.contains('?');
    final hasLowConfidence = scores.values.any((s) => s < 0.3);
    final needsNarrative = input['needs_narrative'] as bool? ?? false;
    
    return hasComplexQuery || hasLowConfidence || needsNarrative;
  }
  
  Map<String, dynamic> _prepareStructuredContext(
    Map<String, dynamic> input,
    Map<String, double> scores,
  ) {
    // Convert to structured facts for Gemini
    return {
      'dimension_scores': scores,
      'traits': _scoresToTraits(scores),
      'places': input['places'] ?? [],
      'social_graph': input['social_graph'] ?? [],
      'onboarding_data': input['onboarding_data'] ?? {},
    };
  }
  
  List<String> _scoresToTraits(Map<String, double> scores) {
    final traits = <String>[];
    if (scores['exploration_eagerness'] ?? 0.0 > 0.7) traits.add('explorer');
    if (scores['community_orientation'] ?? 0.0 > 0.7) traits.add('community-focused');
    if (scores['location_adventurousness'] ?? 0.0 > 0.7) traits.add('adventurous');
    // ... more trait mappings
    return traits;
  }
  
  String _buildPrompt(Map<String, dynamic> input, Map<String, dynamic> context) {
    final query = input['query'] as String? ?? '';
    final traits = (context['traits'] as List?)?.join(', ') ?? '';
    
    return '''
User query: $query
User traits: $traits
Dimension scores: ${context['dimension_scores']}
Context: ${context}

Provide a helpful recommendation based on this context.
''';
  }
  
  Map<String, double> _ruleBasedDimensionScoring(Map<String, dynamic> input) {
    // Fallback rule-based scoring when ONNX unavailable
    // This is the existing logic from PersonalityLearning
    return {};
  }
  
  Future<InferenceResult> _edgePrefetchInference(Map<String, dynamic> input) async {
    // Similar to device-first but prefetches from edge
    // Implementation similar to device-first
    return await _deviceFirstInference(input);
  }
  
  Future<InferenceResult> _cloudOnlyInference(Map<String, dynamic> input) async {
    // Pure cloud inference (current implementation)
    final response = await llmService.chat(
      messages: [
        {
          'role': 'user',
          'content': input['query'] as String? ?? '',
        },
      ],
    );
    
    return InferenceResult(
      dimensionScores: {},
      reasoning: response,
      source: InferenceSource.cloud,
    );
  }
}

enum InferenceStrategy {
  deviceFirst, // ONNX for math, Gemini for reasoning
  edgePrefetch, // Edge cache + device
  cloudOnly, // Pure cloud (fallback)
}

enum InferenceSource {
  device, // ONNX only
  hybrid, // ONNX + Gemini
  cloud, // Cloud only
}

class InferenceResult {
  final Map<String, double> dimensionScores;
  final String? reasoning;
  final InferenceSource source;
  
  InferenceResult({
    required this.dimensionScores,
    this.reasoning,
    required this.source,
  });
}
```

#### **3.2: ONNX Dimension Scorer**

**Files:**
- `lib/core/ml/onnx_dimension_scorer.dart` (NEW)

**Implementation:**

```dart
// lib/core/ml/onnx_dimension_scorer.dart
class OnnxDimensionScorer {
  // ONNX runtime instance
  // Model loading
  // Dimension scoring logic
  
  /// Scores personality dimensions from onboarding inputs
  Future<Map<String, double>> scoreDimensions(Map<String, dynamic> input) async {
    // Map onboarding inputs → dimension scores
    // Use ONNX model for fast, privacy-sensitive scoring
    // Returns dimension scores (0.0-1.0)
    return {};
  }
  
  /// Enforces safety heuristics
  bool validateScores(Map<String, double> scores) {
    // Check for extreme values
    // Validate dimension ranges
    // Return true if safe
    return true;
  }
}
```

**Deliverables:**
- ✅ InferenceOrchestrator implementation
- ✅ ONNX dimension scorer
- ✅ Device-first strategy logic
- ✅ Integration with LLMService
- ✅ Re-enable ONNX in injection_container.dart

---

### **Phase 4: Supabase Edge Mesh (Week 4-5)**

**Goal:** Create small, focused edge functions for onboarding aggregation, social enrichment, and LLM generation.

#### **4.1: Onboarding Aggregation Function**

**Files:**
- `supabase/functions/onboarding-aggregation/index.ts` (NEW)

**Implementation:**

```typescript
// supabase/functions/onboarding-aggregation/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { agentId, onboardingData } = await req.json()
    
    // Aggregate onboarding data
    const aggregated = {
      age: onboardingData.age,
      homebase: onboardingData.homebase,
      favoritePlaces: onboardingData.favoritePlaces?.length ?? 0,
      preferences: onboardingData.preferences,
      baselineLists: onboardingData.baselineLists?.length ?? 0,
      respectedFriends: onboardingData.respectedFriends?.length ?? 0,
      socialMediaConnected: onboardingData.socialMediaConnected || [],
    }
    
    // Map to dimensions (rule-based)
    const dimensions = mapOnboardingToDimensions(aggregated)
    
    // Store aggregated data
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    await supabase
      .from('onboarding_aggregations')
      .upsert({
        agent_id: agentId,
        aggregated_data: aggregated,
        dimensions: dimensions,
        updated_at: new Date().toISOString(),
      })
    
    return new Response(JSON.stringify({ success: true, dimensions }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

function mapOnboardingToDimensions(aggregated: any) {
  // Rule-based mapping: onboarding → dimensions
  // Similar to PersonalityLearning logic
  return {}
}
```

#### **4.2: Social Data Enrichment Function**

**Files:**
- `supabase/functions/social-enrichment/index.ts` (NEW)

**Implementation:**

```typescript
// supabase/functions/social-enrichment/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const { agentId } = await req.json()
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    // Query social data
    const respects = await supabase
      .from('user_respects')
      .select('*, spots(*), lists(*)')
      .eq('user_id', userId)
      .limit(50)
    
    const follows = await supabase
      .from('user_follows')
      .select('*, followed_user:users(*)')
      .eq('follower_id', userId)
      .limit(50)
    
    // Enrich with insights
    const insights = {
      respectPatterns: analyzeRespectPatterns(respects.data),
      followNetwork: analyzeFollowNetwork(follows.data),
      socialInfluence: calculateSocialInfluence(respects.data, follows.data),
    }
    
    return new Response(JSON.stringify({ insights }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

function analyzeRespectPatterns(respects: any[]) {
  // Analyze what user respects (categories, types, etc.)
  return {}
}

function analyzeFollowNetwork(follows: any[]) {
  // Analyze follow network structure
  return {}
}

function calculateSocialInfluence(respects: any[], follows: any[]) {
  // Calculate social influence metrics
  return {}
}
```

#### **4.3: LLM Generation Function with Context**

**Files:**
- `supabase/functions/llm-generation/index.ts` (NEW - or update existing)

**Implementation:**

```typescript
// supabase/functions/llm-generation/index.ts
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

serve(async (req) => {
  try {
    const { 
      query, 
      structuredContext, // From retrieval layer
      dimensionScores, // From ONNX/device
      personalityProfile, // From PersonalityProfile
    } = await req.json()
    
    // Call Gemini with distilled context
    const response = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': Deno.env.get('GEMINI_API_KEY')!,
      },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: buildPrompt(query, structuredContext, dimensionScores, personalityProfile),
          }],
        }],
      }),
    })
    
    const data = await response.json()
    const generatedText = data.candidates[0].content.parts[0].text
    
    // Publish back to client via Supabase Realtime
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )
    
    await supabase
      .from('llm_responses')
      .insert({
        agent_id: structuredContext.agentId,
        query: query,
        response: generatedText,
        created_at: new Date().toISOString(),
      })
    
    return new Response(JSON.stringify({ response: generatedText }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 })
  }
})

function buildPrompt(
  query: string,
  structuredContext: any,
  dimensionScores: any,
  personalityProfile: any,
) {
  return `
User query: ${query}

Structured context:
- Traits: ${structuredContext.traits?.join(', ')}
- Places: ${structuredContext.places?.length || 0} places
- Social graph: ${structuredContext.social_graph?.length || 0} connections

Dimension scores: ${JSON.stringify(dimensionScores)}
Personality profile: ${JSON.stringify(personalityProfile)}

Provide a helpful recommendation based on this context.
`
}
```

#### **4.4: Realtime Event Triggers**

**Files:**
- `supabase/functions/onboarding-aggregation/index.ts` (UPDATE - add trigger)
- Database triggers (NEW)

**Implementation:**

```sql
-- Trigger: When OnboardingDataService saves, trigger edge function
CREATE OR REPLACE FUNCTION trigger_onboarding_aggregation()
RETURNS TRIGGER AS $$
BEGIN
  -- Call edge function via HTTP (or use pg_net extension)
  PERFORM net.http_post(
    url := current_setting('app.edge_function_url') || '/onboarding-aggregation',
    body := jsonb_build_object(
      'agent_id', NEW.agent_id,
      'onboarding_data', NEW.data
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER onboarding_saved_trigger
  AFTER INSERT OR UPDATE ON onboarding_data
  FOR EACH ROW
  EXECUTE FUNCTION trigger_onboarding_aggregation();
```

**Deliverables:**
- ✅ Onboarding aggregation edge function
- ✅ Social enrichment edge function
- ✅ LLM generation function with structured context
- ✅ Realtime event triggers
- ✅ Integration with OnboardingDataService

---

### **Phase 5: Retrieval + LLM Fusion (Week 5-6)**

**Goal:** Build deterministic layer that converts interactions into structured facts, indexes them, and feeds distilled context to Gemini.

#### **5.1: Structured Facts Layer**

**Files:**
- `lib/core/ai/structured_facts_extractor.dart` (NEW)
- `lib/core/ai/facts_index.dart` (NEW)

**Implementation:**

```dart
// lib/core/ai/structured_facts_extractor.dart
class StructuredFactsExtractor {
  /// Extracts structured facts from interactions
  Future<StructuredFacts> extractFacts(List<InteractionEvent> events) async {
    final traits = <String>[];
    final places = <String>[];
    final socialGraph = <String>[];
    
    for (final event in events) {
      switch (event.eventType) {
        case 'respect_tap':
          final targetType = event.parameters['target_type'];
          if (targetType == 'list') {
            final category = event.parameters['category'];
            if (category != null) traits.add('prefers_$category');
          }
          break;
          
        case 'spot_visited':
          final spotId = event.parameters['spot_id'];
          if (spotId != null) places.add(spotId);
          break;
          
        case 'event_attended':
          final eventId = event.parameters['event_id'];
          if (eventId != null) socialGraph.add('attended_$eventId');
          break;
      }
    }
    
    return StructuredFacts(
      traits: traits,
      places: places,
      socialGraph: socialGraph,
      timestamp: DateTime.now(),
    );
  }
}

class StructuredFacts {
  final List<String> traits;
  final List<String> places;
  final List<String> socialGraph;
  final DateTime timestamp;
  
  StructuredFacts({
    required this.traits,
    required this.places,
    required this.socialGraph,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'traits': traits,
    'places': places,
    'social_graph': socialGraph,
    'timestamp': timestamp.toIso8601String(),
  };
}
```

#### **5.2: Facts Indexing**

**Files:**
- `lib/core/ai/facts_index.dart` (NEW)

**Implementation:**

```dart
// lib/core/ai/facts_index.dart
class FactsIndex {
  final SupabaseClient supabase;
  
  /// Index structured facts in Supabase/Postgres
  Future<void> indexFacts(String agentId, StructuredFacts facts) async {
    await supabase
        .from('structured_facts')
        .upsert({
          'agent_id': agentId,
          'traits': facts.traits,
          'places': facts.places,
          'social_graph': facts.socialGraph,
          'timestamp': facts.timestamp.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
  }
  
  /// Retrieve indexed facts for LLM context
  Future<StructuredFacts> retrieveFacts(String agentId) async {
    final result = await supabase
        .from('structured_facts')
        .select('*')
        .eq('agent_id', agentId)
        .order('updated_at', ascending: false)
        .limit(1)
        .single();
    
    return StructuredFacts(
      traits: List<String>.from(result['traits'] ?? []),
      places: List<String>.from(result['places'] ?? []),
      socialGraph: List<String>.from(result['social_graph'] ?? []),
      timestamp: DateTime.parse(result['timestamp']),
    );
  }
}
```

#### **5.3: LLM Context Preparation**

**Files:**
- `lib/core/services/llm_service.dart` (UPDATE)

**Implementation:**

```dart
// Update LLMService to use structured facts
Future<String> generateWithContext({
  required String query,
  required String agentId,
}) async {
  // Step 1: Retrieve structured facts
  final factsIndex = FactsIndex(supabase);
  final facts = await factsIndex.retrieveFacts(agentId);
  
  // Step 2: Get dimension scores (from ONNX or PersonalityProfile)
  final personalityService = GetIt.instance<PersonalityLearning>();
  final profile = await personalityService.getPersonalityProfile(agentId);
  final dimensionScores = profile?.dimensions ?? {};
  
  // Step 3: Prepare distilled context
  final context = {
    'traits': facts.traits,
    'places': facts.places,
    'social_graph': facts.socialGraph,
    'dimension_scores': dimensionScores,
  };
  
  // Step 4: Call Gemini with distilled context
  return await chat(
    messages: [
      {
        'role': 'user',
        'content': query,
      },
    ],
    context: context,
  );
}
```

**Deliverables:**
- ✅ Structured facts extractor
- ✅ Facts indexing system
- ✅ LLM context preparation
- ✅ Integration with LLMService
- ✅ Database schema for structured_facts

---

### **Phase 6: Federated Learning Enhancements (Week 6-7)**

**Goal:** Use AI2AI hooks to collect anonymized embedding deltas for on-device personalization.

#### **6.1: AI2AI Embedding Delta Collection**

**Files:**
- `lib/core/ai2ai/embedding_delta_collector.dart` (NEW)
- `lib/core/ai2ai/federated_learning_hooks.dart` (NEW)

**Implementation:**

```dart
// lib/core/ai2ai/embedding_delta_collector.dart
class EmbeddingDeltaCollector {
  /// Collects anonymized embedding deltas from AI2AI connections
  Future<List<EmbeddingDelta>> collectDeltas() async {
    // Get recent AI2AI connections
    final connections = await _getRecentAI2AIConnections();
    
    final deltas = <EmbeddingDelta>[];
    for (final connection in connections) {
      // Calculate embedding delta (anonymized)
      final delta = await _calculateDelta(connection);
      if (delta != null) {
        deltas.add(delta);
      }
    }
    
    return deltas;
  }
  
  Future<EmbeddingDelta?> _calculateDelta(AI2AIConnection connection) async {
    // Calculate difference between personalities
    // Anonymize (remove personal identifiers)
    // Return delta if significant
    return null; // Simplified
  }
}

class EmbeddingDelta {
  final List<double> delta; // Anonymized embedding difference
  final DateTime timestamp;
  final String? category; // Optional category (e.g., "coffee_preference")
  
  EmbeddingDelta({
    required this.delta,
    required this.timestamp,
    this.category,
  });
}
```

#### **6.2: On-Device Model Updates**

**Files:**
- `lib/core/ml/onnx_dimension_scorer.dart` (UPDATE)

**Implementation:**

```dart
// Update ONNX model with federated deltas
Future<void> updateWithDeltas(List<EmbeddingDelta> deltas) async {
  // Apply deltas to on-device model
  // Keep personalization fresh even offline
  // Lightweight update (not full retraining)
}
```

#### **6.3: Edge Sync**

**Files:**
- `supabase/functions/federated-sync/index.ts` (NEW)

**Implementation:**

```typescript
// Sync federated updates to edge functions
// Aggregate deltas from multiple agents
// Update cloud models
```

**Deliverables:**
- ✅ Embedding delta collector
- ✅ AI2AI hooks integration
- ✅ On-device model updates
- ✅ Edge sync function
- ✅ Privacy-preserving anonymization

---

### **Phase 7: Decision Fabric (Week 7-8)**

**Goal:** Coordinator service that chooses optimal pathway in real-time.

#### **7.1: Decision Coordinator**

**Files:**
- `lib/core/ai/decision_coordinator.dart` (NEW)

**Implementation:**

```dart
// lib/core/ai/decision_coordinator.dart
class DecisionCoordinator {
  final InferenceOrchestrator orchestrator;
  final ConnectivityService connectivity;
  final ConfigService config;
  
  /// Chooses optimal inference pathway
  Future<InferenceResult> coordinate({
    required Map<String, dynamic> input,
    required InferenceContext context,
  }) async {
    // Decision logic:
    // 1. Offline? → ONNX + Rules
    // 2. Online but latency critical? → Local scores + Cached recommendations
    // 3. Need rich narrative? → Gemini through LLM service
    // 4. Need social/community insights? → Edge functions
    
    final isOffline = !await connectivity.isConnected();
    final needsNarrative = context.needsNarrative;
    final latencyCritical = context.latencyCritical;
    final needsSocialInsights = context.needsSocialInsights;
    
    if (isOffline) {
      // Offline: Stick to ONNX + rules
      return await orchestrator.infer(
        input: input,
        strategy: InferenceStrategy.deviceFirst,
      );
    } else if (latencyCritical) {
      // Latency critical: Local scores + cached
      return await _getCachedRecommendations(input);
    } else if (needsNarrative || needsSocialInsights) {
      // Rich narrative or social insights: Gemini/Edge
      return await orchestrator.infer(
        input: input,
        strategy: InferenceStrategy.edgePrefetch,
      );
    } else {
      // Default: Device-first with Gemini fallback
      return await orchestrator.infer(
        input: input,
        strategy: InferenceStrategy.deviceFirst,
      );
    }
  }
  
  Future<InferenceResult> _getCachedRecommendations(Map<String, dynamic> input) async {
    // Get cached recommendations from local storage
    // Return immediately for low latency
    return InferenceResult(
      dimensionScores: {},
      reasoning: null,
      source: InferenceSource.device,
    );
  }
}

class InferenceContext {
  final bool needsNarrative;
  final bool latencyCritical;
  final bool needsSocialInsights;
  final Map<String, dynamic>? userContext;
  
  InferenceContext({
    this.needsNarrative = false,
    this.latencyCritical = false,
    this.needsSocialInsights = false,
    this.userContext,
  });
}
```

**Deliverables:**
- ✅ Decision coordinator implementation
- ✅ Pathway selection logic
- ✅ Integration with all inference layers
- ✅ Caching strategy
- ✅ Context-aware routing

---

### **Phase 8: AI2AI Mesh Integration & Learning Loop Closure (Week 8)**

**Goal:** Integrate AI2AI mesh learning, conversation analysis, and real-time ONNX updates to close all learning loops.

#### **8.0: Cross-Platform LLM Communication Architecture (Phase 11 Enhancement)**

**Purpose:** Explain how different on-device LLMs on Android and iOS can communicate through the AI2AI mesh despite using different models.

**Problem Statement:**
- Android devices use platform-specific LLMs (e.g., llama.cpp, Gemma)
- iOS devices use different LLMs (e.g., CoreML models, Phi, Mistral)
- Different LLMs produce different token sequences and embeddings
- AI2AI mesh needs standardized communication protocol

**Solution Architecture:**

The AI2AI mesh doesn't communicate raw LLM outputs. Instead, it uses standardized abstraction layers that work across platforms:

```
┌─────────────────────────────────────────────────────────────┐
│ Platform-Specific LLM Layer (Different per platform)       │
├─────────────────────────────────────────────────────────────┤
│ Android: llama.cpp / Gemma                                  │
│ iOS: CoreML / Phi / Mistral                                 │
│ • Different tokenizers, vocabularies, embeddings            │
│ • Platform-optimized for performance                        │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ Standardized Personality Abstraction Layer                  │
├─────────────────────────────────────────────────────────────┤
│ • Converts LLM outputs → Personality Dimension Scores       │
│ • Platform-agnostic dimension embeddings                    │
│ • Standardized data structures (PersonalityProfile)         │
│ • Works identically on Android and iOS                      │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ ONNX Dimension Scoring Layer (Standardized)                 │
├─────────────────────────────────────────────────────────────┤
│ • ONNX models work on both Android and iOS                  │
│ • Standardized dimension scores (0.0-1.0 range)            │
│ • Platform-agnostic embeddings                              │
│ • Consistent scoring logic across platforms                 │
└─────────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ AI2AI Mesh Communication Layer                              │
├─────────────────────────────────────────────────────────────┤
│ • Exchanges PersonalityProfile objects                      │
│ • Exchanges EmbeddingDelta objects                          │
│ • Standardized JSON/binary format                           │
│ • Platform-independent protocol                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Components:**

##### **1. Personality Abstraction Layer**

The personality learning system abstracts away LLM differences by converting platform-specific LLM outputs into standardized personality dimensions:

```dart
// Platform-specific LLM outputs → Standardized personality dimensions
PersonalityProfile {
  dimensions: {
    'exploration_eagerness': 0.75,    // Standardized score (0.0-1.0)
    'community_orientation': 0.60,    // Platform-agnostic
    'temporal_flexibility': 0.55,     // Works on both platforms
    // ... 12 dimensions total (standardized)
  },
  dimensionConfidence: {
    'exploration_eagerness': 0.85,    // Confidence score
    // ... standardized confidence scores
  }
}
```

**How It Works:**
- Android LLM processes user interactions → Produces platform-specific outputs
- iOS LLM processes same interactions → Produces different platform-specific outputs
- **Both map to same standardized 12-dimensional personality profile**
- Standardized dimensions are what get communicated through the mesh

##### **2. ONNX Standardization Role**

ONNX ensures consistent dimension scoring across platforms:

```dart
// OnnxDimensionScorer works identically on both platforms
class OnnxDimensionScorer {
  // Takes standardized input, produces standardized output
  Future<Map<String, double>> scoreDimensions(Map<String, dynamic> input) async {
    // ONNX model runs identically on Android and iOS
    // Returns standardized dimension scores (0.0-1.0)
    // Platform differences abstracted away
  }
  
  // EmbeddingDelta is platform-agnostic
  Future<void> updateWithDeltas(List<EmbeddingDelta> deltas) async {
    // EmbeddingDelta format works on both platforms
    // ONNX bias updates work identically on both platforms
    // No platform-specific logic needed
  }
}
```

**ONNX Benefits:**
- Same model format works on Android and iOS
- Same dimension scoring logic across platforms
- Same embedding delta processing
- Platform-independent model updates
- Standardized bias adjustments

##### **3. AI2AI Mesh Communication Protocol**

The mesh communicates standardized data structures, not raw LLM outputs:

**Exchanged Data Structures:**

1. **PersonalityProfile Objects:**
   ```dart
   // Standardized format (works on both platforms)
   PersonalityProfile {
     agentId: 'agent_...',
     dimensions: {
       'exploration_eagerness': 0.75,
       // ... standardized 12 dimensions
     },
     dimensionConfidence: {...},
     // ... standardized fields
   }
   ```

2. **EmbeddingDelta Objects:**
   ```dart
   // Platform-agnostic delta format
   EmbeddingDelta {
     delta: [0.05, 0.03, ...],  // Dimension changes (standardized)
     timestamp: DateTime,        // Standardized timestamp
     category: 'dimension_name', // Standardized category
     metadata: {...}             // Standardized metadata
   }
   ```

3. **Anonymized Personality Data:**
   ```dart
   // Standardized anonymized format
   AnonymizedVibeData {
     hashedUserId: '...',
     anonymizedDimensions: {
       'exploration_eagerness': 0.75,  // Standardized score
       // ... standardized dimensions
     }
   }
   ```

**Communication Flow:**

```
Android Device (LLM: llama.cpp)
    ↓
    Converts LLM outputs → PersonalityProfile (standardized)
    ↓
    Exchanges PersonalityProfile via Bluetooth mesh
    ↓
iOS Device (LLM: CoreML)
    ↓
    Receives PersonalityProfile (standardized format)
    ↓
    Applies to local PersonalityProfile
    ↓
    Updates ONNX biases (standardized)
    ↓
    Converts to local LLM context (platform-specific)
```

**Key Points:**

✅ **Abstraction Layer**: LLM differences are abstracted away by the personality learning system
✅ **Standardized Dimensions**: Both platforms use the same 12-dimensional personality model
✅ **ONNX Compatibility**: ONNX provides platform-agnostic dimension scoring
✅ **Mesh Protocol**: AI2AI mesh communicates standardized data structures, not raw LLM outputs
✅ **Platform Independence**: Android and iOS LLMs can be completely different, but mesh communication works seamlessly

**Implementation Files:**
- `lib/core/ai/personality_learning.dart` - Personality abstraction layer
- `lib/core/ml/onnx_dimension_scorer.dart` - ONNX standardization layer
- `packages/avrai_network/lib/network/ai2ai_protocol.dart` - Mesh communication protocol
- `packages/avrai_network/lib/network/personality_data_codec.dart` - Standardized data encoding/decoding

**Related Documentation:**
- `docs/plans/ml_models/ON_DEVICE_MODEL_RECOMMENDATIONS.md` - Platform-specific LLM recommendations
- `lib/core/services/llm_service.dart` - Platform-specific LLM backends
- `docs/plans/llm_integration/LLM_INTEGRATION_ASSESSMENT.md` - LLM integration architecture

---

#### **8.1: AI2AI Mesh → ContinuousLearningSystem Integration**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)
- `lib/core/ai2ai/connection_orchestrator.dart` (UPDATE - hook integration)

**Implementation:**

```dart
// Add to ContinuousLearningSystem
/// Process AI2AI mesh learning insights
/// 
/// Converts AI2AI learning insights into interaction events for processing
/// through the continuous learning pipeline.
/// 
/// Phase 11 Enhancement: AI2AI Mesh Integration
Future<void> processAI2AILearningInsight({
  required String userId,
  required AI2AILearningInsight insight,
  required String peerId,
}) async {
  try {
    developer.log(
      'Processing AI2AI mesh learning insight from peer: $peerId',
      name: _logName,
    );
    
    // Convert AI2AI learning insight to interaction event
    final payload = {
      'event_type': 'ai2ai_learning_insight',
      'source': 'ai2ai',
      'peer_id': peerId,
      'learning_quality': insight.learningQuality,
      'dimension_updates': insight.dimensionInsights,
      'parameters': {
        'insight_type': insight.type.toString(),
        'timestamp': insight.timestamp.toIso8601String(),
      },
      'context': {
        'source': 'ai2ai_mesh',
        'learning_quality': insight.learningQuality,
      },
    };
    
    // Process through existing learning pipeline (includes safeguards)
    await processUserInteraction(
      userId: userId,
      payload: payload,
    );
    
    // Also update ONNX biases directly from mesh insights (real-time)
    await _updateOnnxFromMeshInsight(insight);
  } catch (e, stackTrace) {
    developer.log(
      'Error processing AI2AI learning insight: $e',
      name: _logName,
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Update ONNX biases from AI2AI mesh learning insight (real-time)
/// 
/// Phase 11 Enhancement: Real-time ONNX Updates from Mesh
Future<void> _updateOnnxFromMeshInsight(AI2AILearningInsight insight) async {
  try {
    // Convert AI2AI learning insight to embedding deltas
    final deltas = insight.dimensionInsights.entries.map((entry) {
      return EmbeddingDelta(
        delta: [entry.value],
        timestamp: insight.timestamp,
        category: entry.key,
        metadata: {
          'source': 'ai2ai_mesh',
          'learning_quality': insight.learningQuality,
          'insight_type': insight.type.toString(),
        },
      );
    }).toList();
    
    // Update ONNX scorer directly (non-blocking)
    if (GetIt.instance.isRegistered<OnnxDimensionScorer>()) {
      final onnxScorer = GetIt.instance<OnnxDimensionScorer>();
      await onnxScorer.updateWithDeltas(deltas);
      
      developer.log(
        'Updated ONNX biases from mesh insight: ${deltas.length} dimensions',
        name: _logName,
      );
    }
  } catch (e) {
    developer.log(
      'Error updating ONNX from mesh insight: $e',
      name: _logName,
    );
    // Non-blocking
  }
}
```

**Integration Point:**
- Hook into `ConnectionOrchestrator._maybeApplyPassiveAi2AiLearning()`
- After generating `AI2AILearningInsight`, call `ContinuousLearningSystem.processAI2AILearningInsight()`

**Files to Update:**
- `lib/core/ai2ai/connection_orchestrator.dart:1357` - Add call after generating insight

#### **8.2: Real-time ONNX Updates from Interaction Events**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)
- `lib/core/ml/onnx_dimension_scorer.dart` (no changes needed)

**Implementation:**

```dart
// Add to ContinuousLearningSystem.processUserInteraction()
// After dimension updates are calculated (line ~260):

// Directly update ONNX biases from interaction events (Phase 11 Enhancement)
if (dimensionUpdates.isNotEmpty && source != 'ai2ai') {
  await _updateOnnxBiasesFromInteraction(
    dimensionUpdates: dimensionUpdates,
    context: context,
  );
}

/// Update ONNX biases directly from user interaction events
/// 
/// Phase 11 Enhancement: Real-time ONNX Updates from Interactions
Future<void> _updateOnnxBiasesFromInteraction({
  required Map<String, double> dimensionUpdates,
  required Map<String, dynamic> context,
}) async {
  try {
    // Convert dimension updates to embedding deltas
    final deltas = dimensionUpdates.entries.map((entry) {
      return EmbeddingDelta(
        delta: [entry.value], // Single dimension delta
        timestamp: DateTime.now(),
        category: entry.key, // Dimension name as category
        metadata: {
          'source': 'user_interaction',
          'context': context,
        },
      );
    }).toList();
    
    // Update ONNX scorer with deltas
    if (GetIt.instance.isRegistered<OnnxDimensionScorer>()) {
      final onnxScorer = GetIt.instance<OnnxDimensionScorer>();
      await onnxScorer.updateWithDeltas(deltas);
      
      developer.log(
        'Updated ONNX biases from ${deltas.length} interaction dimensions',
        name: _logName,
      );
    }
  } catch (e) {
    developer.log(
      'Error updating ONNX biases from interaction: $e',
      name: _logName,
    );
    // Non-blocking
  }
}
```

**Benefits:**
- ONNX scorer stays updated from user interactions in real-time
- Faster personalization without waiting for federated sync
- Offline learning reflected in ONNX biases immediately

#### **8.3: Conversation-Based Learning Integration**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)
- `lib/core/ai/ai2ai_learning/orchestrator.dart` (UPDATE - hook integration)

**Implementation:**

```dart
// Add to ContinuousLearningSystem
/// Process AI2AI chat conversation for continuous learning
/// 
/// Converts AI2AI chat analysis results into interaction events for processing
/// through the continuous learning pipeline.
/// 
/// Phase 11 Enhancement: Conversation-Based Learning
Future<void> processAI2AIChatConversation({
  required String userId,
  required AI2AIChatAnalysisResult chatAnalysis,
}) async {
  try {
    // Only process if analysis confidence is sufficient
    if (chatAnalysis.analysisConfidence < 0.6) {
      developer.log(
        'Chat analysis confidence too low: ${chatAnalysis.analysisConfidence}',
        name: _logName,
      );
      return;
    }
    
    // Extract dimension insights from conversation analysis
    final dimensionInsights = chatAnalysis.evolutionRecommendations
        ?.map((rec) => MapEntry(rec.dimension, rec.proposedChange))
        .toMap() ?? {};
    
    if (dimensionInsights.isEmpty) {
      developer.log('No dimension insights from chat conversation', name: _logName);
      return;
    }
    
    // Convert to interaction event format
    final payload = {
      'event_type': 'ai2ai_chat_conversation',
      'source': 'ai2ai_chat',
      'parameters': {
        'chat_type': chatAnalysis.chatEvent.messageType.toString(),
        'analysis_confidence': chatAnalysis.analysisConfidence,
        'shared_insights_count': chatAnalysis.sharedInsights?.length ?? 0,
        'learning_opportunities_count': chatAnalysis.learningOpportunities?.length ?? 0,
      },
      'context': {
        'source': 'ai2ai_chat',
        'conversation_patterns': chatAnalysis.conversationPatterns?.toJson(),
        'trust_metrics': chatAnalysis.trustMetrics?.toJson(),
      },
      'dimension_updates': dimensionInsights,
    };
    
    // Process through learning pipeline
    await processUserInteraction(
      userId: userId,
      payload: payload,
    );
    
    developer.log(
      'Processed AI2AI chat conversation: ${dimensionInsights.length} dimensions updated',
      name: _logName,
    );
  } catch (e, stackTrace) {
    developer.log(
      'Error processing AI2AI chat conversation: $e',
      name: _logName,
      error: e,
      stackTrace: stackTrace,
    );
  }
}
```

**Integration Point:**
- Hook into `AI2AILearningOrchestrator.analyzeChatConversation()`
- After analysis, if confidence >= 0.6, call `ContinuousLearningSystem.processAI2AIChatConversation()`

**Files to Update:**
- `lib/core/ai/ai2ai_learning/orchestrator.dart:146` - Add call after analysis

#### **8.4: Offline Mesh Learning Integration**

**Files:**
- `lib/core/ai/decision_coordinator.dart` (UPDATE)

**Implementation:**

```dart
// Enhance DecisionCoordinator.coordinate()
Future<InferenceResult> coordinate({
  required Map<String, dynamic> input,
  required InferenceContext context,
}) async {
  // ... existing connectivity check ...
  
  if (isOffline) {
    // Offline: Use ONNX + Rules + AI2AI Mesh Learning
    chosenStrategy = InferenceStrategy.deviceFirst;
    decisionReason = 'Offline: Using device-first + AI2AI mesh learning';
    developer.log(decisionReason, name: _logName);
    
    // Phase 11 Enhancement: Get AI2AI mesh learning insights (works offline via Bluetooth)
    final meshInsights = await _getOfflineMeshInsights(input);
    if (meshInsights.isNotEmpty) {
      // Enhance input with mesh learning context
      input = {
        ...input,
        'ai2ai_mesh_insights': meshInsights,
        'source': 'offline_mesh',
      };
      
      developer.log(
        'Enhanced input with ${meshInsights.length} offline mesh insights',
        name: _logName,
      );
    }
    
    // Offline: Stick to ONNX + rules + mesh insights
    result = await orchestrator.infer(
      input: input,
      strategy: chosenStrategy,
    );
  }
  // ... rest of existing logic ...
}

/// Get offline mesh learning insights from AI2AI connections
/// 
/// Phase 11 Enhancement: Offline Mesh Learning
/// This works offline because AI2AI mesh uses Bluetooth
Future<List<Map<String, dynamic>>> _getOfflineMeshInsights(
  Map<String, dynamic> input,
) async {
  try {
    // Try to get recent passive learning insights from ConnectionOrchestrator
    // Note: This requires exposing passive learning insights through orchestrator API
    // For now, return empty list (implementation depends on ConnectionOrchestrator API)
    
    // TODO(Phase 11.8): Implement ConnectionOrchestrator.getRecentMeshInsights()
    // This would return recent AI2AILearningInsight objects from passive learning
    
    return [];
  } catch (e) {
    developer.log('Error getting offline mesh insights: $e', name: _logName);
    return [];
  }
}
```

**Benefits:**
- Offline learning from nearby devices via Bluetooth mesh
- Continuous improvement without internet connection
- Better recommendations in offline scenarios

#### **8.5: Complete Interaction → Mesh → ONNX Pipeline**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE)
- `lib/core/ai2ai/connection_orchestrator.dart` (UPDATE - propagation hook)

**Implementation:**

```dart
// Add to ContinuousLearningSystem.processUserInteraction()
// After processing interaction (line ~318):

// Phase 11 Enhancement: Propagate significant learning through mesh
if (dimensionUpdates.isNotEmpty && source != 'ai2ai') {
  await _propagateLearningToMesh(
    userId: userId,
    dimensionUpdates: dimensionUpdates,
    context: context,
  );
}

/// Propagate learning insights to AI2AI mesh for collective learning
/// 
/// Phase 11 Enhancement: Complete Learning Pipeline
/// Sends significant dimension updates to mesh for propagation to nearby devices
Future<void> _propagateLearningToMesh({
  required String userId,
  required Map<String, double> dimensionUpdates,
  required Map<String, dynamic> context,
}) async {
  try {
    // Only propagate if updates are significant (22% threshold)
    final significantUpdates = dimensionUpdates.entries
        .where((entry) => entry.value.abs() >= 0.22)
        .toMap();
    
    if (significantUpdates.isEmpty) {
      developer.log(
        'No significant dimension updates to propagate to mesh',
        name: _logName,
      );
      return;
    }
    
    // Create AI2AI learning insight for mesh propagation
    final insight = AI2AILearningInsight(
      type: AI2AIInsightType.dimensionDiscovery,
      dimensionInsights: significantUpdates,
      learningQuality: 0.8, // High quality for direct user interactions
      timestamp: DateTime.now(),
    );
    
    // Propagate through mesh (via ConnectionOrchestrator)
    // Note: This requires ConnectionOrchestrator API for sending insights
    // TODO(Phase 11.8): Implement ConnectionOrchestrator.propagateLearningInsight()
    
    developer.log(
      'Prepared ${significantUpdates.length} dimension updates for mesh propagation',
      name: _logName,
    );
  } catch (e) {
    developer.log(
      'Error propagating learning to mesh: $e',
      name: _logName,
    );
    // Non-blocking
  }
}
```

**Complete Learning Flow:**
```
User Interaction
    ↓
ContinuousLearningSystem.processUserInteraction()
    ↓
Update PersonalityProfile (via PersonalityLearning)
    ↓
Update ONNX Biases (direct, real-time)
    ↓
Propagate to AI2AI Mesh (significant updates only)
    ↓
Mesh → Other Devices → Their ONNX Updates
    ↓
Collective Learning Loop Complete
```

**Deliverables:**
- ✅ AI2AI mesh learning integrated into ContinuousLearningSystem
- ✅ Real-time ONNX updates from interaction events
- ✅ Conversation-based learning integrated
- ✅ Offline mesh learning in DecisionCoordinator
- ✅ Complete interaction → mesh → ONNX pipeline
- ✅ All learning loops closed

---

### **Phase 9: Learning Quality Monitoring (Week 8)**

**Goal:** Implement learning history persistence and analytics dashboards.

#### **9.1: Learning History Persistence**

**Files:**
- `lib/core/ai/continuous_learning_system.dart` (UPDATE - _learningHistory)

**Implementation:**

```dart
// Persist learning history to Supabase
Future<void> _persistLearningHistory() async {
  final supabase = Supabase.instance.client;
  final agentId = await _agentIdService.getUserAgentId(userId);
  
  for (final entry in _learningHistory.entries) {
    final dimension = entry.key;
    final events = entry.value;
    
    // Store recent events
    for (final event in events.take(10)) {
      await supabase.from('learning_history').insert({
        'agent_id': agentId,
        'dimension': dimension,
        'improvement': event.improvement,
        'data_source': event.dataSource,
        'timestamp': event.timestamp.toIso8601String(),
      });
    }
  }
}
```

#### **8.2: Analytics Dashboard**

**Files:**
- `lib/presentation/pages/admin/learning_analytics_page.dart` (NEW)

**Implementation:**

```dart
// Dashboard to visualize learning quality
// Show dimension improvements over time
// Detect when interactions fail to improve metrics
// Suggest which signals to capture next
```

**Deliverables:**
- ✅ Learning history persistence
- ✅ Analytics dashboard
- ✅ Quality metrics tracking
- ✅ Feedback loop for signal optimization

---

## 🔄 **INTEGRATION POINTS**

### **1. OnboardingDataService → Edge Functions**

When `OnboardingDataService.saveOnboardingData()` is called:
1. Save to Sembast (existing)
2. Trigger Supabase Realtime event
3. Edge function `onboarding-aggregation` processes data
4. Publishes aggregated dimensions back to client

### **2. Interaction Events → Learning System**

When user interacts (respect tap, list view, etc.):
1. Log structured event with context
2. Queue locally (Sembast/Isar)
3. Process via `ContinuousLearningSystem.processUserInteraction()`
4. Update dimensions in real-time
5. Sync to Supabase when online

### **3. Learning System → PersonalityProfile**

When dimensions update:
1. `updateModelRealtime()` called
2. Map learning dimensions → personality dimensions
3. Update PersonalityProfile
4. Feed back into agent generation pipeline

### **4. Inference Orchestrator → All Layers**

When inference needed:
1. DecisionCoordinator chooses pathway
2. InferenceOrchestrator routes to appropriate layer
3. ONNX for dimension math (device)
4. Gemini for reasoning (cloud)
5. Edge functions for social/community enrichment

---

## 📊 **SUCCESS METRICS**

### **Technical Metrics:**
- ✅ Zero linter errors
- ✅ All tests passing
- ✅ <100ms on-device inference latency
- ✅ <2s cloud inference latency (with Gemini)
- ✅ 100% offline functionality for dimension scoring

### **Learning Metrics:**
- ✅ Dimension weights update within 1 second of interaction
- ✅ PersonalityProfile reflects learning updates within 5 seconds
- ✅ Learning history persisted for all dimensions
- ✅ Analytics dashboard shows improvement trends

### **User Experience Metrics:**
- ✅ Recommendations improve over time (measured by user feedback)
- ✅ Doors shown match user preferences (measured by respect/visit rates)
- ✅ AI2AI connections improve (measured by connection success rate)
- ✅ Context-aware suggestions (measured by engagement)

---

## 🛡️ **AI2AI LEARNING SAFEGUARDS (Phase 11 Enhancement)**

### **Purpose:**
Prevent AI2AI learning system from "exploding" by enforcing rate limits, quality thresholds, and drift prevention. These safeguards ensure stable, bounded learning that prevents runaway personality convergence, infinite loops, and excessive resource consumption.

### **Safeguards Implemented:**

#### **1. Learning Throttling (20-Minute Interval Per Peer)**
- **Implementation:** `ContinuousLearningSystem._lastAi2AiLearningAtByPeerId` tracks last learning time per peer
- **Threshold:** Minimum 20 minutes between learning updates from the same peer
- **Purpose:** Prevents rapid learning drift from nearby devices
- **Location:** `lib/core/ai/continuous_learning_system.dart:145-161`

#### **2. Learning Quality Thresholds (65% Minimum)**
- **Implementation:** Checks `learningQuality` from payload before processing
- **Threshold:** 65% minimum quality required for AI2AI learning
- **Purpose:** Rejects low-quality learning insights that could cause drift
- **Location:** `lib/core/ai/continuous_learning_system.dart:164-173`, `lib/core/ai2ai/embedding_delta_collector.dart:95-105`

#### **3. Dimension Delta Thresholds (22% Minimum)**
- **Implementation:** Filters out dimension updates below 22% threshold
- **Threshold:** Only applies learning if `abs(delta) >= 0.22` for at least one dimension
- **Purpose:** Only learns from significant personality differences
- **Location:** `lib/core/ai/continuous_learning_system.dart:278-294`, `lib/core/ai2ai/embedding_delta_collector.dart:195-220`

#### **4. Connection Limits (Max 12 Simultaneous)**
- **Implementation:** Respects `VibeConstants.maxSimultaneousConnections = 12`
- **Threshold:** Maximum 12 simultaneous AI2AI connections
- **Cooldown:** 60 seconds between connections to same peer
- **Purpose:** Prevents connection overload and resource exhaustion
- **Location:** `lib/core/ai2ai/embedding_delta_collector.dart:84-96`

#### **5. Drift Prevention (30% Maximum from Original)**
- **Implementation:** Checks personality drift from original profile before applying updates
- **Threshold:** Maximum 30% drift from original personality (contextual layer)
- **Core Personality:** Completely stable (no learning from partners)
- **Purpose:** Prevents personality homogenization and preserves user identity
- **Location:** `lib/core/ai/continuous_learning_system.dart:650-690`, `lib/core/ai/personality_learning.dart:750-780`

#### **6. Rate Limiting (Token Bucket Per Peer)**
- **Implementation:** Integrates `RateLimiter` from `avrai_network` package
- **Configuration:** 10 tokens, 1 token/second refill rate
- **Types:** Separate buckets for handshakes, messages, connections
- **Purpose:** Prevents message flooding and DDoS-like scenarios
- **Location:** `lib/core/ai/continuous_learning_system.dart:175-187`

### **Integration Points:**

#### **ContinuousLearningSystem.processUserInteraction()**
- Checks all safeguards (throttling, quality, rate limiting) before processing AI2AI learning
- Applies dimension delta threshold (22% minimum)
- Records learning time for throttling enforcement
- **Phase 11 Enhancement:** Updates ONNX biases in real-time from interactions
- **Phase 11 Enhancement:** Propagates significant updates to AI2AI mesh

#### **ContinuousLearningSystem.processAI2AILearningInsight()** (NEW)
- **Phase 11 Enhancement:** Processes AI2AI mesh learning insights
- Converts mesh insights to interaction events for pipeline processing
- Updates ONNX biases directly from mesh insights (real-time)

#### **ContinuousLearningSystem.processAI2AIChatConversation()** (NEW)
- **Phase 11 Enhancement:** Processes AI2AI chat conversation analysis
- Extracts dimension insights from conversation patterns
- Integrates conversation-based learning into continuous learning pipeline

#### **EmbeddingDeltaCollector.collectDeltas()**
- Respects connection limits (max 12 simultaneous)
- Checks learning quality threshold (65% minimum) if provided
- Applies dimension delta threshold (22% minimum) per dimension

#### **PersonalityLearning.evolveFromAI2AILearning()**
- Enforces drift prevention (30% max drift from original)
- Clamps dimension updates to drift limits
- Preserves core personality stability

#### **updateModelRealtime()**
- Checks drift limits before updating personality profile
- Clamps dimension values to max drift
- Logs drift violations for monitoring

#### **DecisionCoordinator.coordinate()**
- **Phase 11 Enhancement:** Leverages AI2AI mesh when offline
- Gets offline mesh learning insights for enhanced recommendations
- Works without internet connection via Bluetooth mesh

#### **ConnectionOrchestrator._maybeApplyPassiveAi2AiLearning()**
- **Phase 11 Enhancement:** Calls ContinuousLearningSystem.processAI2AILearningInsight()
- Integrates passive mesh learning into continuous learning pipeline
- Updates ONNX biases in real-time from passive learning

### **References:**
- `lib/core/ai2ai/connection_orchestrator.dart` - Existing safeguard implementation (reference implementation)
- `lib/core/constants/vibe_constants.dart` - Safeguard constants (maxSimultaneousConnections, ai2aiLearningRate, etc.)
- `packages/avrai_network/lib/network/rate_limiter.dart` - Rate limiting implementation
- `lib/core/ai2ai/adaptive_mesh_hop_policy.dart` - Hop limit policies

### **Monitoring & Debugging:**
All safeguard checks log detailed messages for monitoring:
- `AI2AI learning throttled: 20-min interval not met`
- `AI2AI learning rejected: quality below 65% threshold`
- `AI2AI learning rejected: no dimension deltas >= 22% threshold`
- `Drift limit exceeded: clamping to max drift`
- `Connection limit exceeded: limiting to max`

---

## 🚨 **RISKS & MITIGATION**

### **Risk 1: ONNX Model Complexity**
**Risk:** ONNX model may be too complex for on-device inference  
**Mitigation:** Start with simple rule-based scoring, add ONNX incrementally

### **Risk 2: Edge Function Latency**
**Risk:** Edge functions may add latency  
**Mitigation:** Use caching, prefetching, and async processing

### **Risk 3: Learning Loop Overfitting**
**Risk:** Model may overfit to recent interactions  
**Mitigation:** Use learning rates, decay factors, validation, and **AI2AI Learning Safeguards** (throttling, quality thresholds, drift prevention)

### **Risk 4: Privacy Concerns**
**Risk:** User data may be exposed  
**Mitigation:** Use agentId (not userId), anonymize deltas, on-device processing

### **Risk 5: AI2AI System Explosion (NEW - Phase 11 Enhancement)**
**Risk:** Unbounded learning could cause personality drift, infinite loops, or resource exhaustion  
**Mitigation:** Comprehensive safeguards system:
- Learning throttling (20-min interval)
- Quality thresholds (65% minimum)
- Delta thresholds (22% minimum)
- Connection limits (max 12 simultaneous)
- Drift prevention (30% max from original)
- Rate limiting (token bucket per peer)

---

## 📅 **TIMELINE SUMMARY**

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| Phase 1: Event Instrumentation | Week 1-2 | Structured events, schema hooks |
| Phase 2: Learning Loop Closure | Week 2-3 | processUserInteraction, trainModel, updateModelRealtime |
| Phase 3: Layered Inference | Week 3-4 | InferenceOrchestrator, ONNX scorer |
| Phase 4: Edge Mesh | Week 4-5 | Onboarding, social, LLM edge functions |
| Phase 5: Retrieval + LLM Fusion | Week 5-6 | Structured facts, facts index |
| Phase 6: Federated Learning | Week 6-7 | Embedding deltas, on-device updates |
| Phase 7: Decision Fabric | Week 7-8 | Decision coordinator |
| Phase 8: Quality Monitoring | Week 8 | Learning history, analytics dashboard |

**Total:** 6-8 weeks

---

## ✅ **COMPLETION CRITERIA**

- [ ] All event types instrumented with context
- [ ] All schema hooks implemented (social, community, app usage)
- [ ] Learning loop fully closed (events → dimensions → PersonalityProfile)
- [ ] ONNX orchestrator working (device-first strategy)
- [ ] All edge functions deployed and tested
- [ ] Structured facts extraction and indexing working
- [ ] Federated learning hooks integrated
- [ ] Decision coordinator routing correctly
- [ ] **AI2AI mesh learning integrated into ContinuousLearningSystem** (Phase 11 Enhancement)
- [ ] **Real-time ONNX updates from interaction events** (Phase 11 Enhancement)
- [ ] **Conversation-based learning integrated** (Phase 11 Enhancement)
- [ ] **Offline mesh learning in DecisionCoordinator** (Phase 11 Enhancement)
- [ ] **Complete interaction → mesh → ONNX pipeline** (Phase 11 Enhancement)
- [ ] **⚛️ Quantum atomic time integrated throughout all learning systems** (Phase 11 Enhancement - CRITICAL)
  - [ ] InteractionEvent includes atomicTimestamp field
  - [ ] ContinuousLearningSystem uses AtomicClockService for all time operations
  - [ ] PersonalityLearning uses atomic timestamps for drift detection with temporal decay
  - [ ] EventLogger captures atomic timestamps for all events
  - [ ] All throttling checks use atomic time precision
  - [ ] All quantum formulas use atomic timestamps (not DateTime)
- [ ] **Adaptive event instrumentation system implemented** (Phase 11 Enhancement)
  - [ ] EventTypeRegistry system for dynamic event type management
  - [ ] EventLearningAnalyzer for learning-driven event value assessment
  - [ ] ContextLearningAnalyzer for automatic context value identification
  - [ ] Dynamic schema updates based on learning insights
  - [ ] Configuration-based event type registration (no code changes needed)
  - [ ] Automatic event type suggestions based on parameter patterns
  - [ ] Low-value event types automatically disabled
- [ ] Learning history persisted and visualized
- [ ] Zero linter errors
- [ ] All tests passing
- [ ] Documentation complete

---

## 📚 **RELATED DOCUMENTATION**

- `docs/plans/data_sources/DATA_SOURCES_IMPLEMENTATION_COMPLETE.md` - Data source connections
- `docs/plans/llm_integration/LLM_INTEGRATION_ASSESSMENT.md` - LLM integration guide
- `docs/architecture/ONBOARDING_TO_AGENT_GENERATION_FLOW.md` - Onboarding pipeline
- `lib/core/ai/continuous_learning_system.dart` - Current implementation
- `docs/plans/philosophy_implementation/SPOTS_PHILOSOPHY_AND_ARCHITECTURE.md` - Philosophy alignment

**⚛️ Quantum Atomic Time Integration (Phase 11 - CRITICAL):**
- `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_INTEGRATION_GUIDE.md` - Complete atomic time integration guide with quantum formulas
- `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_IMPLEMENTATION_UPDATES.md` - Detailed code examples for all files requiring atomic time updates
- `packages/avrai_core/lib/services/atomic_clock_service.dart` - Atomic clock service implementation
- `packages/avrai_core/lib/models/atomic_timestamp.dart` - Atomic timestamp model definition

---

**Status:** 📋 Ready for Implementation (Enhanced with Phase 11 Integrations + ⚛️ Quantum Atomic Time)  
**Last Updated:** January 3, 2026  
**Next Steps:** Begin Phase 1: Event Instrumentation & Schema Hooks

**⚛️ IMPORTANT:** All Phase 11 learning systems **MUST** use atomic timestamps for quantum formula compatibility. See `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_INTEGRATION_GUIDE.md` for complete guide and `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_IMPLEMENTATION_UPDATES.md` for detailed code examples.

---

## 🆕 **PHASE 11 ENHANCEMENTS (January 2026)**

### **Purpose:**
Close all learning loops between user interactions, AI2AI mesh learning, ONNX updates, and conversation analysis. These enhancements ensure a complete, real-time learning system that works both online and offline.

### **Key Enhancements:**

1. **AI2AI Mesh → ContinuousLearningSystem Integration**
   - Mesh learning insights processed through continuous learning pipeline
   - Real-time ONNX updates from mesh insights
   - Works offline via Bluetooth mesh

2. **Real-time ONNX Updates from Interactions**
   - User interactions update ONNX biases immediately
   - No waiting for federated sync
   - Faster personalization

3. **Conversation-Based Learning Integration**
   - AI2AI chat conversations feed into continuous learning
   - Conversation patterns extracted for dimension updates
   - Collective intelligence from conversations

4. **Offline Mesh Learning**
   - DecisionCoordinator leverages AI2AI mesh when offline
   - Bluetooth mesh provides learning insights without internet
   - Continuous improvement in offline scenarios

5. **Complete Learning Pipeline**
   - User interactions → ONNX updates → Mesh propagation → Other devices
   - All learning loops closed
   - Real-time, offline-capable learning system

6. **⚛️ Quantum Atomic Time Integration** (CRITICAL - Phase 11 Enhancement)
   - All learning systems use atomic timestamps for quantum formula compatibility
   - Drift detection uses atomic time with temporal decay: `e^(-γ_learning * (t_atomic - t_atomic_original))`
   - Throttling checks use atomic time precision for 20-minute intervals
   - All interaction events include atomic timestamps for quantum calculations
   - **Required for quantum formulas:** All quantum temporal formulas require `t_atomic`, not `DateTime`
   - **See:** `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_INTEGRATION_GUIDE.md` for complete guide
   - **See:** `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_IMPLEMENTATION_UPDATES.md` for detailed code examples

7. **Cross-Platform LLM Communication Architecture** (Phase 11 Enhancement)
   - Explains how different on-device LLMs (Android vs iOS) communicate through AI2AI mesh
   - Standardized personality abstraction layer abstracts away LLM differences
   - ONNX ensures consistent dimension scoring across platforms
   - AI2AI mesh communicates standardized data structures, not raw LLM outputs
   - **See:** Phase 8.0 for complete architecture documentation

8. **Adaptive Event Instrumentation System** (Phase 11 Enhancement)
   - System learns and updates what types of user information are captured automatically
   - Event types can be added/updated without code changes via configuration
   - Learning-driven event value assessment identifies valuable vs unused parameters
   - Dynamic schema updates based on learning insights
   - Automatic context learning identifies valuable context fields per event type
   - System suggests new event types based on parameter patterns
   - Low-value event types automatically disabled (< 0.1 learning value)
   - **See:** Phase 1.1.1 for complete implementation documentation

### **Implementation Priority:**
- **Critical:** Phase 8.1 (AI2AI Mesh Integration), Phase 8.2 (Real-time ONNX Updates), **⚛️ Quantum Atomic Time Integration**
- **High:** Phase 8.3 (Conversation Learning), Phase 8.5 (Complete Pipeline)
- **Medium:** Phase 8.4 (Offline Mesh Learning)

### **Related Documentation:**
- `lib/core/ai2ai/connection_orchestrator.dart` - AI2AI mesh implementation
- `lib/core/ai/ai2ai_learning/orchestrator.dart` - Chat conversation analysis
- `lib/core/ml/onnx_dimension_scorer.dart` - ONNX bias updates
- `lib/core/ai/decision_coordinator.dart` - Offline mesh integration
- **⚛️ Atomic Time Integration:**
  - `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_INTEGRATION_GUIDE.md` - Complete atomic time integration guide
  - `docs/plans/user_ai_interaction/PHASE_11_ATOMIC_TIME_IMPLEMENTATION_UPDATES.md` - Detailed code examples for all files
  - `packages/avrai_core/lib/services/atomic_clock_service.dart` - Atomic clock service implementation
  - `packages/avrai_core/lib/models/atomic_timestamp.dart` - Atomic timestamp model
- **Cross-Platform LLM Communication:**
  - Phase 8.0 - Cross-Platform LLM Communication Architecture (complete explanation)
  - `lib/core/ai/personality_learning.dart` - Personality abstraction layer
  - `packages/avrai_network/lib/network/ai2ai_protocol.dart` - Mesh communication protocol
  - `packages/avrai_network/lib/network/personality_data_codec.dart` - Standardized data encoding/decoding
  - `docs/plans/ml_models/ON_DEVICE_MODEL_RECOMMENDATIONS.md` - Platform-specific LLM recommendations
- **Adaptive Event Instrumentation:**
  - Phase 1.1.1 - Adaptive Event Instrumentation System (complete implementation documentation)
  - `lib/core/ai/event_type_registry.dart` - Event type registry system
  - `lib/core/ai/event_learning_analyzer.dart` - Learning-driven event analysis
  - `lib/core/ai/context_learning_analyzer.dart` - Context value analysis
  - `lib/core/ai/continuous_learning_system.dart` - Integration with learning system

