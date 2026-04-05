#!/usr/bin/env python3
"""
Base Class for Atomic Timing Experiments

Provides common functionality for all atomic timing A/B experiments.
Follows the same framework pattern as other marketing experiments.

Date: December 23, 2025
"""

import numpy as np
import pandas as pd
import json
import time
import random
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from datetime import datetime, timezone
from collections import defaultdict
import warnings
from scipy import stats
warnings.filterwarnings('ignore')

# Configuration
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)
random.seed(RANDOM_SEED)


class AtomicTimingExperimentBase:
    """Base class for atomic timing experiments"""
    
    def __init__(self, experiment_name: str, num_pairs: int = 1000, num_nodes: int = 10, random_seed: int = 42):
        self.experiment_name = experiment_name
        self.num_pairs = num_pairs
        self.num_nodes = num_nodes
        self.random_seed = random_seed
        np.random.seed(random_seed)
        random.seed(random_seed)
        
        # Set up results directory
        self.results_dir = Path(__file__).parent / 'results' / 'atomic_timing' / experiment_name
        self.results_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_test_data(self) -> Tuple[List[Dict], List[Dict]]:
        """Generate test data pairs for control and test groups"""
        # Same data for both groups (fair comparison)
        control_pairs = []
        test_pairs = []
        
        for i in range(self.num_pairs):
            # Generate random timestamps (same for both groups)
            base_time = time.time() + random.uniform(-86400 * 365, 86400 * 365)  # ±1 year
            
            # Control: Standard timestamps (UTC, millisecond precision)
            control_timestamp_a = datetime.fromtimestamp(base_time, tz=timezone.utc)
            control_timestamp_b = datetime.fromtimestamp(
                base_time + random.uniform(-3600, 3600),  # ±1 hour variation
                tz=timezone.utc
            )
            
            # Test: Atomic timestamps (same base time, but with atomic precision)
            # For simulation, we'll use the same time but track as "atomic"
            test_timestamp_a = {
                'server_time': base_time,
                'device_time': base_time + random.uniform(-0.001, 0.001),  # Small device offset
                'offset': random.uniform(-0.001, 0.001),
                'precision': 'millisecond',
                'local_time': datetime.fromtimestamp(base_time),
                'timezone_id': random.choice(['America/Los_Angeles', 'America/New_York', 'Europe/London', 'Asia/Tokyo'])
            }
            test_timestamp_b = {
                'server_time': base_time + random.uniform(-3600, 3600),
                'device_time': base_time + random.uniform(-3600, 3600) + random.uniform(-0.001, 0.001),
                'offset': random.uniform(-0.001, 0.001),
                'precision': 'millisecond',
                'local_time': datetime.fromtimestamp(base_time + random.uniform(-3600, 3600)),
                'timezone_id': random.choice(['America/Los_Angeles', 'America/New_York', 'Europe/London', 'Asia/Tokyo'])
            }
            
            control_pairs.append({
                'pair_id': f'pair_{i:04d}',
                'timestamp_a': control_timestamp_a,
                'timestamp_b': control_timestamp_b,
            })
            
            test_pairs.append({
                'pair_id': f'pair_{i:04d}',
                'timestamp_a': test_timestamp_a,
                'timestamp_b': test_timestamp_b,
            })
        
        return control_pairs, test_pairs
    
    def run_control_group(self, pairs: List[Dict]) -> List[Dict]:
        """Run control group (standard timestamps) - to be implemented by subclasses"""
        raise NotImplementedError("Subclasses must implement run_control_group")
    
    def run_test_group(self, pairs: List[Dict]) -> List[Dict]:
        """Run test group (atomic timing) - to be implemented by subclasses"""
        raise NotImplementedError("Subclasses must implement run_test_group")
    
    def calculate_statistics(
        self,
        control_results: List[Dict],
        test_results: List[Dict]
    ) -> Dict:
        """Calculate statistics comparing control vs test groups"""
        control_df = pd.DataFrame(control_results)
        test_df = pd.DataFrame(test_results)
        
        stats_dict = {
            'control': {},
            'test': {},
            'improvements': {},
            'statistical_tests': {}
        }
        
        # Calculate means for each metric
        for metric in control_df.columns:
            if metric in ['pair_id', 'experiment_id']:
                continue
            
            # Skip non-numeric columns
            if not pd.api.types.is_numeric_dtype(control_df[metric]):
                continue
            
            if metric in control_df.columns and metric in test_df.columns:
                control_mean = control_df[metric].mean()
                test_mean = test_df[metric].mean()
                
                stats_dict['control'][metric] = float(control_mean)
                stats_dict['test'][metric] = float(test_mean)
                
                # Calculate improvement
                if control_mean > 0:
                    improvement = ((test_mean - control_mean) / control_mean) * 100
                    improvement_x = test_mean / control_mean if control_mean > 0 else 0
                    stats_dict['improvements'][metric] = {
                        'percentage': float(improvement),
                        'multiplier': float(improvement_x)
                    }
                
                # Statistical tests
                if len(control_df) > 1 and len(test_df) > 1:
                    # t-test
                    t_stat, p_value = stats.ttest_ind(control_df[metric], test_df[metric])
                    
                    # Cohen's d (effect size)
                    pooled_std = np.sqrt(
                        ((len(control_df) - 1) * control_df[metric].std()**2 + 
                         (len(test_df) - 1) * test_df[metric].std()**2) /
                        (len(control_df) + len(test_df) - 2)
                    )
                    cohens_d = (test_mean - control_mean) / pooled_std if pooled_std > 0 else 0
                    
                    # Confidence interval (95%)
                    control_ci = stats.t.interval(
                        0.95, len(control_df) - 1,
                        loc=control_mean,
                        scale=stats.sem(control_df[metric])
                    )
                    test_ci = stats.t.interval(
                        0.95, len(test_df) - 1,
                        loc=test_mean,
                        scale=stats.sem(test_df[metric])
                    )
                    
                    stats_dict['statistical_tests'][metric] = {
                        't_statistic': float(t_stat),
                        'p_value': float(p_value),
                        'cohens_d': float(cohens_d),
                        'control_ci_95': [float(control_ci[0]), float(control_ci[1])],
                        'test_ci_95': [float(test_ci[0]), float(test_ci[1])],
                        'statistically_significant': p_value < 0.01,
                        'large_effect_size': abs(cohens_d) > 1.0
                    }
        
        return stats_dict
    
    def save_results(
        self,
        control_results: List[Dict],
        test_results: List[Dict],
        statistics: Dict
    ):
        """Save results to files"""
        # Save CSV files
        pd.DataFrame(control_results).to_csv(
            self.results_dir / 'control_results.csv',
            index=False
        )
        pd.DataFrame(test_results).to_csv(
            self.results_dir / 'test_results.csv',
            index=False
        )
        
        # Save statistics JSON
        with open(self.results_dir / 'statistics.json', 'w') as f:
            json.dump(statistics, f, indent=2, default=str)
        
        # Save summary report
        self._generate_summary_report(statistics)
    
    def _generate_summary_report(self, statistics: Dict):
        """Generate markdown summary report"""
        report = f"""# {self.experiment_name} - Results Summary

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Experiment:** {self.experiment_name}  
**Test Pairs:** {self.num_pairs}  
**Random Seed:** {self.random_seed}

---

## 📊 Results Summary

### Control Group (Standard Timestamps)
"""
        for metric, value in statistics['control'].items():
            report += f"- **{metric}:** {value:.4f}\n"
        
        report += "\n### Test Group (Atomic Timing)\n"
        for metric, value in statistics['test'].items():
            report += f"- **{metric}:** {value:.4f}\n"
        
        report += "\n### Improvements\n"
        for metric, improvement in statistics['improvements'].items():
            report += f"- **{metric}:** {improvement['percentage']:.2f}% improvement ({improvement['multiplier']:.2f}x)\n"
        
        report += "\n### Statistical Validation\n"
        for metric, test in statistics['statistical_tests'].items():
            report += f"\n**{metric}:**\n"
            report += f"- p-value: {test['p_value']:.6f} {'✅' if test['statistically_significant'] else '❌'}\n"
            report += f"- Cohen's d: {test['cohens_d']:.4f} {'✅' if test['large_effect_size'] else '❌'}\n"
            report += f"- Control 95% CI: [{test['control_ci_95'][0]:.4f}, {test['control_ci_95'][1]:.4f}]\n"
            report += f"- Test 95% CI: [{test['test_ci_95'][0]:.4f}, {test['test_ci_95'][1]:.4f}]\n"
        
        report += "\n---\n\n**Status:** ✅ Experiment Complete"
        
        with open(self.results_dir / 'SUMMARY.md', 'w') as f:
            f.write(report)
    
    def run_experiment(self) -> Tuple[List[Dict], List[Dict], Dict]:
        """Run the full experiment"""
        print("=" * 70)
        print(f"Running {self.experiment_name}")
        print("=" * 70)
        print()
        
        # Generate test data
        print(f"Generating {self.num_pairs} test pairs...")
        control_pairs, test_pairs = self.generate_test_data()
        
        # Run control group
        print("Running control group (standard timestamps)...")
        control_results = self.run_control_group(control_pairs)
        
        # Run test group
        print("Running test group (atomic timing)...")
        test_results = self.run_test_group(test_pairs)
        
        # Calculate statistics
        print("Calculating statistics...")
        statistics = self.calculate_statistics(control_results, test_results)
        
        # Save results
        print("Saving results...")
        self.save_results(control_results, test_results, statistics)
        
        print(f"\n✅ Experiment complete!")
        print(f"Results saved to: {self.results_dir}")
        
        return control_results, test_results, statistics

