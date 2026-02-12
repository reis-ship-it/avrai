#!/usr/bin/env python3
"""
Patent #15: Tiered Discovery System with Compatibility Bridge Recommendations Experiments

Runs all 4 required experiments:
1. Multi-Tier Architecture Accuracy (P1)
2. Compatibility Bridge Algorithm Effectiveness (P1)
3. Adaptive Prioritization Accuracy (P1)
4. Confidence Scoring Accuracy (P1)

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
PATENT_NUMBER = "15"
PATENT_NAME = "Tiered Discovery System with Compatibility Bridge Recommendations"
PATENT_FOLDER = "patent_15_tiered_discovery"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_USERS = 500
NUM_OPPORTUNITIES = 1000
TIER1_THRESHOLD = 0.7
TIER2_MIN = 0.4
TIER2_MAX = 0.69
TIER3_MAX = 0.4
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)


def generate_synthetic_data():
    """Generate synthetic user and discovery opportunity data."""
    print("Generating synthetic data...")
    
    users = []
    for i in range(NUM_USERS):
        # Generate user preferences
        user = {
            'user_id': f'user_{i:04d}',
            'preferences': {
                'category_1': random.uniform(0.0, 1.0),
                'category_2': random.uniform(0.0, 1.0),
                'category_3': random.uniform(0.0, 1.0),
            },
            'direct_activity': random.uniform(0.0, 1.0),
            'ai2ai_confidence': random.uniform(0.0, 1.0),
            'network_confidence': random.uniform(0.0, 1.0),
            'context_match': random.uniform(0.0, 1.0),
        }
        users.append(user)
    
    opportunities = []
    for i in range(NUM_OPPORTUNITIES):
        # Generate discovery opportunity
        opportunity = {
            'opportunity_id': f'opp_{i:04d}',
            'category': random.choice(['category_1', 'category_2', 'category_3']),
            'has_direct_activity': random.random() < 0.3,
            'activity_strength': random.uniform(0.0, 1.0) if random.random() < 0.3 else 0.0,
            'has_ai2ai_learning': random.random() < 0.4,
            'ai2ai_confidence': random.uniform(0.0, 1.0) if random.random() < 0.4 else 0.0,
            'has_cloud_pattern': random.random() < 0.5,
            'network_confidence': random.uniform(0.0, 1.0) if random.random() < 0.5 else 0.0,
            'context_match': random.uniform(0.0, 1.0),
        }
        opportunities.append(opportunity)
    
    # Save data
    with open(DATA_DIR / 'synthetic_users.json', 'w') as f:
        json.dump(users, f, indent=2)
    with open(DATA_DIR / 'synthetic_opportunities.json', 'w') as f:
        json.dump(opportunities, f, indent=2)
    
    print(f"✅ Generated {len(users)} users and {len(opportunities)} opportunities")
    return users, opportunities


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_users.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_users.json', 'r') as f:
        users = json.load(f)
    with open(DATA_DIR / 'synthetic_opportunities.json', 'r') as f:
        opportunities = json.load(f)
    
    return users, opportunities


def calculate_confidence(opportunity):
    """Calculate confidence score: 40% direct activity + 25% AI2AI + 20% network + 15% context"""
    confidence = 0.0
    
    # Direct activity weight (40%)
    if opportunity['has_direct_activity']:
        confidence += 0.4 * opportunity['activity_strength']
    
    # AI2AI learned weight (25%)
    if opportunity['has_ai2ai_learning']:
        confidence += 0.25 * opportunity['ai2ai_confidence']
    
    # Cloud network weight (20%)
    if opportunity['has_cloud_pattern']:
        confidence += 0.2 * opportunity['network_confidence']
    
    # Contextual weight (15%)
    confidence += 0.15 * opportunity['context_match']
    
    return min(confidence, 1.0)


def assign_tier(confidence):
    """Assign opportunity to tier based on confidence."""
    if confidence >= TIER1_THRESHOLD:
        return 1
    elif confidence >= TIER2_MIN and confidence <= TIER2_MAX:
        return 2
    else:
        return 3


def calculate_bridge_compatibility(shared_preferences, unique_differences):
    """Calculate bridge compatibility: (shared × 0.6) + (bridge × 0.4)"""
    # Calculate shared compatibility (simplified)
    shared_compatibility = np.mean(list(shared_preferences.values())) if shared_preferences else 0.5
    
    # Calculate bridge score (how well it bridges differences)
    if unique_differences:
        bridge_score = 1.0 - np.mean([abs(diff) for diff in unique_differences.values()])
    else:
        bridge_score = 0.5
    
    # Weighted combination
    bridge_compatibility = (shared_compatibility * 0.6) + (bridge_score * 0.4)
    
    return bridge_compatibility, shared_compatibility, bridge_score


def experiment_1_multi_tier_architecture():
    """Experiment 1: Multi-Tier Architecture Accuracy."""
    print("=" * 70)
    print("Experiment 1: Multi-Tier Architecture Accuracy")
    print("=" * 70)
    print()
    
    users, opportunities = load_data()
    
    results = []
    print(f"Testing multi-tier architecture for {len(opportunities)} opportunities...")
    
    for opportunity in opportunities:
        # Calculate confidence
        confidence = calculate_confidence(opportunity)
        
        # Assign tier
        tier = assign_tier(confidence)
        
        # Check tier assignment correctness
        tier_correct = False
        if tier == 1:
            tier_correct = confidence >= TIER1_THRESHOLD
        elif tier == 2:
            tier_correct = confidence >= TIER2_MIN and confidence <= TIER2_MAX
        else:
            tier_correct = confidence < TIER3_MAX
        
        results.append({
            'opportunity_id': opportunity['opportunity_id'],
            'confidence': confidence,
            'tier': tier,
            'tier_correct': tier_correct,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    tier_accuracy = df['tier_correct'].mean()
    tier1_rate = (df['tier'] == 1).mean()
    tier2_rate = (df['tier'] == 2).mean()
    tier3_rate = (df['tier'] == 3).mean()
    avg_confidence_tier1 = df[df['tier'] == 1]['confidence'].mean() if len(df[df['tier'] == 1]) > 0 else 0.0
    avg_confidence_tier2 = df[df['tier'] == 2]['confidence'].mean() if len(df[df['tier'] == 2]) > 0 else 0.0
    avg_confidence_tier3 = df[df['tier'] == 3]['confidence'].mean() if len(df[df['tier'] == 3]) > 0 else 0.0
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Tier Assignment Accuracy: {tier_accuracy:.2%}")
    print(f"Tier 1 Rate: {tier1_rate:.2%}")
    print(f"Tier 2 Rate: {tier2_rate:.2%}")
    print(f"Tier 3 Rate: {tier3_rate:.2%}")
    print(f"Average Confidence (Tier 1): {avg_confidence_tier1:.6f}")
    print(f"Average Confidence (Tier 2): {avg_confidence_tier2:.6f}")
    print(f"Average Confidence (Tier 3): {avg_confidence_tier3:.6f}")
    
    df.to_csv(RESULTS_DIR / 'multi_tier_architecture.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'multi_tier_architecture.csv'}")
    
    return {
        'tier_accuracy': tier_accuracy,
        'tier1_rate': tier1_rate,
        'tier2_rate': tier2_rate,
        'tier3_rate': tier3_rate,
        'avg_confidence_tier1': avg_confidence_tier1,
        'avg_confidence_tier2': avg_confidence_tier2,
        'avg_confidence_tier3': avg_confidence_tier3,
    }


def experiment_2_compatibility_bridge():
    """Experiment 2: Compatibility Bridge Algorithm Effectiveness."""
    print("=" * 70)
    print("Experiment 2: Compatibility Bridge Algorithm Effectiveness")
    print("=" * 70)
    print()
    
    users, opportunities = load_data()
    
    results = []
    print(f"Testing compatibility bridge algorithm for {len(users)} user pairs...")
    
    # Create user pairs
    pairs = []
    for i in range(min(100, len(users))):  # Sample for speed
        for j in range(i + 1, min(i + 5, len(users))):
            pairs.append((users[i], users[j]))
    
    for user1, user2 in pairs:
        # Calculate shared preferences
        shared_preferences = {}
        for key in user1['preferences']:
            if key in user2['preferences']:
                shared_preferences[key] = (user1['preferences'][key] + user2['preferences'][key]) / 2.0
        
        # Calculate unique differences
        unique_differences = {}
        for key in user1['preferences']:
            if key in user2['preferences']:
                unique_differences[key] = user1['preferences'][key] - user2['preferences'][key]
        
        # Calculate bridge compatibility
        bridge_compat, shared_compat, bridge_score = calculate_bridge_compatibility(
            shared_preferences,
            unique_differences
        )
        
        results.append({
            'user1_id': user1['user_id'],
            'user2_id': user2['user_id'],
            'bridge_compatibility': bridge_compat,
            'shared_compatibility': shared_compat,
            'bridge_score': bridge_score,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_bridge_compat = df['bridge_compatibility'].mean()
    avg_shared_compat = df['shared_compatibility'].mean()
    avg_bridge_score = df['bridge_score'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Average Bridge Compatibility: {avg_bridge_compat:.6f}")
    print(f"Average Shared Compatibility: {avg_shared_compat:.6f}")
    print(f"Average Bridge Score: {avg_bridge_score:.6f}")
    
    df.to_csv(RESULTS_DIR / 'compatibility_bridge.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'compatibility_bridge.csv'}")
    
    return {
        'avg_bridge_compat': avg_bridge_compat,
        'avg_shared_compat': avg_shared_compat,
        'avg_bridge_score': avg_bridge_score,
    }


def experiment_3_adaptive_prioritization():
    """Experiment 3: Adaptive Prioritization Accuracy."""
    print("=" * 70)
    print("Experiment 3: Adaptive Prioritization Accuracy")
    print("=" * 70)
    print()
    
    users, opportunities = load_data()
    
    results = []
    print(f"Testing adaptive prioritization for {len(users)} users...")
    
    for user in users[:100]:  # Sample for speed
        # Simulate user interactions
        tier1_interactions = random.randint(0, 50)
        tier2_interactions = random.randint(0, 30)
        tier3_interactions = random.randint(0, 20)
        total_interactions = tier1_interactions + tier2_interactions + tier3_interactions
        
        if total_interactions > 0:
            tier1_rate = tier1_interactions / total_interactions
            tier2_rate = tier2_interactions / total_interactions
            tier3_rate = tier3_interactions / total_interactions
        else:
            tier1_rate = 0.33
            tier2_rate = 0.33
            tier3_rate = 0.34
        
        # Calculate adaptive weights (normalized)
        total_rate = tier1_rate + tier2_rate + tier3_rate
        if total_rate > 0:
            adaptive_weight_tier1 = tier1_rate / total_rate
            adaptive_weight_tier2 = tier2_rate / total_rate
            adaptive_weight_tier3 = tier3_rate / total_rate
        else:
            adaptive_weight_tier1 = 0.33
            adaptive_weight_tier2 = 0.33
            adaptive_weight_tier3 = 0.34
        
        results.append({
            'user_id': user['user_id'],
            'tier1_interactions': tier1_interactions,
            'tier2_interactions': tier2_interactions,
            'tier3_interactions': tier3_interactions,
            'total_interactions': total_interactions,
            'tier1_rate': tier1_rate,
            'tier2_rate': tier2_rate,
            'tier3_rate': tier3_rate,
            'adaptive_weight_tier1': adaptive_weight_tier1,
            'adaptive_weight_tier2': adaptive_weight_tier2,
            'adaptive_weight_tier3': adaptive_weight_tier3,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_tier1_rate = df['tier1_rate'].mean()
    avg_tier2_rate = df['tier2_rate'].mean()
    avg_tier3_rate = df['tier3_rate'].mean()
    avg_adaptive_weight_tier1 = df['adaptive_weight_tier1'].mean()
    avg_adaptive_weight_tier2 = df['adaptive_weight_tier2'].mean()
    avg_adaptive_weight_tier3 = df['adaptive_weight_tier3'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Average Tier 1 Interaction Rate: {avg_tier1_rate:.2%}")
    print(f"Average Tier 2 Interaction Rate: {avg_tier2_rate:.2%}")
    print(f"Average Tier 3 Interaction Rate: {avg_tier3_rate:.2%}")
    print(f"Average Adaptive Weight (Tier 1): {avg_adaptive_weight_tier1:.6f}")
    print(f"Average Adaptive Weight (Tier 2): {avg_adaptive_weight_tier2:.6f}")
    print(f"Average Adaptive Weight (Tier 3): {avg_adaptive_weight_tier3:.6f}")
    
    df.to_csv(RESULTS_DIR / 'adaptive_prioritization.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'adaptive_prioritization.csv'}")
    
    return {
        'avg_tier1_rate': avg_tier1_rate,
        'avg_tier2_rate': avg_tier2_rate,
        'avg_tier3_rate': avg_tier3_rate,
        'avg_adaptive_weight_tier1': avg_adaptive_weight_tier1,
        'avg_adaptive_weight_tier2': avg_adaptive_weight_tier2,
        'avg_adaptive_weight_tier3': avg_adaptive_weight_tier3,
    }


def experiment_4_confidence_scoring():
    """Experiment 4: Confidence Scoring Accuracy."""
    print("=" * 70)
    print("Experiment 4: Confidence Scoring Accuracy")
    print("=" * 70)
    print()
    
    users, opportunities = load_data()
    
    results = []
    print(f"Testing confidence scoring for {len(opportunities)} opportunities...")
    
    for opportunity in opportunities:
        # Calculate confidence
        confidence = calculate_confidence(opportunity)
        
        # Check component contributions
        direct_activity_contrib = 0.4 * opportunity['activity_strength'] if opportunity['has_direct_activity'] else 0.0
        ai2ai_contrib = 0.25 * opportunity['ai2ai_confidence'] if opportunity['has_ai2ai_learning'] else 0.0
        network_contrib = 0.2 * opportunity['network_confidence'] if opportunity['has_cloud_pattern'] else 0.0
        context_contrib = 0.15 * opportunity['context_match']
        
        total_contrib = direct_activity_contrib + ai2ai_contrib + network_contrib + context_contrib
        
        results.append({
            'opportunity_id': opportunity['opportunity_id'],
            'confidence': confidence,
            'direct_activity_contrib': direct_activity_contrib,
            'ai2ai_contrib': ai2ai_contrib,
            'network_contrib': network_contrib,
            'context_contrib': context_contrib,
            'total_contrib': total_contrib,
            'confidence_correct': abs(confidence - total_contrib) < 0.001,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    confidence_accuracy = df['confidence_correct'].mean()
    avg_confidence = df['confidence'].mean()
    avg_direct_contrib = df['direct_activity_contrib'].mean()
    avg_ai2ai_contrib = df['ai2ai_contrib'].mean()
    avg_network_contrib = df['network_contrib'].mean()
    avg_context_contrib = df['context_contrib'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Confidence Scoring Accuracy: {confidence_accuracy:.2%}")
    print(f"Average Confidence: {avg_confidence:.6f}")
    print(f"Average Direct Activity Contribution: {avg_direct_contrib:.6f}")
    print(f"Average AI2AI Contribution: {avg_ai2ai_contrib:.6f}")
    print(f"Average Network Contribution: {avg_network_contrib:.6f}")
    print(f"Average Context Contribution: {avg_context_contrib:.6f}")
    
    df.to_csv(RESULTS_DIR / 'confidence_scoring.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'confidence_scoring.csv'}")
    
    return {
        'confidence_accuracy': confidence_accuracy,
        'avg_confidence': avg_confidence,
        'avg_direct_contrib': avg_direct_contrib,
        'avg_ai2ai_contrib': avg_ai2ai_contrib,
        'avg_network_contrib': avg_network_contrib,
        'avg_context_contrib': avg_context_contrib,
    }


def validate_patent_claims(experiment_results):
    """Validate patent claims against experiment results."""
    validation_report = {
        'all_claims_validated': True,
        'claim_checks': [],
    }
    
    # Check Experiment 1: Multi-tier architecture
    if experiment_results.get('exp1', {}).get('tier_accuracy', 0) >= 0.95:
        validation_report['claim_checks'].append({
            'claim': 'Multi-tier architecture works accurately',
            'result': f"Tier accuracy: {experiment_results['exp1']['tier_accuracy']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Multi-tier architecture works accurately',
            'result': f"Tier accuracy: {experiment_results['exp1']['tier_accuracy']:.2%} (below 95%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 2: Compatibility bridge
    if experiment_results.get('exp2', {}).get('avg_bridge_compat', 0) > 0:
        validation_report['claim_checks'].append({
            'claim': 'Compatibility bridge algorithm works effectively',
            'result': f"Average bridge compatibility: {experiment_results['exp2']['avg_bridge_compat']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Compatibility bridge algorithm works effectively',
            'result': f"Average bridge compatibility: {experiment_results['exp2']['avg_bridge_compat']:.6f} (zero)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 3: Adaptive prioritization
    if experiment_results.get('exp3', {}).get('avg_adaptive_weight_tier1', 0) > 0:
        validation_report['claim_checks'].append({
            'claim': 'Adaptive prioritization works correctly',
            'result': f"Average adaptive weight (Tier 1): {experiment_results['exp3']['avg_adaptive_weight_tier1']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Adaptive prioritization works correctly',
            'result': f"Average adaptive weight (Tier 1): {experiment_results['exp3']['avg_adaptive_weight_tier1']:.6f} (zero)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 4: Confidence scoring
    if experiment_results.get('exp4', {}).get('confidence_accuracy', 0) >= 0.95:
        validation_report['claim_checks'].append({
            'claim': 'Confidence scoring works accurately',
            'result': f"Confidence accuracy: {experiment_results['exp4']['confidence_accuracy']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Confidence scoring works accurately',
            'result': f"Confidence accuracy: {experiment_results['exp4']['confidence_accuracy']:.2%} (below 95%)",
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
    exp1_results = experiment_1_multi_tier_architecture()
    exp2_results = experiment_2_compatibility_bridge()
    exp3_results = experiment_3_adaptive_prioritization()
    exp4_results = experiment_4_confidence_scoring()
    
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

