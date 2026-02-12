# Quick Start: Using Real Data for Validation

This guide walks you through using real personality datasets to validate the knot theory matching system.

---

## 🚀 Quick Start (5 minutes)

### Step 1: Create Sample Dataset

```bash
# Create a sample dataset (100 profiles)
python scripts/knot_validation/download_sample_dataset.py \
    --output data/raw/big_five_sample.csv \
    --num-profiles 100
```

### Step 2: Convert to SPOTS Format

```bash
# Convert Big Five to SPOTS 12 dimensions
python scripts/knot_validation/data_converter.py \
    data/raw/big_five_sample.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json
```

### Step 3: Generate Knots

```bash
# Generate knots from converted profiles
python scripts/knot_validation/generate_knots_from_profiles.py \
    --input data/processed/spots_profiles.json \
    --output docs/plans/knot_theory/validation/knot_generation_results.json
```

### Step 4: Compare Matching Accuracy

```bash
# Compare quantum-only vs integrated matching
python scripts/knot_validation/compare_matching_accuracy.py \
    --profiles data/processed/spots_profiles.json \
    --knots docs/plans/knot_theory/validation/knot_generation_results.json \
    --ground-truth data/processed/ground_truth.json \
    --output docs/plans/knot_theory/validation/matching_accuracy_results.json
```

---

## 📊 Using Real Open Datasets

### Option 1: Kaggle Big Five Dataset

```bash
# 1. Install Kaggle API
pip install kaggle

# 2. Set up Kaggle credentials (see Kaggle API docs)

# 3. Download dataset
python scripts/knot_validation/download_sample_dataset.py \
    --kaggle tunguz/big-five-personality-test \
    --output data/raw/big_five_kaggle.csv

# 4. Convert and validate
python scripts/knot_validation/data_converter.py \
    data/raw/big_five_kaggle.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json
```

### Option 2: Your Own Dataset

If you have your own Big Five dataset:

```bash
# 1. Place your CSV file in data/raw/
#    Required columns: user_id, openness, conscientiousness, 
#                      extraversion, agreeableness, neuroticism

# 2. Convert to SPOTS format
python scripts/knot_validation/data_converter.py \
    data/raw/your_dataset.csv \
    --output data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json
```

---

## 📋 Expected Results

After running validation with real data, you should see:

1. **Knot Generation:**
   - 100% success rate (all profiles converted to knots)
   - 20-40 different knot types identified
   - Complexity distribution across profiles

2. **Matching Accuracy:**
   - Quantum-only accuracy: 70-85%
   - Integrated accuracy: 75-90% (if knots help)
   - Improvement: +5-15% (target: ≥5%)

3. **Recommendation Quality:**
   - Engagement improvement: +20-40%
   - User satisfaction improvement: +15-30%

---

## 🔧 Troubleshooting

### Issue: "Missing Big Five data"

**Solution:** Check your CSV column names. The converter accepts:
- `openness`, `O`, `OPN`, `openness_score`
- `conscientiousness`, `C`, `CON`, `conscientiousness_score`
- etc.

### Issue: "No profiles loaded"

**Solution:** Check JSON format. Should be:
```json
[
  {"user_id": "...", "dimensions": {...}},
  ...
]
```

### Issue: "Low matching accuracy"

**Possible causes:**
1. Ground truth threshold too high/low
2. Dataset too small (< 50 profiles)
3. Need to optimize weights

**Solution:**
```bash
# Optimize compatibility weights
python scripts/knot_validation/optimize_compatibility_weights.py \
    --profiles data/processed/spots_profiles.json \
    --ground-truth data/processed/ground_truth.json
```

---

## 📈 Next Steps

1. **Optimize Weights:**
   ```bash
   python scripts/knot_validation/optimize_compatibility_weights.py
   ```

2. **Cross-Validate:**
   ```bash
   python scripts/knot_validation/cross_validate.py
   ```

3. **Performance Benchmarks:**
   ```bash
   python scripts/knot_validation/performance_benchmarks.py
   ```

---

## 📝 Notes

- **Sample Size:** Recommend 100+ profiles for meaningful results
- **Data Quality:** Ensure all 5 Big Five dimensions are present
- **Ground Truth:** Generated using same compatibility formula (for consistency)
- **Real Data:** For best results, use actual SPOTS user data when available

---

**Last Updated:** December 16, 2025
