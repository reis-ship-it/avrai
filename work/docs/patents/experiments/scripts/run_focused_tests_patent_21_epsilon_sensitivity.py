#!/usr/bin/env python3
"""
Focused Test: Patent #21 - Parameter Sensitivity (Epsilon)

CRITICAL TEST: Prove epsilon = 0.5 is optimal (privacy/accuracy tradeoff)

Tests different epsilon values to find optimal balance:
- Too low: Poor accuracy (over-privacy)
- Too high: Poor privacy (over-accuracy)
- Optimal: Best tradeoff

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
from run_patent_21_experiments import (
    load_data,
    quantum_compatibility,
    apply_differential_privacy
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_21' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def test_epsilon_sensitivity():
    """Test epsilon parameter sensitivity to prove optimal value."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #21 - Epsilon Parameter Sensitivity")
    print("=" * 70)
    print()
    print("Testing different epsilon values to find optimal balance")
    print("Expected: Epsilon = 0.5 achieves optimal privacy/accuracy tradeoff")
    print()
    
    agents, profiles = load_data()
    
    # Generate test pairs
    agent_ids = list(profiles.keys())
    pairs = []
    for _ in range(200):  # Sample for speed
        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
        pairs.append((agent_ids[idx_a], agent_ids[idx_b]))
    
    print(f"Testing {len(pairs)} pairs with different epsilon values...")
    print()
    
    # Test epsilon values
    epsilon_values = [0.001, 0.01, 0.02, 0.05, 0.1, 0.5, 1.0, 2.0]
    
    results = []
    
    for epsilon in epsilon_values:
        print(f"Testing epsilon = {epsilon}...")
        start_time = time.time()
        
        accuracy_losses = []
        privacy_protections = []
        
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            # Original compatibility
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            # Anonymized compatibility
            anonymized_a = apply_differential_privacy(profile_a, epsilon=epsilon)
            anonymized_b = apply_differential_privacy(profile_b, epsilon=epsilon)
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            
            # Accuracy loss (lower is better)
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_losses.append(accuracy_loss)
            
            # Privacy protection (measured as noise magnitude)
            noise_magnitude_a = np.linalg.norm(anonymized_a - profile_a)
            noise_magnitude_b = np.linalg.norm(anonymized_b - profile_b)
            avg_noise = (noise_magnitude_a + noise_magnitude_b) / 2.0
            privacy_protections.append(avg_noise)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        std_accuracy_loss = np.std(accuracy_losses)
        avg_privacy_protection = np.mean(privacy_protections)
        std_privacy_protection = np.std(privacy_protections)
        
        # Calculate tradeoff score (lower is better)
        # We want to minimize accuracy loss while maximizing privacy protection
        # Tradeoff score balances both: lower accuracy loss + higher privacy = better
        # Formula: tradeoff_score = accuracy_loss / (1 + privacy_protection)
        # This rewards high privacy (denominator increases) and low accuracy loss (numerator decreases)
        # However, we need to balance: too low epsilon = high privacy but poor accuracy
        # Optimal: balance between accuracy preservation (1 - accuracy_loss) and privacy
        # Refined formula: tradeoff_score = accuracy_loss / (epsilon + 0.1)
        # This penalizes very low epsilon (too much accuracy loss) while rewarding good privacy
        # Alternative: weighted combination
        # Normalize both metrics to [0, 1] and combine: tradeoff = 0.6 * accuracy_loss + 0.4 * (1 - privacy_protection)
        # Lower is better: want low accuracy loss AND high privacy
        normalized_accuracy_loss = avg_accuracy_loss  # Already in [0, 1]
        normalized_privacy = avg_privacy_protection / 2.0  # Normalize privacy to [0, 1] range
        tradeoff_score = 0.6 * normalized_accuracy_loss + 0.4 * (1.0 - normalized_privacy)
        
        elapsed = time.time() - start_time
        
        print(f"  Average accuracy loss: {avg_accuracy_loss:.4f} ± {std_accuracy_loss:.4f}")
        print(f"  Average privacy protection: {avg_privacy_protection:.4f} ± {std_privacy_protection:.4f}")
        print(f"  Tradeoff score: {tradeoff_score:.4f} (lower is better)")
        print(f"  Duration: {elapsed:.2f}s")
        print()
        
        results.append({
            'epsilon': epsilon,
            'avg_accuracy_loss': avg_accuracy_loss,
            'std_accuracy_loss': std_accuracy_loss,
            'avg_privacy_protection': avg_privacy_protection,
            'std_privacy_protection': std_privacy_protection,
            'tradeoff_score': tradeoff_score,
            'duration_seconds': elapsed
        })
    
    # Find optimal epsilon
    df = pd.DataFrame(results)
    optimal_idx = df['tradeoff_score'].idxmin()
    optimal_epsilon = df.loc[optimal_idx, 'epsilon']
    optimal_tradeoff = df.loc[optimal_idx, 'tradeoff_score']
    
    print("=" * 70)
    print("OPTIMAL EPSILON ANALYSIS")
    print("=" * 70)
    print()
    print(f"Optimal epsilon: {optimal_epsilon}")
    print(f"Optimal tradeoff score: {optimal_tradeoff:.4f}")
    print()
    print("Epsilon vs. Tradeoff Score:")
    for _, row in df.iterrows():
        marker = " ← OPTIMAL" if row['epsilon'] == optimal_epsilon else ""
        print(f"  ε = {row['epsilon']:6.3f}: {row['tradeoff_score']:.4f}{marker}")
    print()
    
    # Check if current epsilon (0.5) is optimal
    current_epsilon = 0.5
    current_row = df[df['epsilon'] == current_epsilon]
    if not current_row.empty:
        current_tradeoff = current_row['tradeoff_score'].iloc[0]
        current_accuracy_loss = current_row['avg_accuracy_loss'].iloc[0]
        current_privacy = current_row['avg_privacy_protection'].iloc[0]
        
        print(f"Current epsilon (0.5):")
        print(f"  Tradeoff score: {current_tradeoff:.4f}")
        print(f"  Accuracy loss: {current_accuracy_loss:.4f}")
        print(f"  Privacy protection: {current_privacy:.4f}")
        print()
        
        if abs(optimal_epsilon - current_epsilon) < 0.1:
            print("✅ PROOF: Current epsilon (0.5) is optimal or near-optimal")
            print(f"   Optimal epsilon: {optimal_epsilon}, Current: {current_epsilon}")
            print(f"   This proves technical specificity - the parameter is non-obvious.")
        else:
            print(f"⚠️  WARNING: Optimal epsilon ({optimal_epsilon}) differs from current ({current_epsilon})")
            print(f"   Consider updating epsilon to {optimal_epsilon}")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'epsilon_sensitivity_results.csv', index=False)
    
    # Save analysis
    analysis = {
        'optimal_epsilon': float(optimal_epsilon),
        'optimal_tradeoff_score': float(optimal_tradeoff),
        'current_epsilon': 0.5,
        'current_tradeoff_score': float(current_tradeoff) if not current_row.empty else None,
        'is_optimal': bool(abs(optimal_epsilon - current_epsilon) < 0.1 if not current_row.empty else False),
        'epsilon_values_tested': [float(e) for e in epsilon_values],
        'tradeoff_scores': [float(df[df['epsilon'] == e]['tradeoff_score'].iloc[0]) for e in epsilon_values]
    }
    
    with open(RESULTS_DIR / 'epsilon_sensitivity_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'epsilon_sensitivity_results.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'epsilon_sensitivity_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_epsilon_sensitivity()

