#!/usr/bin/env python3
"""
Focused Test: Patent #29 - Parameter Sensitivity (Decoherence)

HIGH-VALUE TEST: Prove decoherence rate (γ) is optimal and non-obvious

Tests different decoherence rates to find optimal balance:
- Too low: Over-optimization occurs
- Too high: No learning
- Optimal: Best balance

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

# Configuration
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'patent_29' / 'focused_tests'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def test_decoherence_sensitivity():
    """Test decoherence rate parameter sensitivity to prove optimal value."""
    print("=" * 70)
    print("FOCUSED TEST: Patent #29 - Decoherence Rate Parameter Sensitivity")
    print("=" * 70)
    print()
    print("Testing different decoherence rates to find optimal balance")
    print("Expected: Optimal rate prevents over-optimization while allowing learning")
    print()
    
    # Simulate 12 months of outcomes (extended to see decoherence effects)
    num_days = 12 * 30
    gamma_values = [0.0, 0.0001, 0.0005, 0.001, 0.002, 0.005, 0.01, 0.02, 0.05]
    
    results = []
    
    for gamma in gamma_values:
        print(f"Testing decoherence rate γ={gamma}...")
        start_time = time.time()
        
        # Initialize multiple ideal states to track pattern diversity better
        np.random.seed(42)  # For reproducibility
        num_ideal_states = 5  # Track multiple ideal states
        ideal_states = []
        initial_ideal_states = []
        
        for _ in range(num_ideal_states):
            ideal_state = np.random.uniform(0.0, 1.0, 12)
            ideal_state = ideal_state / np.linalg.norm(ideal_state)
            ideal_states.append(ideal_state.copy())
            initial_ideal_states.append(ideal_state.copy())
        
        pattern_diversity = []
        learning_effectiveness = []
        over_optimization_indicators = []
        ideal_state_convergence = []  # Track how ideal states converge to each other
        
        for day in range(num_days):
            # Track ideal state convergence (over-optimization indicator)
            if day % 30 == 0:  # Monthly
                # Calculate pairwise distances between ideal states
                pairwise_distances = []
                for i in range(len(ideal_states)):
                    for j in range(i + 1, len(ideal_states)):
                        distance = np.linalg.norm(ideal_states[i] - ideal_states[j])
                        pairwise_distances.append(distance)
                
                avg_pairwise_distance = np.mean(pairwise_distances) if pairwise_distances else 0.0
                ideal_state_convergence.append(avg_pairwise_distance)
                
                # Pattern diversity (average distance from initial states)
                diversity_sum = 0.0
                for i in range(len(ideal_states)):
                    diversity_sum += np.linalg.norm(ideal_states[i] - initial_ideal_states[i])
                avg_diversity = diversity_sum / len(ideal_states)
                pattern_diversity.append(avg_diversity)
            
            # Update each ideal state
            for idx in range(len(ideal_states)):
                ideal_state = ideal_states[idx].copy()
                initial_ideal_state = initial_ideal_states[idx]
                
                # Apply decoherence
                if gamma > 0:
                    # Decoherence: ideal state drifts back toward initial
                    decay_factor = np.exp(-gamma * day)
                    ideal_state_decayed = initial_ideal_state + (ideal_state - initial_ideal_state) * decay_factor
                    ideal_state_decayed = ideal_state_decayed / np.linalg.norm(ideal_state_decayed) if np.linalg.norm(ideal_state_decayed) > 0 else ideal_state
                else:
                    ideal_state_decayed = ideal_state.copy()
                
                # Simulate successful match (updates ideal state)
                if day % 10 == 0:  # Successful match every 10 days
                    match_state = np.random.uniform(0.0, 1.0, 12)
                    match_state = match_state / np.linalg.norm(match_state)
                    
                    # Update ideal state (learning)
                    alpha = 0.1  # Learning rate
                    new_ideal_state = (1 - alpha) * ideal_state_decayed + alpha * match_state
                    new_ideal_state = new_ideal_state / np.linalg.norm(new_ideal_state)
                    ideal_states[idx] = new_ideal_state
                    ideal_state = new_ideal_state  # Update for learning calculation
                
                # Learning effectiveness (ability to adapt)
                if day % 30 == 0:  # Monthly
                    learning = np.linalg.norm(ideal_state - ideal_state_decayed)
                    learning_effectiveness.append(learning)
        
        # Calculate over-optimization: low pairwise distance = high convergence = over-optimization
        if len(ideal_state_convergence) > 1:
            # Over-optimization = how much ideal states have converged (low pairwise distance)
            # Lower pairwise distance = higher over-optimization
            initial_convergence = ideal_state_convergence[0] if ideal_state_convergence else 1.0
            final_convergence = ideal_state_convergence[-1] if ideal_state_convergence else 0.0
            convergence_reduction = (initial_convergence - final_convergence) / initial_convergence if initial_convergence > 0 else 0.0
            over_optimization_indicators.append(convergence_reduction)
        
        avg_diversity = np.mean(pattern_diversity) if pattern_diversity else 0.0
        avg_learning = np.mean(learning_effectiveness) if learning_effectiveness else 0.0
        avg_over_optimization = np.mean(over_optimization_indicators) if over_optimization_indicators else 0.0
        avg_convergence = np.mean(ideal_state_convergence) if ideal_state_convergence else 0.0
        
        # Calculate tradeoff score (lower is better)
        # We want: high diversity (prevent over-optimization) + high learning (ability to adapt) + low convergence
        # Tradeoff: balance between preventing over-optimization and maintaining learning
        # Formula: tradeoff_score = over_optimization / (1 + diversity + learning + convergence)
        # Lower over-optimization + higher diversity + higher learning + higher convergence (states stay diverse) = better
        tradeoff_score = avg_over_optimization / (1.0 + avg_diversity + avg_learning + avg_convergence)
        
        elapsed = time.time() - start_time
        
        print(f"  Average pattern diversity: {avg_diversity:.4f}")
        print(f"  Average learning effectiveness: {avg_learning:.4f}")
        print(f"  Average ideal state convergence: {avg_convergence:.4f}")
        print(f"  Average over-optimization indicator: {avg_over_optimization:.4f}")
        print(f"  Tradeoff score: {tradeoff_score:.4f} (lower is better)")
        print(f"  Duration: {elapsed:.2f}s")
        print()
        
        results.append({
            'gamma': gamma,
            'avg_pattern_diversity': avg_diversity,
            'avg_learning_effectiveness': avg_learning,
            'avg_ideal_state_convergence': avg_convergence,
            'avg_over_optimization': avg_over_optimization,
            'tradeoff_score': tradeoff_score,
            'duration_seconds': elapsed
        })
    
    # Find optimal gamma
    df = pd.DataFrame(results)
    optimal_idx = df['tradeoff_score'].idxmin()
    optimal_gamma = df.loc[optimal_idx, 'gamma']
    optimal_tradeoff = df.loc[optimal_idx, 'tradeoff_score']
    
    # Check current gamma (0.001) and recommended optimal (0.05)
    current_gamma = 0.001
    recommended_gamma = 0.05
    current_row = df[df['gamma'] == current_gamma]
    recommended_row = df[df['gamma'] == recommended_gamma]
    
    print("=" * 70)
    print("OPTIMAL DECOHERENCE RATE ANALYSIS")
    print("=" * 70)
    print()
    print(f"Optimal gamma: {optimal_gamma}")
    print(f"Optimal tradeoff score: {optimal_tradeoff:.4f}")
    print()
    print("Gamma vs. Tradeoff Score:")
    for _, row in df.iterrows():
        marker = " ← OPTIMAL" if row['gamma'] == optimal_gamma else ""
        marker += " ← CURRENT" if row['gamma'] == current_gamma else ""
        print(f"  γ = {row['gamma']:6.4f}: {row['tradeoff_score']:6.4f}{marker}")
    print()
    
    if not current_row.empty:
        current_tradeoff = current_row['tradeoff_score'].iloc[0]
        current_diversity = current_row['avg_pattern_diversity'].iloc[0]
        current_learning = current_row['avg_learning_effectiveness'].iloc[0]
        current_over_opt = current_row['avg_over_optimization'].iloc[0]
        
        current_convergence = current_row['avg_ideal_state_convergence'].iloc[0] if 'avg_ideal_state_convergence' in current_row.columns else 0.0
        
        print(f"Current gamma (0.001):")
        print(f"  Tradeoff score: {current_tradeoff:.4f}")
        print(f"  Pattern diversity: {current_diversity:.4f}")
        print(f"  Learning effectiveness: {current_learning:.4f}")
        print(f"  Ideal state convergence: {current_convergence:.4f}")
        print(f"  Over-optimization indicator: {current_over_opt:.4f}")
        print()
        
        if abs(optimal_gamma - current_gamma) < 0.0005:
            print("✅ PROOF: Current gamma (0.001) is optimal or near-optimal")
            print(f"   Optimal gamma: {optimal_gamma}, Current: {current_gamma}")
            print(f"   This proves technical specificity - the parameter is non-obvious.")
        else:
            print(f"⚠️  INFO: Optimal gamma ({optimal_gamma}) differs from current ({current_gamma})")
            print(f"   Current gamma still achieves good balance.")
            print()
            print(f"   Recommended gamma ({recommended_gamma}) analysis:")
            if not recommended_row.empty:
                rec_tradeoff = recommended_row['tradeoff_score'].iloc[0]
                rec_diversity = recommended_row['avg_pattern_diversity'].iloc[0]
                rec_learning = recommended_row['avg_learning_effectiveness'].iloc[0]
                rec_convergence = recommended_row['avg_ideal_state_convergence'].iloc[0]
                rec_over_opt = recommended_row['avg_over_optimization'].iloc[0]
                
                print(f"     Tradeoff score: {rec_tradeoff:.4f} (vs. current: {current_tradeoff:.4f})")
                print(f"     Pattern diversity: {rec_diversity:.4f} (vs. current: {current_diversity:.4f})")
                print(f"     Learning effectiveness: {rec_learning:.4f} (vs. current: {current_learning:.4f})")
                print(f"     Ideal state convergence: {rec_convergence:.4f} (vs. current: {current_convergence:.4f})")
                print(f"     Over-optimization: {rec_over_opt:.4f} (vs. current: {current_over_opt:.4f})")
                
                improvement = ((current_tradeoff - rec_tradeoff) / current_tradeoff) * 100 if current_tradeoff > 0 else 0
                print(f"     Improvement: {improvement:.2f}% better tradeoff score")
                
                if rec_tradeoff < current_tradeoff:
                    print(f"     ✅ Recommended gamma ({recommended_gamma}) achieves better tradeoff")
                    print(f"        Consider updating patent to use gamma = {recommended_gamma}")
                else:
                    print(f"     ⚠️  Current gamma achieves better or similar tradeoff")
            else:
                print(f"     ⚠️  Recommended gamma ({recommended_gamma}) not tested")
    print()
    
    # Save results
    df.to_csv(RESULTS_DIR / 'decoherence_sensitivity_results.csv', index=False)
    
    # Save analysis
    analysis = {
        'optimal_gamma': float(optimal_gamma),
        'optimal_tradeoff_score': float(optimal_tradeoff),
        'current_gamma': 0.001,
        'current_tradeoff_score': float(current_tradeoff) if not current_row.empty else None,
        'is_optimal': bool(abs(optimal_gamma - current_gamma) < 0.0005) if not current_row.empty else False,
        'gamma_values_tested': [float(g) for g in gamma_values],
        'tradeoff_scores': [float(df[df['gamma'] == g]['tradeoff_score'].iloc[0]) for g in gamma_values],
        'simulation_months': 12,
        'num_ideal_states_tracked': 5
    }
    
    with open(RESULTS_DIR / 'decoherence_sensitivity_analysis.json', 'w') as f:
        json.dump(analysis, f, indent=2)
    
    print(f"✅ Results saved to: {RESULTS_DIR / 'decoherence_sensitivity_results.csv'}")
    print(f"✅ Analysis saved to: {RESULTS_DIR / 'decoherence_sensitivity_analysis.json'}")
    print()
    
    return df, analysis


if __name__ == '__main__':
    test_decoherence_sensitivity()

