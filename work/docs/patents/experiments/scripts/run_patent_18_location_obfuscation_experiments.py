#!/usr/bin/env python3
"""
Patent #18: Location Obfuscation System with Differential Privacy Noise Experiments

Runs all 4 required experiments:
1. City-Level Rounding Accuracy (P1)
2. Differential Privacy Noise Effectiveness (P1)
3. Home Location Protection Accuracy (P1)
4. Obfuscation Distance Analysis (P1)

Date: December 21, 2025
"""

import numpy as np
import pandas as pd
import json
from pathlib import Path
import time
from scipy.stats import pearsonr
from sklearn.metrics import mean_absolute_error, mean_squared_error, accuracy_score
from collections import defaultdict
import random
import warnings
warnings.filterwarnings('ignore')

# Configuration
PATENT_NUMBER = "18"
PATENT_NAME = "Location Obfuscation System with Differential Privacy Noise"
PATENT_FOLDER = "patent_18_location_obfuscation"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_SAMPLES = 1000
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)

# Constants from patent
CITY_LEVEL_PRECISION = 0.01  # degrees ≈ 1km
DIFF_PRIVACY_NOISE_LEVEL = 0.005  # degrees ≈ 500m
EXPIRATION_HOURS = 24


def generate_synthetic_data():
    """Generate synthetic location data for experiments."""
    print("Generating synthetic data...")
    
    # Generate 1000 exact locations (random coordinates)
    locations = []
    home_locations = {}  # Store home locations for some users
    
    for i in range(1000):
        # Generate random coordinates (simulating various locations)
        latitude = random.uniform(-90, 90)
        longitude = random.uniform(-180, 180)
        
        user_id = f'user_{i:04d}'
        
        # 10% of users have home locations
        if random.random() < 0.1:
            home_locations[user_id] = {
                'latitude': latitude,
                'longitude': longitude,
                'address': f'Home Address {i}',
            }
        
        location = {
            'user_id': user_id,
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': time.time() + i * 3600,  # 1 hour intervals
            'is_home': user_id in home_locations and 
                      abs(latitude - home_locations[user_id]['latitude']) < 0.001 and
                      abs(longitude - home_locations[user_id]['longitude']) < 0.001,
        }
        locations.append(location)
    
    # Calculate ground truth obfuscated locations
    ground_truth_obfuscated = []
    for location in locations:
        # City-level rounding
        rounded_lat = round(location['latitude'] / CITY_LEVEL_PRECISION) * CITY_LEVEL_PRECISION
        rounded_lng = round(location['longitude'] / CITY_LEVEL_PRECISION) * CITY_LEVEL_PRECISION
        
        # Expected distance from original (for validation)
        lat_distance_km = abs(location['latitude'] - rounded_lat) * 111.0  # degrees to km
        lng_distance_km = abs(location['longitude'] - rounded_lng) * 111.0 * np.cos(np.radians(location['latitude']))
        total_distance_km = np.sqrt(lat_distance_km**2 + lng_distance_km**2)
        
        ground_truth_obfuscated.append({
            'user_id': location['user_id'],
            'original_lat': location['latitude'],
            'original_lng': location['longitude'],
            'rounded_lat': rounded_lat,
            'rounded_lng': rounded_lng,
            'expected_distance_km': float(total_distance_km),
            'is_home': location['is_home'],
        })
    
    # Save data
    with open(DATA_DIR / 'synthetic_locations.json', 'w') as f:
        json.dump(locations, f, indent=2, default=str)
    
    with open(DATA_DIR / 'home_locations.json', 'w') as f:
        json.dump(home_locations, f, indent=2, default=str)
    
    with open(DATA_DIR / 'ground_truth_obfuscated.json', 'w') as f:
        json.dump(ground_truth_obfuscated, f, indent=2, default=str)
    
    print(f"✅ Generated {len(locations)} locations, {len(home_locations)} home locations")
    return locations, home_locations, ground_truth_obfuscated


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_locations.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_locations.json', 'r') as f:
        locations = json.load(f)
    
    with open(DATA_DIR / 'home_locations.json', 'r') as f:
        home_locations = json.load(f)
    
    with open(DATA_DIR / 'ground_truth_obfuscated.json', 'r') as f:
        ground_truth_obfuscated = json.load(f)
    
    return locations, home_locations, ground_truth_obfuscated


def round_to_city_center(coordinate):
    """Simulate city-level precision rounding."""
    return round(coordinate / CITY_LEVEL_PRECISION) * CITY_LEVEL_PRECISION


def add_differential_privacy_noise(coordinate):
    """Simulate differential privacy noise addition."""
    noise = (random.random() - 0.5) * 2 * DIFF_PRIVACY_NOISE_LEVEL
    return coordinate + noise


def obfuscate_location(latitude, longitude, user_id, home_locations, is_admin=False):
    """Simulate complete location obfuscation process."""
    # Check admin override
    if is_admin:
        return {
            'obfuscated_lat': latitude,
            'obfuscated_lng': longitude,
            'is_exact': True,
            'is_blocked': False,
        }
    
    # Check home location
    if user_id in home_locations:
        home = home_locations[user_id]
        # Check if location matches home (within 0.001 degrees ≈ 100m)
        if (abs(latitude - home['latitude']) < 0.001 and 
            abs(longitude - home['longitude']) < 0.001):
            return {
                'obfuscated_lat': None,
                'obfuscated_lng': None,
                'is_exact': False,
                'is_blocked': True,
            }
    
    # Apply city-level rounding
    rounded_lat = round_to_city_center(latitude)
    rounded_lng = round_to_city_center(longitude)
    
    # Add differential privacy noise
    obfuscated_lat = add_differential_privacy_noise(rounded_lat)
    obfuscated_lng = add_differential_privacy_noise(rounded_lng)
    
    return {
        'obfuscated_lat': obfuscated_lat,
        'obfuscated_lng': obfuscated_lng,
        'is_exact': False,
        'is_blocked': False,
    }


def calculate_distance_km(lat1, lng1, lat2, lng2):
    """Calculate distance between two coordinates in kilometers (Haversine formula)."""
    R = 6371.0  # Earth radius in km
    
    lat1_rad = np.radians(lat1)
    lat2_rad = np.radians(lat2)
    dlat = np.radians(lat2 - lat1)
    dlng = np.radians(lng2 - lng1)
    
    a = np.sin(dlat/2)**2 + np.cos(lat1_rad) * np.cos(lat2_rad) * np.sin(dlng/2)**2
    c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1-a))
    
    return R * c


# ============================================================================
# EXPERIMENTS
# ============================================================================

def experiment_1_city_level_rounding():
    """Experiment 1: City-Level Rounding Accuracy"""
    print("\n" + "="*70)
    print("Experiment 1: City-Level Rounding Accuracy")
    print("="*70)
    
    locations, _, ground_truth = load_data()
    
    results = []
    for location, gt in zip(locations, ground_truth):
        # Apply rounding
        rounded_lat = round_to_city_center(location['latitude'])
        rounded_lng = round_to_city_center(location['longitude'])
        
        # Calculate distance from original
        distance_km = calculate_distance_km(
            location['latitude'], location['longitude'],
            rounded_lat, rounded_lng
        )
        
        results.append({
            'user_id': location['user_id'],
            'original_lat': location['latitude'],
            'original_lng': location['longitude'],
            'rounded_lat': rounded_lat,
            'rounded_lng': rounded_lng,
            'distance_km': distance_km,
            'expected_distance_km': gt['expected_distance_km'],
            'rounding_error': abs(distance_km - gt['expected_distance_km']),
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_distance = df['distance_km'].mean()
    max_distance = df['distance_km'].max()
    p95_distance = df['distance_km'].quantile(0.95)
    
    # Check if rounding is correct (should match ground truth)
    rounding_accuracy = (df['rounding_error'] < 0.01).mean()  # Within 10m
    
    results_summary = {
        'experiment': 'City-Level Rounding Accuracy',
        'avg_distance_km': float(avg_distance),
        'max_distance_km': float(max_distance),
        'p95_distance_km': float(p95_distance),
        'rounding_accuracy': float(rounding_accuracy),
        'target_precision_km': 1.0,  # City-level ≈ 1km
        'num_samples': len(results),
    }
    
    print(f"✅ Average Distance: {avg_distance:.4f} km")
    print(f"✅ Max Distance: {max_distance:.4f} km")
    print(f"✅ P95 Distance: {p95_distance:.4f} km")
    print(f"✅ Rounding Accuracy: {rounding_accuracy:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp1_city_level_rounding.csv', index=False)
    with open(RESULTS_DIR / 'exp1_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_2_differential_privacy_noise():
    """Experiment 2: Differential Privacy Noise Effectiveness"""
    print("\n" + "="*70)
    print("Experiment 2: Differential Privacy Noise Effectiveness")
    print("="*70)
    
    locations, home_locations, _ = load_data()
    
    results = []
    for location in locations[:500]:  # Sample for efficiency
        # Apply obfuscation with noise
        obfuscated = obfuscate_location(
            location['latitude'],
            location['longitude'],
            location['user_id'],
            home_locations,
            is_admin=False
        )
        
        if obfuscated['obfuscated_lat'] is not None:
            # Calculate distance from original
            distance_km = calculate_distance_km(
                location['latitude'], location['longitude'],
                obfuscated['obfuscated_lat'], obfuscated['obfuscated_lng']
            )
            
            # Calculate noise contribution
            rounded_lat = round_to_city_center(location['latitude'])
            rounded_lng = round_to_city_center(location['longitude'])
            rounding_distance = calculate_distance_km(
                location['latitude'], location['longitude'],
                rounded_lat, rounded_lng
            )
            noise_distance = distance_km - rounding_distance
            
            results.append({
                'user_id': location['user_id'],
                'total_distance_km': distance_km,
                'rounding_distance_km': rounding_distance,
                'noise_distance_km': abs(noise_distance),
                'expected_noise_km': 0.5,  # ~500m
            })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_total_distance = df['total_distance_km'].mean()
    avg_noise_distance = df['noise_distance_km'].mean()
    max_noise_distance = df['noise_distance_km'].max()
    
    # Check if noise is within expected range (±500m)
    noise_within_range = ((df['noise_distance_km'] <= 0.6) & (df['noise_distance_km'] >= 0)).mean()
    
    results_summary = {
        'experiment': 'Differential Privacy Noise Effectiveness',
        'avg_total_distance_km': float(avg_total_distance),
        'avg_noise_distance_km': float(avg_noise_distance),
        'max_noise_distance_km': float(max_noise_distance),
        'noise_within_range': float(noise_within_range),
        'expected_noise_km': 0.5,
        'num_samples': len(results),
    }
    
    print(f"✅ Average Total Distance: {avg_total_distance:.4f} km")
    print(f"✅ Average Noise Distance: {avg_noise_distance:.4f} km")
    print(f"✅ Max Noise Distance: {max_noise_distance:.4f} km")
    print(f"✅ Noise Within Range: {noise_within_range:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp2_differential_privacy_noise.csv', index=False)
    with open(RESULTS_DIR / 'exp2_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_3_home_location_protection():
    """Experiment 3: Home Location Protection Accuracy"""
    print("\n" + "="*70)
    print("Experiment 3: Home Location Protection Accuracy")
    print("="*70)
    
    locations, home_locations, _ = load_data()
    
    results = []
    for location in locations:
        # Check if this is a home location
        is_home = location['is_home']
        
        # Try to obfuscate
        obfuscated = obfuscate_location(
            location['latitude'],
            location['longitude'],
            location['user_id'],
            home_locations,
            is_admin=False
        )
        
        # Check if blocking worked correctly
        is_blocked = obfuscated['is_blocked']
        correctly_blocked = (is_home and is_blocked) or (not is_home and not is_blocked)
        
        results.append({
            'user_id': location['user_id'],
            'is_home': is_home,
            'is_blocked': is_blocked,
            'correctly_blocked': correctly_blocked,
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    home_locations_count = df['is_home'].sum()
    blocked_count = df['is_blocked'].sum()
    protection_accuracy = df['correctly_blocked'].mean()
    
    # True positive rate (home locations that were blocked)
    true_positives = ((df['is_home']) & (df['is_blocked'])).sum()
    false_negatives = ((df['is_home']) & (~df['is_blocked'])).sum()
    recall = true_positives / (true_positives + false_negatives) if (true_positives + false_negatives) > 0 else 0.0
    
    # False positive rate (non-home locations that were blocked)
    false_positives = ((~df['is_home']) & (df['is_blocked'])).sum()
    true_negatives = ((~df['is_home']) & (~df['is_blocked'])).sum()
    false_positive_rate = false_positives / (false_positives + true_negatives) if (false_positives + true_negatives) > 0 else 0.0
    
    results_summary = {
        'experiment': 'Home Location Protection Accuracy',
        'home_locations_count': int(home_locations_count),
        'blocked_count': int(blocked_count),
        'protection_accuracy': float(protection_accuracy),
        'recall': float(recall),
        'false_positive_rate': float(false_positive_rate),
        'num_samples': len(results),
    }
    
    print(f"✅ Home Locations: {home_locations_count}")
    print(f"✅ Blocked Locations: {blocked_count}")
    print(f"✅ Protection Accuracy: {protection_accuracy:.4f}")
    print(f"✅ Recall (Home Detection): {recall:.4f}")
    print(f"✅ False Positive Rate: {false_positive_rate:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp3_home_location_protection.csv', index=False)
    with open(RESULTS_DIR / 'exp3_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_4_obfuscation_distance_analysis():
    """Experiment 4: Obfuscation Distance Analysis"""
    print("\n" + "="*70)
    print("Experiment 4: Obfuscation Distance Analysis")
    print("="*70)
    
    locations, home_locations, _ = load_data()
    
    results = []
    for location in locations[:500]:  # Sample for efficiency
        # Skip home locations
        if location['is_home']:
            continue
        
        # Apply obfuscation
        obfuscated = obfuscate_location(
            location['latitude'],
            location['longitude'],
            location['user_id'],
            home_locations,
            is_admin=False
        )
        
        if obfuscated['obfuscated_lat'] is not None:
            # Calculate distances
            total_distance = calculate_distance_km(
                location['latitude'], location['longitude'],
                obfuscated['obfuscated_lat'], obfuscated['obfuscated_lng']
            )
            
            # Calculate rounding distance
            rounded_lat = round_to_city_center(location['latitude'])
            rounded_lng = round_to_city_center(location['longitude'])
            rounding_distance = calculate_distance_km(
                location['latitude'], location['longitude'],
                rounded_lat, rounded_lng
            )
            
            # Calculate noise distance
            noise_distance = calculate_distance_km(
                rounded_lat, rounded_lng,
                obfuscated['obfuscated_lat'], obfuscated['obfuscated_lng']
            )
            
            results.append({
                'user_id': location['user_id'],
                'total_obfuscation_km': total_distance,
                'rounding_component_km': rounding_distance,
                'noise_component_km': noise_distance,
                'expected_total_km': 1.5,  # ~1km rounding + ~0.5km noise
            })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_total = df['total_obfuscation_km'].mean()
    avg_rounding = df['rounding_component_km'].mean()
    avg_noise = df['noise_component_km'].mean()
    
    # Check if total obfuscation is within expected range (~1.5km)
    within_expected_range = ((df['total_obfuscation_km'] >= 0.5) & (df['total_obfuscation_km'] <= 2.0)).mean()
    
    results_summary = {
        'experiment': 'Obfuscation Distance Analysis',
        'avg_total_obfuscation_km': float(avg_total),
        'avg_rounding_component_km': float(avg_rounding),
        'avg_noise_component_km': float(avg_noise),
        'within_expected_range': float(within_expected_range),
        'expected_total_km': 1.5,
        'num_samples': len(results),
    }
    
    print(f"✅ Average Total Obfuscation: {avg_total:.4f} km")
    print(f"✅ Average Rounding Component: {avg_rounding:.4f} km")
    print(f"✅ Average Noise Component: {avg_noise:.4f} km")
    print(f"✅ Within Expected Range: {within_expected_range:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp4_obfuscation_distance.csv', index=False)
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
    exp1_results = experiment_1_city_level_rounding()
    exp2_results = experiment_2_differential_privacy_noise()
    exp3_results = experiment_3_home_location_protection()
    exp4_results = experiment_4_obfuscation_distance_analysis()
    
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

