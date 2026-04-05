# Personality Data Conversion System - Architecture

**Version:** 1.0.0  
**Date:** December 16, 2025

---

## 🏗️ Architecture Overview

The Personality Data Conversion System is a modular, extensible architecture for converting personality datasets from various formats to SPOTS 12-dimension format.

### Design Principles

1. **Modularity** - Each component has a single responsibility
2. **Extensibility** - Easy to add new converters and formats
3. **Discoverability** - Registry system for datasets and converters
4. **Reusability** - Components can be used independently
5. **Testability** - Each component can be tested in isolation

---

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLI Layer (cli/)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   convert    │  │   download   │  │   validate   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Orchestration Layer (converter.py)              │
│  Coordinates: Loaders → Converters → Processors              │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Loaders    │  │  Converters  │  │  Processors  │
│  (loaders/)  │  │(converters/) │  │(processors/) │
└──────────────┘  └──────────────┘  └──────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Registry Layer (registry/)                      │
│  ┌──────────────────┐  ┌──────────────────┐                 │
│  │ Dataset Registry  │  │Converter Registry│                │
│  └──────────────────┘  └──────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Utility Layer (utils/)                          │
│  Archetype inference, compatibility, extraction               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Component Details

### 1. Converters (`converters/`)

**Purpose:** Convert personality data from source format to SPOTS 12 dimensions.

**Base Interface:**
```python
class PersonalityConverter(ABC):
    def convert(source_data: Dict) -> Dict[str, float]
    def validate_source(source_data: Dict) -> bool
    def get_source_format() -> str
    def get_required_fields() -> List[str]
```

**Current Implementations:**
- `BigFiveToSpotsConverter` - Converts Big Five (OCEAN) to SPOTS

**Adding New Converters:**
1. Extend `PersonalityConverter`
2. Implement required methods
3. Register in `converter_registry.py`

---

### 2. Loaders (`loaders/`)

**Purpose:** Load personality datasets from file formats.

**Current Implementations:**
- `CSVLoader` - Load/save CSV files
- `JSONLoader` - Load/save JSON files

**Adding New Loaders:**
1. Create loader class with `load()` and `save()` methods
2. Add to `loaders/__init__.py`

---

### 3. Processors (`processors/`)

**Purpose:** Post-process converted data.

**Current Implementations:**
- `GroundTruthGenerator` - Generate compatibility pairs
- `DatasetValidator` - Validate dataset structure
- `Normalizer` - Normalize scores across scales

**Adding New Processors:**
1. Create processor class
2. Add to `processors/__init__.py`

---

### 4. Registry (`registry/`)

**Purpose:** Discover and manage datasets and converters.

**Components:**
- `DatasetRegistry` - Known datasets with metadata
- `ConverterRegistry` - Available converters

**Usage:**
```python
from scripts.personality_data.registry import get_dataset_info, get_converter

# Get dataset info
info = get_dataset_info('big_five_kaggle')

# Get converter
converter_class = get_converter('big_five_to_spots')
```

---

### 5. Utilities (`utils/`)

**Purpose:** Shared utility functions.

**Current Utilities:**
- `archetype_inference` - Infer personality archetypes
- `compatibility_calculator` - Calculate compatibility scores
- `big_five_extractor` - Extract Big Five from flexible column names

---

### 6. CLI (`cli/`)

**Purpose:** Command-line interfaces for common operations.

**Current CLIs:**
- `convert.py` - Convert datasets
- `download.py` - Download datasets

**Usage:**
```bash
python -m scripts.personality_data.cli.convert input.csv --output output.json
python -m scripts.personality_data.cli.download --output data.csv
```

---

## 🔄 Data Flow

### Conversion Flow

```
1. User provides input file
   ↓
2. CLI detects format (CSV/JSON)
   ↓
3. Loader loads raw profiles
   ↓
4. Converter extracts source data (e.g., Big Five)
   ↓
5. Converter converts to SPOTS dimensions
   ↓
6. Validator validates output (optional)
   ↓
7. Loader saves SPOTS profiles
   ↓
8. Ground truth generator creates pairs (optional)
```

### Example: Big Five Conversion

```
CSV File (Big Five)
  → CSVLoader.load()
  → BigFiveExtractor.extract()
  → BigFiveToSpotsConverter.convert()
  → DatasetValidator.validate()
  → JSONLoader.save()
  → SPOTS JSON File
```

---

## 🎯 Extension Points

### Adding a New Personality Format

1. **Create Converter:**
   ```python
   # converters/mbti_to_spots.py
   class MBTIToSpotsConverter(PersonalityConverter):
       def convert(self, source_data):
           # Convert MBTI to SPOTS
           pass
   ```

2. **Register Converter:**
   ```python
   # registry/converter_registry.py
   register_converter('mbti', MBTIToSpotsConverter)
   ```

3. **Add to CLI:**
   ```bash
   python -m scripts.personality_data.cli.convert \
       input.csv --source mbti --output output.json
   ```

### Adding a New Dataset

1. **Register Dataset:**
   ```python
   # registry/dataset_registry.py
   register_dataset('my_dataset', {
       'name': 'My Dataset',
       'url': 'https://...',
       'format': 'csv',
       'converter': 'big_five',
       'columns': {...},
       'scale': '1-5',
   })
   ```

2. **Use in CLI:**
   ```bash
   python -m scripts.personality_data.cli.convert \
       input.csv --dataset my_dataset --output output.json
   ```

---

## 📊 Data Structures

### SPOTS Profile Format

```json
{
  "user_id": "user_1",
  "dimensions": {
    "exploration_eagerness": 0.75,
    "community_orientation": 0.68,
    "adventure_seeking": 0.72,
    "social_preference": 0.81,
    "energy_preference": 0.65,
    "novelty_seeking": 0.78,
    "value_orientation": 0.70,
    "crowd_tolerance": 0.73,
    "authenticity": 0.69,
    "archetype": 0.85,
    "trust_level": 0.77,
    "openness": 0.80
  },
  "created_at": "2025-01-01T00:00:00Z",
  "source": "big_five_conversion",
  "original_data": {
    "source_format": "big_five",
    "raw_profile": {...}
  }
}
```

### Ground Truth Format

```json
[
  {
    "user_a": "user_1",
    "user_b": "user_2",
    "is_compatible": true,
    "compatibility_score": 0.75,
    "true_compatibility": 0.72
  }
]
```

---

## 🔌 Integration Points

### With Knot Validation

The system integrates with knot validation scripts:
- Converted profiles → `generate_knots_from_profiles.py`
- Ground truth → `compare_matching_accuracy.py`

### With Other Systems

The system can be used by:
- Recommendation system testing
- Compatibility matching experiments
- Personality analysis research
- Any system needing SPOTS-formatted personality data

---

## 🧪 Testing Strategy

### Unit Tests
- Test each converter independently
- Test loaders with sample data
- Test processors with known inputs

### Integration Tests
- Test full conversion pipeline
- Test CLI tools
- Test registry system

### Validation Tests
- Test with real datasets
- Test error handling
- Test edge cases

---

## 📈 Future Enhancements

1. **More Converters:**
   - MBTI → SPOTS
   - Enneagram → SPOTS
   - 16PF → SPOTS

2. **More Loaders:**
   - Excel loader
   - Database loader
   - API loader

3. **More Processors:**
   - Data augmentation
   - Feature engineering
   - Statistical analysis

4. **Web Interface:**
   - Web UI for conversion
   - Dataset browser
   - Conversion history

---

**Last Updated:** December 16, 2025
