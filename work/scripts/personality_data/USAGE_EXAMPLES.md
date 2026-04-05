# Personality Data System - Usage Examples

Practical examples for using the personality data conversion system.

---

## 📋 Basic Conversion

### Convert CSV Dataset

```bash
python -m scripts.personality_data.cli.convert \
    data/raw/big_five.csv \
    --output data/processed/spots_profiles.json \
    --source big_five
```

### Convert JSON Dataset

```bash
python -m scripts.personality_data.cli.convert \
    data/raw/personality_data.json \
    --output data/processed/spots_profiles.json \
    --source big_five \
    --format json
```

---

## 📊 Using Dataset Registry

### Convert with Registered Dataset

```bash
# Uses dataset metadata (column mappings, scale, etc.)
python -m scripts.personality_data.cli.convert \
    data/raw/kaggle_big_five.csv \
    --dataset big_five_kaggle \
    --output data/processed/spots_profiles.json
```

### List Available Datasets

```bash
python -m scripts.personality_data.cli.convert --list-datasets
```

**Output:**
```
Available datasets:
  big_five_kaggle: Big Five Personality Test (Kaggle)
    URL: https://www.kaggle.com/datasets/tunguz/big-five-personality-test
  ipip_neo: IPIP-NEO Personality Inventory
    URL: https://openpsychometrics.org/_rawdata/
  uci_personality: Personality Dataset (UCI ML Repository)
    URL: https://archive.ics.uci.edu/ml/datasets/Personality+prediction
```

---

## 🎯 Ground Truth Generation

### Convert and Generate Ground Truth

```bash
python -m scripts.personality_data.cli.convert \
    data/raw/big_five.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json \
    --threshold 0.6 \
    --noise 0.05
```

**Parameters:**
- `--threshold`: Compatibility threshold (0.6 = 60% compatibility)
- `--noise`: Noise level for realism (0.05 = 5% standard deviation)

---

## 🐍 Python API Examples

### Basic Conversion

```python
from scripts.personality_data.converter import convert_dataset
from pathlib import Path

profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)

print(f"Converted {len(profiles)} profiles")
```

### Using Registry

```python
from scripts.personality_data.registry import get_dataset_info, get_converter

# Get dataset info
info = get_dataset_info('big_five_kaggle')
print(f"Dataset: {info['name']}")
print(f"URL: {info['url']}")

# Get converter
converter_class = get_converter('big_five_to_spots')
converter = converter_class()
```

### Generate Ground Truth

```python
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator
from scripts.personality_data.loaders.json_loader import JSONLoader
from pathlib import Path

# Load profiles
profiles = JSONLoader.load(Path('data/processed/spots_profiles.json'))

# Generate ground truth
generator = GroundTruthGenerator(
    compatibility_threshold=0.6,
    noise_level=0.05
)
ground_truth = generator.generate(
    profiles,
    Path('data/processed/ground_truth.json')
)

print(f"Generated {len(ground_truth)} pairs")
```

### Validate Dataset

```python
from scripts.personality_data.processors.dataset_validator import DatasetValidator
from scripts.personality_data.loaders.json_loader import JSONLoader
from pathlib import Path

# Load profiles
profiles = JSONLoader.load(Path('data/processed/spots_profiles.json'))

# Validate
is_valid, errors = DatasetValidator.validate_spots_profiles(profiles)

if is_valid:
    print("✅ Dataset is valid")
else:
    print(f"❌ Dataset has {len(errors)} errors:")
    for error in errors[:10]:
        print(f"  - {error}")
```

---

## 🔬 Experiment Examples

### Example 1: Compatibility Matching Experiment

```python
from scripts.personality_data.converter import convert_dataset
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator
from pathlib import Path

# Convert dataset
profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)

# Generate ground truth
generator = GroundTruthGenerator(compatibility_threshold=0.6)
ground_truth = generator.generate(profiles, Path('data/processed/ground_truth.json'))

# Use in your experiment
for pair in ground_truth:
    if pair['is_compatible']:
        # Test your matching algorithm
        pass
```

### Example 2: Personality Distribution Analysis

```python
from scripts.personality_data.converter import convert_dataset
from scripts.personality_data.loaders.json_loader import JSONLoader
import statistics
from pathlib import Path

# Convert dataset
profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)

# Analyze dimension distributions
dimensions = ['exploration_eagerness', 'community_orientation', 'social_preference']
for dim in dimensions:
    values = [p['dimensions'][dim] for p in profiles]
    print(f"{dim}:")
    print(f"  Mean: {statistics.mean(values):.3f}")
    print(f"  Std: {statistics.stdev(values):.3f}")
    print(f"  Range: [{min(values):.3f}, {max(values):.3f}]")
```

### Example 3: Archetype Analysis

```python
from scripts.personality_data.converter import convert_dataset
from scripts.personality_data.utils.archetype_inference import infer_archetype
from collections import Counter
from pathlib import Path

# Convert dataset
profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)

# Analyze archetypes
archetypes = [infer_archetype(p['dimensions']) for p in profiles]
archetype_counts = Counter(archetypes)

print("Archetype Distribution:")
for archetype, count in archetype_counts.most_common():
    percentage = (count / len(profiles)) * 100
    print(f"  {archetype}: {count} ({percentage:.1f}%)")
```

---

## 🔄 Workflow Examples

### Complete Validation Workflow

```bash
# 1. Download/create dataset
python -m scripts.personality_data.cli.download \
    --output data/raw/big_five_sample.csv \
    --num-profiles 100

# 2. Convert to SPOTS format
python -m scripts.personality_data.cli.convert \
    data/raw/big_five_sample.csv \
    --output data/processed/spots_profiles.json \
    --source big_five

# 3. Generate ground truth
python -m scripts.personality_data.cli.convert \
    data/raw/big_five_sample.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json \
    --source big_five

# 4. Use in validation
python scripts/knot_validation/generate_knots_from_profiles.py \
    --input data/processed/spots_profiles.json \
    --output docs/plans/knot_theory/validation/knot_generation_results.json

python scripts/knot_validation/compare_matching_accuracy.py \
    --profiles data/processed/spots_profiles.json \
    --knots docs/plans/knot_theory/validation/knot_generation_results.json \
    --ground-truth data/processed/ground_truth.json
```

---

## 🛠️ Advanced Usage

### Custom Converter

```python
from scripts.personality_data.converters.base import PersonalityConverter
from scripts.personality_data.registry.converter_registry import register_converter

class MyFormatConverter(PersonalityConverter):
    def convert(self, source_data):
        # Your conversion logic
        return spots_dimensions
    
    def validate_source(self, source_data):
        return 'field1' in source_data and 'field2' in source_data
    
    def get_source_format(self):
        return 'my_format'
    
    def get_required_fields(self):
        return ['field1', 'field2']

# Register
register_converter('my_format', MyFormatConverter)

# Use
from scripts.personality_data.converter import convert_dataset
profiles = convert_dataset(..., source_format='my_format')
```

### Custom Dataset Registration

```python
from scripts.personality_data.registry.dataset_registry import register_dataset

register_dataset('my_dataset', {
    'name': 'My Custom Dataset',
    'url': 'https://example.com/dataset',
    'format': 'csv',
    'converter': 'big_five',
    'columns': {
        'openness': ['O', 'openness'],
        'conscientiousness': ['C', 'conscientiousness'],
        # ...
    },
    'scale': '1-5',
})

# Use
python -m scripts.personality_data.cli.convert \
    data/raw/my_dataset.csv \
    --dataset my_dataset \
    --output data/processed/spots.json
```

---

## 📝 Notes

- All file paths can be relative or absolute
- Output directories are created automatically
- Validation is enabled by default (use `--no-validate` to skip)
- Ground truth uses same compatibility formula as matching system (for consistency)

---

**Last Updated:** December 16, 2025
