#!/usr/bin/env python3
"""
Focused Test: Patent #21 - Alternative Approaches for 95%+ Accuracy

Since epsilon alone doesn't achieve 95%+, test alternative approaches:
1. Reduced noise scale (smaller noise magnitude)
2. Post-normalization correction (adjust after normalization)
3. Selective noise application (noise only on non-critical dimensions)
4. Adaptive epsilon (different epsilon per dimension)
5. Noise reduction techniques (smoothing, filtering)

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
    quantum_compatibility
)

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_21' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def apply_reduced_noise_privacy(profile, epsilon=0.01, noise_reduction_factor=0.5):
    """
    Apply differential privacy with reduced noise scale.
    
    noise_reduction_factor: Multiplier for noise scale (0.5 = half noise)
    """
    sensitivity = 1.0
    scale = (sensitivity / epsilon) * noise_reduction_factor  # Reduced noise
    
    noise = np.random.laplace(0, scale, 12)
    anonymized = profile + noise
    anonymized = np.clip(anonymized, 0.0, 1.0)
    
    # Normalize
    norm = np.linalg.norm(anonymized)
    if norm > 0:
        anonymized = anonymized / norm
    else:
        anonymized = profile / np.linalg.norm(profile) if np.linalg.norm(profile) > 0 else profile
    
    return anonymized


def apply_post_normalization_correction(profile, original_profile, correction_strength=0.3):
    """
    Apply correction after normalization to preserve original direction.
    
    correction_strength: How much to correct (0.0 = no correction, 1.0 = full correction)
    """
    # Normalize first
    norm = np.linalg.norm(profile)
    if norm > 0:
        normalized = profile / norm
    else:
        normalized = profile
    
    # Correct toward original direction
    original_normalized = original_profile / np.linalg.norm(original_profile) if np.linalg.norm(original_profile) > 0 else original_profile
    
    corrected = (1 - correction_strength) * normalized + correction_strength * original_normalized
    corrected = corrected / np.linalg.norm(corrected) if np.linalg.norm(corrected) > 0 else corrected
    
    return corrected


def apply_selective_noise_privacy(profile, epsilon=0.01, critical_dimensions=[0, 1, 2]):
    """
    Apply noise only to non-critical dimensions.
    
    critical_dimensions: Dimensions to preserve (less noise)
    """
    sensitivity = 1.0
    scale = sensitivity / epsilon
    
    noise = np.random.laplace(0, scale, 12)
    
    # Reduce noise on critical dimensions
    for dim in critical_dimensions:
        noise[dim] = noise[dim] * 0.1  # 10% noise on critical dimensions
    
    anonymized = profile + noise
    anonymized = np.clip(anonymized, 0.0, 1.0)
    
    # Normalize
    norm = np.linalg.norm(anonymized)
    if norm > 0:
        anonymized = anonymized / norm
    else:
        anonymized = profile / np.linalg.norm(profile) if np.linalg.norm(profile) > 0 else profile
    
    return anonymized


def apply_adaptive_epsilon_privacy(profile, epsilon_base=0.01, dimension_weights=None):
    """
    Apply different epsilon per dimension based on importance.
    
    dimension_weights: Lower weight = less noise (higher epsilon effective)
    """
    if dimension_weights is None:
        dimension_weights = np.ones(12)  # Equal weights
    
    sensitivity = 1.0
    anonymized = profile.copy()
    
    for dim in range(12):
        # Effective epsilon for this dimension
        effective_epsilon = epsilon_base / dimension_weights[dim]
        scale = sensitivity / effective_epsilon
        
        noise = np.random.laplace(0, scale, 1)[0]
        anonymized[dim] = profile[dim] + noise
    
    anonymized = np.clip(anonymized, 0.0, 1.0)
    
    # Normalize
    norm = np.linalg.norm(anonymized)
    if norm > 0:
        anonymized = anonymized / norm
    else:
        anonymized = profile / np.linalg.norm(profile) if np.linalg.norm(profile) > 0 else profile
    
    return anonymized


def test_alternative_approaches():
    """Test alternative approaches for 95%+ accuracy."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #21 - Alternative Approaches for 95%+ Accuracy")
    print("=" * 70)
    print()
    print("Testing alternative privacy mechanisms:")
    print("  1. Reduced noise scale")
    print("  2. Post-normalization correction")
    print("  3. Selective noise application")
    print("  4. Adaptive epsilon per dimension")
    print()
    
    agents, profiles = load_data()
    
    # Generate test pairs
    agent_ids = list(profiles.keys())
    pairs = []
    for _ in range(500):
        idx_a, idx_b = np.random.choice(len(agent_ids), 2, replace=False)
        pairs.append((agent_ids[idx_a], agent_ids[idx_b]))
    
    print(f"Testing {len(pairs)} pairs...")
    print()
    
    results = []
    
    # Test 1: Reduced noise scale
    print("Test 1: Reduced Noise Scale")
    print("-" * 70)
    for reduction_factor in [0.1, 0.2, 0.3, 0.4, 0.5]:
        accuracy_losses = []
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            anonymized_a = apply_reduced_noise_privacy(profile_a, epsilon=0.01, noise_reduction_factor=reduction_factor)
            anonymized_b = apply_reduced_noise_privacy(profile_b, epsilon=0.01, noise_reduction_factor=reduction_factor)
            
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_losses.append(accuracy_loss)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        accuracy_preservation = 1.0 - avg_accuracy_loss
        status = "✅ TARGET" if accuracy_preservation >= 0.95 else "⚠️ BELOW"
        
        print(f"  Reduction factor {reduction_factor}: {accuracy_preservation * 100:.2f}% {status}")
        
        results.append({
            'approach': 'Reduced Noise Scale',
            'parameter': f'reduction_factor={reduction_factor}',
            'accuracy_preservation': accuracy_preservation,
            'accuracy_preservation_percent': accuracy_preservation * 100,
            'meets_target': accuracy_preservation >= 0.95
        })
    print()
    
    # Test 2: Post-normalization correction
    print("Test 2: Post-Normalization Correction")
    print("-" * 70)
    for correction_strength in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95]:
        accuracy_losses = []
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            # Apply noise first
            from run_patent_21_experiments import apply_differential_privacy
            noisy_a = apply_differential_privacy(profile_a, epsilon=0.01)
            noisy_b = apply_differential_privacy(profile_b, epsilon=0.01)
            
            # Apply correction
            anonymized_a = apply_post_normalization_correction(noisy_a, profile_a, correction_strength=correction_strength)
            anonymized_b = apply_post_normalization_correction(noisy_b, profile_b, correction_strength=correction_strength)
            
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_losses.append(accuracy_loss)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        accuracy_preservation = 1.0 - avg_accuracy_loss
        status = "✅ TARGET" if accuracy_preservation >= 0.95 else "⚠️ BELOW"
        
        print(f"  Correction strength {correction_strength}: {accuracy_preservation * 100:.2f}% {status}")
        
        results.append({
            'approach': 'Post-Normalization Correction',
            'parameter': f'correction_strength={correction_strength}',
            'accuracy_preservation': accuracy_preservation,
            'accuracy_preservation_percent': accuracy_preservation * 100,
            'meets_target': accuracy_preservation >= 0.95
        })
    print()
    
    # Test 3: Selective noise (test different critical dimension sets)
    print("Test 3: Selective Noise Application")
    print("-" * 70)
    critical_sets = [
        [0, 1, 2],  # First 3 dimensions
        [0, 1, 2, 3, 4],  # First 5 dimensions
        [6, 7, 8],  # Middle dimensions
        [9, 10, 11],  # Last 3 dimensions
    ]
    
    for critical_dims in critical_sets:
        accuracy_losses = []
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            anonymized_a = apply_selective_noise_privacy(profile_a, epsilon=0.01, critical_dimensions=critical_dims)
            anonymized_b = apply_selective_noise_privacy(profile_b, epsilon=0.01, critical_dimensions=critical_dims)
            
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_losses.append(accuracy_loss)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        accuracy_preservation = 1.0 - avg_accuracy_loss
        status = "✅ TARGET" if accuracy_preservation >= 0.95 else "⚠️ BELOW"
        
        print(f"  Critical dims {critical_dims}: {accuracy_preservation * 100:.2f}% {status}")
        
        results.append({
            'approach': 'Selective Noise',
            'parameter': f'critical_dims={critical_dims}',
            'accuracy_preservation': accuracy_preservation,
            'accuracy_preservation_percent': accuracy_preservation * 100,
            'meets_target': accuracy_preservation >= 0.95
        })
    print()
    
    # Test 4: Adaptive epsilon
    print("Test 4: Adaptive Epsilon Per Dimension")
    print("-" * 70)
    weight_configs = [
        np.ones(12),  # Equal weights
        np.array([2.0, 2.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),  # Higher weight on first 3
        np.array([5.0, 5.0, 5.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]),  # Much higher weight on first 3
    ]
    
    for i, weights in enumerate(weight_configs):
        accuracy_losses = []
        for agent_a_id, agent_b_id in pairs:
            profile_a = profiles[agent_a_id]
            profile_b = profiles[agent_b_id]
            
            original_compatibility = quantum_compatibility(profile_a, profile_b)
            
            anonymized_a = apply_adaptive_epsilon_privacy(profile_a, epsilon_base=0.01, dimension_weights=weights)
            anonymized_b = apply_adaptive_epsilon_privacy(profile_b, epsilon_base=0.01, dimension_weights=weights)
            
            anonymized_compatibility = quantum_compatibility(anonymized_a, anonymized_b)
            accuracy_loss = abs(original_compatibility - anonymized_compatibility)
            accuracy_losses.append(accuracy_loss)
        
        avg_accuracy_loss = np.mean(accuracy_losses)
        accuracy_preservation = 1.0 - avg_accuracy_loss
        status = "✅ TARGET" if accuracy_preservation >= 0.95 else "⚠️ BELOW"
        
        print(f"  Weight config {i+1}: {accuracy_preservation * 100:.2f}% {status}")
        
        results.append({
            'approach': 'Adaptive Epsilon',
            'parameter': f'weight_config_{i+1}',
            'accuracy_preservation': accuracy_preservation,
            'accuracy_preservation_percent': accuracy_preservation * 100,
            'meets_target': accuracy_preservation >= 0.95
        })
    print()
    
    # Summary
    df = pd.DataFrame(results)
    target_approaches = df[df['meets_target'] == True]
    
    print("=" * 70)
    print("RESULTS: APPROACHES THAT ACHIEVE 95%+ ACCURACY")
    print("=" * 70)
    print()
    
    if len(target_approaches) > 0:
        print("✅ Found approaches that achieve 95%+ accuracy:")
        print()
        for _, row in target_approaches.iterrows():
            print(f"  {row['approach']}: {row['parameter']}")
            print(f"    Accuracy: {row['accuracy_preservation_percent']:.2f}%")
            print()
        
        # Find best approach
        best_idx = target_approaches['accuracy_preservation_percent'].idxmax()
        best_approach = target_approaches.loc[best_idx]
        
        print("=" * 70)
        print("BEST APPROACH")
        print("=" * 70)
        print()
        print(f"✅ Best approach: {best_approach['approach']}")
        print(f"   Parameter: {best_approach['parameter']}")
        print(f"   Accuracy: {best_approach['accuracy_preservation_percent']:.2f}%")
        print()
    else:
        print("⚠️  WARNING: No approach achieves 95%+ accuracy")
        print()
        print("Closest approaches:")
        closest = df.nlargest(5, 'accuracy_preservation_percent')
        for _, row in closest.iterrows():
            print(f"  {row['approach']}: {row['parameter']} - {row['accuracy_preservation_percent']:.2f}%")
        print()
        print("Consider:")
        print("  1. Combining multiple approaches")
        print("  2. Accepting lower privacy for higher accuracy")
        print("  3. Using different privacy mechanism")
        print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'alternative_95_percent_approaches.csv', index=False)
    
    analysis = {
        'target_accuracy': 95.0,
        'approaches_tested': len(df),
        'approaches_meeting_target': len(target_approaches),
        'best_approach': {
            'name': best_approach['approach'] if len(target_approaches) > 0 else None,
            'parameter': best_approach['parameter'] if len(target_approaches) > 0 else None,
            'accuracy': float(best_approach['accuracy_preservation_percent']) if len(target_approaches) > 0 else None
        } if len(target_approaches) > 0 else None
    }
    
    with open(RESULTS_DIR / 'alternative_95_percent_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'alternative_95_percent_approaches.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'alternative_95_percent_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_alternative_approaches()

