# Universal Personality Converter

**Purpose:** Convert any personality data format to SPOTS 12 dimensions using auto-detection and heuristic mapping.

---

## 🎯 Features

- **Auto-Detection:** Automatically detects known formats (Big Five, MBTI, Enneagram)
- **Heuristic Mapping:** Maps unknown fields to SPOTS dimensions using semantic similarity
- **Custom Mappings:** Supports custom field → dimension mappings
- **Intelligent Defaults:** Fills missing dimensions with related dimension averages or neutral values

---

## 📍 Architecture Location

The universal converter sits in the **Converters Layer**:

```
scripts/personality_data/
├── converters/
│   ├── base.py                    # Base interface
│   ├── big_five_to_spots.py       # Big Five converter
│   └── universal.py               # ✅ Universal converter
├── registry/
│   └── converter_registry.py     # ✅ Registered as 'universal' and 'auto'
└── converter.py                   # ✅ Used by orchestration layer
```

---

## 🚀 Usage

### **Via CLI**

```bash
# Auto-detect format
python -m scripts.personality_data.cli.convert input.json --source universal --output output.json

# Or use 'auto' alias
python -m scripts.personality_data.cli.convert input.json --source auto --output output.json
```

### **Via Python API**

```python
from scripts.personality_data.registry.converter_registry import get_converter

# Get universal converter
converter_class = get_converter('universal')
converter = converter_class()

# Convert any personality data
source_data = {
    'adventure_score': 0.8,
    'social_preference': 0.6,
    'quality_focus': 0.9
}

spots_dimensions = converter.convert(source_data)
# Returns: Dict with all 12 SPOTS dimensions (0.0-1.0)
```

### **Via Orchestration Layer**

```python
from scripts.personality_data.converter import convert_dataset
from pathlib import Path

profiles = convert_dataset(
    input_file=Path('input.json'),
    output_file=Path('output.json'),
    source_format='universal',  # Use universal converter
    input_file_format='json'
)
```

---

## 🔧 Custom Mappings

You can provide custom field → dimension mappings:

```python
custom_mappings = {
    'my_exploration_field': ['exploration_eagerness', 'novelty_seeking'],
    'my_social_field': ['social_discovery_style', 'community_orientation']
}

converter = UniversalPersonalityConverter(custom_mappings=custom_mappings)
result = converter.convert({
    'my_exploration_field': 0.85,
    'my_social_field': 0.6
})
```

---

## 📊 How It Works

### **1. Auto-Detection**

The converter first tries to detect known formats:

- **Big Five:** Detects `openness`, `conscientiousness`, `extraversion`, `agreeableness`, `neuroticism`
- **MBTI:** Detects `mbti`, `myers`, `briggs`, `intj`, `enfp`, `personality_type`
- **Enneagram:** Detects `enneagram`, `type`, `wing`

If a known format is detected, it uses the specific converter (e.g., `BigFiveToSpotsConverter`).

### **2. Heuristic Mapping**

For unknown formats, it uses semantic similarity to map fields:

- `adventure_score` → `exploration_eagerness`, `location_adventurousness`
- `social_preference` → `social_discovery_style`, `community_orientation`
- `quality_focus` → `value_orientation`
- `crowd_comfort` → `crowd_tolerance`

### **3. Pattern Matching**

If semantic mapping fails, it uses pattern matching:

- Fields containing `explor` or `adventur` → exploration dimensions
- Fields containing `social` or `community` → social dimensions
- Fields containing `authentic` or `value` → authenticity/value dimensions
- etc.

### **4. Intelligent Defaults**

Missing dimensions are filled with:
1. Average of related dimensions (if available)
2. Neutral value (0.5) as fallback

---

## ✅ SPOTS 12 Dimensions

The converter always outputs all 12 SPOTS dimensions:

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

## 📝 Examples

### **Example 1: Big Five (Auto-Detected)**

```python
big_five_data = {
    'openness': 4.2,
    'conscientiousness': 3.8,
    'extraversion': 2.5,
    'agreeableness': 4.1,
    'neuroticism': 2.0
}

converter = get_converter('universal')()
result = converter.convert(big_five_data)
# Uses BigFiveToSpotsConverter automatically
```

### **Example 2: Unknown Format (Heuristic)**

```python
unknown_data = {
    'adventure_score': 0.8,
    'social_preference': 0.6,
    'quality_focus': 0.9,
    'crowd_comfort': 0.4
}

converter = get_converter('universal')()
result = converter.convert(unknown_data)
# Maps fields heuristically to SPOTS dimensions
```

### **Example 3: Custom Format**

```python
custom_data = {
    'exploration_level': 0.7,
    'community_engagement': 0.85,
    'authenticity_value': 0.6
}

converter = get_converter('universal')()
result = converter.convert(custom_data)
# Uses pattern matching and semantic similarity
```

---

## 🔗 Integration Points

1. **Converter Registry:** Registered as `'universal'` and `'auto'`
2. **Orchestration Layer:** Used by `converter.py` when `source_format='universal'`
3. **CLI:** Available via `--source universal` or `--source auto`
4. **E-Commerce API:** Indirectly - reads pre-converted SPOTS data from database

---

## 🎯 Use Cases

- **Unknown Formats:** Convert personality data from unknown or custom formats
- **Mixed Formats:** Handle datasets with multiple personality format types
- **Rapid Prototyping:** Quickly convert new personality data without writing a custom converter
- **Data Integration:** Convert external personality data to SPOTS format for integration

---

**Last Updated:** December 30, 2025
