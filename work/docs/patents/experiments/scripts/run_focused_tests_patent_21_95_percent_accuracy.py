#!/usr/bin/env python3
"""
Focused Test: Patent #21 - Achieving 95%+ Privacy Accuracy

GOAL: Find epsilon value that achieves 95%+ accuracy preservation while maintaining privacy

Tests different epsilon values to find optimal balance:
- Lower epsilon = stronger privacy but lower accuracy
- Higher epsilon = weaker privacy but higher accuracy
- Target: 95%+ accuracy with acceptable privacy

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


def test_epsilon_for_95_percent_accuracy():
    """Test different epsilon values to achieve 95%+ accuracy."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #21 - Achieving 95%+ Privacy Accuracy")
    print("=" * 70)
    print()
    print("Testing different epsilon values to find optimal balance")
    print("Target: 95%+ accuracy preservation with acceptable privacy")
    print()
    
    agents, profiles = load_data()
    
    # Generate test pairs
    agent_ids = list(profiles.keys())
    pairs = []
    for _ in range(500):  # More pairs for better statistics
        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
        pairs.append((agent_ids[idx_a], agent_ids[idx_b]))
    
    print(f"Testing {len(pairs)} pairs with different epsilon values...")
    print()
    
    # Test epsilon values from 0.01 to 1.0
    epsilon_values = [0.01, 0.02, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
    
    results = []
    
    for epsilon in epsilon_values:
        print(f"Testing epsilon = {epsilon}...")
        start_time = time.time()
        
        accuracy_losses = []
        privacy_scores = []
        
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            # Original compatibility
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            # Apply differential privacy with current epsilon
            anonymized_a = apply_differential_privacy(profile_a, epsilon=epsilon)
            anonymized_b = apply_differential_privacy(profile_b, epsilon=epsilon)
            
            # Calculate anonymized compatibility
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            
            # Accuracy loss
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_loss = min(1.0, max(0.0, accuracy_loss))
            accuracy_losses.append(accuracy_loss)
            
            # Privacy score (inverse of epsilon - lower epsilon = stronger privacy)
            # Normalize to [0, 1] where 1 = strongest privacy (epsilon = 0.01)
            privacy_score = 1.0 / (1.0 + epsilon * 10)  # Scale to make 0.01 = ~0.91
            privacy_scores.append(privacy_score)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        std_accuracy_loss = np.std(accuracy_losses)
        accuracy_preservation = 1.0 - avg_accuracy_loss
        avg_privacy_score = np.mean(privacy_scores)
        
        # Tradeoff score (lower is better)
        # We want: high accuracy (low loss) + high privacy (high privacy score)
        # Tradeoff = (1 - accuracy_preservation) + (1 - privacy_score)
        tradeoff_score = (1.0 - accuracy_preservation) + (1.0 - avg_privacy_score)
        
        elapsed = time.time() - start_time
        
        status = "✅ TARGET" if accuracy_preservation >= 0.95 else "⚠️ BELOW"
        
        print(f"  Accuracy preservation: {accuracy_preservation * 100:.2f}% {status}")
        print(f"  Average accuracy loss: {avg_accuracy_loss:.4f} ± {std_accuracy_loss:.4f}")
        print(f"  Privacy score: {avg_privacy_score:.4f}")
        print(f"  Tradeoff score: {tradeoff_score:.4f} (lower is better)")
        print(f"  Duration: {elapsed:.2f}s")
        print()
        
        results.append({
            'epsilon': epsilon,
            'accuracy_preservation': accuracy_preservation,
            'accuracy_preservation_percent': accuracy_preservation * 100,
            'avg_accuracy_loss': avg_accuracy_loss,
            'std_accuracy_loss': std_accuracy_loss,
            'privacy_score': avg_privacy_score,
            'tradeoff_score': tradeoff_score,
            'meets_target': accuracy_preservation >= 0.95,
            'duration_seconds': elapsed
        })
    
    # Find epsilon that achieves 95%+ accuracy
    df = pd.DataFrame(results)
    target_epsilons = df[df['meets_target'] == True]
    
    print("=" * 70)
    print("RESULTS: EPSILON VALUES THAT ACHIEVE 95%+ ACCURACY")
    print("=" * 70)
    print()
    
    if len(target_epsilons) > 0:
        print("✅ Found epsilon values that achieve 95%+ accuracy:")
        print()
        for _, row in target_epsilons.iterrows():
            print(f"  ε = {row['epsilon']:.2f}: {row['accuracy_preservation_percent']:.2f}% accuracy")
            print(f"    Privacy score: {row['privacy_score']:.4f}")
            print(f"    Tradeoff score: {row['tradeoff_score']:.4f}")
            print()
        
        # Find optimal epsilon (best tradeoff score among those meeting target)
        optimal_idx = target_epsilons['tradeoff_score'].idxmin()
        optimal_epsilon = target_epsilons.loc[optimal_idx, 'epsilon']
        optimal_accuracy = target_epsilons.loc[optimal_idx, 'accuracy_preservation_percent']
        optimal_privacy = target_epsilons.loc[optimal_idx, 'privacy_score']
        optimal_tradeoff = target_epsilons.loc[optimal_idx, 'tradeoff_score']
        
        print("=" * 70)
        print("OPTIMAL EPSILON FOR 95%+ ACCURACY")
        print("=" * 70)
        print()
        print(f"✅ Optimal epsilon: {optimal_epsilon}")
        print(f"   Accuracy preservation: {optimal_accuracy:.2f}%")
        print(f"   Privacy score: {optimal_privacy:.4f}")
        print(f"   Tradeoff score: {optimal_tradeoff:.4f}")
        print()
        print(f"   Recommendation: Use epsilon = {optimal_epsilon} for 95%+ accuracy")
        print()
    else:
        print("⚠️  WARNING: No epsilon value achieves 95%+ accuracy")
        print()
        print("Closest epsilon values:")
        closest = df.nsmallest(3, 'accuracy_preservation', keep='all')
        for _, row in closest.iterrows():
            print(f"  ε = {row['epsilon']:.2f}: {row['accuracy_preservation_percent']:.2f}% accuracy")
        print()
        print("Consider:")
        print("  1. Using higher epsilon values (> 1.0)")
        print("  2. Alternative privacy mechanisms")
        print("  3. Accepting lower privacy for higher accuracy")
        print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'epsilon_95_percent_accuracy_test.csv', index=False)
    
    # Save analysis
    analysis = {
        'target_accuracy': 95.0,
        'epsilon_values_tested': [float(e) for e in epsilon_values],
        'epsilons_meeting_target': [float(row['epsilon']) for _, row in target_epsilons.iterrows()] if len(target_epsilons) > 0 else [],
        'optimal_epsilon': float(optimal_epsilon) if len(target_epsilons) > 0 else None,
        'optimal_accuracy': float(optimal_accuracy) if len(target_epsilons) > 0 else None,
        'optimal_privacy_score': float(optimal_privacy) if len(target_epsilons) > 0 else None,
        'optimal_tradeoff_score': float(optimal_tradeoff) if len(target_epsilons) > 0 else None,
        'current_epsilon': 0.01,
        'current_accuracy': float(df[df['epsilon'] == 0.01]['accuracy_preservation_percent'].iloc[0]) if len(df[df['epsilon'] == 0.01]) > 0 else None
    }
    
    with open(RESULTS_DIR / 'epsilon_95_percent_accuracy_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'epsilon_95_percent_accuracy_test.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'epsilon_95_percent_accuracy_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_epsilon_for_95_percent_accuracy()

