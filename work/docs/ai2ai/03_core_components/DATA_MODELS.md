# AI2AI Data Models

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for all AI2AI data models

---

## 🎯 **Overview**

This document describes all data models used in the AI2AI system.

---

## 📋 **Core Models**

### **PersonalityProfile**

**Purpose:** Represents user personality with dimensions and evolution data

**Key Fields:**
- `dimensions` - Map of personality dimensions (0.0-1.0)
- `archetype` - Personality archetype
- `evolutionGeneration` - Evolution generation number
- `authenticity` - Authenticity score

**Code Reference:**
- `lib/core/models/personality_profile.dart`

---

### **UserVibe**

**Purpose:** Compiled user vibe for compatibility analysis

**Key Fields:**
- `anonymizedDimensions` - Anonymized personality dimensions
- `vibeSignature` - Vibe signature hash
- `compatibilityScores` - Compatibility scores

**Code Reference:**
- `lib/core/models/user_vibe.dart`

---

### **AnonymousUser**

**Purpose:** Anonymous user model for AI2AI communication

**CRITICAL:** NO personal information fields allowed

**Key Fields:**
- `agentId` - Anonymous identifier
- `personalityDimensions` - Anonymized personality
- `preferences` - Filtered preferences (non-personal)
- `expertise` - Expertise areas
- `location` - Obfuscated location (city-level only)

**Code Reference:**
- `lib/core/models/anonymous_user.dart`

---

### **ConnectionMetrics**

**Purpose:** Metrics for AI2AI connections

**Key Fields:**
- `compatibility` - Compatibility score
- `learningEffectiveness` - Learning effectiveness score
- `aiPleasureScore` - AI pleasure score
- `connectionQuality` - Connection quality score

**Code Reference:**
- `lib/core/models/connection_metrics.dart`

---

### **AIPersonalityNode**

**Purpose:** Represents a discovered AI personality node

**Key Fields:**
- `nodeId` - Node identifier
- `vibe` - UserVibe for compatibility analysis
- `lastSeen` - Last seen timestamp

**Code Reference:**
- `lib/core/ai2ai/aipersonality_node.dart`

---

## 🔗 **Related Documentation**

- **Core Components:** [`README.md`](./README.md)
- **Services:** [`SERVICES.md`](./SERVICES.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Data Models Documentation Complete

