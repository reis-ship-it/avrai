# Big Five OCEAN Data Requirement for All Experiments

**Date:** December 30, 2025  
**Status:** ✅ **MANDATORY** - Effective Immediately  
**Purpose:** Standardize all experiments to use real Big Five OCEAN data converted to SPOTS 12 dimensions

---

## 🚨 **MANDATORY RULE**

**ALL experiments MUST use real Big Five OCEAN data (100k+ examples) converted to SPOTS 12 dimensions.**

### **Requirements:**

1. ✅ **Use `load_and_convert_big_five_to_spots()` from `shared_data_model.py`**
2. ✅ **Load raw Big Five OCEAN data (from CSV or JSON)**
3. ✅ **Convert to SPOTS 12 dimensions using `BigFiveToSpotsConverter`**
4. ✅ **Document that experiments use real data (not synthetic)**

### **FORBIDDEN:**

- ❌ **DO NOT use synthetic data generation for personality profiles**
- ❌ **DO NOT use `generate_integrated_user_profile()` or similar synthetic generators**
- ❌ **DO NOT hardcode personality dimensions**
- ❌ **DO NOT use pre-converted data without documenting the conversion**

---

## 📅 **Historical Note**

**CRITICAL:** Experiments completed before December 30, 2025 used synthetic data.

- All new experiments must use real Big Five data
- When referencing old experiments, clearly state they used synthetic data
- When updating old experiments, migrate them to use real Big Five data
- Results from pre-December 30, 2025 experiments should be interpreted with this context

---

## 🔧 **Standard Implementation Pattern**

### **Function Location:**

`docs/patents/experiments/scripts/shared_data_model.py`

```python
def load_and_convert_big_five_to_spots(
    max_profiles: Optional[int] = None,
    data_source: str = 'auto',  # 'csv', 'json', or 'auto'
    project_root: Optional[Path] = None
) -> List[Dict[str, Any]]:
    """
    Load raw Big Five OCEAN data and convert to SPOTS 12 dimensions.
    
    Returns:
        List of SPOTS profiles with:
        - user_id: User identifier
        - dimensions: Dict of 12 SPOTS dimensions (0.0-1.0)
        - created_at: Creation timestamp (if available)
        - source: 'big_five_conversion'
        - original_data.big_five: Original OCEAN scores
        - original_data.raw_profile: Raw profile data
    """
```

### **Usage in Experiments:**

```python
from shared_data_model import load_and_convert_big_five_to_spots
from pathlib import Path

def load_personality_profiles() -> List[PersonalityProfile]:
    """
    Load personality profiles from Big Five OCEAN data, converted to SPOTS 12 dimensions.
    
    **MANDATORY:** This experiment uses real Big Five OCEAN data (100k+ examples)
    converted to SPOTS 12 dimensions via the standardized conversion function.
    
    **Historical Note:** Experiments completed before December 30, 2025 used synthetic data.
    This experiment has been updated to use real Big Five data.
    """
    # Get project root
    project_root = Path(__file__).parent.parent.parent.parent.parent
    
    # Load and convert Big Five OCEAN to SPOTS 12
    spots_profiles = load_and_convert_big_five_to_spots(
        max_profiles=100,  # Or None for all available
        data_source='auto',  # Try CSV first, then JSON
        project_root=project_root
    )
    
    # Convert to PersonalityProfile objects (if needed)
    profiles = []
    for item in spots_profiles:
        profile = PersonalityProfile(
            user_id=item['user_id'],
            dimensions=item['dimensions'],
            created_at=item.get('created_at', '2025-12-30')
        )
        profiles.append(profile)
    
    return profiles
```

---

## 📊 **Data Sources**

### **Primary Source: CSV**

**Location:** `data/raw/big_five.csv`

**Format:**
```csv
user_id,openness,conscientiousness,extraversion,agreeableness,neuroticism
user_1,4.06,1.85,4.81,3.64,3.17
user_2,1.32,4.13,1.47,4.73,2.5
...
```

**Scale:** 1-5 (Big Five standard)

**Count:** 100k+ real examples

### **Fallback Source: JSON**

**Location:** `data/raw/big_five_spots.json`

**Format:**
```json
[
  {
    "user_id": "user_1",
    "dimensions": {...},  // Already converted SPOTS 12
    "original_data": {
      "big_five": {
        "openness": 4.06,
        "conscientiousness": 1.85,
        "extraversion": 4.81,
        "agreeableness": 3.64,
        "neuroticism": 3.17
      }
    }
  }
]
```

**Note:** Function extracts `original_data.big_five` and re-converts to ensure consistency.

---

## 🔄 **Conversion Process**

### **Converter Used:**

`BigFiveToSpotsConverter` from `scripts/personality_data/converters/big_five_to_spots.py`

### **Mapping:**

- **Openness** → `exploration_eagerness`, `novelty_seeking`, `openness`
- **Conscientiousness** → `value_orientation`, `authenticity_preference`
- **Extraversion** → `social_discovery_style`, `community_orientation`, `adventure_seeking`
- **Agreeableness** → `trust_network_reliance`, `crowd_tolerance`
- **Neuroticism** → `energy_preference` (inverted)

### **Output:**

All 12 SPOTS dimensions normalized to 0.0-1.0 range:
1. `exploration_eagerness`
2. `community_orientation`
3. `authenticity_preference`
4. `social_discovery_style`
5. `temporal_flexibility`
6. `location_adventurousness`
7. `curation_tendency`
8. `trust_network_reliance`
9. `energy_preference`
10. `novelty_seeking`
11. `value_orientation`
12. `crowd_tolerance`

---

## ✅ **Updated Experiments**

The following experiments have been updated to use real Big Five data:

- ✅ `patent_31_experiment_2_knot_weaving.py`
- ✅ `patent_31_experiment_4_dynamic_evolution.py`
- ✅ `patent_31_experiment_5_physics_based.py`

**All other experiments should be updated when modified or when creating new experiments.**

---

## 📝 **Documentation Requirements**

When creating or updating experiments:

1. ✅ **State that experiments use real Big Five OCEAN data**
2. ✅ **Reference `load_and_convert_big_five_to_spots()` function**
3. ✅ **Note that experiments before December 30, 2025 used synthetic data**
4. ✅ **Include data source and conversion method in experiment documentation**
5. ✅ **Document the number of profiles used in the experiment**

---

## 🎯 **Benefits**

1. **Real Personality Distributions:** Experiments use actual human personality data
2. **Better Validation:** Results reflect real-world personality patterns
3. **Consistency:** All experiments use the same data source and conversion method
4. **Reproducibility:** Standardized function ensures consistent conversion
5. **Scalability:** Can easily load 100k+ profiles for large-scale experiments

---

## 🔍 **Verification**

To verify an experiment uses real Big Five data:

1. Check that `load_personality_profiles()` calls `load_and_convert_big_five_to_spots()`
2. Verify no synthetic data generation functions are called
3. Confirm documentation states use of real Big Five data
4. Check that profiles have `original_data.big_five` field

---

**Last Updated:** December 30, 2025  
**Status:** Active - Mandatory for all experiments
