# Selective Convergence

**Created:** December 8, 2025, 5:25 PM CST  
**Purpose:** Documentation for selective dimension convergence system

---

## 🎯 **Overview**

Selective convergence allows AIs to converge only on dimensions where they are similar, while preserving their unique differences. This prevents forced homogenization and maintains individual personality uniqueness.

**Philosophy:** "Doors, not badges" - Converge on similarities, preserve differences to discover new doors.

---

## 🧠 **The Concept**

### **Problem with Full Convergence**

If two AIs are frequently in proximity, forcing full convergence would:
- Lose unique preferences
- Homogenize personalities
- Remove individual character

### **Solution: Selective Convergence**

Only converge dimensions where:
1. Values are similar (difference < 0.3)
2. Both values are significant (> 0.3)
3. Compatibility is high for this dimension (> 0.5)

**Example:**
- Coworker A: Loves cafes, jazz bars, smoke lounges
- Coworker B: Loves cafes, family movies, family activities
- **Converge:** Cafe preferences (similar)
- **Preserve:** Jazz bars vs family movies (different)

---

## 🏗️ **Implementation**

### **Convergence Plan**

```dart
class SelectiveConvergenceService {
  Future<ConvergencePlan> createConvergencePlan(
    PersonalityProfile profile1,
    PersonalityProfile profile2,
    VibeCompatibilityResult compatibility,
  ) async {
    final plan = ConvergencePlan();
    
    for (final dimension in VibeConstants.coreDimensions) {
      final value1 = profile1.dimensions[dimension] ?? 0.5;
      final value2 = profile2.dimensions[dimension] ?? 0.5;
      final difference = (value1 - value2).abs();
      
      // Converge if similar and compatible
      if (difference < 0.3 && 
          value1 > 0.3 && 
          value2 > 0.3 &&
          compatibility.dimensionCompatibility[dimension] ?? 0.0 > 0.5) {
        plan.addConvergence(dimension, (value1 + value2) / 2);
      } else {
        plan.preserveDifference(dimension, value1, value2);
      }
    }
    
    return plan;
  }
}
```

**Code Reference:**
- `docs/plans/ai2ai_system/SELECTIVE_CONVERGENCE_AND_COMPATIBILITY_MATRIX_PLAN.md` - Implementation plan
- `lib/core/constants/vibe_constants.dart` - Core dimensions

---

## 🔗 **Related Documentation**

- **Frequency Recognition:** [`FREQUENCY_RECOGNITION.md`](./FREQUENCY_RECOGNITION.md)
- **Compatibility Matrix:** [`COMPATIBILITY_MATRIX.md`](./COMPATIBILITY_MATRIX.md)
- **Tiered Discovery:** [`TIERED_DISCOVERY.md`](./TIERED_DISCOVERY.md)
- **Comprehensive Guide:** [`CONVERGENCE_DISCOVERY_GUIDE.md`](./CONVERGENCE_DISCOVERY_GUIDE.md)

---

**Last Updated:** December 8, 2025, 5:25 PM CST  
**Status:** Selective Convergence Documentation Complete

