#!/usr/bin/env python3
"""
Focused Test: Patent #3 - Advanced Homogenization Metrics

CREATIVE APPROACH: Multiple ways to observe and measure homogenization

New metrics:
1. Entropy-based homogenization (information theory)
2. Correlation-based homogenization (similarity patterns)
3. Distribution shift analysis (statistical distance)
4. Principal component analysis (dimensionality reduction)
5. Cluster stability analysis (cluster preservation)
6. Variance ratio analysis (variance reduction per dimension)
7. Cosine similarity distribution (pairwise similarity)
8. Mahalanobis distance analysis (multivariate distance)
9. Kullback-Leibler divergence (distribution divergence)
10. Wasserstein distance (optimal transport distance)

Date: December 20, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
import sys
from scipy import stats
from scipy.spatial.distance import mahalanobis
from scipy.stats import entropy
from sklearn.decomposition import PCA
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score

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


def calculate_entropy_homogenization(initial_profiles, current_profiles):
    """
    Calculate homogenization using information entropy.
    
    Lower entropy = higher homogenization (less diversity)
    """
    # Convert profiles to arrays
    initial_array = np.array([initial_profiles[aid] for aid in initial_profiles.keys()])
    current_array = np.array([current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles])
    
    # Calculate entropy per dimension
    initial_entropies = []
    current_entropies = []
    
    for dim in range(12):
        # Discretize values into bins for entropy calculation
        initial_values = initial_array[:, dim]
        current_values = current_array[:, dim]
        
        # Use 20 bins
        initial_hist, _ = np.histogram(initial_values, bins=20, range=(0, 1))
        current_hist, _ = np.histogram(current_values, bins=20, range=(0, 1))
        
        # Normalize to probabilities
        initial_probs = initial_hist / np.sum(initial_hist) if np.sum(initial_hist) > 0 else initial_hist
        current_probs = current_hist / np.sum(current_hist) if np.sum(current_hist) > 0 else current_hist
        
        # Calculate entropy
        initial_ent = entropy(initial_probs + 1e-10)  # Add small value to avoid log(0)
        current_ent = entropy(current_probs + 1e-10)
        
        initial_entropies.append(initial_ent)
        current_entropies.append(current_ent)
    
    # Calculate homogenization (entropy reduction)
    avg_initial_entropy = np.mean(initial_entropies)
    avg_current_entropy = np.mean(current_entropies)
    
    if avg_initial_entropy > 0:
        homogenization = 1 - (avg_current_entropy / avg_initial_entropy)
    else:
        homogenization = 0.0
    
    return {
        'homogenization': max(0.0, min(1.0, homogenization)),
        'initial_entropy': avg_initial_entropy,
        'current_entropy': avg_current_entropy,
        'per_dimension_entropies': {
            'initial': initial_entropies,
            'current': current_entropies
        }
    }


def calculate_correlation_homogenization(initial_profiles, current_profiles):
    """
    Calculate homogenization using correlation analysis.
    
    Higher correlation = higher homogenization (agents more similar)
    """
    # Convert profiles to arrays
    initial_array = np.array([initial_profiles[aid] for aid in initial_profiles.keys()])
    current_array = np.array([current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles])
    
    # Calculate pairwise correlations
    initial_correlations = []
    current_correlations = []
    
    profile_list_initial = list(initial_profiles.values())
    profile_list_current = [current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles]
    
    for i in range(len(profile_list_initial)):
        for j in range(i + 1, len(profile_list_initial)):
            corr_initial = np.corrcoef(profile_list_initial[i], profile_list_initial[j])[0, 1]
            initial_correlations.append(corr_initial)
    
    for i in range(len(profile_list_current)):
        for j in range(i + 1, len(profile_list_current)):
            corr_current = np.corrcoef(profile_list_current[i], profile_list_current[j])[0, 1]
            current_correlations.append(corr_current)
    
    avg_initial_corr = np.mean(np.abs(initial_correlations)) if initial_correlations else 0.0
    avg_current_corr = np.mean(np.abs(current_correlations)) if current_correlations else 0.0
    
    # Homogenization = increase in correlation
    if avg_initial_corr < 1.0:
        homogenization = (avg_current_corr - avg_initial_corr) / (1.0 - avg_initial_corr)
    else:
        homogenization = 0.0
    
    return {
        'homogenization': max(0.0, min(1.0, homogenization)),
        'initial_avg_correlation': avg_initial_corr,
        'current_avg_correlation': avg_current_corr
    }


def calculate_distribution_shift(initial_profiles, current_profiles):
    """
    Calculate homogenization using distribution shift (Kolmogorov-Smirnov test).
    
    Higher shift = higher homogenization (distributions more similar)
    """
    # Convert profiles to arrays
    initial_array = np.array([initial_profiles[aid] for aid in initial_profiles.keys()])
    current_array = np.array([current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles])
    
    ks_statistics = []
    p_values = []
    
    for dim in range(12):
        initial_values = initial_array[:, dim]
        current_values = current_array[:, dim]
        
        # Kolmogorov-Smirnov test
        ks_stat, p_value = stats.ks_2samp(initial_values, current_values)
        ks_statistics.append(ks_stat)
        p_values.append(p_value)
    
    # Average KS statistic (higher = more shift = more homogenization)
    avg_ks_stat = np.mean(ks_statistics)
    
    return {
        'avg_ks_statistic': avg_ks_stat,
        'per_dimension_ks': ks_statistics,
        'per_dimension_p_values': p_values
    }


def calculate_pca_homogenization(initial_profiles, current_profiles):
    """
    Calculate homogenization using PCA (dimensionality reduction).
    
    Fewer principal components needed = higher homogenization (less variance)
    """
    # Convert profiles to arrays
    initial_array = np.array([initial_profiles[aid] for aid in initial_profiles.keys()])
    current_array = np.array([current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles])
    
    # PCA on initial profiles
    pca_initial = PCA()
    pca_initial.fit(initial_array)
    initial_variance_ratio = pca_initial.explained_variance_ratio_
    
    # PCA on current profiles
    pca_current = PCA()
    pca_current.fit(current_array)
    current_variance_ratio = pca_current.explained_variance_ratio_
    
    # Number of components needed for 95% variance
    initial_components_95 = np.argmax(np.cumsum(initial_variance_ratio) >= 0.95) + 1
    current_components_95 = np.argmax(np.cumsum(current_variance_ratio) >= 0.95) + 1
    
    # Homogenization = reduction in dimensionality
    if initial_components_95 > 0:
        homogenization = 1 - (current_components_95 / initial_components_95)
    else:
        homogenization = 0.0
    
    return {
        'homogenization': max(0.0, min(1.0, homogenization)),
        'initial_components_95': int(initial_components_95),
        'current_components_95': int(current_components_95),
        'initial_variance_ratio': initial_variance_ratio.tolist(),
        'current_variance_ratio': current_variance_ratio.tolist()
    }


def calculate_cosine_similarity_distribution(initial_profiles, current_profiles):
    """
    Calculate homogenization using cosine similarity distribution.
    
    Higher average cosine similarity = higher homogenization
    """
    profile_list_initial = list(initial_profiles.values())
    profile_list_current = [current_profiles[aid] for aid in current_profiles.keys() if aid in current_profiles]
    
    initial_similarities = []
    current_similarities = []
    
    for i in range(len(profile_list_initial)):
        for j in range(i + 1, len(profile_list_initial)):
            sim = np.dot(profile_list_initial[i], profile_list_initial[j]) / (
                np.linalg.norm(profile_list_initial[i]) * np.linalg.norm(profile_list_initial[j])
            )
            initial_similarities.append(sim)
    
    for i in range(len(profile_list_current)):
        for j in range(i + 1, len(profile_list_current)):
            sim = np.dot(profile_list_current[i], profile_list_current[j]) / (
                np.linalg.norm(profile_list_current[i]) * np.linalg.norm(profile_list_current[j])
            )
            current_similarities.append(sim)
    
    avg_initial_sim = np.mean(initial_similarities) if initial_similarities else 0.0
    avg_current_sim = np.mean(current_similarities) if current_similarities else 0.0
    
    # Homogenization = increase in similarity
    if avg_initial_sim < 1.0:
        homogenization = (avg_current_sim - avg_initial_sim) / (1.0 - avg_initial_sim)
    else:
        homogenization = 0.0
    
    return {
        'homogenization': max(0.0, min(1.0, homogenization)),
        'initial_avg_similarity': avg_initial_sim,
        'current_avg_similarity': avg_current_sim,
        'similarity_distribution': {
            'initial': {
                'mean': float(np.mean(initial_similarities)) if initial_similarities else 0.0,
                'std': float(np.std(initial_similarities)) if initial_similarities else 0.0,
                'min': float(np.min(initial_similarities)) if initial_similarities else 0.0,
                'max': float(np.max(initial_similarities)) if initial_similarities else 0.0
            },
            'current': {
                'mean': float(np.mean(current_similarities)) if current_similarities else 0.0,
                'std': float(np.std(current_similarities)) if current_similarities else 0.0,
                'min': float(np.min(current_similarities)) if current_similarities else 0.0,
                'max': float(np.max(current_similarities)) if current_similarities else 0.0
            }
        }
    }


def calculate_variance_ratio_homogenization(initial_profiles, current_profiles):
    """
    Calculate homogenization using variance ratio per dimension.
    
    Higher variance reduction = higher homogenization
    """
    per_dimension_homogenization = []
    
    for dim in range(12):
        initial_values = np.array([initial_profiles[aid][dim] for aid in initial_profiles.keys()])
        current_values = np.array([current_profiles[aid][dim] for aid in current_profiles.keys() if aid in current_profiles])
        
        initial_variance = np.var(initial_values)
        current_variance = np.var(current_values)
        
        if initial_variance > 0:
            homogenization = 1 - (current_variance / initial_variance)
        else:
            homogenization = 0.0
        
        per_dimension_homogenization.append(homogenization)
    
    return {
        'per_dimension_homogenization': per_dimension_homogenization,
        'average_homogenization': np.mean(per_dimension_homogenization),
        'max_homogenization': np.max(per_dimension_homogenization),
        'min_homogenization': np.min(per_dimension_homogenization),
        'std_homogenization': np.std(per_dimension_homogenization)
    }


def test_advanced_homogenization_metrics():
    """Test all advanced homogenization metrics."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #3 - Advanced Homogenization Metrics")
    print("=" * 70)
    print()
    print("Testing multiple ways to observe and measure homogenization:")
    print("  1. Entropy-based homogenization")
    print("  2. Correlation-based homogenization")
    print("  3. Distribution shift analysis")
    print("  4. PCA-based homogenization")
    print("  5. Cosine similarity distribution")
    print("  6. Variance ratio analysis")
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
    
    print("Calculating advanced homogenization metrics...")
    print()
    
    all_metrics = {}
    
    # 1. Entropy-based homogenization
    print("1. Entropy-Based Homogenization:")
    entropy_metrics = calculate_entropy_homogenization(profiles, final_profiles)
    all_metrics['entropy'] = entropy_metrics
    print(f"   Homogenization: {entropy_metrics['homogenization'] * 100:.2f}%")
    print(f"   Initial entropy: {entropy_metrics['initial_entropy']:.4f}")
    print(f"   Current entropy: {entropy_metrics['current_entropy']:.4f}")
    print()
    
    # 2. Correlation-based homogenization
    print("2. Correlation-Based Homogenization:")
    corr_metrics = calculate_correlation_homogenization(profiles, final_profiles)
    all_metrics['correlation'] = corr_metrics
    print(f"   Homogenization: {corr_metrics['homogenization'] * 100:.2f}%")
    print(f"   Initial avg correlation: {corr_metrics['initial_avg_correlation']:.4f}")
    print(f"   Current avg correlation: {corr_metrics['current_avg_correlation']:.4f}")
    print()
    
    # 3. Distribution shift
    print("3. Distribution Shift Analysis:")
    dist_metrics = calculate_distribution_shift(profiles, final_profiles)
    all_metrics['distribution_shift'] = dist_metrics
    print(f"   Average KS statistic: {dist_metrics['avg_ks_statistic']:.4f}")
    print(f"   (Higher = more shift = more homogenization)")
    print()
    
    # 4. PCA-based homogenization
    print("4. PCA-Based Homogenization:")
    pca_metrics = calculate_pca_homogenization(profiles, final_profiles)
    all_metrics['pca'] = pca_metrics
    print(f"   Homogenization: {pca_metrics['homogenization'] * 100:.2f}%")
    print(f"   Initial components (95% variance): {pca_metrics['initial_components_95']}")
    print(f"   Current components (95% variance): {pca_metrics['current_components_95']}")
    print()
    
    # 5. Cosine similarity distribution
    print("5. Cosine Similarity Distribution:")
    cosine_metrics = calculate_cosine_similarity_distribution(profiles, final_profiles)
    all_metrics['cosine_similarity'] = cosine_metrics
    print(f"   Homogenization: {cosine_metrics['homogenization'] * 100:.2f}%")
    print(f"   Initial avg similarity: {cosine_metrics['initial_avg_similarity']:.4f}")
    print(f"   Current avg similarity: {cosine_metrics['current_avg_similarity']:.4f}")
    print()
    
    # 6. Variance ratio analysis
    print("6. Variance Ratio Analysis:")
    variance_metrics = calculate_variance_ratio_homogenization(profiles, final_profiles)
    all_metrics['variance_ratio'] = variance_metrics
    print(f"   Average homogenization: {variance_metrics['average_homogenization'] * 100:.2f}%")
    print(f"   Range: {variance_metrics['min_homogenization'] * 100:.2f}% - {variance_metrics['max_homogenization'] * 100:.2f}%")
    print(f"   Std deviation: {variance_metrics['std_homogenization'] * 100:.2f}%")
    print()
    
    # Summary
    print("=" * 70)
    print("SUMMARY: MULTIPLE HOMOGENIZATION PERSPECTIVES")
    print("=" * 70)
    print()
    print("Homogenization from different perspectives:")
    print(f"  1. Entropy-based:        {entropy_metrics['homogenization'] * 100:6.2f}%")
    print(f"  2. Correlation-based:    {corr_metrics['homogenization'] * 100:6.2f}%")
    print(f"  3. PCA-based:            {pca_metrics['homogenization'] * 100:6.2f}%")
    print(f"  4. Cosine similarity:    {cosine_metrics['homogenization'] * 100:6.2f}%")
    print(f"  5. Variance ratio:       {variance_metrics['average_homogenization'] * 100:6.2f}%")
    print()
    
    # Save results
    # Convert numpy arrays to lists for JSON serialization
    metrics_clean = {}
    for key, value in all_metrics.items():
        if isinstance(value, dict):
            metrics_clean[key] = {}
            for k, v in value.items():
                if isinstance(v, np.ndarray):
                    metrics_clean[key][k] = v.tolist()
                elif isinstance(v, (np.integer, np.floating)):
                    metrics_clean[key][k] = float(v)
                else:
                    metrics_clean[key][k] = v
        else:
            metrics_clean[key] = value
    
    with open(RESULTS_DIR / 'advanced_homogenization_metrics.json', 'w') as f:
        json.dump(metrics_clean, f, indent=2)
    
    # Create summary DataFrame
    summary_data = {
        'metric': [
            'Entropy-based',
            'Correlation-based',
            'PCA-based',
            'Cosine similarity',
            'Variance ratio'
        ],
        'homogenization_percent': [
            entropy_metrics['homogenization'] * 100,
            corr_metrics['homogenization'] * 100,
            pca_metrics['homogenization'] * 100,
            cosine_metrics['homogenization'] * 100,
            variance_metrics['average_homogenization'] * 100
        ]
    }
    
    df_summary = pd.DataFrame(summary_data)
    df_summary.to_csv(RESULTS_DIR / 'advanced_homogenization_summary.csv', index=False)
    
    print(f"✅ Results saved to:")
    print(f"   - {RESULTS_DIR / 'advanced_homogenization_metrics.json'}")
    print(f"   - {RESULTS_DIR / 'advanced_homogenization_summary.csv'}")
    print()
    
    return all_metrics, df_summary


if __name__ == '__main__':
    test_advanced_homogenization_metrics()

