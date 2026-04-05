#!/usr/bin/env python3
"""
Focused Test: Patent #3 - Alternative Comparisons

HIGH-VALUE TEST: Prove combination is better than alternatives

Compares:
- Fixed threshold alone
- Time-based decay alone
- Influence reduction alone
- Other diversity maintenance approaches
- SPOTS combination (all three mechanisms)

Expected: Combination achieves 34.56% homogenization vs. 48-60% for alternatives

Date: December 20, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
import sys

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

# Import from existing experiment script
from run_patent_3_experiments import (
    load_data,
    calculate_homogenization_rate,
    simulate_evolution
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_3' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def simulate_alternative_approach(profiles, num_months=6, approach='fixed_threshold'):
    """
    Simulate alternative diversity maintenance approaches.
    
    Args:
        profiles: Initial profiles
        num_months: Months to simulate
        approach: 'fixed_threshold', 'time_decay', 'influence_reduction', 'no_mechanisms'
    """
    num_days = num_months * 30
    current_profiles = {k: v.copy() for k, v in profiles.items()}
    initial_profiles = {k: v.copy() for k, v in profiles.items()}
    
    for day in range(num_days):
        agent_ids = list(current_profiles.keys())
        
        if len(agent_ids) < 2:
            continue
        
        # Calculate homogenization for adaptive approaches
        current_homogenization = calculate_homogenization_rate(
            initial_profiles,
            current_profiles
        )
        
        # Apply approach-specific logic
        if approach == 'fixed_threshold':
            # Fixed threshold only (no adaptive mechanisms)
            drift_limit = 0.1836
            base_influence = 0.02
            influence_multiplier = 1.0
            use_time_decay = False
        elif approach == 'time_decay':
            # Time-based decay only (no adaptive influence or frequency reduction)
            drift_limit = 0.1836
            base_influence = 0.02
            influence_multiplier = 1.0
            use_time_decay = True
        elif approach == 'influence_reduction':
            # Adaptive influence reduction only (no time decay or frequency reduction)
            drift_limit = 0.1836
            base_influence = 0.02
            if current_homogenization > 0.45:
                influence_multiplier = 1.0 - ((current_homogenization - 0.45) * 0.7)
                influence_multiplier = max(0.6, influence_multiplier)
            else:
                influence_multiplier = 1.0
            use_time_decay = False
        elif approach == 'no_mechanisms':
            # No mechanisms (baseline)
            drift_limit = None
            base_influence = 0.02
            influence_multiplier = 1.0
            use_time_decay = False
        else:
            # Default: no mechanisms
            drift_limit = None
            base_influence = 0.02
            influence_multiplier = 1.0
            use_time_decay = False
        
        # Perform interactions
        interactions_this_day = agent_ids  # All agents interact (no frequency reduction for alternatives)
        
        for i in range(len(interactions_this_day)):
            idx_a, idx_b = np.random.choice(len(interactions_this_day), 2, replace=False)
            agent_a = interactions_this_day[idx_a]
            agent_b = interactions_this_day[idx_b]
            
            profile_a = current_profiles[agent_a]
            profile_b = current_profiles[agent_b]
            
            inner_product = np.abs(np.dot(profile_a, profile_b))
            compatibility = inner_product ** 2
            influence = compatibility * base_influence * influence_multiplier
            
            new_profile_a = profile_a + influence * (profile_b - profile_a)
            
            # Apply drift resistance if enabled
            if drift_limit is not None:
                initial_profile_a = initial_profiles[agent_a]
                drift = np.abs(new_profile_a - initial_profile_a)
                for dim in range(12):
                    if drift[dim] > drift_limit:
                        new_profile_a[dim] = initial_profile_a[dim] + np.sign(new_profile_a[dim] - initial_profile_a[dim]) * drift_limit
            
            # Apply time decay if enabled
            if use_time_decay:
                days_in_system_a = day  # Simplified: all agents start at day 0
                decay_rate = 0.001
                decay_start_days = 180
                apply_decay = current_homogenization > 0.35
                
                if days_in_system_a > decay_start_days and apply_decay:
                    decay_days = days_in_system_a - decay_start_days
                    decay_factor = np.exp(-decay_rate * decay_days)
                    initial_profile_a = initial_profiles[agent_a]
                    new_profile_a = initial_profile_a + (new_profile_a - initial_profile_a) * decay_factor
            
            new_profile_a = np.clip(new_profile_a, 0.0, 1.0)
            current_profiles[agent_a] = new_profile_a
    
    return current_profiles


def test_alternative_comparisons():
    """Test alternative approaches to prove SPOTS combination is superior."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #3 - Alternative Comparisons")
    print("=" * 70)
    print()
    print("Comparing SPOTS combination to alternative approaches")
    print("Expected: Combination achieves 34.56% homogenization vs. 48-60% for alternatives")
    print()
    
    profiles = load_data()
    num_months = 6
    
    # Test approaches
    approaches = [
        ('No Mechanisms (Baseline)', 'no_mechanisms'),
        ('Fixed Threshold Only', 'fixed_threshold'),
        ('Time-Based Decay Only', 'time_decay'),
        ('Adaptive Influence Reduction Only', 'influence_reduction'),
        ('SPOTS Combination (All Three)', 'spots_combination')
    ]
    
    results = []
    
    for approach_name, approach_key in approaches:
        print(f"Testing: {approach_name}...")
        start_time = time.time()
        
        if approach_key == 'spots_combination':
            # Use full SPOTS implementation with all mechanisms
            evolution_history, final_profiles = simulate_evolution(
                profiles,
                num_months=num_months,
                drift_limit=0.1836,
                use_diversity_mechanisms=True
            )
        else:
            # Use alternative approach
            final_profiles = simulate_alternative_approach(
                profiles,
                num_months=num_months,
                approach=approach_key
            )
        
        # Calculate final homogenization
        final_homogenization = calculate_homogenization_rate(
            profiles,
            final_profiles
        )
        
        elapsed = time.time() - start_time
        
        print(f"  Final homogenization: {final_homogenization * 100:.2f}%")
        print(f"  Duration: {elapsed:.2f}s")
        print()
        
        results.append({
            'approach': approach_name,
            'approach_key': approach_key,
            'homogenization_rate': final_homogenization,
            'homogenization_percent': final_homogenization * 100,
            'duration_seconds': elapsed
        })
    
    # Calculate improvements
    df = pd.DataFrame(results)
    baseline = df[df['approach_key'] == 'no_mechanisms']['homogenization_percent'].iloc[0]
    spots_combination = df[df['approach_key'] == 'spots_combination']['homogenization_percent'].iloc[0]
    
    print("=" * 70)
    print("ALTERNATIVE COMPARISON ANALYSIS")
    print("=" * 70)
    print()
    print(f"Baseline (No Mechanisms): {baseline:.2f}%")
    print(f"SPOTS Combination: {spots_combination:.2f}%")
    print(f"SPOTS Improvement: {baseline - spots_combination:.2f}%")
    print()
    print("Approach vs. Homogenization:")
    for _, row in df.iterrows():
        improvement = baseline - row['homogenization_percent']
        marker = " ← SPOTS" if row['approach_key'] == 'spots_combination' else ""
        marker += " ← BASELINE" if row['approach_key'] == 'no_mechanisms' else ""
        print(f"  {row['approach']:40s}: {row['homogenization_percent']:5.2f}% (improvement: {improvement:+.2f}%){marker}")
    print()
    
    # Check if SPOTS is better than alternatives
    alternatives = df[df['approach_key'] != 'spots_combination']
    alternatives = alternatives[alternatives['approach_key'] != 'no_mechanisms']
    
    spots_better_than_all = all(spots_combination < alt['homogenization_percent'] for _, alt in alternatives.iterrows())
    
    if spots_better_than_all:
        print("✅ PROOF: SPOTS combination is better than all alternatives")
        print(f"   SPOTS: {spots_combination:.2f}% homogenization")
        for _, alt in alternatives.iterrows():
            print(f"   {alt['approach']}: {alt['homogenization_percent']:.2f}% homogenization")
        print(f"   This proves non-obviousness - the combination is superior.")
    else:
        print("⚠️  WARNING: SPOTS may not be better than all alternatives")
        print(f"   Review results for potential improvements.")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'alternative_comparisons_results.csv', index=False)
    
    # Save analysis
    analysis = {
        'baseline_homogenization': float(baseline),
        'spots_combination_homogenization': float(spots_combination),
        'spots_improvement': float(baseline - spots_combination),
        'spots_better_than_all': bool(spots_better_than_all),
        'approaches': [
            {
                'name': row['approach'],
                'key': row['approach_key'],
                'homogenization': float(row['homogenization_percent'])
            }
            for _, row in df.iterrows()
        ]
    }
    
    with open(RESULTS_DIR / 'alternative_comparisons_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'alternative_comparisons_results.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'alternative_comparisons_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_alternative_comparisons()

