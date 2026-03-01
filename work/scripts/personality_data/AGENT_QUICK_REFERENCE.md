# Personality Data System - Agent Quick Reference

**For other agents:** Quick guide to using the personality data conversion system.

---

## 🎯 What This System Does

Converts personality datasets (Big Five, MBTI, etc.) to SPOTS 12-dimension format for use in experiments, validation, and research.

---

## 🚀 Quick Start

### Convert a Dataset

```bash
python -m scripts.personality_data.cli.convert \
    data/raw/big_five.csv \
    --output data/processed/spots_profiles.json \
    --source big_five
```

### Use in Python

```python
from scripts.personality_data.converter import convert_dataset
from pathlib import Path

profiles = convert_dataset(
    Path('data/raw/big_five.csv'),
    Path('data/processed/spots_profiles.json'),
    source_format='big_five'
)
```

---

## 📍 Key Files

- **Main converter:** `scripts/personality_data/converter.py`
- **CLI tools:** `scripts/personality_data/cli/convert.py`
- **Documentation:** `scripts/personality_data/README.md`
- **Architecture:** `scripts/personality_data/ARCHITECTURE.md`

---

## 🔧 Available Converters

- `big_five` / `big_five_to_spots` / `ocean` - Big Five (OCEAN) → SPOTS

**List all:**
```bash
python -m scripts.personality_data.cli.convert --list-converters
```

---

## 📊 Available Datasets

- `big_five_kaggle` - Big Five Personality Test (Kaggle)
- `ipip_neo` - IPIP-NEO Personality Inventory
- `uci_personality` - UCI ML Repository

**List all:**
```bash
python -m scripts.personality_data.cli.convert --list-datasets
```

---

## 💡 Common Use Cases

### 1. Convert Open Dataset
```bash
python -m scripts.personality_data.cli.convert \
    data/raw/dataset.csv \
    --dataset big_five_kaggle \
    --output data/processed/spots.json
```

### 2. Generate Ground Truth
```bash
python -m scripts.personality_data.cli.convert \
    data/raw/dataset.csv \
    --output data/processed/spots.json \
    --ground-truth data/processed/ground_truth.json
```

### 3. Use in Experiment
```python
from scripts.personality_data.converter import convert_dataset
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator

# Convert
profiles = convert_dataset(...)

# Generate ground truth
generator = GroundTruthGenerator()
ground_truth = generator.generate(profiles)
```

---

## 🔗 Integration Points

- **Knot validation:** Uses converted profiles for knot generation
- **Matching experiments:** Uses ground truth for accuracy testing
- **Recommendation testing:** Uses profiles for recommendation quality
- **Any experiment:** Needs SPOTS-formatted personality data

---

## 📚 Full Documentation

- **User Guide:** `scripts/personality_data/README.md`
- **Architecture:** `scripts/personality_data/ARCHITECTURE.md`
- **Dataset Guide:** `scripts/knot_validation/README_DATASETS.md`

---

**Last Updated:** December 16, 2025
