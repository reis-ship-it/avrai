#!/usr/bin/env python3
"""
Patent #7: Real-Time Trend Detection with Privacy Preservation Experiments

Runs all 4 required experiments:
1. Real-Time Stream Processing Latency (P1)
2. Privacy-Preserving Aggregation Accuracy (P1)
3. Trend Prediction Accuracy (P1)
4. Multi-Source Fusion Effectiveness (P1)

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
PATENT_NUMBER = "7"
PATENT_NAME = "Real-Time Trend Detection with Privacy Preservation"
PATENT_FOLDER = "patent_7_real_time_trend_detection"

DATA_DIR = Path(__file__).parent.parent / 'data' / PATENT_FOLDER
RESULTS_DIR = Path(__file__).parent.parent / 'results' / f'patent_{PATENT_NUMBER}'
DATA_DIR.mkdir(parents=True, exist_ok=True)
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

NUM_SAMPLES = 1000
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)


def generate_synthetic_data():
    """Generate synthetic trend data for experiments."""
    print("Generating synthetic data...")
    
    # Generate time series data for different categories
    categories = ['technology', 'science', 'art', 'philosophy', 'business', 'health', 'education', 'sports']
    num_time_points = 1000
    timestamps = [time.time() + i * 3600 for i in range(num_time_points)]  # 1 hour intervals
    
    # Generate trend data for each category
    trend_data = []
    for category in categories:
        # Create a trend with some growth/decline
        base_activity = random.uniform(10, 100)
        growth_rate = random.uniform(-0.1, 0.3)  # Some categories grow, some decline
        noise = np.random.normal(0, 5, num_time_points)
        
        for i, timestamp in enumerate(timestamps):
            activity = base_activity * (1 + growth_rate * i / num_time_points) + noise[i]
            activity = max(0, activity)  # No negative activity
            
            trend_data.append({
                'timestamp': timestamp,
                'category': category,
                'activity_level': float(activity),
                'user_count': int(activity * random.uniform(0.5, 2.0)),
                'event_count': int(activity * random.uniform(0.1, 0.5)),
            })
    
    # Generate multi-source trends
    ai_network_trends = []
    community_trends = []
    temporal_trends = []
    location_trends = []
    
    for i, data_point in enumerate(trend_data[:500]):  # Sample for efficiency
        # AI Network trends (30% weight)
        ai_network_trends.append({
            'timestamp': data_point['timestamp'],
            'category': data_point['category'],
            'trend_score': data_point['activity_level'] * random.uniform(0.8, 1.2),
            'connection_rate': random.uniform(0.1, 0.5),
        })
        
        # Community trends (40% weight)
        community_trends.append({
            'timestamp': data_point['timestamp'],
            'category': data_point['category'],
            'trend_score': data_point['activity_level'] * random.uniform(0.9, 1.1),
            'engagement_rate': random.uniform(0.2, 0.8),
        })
        
        # Temporal trends (20% weight)
        hour_of_day = (i % 24)
        temporal_trends.append({
            'timestamp': data_point['timestamp'],
            'category': data_point['category'],
            'trend_score': data_point['activity_level'] * (1 + 0.1 * np.sin(hour_of_day / 24 * 2 * np.pi)),
            'time_pattern': hour_of_day,
        })
        
        # Location trends (10% weight)
        location_trends.append({
            'timestamp': data_point['timestamp'],
            'category': data_point['category'],
            'trend_score': data_point['activity_level'] * random.uniform(0.7, 1.3),
            'location_diversity': random.uniform(0.3, 1.0),
        })
    
    # Calculate ground truth trends (for validation)
    ground_truth_trends = {}
    for category in categories:
        category_data = [d for d in trend_data if d['category'] == category]
        if len(category_data) > 10:
            # Calculate growth rate
            early_activity = np.mean([d['activity_level'] for d in category_data[:100]])
            late_activity = np.mean([d['activity_level'] for d in category_data[-100:]])
            growth_rate = (late_activity - early_activity) / early_activity if early_activity > 0 else 0
            
            # Calculate acceleration
            mid_activity = np.mean([d['activity_level'] for d in category_data[400:600]])
            acceleration = ((late_activity - mid_activity) - (mid_activity - early_activity)) / early_activity if early_activity > 0 else 0
            
            ground_truth_trends[category] = {
                'growth_rate': float(growth_rate),
                'acceleration': float(acceleration),
                'is_emerging': growth_rate > 0.2 and acceleration > 0.1,
                'avg_activity': float(np.mean([d['activity_level'] for d in category_data])),
            }
    
    # Save data
    with open(DATA_DIR / 'synthetic_trend_data.json', 'w') as f:
        json.dump(trend_data, f, indent=2, default=str)
    
    with open(DATA_DIR / 'ai_network_trends.json', 'w') as f:
        json.dump(ai_network_trends, f, indent=2, default=str)
    
    with open(DATA_DIR / 'community_trends.json', 'w') as f:
        json.dump(community_trends, f, indent=2, default=str)
    
    with open(DATA_DIR / 'temporal_trends.json', 'w') as f:
        json.dump(temporal_trends, f, indent=2, default=str)
    
    with open(DATA_DIR / 'location_trends.json', 'w') as f:
        json.dump(location_trends, f, indent=2, default=str)
    
    with open(DATA_DIR / 'ground_truth_trends.json', 'w') as f:
        json.dump(ground_truth_trends, f, indent=2, default=str)
    
    print(f"✅ Generated {len(trend_data)} trend data points, multi-source trends, and ground truth")
    return trend_data, ai_network_trends, community_trends, temporal_trends, location_trends, ground_truth_trends


def load_data():
    """Load synthetic data."""
    if not (DATA_DIR / 'synthetic_trend_data.json').exists():
        return generate_synthetic_data()
    
    with open(DATA_DIR / 'synthetic_trend_data.json', 'r') as f:
        trend_data = json.load(f)
    
    with open(DATA_DIR / 'ai_network_trends.json', 'r') as f:
        ai_network_trends = json.load(f)
    
    with open(DATA_DIR / 'community_trends.json', 'r') as f:
        community_trends = json.load(f)
    
    with open(DATA_DIR / 'temporal_trends.json', 'r') as f:
        temporal_trends = json.load(f)
    
    with open(DATA_DIR / 'location_trends.json', 'r') as f:
        location_trends = json.load(f)
    
    with open(DATA_DIR / 'ground_truth_trends.json', 'r') as f:
        ground_truth_trends = json.load(f)
    
    return trend_data, ai_network_trends, community_trends, temporal_trends, location_trends, ground_truth_trends


def process_trend_data_stream(data_point, apply_privacy=True):
    """Simulate real-time stream processing with privacy preservation."""
    start_time = time.time()
    
    # Anonymize data immediately
    anonymized = {
        'category': data_point['category'],
        'activity_level': data_point['activity_level'],
        'timestamp': data_point['timestamp'],
    }
    
    # Apply differential privacy if enabled
    if apply_privacy:
        epsilon = 1.0
        noise_scale = 1.0 / epsilon
        noise = np.random.laplace(0, noise_scale)
        anonymized['activity_level'] = max(0, anonymized['activity_level'] + noise * 5)
    
    # Extract aggregate patterns only
    patterns = {
        'category': anonymized['category'],
        'aggregate_activity': anonymized['activity_level'],
        'sample_size': 1,  # In real system, this would be aggregate count
    }
    
    # Calculate trend metrics
    trend = {
        'category': patterns['category'],
        'trend_score': patterns['aggregate_activity'],
        'confidence': 0.5 + random.uniform(0, 0.5),  # Simplified confidence
    }
    
    processing_time = (time.time() - start_time) * 1000  # Convert to milliseconds
    
    return {
        'trend': trend,
        'processing_time_ms': processing_time,
        'latency_meets_target': processing_time < 1000,  # Sub-second target
    }


def privacy_preserving_aggregation(data_points, epsilon=1.0):
    """Simulate privacy-preserving aggregation."""
    if not data_points:
        return {}
    
    # Calculate true aggregate
    true_avg = np.mean([d['activity_level'] for d in data_points])
    true_sum = np.sum([d['activity_level'] for d in data_points])
    true_count = len(data_points)
    
    # Apply Laplace noise for differential privacy
    noise_scale = 1.0 / epsilon
    noise_avg = np.random.laplace(0, noise_scale)
    noise_sum = np.random.laplace(0, noise_scale * true_count)
    
    # Private aggregates
    private_avg = true_avg + noise_avg * 5  # Scale noise
    private_sum = true_sum + noise_sum
    private_count = true_count  # Count typically not private
    
    # Calculate privacy loss
    privacy_loss = abs(private_avg - true_avg)
    
    return {
        'true_avg': float(true_avg),
        'private_avg': float(private_avg),
        'privacy_loss': float(privacy_loss),
        'privacy_budget_used': epsilon,
    }


def predict_trends(current_patterns, history_patterns):
    """Simulate trend prediction algorithm."""
    if not current_patterns or not history_patterns:
        return {}
    
    # Analyze growth patterns
    current_avg = np.mean([p['activity_level'] for p in current_patterns])
    history_avg = np.mean([p['activity_level'] for p in history_patterns])
    
    growth_rate = (current_avg - history_avg) / history_avg if history_avg > 0 else 0
    
    # Calculate acceleration (simplified)
    if len(history_patterns) > 100:
        early_avg = np.mean([p['activity_level'] for p in history_patterns[:50]])
        mid_avg = np.mean([p['activity_level'] for p in history_patterns[50:100]])
        late_avg = current_avg
        
        acceleration = ((late_avg - mid_avg) - (mid_avg - early_avg)) / early_avg if early_avg > 0 else 0
    else:
        acceleration = 0
    
    # Predict emerging categories
    is_emerging = growth_rate > 0.2 and acceleration > 0.1
    
    # Forecast confidence
    confidence = min(1.0, abs(growth_rate) * 2 + abs(acceleration) * 5)
    
    return {
        'growth_rate': float(growth_rate),
        'acceleration': float(acceleration),
        'is_emerging': is_emerging,
        'confidence': float(confidence),
        'forecasted_activity': float(current_avg * (1 + growth_rate)),
    }


def multi_source_fusion(ai_trends, community_trends, temporal_trends, location_trends):
    """Simulate multi-source trend fusion."""
    # Weight distribution: AI 30%, Community 40%, Temporal 20%, Location 10%
    weights = {
        'ai': 0.3,
        'community': 0.4,
        'temporal': 0.2,
        'location': 0.1,
    }
    
    # Combine trends by category
    categories = set()
    if ai_trends:
        categories.update([t['category'] for t in ai_trends])
    if community_trends:
        categories.update([t['category'] for t in community_trends])
    
    fused_trends = {}
    for category in categories:
        # Get trends for this category from each source
        ai_scores = [t['trend_score'] for t in ai_trends if t['category'] == category]
        community_scores = [t['trend_score'] for t in community_trends if t['category'] == category]
        temporal_scores = [t['trend_score'] for t in temporal_trends if t['category'] == category]
        location_scores = [t['trend_score'] for t in location_trends if t['category'] == category]
        
        # Weighted combination
        fused_score = (
            (np.mean(ai_scores) if ai_scores else 0) * weights['ai'] +
            (np.mean(community_scores) if community_scores else 0) * weights['community'] +
            (np.mean(temporal_scores) if temporal_scores else 0) * weights['temporal'] +
            (np.mean(location_scores) if location_scores else 0) * weights['location']
        )
        
        fused_trends[category] = {
            'fused_score': float(fused_score),
            'ai_contribution': float((np.mean(ai_scores) if ai_scores else 0) * weights['ai']),
            'community_contribution': float((np.mean(community_scores) if community_scores else 0) * weights['community']),
            'temporal_contribution': float((np.mean(temporal_scores) if temporal_scores else 0) * weights['temporal']),
            'location_contribution': float((np.mean(location_scores) if location_scores else 0) * weights['location']),
        }
    
    return fused_trends


# ============================================================================
# EXPERIMENTS
# ============================================================================

def experiment_1_stream_processing_latency():
    """Experiment 1: Real-Time Stream Processing Latency"""
    print("\n" + "="*70)
    print("Experiment 1: Real-Time Stream Processing Latency")
    print("="*70)
    
    trend_data, _, _, _, _, _ = load_data()
    
    results = []
    for data_point in trend_data[:500]:  # Sample for efficiency
        result = process_trend_data_stream(data_point, apply_privacy=True)
        results.append({
            'category': data_point['category'],
            'processing_time_ms': result['processing_time_ms'],
            'latency_meets_target': result['latency_meets_target'],
            'trend_score': result['trend']['trend_score'],
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_latency = df['processing_time_ms'].mean()
    max_latency = df['processing_time_ms'].max()
    p95_latency = df['processing_time_ms'].quantile(0.95)
    p99_latency = df['processing_time_ms'].quantile(0.99)
    meets_target_rate = df['latency_meets_target'].mean()
    
    results_summary = {
        'experiment': 'Real-Time Stream Processing Latency',
        'avg_latency_ms': float(avg_latency),
        'max_latency_ms': float(max_latency),
        'p95_latency_ms': float(p95_latency),
        'p99_latency_ms': float(p99_latency),
        'meets_target_rate': float(meets_target_rate),
        'target_latency_ms': 1000.0,
        'num_samples': len(results),
    }
    
    print(f"✅ Average Latency: {avg_latency:.2f} ms")
    print(f"✅ Max Latency: {max_latency:.2f} ms")
    print(f"✅ P95 Latency: {p95_latency:.2f} ms")
    print(f"✅ Meets Target Rate: {meets_target_rate:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp1_stream_processing_latency.csv', index=False)
    with open(RESULTS_DIR / 'exp1_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_2_privacy_aggregation_accuracy():
    """Experiment 2: Privacy-Preserving Aggregation Accuracy"""
    print("\n" + "="*70)
    print("Experiment 2: Privacy-Preserving Aggregation Accuracy")
    print("="*70)
    
    trend_data, _, _, _, _, _ = load_data()
    
    # Test with different privacy budgets
    privacy_budgets = [0.5, 1.0, 2.0, 5.0]
    results = []
    
    # Group by category
    categories = set([d['category'] for d in trend_data])
    
    for category in categories:
        category_data = [d for d in trend_data if d['category'] == category]
        
        for epsilon in privacy_budgets:
            aggregation_result = privacy_preserving_aggregation(category_data[:100], epsilon=epsilon)
            
            results.append({
                'category': category,
                'epsilon': epsilon,
                'true_avg': aggregation_result['true_avg'],
                'private_avg': aggregation_result['private_avg'],
                'privacy_loss': aggregation_result['privacy_loss'],
            })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    avg_privacy_loss = df['privacy_loss'].mean()
    max_privacy_loss = df['privacy_loss'].max()
    
    # Correlation between true and private averages
    correlation, p_value = pearsonr(df['true_avg'], df['private_avg'])
    
    results_summary = {
        'experiment': 'Privacy-Preserving Aggregation Accuracy',
        'avg_privacy_loss': float(avg_privacy_loss),
        'max_privacy_loss': float(max_privacy_loss),
        'correlation': float(correlation) if not np.isnan(correlation) else 0.0,
        'p_value': float(p_value) if not np.isnan(p_value) else 1.0,
        'num_privacy_budgets_tested': len(privacy_budgets),
        'num_categories': len(categories),
    }
    
    print(f"✅ Average Privacy Loss: {avg_privacy_loss:.6f}")
    print(f"✅ Max Privacy Loss: {max_privacy_loss:.6f}")
    print(f"✅ Correlation: {correlation:.4f}" if not np.isnan(correlation) else "✅ Correlation: N/A")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp2_privacy_aggregation.csv', index=False)
    with open(RESULTS_DIR / 'exp2_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_3_trend_prediction_accuracy():
    """Experiment 3: Trend Prediction Accuracy"""
    print("\n" + "="*70)
    print("Experiment 3: Trend Prediction Accuracy")
    print("="*70)
    
    trend_data, _, _, _, _, ground_truth_trends = load_data()
    
    results = []
    for category, gt_trend in ground_truth_trends.items():
        category_data = [d for d in trend_data if d['category'] == category]
        
        if len(category_data) > 100:
            # Split into current and history
            current_patterns = category_data[-50:]
            history_patterns = category_data[:-50]
            
            # Predict trends
            prediction = predict_trends(current_patterns, history_patterns)
            
            results.append({
                'category': category,
                'predicted_growth_rate': prediction['growth_rate'],
                'ground_truth_growth_rate': gt_trend['growth_rate'],
                'predicted_acceleration': prediction['acceleration'],
                'ground_truth_acceleration': gt_trend['acceleration'],
                'predicted_emerging': prediction['is_emerging'],
                'ground_truth_emerging': gt_trend['is_emerging'],
                'confidence': prediction['confidence'],
            })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    growth_mae = mean_absolute_error(df['ground_truth_growth_rate'], df['predicted_growth_rate'])
    acceleration_mae = mean_absolute_error(df['ground_truth_acceleration'], df['predicted_acceleration'])
    
    growth_correlation, _ = pearsonr(df['ground_truth_growth_rate'], df['predicted_growth_rate'])
    acceleration_correlation, _ = pearsonr(df['ground_truth_acceleration'], df['predicted_acceleration'])
    
    # Emerging category prediction accuracy
    # Convert boolean strings to actual booleans, then to int
    df['ground_truth_emerging'] = df['ground_truth_emerging'].apply(lambda x: bool(x) if isinstance(x, str) else x)
    df['predicted_emerging'] = df['predicted_emerging'].apply(lambda x: bool(x) if isinstance(x, str) else x)
    emerging_accuracy = accuracy_score(
        df['ground_truth_emerging'].astype(int),
        df['predicted_emerging'].astype(int)
    )
    
    results_summary = {
        'experiment': 'Trend Prediction Accuracy',
        'growth_rate_mae': float(growth_mae),
        'acceleration_mae': float(acceleration_mae),
        'growth_rate_correlation': float(growth_correlation),
        'acceleration_correlation': float(acceleration_correlation),
        'emerging_prediction_accuracy': float(emerging_accuracy),
        'num_categories': len(results),
    }
    
    print(f"✅ Growth Rate MAE: {growth_mae:.4f}")
    print(f"✅ Acceleration MAE: {acceleration_mae:.4f}")
    print(f"✅ Growth Rate Correlation: {growth_correlation:.4f}")
    print(f"✅ Emerging Prediction Accuracy: {emerging_accuracy:.4f}")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp3_trend_prediction.csv', index=False)
    with open(RESULTS_DIR / 'exp3_results.json', 'w') as f:
        json.dump(results_summary, f, indent=2)
    
    return results_summary


def experiment_4_multi_source_fusion():
    """Experiment 4: Multi-Source Fusion Effectiveness"""
    print("\n" + "="*70)
    print("Experiment 4: Multi-Source Fusion Effectiveness")
    print("="*70)
    
    _, ai_network_trends, community_trends, temporal_trends, location_trends, ground_truth_trends = load_data()
    
    # Fuse trends from all sources
    fused_trends = multi_source_fusion(ai_network_trends, community_trends, temporal_trends, location_trends)
    
    results = []
    for category, fused in fused_trends.items():
        # Get ground truth activity for comparison
        gt_activity = ground_truth_trends.get(category, {}).get('avg_activity', 0)
        
        # Normalize fused score for comparison (simplified)
        normalized_fused = fused['fused_score'] / 100.0 if fused['fused_score'] > 0 else 0
        
        results.append({
            'category': category,
            'fused_score': fused['fused_score'],
            'normalized_fused': normalized_fused,
            'ground_truth_activity': gt_activity,
            'ai_contribution': fused['ai_contribution'],
            'community_contribution': fused['community_contribution'],
            'temporal_contribution': fused['temporal_contribution'],
            'location_contribution': fused['location_contribution'],
            'total_contribution': (
                fused['ai_contribution'] + fused['community_contribution'] +
                fused['temporal_contribution'] + fused['location_contribution']
            ),
        })
    
    df = pd.DataFrame(results)
    
    # Calculate metrics
    # Check if weights are correct (AI 30%, Community 40%, Temporal 20%, Location 10%)
    avg_ai_weight = (df['ai_contribution'] / df['total_contribution']).mean()
    avg_community_weight = (df['community_contribution'] / df['total_contribution']).mean()
    avg_temporal_weight = (df['temporal_contribution'] / df['total_contribution']).mean()
    avg_location_weight = (df['location_contribution'] / df['total_contribution']).mean()
    
    # Correlation with ground truth
    if len(df) > 1 and df['ground_truth_activity'].sum() > 0:
        try:
            correlation, p_value = pearsonr(df['normalized_fused'], df['ground_truth_activity'])
        except ValueError:
            correlation, p_value = 0.0, 1.0
    else:
        correlation, p_value = 0.0, 1.0
    
    results_summary = {
        'experiment': 'Multi-Source Fusion Effectiveness',
        'avg_ai_weight': float(avg_ai_weight),
        'avg_community_weight': float(avg_community_weight),
        'avg_temporal_weight': float(avg_temporal_weight),
        'avg_location_weight': float(avg_location_weight),
        'expected_ai_weight': 0.3,
        'expected_community_weight': 0.4,
        'expected_temporal_weight': 0.2,
        'expected_location_weight': 0.1,
        'correlation_with_ground_truth': float(correlation) if not np.isnan(correlation) else 0.0,
        'num_categories': len(results),
    }
    
    print(f"✅ AI Weight: {avg_ai_weight:.4f} (expected: 0.30)")
    print(f"✅ Community Weight: {avg_community_weight:.4f} (expected: 0.40)")
    print(f"✅ Temporal Weight: {avg_temporal_weight:.4f} (expected: 0.20)")
    print(f"✅ Location Weight: {avg_location_weight:.4f} (expected: 0.10)")
    print(f"✅ Correlation with Ground Truth: {correlation:.4f}" if not np.isnan(correlation) else "✅ Correlation: N/A")
    
    # Save results
    df.to_csv(RESULTS_DIR / 'exp4_multi_source_fusion.csv', index=False)
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
    exp1_results = experiment_1_stream_processing_latency()
    exp2_results = experiment_2_privacy_aggregation_accuracy()
    exp3_results = experiment_3_trend_prediction_accuracy()
    exp4_results = experiment_4_multi_source_fusion()
    
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

