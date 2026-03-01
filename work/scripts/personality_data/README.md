# Personality Data Conversion System

A modular, extensible system for converting personality datasets from various formats (Big Five, MBTI, Enneagram, etc.) to SPOTS 12-dimension format.

---

## 🎯 Overview

This system provides:
- **Modular converters** for different personality formats
- **Dataset registry** for known datasets
- **Flexible loaders** for CSV/JSON files
- **Ground truth generation** for compatibility matching
- **CLI tools** for easy conversion
- **Validation** and error checking

---

## 📁 Architecture

```
scripts/personality_data/
├── converters/          # Personality format converters
│   ├── base.py         # Base converter interface
│   └── big_five_to_spots.py
├── loaders/            # Dataset file loaders
│   ├── csv_loader.py
│   └── json_loader.py
├── processors/         # Data processors
│   ├── ground_truth_generator.py
│   ├── dataset_validator.py
│   └── normalizer.py
├── registry/           # Registries
│   ├── dataset_registry.py
│   └── converter_registry.py
├── utils/              # Utility functions
│   ├── archetype_inference.py
│   ├── compatibility_calculator.py
│   └── big_five_extractor.py
└── cli/                # Command-line tools
    ├── convert.py
    └── download.py
```

---

## 🚀 Quick Start

### Convert a Dataset

```bash
# Using CLI
python -m scripts.personality_data.cli.convert \
    data/raw/big_five.csv \
    --output data/processed/spots_profiles.json \
    --source big_five

# With ground truth generation
python -m scripts.personality_data.cli.convert \
    data/raw/big_five.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json \
    --source big_five
```

### Using Python API

```python
from scripts.personality_data.converter import convert_dataset
from pathlib import Path

# Convert dataset
profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)
```

---

## 📊 Supported Formats

### Currently Supported
- **Big Five (OCEAN)** → SPOTS 12 dimensions
  - Handles 1-5 scale, 0-1 scale, 0-100 scale
  - Flexible column name matching

### Future Support
- MBTI → SPOTS
- Enneagram → SPOTS
- Custom personality inventories

---

## 🔧 Adding New Converters

1. **Create converter class:**
```python
from scripts.personality_data.converters.base import PersonalityConverter

class MyFormatConverter(PersonalityConverter):
    def convert(self, source_data: Dict) -> Dict[str, float]:
        # Your conversion logic
        return spots_dimensions
    
    def validate_source(self, source_data: Dict) -> bool:
        # Validation logic
        return True
    
    def get_source_format(self) -> str:
        return 'my_format'
    
    def get_required_fields(self) -> List[str]:
        return ['field1', 'field2']
```

2. **Register converter:**
```python
from scripts.personality_data.registry.converter_registry import register_converter

register_converter('my_format', MyFormatConverter)
```

---

## 📋 Dataset Registry

The system includes a registry of known datasets:

```python
from scripts.personality_data.registry.dataset_registry import get_dataset_info

info = get_dataset_info('big_five_kaggle')
# Returns: name, URL, format, converter, column mappings, scale
```

**Available datasets:**
- `big_five_kaggle` - Big Five Personality Test (Kaggle)
- `ipip_neo` - IPIP-NEO Personality Inventory
- `uci_personality` - UCI ML Repository Personality Dataset

---

## 🎯 Use Cases

### 1. Convert Open Datasets
```bash
python -m scripts.personality_data.cli.convert \
    data/raw/kaggle_big_five.csv \
    --dataset big_five_kaggle \
    --output data/processed/spots_profiles.json
```

### 2. Generate Test Data
```bash
python -m scripts.personality_data.cli.download \
    --output data/raw/sample.csv \
    --num-profiles 1000
```

### 3. Create Ground Truth
```python
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator

generator = GroundTruthGenerator(compatibility_threshold=0.6)
ground_truth = generator.generate(profiles, Path('ground_truth.json'))
```

### 4. Validate Datasets
```python
from scripts.personality_data.processors.dataset_validator import DatasetValidator

is_valid, errors = DatasetValidator.validate_spots_profiles(profiles)
```

---

## 📚 API Reference

### Main Functions

**`convert_dataset()`** - Convert personality dataset to SPOTS format
**`get_converter()`** - Get converter by ID
**`get_dataset_info()`** - Get dataset information
**`GroundTruthGenerator`** - Generate compatibility pairs
**`DatasetValidator`** - Validate datasets

---

## 🔗 Related Documentation

- `ARCHITECTURE.md` - Detailed architecture documentation
- `scripts/knot_validation/README_DATASETS.md` - Dataset usage guide
- `docs/plans/knot_theory/REAL_DATA_VALIDATION_SETUP.md` - Validation setup

---

**Last Updated:** December 16, 2025
