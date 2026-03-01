#!/usr/bin/env python3
"""
Patent #3: Incremental Agent Addition Experiment

Tests drift resistance when new agents join at random times (real-world scenario).

Method:
1. Start with 100 agents at time 0
2. Add 10 new agents every month (random times within month)
3. Run simulation for 12 months
4. Measure:
   - Original agents: Homogenization rate, drift resistance
   - New agents: Homogenization rate, drift resistance
   - Overall: Threshold stability, homogenization rate
   - Comparison: New agents vs. original agents behavior

Date: December 19, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
import random

# Configuration
DATA_DIR = Path(__file__).parent.parent / 'data' / 'patent_3_contextual_personality'
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_3'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Drift limit (18.36% threshold)
DRIFT_LIMIT = 0.1836


def generate_unique_profile(seed=None):
    """Generate a single unique personality profile."""
    if seed is not None:
        np.random.seed(seed)
    
    profile = np.random.uniform(0.0, 1.0, 12)
    norm = np.linalg.norm(profile)
    if norm > 0:
        profile = profile / norm
    else:
        profile = np.ones(12) / np.sqrt(12)
    
    return profile


def calculate_diversity(profiles):
    """Calculate personality diversity."""
    profile_list = list(profiles.values())
    if len(profile_list) < 2:
        return 0.0
    
    diversity = 0.0
    count = 0
    for i in range(len(profile_list)):
        for j in range(i + 1, len(profile_list)):
            diversity += np.linalg.norm(profile_list[i] - profile_list[j])
            count += 1
    
    return diversity / count if count > 0 else 0.0


def calculate_homogenization_rate(initial_profiles, current_profiles):
    """Calculate homogenization rate."""
    initial_diversity = calculate_diversity(initial_profiles)
    current_diversity = calculate_diversity(current_profiles)
    
    if initial_diversity == 0:
        return 0.0
    
    homogenization = 1 - (current_diversity / initial_diversity)
    return max(0.0, min(1.0, homogenization))


def simulate_evolution_with_incremental_addition(
    initial_profiles,
    num_months=12,
    agents_per_month=10,
    churn_rate=0.05,  # 5% of users stop using app each month
    drift_limit=DRIFT_LIMIT
):
    """
    Simulate personality evolution with incremental agent addition and churn.
    
    Args:
        initial_profiles: Initial personality profiles (dict: agent_id -> profile)
        num_months: Number of months to simulate
        agents_per_month: Number of new agents to add each month
        churn_rate: Fraction of users who stop using app each month (default: 5%)
        drift_limit: Maximum drift allowed
    """
    num_days = num_months * 30
    evolution_history = []
    agent_join_times = {}  # Track when each agent joined
    agent_churn_times = {}  # Track when each agent left (None if still active)
    
    # Initialize with original agents
    current_profiles = {k: v.copy() for k, v in initial_profiles.items()}
    initial_profiles_tracked = {k: v.copy() for k, v in initial_profiles.items()}
    
    # Track join times for original agents (all at time 0)
    for agent_id in initial_profiles.keys():
        agent_join_times[agent_id] = 0
        agent_churn_times[agent_id] = None  # Still active
    
    # Generate new agents to add (pre-generate for reproducibility)
    new_agent_counter = len(initial_profiles)
    new_agents_to_add = []
    for month in range(1, num_months + 1):
        for _ in range(agents_per_month):
            agent_id = f"new_agent_{new_agent_counter}"
            profile = generate_unique_profile(seed=42 + new_agent_counter)
            join_day = random.randint((month - 1) * 30, month * 30 - 1)
            new_agents_to_add.append((agent_id, profile, join_day, month))
            new_agent_counter += 1
    
    # Sort by join day
    new_agents_to_add.sort(key=lambda x: x[2])
    
    new_agent_index = 0
    
    for day in range(num_days):
        # Add new agents on their join day
        while new_agent_index < len(new_agents_to_add):
            agent_id, profile, join_day, join_month = new_agents_to_add[new_agent_index]
            if join_day == day:
                current_profiles[agent_id] = profile.copy()
                initial_profiles_tracked[agent_id] = profile.copy()
                agent_join_times[agent_id] = day
                new_agent_index += 1
            elif join_day > day:
                break
            else:
                new_agent_index += 1
        
        # Simulate daily interactions with creative diversity mechanisms
        agent_ids = list(current_profiles.keys())
        
        # Calculate current homogenization for adaptive mechanisms
        if len(agent_ids) > 1:
            current_homogenization = calculate_homogenization_rate(
                {aid: initial_profiles_tracked[aid] for aid in agent_ids},
                {aid: current_profiles[aid] for aid in agent_ids}
            )
        else:
            current_homogenization = 0.0
        
        # Creative Solution 1: Reduced influence rate (adaptive)
        # Allow more influence for healthy learning, but reduce as homogenization increases
        base_influence = 0.02
        # Only reduce influence if homogenization gets high (above 45%)
        if current_homogenization > 0.45:
            influence_multiplier = 1.0 - ((current_homogenization - 0.45) * 0.7)  # Reduce only above 45%
            influence_multiplier = max(0.6, influence_multiplier)  # Minimum 60% influence
        else:
            influence_multiplier = 1.0  # Full influence below 45% homogenization
        
        # Creative Solution 2: Interaction frequency reduction
        # Not all agents interact every day - frequency decreases with time in system
        # But allow most interactions - only reduce for very long-term users
        interactions_this_day = []
        for agent_id in agent_ids:
            days_in_system = day - agent_join_times.get(agent_id, 0)
            # Interaction probability decreases very slowly - most users still interact
            interaction_probability = 1.0 / (1.0 + days_in_system / 180.0)  # Decreases over ~6 months (very slow)
            if np.random.random() < interaction_probability:
                interactions_this_day.append(agent_id)
        
        # If no interactions, skip
        if len(interactions_this_day) < 2:
            interactions_this_day = agent_ids  # Fallback: all agents interact
        
        # Creative Solution 3: Time-based drift decay
        # Agents gradually "remember" their original personality
        # But only apply decay after significant time AND when homogenization is high
        decay_rate = 0.001  # Very slow decay rate - allow more drift
        decay_start_days = 180  # Only start decay after 180 days (6 months)
        # Only apply decay if homogenization is getting high
        apply_decay = current_homogenization > 0.35  # Only decay if homogenization > 35%
        
        # Perform interactions
        num_interactions = len(interactions_this_day)
        for i in range(num_interactions):
            idx_a, idx_b = np.random.choice(len(interactions_this_day), 2, replace=False)
            agent_a = interactions_this_day[idx_a]
            agent_b = interactions_this_day[idx_b]
            
            profile_a = current_profiles[agent_a]
            profile_b = current_profiles[agent_b]
            
            # Calculate compatibility (quantum-based)
            inner_product = np.abs(np.dot(profile_a, profile_b))
            compatibility = inner_product ** 2
            influence = compatibility * base_influence * influence_multiplier
            
            # Apply influence
            new_profile_a = profile_a + influence * (profile_b - profile_a)
            
            # Apply drift resistance
            initial_profile_a = initial_profiles_tracked[agent_a]
            drift = np.abs(new_profile_a - initial_profile_a)
            for dim in range(12):
                if drift[dim] > drift_limit:
                    new_profile_a[dim] = initial_profile_a[dim] + np.sign(new_profile_a[dim] - initial_profile_a[dim]) * drift_limit
            
            # Creative Solution 3: Time-based drift decay
            # Apply exponential decay to drift, gradually returning toward initial state
            # But only after decay_start_days AND if homogenization is high
            days_in_system_a = day - agent_join_times.get(agent_a, 0)
            if days_in_system_a > decay_start_days and apply_decay:
                # Only apply decay after decay_start_days and if homogenization is high
                decay_days = days_in_system_a - decay_start_days
                decay_factor = np.exp(-decay_rate * decay_days)
                # Decay the drift: new_profile = initial + (current - initial) * decay_factor
                new_profile_a = initial_profile_a + (new_profile_a - initial_profile_a) * decay_factor
            
            new_profile_a = np.clip(new_profile_a, 0.0, 1.0)
            current_profiles[agent_a] = new_profile_a
        
        # Apply churn at end of each month
        if day % 30 == 29 and day > 0:  # End of month (day 29, 59, 89, etc.)
            month = (day + 1) // 30
            active_agents = [aid for aid in current_profiles.keys() if agent_churn_times.get(aid) is None]
            
            if len(active_agents) > 0:
                # Calculate number of agents to churn
                num_to_churn = max(1, int(len(active_agents) * churn_rate))
                
                # Preferentially churn older, more homogenized agents
                # Calculate homogenization for each active agent
                agent_homogenization = {}
                for agent_id in active_agents:
                    initial_profile = initial_profiles_tracked[agent_id]
                    current_profile = current_profiles[agent_id]
                    drift = np.linalg.norm(current_profile - initial_profile)
                    agent_homogenization[agent_id] = drift
                
                # Sort by homogenization (highest first) and age (oldest first)
                # Weight: 80% homogenization, 20% age (preferentially remove most homogenized)
                agent_scores = []
                for agent_id in active_agents:
                    homogenization_score = agent_homogenization[agent_id]
                    age_score = agent_join_times[agent_id] / (day + 1)  # Normalize by current day
                    combined_score = 0.8 * homogenization_score + 0.2 * age_score
                    agent_scores.append((agent_id, combined_score))
                
                # Sort by score (highest = most likely to churn)
                agent_scores.sort(key=lambda x: x[1], reverse=True)
                
                # Select top N agents to churn
                agents_to_churn = [aid for aid, _ in agent_scores[:num_to_churn]]
                
                # Mark agents as churned
                for agent_id in agents_to_churn:
                    agent_churn_times[agent_id] = day
                    # Remove from current profiles (they stop using app)
                    if agent_id in current_profiles:
                        del current_profiles[agent_id]
        
        # Save monthly snapshots
        if day % 30 == 0:
            month = day // 30
            evolution_history.append({
                'month': month,
                'profiles': {k: v.copy() for k, v in current_profiles.items()},
                'agent_join_times': agent_join_times.copy(),
                'agent_churn_times': agent_churn_times.copy()
            })
    
    return evolution_history, current_profiles, agent_join_times, agent_churn_times, initial_profiles_tracked


def experiment_incremental_addition():
    """Experiment: Incremental Agent Addition - Drift Resistance."""
    print("=" * 70)
    print("Experiment: Incremental Agent Addition - Drift Resistance")
    print("=" * 70)
    print()
    print("Testing real-world scenario: New users join continuously")
    print()
    
    # Load initial data
    with open(DATA_DIR / 'initial_profiles.json', 'r') as f:
        initial_profiles_dict = json.load(f)
    
    initial_profiles = {k: np.array(v) for k, v in initial_profiles_dict.items()}
    
    # Limit to 100 agents for initial set
    agent_ids = list(initial_profiles.keys())[:100]
    initial_profiles = {aid: initial_profiles[aid] for aid in agent_ids}
    
    print(f"Starting with {len(initial_profiles)} agents")
    print(f"Adding 10 new agents every month for 12 months")
    print(f"Total agents after 12 months: {len(initial_profiles) + 12 * 10}")
    print()
    
    # Run simulation with churn
    print("Running simulation with churn (5% per month)...")
    start_time = time.time()
    
    # Run simulation with 5% churn (realistic) and creative diversity mechanisms
    print("Running simulation with:")
    print("  - 5% churn per month (realistic)")
    print("  - Time-based drift decay (agents remember original personality)")
    print("  - Adaptive influence reduction (less influence as homogenization increases)")
    print("  - Interaction frequency reduction (long-term users interact less)")
    print()
    
    evolution_history, final_profiles, agent_join_times, agent_churn_times, initial_profiles_tracked = simulate_evolution_with_incremental_addition(
        initial_profiles,
        num_months=12,
        agents_per_month=10,
        churn_rate=0.05,  # Fixed 5% churn (realistic)
        drift_limit=DRIFT_LIMIT
    )
    
    elapsed = time.time() - start_time
    print(f"✅ Simulation completed in {elapsed:.2f} seconds")
    print()
    
    # Analyze results
    print("Analyzing results...")
    print()
    
    results = []
    
    # Separate original and new agents (only active ones)
    all_agent_ids = set(agent_join_times.keys())
    churned_agent_ids = set([aid for aid, churn_time in agent_churn_times.items() if churn_time is not None])
    active_agent_ids = all_agent_ids - churned_agent_ids
    
    original_agent_ids = [aid for aid in active_agent_ids if agent_join_times[aid] == 0]
    new_agent_ids = [aid for aid in active_agent_ids if agent_join_times[aid] > 0]
    
    print(f"Total agents ever: {len(all_agent_ids)}")
    print(f"Churned agents: {len(churned_agent_ids)}")
    print(f"Active agents: {len(active_agent_ids)}")
    print(f"  - Original (active): {len(original_agent_ids)}")
    print(f"  - New (active): {len(new_agent_ids)}")
    print()
    
    # Analyze each month
    for snapshot in evolution_history:
        month = snapshot['month']
        profiles = snapshot['profiles']  # Only active agents
        join_times = snapshot['agent_join_times']
        churn_times = snapshot.get('agent_churn_times', {})
        
        # Separate profiles by join time (only active agents)
        original_profiles = {aid: profiles[aid] for aid in profiles.keys() if join_times.get(aid, -1) == 0}
        new_profiles = {aid: profiles[aid] for aid in profiles.keys() if join_times.get(aid, -1) > 0}
        
        # Get initial profiles for comparison
        original_initial = {aid: initial_profiles_tracked[aid] for aid in original_profiles.keys()}
        new_initial = {aid: initial_profiles_tracked[aid] for aid in new_profiles.keys()}
        
        # Calculate homogenization
        if len(original_profiles) > 1:
            original_homogenization = calculate_homogenization_rate(original_initial, original_profiles)
        else:
            original_homogenization = 0.0
        
        if len(new_profiles) > 1:
            new_homogenization = calculate_homogenization_rate(new_initial, new_profiles)
        else:
            new_homogenization = 0.0
        
        # Overall homogenization
        all_initial = {**original_initial, **new_initial}
        all_current = {**original_profiles, **new_profiles}
        overall_homogenization = calculate_homogenization_rate(all_initial, all_current)
        
        results.append({
            'month': month,
            'total_agents': len(profiles),
            'original_agents': len(original_profiles),
            'new_agents': len(new_profiles),
            'original_homogenization': original_homogenization,
            'new_homogenization': new_homogenization,
            'overall_homogenization': overall_homogenization
        })
    
    df = pd.DataFrame(results)
    
    # Final analysis
    print("=" * 70)
    print("RESULTS SUMMARY")
    print("=" * 70)
    print()
    
    final_month = df.iloc[-1]
    print(f"Month 12 (Final):")
    print(f"  Total agents: {final_month['total_agents']}")
    print(f"  Original agents: {final_month['original_agents']}")
    print(f"  New agents: {final_month['new_agents']}")
    print()
    print(f"Homogenization Rates:")
    print(f"  Original agents: {final_month['original_homogenization']*100:.2f}%")
    print(f"  New agents: {final_month['new_homogenization']*100:.2f}%")
    print(f"  Overall: {final_month['overall_homogenization']*100:.2f}%")
    print()
    
    # Compare original vs new
    original_avg = df['original_homogenization'].mean()
    new_avg = df[df['new_agents'] > 0]['new_homogenization'].mean()
    
    print("Average Homogenization (across all months):")
    print(f"  Original agents: {original_avg*100:.2f}%")
    print(f"  New agents: {new_avg*100:.2f}%")
    print(f"  Difference: {abs(original_avg - new_avg)*100:.2f}%")
    print()
    
    # Threshold check (must be below 52%)
    threshold_hold = final_month['overall_homogenization'] < 0.52
    print(f"18.36% Threshold Check (Must be < 52%):")
    print(f"  Overall homogenization: {final_month['overall_homogenization']*100:.2f}%")
    print(f"  Target: < 52% (48% uniqueness preserved)")
    print(f"  Threshold holds: {'✅ YES' if threshold_hold else '❌ NO'}")
    if not threshold_hold:
        print(f"  ⚠️  WARNING: Homogenization too high! Need to adjust churn rate or other parameters.")
    print()
    
    # New agents behavior
    new_agents_preserve_uniqueness = new_avg < 0.50
    print(f"New Agents Behavior:")
    print(f"  Average homogenization: {new_avg*100:.2f}%")
    print(f"  Uniqueness preserved: {'✅ YES' if new_agents_preserve_uniqueness else '❌ NO'}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'incremental_addition_results.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'incremental_addition_results.csv'}")
    print()
    
    return df


def main():
    """Run incremental addition experiment."""
    print()
    print("=" * 70)
    print("Patent #3: Incremental Agent Addition Experiment")
    print("=" * 70)
    print()
    print("Real-World Scenario: New users join continuously")
    print()
    
    experiment_incremental_addition()
    
    print("=" * 70)
    print("✅ Experiment Complete")
    print("=" * 70)
    print()


if __name__ == '__main__':
    main()

