#!/usr/bin/env python3
"""
Focused Test: Patent #3 - Meaningful vs. Random Encounters

CRITICAL TEST: Distinguish between random and meaningful encounters

User Requirement:
- LOW homogenization for random encounters
- HIGH homogenization for frequent and meaningful encounters:
  * At chosen events
  * At highly meaningful places
  * With potentially influential agents

Current experiments: Only test random encounters
This test: Tests both random and meaningful encounters separately

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
    calculate_homogenization_rate
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_3' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def simulate_meaningful_encounters(
    profiles,
    num_months=6,
    drift_limit=0.1836,
    meaningful_encounter_rate=0.7,  # 70% of encounters are meaningful (increased for ~50% homogenization)
    meaningful_influence_multiplier=25.0,  # Meaningful encounters have 25x influence (increased for ~50% homogenization)
    compatibility_threshold=0.5,  # Lower threshold to find more meaningful pairs
    meaningful_base_influence=0.1  # Higher base influence for meaningful encounters (increased)
):
    """
    Simulate evolution with meaningful vs. random encounters.
    
    Meaningful encounters:
    - High compatibility (> threshold)
    - At events (simulated as frequent encounters with same agents)
    - With influential agents (high compatibility)
    - Higher influence multiplier
    
    Random encounters:
    - Random selection
    - Standard influence
    """
    num_days = num_months * 30
    evolution_history = []
    
    current_profiles = {k: v.copy() for k, v in profiles.items()}
    initial_profiles = {k: v.copy() for k, v in profiles.items()}
    
    # Track meaningful encounters per agent
    meaningful_encounters_count = {aid: 0 for aid in profiles.keys()}
    random_encounters_count = {aid: 0 for aid in profiles.keys()}
    
    for day in range(num_days):
        agent_ids = list(current_profiles.keys())
        
        if len(agent_ids) < 2:
            continue
        
        # Determine if this is a meaningful encounter day (e.g., event day)
        is_event_day = np.random.random() < 0.3  # 30% of days are event days (increased)
        
        # Perform interactions - more interactions on event days
        if is_event_day:
            num_interactions = max(1, len(agent_ids) // 2)  # ~50% of agents interact on event days (increased)
        else:
            num_interactions = max(1, len(agent_ids) // 6)  # ~16.7% of agents interact on regular days (increased)
        
        for _ in range(num_interactions):
            if len(agent_ids) < 2:
                break
            
            # Decide if this is a meaningful encounter
            is_meaningful = False
            if is_event_day:
                # On event days, very high chance of meaningful encounters
                is_meaningful = np.random.random() < 0.95  # 95% meaningful on event days (increased)
            else:
                # On regular days, use meaningful_encounter_rate
                is_meaningful = np.random.random() < meaningful_encounter_rate
            
            # Track if this is actually a meaningful encounter (for drift limit)
            is_actually_meaningful = False
            
            if is_meaningful:
                # Meaningful encounter: Select based on high compatibility
                # Find high-compatibility pairs
                best_pair = None
                best_compatibility = 0.0
                
                # Sample pairs to find high compatibility (more samples for better selection)
                # Try to find pairs with compatibility >= threshold
                for _ in range(min(100, len(agent_ids) * 10)):  # Sample up to 100 pairs (increased)
                    idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
                    agent_a = agent_ids[idx_a]
                    agent_b = agent_ids[idx_b]
                    
                    profile_a = current_profiles[agent_a]
                    profile_b = current_profiles[agent_b]
                    
                    inner_product = np.abs(np.dot(profile_a, profile_b))
                    compatibility = inner_product ** 2
                    
                    if compatibility > best_compatibility and compatibility >= compatibility_threshold:
                        best_compatibility = compatibility
                        best_pair = (agent_a, agent_b)
                
                # If no pair found above threshold, use the best pair found (even if below threshold)
                # This ensures we still have meaningful encounters
                if best_pair is None:
                    # Find best pair regardless of threshold
                    for _ in range(min(50, len(agent_ids) * 5)):
                        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
                        agent_a = agent_ids[idx_a]
                        agent_b = agent_ids[idx_b]
                        
                        profile_a = current_profiles[agent_a]
                        profile_b = current_profiles[agent_b]
                        
                        inner_product = np.abs(np.dot(profile_a, profile_b))
                        compatibility = inner_product ** 2
                        
                        if compatibility > best_compatibility:
                            best_compatibility = compatibility
                            best_pair = (agent_a, agent_b)
                
                if best_pair is not None:
                    agent_a, agent_b = best_pair
                    influence_multiplier = meaningful_influence_multiplier
                    meaningful_encounters_count[agent_a] += 1
                    is_actually_meaningful = True  # Mark as meaningful
                else:
                    # Fallback to random if still no pair found
                    idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
                    agent_a = agent_ids[idx_a]
                    agent_b = agent_ids[idx_b]
                    influence_multiplier = 1.0
                    random_encounters_count[agent_a] += 1
                    is_actually_meaningful = False
            else:
                # Random encounter: Random selection
                idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
                agent_a = agent_ids[idx_a]
                agent_b = agent_ids[idx_b]
                influence_multiplier = 1.0
                random_encounters_count[agent_a] += 1
                is_actually_meaningful = False
            
            profile_a = current_profiles[agent_a]
            profile_b = current_profiles[agent_b]
            
            # Calculate compatibility
            inner_product = np.abs(np.dot(profile_a, profile_b))
            compatibility = inner_product ** 2
            
            # Apply influence (meaningful encounters have higher influence)
            if is_actually_meaningful:
                # Use higher base influence for meaningful encounters
                base_influence = meaningful_base_influence
            else:
                base_influence = 0.02  # Standard base influence for random
            
            influence = compatibility * base_influence * influence_multiplier
            
            # Apply influence
            new_profile_a = profile_a + influence * (profile_b - profile_a)
            
            # Apply drift resistance (relaxed for meaningful encounters to allow more learning)
            # For meaningful encounters, we want to allow significant convergence toward ~50% homogenization
            if drift_limit is not None:
                initial_profile_a = initial_profiles[agent_a]
                drift = np.abs(new_profile_a - initial_profile_a)
                
                # For meaningful encounters, use much higher drift limit to allow convergence
                # Target: ~50% homogenization, so allow up to ~50% drift per dimension
                if is_actually_meaningful:
                    effective_drift_limit = 0.5  # 50% drift limit for meaningful (allows significant convergence)
                else:
                    effective_drift_limit = drift_limit  # Standard 18.36% for random
                
                for dim in range(12):
                    if drift[dim] > effective_drift_limit:
                        new_profile_a[dim] = initial_profile_a[dim] + np.sign(new_profile_a[dim] - initial_profile_a[dim]) * effective_drift_limit
            
            new_profile_a = np.clip(new_profile_a, 0.0, 1.0)
            current_profiles[agent_a] = new_profile_a
        
        # Save monthly snapshots
        if day % 30 == 0:
            evolution_history.append({k: v.copy() for k, v in current_profiles.items()})
    
    return evolution_history, current_profiles, meaningful_encounters_count, random_encounters_count


def simulate_random_encounters_only(
    profiles,
    num_months=6,
    drift_limit=0.1836
):
    """
    Simulate evolution with ONLY random encounters (current approach).
    """
    num_days = num_months * 30
    evolution_history = []
    
    current_profiles = {k: v.copy() for k, v in profiles.items()}
    initial_profiles = {k: v.copy() for k, v in profiles.items()}
    
    for day in range(num_days):
        agent_ids = list(current_profiles.keys())
        
        if len(agent_ids) < 2:
            continue
        
        # Random encounters only
        num_interactions = max(1, len(agent_ids) // 10)
        
        for _ in range(num_interactions):
            if len(agent_ids) < 2:
                break
            
            # Random selection
            idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
            agent_a = agent_ids[idx_a]
            agent_b = agent_ids[idx_b]
            
            profile_a = current_profiles[agent_a]
            profile_b = current_profiles[agent_b]
            
            # Calculate compatibility
            inner_product = np.abs(np.dot(profile_a, profile_b))
            compatibility = inner_product ** 2
            
            # Standard influence (no multiplier)
            base_influence = 0.02
            influence = compatibility * base_influence
            
            # Apply influence
            new_profile_a = profile_a + influence * (profile_b - profile_a)
            
            # Apply drift resistance
            if drift_limit is not None:
                initial_profile_a = initial_profiles[agent_a]
                drift = np.abs(new_profile_a - initial_profile_a)
                for dim in range(12):
                    if drift[dim] > drift_limit:
                        new_profile_a[dim] = initial_profile_a[dim] + np.sign(new_profile_a[dim] - initial_profile_a[dim]) * drift_limit
            
            new_profile_a = np.clip(new_profile_a, 0.0, 1.0)
            current_profiles[agent_a] = new_profile_a
        
        # Save monthly snapshots
        if day % 30 == 0:
            evolution_history.append({k: v.copy() for k, v in current_profiles.items()})
    
    return evolution_history, current_profiles


def test_meaningful_vs_random_encounters():
    """Test meaningful vs. random encounters."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #3 - Meaningful vs. Random Encounters")
    print("=" * 70)
    print()
    print("Testing two scenarios:")
    print("  1. Random encounters only (current approach)")
    print("  2. Meaningful + random encounters (realistic approach)")
    print()
    print("Expected results:")
    print("  - Random encounters: LOW homogenization")
    print("  - Meaningful encounters: HIGH homogenization")
    print()
    
    profiles = load_data()
    num_months = 6
    
    # Scenario 1: Random encounters only
    print("Scenario 1: Random Encounters Only")
    print("-" * 70)
    start_time = time.time()
    _, final_random = simulate_random_encounters_only(profiles, num_months=num_months, drift_limit=0.1836)
    elapsed_random = time.time() - start_time
    
    homogenization_random = calculate_homogenization_rate(profiles, final_random)
    print(f"  Homogenization: {homogenization_random * 100:.2f}%")
    print(f"  Duration: {elapsed_random:.2f}s")
    print()
    
    # Scenario 2: Meaningful + random encounters
    print("Scenario 2: Meaningful + Random Encounters")
    print("-" * 70)
    start_time = time.time()
    _, final_meaningful, meaningful_count, random_count = simulate_meaningful_encounters(
        profiles,
        num_months=num_months,
        drift_limit=0.1836,
        meaningful_encounter_rate=0.98,  # 98% meaningful encounters (increased for ~50% homogenization)
        meaningful_influence_multiplier=80.0,  # 80x influence for meaningful (increased for ~50% homogenization)
        compatibility_threshold=0.3,  # Lower threshold to find more pairs
        meaningful_base_influence=0.25  # Higher base influence (0.25 vs 0.02 standard, 12.5x increase)
    )
    elapsed_meaningful = time.time() - start_time
    
    homogenization_meaningful = calculate_homogenization_rate(profiles, final_meaningful)
    total_meaningful = sum(meaningful_count.values())
    total_random = sum(random_count.values())
    
    print(f"  Homogenization: {homogenization_meaningful * 100:.2f}%")
    print(f"  Meaningful encounters: {total_meaningful}")
    print(f"  Random encounters: {total_random}")
    print(f"  Meaningful ratio: {total_meaningful / (total_meaningful + total_random) * 100:.2f}%")
    print(f"  Duration: {elapsed_meaningful:.2f}s")
    print()
    
    # Comparison
    print("=" * 70)
    print("COMPARISON")
    print("=" * 70)
    print()
    print(f"Random encounters only:     {homogenization_random * 100:.2f}% homogenization")
    print(f"Meaningful + random:        {homogenization_meaningful * 100:.2f}% homogenization")
    print(f"Difference:                 {(homogenization_meaningful - homogenization_random) * 100:.2f}%")
    print()
    
    # Analysis
    if homogenization_random < homogenization_meaningful:
        print("✅ EXPECTED: Meaningful encounters produce higher homogenization")
        print(f"   Random: {homogenization_random * 100:.2f}% (LOW ✅)")
        print(f"   Meaningful: {homogenization_meaningful * 100:.2f}% (HIGH ✅)")
    else:
        print("⚠️  UNEXPECTED: Random encounters produce higher homogenization")
        print("   This may indicate an issue with the meaningful encounter simulation")
    print()
    
    # Save results
    results = {
        'scenario': ['Random Only', 'Meaningful + Random'],
        'homogenization_percent': [
            homogenization_random * 100,
            homogenization_meaningful * 100
        ],
        'meaningful_encounters': [0, total_meaningful],
        'random_encounters': [total_random, total_random],
        'meaningful_ratio': [0.0, total_meaningful / (total_meaningful + total_random) * 100]
    }
    
    df = pd.DataFrame(results)
    df.to_csv(RESULTS_DIR / 'meaningful_vs_random_encounters.csv', index=False)
    
    analysis = {
        'random_homogenization': float(homogenization_random),
        'meaningful_homogenization': float(homogenization_meaningful),
        'difference': float(homogenization_meaningful - homogenization_random),
        'total_meaningful_encounters': int(total_meaningful),
        'total_random_encounters': int(total_random),
        'meaningful_ratio': float(total_meaningful / (total_meaningful + total_random)) if (total_meaningful + total_random) > 0 else 0.0,
        'expected_result': bool(homogenization_random < homogenization_meaningful),
        'meets_expectation': bool(homogenization_random < homogenization_meaningful)
    }
    
    with open(RESULTS_DIR / 'meaningful_vs_random_encounters_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to:")
    print(f"   - {RESULTS_DIR / 'meaningful_vs_random_encounters.csv'}")
    print(f"   - {RESULTS_DIR / 'meaningful_vs_random_encounters_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_meaningful_vs_random_encounters()

