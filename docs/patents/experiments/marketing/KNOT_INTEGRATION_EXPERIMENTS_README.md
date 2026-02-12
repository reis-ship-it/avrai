# Knot Integration Experiments

**Date:** December 28, 2025  
**Purpose:** Validate knot integration improvements in recommendation and matching services

---

## Overview

These experiments validate the improvements from integrating knot topology into:
1. **EventRecommendationService** - Recommendation quality
2. **EventMatchingService** - Matching accuracy
3. **SpotVibeMatchingService** - Spot-user compatibility

---

## Experiments

### 1. Knot-Enhanced Recommendation Experiment

**File:** `run_knot_recommendation_experiment.py`

**Purpose:** Compare EventRecommendationService with/without knot integration

**Control Group:** Quantum-only compatibility (baseline)
- Formula: 70% quantum + 20% location + 10% expertise

**Test Group:** Integrated compatibility (quantum + knot)
- Formula: 70% quantum + 30% knot (for compatibility)
- Then: 35% matching + 35% preferences + 15% cross-locality + 15% knot

**Metrics:**
- Click rate
- Conversion rate
- Average compatibility score
- Total engagement

**Expected Improvements:**
- 5-15% improvement in click rate
- 5-15% improvement in conversion rate
- 5-10% improvement in compatibility scores

---

### 2. Knot-Enhanced Matching Experiment

**File:** `run_knot_matching_experiment.py`

**Purpose:** Compare EventMatchingService with/without knot integration

**Control Group:** Quantum-only matching (baseline)
- Uses quantum compatibility and expertise matching

**Test Group:** Integrated matching (quantum + knot)
- Formula: 93% quantum + 7% knot topology

**Metrics:**
- Matching score accuracy
- Connection rate
- User satisfaction
- Connection probability

**Expected Improvements:**
- 3-7% improvement in matching score
- 5-10% improvement in connection rate
- 5-10% improvement in user satisfaction

---

### 3. Knot-Enhanced Spot Matching Experiment

**File:** `run_knot_spot_matching_experiment.py`

**Purpose:** Compare SpotVibeMatchingService with/without knot integration

**Control Group:** Vibe-only compatibility (baseline)
- Cosine similarity between user personality and spot vibe

**Test Group:** Integrated compatibility (vibe + knot)
- Formula: 85% vibe + 15% knot topology

**Metrics:**
- Compatibility score
- Calling rate (spots that "call" users)
- User satisfaction

**Expected Improvements:**
- 5-10% improvement in compatibility score
- 5-10% improvement in calling accuracy
- 5-10% improvement in user satisfaction

---

## Running Experiments

### Run Individual Experiment

```bash
cd docs/patents/experiments/marketing
source ../venv/bin/activate
python3 run_knot_recommendation_experiment.py
python3 run_knot_matching_experiment.py
python3 run_knot_spot_matching_experiment.py
```

### Run All Experiments

```bash
cd docs/patents/experiments/marketing
source ../venv/bin/activate
python3 run_all_knot_integration_experiments.py
```

---

## Results Structure

Each experiment generates:

- `control_*.csv` - Control group detailed results
- `test_*.csv` - Test group detailed results
- `analysis.json` - Statistical analysis (p-values, effect sizes)
- `REPORT.md` - Comprehensive markdown report

**Results directories:**
- `results/knot_recommendation/` - Recommendation experiment results
- `results/knot_matching/` - Matching experiment results
- `results/knot_spot_matching/` - Spot matching experiment results

---

## Statistical Validation

All experiments use:
- **T-tests** for continuous metrics (compatibility, satisfaction)
- **Chi-square tests** for categorical metrics (connection rate, calling rate)
- **Effect sizes** (Cohen's d) for practical significance
- **Significance threshold:** p < 0.01
- **Large effect threshold:** |Cohen's d| > 1.0

---

## Expected Runtime

- **Recommendation Experiment:** ~2-3 minutes (1,000 users × 500 events)
- **Matching Experiment:** ~2-3 minutes (1,000 users × 500 events × 10 matches)
- **Spot Matching Experiment:** ~2-3 minutes (1,000 users × 500 spots × 20 matches)
- **All Experiments:** ~6-9 minutes total

---

## Dependencies

- `numpy` - Numerical computations
- `pandas` - Data manipulation
- `scipy` - Statistical tests
- `shared_data_model` - Shared user/event data structures
- `knot_validation` (optional) - Knot generation (falls back to simplified version if unavailable)

---

## Notes

- Experiments use simplified knot generation if full knot validation is unavailable
- All experiments use same random seed (42) for reproducibility
- Statistical significance requires p < 0.01
- Large effect sizes (Cohen's d > 1.0) indicate practical significance

---

**Last Updated:** December 28, 2025
