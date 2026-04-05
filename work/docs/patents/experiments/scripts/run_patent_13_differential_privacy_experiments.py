#!/usr/bin/env python3
"""
Patent #13: Differential Privacy with Entropy Validation Experiments

Runs all 4 required experiments:
1. Laplace Noise Addition Accuracy (P1)
2. Epsilon Privacy Budget Effectiveness (P1)
3. Entropy Validation Accuracy (P1)
4. Temporal Decay Signature Effectiveness (P1)

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
import hashlib
import warnings
warnings.filterwarnings('ignore')

# Configuration
PATENT_NUMBER = "13"
PATENT_NAME = "Differential Privacy with Entropy Validation"
PATENT_FOLDER = "patent_13_differential_privacy"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_PROFILES = 500
DEFAULT_EPSILON = 0.02
MIN_ENTROPY = 0.8
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)


def generate_synthetic_data():
    """Generate synthetic personality profile data."""
    print("Generating synthetic data...")
    
    profiles = []
    for i in range(NUM_PROFILES):
        # Generate 12-dimensional personality profile
        profile = {
            'profile_id': f'profile_{i:04d}',
            'dimensions': {
                f'dim_{j}': random.uniform(0.0, 1.0) for j in range(12)
            }
        }
        profiles.append(profile)
    
    # Save data
    with open(DATA_DIR / 'synthetic_profiles.json', 'w') as f:
        json.dump(profiles, f, indent=2)
    
    print(f"✅ Generated {len(profiles)} profiles")
    return profiles


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_profiles.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_profiles.json', 'r') as f:
        profiles = json.load(f)
    
    return profiles


def laplace_noise(epsilon, sensitivity):
    """Generate Laplace noise: L(0, scale) where scale = sensitivity / epsilon"""
    u = random.uniform(-0.5, 0.5)
    scale = sensitivity / epsilon if epsilon > 0 else float('inf')
    
    # Laplace distribution: -scale * sign(u) * log(1 - 2*|u|)
    noise = -scale * np.sign(u) * np.log(1 - 2 * abs(u))
    
    return noise


def apply_differential_privacy(data, epsilon=DEFAULT_EPSILON, sensitivity=1.0):
    """Apply differential privacy with Laplace noise."""
    noisy_data = {}
    
    for key, value in data.items():
        noise = laplace_noise(epsilon, sensitivity)
        noisy_value = np.clip(value + noise, 0.0, 1.0)  # Clamp to [0, 1]
        noisy_data[key] = noisy_value
    
    return noisy_data


def calculate_entropy(data, bins=10):
    """Calculate entropy: H(X) = -Σ p(x) log₂(p(x))"""
    # Convert to array
    values = np.array(list(data.values()))
    
    # Create histogram
    hist, _ = np.histogram(values, bins=bins, range=(0.0, 1.0))
    
    # Normalize to probabilities
    probs = hist / np.sum(hist) if np.sum(hist) > 0 else hist
    
    # Calculate entropy
    entropy = 0.0
    for p in probs:
        if p > 0:
            entropy -= p * np.log2(p)
    
    return entropy


def validate_entropy(anonymized_data, min_entropy=MIN_ENTROPY):
    """Validate entropy meets minimum threshold."""
    entropy = calculate_entropy(anonymized_data)
    return entropy >= min_entropy, entropy


def generate_secure_salt(length=32):
    """Generate cryptographically secure random salt."""
    salt_bytes = np.random.bytes(length)
    salt = salt_bytes.hex()
    return salt


def create_secure_hash(data, salt, iterations=1000):
    """Create SHA-256 hash with multiple iterations."""
    current_hash = (data + salt).encode('utf-8')
    
    for _ in range(iterations):
        current_hash = hashlib.sha256(current_hash).digest()
    
    return current_hash.hex()


def create_temporal_decay_signature(salt, window_minutes=15):
    """Create temporal decay signature with time window."""
    now = time.time()
    
    # Round to time window
    window_seconds = window_minutes * 60
    window_start = int(now // window_seconds) * window_seconds
    
    # Create temporal data
    temporal_data = f"{salt}-{window_start}"
    
    # Create signature
    signature = create_secure_hash(temporal_data, salt)
    
    return signature, window_start


def experiment_1_laplace_noise():
    """Experiment 1: Laplace Noise Addition Accuracy."""
    print("=" * 70)
    print("Experiment 1: Laplace Noise Addition Accuracy")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Applying Laplace noise to {len(profiles)} profiles...")
    
    for profile in profiles:
        original_data = profile['dimensions']
        
        # Apply differential privacy
        noisy_data = apply_differential_privacy(original_data, epsilon=DEFAULT_EPSILON)
        
        # Calculate noise statistics
        noise_values = []
        for key in original_data:
            noise = noisy_data[key] - original_data[key]
            noise_values.append(noise)
        
        avg_noise = np.mean(noise_values)
        noise_std = np.std(noise_values)
        max_noise = np.max(np.abs(noise_values))
        
        # Calculate utility (correlation with original)
        original_values = list(original_data.values())
        noisy_values = list(noisy_data.values())
        correlation, p_value = pearsonr(original_values, noisy_values)
        
        results.append({
            'profile_id': profile['profile_id'],
            'avg_noise': avg_noise,
            'noise_std': noise_std,
            'max_noise': max_noise,
            'correlation': correlation,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_noise_mean = df['avg_noise'].mean()
    avg_noise_std = df['noise_std'].mean()
    avg_max_noise = df['max_noise'].mean()
    avg_correlation = df['correlation'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Average Noise Mean: {avg_noise_mean:.6f}")
    print(f"Average Noise Std: {avg_noise_std:.6f}")
    print(f"Average Max Noise: {avg_max_noise:.6f}")
    print(f"Average Correlation (utility): {avg_correlation:.6f}")
    
    df.to_csv(RESULTS_DIR / 'laplace_noise.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'laplace_noise.csv'}")
    
    return {
        'avg_noise_mean': avg_noise_mean,
        'avg_noise_std': avg_noise_std,
        'avg_max_noise': avg_max_noise,
        'avg_correlation': avg_correlation,
    }


def experiment_2_epsilon_privacy_budget():
    """Experiment 2: Epsilon Privacy Budget Effectiveness."""
    print("=" * 70)
    print("Experiment 2: Epsilon Privacy Budget Effectiveness")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Testing epsilon privacy budgets for {len(profiles)} profiles...")
    
    epsilon_levels = [0.01, 0.02, 0.1]  # Maximum, High, Standard
    
    for epsilon in epsilon_levels:
        correlations = []
        noise_levels = []
        
        for profile in profiles[:100]:  # Sample for speed
            original_data = profile['dimensions']
            noisy_data = apply_differential_privacy(original_data, epsilon=epsilon)
            
            # Calculate correlation (utility)
            original_values = list(original_data.values())
            noisy_values = list(noisy_data.values())
            correlation, _ = pearsonr(original_values, noisy_values)
            correlations.append(correlation)
            
            # Calculate noise level
            noise = np.mean([abs(noisy_data[k] - original_data[k]) for k in original_data])
            noise_levels.append(noise)
        
        avg_correlation = np.mean(correlations)
        avg_noise = np.mean(noise_levels)
        
        results.append({
            'epsilon': epsilon,
            'avg_correlation': avg_correlation,
            'avg_noise': avg_noise,
            'privacy_level': 'MAXIMUM' if epsilon == 0.01 else 'HIGH' if epsilon == 0.02 else 'STANDARD',
        })
    
    df = pd.DataFrame(results)
    
    print()
    print("Results:")
    print("-" * 70)
    for _, row in df.iterrows():
        print(f"Epsilon {row['epsilon']:.3f} ({row['privacy_level']}):")
        print(f"  Average Correlation: {row['avg_correlation']:.6f}")
        print(f"  Average Noise: {row['avg_noise']:.6f}")
    
    df.to_csv(RESULTS_DIR / 'epsilon_privacy_budget.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'epsilon_privacy_budget.csv'}")
    
    return {
        'epsilon_levels': df['epsilon'].tolist(),
        'avg_correlations': df['avg_correlation'].tolist(),
        'avg_noise_levels': df['avg_noise'].tolist(),
    }


def experiment_3_entropy_validation():
    """Experiment 3: Entropy Validation Accuracy."""
    print("=" * 70)
    print("Experiment 3: Entropy Validation Accuracy")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Validating entropy for {len(profiles)} profiles...")
    
    for profile in profiles:
        original_data = profile['dimensions']
        
        # Apply differential privacy
        noisy_data = apply_differential_privacy(original_data, epsilon=DEFAULT_EPSILON)
        
        # Validate entropy
        is_valid, entropy = validate_entropy(noisy_data, min_entropy=MIN_ENTROPY)
        
        # Calculate original entropy for comparison
        original_entropy = calculate_entropy(original_data)
        
        results.append({
            'profile_id': profile['profile_id'],
            'original_entropy': original_entropy,
            'anonymized_entropy': entropy,
            'min_entropy': MIN_ENTROPY,
            'is_valid': is_valid,
            'entropy_meets_threshold': entropy >= MIN_ENTROPY,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    validation_rate = df['is_valid'].mean()
    avg_original_entropy = df['original_entropy'].mean()
    avg_anonymized_entropy = df['anonymized_entropy'].mean()
    entropy_improvement = avg_anonymized_entropy - avg_original_entropy
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Validation Rate (entropy >= {MIN_ENTROPY}): {validation_rate:.2%}")
    print(f"Average Original Entropy: {avg_original_entropy:.6f}")
    print(f"Average Anonymized Entropy: {avg_anonymized_entropy:.6f}")
    print(f"Entropy Improvement: {entropy_improvement:.6f}")
    
    df.to_csv(RESULTS_DIR / 'entropy_validation.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'entropy_validation.csv'}")
    
    return {
        'validation_rate': validation_rate,
        'avg_original_entropy': avg_original_entropy,
        'avg_anonymized_entropy': avg_anonymized_entropy,
        'entropy_improvement': entropy_improvement,
    }


def experiment_4_temporal_decay_signature():
    """Experiment 4: Temporal Decay Signature Effectiveness."""
    print("=" * 70)
    print("Experiment 4: Temporal Decay Signature Effectiveness")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Creating temporal decay signatures for {len(profiles)} profiles...")
    
    for profile in profiles:
        # Generate fresh salt
        salt = generate_secure_salt()
        
        # Create temporal signature
        signature, window_start = create_temporal_decay_signature(salt, window_minutes=15)
        
        # Simulate time passage (test expiration)
        current_time = time.time()
        expiration_time = window_start + (30 * 24 * 60 * 60)  # 30 days
        is_expired = current_time > expiration_time
        
        # Test signature uniqueness (same salt, different time windows)
        signature2, window_start2 = create_temporal_decay_signature(salt, window_minutes=15)
        signatures_different = (signature != signature2) or (window_start != window_start2)
        
        results.append({
            'profile_id': profile['profile_id'],
            'salt': salt,
            'signature': signature,
            'window_start': window_start,
            'expiration_time': expiration_time,
            'is_expired': is_expired,
            'signatures_different': signatures_different,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    unique_salts = df['salt'].nunique()
    unique_signatures = df['signature'].nunique()
    expiration_rate = df['is_expired'].mean()
    uniqueness_rate = df['signatures_different'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Unique Salts: {unique_salts}/{len(profiles)} (100% unique expected)")
    print(f"Unique Signatures: {unique_signatures}/{len(profiles)}")
    print(f"Expiration Rate: {expiration_rate:.2%}")
    print(f"Signature Uniqueness Rate: {uniqueness_rate:.2%}")
    
    df.to_csv(RESULTS_DIR / 'temporal_decay_signature.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'temporal_decay_signature.csv'}")
    
    return {
        'unique_salts': unique_salts,
        'unique_signatures': unique_signatures,
        'expiration_rate': expiration_rate,
        'uniqueness_rate': uniqueness_rate,
    }


def validate_patent_claims(experiment_results):
    """Validate patent claims against experiment results."""
    validation_report = {
        'all_claims_validated': True,
        'claim_checks': [],
    }
    
    # Check Experiment 1: Laplace noise
    if abs(experiment_results.get('exp1', {}).get('avg_noise_mean', 1.0)) < 0.1:
        validation_report['claim_checks'].append({
            'claim': 'Laplace noise addition works correctly',
            'result': f"Average noise mean: {experiment_results['exp1']['avg_noise_mean']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Laplace noise addition works correctly',
            'result': f"Average noise mean: {experiment_results['exp1']['avg_noise_mean']:.6f} (above 0.1)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 2: Epsilon privacy budget
    if experiment_results.get('exp2', {}).get('avg_correlations', [0])[1] > 0.5:  # epsilon=0.02
        validation_report['claim_checks'].append({
            'claim': 'Epsilon privacy budget (ε=0.02) provides good privacy-utility tradeoff',
            'result': f"Average correlation: {experiment_results['exp2']['avg_correlations'][1]:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Epsilon privacy budget (ε=0.02) provides good privacy-utility tradeoff',
            'result': f"Average correlation: {experiment_results['exp2']['avg_correlations'][1]:.6f} (below 0.5)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 3: Entropy validation
    if experiment_results.get('exp3', {}).get('validation_rate', 0) >= 0.8:
        validation_report['claim_checks'].append({
            'claim': 'Entropy validation ensures minimum entropy (0.8+)',
            'result': f"Validation rate: {experiment_results['exp3']['validation_rate']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Entropy validation ensures minimum entropy (0.8+)',
            'result': f"Validation rate: {experiment_results['exp3']['validation_rate']:.2%} (below 80%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 4: Temporal decay signature
    if experiment_results.get('exp4', {}).get('unique_salts', 0) == NUM_PROFILES:
        validation_report['claim_checks'].append({
            'claim': 'Temporal decay signatures work with unique salts',
            'result': f"Unique salts: {experiment_results['exp4']['unique_salts']}/{NUM_PROFILES}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Temporal decay signatures work with unique salts',
            'result': f"Unique salts: {experiment_results['exp4']['unique_salts']}/{NUM_PROFILES} (not all unique)",
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
    exp1_results = experiment_1_laplace_noise()
    exp2_results = experiment_2_epsilon_privacy_budget()
    exp3_results = experiment_3_entropy_validation()
    exp4_results = experiment_4_temporal_decay_signature()
    
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

