# Integration Implementation Guide - Dynamic Diversity Mechanisms

**Date:** December 19, 2025  
**Purpose:** Step-by-step guide to integrate dynamic diversity mechanisms into Experiments 1-3  
**Status:** Implementation Guide

---

## 🎯 **Quick Reference: What to Change**

### **File to Modify:**
`docs/patents/experiments/scripts/run_patent_3_experiments.py`

### **Functions to Update:**
1. `simulate_evolution()` - Add mechanisms
2. `experiment_1_threshold_testing()` - Test with/without mechanisms
3. `experiment_2_homogenization_evidence()` - Add mechanisms-only scenario
4. `experiment_3_solution_effectiveness()` - Add all scenarios

---

## 📝 **Step-by-Step Implementation**

### **Step 1: Update `simulate_evolution()` Function**

**Current Function Signature:**
```python
def simulate_evolution(profiles, num_months=6, drift_limit=None):
```

**New Function Signature:**
```python
def simulate_evolution(profiles, num_months=6, drift_limit=None, use_diversity_mechanisms=False):
```

**Changes to Make:**

1. **Add homogenization calculation** (after line 50):
```python
# Calculate current homogenization for adaptive mechanisms
if use_diversity_mechanisms and len(current_profiles) > 1:
    current_homogenization = calculate_homogenization_rate(
        initial_profiles,
        current_profiles
    )
else:
    current_homogenization = 0.0
```

2. **Add adaptive influence reduction** (replace line 69):
```python
# Mechanism 1: Adaptive Influence Reduction
base_influence = 0.02
if use_diversity_mechanisms:
    if current_homogenization > 0.45:
        influence_multiplier = 1.0 - ((current_homogenization - 0.45) * 0.7)
        influence_multiplier = max(0.6, influence_multiplier)
    else:
        influence_multiplier = 1.0
else:
    influence_multiplier = 1.0

influence = compatibility * base_influence * influence_multiplier
```

3. **Add interaction frequency reduction** (before line 57):
```python
# Mechanism 3: Interaction Frequency Reduction
interactions_this_day = []
if use_diversity_mechanisms:
    for agent_id in agent_ids:
        days_in_system = day  # All agents start at day 0
        interaction_probability = 1.0 / (1.0 + days_in_system / 180.0)
        if np.random.random() < interaction_probability:
            interactions_this_day.append(agent_id)
else:
    interactions_this_day = agent_ids

if len(interactions_this_day) < 2:
    interactions_this_day = agent_ids  # Fallback
```

4. **Update interaction loop** (replace line 58):
```python
num_interactions = len(interactions_this_day)
for i in range(num_interactions):
    idx_a, idx_b = np.random.choice(len(interactions_this_day), 2, replace=False)
    agent_a = interactions_this_day[idx_a]
    agent_b = interactions_this_day[idx_b]
```

5. **Add conditional time-based drift decay** (after drift resistance, before line 83):
```python
# Mechanism 2: Conditional Time-Based Drift Decay
if use_diversity_mechanisms:
    days_in_system_a = day  # All agents start at day 0
    decay_rate = 0.001
    decay_start_days = 180
    apply_decay = current_homogenization > 0.35
    
    if days_in_system_a > decay_start_days and apply_decay:
        decay_days = days_in_system_a - decay_start_days
        decay_factor = np.exp(-decay_rate * decay_days)
        new_profile_a = initial_profile_a + (new_profile_a - initial_profile_a) * decay_factor
```

---

### **Step 2: Update Experiment 1**

**Current Function:**
```python
def experiment_1_threshold_testing(num_months=6):
```

**New Function:**
```python
def experiment_1_threshold_testing(num_months=6, use_mechanisms=False):
    """Experiment 1: Threshold Testing with optional diversity mechanisms."""
    # ... existing code ...
    
    for threshold, name in zip(thresholds, threshold_names):
        evolution_history, final_profiles = simulate_evolution(
            initial_profiles,
            num_months=num_months,
            drift_limit=threshold,
            use_diversity_mechanisms=use_mechanisms  # ADD THIS
        )
        # ... rest of code ...
```

**Add Comparison Function:**
```python
def experiment_1_threshold_testing_comparison(num_months=6):
    """Run Experiment 1 with and without mechanisms for comparison."""
    results_baseline = experiment_1_threshold_testing(num_months, use_mechanisms=False)
    results_with_mechanisms = experiment_1_threshold_testing(num_months, use_mechanisms=True)
    
    # Save comparison
    comparison = []
    for baseline, improved in zip(results_baseline, results_with_mechanisms):
        improvement = baseline['homogenization_rate'] - improved['homogenization_rate']
        comparison.append({
            'threshold': baseline['threshold'],
            'baseline_homogenization': baseline['homogenization_rate'],
            'with_mechanisms_homogenization': improved['homogenization_rate'],
            'improvement': improvement,
            'improvement_percent': improvement / baseline['homogenization_rate'] * 100 if baseline['homogenization_rate'] > 0 else 0
        })
    
    df = pd.DataFrame(comparison)
    df.to_csv(RESULTS_DIR / f'threshold_testing_comparison_{num_months}months.csv', index=False)
    
    return comparison
```

---

### **Step 3: Update Experiment 2**

**Current Function:**
```python
def experiment_2_homogenization_evidence(num_months=6):
```

**New Function:**
```python
def experiment_2_homogenization_evidence(num_months=6):
    """Experiment 2: Homogenization Problem Evidence with mechanism comparison."""
    initial_profiles = load_data()
    
    # Scenario 1: Without drift resistance (baseline)
    _, final_no_resistance = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=None, use_diversity_mechanisms=False
    )
    
    # Scenario 2: With mechanisms but NO drift limit (NEW)
    _, final_with_mechanisms = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=None, use_diversity_mechanisms=True
    )
    
    # Scenario 3: With mechanisms AND 18.36% drift limit (full solution)
    _, final_full_solution = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=0.1836, use_diversity_mechanisms=True
    )
    
    # Calculate results for all scenarios
    # ... (see full implementation in main document)
```

---

### **Step 4: Update Experiment 3**

**Current Function:**
```python
def experiment_3_solution_effectiveness(num_months=6):
```

**New Function:**
```python
def experiment_3_solution_effectiveness(num_months=6):
    """Experiment 3: Solution Effectiveness with mechanism comparison."""
    initial_profiles = load_data()
    
    # Scenario 1: Baseline (no resistance, no mechanisms)
    _, final_baseline = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=None, use_diversity_mechanisms=False
    )
    
    # Scenario 2: 18.36% threshold only (no mechanisms)
    _, final_threshold_only = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=0.1836, use_diversity_mechanisms=False
    )
    
    # Scenario 3: Mechanisms only (no threshold) - NEW
    _, final_mechanisms_only = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=None, use_diversity_mechanisms=True
    )
    
    # Scenario 4: Full solution (18.36% threshold + mechanisms) - NEW
    _, final_full_solution = simulate_evolution(
        initial_profiles, num_months=num_months, drift_limit=0.1836, use_diversity_mechanisms=True
    )
    
    # Calculate all metrics
    # ... (see full implementation in main document)
```

---

## 🧪 **Testing the Integration**

### **Test 1: Verify Mechanisms Work**

```python
# Run Experiment 1 with mechanisms
results = experiment_1_threshold_testing(num_months=6, use_mechanisms=True)

# Check 18.36% threshold result
threshold_1836 = [r for r in results if r['threshold'] == '18.36%'][0]
assert threshold_1836['homogenization_rate'] < 0.50, "Should be < 50%"
assert threshold_1836['homogenization_rate'] > 0.20, "Should be > 20% (healthy range)"
print(f"✅ 18.36% threshold with mechanisms: {threshold_1836['homogenization_rate']:.2%}")
```

### **Test 2: Verify Improvement**

```python
# Run comparison
comparison = experiment_1_threshold_testing_comparison(num_months=6)

# Check improvement at 18.36%
improvement_1836 = [c for c in comparison if c['threshold'] == '18.36%'][0]
assert improvement_1836['improvement'] > 0.10, "Should improve by > 10%"
print(f"✅ Improvement at 18.36%: {improvement_1836['improvement']:.2%}")
```

### **Test 3: Verify All Scenarios**

```python
# Run Experiment 3
results = experiment_3_solution_effectiveness(num_months=6)

# Verify full solution is best
assert results['full_solution_homogenization'] < results['threshold_only_homogenization']
assert results['full_solution_homogenization'] < results['mechanisms_only_homogenization']
print(f"✅ Full solution homogenization: {results['full_solution_homogenization']:.2%}")
```

---

## 📊 **Expected Output Files**

### **New CSV Files:**

1. **`threshold_testing_comparison_{months}months.csv`**
   - Columns: threshold, baseline_homogenization, with_mechanisms_homogenization, improvement, improvement_percent

2. **`homogenization_evidence_comparison_{months}months.csv`**
   - Columns: scenario, homogenization_rate, diversity_preserved, prevention_rate

3. **`solution_effectiveness_comparison_{months}months.csv`**
   - Columns: scenario, homogenization_rate, prevention_rate, mechanism_improvement

---

## ✅ **Validation Checklist**

After implementation, verify:

- [ ] `simulate_evolution()` accepts `use_diversity_mechanisms` parameter
- [ ] Mechanisms are implemented correctly
- [ ] Experiment 1 runs with/without mechanisms
- [ ] Experiment 2 includes mechanisms-only scenario
- [ ] Experiment 3 includes all scenarios
- [ ] Results show improvement (48% → 34.56% for 18.36% threshold)
- [ ] CSV files are generated correctly
- [ ] Results match expected values

---

## 🎯 **Success Metrics**

**Integration Successful If:**
1. ✅ Experiment 1: 18.36% threshold → 34.56% homogenization (with mechanisms)
2. ✅ Experiment 2: Mechanisms alone → 60-70% homogenization (vs. 100% baseline)
3. ✅ Experiment 3: Full solution → 34.56% homogenization (65.44% prevention)
4. ✅ All experiments demonstrate mechanism effectiveness
5. ✅ Results support Claim 5 (Dynamic Diversity Maintenance System)

---

**Last Updated:** December 19, 2025

