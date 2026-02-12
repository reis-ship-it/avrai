# Using Open Datasets for Knot Theory Validation

This guide explains how to use open personality datasets to validate the knot theory matching system.

---

## 📊 Available Open Datasets

### 1. Big Five Personality Dataset (Kaggle)

**URL:** `https://www.kaggle.com/datasets/tunguz/big-five-personality-test`

**Description:**
- 1M+ responses to Big Five personality test
- Contains: Openness, Conscientiousness, Extraversion, Agreeableness, Neuroticism
- Format: CSV

**Download:**
```bash
# Requires Kaggle API (install: pip install kaggle)
kaggle datasets download -d tunguz/big-five-personality-test
unzip big-five-personality-test.zip
```

**Usage:**
```bash
python scripts/knot_validation/data_converter.py data-raw.csv \
    --output data_spots.json \
    --ground-truth ground_truth.json
```

---

### 2. IPIP-NEO Personality Inventory

**URL:** `https://openpsychometrics.org/_rawdata/`

**Description:**
- Open-source Big Five inventory
- Multiple datasets available
- Format: CSV/JSON

**Download:**
```bash
# Download from OpenPsychometrics
wget https://openpsychometrics.org/_rawdata/IPIP-FFM-data-8Nov2018.zip
unzip IPIP-FFM-data-8Nov2018.zip
```

---

### 3. Personality Dataset (UCI ML Repository)

**URL:** `https://archive.ics.uci.edu/ml/datasets/Personality+prediction`

**Description:**
- Personality traits and behavioral data
- Format: CSV

**Download:**
```bash
wget https://archive.ics.uci.edu/ml/machine-learning-databases/personality/personality.data
```

---

## 🔄 Data Conversion Process

### Step 1: Download Dataset

Choose one of the datasets above and download it to `data/raw/`:

```bash
mkdir -p data/raw
# Download your chosen dataset here
```

### Step 2: Convert to SPOTS Format

Use the data converter to convert Big Five scores to SPOTS 12 dimensions:

```bash
python scripts/knot_validation/data_converter.py \
    data/raw/big_five_dataset.csv \
    --output data/processed/spots_profiles.json \
    --format csv
```

**Output:** `data/processed/spots_profiles.json` with SPOTS-formatted profiles

### Step 3: Create Ground Truth

Generate ground truth compatibility pairs:

```bash
python scripts/knot_validation/data_converter.py \
    data/raw/big_five_dataset.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json \
    --threshold 0.6 \
    --noise 0.05
```

**Parameters:**
- `--threshold`: Compatibility threshold (0.6 = 60% compatibility)
- `--noise`: Noise level for realism (0.05 = 5% standard deviation)

---

## 🧪 Running Validation with Real Data

### Step 1: Generate Knots from Real Profiles

```bash
python scripts/knot_validation/generate_knots_from_profiles.py \
    --input data/processed/spots_profiles.json \
    --output docs/plans/knot_theory/validation/knot_generation_results.json
```

### Step 2: Compare Matching Accuracy

```bash
python scripts/knot_validation/compare_matching_accuracy.py \
    --profiles data/processed/spots_profiles.json \
    --knots docs/plans/knot_theory/validation/knot_generation_results.json \
    --ground-truth data/processed/ground_truth.json \
    --output docs/plans/knot_theory/validation/matching_accuracy_results.json
```

### Step 3: Analyze Recommendations

```bash
python scripts/knot_validation/analyze_recommendation_improvement.py \
    --profiles data/processed/spots_profiles.json \
    --knots docs/plans/knot_theory/validation/knot_generation_results.json \
    --output docs/plans/knot_theory/validation/recommendation_improvement_results.json
```

### Step 4: Assess Research Value

```bash
python scripts/knot_validation/assess_research_value.py \
    --knots docs/plans/knot_theory/validation/knot_generation_results.json \
    --output docs/plans/knot_theory/validation/research_value_assessment.json
```

---

## 📋 Expected Dataset Format

### Input CSV Format (Big Five)

```csv
user_id,openness,conscientiousness,extraversion,agreeableness,neuroticism
user_1,4.2,3.8,4.5,4.1,2.3
user_2,3.5,4.2,3.9,4.5,2.8
...
```

**Column Names (accepted variations):**
- Openness: `openness`, `O`, `OPN`, `openness_score`
- Conscientiousness: `conscientiousness`, `C`, `CON`, `conscientiousness_score`
- Extraversion: `extraversion`, `E`, `EXT`, `extraversion_score`
- Agreeableness: `agreeableness`, `A`, `AGR`, `agreeableness_score`
- Neuroticism: `neuroticism`, `N`, `NEU`, `neuroticism_score`

**Value Ranges:**
- 1-5 scale: Automatically normalized to 0.0-1.0
- 0-1 scale: Used as-is
- 0-100 scale: Automatically normalized to 0.0-1.0

### Output JSON Format (SPOTS)

```json
[
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
      "big_five": {
        "openness": 4.2,
        "conscientiousness": 3.8,
        "extraversion": 4.5,
        "agreeableness": 4.1,
        "neuroticism": 2.3
      }
    }
  }
]
```

---

## 🎯 Quick Start Example

```bash
# 1. Download sample dataset (or use your own)
# Place in data/raw/big_five_sample.csv

# 2. Convert to SPOTS format
python scripts/knot_validation/data_converter.py \
    data/raw/big_five_sample.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json

# 3. Run full validation
./scripts/knot_validation/run_all_validation.sh \
    --profiles data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json
```

---

## 📝 Notes

1. **Data Quality:** Ensure your dataset has all 5 Big Five dimensions
2. **Sample Size:** Recommend 100+ profiles for meaningful validation
3. **Ground Truth:** Ground truth is generated using the same compatibility formula (for consistency)
4. **Noise:** Add noise to ground truth to simulate real-world variability

---

## 🔗 Resources

- **Kaggle Datasets:** https://www.kaggle.com/datasets
- **OpenPsychometrics:** https://openpsychometrics.org/_rawdata/
- **UCI ML Repository:** https://archive.ics.uci.edu/ml/index.php

---

**Last Updated:** December 16, 2025
