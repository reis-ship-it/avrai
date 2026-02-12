# Two-Tier Discovery System

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for two-tier discovery system

---

## 🎯 **Overview**

The two-tier discovery system prioritizes suggestions based on direct user activity and preferences (Tier 1), while offering compatibility matrix bridge opportunities as secondary suggestions (Tier 2).

**Philosophy:** Direct user interests are primary, bridge opportunities are secondary.

---

## 🧠 **The Concept**

### **Tier 1: Direct Activity/Preference Matches**

**Primary Suggestions:**
- Based on direct user activity
- Based on user preferences
- Based on past behavior
- High confidence matches

**Example:**
- User visits coffee shops frequently → Suggest coffee shops
- User likes jazz music → Suggest jazz venues

---

### **Tier 2: Compatibility Matrix Bridge Opportunities**

**Secondary Suggestions:**
- Based on compatibility matrix
- Bridge categories combining shared + unique preferences
- Lower confidence, but novel opportunities
- Discover new doors through differences

**Example:**
- User A likes cafes, User B likes jazz bars
- Tier 2 suggestion: "Family-friendly jazz cafe"

---

## 🏗️ **Implementation**

### **Discovery Service**

```dart
class DiscoveryService {
  Future<DiscoveryResults> generateDiscoveryOpportunities(
    String userId,
    PersonalityProfile profile,
  ) async {
    // TIER 1: Direct activity/preference matches (PRIMARY)
    final tier1Opportunities = await _generateTier1Opportunities(userId, profile);
    
    // TIER 2: Compatibility matrix bridge opportunities (SECONDARY)
    final tier2Opportunities = await _generateTier2Opportunities(userId, profile);
    
    return DiscoveryResults(
      tier1: tier1Opportunities, // Primary suggestions
      tier2: tier2Opportunities, // Secondary suggestions
    );
  }
}
```

**Code Reference:**
- `docs/plans/ai2ai_system/SELECTIVE_CONVERGENCE_AND_COMPATIBILITY_MATRIX_PLAN.md` - Implementation plan

---

## 🔗 **Related Documentation**

- **Selective Convergence:** [`SELECTIVE_CONVERGENCE.md`](./SELECTIVE_CONVERGENCE.md)
- **Compatibility Matrix:** [`COMPATIBILITY_MATRIX.md`](./COMPATIBILITY_MATRIX.md)
- **Comprehensive Guide:** [`CONVERGENCE_DISCOVERY_GUIDE.md`](./CONVERGENCE_DISCOVERY_GUIDE.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Tiered Discovery Documentation Complete

