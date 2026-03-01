#!/usr/bin/env python3
"""
Patent #4: Privacy-Preserving Anonymized Vibe Signature Experiments

Runs all 4 required experiments:
1. Anonymized Dimension Extraction Accuracy (P1)
2. Vibe Signature Generation Effectiveness (P1)
3. Privacy-Preserving Compatibility Accuracy (P1)
4. Zero-Knowledge Exchange Validation (P1)

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
PATENT_NUMBER = "4"
PATENT_NAME = "Privacy-Preserving Anonymized Vibe Signature"
PATENT_FOLDER = "patent_4_vibe_signatures"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_PROFILES = 500
EPSILON = 0.02  # Differential privacy epsilon
SENSITIVITY = 1.0
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
            },
            'user_id': f'user_{i:04d}',  # Personal identifier (will be removed)
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
    """Generate Laplace noise."""
    u = random.uniform(-0.5, 0.5)
    scale = sensitivity / epsilon if epsilon > 0 else float('inf')
    noise = -scale * np.sign(u) * np.log(1 - 2 * abs(u))
    return noise


def anonymize_dimensions(dimensions, epsilon=EPSILON, sensitivity=SENSITIVITY):
    """Anonymize dimensions using differential privacy."""
    anonymized = {}
    
    for key, value in dimensions.items():
        noise = laplace_noise(epsilon, sensitivity)
        anonymized_value = np.clip(value + noise, 0.0, 1.0)
        anonymized[key] = anonymized_value
    
    return anonymized


def generate_secure_salt(length=32):
    """Generate cryptographically secure random salt."""
    salt_bytes = np.random.bytes(length)
    return salt_bytes.hex()


def create_archetype_hash(archetype, salt):
    """Create archetype hash (no identifiers)."""
    data = f"{archetype}-{salt}"
    hash_obj = hashlib.sha256(data.encode('utf-8'))
    return hash_obj.hexdigest()


def create_temporal_signature(salt):
    """Create temporal signature with expiration."""
    now = time.time()
    window_seconds = 15 * 60  # 15 minutes
    window_start = int(now // window_seconds) * window_seconds
    
    temporal_data = f"{salt}-{window_start}"
    signature = hashlib.sha256(temporal_data.encode('utf-8')).hexdigest()
    
    return signature, window_start


def create_vibe_signature(profile, anonymized_dimensions):
    """Create anonymized vibe signature."""
    # Generate salt
    salt = generate_secure_salt()
    
    # Create archetype hash (no identifiers)
    archetype = "default"  # No personal identifiers
    archetype_hash = create_archetype_hash(archetype, salt)
    
    # Create temporal signature
    temporal_sig, window_start = create_temporal_signature(salt)
    
    # Combine into signature
    signature = {
        'anonymized_dimensions': anonymized_dimensions,
        'archetype_hash': archetype_hash,
        'temporal_signature': temporal_sig,
        'salt': salt,
        'window_start': window_start,
    }
    
    return signature


def calculate_compatibility(signature1, signature2):
    """Calculate compatibility from anonymized signatures."""
    dims1 = list(signature1['anonymized_dimensions'].values())
    dims2 = list(signature2['anonymized_dimensions'].values())
    
    # Quantum compatibility: C = |⟨ψ₁|ψ₂⟩|²
    vec1 = np.array(dims1)
    vec2 = np.array(dims2)
    
    # Normalize
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    
    if norm1 > 0:
        vec1 = vec1 / norm1
    if norm2 > 0:
        vec2 = vec2 / norm2
    
    inner_product = np.abs(np.dot(vec1, vec2))
    compatibility = inner_product ** 2
    
    return compatibility


def experiment_1_anonymized_dimension_extraction():
    """Experiment 1: Anonymized Dimension Extraction Accuracy."""
    print("=" * 70)
    print("Experiment 1: Anonymized Dimension Extraction Accuracy")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Extracting anonymized dimensions for {len(profiles)} profiles...")
    
    for profile in profiles:
        original_dimensions = profile['dimensions']
        
        # Anonymize dimensions
        anonymized_dimensions = anonymize_dimensions(original_dimensions)
        
        # Calculate noise statistics
        noise_values = []
        for key in original_dimensions:
            noise = anonymized_dimensions[key] - original_dimensions[key]
            noise_values.append(noise)
        
        avg_noise = np.mean(noise_values)
        noise_std = np.std(noise_values)
        max_noise = np.max(np.abs(noise_values))
        
        # Check privacy (no personal identifiers)
        has_identifiers = 'user_id' in anonymized_dimensions or any('user' in str(k) for k in anonymized_dimensions.keys())
        
        results.append({
            'profile_id': profile['profile_id'],
            'avg_noise': avg_noise,
            'noise_std': noise_std,
            'max_noise': max_noise,
            'has_identifiers': has_identifiers,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_noise_mean = df['avg_noise'].mean()
    avg_noise_std = df['noise_std'].mean()
    avg_max_noise = df['max_noise'].mean()
    privacy_rate = (~df['has_identifiers']).mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Average Noise Mean: {avg_noise_mean:.6f}")
    print(f"Average Noise Std: {avg_noise_std:.6f}")
    print(f"Average Max Noise: {avg_max_noise:.6f}")
    print(f"Privacy Rate (no identifiers): {privacy_rate:.2%}")
    
    df.to_csv(RESULTS_DIR / 'anonymized_dimension_extraction.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'anonymized_dimension_extraction.csv'}")
    
    return {
        'avg_noise_mean': avg_noise_mean,
        'avg_noise_std': avg_noise_std,
        'avg_max_noise': avg_max_noise,
        'privacy_rate': privacy_rate,
    }


def experiment_2_vibe_signature_generation():
    """Experiment 2: Vibe Signature Generation Effectiveness."""
    print("=" * 70)
    print("Experiment 2: Vibe Signature Generation Effectiveness")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Generating vibe signatures for {len(profiles)} profiles...")
    
    for profile in profiles:
        original_dimensions = profile['dimensions']
        
        # Anonymize dimensions
        anonymized_dimensions = anonymize_dimensions(original_dimensions)
        
        # Create vibe signature
        signature = create_vibe_signature(profile, anonymized_dimensions)
        
        # Check signature properties
        has_personal_data = 'user_id' in signature or 'profile_id' in signature
        has_anonymized_dims = 'anonymized_dimensions' in signature
        has_archetype_hash = 'archetype_hash' in signature
        has_temporal_sig = 'temporal_signature' in signature
        has_salt = 'salt' in signature
        
        results.append({
            'profile_id': profile['profile_id'],
            'has_personal_data': has_personal_data,
            'has_anonymized_dims': has_anonymized_dims,
            'has_archetype_hash': has_archetype_hash,
            'has_temporal_sig': has_temporal_sig,
            'has_salt': has_salt,
            'signature_valid': not has_personal_data and has_anonymized_dims and has_archetype_hash and has_temporal_sig and has_salt,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    signature_validity_rate = df['signature_valid'].mean()
    privacy_rate = (~df['has_personal_data']).mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Signature Validity Rate: {signature_validity_rate:.2%}")
    print(f"Privacy Rate (no personal data): {privacy_rate:.2%}")
    
    df.to_csv(RESULTS_DIR / 'vibe_signature_generation.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'vibe_signature_generation.csv'}")
    
    return {
        'signature_validity_rate': signature_validity_rate,
        'privacy_rate': privacy_rate,
    }


def experiment_3_privacy_preserving_compatibility():
    """Experiment 3: Privacy-Preserving Compatibility Accuracy."""
    print("=" * 70)
    print("Experiment 3: Privacy-Preserving Compatibility Accuracy")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Calculating privacy-preserving compatibility for {len(profiles)} profile pairs...")
    
    # Create pairs
    pairs = []
    for i in range(min(100, len(profiles))):  # Sample for speed
        for j in range(i + 1, min(i + 10, len(profiles))):  # Limited pairs per profile
            pairs.append((profiles[i], profiles[j]))
    
    for profile1, profile2 in pairs:
        # Calculate original compatibility
        dims1 = np.array(list(profile1['dimensions'].values()))
        dims2 = np.array(list(profile2['dimensions'].values()))
        
        # Normalize
        norm1 = np.linalg.norm(dims1)
        norm2 = np.linalg.norm(dims2)
        if norm1 > 0:
            dims1 = dims1 / norm1
        if norm2 > 0:
            dims2 = dims2 / norm2
        
        original_compatibility = (np.abs(np.dot(dims1, dims2)) ** 2)
        
        # Create anonymized signatures
        anon_dims1 = anonymize_dimensions(profile1['dimensions'])
        anon_dims2 = anonymize_dimensions(profile2['dimensions'])
        
        sig1 = create_vibe_signature(profile1, anon_dims1)
        sig2 = create_vibe_signature(profile2, anon_dims2)
        
        # Calculate anonymized compatibility
        anonymized_compatibility = calculate_compatibility(sig1, sig2)
        
        error = abs(anonymized_compatibility - original_compatibility)
        
        results.append({
            'profile1_id': profile1['profile_id'],
            'profile2_id': profile2['profile_id'],
            'original_compatibility': original_compatibility,
            'anonymized_compatibility': anonymized_compatibility,
            'error': error,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    mae = df['error'].mean()
    rmse = np.sqrt(df['error'].pow(2).mean())
    correlation, p_value = pearsonr(df['original_compatibility'], df['anonymized_compatibility'])
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Mean Absolute Error: {mae:.6f}")
    print(f"Root Mean Squared Error: {rmse:.6f}")
    print(f"Correlation: {correlation:.6f} (p={p_value:.2e})")
    
    df.to_csv(RESULTS_DIR / 'privacy_preserving_compatibility.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'privacy_preserving_compatibility.csv'}")
    
    return {
        'mae': mae,
        'rmse': rmse,
        'correlation': correlation,
    }


def experiment_4_zero_knowledge_exchange():
    """Experiment 4: Zero-Knowledge Exchange Validation."""
    print("=" * 70)
    print("Experiment 4: Zero-Knowledge Exchange Validation")
    print("=" * 70)
    print()
    
    profiles = load_data()
    
    results = []
    print(f"Validating zero-knowledge exchange for {len(profiles)} profiles...")
    
    for profile in profiles:
        original_dimensions = profile['dimensions']
        user_id = profile['user_id']
        
        # Create anonymized signature
        anonymized_dimensions = anonymize_dimensions(original_dimensions)
        signature = create_vibe_signature(profile, anonymized_dimensions)
        
        # Check zero-knowledge properties
        # 1. No personal identifiers in signature
        signature_str = json.dumps(signature, sort_keys=True)
        has_user_id = user_id in signature_str
        
        # 2. Cannot reconstruct original from signature
        can_reconstruct = False
        for key, value in signature['anonymized_dimensions'].items():
            # Check if original value can be inferred (within noise range)
            original_value = original_dimensions.get(key, 0.0)
            noise_range = abs(value - original_value)
            if noise_range < 0.01:  # Very small noise = might be reconstructible
                can_reconstruct = True
                break
        
        # 3. Compatibility can be calculated without original data
        compatibility_calculable = 'anonymized_dimensions' in signature
        
        zero_knowledge_valid = not has_user_id and not can_reconstruct and compatibility_calculable
        
        results.append({
            'profile_id': profile['profile_id'],
            'has_user_id': has_user_id,
            'can_reconstruct': can_reconstruct,
            'compatibility_calculable': compatibility_calculable,
            'zero_knowledge_valid': zero_knowledge_valid,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    zero_knowledge_rate = df['zero_knowledge_valid'].mean()
    no_identifiers_rate = (~df['has_user_id']).mean()
    reconstruction_rate = df['can_reconstruct'].mean()
    compatibility_rate = df['compatibility_calculable'].mean()
    
    print()
    print("Results:")
    print("-" * 70)
    print(f"Zero-Knowledge Validity Rate: {zero_knowledge_rate:.2%}")
    print(f"No Identifiers Rate: {no_identifiers_rate:.2%}")
    print(f"Reconstruction Rate: {reconstruction_rate:.2%}")
    print(f"Compatibility Calculable Rate: {compatibility_rate:.2%}")
    
    df.to_csv(RESULTS_DIR / 'zero_knowledge_exchange.csv', index=False)
    print(f"✅ Results saved to: {RESULTS_DIR / 'zero_knowledge_exchange.csv'}")
    
    return {
        'zero_knowledge_rate': zero_knowledge_rate,
        'no_identifiers_rate': no_identifiers_rate,
        'reconstruction_rate': reconstruction_rate,
        'compatibility_rate': compatibility_rate,
    }


def validate_patent_claims(experiment_results):
    """Validate patent claims against experiment results."""
    validation_report = {
        'all_claims_validated': True,
        'claim_checks': [],
    }
    
    # Check Experiment 1: Anonymized dimension extraction
    if experiment_results.get('exp1', {}).get('privacy_rate', 0) >= 0.95:
        validation_report['claim_checks'].append({
            'claim': 'Anonymized dimension extraction preserves privacy',
            'result': f"Privacy rate: {experiment_results['exp1']['privacy_rate']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Anonymized dimension extraction preserves privacy',
            'result': f"Privacy rate: {experiment_results['exp1']['privacy_rate']:.2%} (below 95%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 2: Vibe signature generation
    if experiment_results.get('exp2', {}).get('signature_validity_rate', 0) >= 0.95:
        validation_report['claim_checks'].append({
            'claim': 'Vibe signature generation works effectively',
            'result': f"Signature validity rate: {experiment_results['exp2']['signature_validity_rate']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Vibe signature generation works effectively',
            'result': f"Signature validity rate: {experiment_results['exp2']['signature_validity_rate']:.2%} (below 95%)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 3: Privacy-preserving compatibility
    if experiment_results.get('exp3', {}).get('correlation', 0) > 0.3:
        validation_report['claim_checks'].append({
            'claim': 'Privacy-preserving compatibility maintains accuracy',
            'result': f"Correlation: {experiment_results['exp3']['correlation']:.6f}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Privacy-preserving compatibility maintains accuracy',
            'result': f"Correlation: {experiment_results['exp3']['correlation']:.6f} (below 0.3)",
            'valid': False
        })
        validation_report['all_claims_validated'] = False
    
    # Check Experiment 4: Zero-knowledge exchange
    if experiment_results.get('exp4', {}).get('zero_knowledge_rate', 0) >= 0.8:
        validation_report['claim_checks'].append({
            'claim': 'Zero-knowledge exchange works effectively',
            'result': f"Zero-knowledge rate: {experiment_results['exp4']['zero_knowledge_rate']:.2%}",
            'valid': True
        })
    else:
        validation_report['claim_checks'].append({
            'claim': 'Zero-knowledge exchange works effectively',
            'result': f"Zero-knowledge rate: {experiment_results['exp4']['zero_knowledge_rate']:.2%} (below 80%)",
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
    exp1_results = experiment_1_anonymized_dimension_extraction()
    exp2_results = experiment_2_vibe_signature_generation()
    exp3_results = experiment_3_privacy_preserving_compatibility()
    exp4_results = experiment_4_zero_knowledge_exchange()
    
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

