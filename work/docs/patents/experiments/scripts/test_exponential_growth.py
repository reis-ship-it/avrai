#!/usr/bin/env python3
"""
Real-World Scenario: Exponentially Growing User Base

Tests Patent #3 mechanisms with:
- Exponentially growing user base (up to ~100k users)
- Users join at different times over 1 year
- Mechanisms account for individual join times
- Tests with and without mechanisms for comparison

Date: December 19, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
import random
import sys

# Add parent directory to path to import experiment functions
sys.path.insert(0, str(Path(__file__).parent))

from run_patent_3_experiments import (
    simulate_evolution,
    calculate_diversity,
    calculate_homogenization_rate
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_3'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


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


def generate_exponential_growth_users(target_users=100000, num_months=12):
    """
    Generate user base with exponential growth.
    
    Args:
        target_users: Target number of users at end of period
        num_months: Number of months to simulate
    
    Returns:
        Tuple of (profiles dict, agent_join_times dict)
    """
    num_days = num_months * 30
    
    # Exponential growth: N(t) = N0 * e^(r*t)
    # Solve for r: r = ln(N_final / N_initial) / t
    initial_users = 100  # Start with 100 users
    growth_rate = np.log(target_users / initial_users) / num_days
    
    profiles = {}
    agent_join_times = {}
    
    # Initial users (start at day 0)
    for i in range(initial_users):
        agent_id = f"user_{i:06d}"
        profiles[agent_id] = generate_unique_profile(seed=42 + i)
        agent_join_times[agent_id] = 0
    
    # Generate new users with exponential growth
    current_users = initial_users
    user_counter = initial_users
    
    for day in range(1, num_days):
        # Calculate expected users at this day
        expected_users = initial_users * np.exp(growth_rate * day)
        
        # Number of new users to add today
        new_users_today = int(expected_users - current_users)
        
        if new_users_today > 0:
            for _ in range(new_users_today):
                agent_id = f"user_{user_counter:06d}"
                profiles[agent_id] = generate_unique_profile(seed=42 + user_counter)
                agent_join_times[agent_id] = day
                user_counter += 1
                current_users += 1
        
        # Cap at target to avoid overshooting
        if current_users >= target_users:
            break
    
    print(f"Generated {len(profiles):,} users over {num_days} days")
    print(f"Initial users: {initial_users:,}")
    print(f"Final users: {len(profiles):,}")
    print(f"Growth rate: {growth_rate:.6f} per day")
    print()
    
    return profiles, agent_join_times


def test_exponential_growth_scenario(target_users=100000, num_months=12, sample_size=10000):
    """
    Test exponential growth scenario with and without mechanisms.
    
    Args:
        target_users: Target number of users
        num_months: Number of months to simulate
        sample_size: For large user bases, sample this many users for diversity calculation
    """
    print("=" * 70)
    print(f"Real-World Scenario: Exponentially Growing User Base")
    print(f"Target: {target_users:,} users over {num_months} months")
    if target_users > sample_size:
        print(f"Note: Sampling {sample_size:,} users for diversity calculations")
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Generate user base with exponential growth
    print("Generating exponentially growing user base...")
    profiles, agent_join_times = generate_exponential_growth_users(
        target_users=target_users,
        num_months=num_months
    )
    
    # Sample for diversity calculation if user base is large
    if len(profiles) > sample_size:
        sample_agents = random.sample(list(profiles.keys()), sample_size)
        sample_profiles = {aid: profiles[aid] for aid in sample_agents}
        initial_diversity = calculate_diversity(sample_profiles)
        print(f"Initial diversity (sampled {sample_size:,} users): {initial_diversity:.4f}")
    else:
        initial_diversity = calculate_diversity(profiles)
        print(f"Initial diversity: {initial_diversity:.4f}")
    print()
    
    # For very large user bases, we'll need to optimize
    # For now, let's start with a smaller test to verify it works
    if len(profiles) > 50000:
        print(f"⚠️  Warning: {len(profiles):,} users is very large. This may take a long time.")
        print(f"   Consider starting with a smaller test (e.g., 10k users)")
        print(f"   Or we can optimize the simulation further.")
        print()
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("Test cancelled. Try with fewer users first.")
            return None
    
    # Scenario 1: Without mechanisms
    print("Scenario 1: Without mechanisms (baseline)...")
    print("-" * 70)
    scenario1_start = time.time()
    _, final_no_mechanisms = simulate_evolution(
        profiles,
        num_months=num_months,
        drift_limit=0.1836,
        use_diversity_mechanisms=False,
        agent_join_times=agent_join_times
    )
    scenario1_time = time.time() - scenario1_start
    
    # Sample for diversity calculation
    if len(final_no_mechanisms) > sample_size:
        sample_agents = random.sample(list(final_no_mechanisms.keys()), sample_size)
        sample_final = {aid: final_no_mechanisms[aid] for aid in sample_agents}
        diversity_no_mechanisms = calculate_diversity(sample_final)
    else:
        diversity_no_mechanisms = calculate_diversity(final_no_mechanisms)
    
    homogenization_no_mechanisms = 1.0 - (diversity_no_mechanisms / initial_diversity) if initial_diversity > 0 else 0.0
    
    print(f"  Final diversity: {diversity_no_mechanisms:.4f}")
    print(f"  Homogenization: {homogenization_no_mechanisms:.4f} ({homogenization_no_mechanisms*100:.2f}%)")
    print(f"  Time: {scenario1_time:.2f} seconds")
    print()
    
    # Scenario 2: With mechanisms
    print("Scenario 2: With mechanisms (full solution)...")
    print("-" * 70)
    scenario2_start = time.time()
    _, final_with_mechanisms = simulate_evolution(
        profiles,
        num_months=num_months,
        drift_limit=0.1836,
        use_diversity_mechanisms=True,
        agent_join_times=agent_join_times
    )
    scenario2_time = time.time() - scenario2_start
    
    # Sample for diversity calculation
    if len(final_with_mechanisms) > sample_size:
        sample_agents = random.sample(list(final_with_mechanisms.keys()), sample_size)
        sample_final = {aid: final_with_mechanisms[aid] for aid in sample_agents}
        diversity_with_mechanisms = calculate_diversity(sample_final)
    else:
        diversity_with_mechanisms = calculate_diversity(final_with_mechanisms)
    
    homogenization_with_mechanisms = 1.0 - (diversity_with_mechanisms / initial_diversity) if initial_diversity > 0 else 0.0
    
    print(f"  Final diversity: {diversity_with_mechanisms:.4f}")
    print(f"  Homogenization: {homogenization_with_mechanisms:.4f} ({homogenization_with_mechanisms*100:.2f}%)")
    print(f"  Time: {scenario2_time:.2f} seconds")
    print()
    
    # Calculate improvement
    improvement = homogenization_no_mechanisms - homogenization_with_mechanisms
    improvement_percent = (improvement / homogenization_no_mechanisms * 100) if homogenization_no_mechanisms > 0 else 0
    
    prevention_rate = improvement / homogenization_no_mechanisms if homogenization_no_mechanisms > 0 else 0.0
    
    # Results
    results = {
        'target_users': len(profiles),
        'num_months': num_months,
        'initial_diversity': initial_diversity,
        'diversity_no_mechanisms': diversity_no_mechanisms,
        'diversity_with_mechanisms': diversity_with_mechanisms,
        'homogenization_no_mechanisms': homogenization_no_mechanisms,
        'homogenization_with_mechanisms': homogenization_with_mechanisms,
        'improvement': improvement,
        'improvement_percent': improvement_percent,
        'prevention_rate': prevention_rate,
        'scenario1_time_seconds': scenario1_time,
        'scenario2_time_seconds': scenario2_time,
        'total_time_seconds': time.time() - start_time
    }
    
    print("=" * 70)
    print("RESULTS SUMMARY")
    print("=" * 70)
    print()
    print(f"Users: {len(profiles):,}")
    print(f"Time period: {num_months} months")
    print()
    print(f"Without mechanisms:")
    print(f"  Homogenization: {homogenization_no_mechanisms:.4f} ({homogenization_no_mechanisms*100:.2f}%)")
    print()
    print(f"With mechanisms:")
    print(f"  Homogenization: {homogenization_with_mechanisms:.4f} ({homogenization_with_mechanisms*100:.2f}%)")
    print()
    print(f"Improvement:")
    print(f"  Absolute: {improvement:.4f} ({improvement_percent:.2f}%)")
    print(f"  Prevention rate: {prevention_rate:.2%}")
    print()
    print(f"Total time: {time.time() - start_time:.2f} seconds")
    print()
    
    # Save results
    filename = f'exponential_growth_{len(profiles)}users_{num_months}months.csv'
    df = pd.DataFrame([results])
    df.to_csv(RESULTS_DIR / filename, index=False)
    
    print(f"✅ Results saved to: {RESULTS_DIR / filename}")
    print()
    
    return results


if __name__ == '__main__':
    # Default: 100k users over 12 months
    target_users = 100000
    num_months = 12
    
    if len(sys.argv) > 1:
        try:
            target_users = int(sys.argv[1])
        except ValueError:
            print(f"Invalid target users: {sys.argv[1]}, using default {target_users}")
    
    if len(sys.argv) > 2:
        try:
            num_months = int(sys.argv[2])
        except ValueError:
            print(f"Invalid months: {sys.argv[2]}, using default {num_months}")
    
    test_exponential_growth_scenario(target_users=target_users, num_months=num_months)

