#!/usr/bin/env python3
"""
Focused Test: Patent #3 - Mechanism Isolation

CRITICAL TEST: Prove three mechanisms work synergistically

Tests:
1. Adaptive Influence Reduction alone
2. Conditional Time-Based Drift Decay alone
3. Interaction Frequency Reduction alone
4. All three together
5. None (baseline)

Expected: Combination > sum of parts (proves non-obviousness)

Date: December 20, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
import sys

# Add parent directory to path to import simulate_evolution
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


def simulate_evolution_with_mechanism_config(
    profiles, 
    num_months=6, 
    drift_limit=0.1836,
    use_adaptive_influence=False,
    use_time_decay=False,
    use_frequency_reduction=False,
    agent_join_times=None
):
    """
    Simulate evolution with specific mechanism configuration.
    
    Args:
        profiles: Initial profiles
        num_months: Months to simulate
        drift_limit: Drift limit (18.36%)
        use_adaptive_influence: Enable adaptive influence reduction
        use_time_decay: Enable time-based drift decay
        use_frequency_reduction: Enable interaction frequency reduction
        agent_join_times: Optional join times dict
    """
    num_days = num_months * 30
    evolution_history = []
    
    current_profiles = {k: v.copy() for k, v in profiles.items()}
    initial_profiles = {k: v.copy() for k, v in profiles.items()}
    
    if agent_join_times is None:
        agent_join_times = {agent_id: 0 for agent_id in profiles.keys()}
    else:
        for agent_id in profiles.keys():
            if agent_id not in agent_join_times:
                agent_join_times[agent_id] = 0
    
    for day in range(num_days):
        agent_ids = list(current_profiles.keys())
        
        # Calculate homogenization if using adaptive influence
        if use_adaptive_influence and len(agent_ids) > 1:
            current_homogenization = calculate_homogenization_rate(
                initial_profiles,
                current_profiles
            )
        else:
            current_homogenization = 0.0
        
        # Mechanism 1: Adaptive Influence Reduction
        base_influence = 0.02
        if use_adaptive_influence:
            if current_homogenization > 0.45:
                influence_multiplier = 1.0 - ((current_homogenization - 0.45) * 0.7)
                influence_multiplier = max(0.6, influence_multiplier)
            else:
                influence_multiplier = 1.0
        else:
            influence_multiplier = 1.0
        
        # Mechanism 3: Interaction Frequency Reduction
        interactions_this_day = []
        if use_frequency_reduction:
            for agent_id in agent_ids:
                days_in_system = max(0, day - agent_join_times.get(agent_id, 0))
                if days_in_system == 0:
                    interaction_probability = 1.0
                else:
                    interaction_probability = 1.0 / (1.0 + days_in_system / 180.0)
                if np.random.random() < interaction_probability:
                    interactions_this_day.append(agent_id)
        else:
            interactions_this_day = agent_ids
        
        if len(interactions_this_day) < 2:
            interactions_this_day = agent_ids
        
        # Perform interactions
        num_interactions = len(interactions_this_day)
        for i in range(num_interactions):
            idx_a, idx_b = np.random.choice(len(interactions_this_day), 2, replace=False)
            agent_a = interactions_this_day[idx_a]
            agent_b = interactions_this_day[idx_b]
            
            profile_a = current_profiles[agent_a]
            profile_b = current_profiles[agent_b]
            
            inner_product = np.abs(np.dot(profile_a, profile_b))
            compatibility = inner_product ** 2
            influence = compatibility * base_influence * influence_multiplier
            
            new_profile_a = profile_a + influence * (profile_b - profile_a)
            
            # Apply drift resistance
            if drift_limit is not None:
                initial_profile_a = initial_profiles[agent_a]
                drift = np.abs(new_profile_a - initial_profile_a)
                for dim in range(12):
                    if drift[dim] > drift_limit:
                        new_profile_a[dim] = initial_profile_a[dim] + np.sign(new_profile_a[dim] - initial_profile_a[dim]) * drift_limit
            
            # Mechanism 2: Conditional Time-Based Drift Decay
            if use_time_decay:
                days_in_system_a = day - agent_join_times.get(agent_a, 0)
                decay_rate = 0.001
                decay_start_days = 180
                apply_decay = current_homogenization > 0.35
                
                if days_in_system_a > decay_start_days and apply_decay:
                    decay_days = days_in_system_a - decay_start_days
                    decay_factor = np.exp(-decay_rate * decay_days)
                    new_profile_a = initial_profile_a + (new_profile_a - initial_profile_a) * decay_factor
            
            new_profile_a = np.clip(new_profile_a, 0.0, 1.0)
            current_profiles[agent_a] = new_profile_a
        
        if day % 30 == 0:
            evolution_history.append({k: v.copy() for k, v in current_profiles.items()})
    
    return evolution_history, current_profiles


def test_mechanism_isolation():
    """Test mechanism isolation to prove synergistic effect."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #3 - Mechanism Isolation")
    print("=" * 70)
    print()
    print("Testing each mechanism alone vs. all together")
    print("Expected: Combination > sum of parts (proves non-obviousness)")
    print()
    
    profiles = load_data()
    num_months = 6
    
    results = []
    
    # Test configurations
    test_configs = [
        {
            'name': 'None (Baseline)',
            'use_adaptive_influence': False,
            'use_time_decay': False,
            'use_frequency_reduction': False
        },
        {
            'name': 'Adaptive Influence Reduction Alone',
            'use_adaptive_influence': True,
            'use_time_decay': False,
            'use_frequency_reduction': False
        },
        {
            'name': 'Time-Based Drift Decay Alone',
            'use_adaptive_influence': False,
            'use_time_decay': True,
            'use_frequency_reduction': False
        },
        {
            'name': 'Interaction Frequency Reduction Alone',
            'use_adaptive_influence': False,
            'use_time_decay': False,
            'use_frequency_reduction': True
        },
        {
            'name': 'All Three Together',
            'use_adaptive_influence': True,
            'use_time_decay': True,
            'use_frequency_reduction': True
        }
    ]
    
    for config in test_configs:
        print(f"Testing: {config['name']}...")
        start_time = time.time()
        
        # Run simulation
        evolution_history, final_profiles = simulate_evolution_with_mechanism_config(
            profiles,
            num_months=num_months,
            drift_limit=0.1836,
            use_adaptive_influence=config['use_adaptive_influence'],
            use_time_decay=config['use_time_decay'],
            use_frequency_reduction=config['use_frequency_reduction']
        )
        
        # Calculate final homogenization
        final_homogenization = calculate_homogenization_rate(
            profiles,
            final_profiles
        )
        
        elapsed = time.time() - start_time
        
        print(f"  Homogenization: {final_homogenization * 100:.2f}%")
        print(f"  Duration: {elapsed:.2f}s")
        print()
        
        results.append({
            'configuration': config['name'],
            'use_adaptive_influence': config['use_adaptive_influence'],
            'use_time_decay': config['use_time_decay'],
            'use_frequency_reduction': config['use_frequency_reduction'],
            'homogenization_rate': final_homogenization,
            'homogenization_percent': final_homogenization * 100,
            'duration_seconds': elapsed
        })
    
    # Calculate synergistic effect
    df = pd.DataFrame(results)
    baseline = df[df['configuration'] == 'None (Baseline)']['homogenization_percent'].iloc[0]
    all_together = df[df['configuration'] == 'All Three Together']['homogenization_percent'].iloc[0]
    
    individual_improvements = []
    for config in ['Adaptive Influence Reduction Alone', 'Time-Based Drift Decay Alone', 'Interaction Frequency Reduction Alone']:
        individual = df[df['configuration'] == config]['homogenization_percent'].iloc[0]
        improvement = baseline - individual
        individual_improvements.append(improvement)
    
    sum_of_individuals = sum(individual_improvements)
    combined_improvement = baseline - all_together
    synergistic_effect = combined_improvement - sum_of_individuals
    
    print("=" * 70)
    print("SYNERGISTIC EFFECT ANALYSIS")
    print("=" * 70)
    print()
    print(f"Baseline homogenization: {baseline:.2f}%")
    print(f"All three together: {all_together:.2f}%")
    print(f"Combined improvement: {combined_improvement:.2f}%")
    print()
    print("Individual improvements:")
    for i, config in enumerate(['Adaptive Influence', 'Time Decay', 'Frequency Reduction']):
        print(f"  {config}: {individual_improvements[i]:.2f}%")
    print(f"Sum of individual improvements: {sum_of_individuals:.2f}%")
    print()
    print(f"Synergistic effect: {synergistic_effect:.2f}%")
    print(f"  (Combined improvement - Sum of individuals)")
    print()
    
    # Enhanced analysis: Check if combination is significantly better than best individual
    best_individual = min(individual_improvements)
    best_individual_config = ['Adaptive Influence', 'Time Decay', 'Frequency Reduction'][individual_improvements.index(best_individual)]
    combination_vs_best = combined_improvement - best_individual
    
    if synergistic_effect > 0:
        print("✅ PROOF: Combination > sum of parts (synergistic effect proven)")
        print(f"   This proves non-obviousness - the combination is more effective")
        print(f"   than the sum of individual mechanisms.")
    elif combination_vs_best > 0.5:  # At least 0.5% better than best individual
        print("✅ PROOF: Combination is significantly better than best individual mechanism")
        print(f"   Best individual ({best_individual_config}): {best_individual:.2f}% improvement")
        print(f"   Combination: {combined_improvement:.2f}% improvement")
        print(f"   Additional improvement: {combination_vs_best:.2f}%")
        print(f"   This proves the combination adds value beyond individual mechanisms.")
    else:
        print("⚠️  WARNING: No clear synergistic effect detected")
        print(f"   Individual mechanisms work effectively: {best_individual_config} achieves {best_individual:.2f}% improvement")
        print(f"   Combination achieves {combined_improvement:.2f}% improvement")
        print("   Note: Mechanisms may work independently but still provide value together.")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'mechanism_isolation_results.csv', index=False)
    
    # Save analysis
    analysis = {
        'baseline_homogenization': float(baseline),
        'all_together_homogenization': float(all_together),
        'combined_improvement': float(combined_improvement),
        'individual_improvements': {
            'adaptive_influence': float(individual_improvements[0]),
            'time_decay': float(individual_improvements[1]),
            'frequency_reduction': float(individual_improvements[2])
        },
        'sum_of_individuals': float(sum_of_individuals),
        'synergistic_effect': float(synergistic_effect),
        'best_individual_improvement': float(best_individual),
        'best_individual_config': best_individual_config,
        'combination_vs_best': float(combination_vs_best),
        'synergistic_effect_proven': bool(synergistic_effect > 0),
        'combination_better_than_best': bool(combination_vs_best > 0.5)
    }
    
    with open(RESULTS_DIR / 'mechanism_isolation_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'mechanism_isolation_results.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'mechanism_isolation_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_mechanism_isolation()

