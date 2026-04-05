#!/usr/bin/env python3
"""
Patent #30: Privacy-Preserving Admin Viewer for Distributed AI Networks Experiments

Runs all 4 required experiments:
1. AdminPrivacyFilter Accuracy (P1)
2. Real-Time Monitoring Latency (P1)
3. AI-Only Data Visibility Accuracy (P1)
4. Privacy Validation (P1)

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from scipy.stats import pearsonr
from sklearn.metrics import mean_absolute_error, accuracy_score
from collections import defaultdict
import random
import warnings
warnings.filterwarnings('ignore')

# Configuration
PATENT_NUMBER = "30"
PATENT_NAME = "Privacy-Preserving Admin Viewer for Distributed AI Networks"
PATENT_FOLDER = "patent_30_privacy_preserving_admin_viewer"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_SAMPLES = 1000
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# Forbidden keys (personal data) from patent
FORBIDDEN_KEYS = [
    'name', 'email', 'phone', 'home_address', 'homeaddress',
    'residential_address', 'personal_address', 'personal', 'contact',
    'profile', 'displayname', 'username',
]

FORBIDDEN_LOCATION_KEYS = [
    'home_address', 'homeaddress', 'residential_address', 'personal_address',
]

# Allowed keys (AI-related and location data) from patent
ALLOWED_KEYS = [
    'ai_signature', 'user_id', 'ai_personality', 'ai_connections', 'ai_metrics',
    'connection_id', 'ai_status', 'ai_activity', 'location', 'current_location',
    'visited_locations', 'location_history', 'geographic_data', 'vibe_location',
    'spot_locations',
]


def generate_synthetic_data():
    """Generate synthetic admin data for experiments."""
    print("Generating synthetic data...")
    
    # Generate 500 AI agents with mixed personal and AI data
    agents = []
    for i in range(500):
        agent = {
            # Personal data (should be filtered)
            'name': f'User {i}',
            'email': f'user{i}@example.com',
            'phone': f'555-{i:04d}',
            'home_address': f'{i} Main St, City, State',
            'username': f'user_{i}',
            
            # AI-related data (should be allowed)
            'user_id': f'user_{i:04d}',
            'ai_signature': f'sig_{i:04d}',
            'ai_personality': np.random.rand(12).tolist(),
            'ai_connections': random.randint(0, 50),
            'ai_metrics': {
                'compatibility_score': random.uniform(0, 1),
                'connection_rate': random.uniform(0, 1),
            },
            'ai_status': random.choice(['online', 'offline', 'active']),
            'ai_activity': random.uniform(0, 100),
            
            # Location data (should be allowed - vibe indicators)
            'location': {
                'latitude': random.uniform(-90, 90),
                'longitude': random.uniform(-180, 180),
                'city': f'City_{i % 10}',
            },
            'current_location': f'Location_{i}',
            'visited_locations': [f'Loc_{j}' for j in range(random.randint(0, 10))],
        }
        agents.append(agent)
    
    # Generate AI2AI communications
    communications = []
    for i in range(1000):
        comm = {
            'communication_id': f'comm_{i:04d}',
            'agent_a_id': f'user_{random.randint(0, 499):04d}',
            'agent_b_id': f'user_{random.randint(0, 499):04d}',
            'timestamp': time.time() + i * 60,  # 1 minute intervals
            'message_content': f'AI message {i}',
            'learning_insight': random.random() < 0.3,
            'trust_metric': random.uniform(0, 1),
        }
        communications.append(comm)
    
    # Generate collective intelligence data
    collective_intelligence = {
        'network_patterns': {
            'pattern_1': {'strength': random.uniform(0.5, 1.0), 'confidence': random.uniform(0.6, 1.0)},
            'pattern_2': {'strength': random.uniform(0.5, 1.0), 'confidence': random.uniform(0.6, 1.0)},
            'pattern_3': {'strength': random.uniform(0.5, 1.0), 'confidence': random.uniform(0.6, 1.0)},
        },
        'insight_count': random.randint(100, 1000),
        'network_health': random.uniform(0.7, 1.0),
    }
    
    # Save data
    with open(DATA_DIR / 'synthetic_agents.json', 'w') as f:
        json.dump(agents, f, indent=2, default=str)
    
    with open(DATA_DIR / 'synthetic_communications.json', 'w') as f:
        json.dump(communications, f, indent=2, default=str)
    
    with open(DATA_DIR / 'collective_intelligence.json', 'w') as f:
        json.dump(collective_intelligence, f, indent=2, default=str)
    
    print(f"✅ Generated {len(agents)} agents, {len(communications)} communications, and collective intelligence")
    return agents, communications, collective_intelligence


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_agents.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_agents.json', 'r') as f:
        agents = json.load(f)
    
    with open(DATA_DIR / 'synthetic_communications.json', 'r') as f:
        communications = json.load(f)
    
    with open(DATA_DIR / 'collective_intelligence.json', 'r') as f:
        collective_intelligence = json.load(f)
    
    return agents, communications, collective_intelligence


def admin_privacy_filter(data):
    """Simulate AdminPrivacyFilter algorithm."""
    if isinstance(data, dict):
        filtered = {}
        for key, value in data.items():
            key_lower = key.lower()
            
            # Check if key is forbidden
            if any(forbidden in key_lower for forbidden in FORBIDDEN_KEYS):
                continue  # Skip personal data
            
            # Check if key is forbidden location
            if any(forbidden in key_lower for forbidden in FORBIDDEN_LOCATION_KEYS):
                continue  # Skip home address
            
            # Check if key is allowed
            if any(allowed in key_lower for allowed in ALLOWED_KEYS):
                # Recursively filter nested dictionaries
                if isinstance(value, dict):
                    filtered[key] = admin_privacy_filter(value)
                else:
                    filtered[key] = value
        
        return filtered
    elif isinstance(data, list):
        return [admin_privacy_filter(item) for item in data]
    else:
        return data


def check_personal_data_leak(filtered_data):
    """Check if any personal data leaked through filter."""
    if isinstance(filtered_data, dict):
        for key, value in filtered_data.items():
            key_lower = key.lower()
            
            # Check for forbidden keys
            if any(forbidden in key_lower for forbidden in FORBIDDEN_KEYS):
                return True
            
            # Check for forbidden location keys
            if any(forbidden in key_lower for forbidden in FORBIDDEN_LOCATION_KEYS):
                return True
            
            # Recursively check nested structures
            if isinstance(value, (dict, list)):
                if check_personal_data_leak(value):
                    return True
    
    elif isinstance(filtered_data, list):
        for item in filtered_data:
            if check_personal_data_leak(item):
                return True
    
    return False


def check_ai_data_preserved(original_data, filtered_data):
    """Check if AI-related data is preserved."""
    if isinstance(original_data, dict) and isinstance(filtered_data, dict):
        preserved_count = 0
        total_ai_keys = 0
        
        for key in original_data.keys():
            key_lower = key.lower()
            if any(allowed in key_lower for allowed in ALLOWED_KEYS):
                total_ai_keys += 1
                if key in filtered_data:
                    preserved_count += 1
        
        return preserved_count, total_ai_keys
    
    return 0, 0


# ============================================================================
# EXPERIMENTS
# ============================================================================

def experiment_1_privacy_filter_accuracy():
    """Experiment 1: AdminPrivacyFilter Accuracy"""
    print("\n" + "="*70)
    print("Experiment 1: AdminPrivacyFilter Accuracy")
    print("="*70)
    
    agents, _, _ = load_data()
    
    results = []
    for agent in agents:
        # Apply filter
        filtered = admin_privacy_filter(agent)
        
        # Check for personal data leaks
        has_leak = check_personal_data_leak(filtered)
        
        # Count preserved AI data
        preserved_count, total_ai_keys = check_ai_data_preserved(agent, filtered)
        preservation_rate = preserved_count / total_ai_keys if total_ai_keys > 0 else 0.0
        
        # Count filtered personal data
        personal_keys = sum(1 for key in agent.keys() 
                          if any(forbidden in key.lower() for forbidden in FORBIDDEN_KEYS))
        filtered_personal_keys = personal_keys - sum(1 for key in filtered.keys() 
                                                   if any(forbidden in key.lower() for forbidden in FORBIDDEN_KEYS))
        
        results.append({
            'agent_id': agent.get('user_id', 'unknown'),
            'has_personal_data_leak': has_leak,
            'preserved_ai_data_count': preserved_count,
            'total_ai_keys': total_ai_keys,
            'preservation_rate': preservation_rate,
            'personal_keys_in_original': personal_keys,
            'personal_keys_filtered': filtered_personal_keys,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    leak_rate = df['has_personal_data_leak'].mean()
    avg_preservation_rate = df['preservation_rate'].mean()
    avg_personal_filtered = df['personal_keys_filtered'].mean()
    
    # Filtering accuracy (should filter all personal data)
    filtering_accuracy = (df['personal_keys_filtered'] == df['personal_keys_in_original']).mean()
    
    results_summary = {
        'experiment': 'AdminPrivacyFilter Accuracy',
        'leak_rate': float(leak_rate),
        'avg_preservation_rate': float(avg_preservation_rate),
        'avg_personal_filtered': float(avg_personal_filtered),
        'filtering_accuracy': float(filtering_accuracy),
        'num_samples': len(results),
    }
    
    print(f"✅ Personal Data Leak Rate: {leak_rate:.4f} (should be 0.0)")
    print(f"✅ Average AI Data Preservation: {avg_preservation_rate:.4f}")
    print(f"✅ Average Personal Data Filtered: {avg_personal_filtered:.2f}")
    print(f"✅ Filtering Accuracy: {filtering_accuracy:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp1_privacy_filter_accuracy.csv', index=False)
    with open(RESULTS_DIR / 'exp1_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_2_real_time_monitoring_latency():
    """Experiment 2: Real-Time Monitoring Latency"""
    print("\n" + "="*70)
    print("Experiment 2: Real-Time Monitoring Latency")
    print("="*70)
    
    agents, communications, _ = load_data()
    
    results = []
    for comm in communications[:500]:  # Sample for efficiency
        start_time = time.time()
        
        # Simulate real-time monitoring processing
        # Filter communication data
        filtered_comm = admin_privacy_filter(comm)
        
        # Process AI2AI communication
        processing_time = (time.time() - start_time) * 1000  # Convert to milliseconds
        
        results.append({
            'communication_id': comm['communication_id'],
            'processing_time_ms': processing_time,
            'meets_target': processing_time < 3000,  # 3 second target for communications
            'has_learning_insight': comm.get('learning_insight', False),
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_latency = df['processing_time_ms'].mean()
    max_latency = df['processing_time_ms'].max()
    p95_latency = df['processing_time_ms'].quantile(0.95)
    meets_target_rate = df['meets_target'].mean()
    
    results_summary = {
        'experiment': 'Real-Time Monitoring Latency',
        'avg_latency_ms': float(avg_latency),
        'max_latency_ms': float(max_latency),
        'p95_latency_ms': float(p95_latency),
        'meets_target_rate': float(meets_target_rate),
        'target_latency_ms': 3000.0,  # 3 seconds for communications
        'num_samples': len(results),
    }
    
    print(f"✅ Average Latency: {avg_latency:.2f} ms")
    print(f"✅ Max Latency: {max_latency:.2f} ms")
    print(f"✅ P95 Latency: {p95_latency:.2f} ms")
    print(f"✅ Meets Target Rate: {meets_target_rate:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp2_real_time_monitoring_latency.csv', index=False)
    with open(RESULTS_DIR / 'exp2_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_3_ai_only_data_visibility():
    """Experiment 3: AI-Only Data Visibility Accuracy"""
    print("\n" + "="*70)
    print("Experiment 3: AI-Only Data Visibility Accuracy")
    print("="*70)
    
    agents, communications, collective_intelligence = load_data()
    
    results = []
    for agent in agents:
        # Apply filter
        filtered = admin_privacy_filter(agent)
        
        # Check what data is visible
        visible_keys = list(filtered.keys())
        
        # Count AI-related keys
        ai_keys_visible = sum(1 for key in visible_keys 
                            if any(allowed in key.lower() for allowed in ALLOWED_KEYS))
        
        # Count personal keys (should be 0)
        personal_keys_visible = sum(1 for key in visible_keys 
                                  if any(forbidden in key.lower() for forbidden in FORBIDDEN_KEYS))
        
        # Check location data (should be visible - vibe indicators)
        location_keys_visible = sum(1 for key in visible_keys 
                                   if 'location' in key.lower())
        
        results.append({
            'agent_id': agent.get('user_id', 'unknown'),
            'ai_keys_visible': ai_keys_visible,
            'personal_keys_visible': personal_keys_visible,
            'location_keys_visible': location_keys_visible,
            'total_visible_keys': len(visible_keys),
            'ai_only_accuracy': 1.0 if personal_keys_visible == 0 else 0.0,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_ai_keys_visible = df['ai_keys_visible'].mean()
    avg_personal_keys_visible = df['personal_keys_visible'].mean()
    avg_location_keys_visible = df['location_keys_visible'].mean()
    ai_only_accuracy = df['ai_only_accuracy'].mean()
    
    results_summary = {
        'experiment': 'AI-Only Data Visibility Accuracy',
        'avg_ai_keys_visible': float(avg_ai_keys_visible),
        'avg_personal_keys_visible': float(avg_personal_keys_visible),
        'avg_location_keys_visible': float(avg_location_keys_visible),
        'ai_only_accuracy': float(ai_only_accuracy),
        'num_samples': len(results),
    }
    
    print(f"✅ Average AI Keys Visible: {avg_ai_keys_visible:.2f}")
    print(f"✅ Average Personal Keys Visible: {avg_personal_keys_visible:.2f} (should be 0)")
    print(f"✅ Average Location Keys Visible: {avg_location_keys_visible:.2f}")
    print(f"✅ AI-Only Accuracy: {ai_only_accuracy:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp3_ai_only_data_visibility.csv', index=False)
    with open(RESULTS_DIR / 'exp3_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_4_privacy_validation():
    """Experiment 4: Privacy Validation"""
    print("\n" + "="*70)
    print("Experiment 4: Privacy Validation")
    print("="*70)
    
    agents, communications, collective_intelligence = load_data()
    
    results = []
    
    # Test agents
    for agent in agents:
        filtered = admin_privacy_filter(agent)
        has_leak = check_personal_data_leak(filtered)
        results.append({
            'data_type': 'agent',
            'data_id': agent.get('user_id', 'unknown'),
            'has_personal_data_leak': has_leak,
        })
    
    # Test communications
    for comm in communications[:200]:  # Sample
        filtered = admin_privacy_filter(comm)
        has_leak = check_personal_data_leak(filtered)
        results.append({
            'data_type': 'communication',
            'data_id': comm.get('communication_id', 'unknown'),
            'has_personal_data_leak': has_leak,
        })
    
    # Test collective intelligence
    filtered_ci = admin_privacy_filter(collective_intelligence)
    has_leak_ci = check_personal_data_leak(filtered_ci)
    results.append({
        'data_type': 'collective_intelligence',
        'data_id': 'network_patterns',
        'has_personal_data_leak': has_leak_ci,
    })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    total_leaks = df['has_personal_data_leak'].sum()
    leak_rate = df['has_personal_data_leak'].mean()
    
    # Leak rate by data type
    leak_by_type = df.groupby('data_type')['has_personal_data_leak'].mean().to_dict()
    
    # Privacy validation score (1.0 = perfect, 0.0 = all leaked)
    privacy_score = 1.0 - leak_rate
    
    results_summary = {
        'experiment': 'Privacy Validation',
        'total_leaks': int(total_leaks),
        'leak_rate': float(leak_rate),
        'privacy_score': float(privacy_score),
        'leak_by_type': {k: float(v) for k, v in leak_by_type.items()},
        'num_samples': len(results),
    }
    
    print(f"✅ Total Leaks: {total_leaks}")
    print(f"✅ Leak Rate: {leak_rate:.4f} (should be 0.0)")
    print(f"✅ Privacy Score: {privacy_score:.4f} (1.0 = perfect)")
    for data_type, leak_rate_type in leak_by_type.items():
        print(f"   - {data_type}: {leak_rate_type:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp4_privacy_validation.csv', index=False)
    with open(RESULTS_DIR / 'exp4_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def main():
    """Run all experiments."""
    print(f"\n{'='*70}")
    print(f"Patent #{PATENT_NUMBER}: {PATENT_NAME} Experiments")
    print(f"{'='*70}\n")
    
    start_time = time.time()
    
    # Run experiments
    exp1_results = experiment_1_privacy_filter_accuracy()
    exp2_results = experiment_2_real_time_monitoring_latency()
    exp3_results = experiment_3_ai_only_data_visibility()
    exp4_results = experiment_4_privacy_validation()
    
    # Compile all results
    all_results = {
        'patent_number': PATENT_NUMBER,
        'patent_name': PATENT_NAME,
        'experiments': {
            'experiment_1': exp1_results,
            'experiment_2': exp2_results,
            'experiment_3': exp3_results,
            'experiment_4': exp4_results,
        },
        'execution_time_seconds': time.time() - start_time,
        'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
    }
    
    # Save combined results
    with open(RESULTS_DIR / 'all_experiments_results.json', 'w') as f:
        json.dump(all_results, f, indent=2)
    
    print(f"\n{'='*70}")
    print("✅ All experiments completed!")
    print(f"⏱️  Total execution time: {time.time() - start_time:.2f} seconds")
    print(f"📁 Results saved to: {RESULTS_DIR}")
    print(f"{'='*70}\n")
    
    return all_results


if __name__ == '__main__':
    main()

