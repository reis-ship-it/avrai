# Expertise Network Layers

**Created:** December 8, 2025, 5:10 PM CST  
**Purpose:** Documentation of expertise-based network layers and locality understanding

---

## 🎯 **Overview**

The AI2AI system includes an **expertise-based network layer** that organizes AIs by expertise level and locality. This creates a hierarchical network where:

- **Expertise levels** determine network scope (Local, City, Regional, National, Global, Universal)
- **Locality personality** reflects community character shaped by local experts
- **Network layers** enable expertise-based connections and learning

---

## 🏗️ **Expertise Levels**

### **Level Hierarchy**

```
Universal Expert
  └─ Global network access

Global Expert
  └─ International network access

National Expert
  └─ National network access

Regional Expert
  └─ Regional network access

City Expert
  └─ City-wide network access

Local Expert
  └─ Locality-specific network access
```

**Code Reference:**
- `lib/core/models/expertise_level.dart` - ExpertiseLevel enum
- `lib/core/services/expertise_network_service.dart` - Network service

---

## 🏘️ **Locality Personality**

### **What It Is**

Each locality has its own AI personality, shaped by:
- Local expert behavior (10% higher influence)
- All local user behavior
- Community values and preferences

### **How It Works**

1. **Locality Personality Creation**
   - Initial personality created for each locality
   - Evolves based on local user behavior
   - Golden experts have 10% higher influence

2. **Personality Shaping**
   - User actions update locality personality
   - Golden expert actions weighted 10% higher
   - Community character emerges from collective behavior

3. **Network Reflection**
   - Locality personality reflects community
   - AI connections consider locality personality
   - Expertise network organized by locality

**Code Reference:**
- `lib/core/services/locality_personality_service.dart` - Locality personality service
- `lib/core/services/golden_expert_ai_influence_service.dart` - Golden expert influence

---

## 🌐 **Expertise Network Service**

### **Purpose**

Manages expertise-based social graph and connections.

### **Key Functions**

1. **Get Expertise Network**
   - Builds network for a user based on shared expertise
   - Calculates connection strength
   - Determines connection type (mentor/mentee/peer/complementary)

2. **Get Expertise Circles**
   - Groups experts by category and level
   - Filters by location if specified
   - Returns circles sorted by level

3. **Connection Types**
   - **Mentor:** Higher expertise level
   - **Mentee:** Lower expertise level
   - **Peer:** Same expertise level
   - **Complementary:** Different expertise categories

**Code Reference:**
- `lib/core/services/expertise_network_service.dart` - Complete implementation
- `lib/core/models/expertise_level.dart` - Expertise level definitions

---

## 🔗 **Network Integration**

### **AI2AI Connections**

Expertise network informs AI2AI connections:
- Shared expertise increases compatibility
- Expertise level differences create learning opportunities
- Locality personality influences connection preferences

### **Locality Understanding**

- Network reflects locality expertise distribution
- Locality personality shapes AI connections
- Local experts influence community character

**Code Reference:**
- `lib/core/ai2ai/connection_orchestrator.dart` - Connection orchestration
- `lib/core/ai/vibe_analysis_engine.dart` - Compatibility analysis

---

## 📊 **Network Structure**

### **Connection Strength Calculation**

Connection strength based on:
- Shared expertise categories (0.2 per category)
- Level similarity (0.3 weight)
- Location match (0.2 bonus)

**Code Reference:**
```dart
double _calculateConnectionStrength({
  required UnifiedUser user,
  required UnifiedUser otherUser,
  required List<String> sharedCategories,
}) {
  double strength = 0.0;
  
  // Shared categories contribute to strength
  strength += sharedCategories.length * 0.2;
  
  // Level similarity
  for (final category in sharedCategories) {
    final userLevel = user.getExpertiseLevel(category);
    final otherLevel = otherUser.getExpertiseLevel(category);
    
    if (userLevel != null && otherLevel != null) {
      final levelDiff = (userLevel.index - otherLevel.index).abs();
      strength += (1.0 - (levelDiff / ExpertiseLevel.values.length)) * 0.3;
    }
  }
  
  // Location match bonus
  if (user.location != null && otherUser.location != null) {
    if (user.location == otherUser.location) {
      strength += 0.2;
    }
  }
  
  return strength.clamp(0.0, 1.0);
}
```

**File:** `lib/core/services/expertise_network_service.dart`

---

## 🔗 **Related Documentation**

- **Architecture Layers:** [`ARCHITECTURE_LAYERS.md`](./ARCHITECTURE_LAYERS.md)
- **Network Flows:** [`NETWORK_FLOWS.md`](./NETWORK_FLOWS.md)
- **Expertise System:** `docs/plans/expertise_system/` - Expertise system plans

---

**Last Updated:** December 8, 2025, 5:10 PM CST  
**Status:** Expertise Network Layers Documentation Complete

