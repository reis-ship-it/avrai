# Expanded Tiered Discovery System Implementation Plan

**Created:** December 8, 2025  
**Status:** 📋 Implementation Plan  
**Priority:** HIGH  
**Timeline:** 15-20 days  
**Purpose:** Implement comprehensive multi-source, multi-tier discovery system with adaptive prioritization

---

## 🎯 **Executive Summary**

This plan implements an expanded tiered discovery system that:
1. **Multi-Source Tier 1**: Direct activity, AI2AI-learned, cloud network, contextual preferences
2. **Multi-Source Tier 2**: Compatibility matrix bridges, exploration opportunities, temporal bridges
3. **Tier 3**: Experimental suggestions for users who want to try new things
4. **Adaptive Prioritization**: System learns which tiers users interact with and adjusts presentation frequency
5. **Confidence Scoring**: Calculated confidence scores for all suggestions
6. **User Feedback Loop**: Tracks user actions and adapts thresholds
7. **Temporal/Contextual Awareness**: Time-of-day and context-based suggestions
8. **Multi-User Support**: Group suggestions when multiple recognized AIs are present

**Philosophy:** "Doors, not badges" - Show users doors they're ready for, adapt to their exploration style.

---

## 🧠 **The Concept**

### **Problem with Current Two-Tier System**

**Current Gaps:**
- ❌ Too narrow (only direct preferences vs. compatibility matrix)
- ❌ No confidence scoring system
- ❌ No user feedback loop
- ❌ Missing AI2AI-learned preferences
- ❌ Missing cloud network intelligence
- ❌ No temporal/contextual awareness
- ❌ No multi-user support
- ❌ No adaptive prioritization based on user behavior

### **Solution: Expanded Multi-Tier System**

**Tier 1: High-Confidence, Direct Matches (Confidence >= 0.7)**
- **Source 1:** Direct user activity (visits, feedback, patterns)
- **Source 2:** AI2AI-learned preferences (from recognized AIs)
- **Source 3:** Cloud network intelligence (popular doors in area)
- **Source 4:** Contextual preferences (work, social, location-based)

**Tier 2: Moderate-Confidence, Bridge Opportunities (Confidence 0.4-0.69)**
- **Source 1:** Compatibility matrix bridges (shared + differences)
- **Source 2:** Exploration opportunities (novel but potentially interesting)
- **Source 3:** Temporal bridges (time-based opportunities)

**Tier 3: Low-Confidence, Experimental (Confidence < 0.4)**
- **Source 1:** Random exploration (completely new categories)
- **Source 2:** Network outliers (works for similar profiles, untested for you)

**Adaptive Prioritization:**
- Track which tiers users interact with most
- If user frequently interacts with Tier 3 → Show Tier 3 more often
- If user prefers Tier 1 → Keep Tier 1 prominent
- Adapt presentation frequency based on user behavior

---

## 🏗️ **Architecture**

### **1. Discovery Service**

```dart
class DiscoveryService {
  final PersonalityLearning _personalityLearning;
  final AI2AILearningService _ai2aiLearning;
  final CloudLearningInterface _cloudLearning;
  final CompatibilityMatrixService _compatibilityMatrix;
  final UserInteractionTracker _interactionTracker;
  final StorageService _storage;
  
  /// Generate multi-tier discovery opportunities
  Future<DiscoveryResults> generateDiscoveryOpportunities({
    required String userId,
    required PersonalityProfile profile,
    String? context, // 'work', 'social', 'solo', null
    DateTime? timeOfDay,
    List<PersonalityProfile>? groupProfiles, // For multi-user suggestions
  }) async {
    // Get user's tier interaction preferences
    final tierPreferences = await _getUserTierPreferences(userId);
    
    // Generate opportunities from all sources
    final tier1Opportunities = await _generateTier1Opportunities(
      userId, profile, context, timeOfDay, groupProfiles,
    );
    final tier2Opportunities = await _generateTier2Opportunities(
      userId, profile, context, timeOfDay, groupProfiles,
    );
    final tier3Opportunities = await _generateTier3Opportunities(
      userId, profile, context, timeOfDay, groupProfiles,
    );
    
    // Apply adaptive prioritization
    final prioritizedResults = _applyAdaptivePrioritization(
      tier1Opportunities,
      tier2Opportunities,
      tier3Opportunities,
      tierPreferences,
    );
    
    return prioritizedResults;
  }
}
```

### **2. Confidence Scoring System**

```dart
class ConfidenceCalculator {
  /// Calculate confidence score for a discovery opportunity
  double calculateConfidence({
    required DiscoveryOpportunity opportunity,
    required PersonalityProfile profile,
    String? context,
    DateTime? timeOfDay,
  }) {
    double confidence = 0.0;
    
    // Direct activity weight (40%)
    if (opportunity.hasDirectActivity) {
      confidence += 0.4 * opportunity.activityStrength;
    }
    
    // AI2AI learned weight (25%)
    if (opportunity.hasAI2AILearning) {
      confidence += 0.25 * opportunity.ai2aiConfidence;
    }
    
    // Cloud network weight (20%)
    if (opportunity.hasCloudPattern) {
      confidence += 0.2 * opportunity.networkConfidence;
    }
    
    // Contextual match weight (15%)
    if (opportunity.matchesCurrentContext(context)) {
      confidence += 0.15 * opportunity.contextMatch;
    }
    
    // Temporal bonus (up to +0.1)
    if (timeOfDay != null && opportunity.matchesTemporalPattern(timeOfDay)) {
      confidence += 0.1 * opportunity.temporalMatch;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
}
```

### **3. Adaptive Prioritization System**

```dart
class AdaptivePrioritizationService {
  final UserInteractionTracker _interactionTracker;
  final StorageService _storage;
  
  /// Get user's tier interaction preferences
  Future<TierPreferences> getUserTierPreferences(String userId) async {
    final interactionHistory = await _interactionTracker.getInteractionHistory(userId);
    
    // Calculate interaction rates per tier
    final tier1Interactions = interactionHistory
        .where((i) => i.tier == 1 && i.userActed)
        .length;
    final tier2Interactions = interactionHistory
        .where((i) => i.tier == 2 && i.userActed)
        .length;
    final tier3Interactions = interactionHistory
        .where((i) => i.tier == 3 && i.userActed)
        .length;
    
    final totalInteractions = tier1Interactions + tier2Interactions + tier3Interactions;
    
    if (totalInteractions == 0) {
      // Default: Equal weighting
      return TierPreferences(
        tier1Weight: 0.5,
        tier2Weight: 0.3,
        tier3Weight: 0.2,
      );
    }
    
    // Calculate weights based on interaction rates
    final tier1Weight = tier1Interactions / totalInteractions;
    final tier2Weight = tier2Interactions / totalInteractions;
    final tier3Weight = tier3Interactions / totalInteractions;
    
    return TierPreferences(
      tier1Weight: tier1Weight,
      tier2Weight: tier2Weight,
      tier3Weight: tier3Weight,
    );
  }
  
  /// Apply adaptive prioritization to discovery results
  DiscoveryResults applyAdaptivePrioritization({
    required List<DiscoveryOpportunity> tier1,
    required List<DiscoveryOpportunity> tier2,
    required List<DiscoveryOpportunity> tier3,
    required TierPreferences preferences,
  }) {
    // Calculate how many suggestions to show from each tier
    final totalSuggestions = 10; // Default
    
    final tier1Count = (totalSuggestions * preferences.tier1Weight).round();
    final tier2Count = (totalSuggestions * preferences.tier2Weight).round();
    final tier3Count = (totalSuggestions * preferences.tier3Weight).round();
    
    // Select top opportunities from each tier
    final selectedTier1 = tier1
        .sorted((a, b) => b.confidence.compareTo(a.confidence))
        .take(tier1Count)
        .toList();
    
    final selectedTier2 = tier2
        .sorted((a, b) => b.confidence.compareTo(a.confidence))
        .take(tier2Count)
        .toList();
    
    final selectedTier3 = tier3
        .sorted((a, b) => b.confidence.compareTo(a.confidence))
        .take(tier3Count)
        .toList();
    
    // Interleave based on weights (higher weight = more frequent)
    final interleaved = _interleaveOpportunities(
      selectedTier1, selectedTier2, selectedTier3,
      preferences,
    );
    
    return DiscoveryResults(
      opportunities: interleaved,
      tier1Count: selectedTier1.length,
      tier2Count: selectedTier2.length,
      tier3Count: selectedTier3.length,
      tierPreferences: preferences,
    );
  }
  
  /// Interleave opportunities based on tier weights
  List<DiscoveryOpportunity> _interleaveOpportunities(
    List<DiscoveryOpportunity> tier1,
    List<DiscoveryOpportunity> tier2,
    List<DiscoveryOpportunity> tier3,
    TierPreferences preferences,
  ) {
    final result = <DiscoveryOpportunity>[];
    final iterators = [
      tier1.iterator,
      tier2.iterator,
      tier3.iterator,
    ];
    final weights = [
      preferences.tier1Weight,
      preferences.tier2Weight,
      preferences.tier3Weight,
    ];
    
    // Round-robin with weighted frequency
    while (result.length < 10) {
      bool added = false;
      
      for (int i = 0; i < 3; i++) {
        if (iterators[i].moveNext()) {
          // Add based on weight (higher weight = more likely)
          if (Random().nextDouble() < weights[i]) {
            result.add(iterators[i].current);
            added = true;
            break;
          }
        }
      }
      
      if (!added) break; // No more opportunities
    }
    
    return result;
  }
}
```

### **4. User Interaction Tracker**

```dart
class UserInteractionTracker {
  final StorageService _storage;
  
  /// Track user interaction with discovery opportunity
  Future<void> trackInteraction({
    required String userId,
    required String opportunityId,
    required int tier,
    required InteractionType type, // 'viewed', 'acted', 'rejected', 'ignored'
    DateTime? timestamp,
  }) async {
    final interaction = UserInteraction(
      userId: userId,
      opportunityId: opportunityId,
      tier: tier,
      type: type,
      timestamp: timestamp ?? DateTime.now(),
    );
    
    // Save to storage
    final history = await _getInteractionHistory(userId);
    history.add(interaction);
    await _saveInteractionHistory(userId, history);
    
    // Update tier preferences if user acted
    if (type == InteractionType.acted) {
      await _updateTierPreferences(userId, tier);
    }
  }
  
  /// Get interaction history for user
  Future<List<UserInteraction>> getInteractionHistory(String userId) async {
    return await _getInteractionHistory(userId);
  }
  
  /// Update tier preferences based on interaction
  Future<void> _updateTierPreferences(String userId, int tier) async {
    final preferences = await _getTierPreferences(userId);
    
    // Increase weight for interacted tier
    switch (tier) {
      case 1:
        preferences.tier1Weight = (preferences.tier1Weight * 1.1).clamp(0.0, 1.0);
        break;
      case 2:
        preferences.tier2Weight = (preferences.tier2Weight * 1.1).clamp(0.0, 1.0);
        break;
      case 3:
        preferences.tier3Weight = (preferences.tier3Weight * 1.1).clamp(0.0, 1.0);
        break;
    }
    
    // Normalize weights
    final total = preferences.tier1Weight + preferences.tier2Weight + preferences.tier3Weight;
    preferences.tier1Weight /= total;
    preferences.tier2Weight /= total;
    preferences.tier3Weight /= total;
    
    await _saveTierPreferences(userId, preferences);
  }
}
```

### **5. Multi-User Group Suggestions**

```dart
class GroupDiscoveryService {
  /// Generate suggestions for multiple users
  Future<DiscoveryResults> generateGroupOpportunities({
    required List<PersonalityProfile> profiles,
    String? context,
    DateTime? timeOfDay,
  }) async {
    // Calculate group confidence for each opportunity
    final opportunities = await _getAllOpportunities();
    
    final groupOpportunities = opportunities.map((opp) {
      final groupConfidence = _calculateGroupConfidence(profiles, opp);
      return opp.copyWith(confidence: groupConfidence);
    }).toList();
    
    // Sort by group confidence
    groupOpportunities.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    // Apply tier thresholds
    final tier1 = groupOpportunities
        .where((o) => o.confidence >= 0.7)
        .toList();
    final tier2 = groupOpportunities
        .where((o) => o.confidence >= 0.4 && o.confidence < 0.7)
        .toList();
    final tier3 = groupOpportunities
        .where((o) => o.confidence < 0.4)
        .toList();
    
    return DiscoveryResults(
      tier1: tier1,
      tier2: tier2,
      tier3: tier3,
      isGroupSuggestion: true,
    );
  }
  
  /// Calculate confidence for group
  double _calculateGroupConfidence(
    List<PersonalityProfile> profiles,
    DiscoveryOpportunity opportunity,
  ) {
    // Average confidence across all profiles
    final avgConfidence = profiles
        .map((p) => _calculateConfidenceForProfile(p, opportunity))
        .reduce((a, b) => a + b) / profiles.length;
    
    // Bonus for shared preferences
    final sharedBonus = _calculateSharedPreferenceBonus(profiles, opportunity);
    
    return (avgConfidence * 0.7 + sharedBonus * 0.3).clamp(0.0, 1.0);
  }
}
```

---

## 📊 **Data Models**

### **Discovery Opportunity**

```dart
class DiscoveryOpportunity {
  final String id;
  final String spotId;
  final String title;
  final String description;
  final double confidence;
  final int tier; // 1, 2, or 3
  final DiscoverySource source; // 'direct_activity', 'ai2ai', 'cloud', 'compatibility_matrix', etc.
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  
  // Source flags
  bool get hasDirectActivity => source == DiscoverySource.directActivity;
  bool get hasAI2AILearning => source == DiscoverySource.ai2ai;
  bool get hasCloudPattern => source == DiscoverySource.cloud;
  
  // Confidence components
  double get activityStrength => metadata['activityStrength'] ?? 0.0;
  double get ai2aiConfidence => metadata['ai2aiConfidence'] ?? 0.0;
  double get networkConfidence => metadata['networkConfidence'] ?? 0.0;
  double get contextMatch => metadata['contextMatch'] ?? 0.0;
  double get temporalMatch => metadata['temporalMatch'] ?? 0.0;
  
  bool matchesCurrentContext(String? context) {
    return metadata['context'] == context;
  }
  
  bool matchesTemporalPattern(DateTime timeOfDay) {
    // Check if opportunity matches time pattern
    return metadata['temporalPattern']?.matches(timeOfDay) ?? false;
  }
}
```

### **Tier Preferences**

```dart
class TierPreferences {
  final double tier1Weight; // 0.0-1.0
  final double tier2Weight; // 0.0-1.0
  final double tier3Weight; // 0.0-1.0
  
  TierPreferences({
    required this.tier1Weight,
    required this.tier2Weight,
    required this.tier3Weight,
  }) : assert(
          (tier1Weight + tier2Weight + tier3Weight - 1.0).abs() < 0.01,
          'Weights must sum to 1.0',
        );
  
  factory TierPreferences.default_() {
    return TierPreferences(
      tier1Weight: 0.5,
      tier2Weight: 0.3,
      tier3Weight: 0.2,
    );
  }
}
```

### **User Interaction**

```dart
class UserInteraction {
  final String userId;
  final String opportunityId;
  final int tier;
  final InteractionType type;
  final DateTime timestamp;
  
  UserInteraction({
    required this.userId,
    required this.opportunityId,
    required this.tier,
    required this.type,
    required this.timestamp,
  });
}

enum InteractionType {
  viewed,    // User viewed the suggestion
  acted,     // User acted on the suggestion (visited, saved, etc.)
  rejected,  // User explicitly rejected
  ignored,   // User ignored (no action)
}
```

---

## 🔄 **Implementation Phases**

### **Phase 1: Core Discovery Service (3-4 days)**

**Tasks:**
1. Create `DiscoveryService` class
2. Implement `generateDiscoveryOpportunities` method
3. Create `DiscoveryOpportunity` model
4. Create `DiscoveryResults` model
5. Basic tier separation (Tier 1, 2, 3)

**Deliverables:**
- `lib/core/ai2ai/discovery_service.dart`
- `lib/core/models/discovery_opportunity.dart`
- `lib/core/models/discovery_results.dart`

---

### **Phase 2: Multi-Source Tier 1 (3-4 days)**

**Tasks:**
1. Implement direct activity source
2. Implement AI2AI-learned preferences source
3. Implement cloud network intelligence source
4. Implement contextual preferences source
5. Integrate all sources into Tier 1 generation

**Deliverables:**
- `_generateTier1Opportunities` method complete
- Integration with `PersonalityLearning`
- Integration with `AI2AILearningService`
- Integration with `CloudLearningInterface`

---

### **Phase 3: Multi-Source Tier 2 & 3 (3-4 days)**

**Tasks:**
1. Implement compatibility matrix bridge source
2. Implement exploration opportunities source
3. Implement temporal bridges source
4. Implement Tier 3 experimental sources
5. Integrate all sources into Tier 2 & 3 generation

**Deliverables:**
- `_generateTier2Opportunities` method complete
- `_generateTier3Opportunities` method complete
- Integration with `CompatibilityMatrixService`

---

### **Phase 4: Confidence Scoring System (2-3 days)**

**Tasks:**
1. Create `ConfidenceCalculator` class
2. Implement confidence calculation logic
3. Implement confidence component tracking
4. Add confidence to all opportunities
5. Test confidence accuracy

**Deliverables:**
- `lib/core/ai2ai/confidence_calculator.dart`
- Confidence scores on all opportunities
- Confidence component breakdown

---

### **Phase 5: User Interaction Tracker (2-3 days)**

**Tasks:**
1. Create `UserInteractionTracker` class
2. Implement interaction tracking (viewed, acted, rejected, ignored)
3. Implement interaction history storage
4. Create `UserInteraction` model
5. Test interaction tracking

**Deliverables:**
- `lib/core/ai2ai/user_interaction_tracker.dart`
- `lib/core/models/user_interaction.dart`
- Storage integration for interaction history

---

### **Phase 6: Adaptive Prioritization (2-3 days)**

**Tasks:**
1. Create `AdaptivePrioritizationService` class
2. Implement tier preference calculation
3. Implement adaptive prioritization logic
4. Implement interleaving algorithm
5. Test adaptive behavior

**Deliverables:**
- `lib/core/ai2ai/adaptive_prioritization_service.dart`
- `TierPreferences` model
- Adaptive prioritization working

---

### **Phase 7: Multi-User Group Support (2-3 days)**

**Tasks:**
1. Create `GroupDiscoveryService` class
2. Implement group confidence calculation
3. Implement shared preference bonus
4. Integrate with main discovery service
5. Test group suggestions

**Deliverables:**
- `lib/core/ai2ai/group_discovery_service.dart`
- Group suggestions working
- Multi-user support complete

---

### **Phase 8: Integration & Testing (2-3 days)**

**Tasks:**
1. Integrate all components
2. End-to-end testing
3. Performance optimization
4. Edge case handling
5. Documentation

**Deliverables:**
- Fully integrated system
- Test suite
- Documentation complete

---

## 📈 **Success Metrics**

### **Functional Metrics:**
- ✅ All three tiers generating opportunities
- ✅ Confidence scores calculated correctly
- ✅ Adaptive prioritization working
- ✅ User interactions tracked
- ✅ Multi-user suggestions working

### **User Experience Metrics:**
- User engagement with suggestions (view rate, action rate)
- Tier preference adaptation (users who interact with Tier 3 see more Tier 3)
- Suggestion relevance (user feedback)
- Discovery success rate (doors opened)

### **Performance Metrics:**
- Discovery generation time < 500ms
- Confidence calculation time < 100ms
- Interaction tracking latency < 50ms

---

## 🔗 **Dependencies**

### **Required Services:**
- `PersonalityLearning` - For personality profile access
- `AI2AILearningService` - For AI2AI-learned preferences
- `CloudLearningInterface` - For cloud network intelligence
- `CompatibilityMatrixService` - For compatibility matrix bridges
- `StorageService` - For interaction history storage

### **Required Models:**
- `PersonalityProfile` - User personality
- `DiscoveryOpportunity` - Discovery suggestions
- `UserInteraction` - Interaction tracking

---

## 🚨 **Risks & Mitigation**

### **Risk 1: Over-Adaptation**
**Risk:** System adapts too quickly, showing only one tier
**Mitigation:** Gradual adaptation (10% increase per interaction), minimum thresholds

### **Risk 2: Performance Issues**
**Risk:** Generating opportunities for all sources is slow
**Mitigation:** Caching, async generation, limit opportunity count

### **Risk 3: Low Confidence Accuracy**
**Risk:** Confidence scores don't reflect actual relevance
**Mitigation:** User feedback loop, continuous calibration, A/B testing

---

## 📚 **Related Documentation**

- **Selective Convergence:** [`SELECTIVE_CONVERGENCE_PLAN.md`](./SELECTIVE_CONVERGENCE_PLAN.md)
- **Compatibility Matrix:** [`SELECTIVE_CONVERGENCE_PLAN.md`](./SELECTIVE_CONVERGENCE_PLAN.md) (same document)
- **Tiered Discovery:** [`../ai2ai/05_convergence_discovery/TIERED_DISCOVERY.md`](../../ai2ai/05_convergence_discovery/TIERED_DISCOVERY.md)
- **Convergence Guide:** [`../ai2ai/05_convergence_discovery/CONVERGENCE_DISCOVERY_GUIDE.md`](../../ai2ai/05_convergence_discovery/CONVERGENCE_DISCOVERY_GUIDE.md)

---

**Last Updated:** December 8, 2025  
**Status:** 📋 Implementation Plan - Ready for Execution

