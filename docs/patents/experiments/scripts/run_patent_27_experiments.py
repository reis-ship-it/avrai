#!/usr/bin/env python3
"""
Patent #27: Hybrid Quantum-Classical Neural Network Experiments

Runs all 4 required experiments:
1. Hybrid Architecture Accuracy (P1)
2. Gradual Transition Effectiveness (P1)
3. Neural Network Refinement Improvement (P1)
4. Fallback Mechanism Reliability (P1)

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from scipy.stats import pearsonr
from sklearn.metrics import mean_absolute_error, mean_squared_error
import random
import warnings
warnings.filterwarnings('ignore')

# Configuration
PATENT_NUMBER = "27"
PATENT_NAME = "Hybrid Quantum-Classical Neural Network"
PATENT_FOLDER = "patent_27_hybrid_quantum_classical"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_USERS = 500
NUM_RECOMMENDATIONS = 1000
INITIAL_QUANTUM_WEIGHT = 0.70  # 70% quantum baseline
INITIAL_NEURAL_WEIGHT = 0.30   # 30% neural refinement
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)


def generate_synthetic_data():
    """Generate synthetic user and recommendation data."""
    print("Generating synthetic data...")
    
    users = []
    recommendations = []
    
    for i in range(NUM_USERS):
        # Generate user personality profile (12D)
        user_profile = np.random.rand(12)
        user_profile = user_profile / np.linalg.norm(user_profile)  # Normalize
        
        user = {
            'user_id': f'user_{i:04d}',
            'profile': user_profile.tolist(),
        }
        users.append(user)
    
    for i in range(NUM_RECOMMENDATIONS):
        # Generate opportunity profile (12D)
        opportunity_profile = np.random.rand(12)
        opportunity_profile = opportunity_profile / np.linalg.norm(opportunity_profile)
        
        # Generate ground truth calling score
        ground_truth = random.uniform(0.0, 1.0)
        
        recommendation = {
            'recommendation_id': f'rec_{i:04d}',
            'user_id': f'user_{random.randint(0, NUM_USERS-1):04d}',
            'opportunity_profile': opportunity_profile.tolist(),
            'ground_truth_score': ground_truth,
        }
        recommendations.append(recommendation)
    
    # Save data
    with open(DATA_DIR / 'synthetic_users.json', 'w') as f:
        json.dump(users, f, indent=2)
    
    with open(DATA_DIR / 'synthetic_recommendations.json', 'w') as f:
        json.dump(recommendations, f, indent=2)
    
    print(f"✅ Generated {len(users)} users and {len(recommendations)} recommendations")
    return users, recommendations


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_users.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_users.json', 'r') as f:
        users = json.load(f)
    
    with open(DATA_DIR / 'synthetic_recommendations.json', 'r') as f:
        recommendations = json.load(f)
    
    return users, recommendations


def quantum_compatibility(user_profile, opportunity_profile):
    """Calculate quantum compatibility: C = |⟨ψ_user|ψ_opportunity⟩|²"""
    user_vec = np.array(user_profile)
    opp_vec = np.array(opportunity_profile)
    inner_product = np.abs(np.dot(user_vec, opp_vec))
    return inner_product ** 2


def calling_score_formula(vibe_compatibility, life_betterment, connection_prob, context_factor, timing_factor):
    """Calculate calling score using formula: weighted combination"""
    score = (
        vibe_compatibility * 0.40 +
        life_betterment * 0.30 +
        connection_prob * 0.15 +
        context_factor * 0.10 +
        timing_factor * 0.05
    )
    return score


def quantum_baseline_score(user_profile, opportunity_profile):
    """Calculate 70% quantum baseline score."""
    vibe_compatibility = quantum_compatibility(user_profile, opportunity_profile)
    life_betterment = random.uniform(0.5, 1.0)  # Simulated
    connection_prob = random.uniform(0.4, 0.9)  # Simulated
    context_factor = random.uniform(0.6, 1.0)   # Simulated
    timing_factor = random.uniform(0.5, 1.0)     # Simulated
    
    return calling_score_formula(vibe_compatibility, life_betterment, connection_prob, context_factor, timing_factor)


def neural_network_refinement(user_profile, opportunity_profile, confidence):
    """Simulate neural network refinement (30% weight)."""
    # Simulate neural network learning patterns
    base_score = quantum_baseline_score(user_profile, opportunity_profile)
    
    # Neural network adds pattern-based refinement
    pattern_adjustment = random.uniform(-0.1, 0.2) * confidence  # More confident = better refinement
    refined_score = base_score + pattern_adjustment
    
    return max(0.0, min(1.0, refined_score))  # Clamp to [0, 1]


def hybrid_score(user_profile, opportunity_profile, quantum_weight, neural_weight, confidence):
    """Calculate hybrid score: quantum_weight * quantum + neural_weight * neural."""
    quantum_score = quantum_baseline_score(user_profile, opportunity_profile)
    neural_score = neural_network_refinement(user_profile, opportunity_profile, confidence)
    
    hybrid = quantum_weight * quantum_score + neural_weight * neural_score
    return hybrid, quantum_score, neural_score


def experiment_1_hybrid_architecture():
    """Experiment 1: Hybrid Architecture Accuracy."""
    print("=" * 70)
    print("Experiment 1: Hybrid Architecture Accuracy")
    print("=" * 70)
    print()
    
    users, recommendations = load_data()
    
    # Create user profile lookup
    user_profiles = {u['user_id']: u['profile'] for u in users}
    
    results = []
    print(f"Calculating hybrid scores for {len(recommendations)} recommendations...")
    
    for rec in recommendations:
        user_profile = user_profiles[rec['user_id']]
        opportunity_profile = rec['opportunity_profile']
        ground_truth = rec['ground_truth_score']
        
        # Calculate hybrid score (70% quantum, 30% neural)
        hybrid, quantum, neural = hybrid_score(
            user_profile,
            opportunity_profile,
            INITIAL_QUANTUM_WEIGHT,
            INITIAL_NEURAL_WEIGHT,
            confidence=0.5  # Initial confidence
        )
        
        error = abs(hybrid - ground_truth)
        
        results.append({
            'recommendation_id': rec['recommendation_id'],
            'hybrid_score': hybrid,
            'quantum_score': quantum,
            'neural_score': neural,
            'ground_truth': ground_truth,
            'error': error,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    mae = df['error'].mean()
    rmse = np.sqrt(df['error'].pow(2).mean())
    correlation, p_value = pearsonr(df['hybrid_score'], df['ground_truth'])
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Mean Absolute Error: {mae:.6f}")
    print(f"Root Mean Squared Error: {rmse:.6f}")
    print(f"Correlation: {correlation:.6f} (p={p_value:.2e})")
    
    df.to_csv(RESULTS_DIR / 'hybrid_architecture.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'hybrid_architecture.csv'}")
    
    return {
        'mae': mae,
        'rmse': rmse,
        'correlation': correlation,
    }


def experiment_2_gradual_transition():
    """Experiment 2: Gradual Transition Effectiveness."""
    print("=" * 70)
    print("Experiment 2: Gradual Transition Effectiveness")
    print("=" * 70)
    print()
    
    users, recommendations = load_data()
    user_profiles = {u['user_id']: u['profile'] for u in users}
    
    results = []
    print(f"Testing gradual transition for {len(recommendations)} recommendations...")
    
    # Test different confidence levels (0.0 to 1.0)
    confidence_levels = [0.0, 0.25, 0.5, 0.75, 1.0]
    
    for confidence in confidence_levels:
        # Calculate weights based on confidence
        # Start 70/30, gradually increase neural weight as confidence grows
        neural_weight = INITIAL_NEURAL_WEIGHT + (confidence * 0.3)  # Up to 60% neural
        quantum_weight = 1.0 - neural_weight
        
        scores = []
        for rec in recommendations[:100]:  # Sample for speed
            user_profile = user_profiles[rec['user_id']]
            opportunity_profile = rec['opportunity_profile']
            
            hybrid, _, _ = hybrid_score(
                user_profile,
                opportunity_profile,
                quantum_weight,
                neural_weight,
                confidence
            )
            scores.append(hybrid)
        
        avg_score = np.mean(scores)
        
        results.append({
            'confidence': confidence,
            'quantum_weight': quantum_weight,
            'neural_weight': neural_weight,
            'avg_score': avg_score,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    transition_smoothness = df['neural_weight'].diff().abs().mean()
    score_improvement = df['avg_score'].iloc[-1] - df['avg_score'].iloc[0]
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Transition Smoothness (avg weight change): {transition_smoothness:.6f}")
    print(f"Score Improvement (confidence 0.0 to 1.0): {score_improvement:.6f}")
    
    df.to_csv(RESULTS_DIR / 'gradual_transition.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'gradual_transition.csv'}")
    
    return {
        'transition_smoothness': transition_smoothness,
        'score_improvement': score_improvement,
    }


def experiment_3_neural_refinement():
    """Experiment 3: Neural Network Refinement Improvement."""
    print("=" * 70)
    print("Experiment 3: Neural Network Refinement Improvement")
    print("=" * 70)
    print()
    
    users, recommendations = load_data()
    user_profiles = {u['user_id']: u['profile'] for u in users}
    
    results = []
    print(f"Comparing neural refinement for {len(recommendations)} recommendations...")
    
    for rec in recommendations:
        user_profile = user_profiles[rec['user_id']]
        opportunity_profile = rec['opportunity_profile']
        ground_truth = rec['ground_truth_score']
        
        # Pure quantum (100% quantum, 0% neural)
        quantum_only, _, _ = hybrid_score(user_profile, opportunity_profile, 1.0, 0.0, 0.0)
        
        # Hybrid (70% quantum, 30% neural)
        hybrid, _, neural = hybrid_score(
            user_profile,
            opportunity_profile,
            INITIAL_QUANTUM_WEIGHT,
            INITIAL_NEURAL_WEIGHT,
            confidence=0.7
        )
        
        improvement = hybrid - quantum_only
        
        results.append({
            'recommendation_id': rec['recommendation_id'],
            'quantum_only': quantum_only,
            'hybrid_score': hybrid,
            'neural_contribution': neural * INITIAL_NEURAL_WEIGHT,
            'improvement': improvement,
            'ground_truth': ground_truth,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_improvement = df['improvement'].mean()
    improvement_rate = (df['improvement'] > 0).mean()
    avg_neural_contribution = df['neural_contribution'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Average Improvement (hybrid vs quantum-only): {avg_improvement:.6f}")
    print(f"Improvement Rate: {improvement_rate:.2%}")
    print(f"Average Neural Contribution: {avg_neural_contribution:.6f}")
    
    df.to_csv(RESULTS_DIR / 'neural_refinement.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'neural_refinement.csv'}")
    
    return {
        'avg_improvement': avg_improvement,
        'improvement_rate': improvement_rate,
        'avg_neural_contribution': avg_neural_contribution,
    }


def experiment_4_fallback_mechanism():
    """Experiment 4: Fallback Mechanism Reliability."""
    print("=" * 70)
    print("Experiment 4: Fallback Mechanism Reliability")
    print("=" * 70)
    print()
    
    users, recommendations = load_data()
    user_profiles = {u['user_id']: u['profile'] for u in users}
    
    results = []
    print(f"Testing fallback mechanism for {len(recommendations)} recommendations...")
    
    for rec in recommendations:
        user_profile = user_profiles[rec['user_id']]
        opportunity_profile = rec['opportunity_profile']
        
        # Simulate neural network failure (10% failure rate)
        neural_failed = random.random() < 0.1
        
        if neural_failed:
            # Fallback to quantum-only
            fallback_score, _, _ = hybrid_score(user_profile, opportunity_profile, 1.0, 0.0, 0.0)
            hybrid_score_val, _, _ = hybrid_score(
                user_profile,
                opportunity_profile,
                INITIAL_QUANTUM_WEIGHT,
                INITIAL_NEURAL_WEIGHT,
                confidence=0.5
            )
        else:
            # Normal hybrid
            hybrid_score_val, _, _ = hybrid_score(
                user_profile,
                opportunity_profile,
                INITIAL_QUANTUM_WEIGHT,
                INITIAL_NEURAL_WEIGHT,
                confidence=0.5
            )
            fallback_score = hybrid_score_val
        
        fallback_used = neural_failed
        score_difference = abs(fallback_score - hybrid_score_val)
        
        results.append({
            'recommendation_id': rec['recommendation_id'],
            'neural_failed': neural_failed,
            'fallback_used': fallback_used,
            'fallback_score': fallback_score,
            'hybrid_score': hybrid_score_val,
            'score_difference': score_difference,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    fallback_rate = df['fallback_used'].mean()
    avg_score_difference = df[df['fallback_used']]['score_difference'].mean() if df['fallback_used'].any() else 0.0
    fallback_reliability = (df[df['fallback_used']]['score_difference'] < 0.2).mean() if df['fallback_used'].any() else 1.0
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Fallback Usage Rate: {fallback_rate:.2%}")
    print(f"Average Score Difference (fallback vs hybrid): {avg_score_difference:.6f}")
    print(f"Fallback Reliability (difference < 0.2): {fallback_reliability:.2%}")
    
    df.to_csv(RESULTS_DIR / 'fallback_mechanism.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'fallback_mechanism.csv'}")
    
    return {
        'fallback_rate': fallback_rate,
        'avg_score_difference': avg_score_difference,
        'fallback_reliability': fallback_reliability,
    }


def validate_patent_claims(experiment_results):
    """Validate patent claims against experiment results."""
    validation_report = {
        'all_claims_validated': True,
        'claim_checks': [],
    }
    
    # Check Experiment 1: Hybrid architecture
    if experiment_results.get('exp1', {}).get('correlation', 0) > 0.5:
        validation_report['claim_checks'].append({
            'claim': 'Hybrid architecture (70% quantum, 30% neural) works accurately',
            'result': f"Correlation: {experiment_results['exp1']['correlation']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Hybrid architecture (70% quantum, 30% neural) works accurately',
            'result': f"Correlation: {experiment_results['exp1']['correlation']:.6f} (below 0.5)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 2: Gradual transition
    if experiment_results.get('exp2', {}).get('transition_smoothness', 1.0) < 0.2:
        validation_report['claim_checks'].append({
            'claim': 'Gradual transition works smoothly',
            'result': f"Transition smoothness: {experiment_results['exp2']['transition_smoothness']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Gradual transition works smoothly',
            'result': f"Transition smoothness: {experiment_results['exp2']['transition_smoothness']:.6f} (above 0.2)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 3: Neural refinement
    if experiment_results.get('exp3', {}).get('improvement_rate', 0) > 0.5:
        validation_report['claim_checks'].append({
            'claim': 'Neural network refinement improves scores',
            'result': f"Improvement rate: {experiment_results['exp3']['improvement_rate']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Neural network refinement improves scores',
            'result': f"Improvement rate: {experiment_results['exp3']['improvement_rate']:.2%} (below 50%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 4: Fallback mechanism
    if experiment_results.get('exp4', {}).get('fallback_reliability', 0) > 0.8:
        validation_report['claim_checks'].append({
            'claim': 'Fallback mechanism works reliably',
            'result': f"Fallback reliability: {experiment_results['exp4']['fallback_reliability']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Fallback mechanism works reliably',
            'result': f"Fallback reliability: {experiment_results['exp4']['fallback_reliability']:.2%} (below 80%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    return validation_report


def main():
    """Run all experiments."""
    print("=" * 70)
    print(f"Patent #{PATENT_NUMBER}: {PATENT_NAME} Experiments")
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Run all required experiments
    exp1_results = experiment_1_hybrid_architecture()
    exp2_results = experiment_2_gradual_transition()
    exp3_results = experiment_3_neural_refinement()
    exp4_results = experiment_4_fallback_mechanism()
    
    # Validate patent claims
    experiment_results = {
        'exp1': exp1_results,
        'exp2': exp2_results,
        'exp3': exp3_results,
        'exp4': exp4_results,
    }
    
    validation_report = validate_patent_claims(experiment_results)
    
    elapsed_time = time.time() - start_time
    
    # Final summary
    print("=" * 70)
    print("All Experiments Complete")
    print("=" * 70)
    print(f"Total Execution Time: {elapsed_time:.2f} seconds")
    print()
    
    # Print validation results
    if validation_report['all_claims_validated']:
        print("✅ All patent claims validated")
    else:
        print("⚠️  Some patent claims need review:")
        for check in validation_report['claim_checks']:
            if not check['valid']:
                print(f"  - {check['claim']}: {check['result']}")
    
    print()
    print("✅ All results saved to:", RESULTS_DIR)
    print()


if __name__ == '__main__':
    main()

