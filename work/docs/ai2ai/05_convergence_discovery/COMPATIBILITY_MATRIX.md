# Compatibility Matrix

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for compatibility matrix discovery system

---

## 🎯 **Overview**

The compatibility matrix uses both shared preferences and unique differences between AIs to discover "bridge categories" and suggest new "bridge spots" that combine these elements.

**Philosophy:** "Doors, not badges" - Use differences to discover new doors that bridge both preferences.

---

## 🧠 **The Concept**

### **How It Works**

1. **Identify Shared Preferences**
   - Both AIs like cafes
   - Both AIs have similar exploration_eagerness

2. **Identify Unique Differences**
   - AI A: Loves jazz bars
   - AI B: Loves family movies

3. **Generate Bridge Categories**
   - "Family-friendly jazz cafe"
   - "Cafe with live music that's kid-friendly"
   - "Jazz cafe with family seating"

4. **Suggest Bridge Spots**
   - Spots that combine shared + unique preferences
   - Opens new doors for both AIs

---

## 🏗️ **Implementation**

### **Compatibility Matrix Service**

```dart
class CompatibilityMatrixService {
  Future<List<BridgeCategory>> generateBridgeCategories(
    PersonalityProfile profile1,
    PersonalityProfile profile2,
  ) async {
    final shared = _findSharedPreferences(profile1, profile2);
    final unique1 = _findUniquePreferences(profile1, profile2);
    final unique2 = _findUniquePreferences(profile2, profile1);
    
    final bridges = <BridgeCategory>[];
    
    // Generate bridges from shared + unique combinations
    for (final sharedPref in shared) {
      for (final unique in unique1) {
        bridges.add(BridgeCategory(
          sharedPreference: sharedPref,
          uniquePreference1: unique,
          bridgeDescription: _generateBridgeDescription(sharedPref, unique),
        ));
      }
      for (final unique in unique2) {
        bridges.add(BridgeCategory(
          sharedPreference: sharedPref,
          uniquePreference2: unique,
          bridgeDescription: _generateBridgeDescription(sharedPref, unique),
        ));
      }
    }
    
    return bridges;
  }
}
```

**Code Reference:**
- `docs/plans/ai2ai_system/SELECTIVE_CONVERGENCE_AND_COMPATIBILITY_MATRIX_PLAN.md` - Implementation plan

---

## 🔗 **Related Documentation**

- **Selective Convergence:** [`SELECTIVE_CONVERGENCE.md`](./SELECTIVE_CONVERGENCE.md)
- **Tiered Discovery:** [`TIERED_DISCOVERY.md`](./TIERED_DISCOVERY.md)
- **Comprehensive Guide:** [`CONVERGENCE_DISCOVERY_GUIDE.md`](./CONVERGENCE_DISCOVERY_GUIDE.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Compatibility Matrix Documentation Complete

