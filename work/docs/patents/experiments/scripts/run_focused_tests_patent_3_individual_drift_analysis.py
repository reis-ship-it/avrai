#!/usr/bin/env python3
"""
Focused Test: Patent #3 - Individual Agent Drift Analysis

NEW PERSPECTIVE: Analyze homogenization from individual agent perspective

Measures:
1. Individual agent drift per metric (12 personality dimensions)
2. Average drift per metric across all agents
3. Homogenization rate per metric
4. System-wide homogenization (existing measure)

If individual metric drift < 0.01, homogenization is acceptable.

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
    simulate_evolution
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_3' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Personality dimension names
DIMENSIONS = [
    'openness', 'conscientiousness', 'extraversion', 'agreeableness',
    'neuroticism', 'curiosity', 'creativity', 'empathy',
    'assertiveness', 'adaptability', 'resilience', 'optimism'
]


def calculate_metric_drift(initial_profiles, current_profiles):
    """
    Calculate drift per metric (dimension) for each agent.
    
    Returns:
    - per_agent_drift: dict[agent_id] -> array[12] of drift per metric
    - per_metric_avg_drift: array[12] of average drift per metric across all agents
    - per_metric_homogenization: array[12] of homogenization rate per metric
    """
    per_agent_drift = {}
    per_metric_drifts = {dim: [] for dim in range(12)}
    
    for agent_id in initial_profiles.keys():
        if agent_id not in current_profiles:
            continue
        
        initial_profile = initial_profiles[agent_id]
        current_profile = current_profiles[agent_id]
        
        # Calculate drift per metric
        drift = np.abs(current_profile - initial_profile)
        per_agent_drift[agent_id] = drift
        
        # Collect drifts per metric
        for dim in range(12):
            per_metric_drifts[dim].append(drift[dim])
    
    # Calculate average drift per metric
    per_metric_avg_drift = np.array([np.mean(per_metric_drifts[dim]) for dim in range(12)])
    
    # Calculate homogenization per metric
    # Homogenization per metric = how much variance has decreased
    per_metric_homogenization = []
    for dim in range(12):
        initial_values = np.array([initial_profiles[aid][dim] for aid in initial_profiles.keys()])
        current_values = np.array([current_profiles[aid][dim] for aid in current_profiles.keys() if aid in current_profiles])
        
        initial_variance = np.var(initial_values)
        current_variance = np.var(current_values)
        
        if initial_variance > 0:
            homogenization = 1 - (current_variance / initial_variance)
            homogenization = max(0.0, min(1.0, homogenization))
        else:
            homogenization = 0.0
        
        per_metric_homogenization.append(homogenization)
    
    per_metric_homogenization = np.array(per_metric_homogenization)
    
    return per_agent_drift, per_metric_avg_drift, per_metric_homogenization


def calculate_multiple_homogenization_perspectives(initial_profiles, current_profiles):
    """
    Calculate homogenization from multiple perspectives.
    
    Returns dict with various homogenization measures.
    """
    perspectives = {}
    
    # 1. System-wide average (existing method)
    from run_patent_3_experiments import calculate_homogenization_rate
    perspectives['system_wide_average'] = calculate_homogenization_rate(initial_profiles, current_profiles)
    
    # 2. Per-metric homogenization (variance reduction per dimension)
    per_metric_homogenization = []
    for dim in range(12):
        initial_values = np.array([initial_profiles[aid][dim] for aid in initial_profiles.keys()])
        current_values = np.array([current_profiles[aid][dim] for aid in current_profiles.keys() if aid in current_profiles])
        
        initial_variance = np.var(initial_values)
        current_variance = np.var(current_values)
        
        if initial_variance > 0:
            homogenization = 1 - (current_variance / initial_variance)
            homogenization = max(0.0, min(1.0, homogenization))
        else:
            homogenization = 0.0
        
        per_metric_homogenization.append(homogenization)
    
    perspectives['per_metric_homogenization'] = per_metric_homogenization
    perspectives['per_metric_average'] = np.mean(per_metric_homogenization)
    perspectives['per_metric_max'] = np.max(per_metric_homogenization)
    perspectives['per_metric_min'] = np.min(per_metric_homogenization)
    
    # 3. Cluster-based homogenization (how many distinct clusters exist)
    # Use k-means to find clusters, measure how many clusters exist
    from sklearn.cluster import KMeans
    
    initial_clusters = KMeans(n_clusters=min(10, len(initial_profiles)), random_state=42, n_init=10)
    initial_clusters.fit(np.array([initial_profiles[aid] for aid in initial_profiles.keys()]))
    initial_num_clusters = len(np.unique(initial_clusters.labels_))
    
    current_clusters = KMeans(n_clusters=min(10, len(current_profiles)), random_state=42, n_init=10)
    current_clusters.fit(np.array([current_profiles[aid] for aid in current_profiles.keys()]))
    current_num_clusters = len(np.unique(current_clusters.labels_))
    
    if initial_num_clusters > 0:
        cluster_homogenization = 1 - (current_num_clusters / initial_num_clusters)
        cluster_homogenization = max(0.0, min(1.0, cluster_homogenization))
    else:
        cluster_homogenization = 0.0
    
    perspectives['cluster_based_homogenization'] = cluster_homogenization
    perspectives['initial_num_clusters'] = int(initial_num_clusters)
    perspectives['current_num_clusters'] = int(current_num_clusters)
    
    # 4. Maximum individual drift (worst-case agent)
    max_drifts = []
    for agent_id in initial_profiles.keys():
        if agent_id not in current_profiles:
            continue
        drift = np.abs(current_profiles[agent_id] - initial_profiles[agent_id])
        max_drifts.append(np.max(drift))
    
    perspectives['max_individual_drift'] = np.max(max_drifts) if max_drifts else 0.0
    perspectives['avg_max_individual_drift'] = np.mean(max_drifts) if max_drifts else 0.0
    
    # 5. Drift distribution (how many agents have low/high drift)
    all_drifts = []
    for agent_id in initial_profiles.keys():
        if agent_id not in current_profiles:
            continue
        drift = np.abs(current_profiles[agent_id] - initial_profiles[agent_id])
        all_drifts.extend(drift.tolist())
    
    perspectives['drift_percentiles'] = {
        'p10': np.percentile(all_drifts, 10) if all_drifts else 0.0,
        'p25': np.percentile(all_drifts, 25) if all_drifts else 0.0,
        'p50': np.percentile(all_drifts, 50) if all_drifts else 0.0,
        'p75': np.percentile(all_drifts, 75) if all_drifts else 0.0,
        'p90': np.percentile(all_drifts, 90) if all_drifts else 0.0,
        'p95': np.percentile(all_drifts, 95) if all_drifts else 0.0,
        'p99': np.percentile(all_drifts, 99) if all_drifts else 0.0
    }
    
    # 6. Agents with acceptable drift (< 0.01 per metric)
    agents_with_acceptable_drift = 0
    total_metrics_checked = 0
    metrics_with_acceptable_drift = 0
    
    for agent_id in initial_profiles.keys():
        if agent_id not in current_profiles:
            continue
        drift = np.abs(current_profiles[agent_id] - initial_profiles[agent_id])
        total_metrics_checked += len(drift)
        metrics_with_acceptable_drift += np.sum(drift < 0.01)
        if np.all(drift < 0.01):
            agents_with_acceptable_drift += 1
    
    perspectives['agents_with_acceptable_drift'] = agents_with_acceptable_drift
    perspectives['total_agents'] = len([aid for aid in initial_profiles.keys() if aid in current_profiles])
    perspectives['metrics_with_acceptable_drift'] = metrics_with_acceptable_drift
    perspectives['total_metrics_checked'] = total_metrics_checked
    perspectives['acceptable_drift_rate'] = metrics_with_acceptable_drift / total_metrics_checked if total_metrics_checked > 0 else 0.0
    
    return perspectives


def test_individual_drift_analysis():
    """Test individual agent drift and multiple homogenization perspectives."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #3 - Individual Agent Drift Analysis")
    print("=" * 70)
    print()
    print("Analyzing homogenization from multiple perspectives:")
    print("  1. Individual agent drift per metric (12 dimensions)")
    print("  2. Average drift per metric across all agents")
    print("  3. Homogenization rate per metric")
    print("  4. System-wide homogenization (existing measure)")
    print("  5. Cluster-based homogenization")
    print("  6. Drift distribution analysis")
    print()
    print("Acceptable drift threshold: < 0.01 per metric")
    print()
    
    profiles = load_data()
    num_months = 6
    
    print("Running simulation with mechanisms...")
    start_time = time.time()
    
    # Run simulation with mechanisms
    evolution_history, final_profiles = simulate_evolution(
        profiles,
        num_months=num_months,
        drift_limit=0.1836,
        use_diversity_mechanisms=True
    )
    
    elapsed = time.time() - start_time
    print(f"Simulation completed in {elapsed:.2f}s")
    print()
    
    # Calculate individual drift
    print("Calculating individual agent drift...")
    per_agent_drift, per_metric_avg_drift, per_metric_homogenization = calculate_metric_drift(
        profiles, final_profiles
    )
    
    # Calculate multiple perspectives
    print("Calculating multiple homogenization perspectives...")
    perspectives = calculate_multiple_homogenization_perspectives(profiles, final_profiles)
    
    print("=" * 70)
    print("RESULTS: INDIVIDUAL AGENT DRIFT ANALYSIS")
    print("=" * 70)
    print()
    
    # 1. System-wide homogenization
    print("1. SYSTEM-WIDE HOMOGENIZATION (Existing Measure):")
    print(f"   Homogenization rate: {perspectives['system_wide_average'] * 100:.2f}%")
    print()
    
    # 2. Per-metric analysis
    print("2. PER-METRIC ANALYSIS:")
    print()
    print("   Metric | Avg Drift | Homogenization | Status")
    print("   " + "-" * 60)
    
    metrics_acceptable = 0
    for dim in range(12):
        avg_drift = per_metric_avg_drift[dim]
        homogenization = per_metric_homogenization[dim] * 100
        status = "✅ OK" if avg_drift < 0.01 else "⚠️ HIGH"
        if avg_drift < 0.01:
            metrics_acceptable += 1
        
        print(f"   {DIMENSIONS[dim]:20s} | {avg_drift:8.6f} | {homogenization:13.2f}% | {status}")
    
    print()
    print(f"   Metrics with acceptable drift (< 0.01): {metrics_acceptable}/12")
    print(f"   Average drift across all metrics: {np.mean(per_metric_avg_drift):.6f}")
    print(f"   Maximum drift across all metrics: {np.max(per_metric_avg_drift):.6f}")
    print()
    
    # 3. Per-agent analysis (sample)
    print("3. PER-AGENT DRIFT ANALYSIS (Sample of 10 agents):")
    print()
    agent_ids = list(per_agent_drift.keys())[:10]
    
    print("   Agent ID | Max Drift | Avg Drift | Metrics OK | Status")
    print("   " + "-" * 70)
    
    for agent_id in agent_ids:
        drift = per_agent_drift[agent_id]
        max_drift = np.max(drift)
        avg_drift = np.mean(drift)
        metrics_ok = np.sum(drift < 0.01)
        status = "✅ OK" if max_drift < 0.01 else "⚠️ HIGH"
        
        print(f"   {agent_id[:20]:20s} | {max_drift:8.6f} | {avg_drift:8.6f} | {metrics_ok:10d}/12 | {status}")
    
    print()
    
    # 4. Multiple perspectives
    print("4. MULTIPLE HOMOGENIZATION PERSPECTIVES:")
    print()
    print(f"   System-wide average: {perspectives['system_wide_average'] * 100:.2f}%")
    print(f"   Per-metric average: {perspectives['per_metric_average'] * 100:.2f}%")
    print(f"   Per-metric range: {perspectives['per_metric_min'] * 100:.2f}% - {perspectives['per_metric_max'] * 100:.2f}%")
    print(f"   Cluster-based: {perspectives['cluster_based_homogenization'] * 100:.2f}%")
    print(f"     (Clusters: {perspectives['initial_num_clusters']} → {perspectives['current_num_clusters']})")
    print()
    
    # 5. Drift distribution
    print("5. DRIFT DISTRIBUTION:")
    print()
    print(f"   Maximum individual drift: {perspectives['max_individual_drift']:.6f}")
    print(f"   Average maximum drift: {perspectives['avg_max_individual_drift']:.6f}")
    print()
    print("   Drift Percentiles:")
    percentiles = perspectives['drift_percentiles']
    print(f"     P10: {percentiles['p10']:.6f}")
    print(f"     P25: {percentiles['p25']:.6f}")
    print(f"     P50 (Median): {percentiles['p50']:.6f}")
    print(f"     P75: {percentiles['p75']:.6f}")
    print(f"     P90: {percentiles['p90']:.6f}")
    print(f"     P95: {percentiles['p95']:.6f}")
    print(f"     P99: {percentiles['p99']:.6f}")
    print()
    
    # 6. Acceptable drift analysis
    print("6. ACCEPTABLE DRIFT ANALYSIS (< 0.01 per metric):")
    print()
    print(f"   Agents with all metrics < 0.01: {perspectives['agents_with_acceptable_drift']}/{perspectives['total_agents']}")
    print(f"   Metrics with acceptable drift: {perspectives['metrics_with_acceptable_drift']}/{perspectives['total_metrics_checked']}")
    print(f"   Acceptable drift rate: {perspectives['acceptable_drift_rate'] * 100:.2f}%")
    print()
    
    # Overall assessment
    print("=" * 70)
    print("OVERALL ASSESSMENT")
    print("=" * 70)
    print()
    
    avg_drift = np.mean(per_metric_avg_drift)
    max_drift = np.max(per_metric_avg_drift)
    
    if avg_drift < 0.01 and max_drift < 0.01:
        print("✅ EXCELLENT: All metrics have acceptable drift (< 0.01)")
        print(f"   Average drift: {avg_drift:.6f}")
        print(f"   Maximum drift: {max_drift:.6f}")
        print("   Homogenization is acceptable from individual metric perspective.")
    elif avg_drift < 0.01:
        print("✅ GOOD: Average drift is acceptable, but some metrics exceed threshold")
        print(f"   Average drift: {avg_drift:.6f} (< 0.01 ✅)")
        print(f"   Maximum drift: {max_drift:.6f} (>= 0.01 ⚠️)")
        print("   Most metrics are acceptable, but some need attention.")
    else:
        print("⚠️  WARNING: Average drift exceeds acceptable threshold")
        print(f"   Average drift: {avg_drift:.6f} (>= 0.01 ⚠️)")
        print(f"   Maximum drift: {max_drift:.6f}")
        print("   Homogenization may be too high from individual metric perspective.")
    print()
    
    # Save results
    # Per-agent drift
    agent_drift_data = []
    for agent_id, drift in per_agent_drift.items():
        row = {'agent_id': agent_id}
        for dim in range(12):
            row[DIMENSIONS[dim]] = float(drift[dim])
        row['max_drift'] = float(np.max(drift))
        row['avg_drift'] = float(np.mean(drift))
        row['metrics_acceptable'] = int(np.sum(drift < 0.01))
        agent_drift_data.append(row)
    
    df_agent_drift = pd.DataFrame(agent_drift_data)
    df_agent_drift.to_csv(RESULTS_DIR / 'individual_agent_drift.csv', index=False)
    
    # Per-metric analysis
    metric_data = []
    for dim in range(12):
        metric_data.append({
            'metric': DIMENSIONS[dim],
            'dimension': dim,
            'avg_drift': float(per_metric_avg_drift[dim]),
            'homogenization_rate': float(per_metric_homogenization[dim]),
            'homogenization_percent': float(per_metric_homogenization[dim] * 100),
            'acceptable': bool(per_metric_avg_drift[dim] < 0.01)
        })
    
    df_metric = pd.DataFrame(metric_data)
    df_metric.to_csv(RESULTS_DIR / 'per_metric_drift_analysis.csv', index=False)
    
    # Multiple perspectives
    perspectives_clean = {
        'system_wide_average': float(perspectives['system_wide_average']),
        'per_metric_average': float(perspectives['per_metric_average']),
        'per_metric_min': float(perspectives['per_metric_min']),
        'per_metric_max': float(perspectives['per_metric_max']),
        'cluster_based_homogenization': float(perspectives['cluster_based_homogenization']),
        'initial_num_clusters': int(perspectives['initial_num_clusters']),
        'current_num_clusters': int(perspectives['current_num_clusters']),
        'max_individual_drift': float(perspectives['max_individual_drift']),
        'avg_max_individual_drift': float(perspectives['avg_max_individual_drift']),
        'drift_percentiles': perspectives['drift_percentiles'],
        'agents_with_acceptable_drift': int(perspectives['agents_with_acceptable_drift']),
        'total_agents': int(perspectives['total_agents']),
        'metrics_with_acceptable_drift': int(perspectives['metrics_with_acceptable_drift']),
        'total_metrics_checked': int(perspectives['total_metrics_checked']),
        'acceptable_drift_rate': float(perspectives['acceptable_drift_rate'])
    }
    
    with open(RESULTS_DIR / 'multiple_homogenization_perspectives.json', 'w') as f:
        json.dump(perspectives_clean, f, indent=2)
    
    print(f"✅ Results saved to:")
    print(f"   - {RESULTS_DIR / 'individual_agent_drift.csv'}")
    print(f"   - {RESULTS_DIR / 'per_metric_drift_analysis.csv'}")
    print(f"   - {RESULTS_DIR / 'multiple_homogenization_perspectives.json'}")
    print()
    
    return df_agent_drift, df_metric, perspectives_clean


if __name__ == '__main__':
    test_individual_drift_analysis()

