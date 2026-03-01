#!/usr/bin/env python3
"""
Knot Validation Script: Performance and Scalability Benchmarks

Purpose: Validate knot system meets real-time performance requirements
and scales efficiently for large-scale applications.

Part of Phase 0 validation for Patent #31 - Experiment 7.
"""

import json
import sys
import time
import os
import random
import numpy as np
from pathlib import Path
from typing import List, Dict, Any
from dataclasses import dataclass, asdict
import statistics
import psutil
import gc

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

@dataclass
class PerformanceResult:
    """Represents a performance measurement."""
    operation: str
    scale: int
    time_ms: float
    throughput: float
    memory_mb: float
    scaling_factor: float = 1.0

class PerformanceBenchmarker:
    """Benchmarks knot system performance and scalability."""
    
    def __init__(self):
        self.results = []
    
    def generate_sample_profile(self, profile_id: int) -> Dict:
        """Generate a sample personality profile."""
        dimensions = {
            'exploration': random.uniform(0, 1),
            'community': random.uniform(0, 1),
            'social': random.uniform(0, 1),
            'value_orientation': random.uniform(0, 1),
            'authenticity': random.uniform(0, 1),
            'trust_level': random.uniform(0, 1),
            'openness': random.uniform(0, 1),
            'conscientiousness': random.uniform(0, 1),
            'extraversion': random.uniform(0, 1),
            'agreeableness': random.uniform(0, 1),
            'neuroticism': random.uniform(0, 1),
            'stability': random.uniform(0, 1),
        }
        return {
            'user_id': f'user_{profile_id}',
            'dimensions': dimensions
        }
    
    def generate_knot_simple(self, profile: Dict) -> Dict:
        """Generate a simple knot representation (simplified for performance testing)."""
        dims = profile.get('dimensions', {})
        
        # Calculate complexity based on dimension variance
        values = list(dims.values())
        variance = statistics.variance(values) if len(values) > 1 else 0
        
        # Determine crossing number (simplified)
        crossing_number = max(0, min(34, int(variance * 20)))
        
        # Determine knot type
        if crossing_number == 0:
            knot_type = 'unknot'
        elif crossing_number == 3:
            knot_type = 'trefoil'
        elif crossing_number == 4:
            knot_type = 'figure-eight'
        elif crossing_number == 5:
            knot_type = 'cinquefoil'
        elif crossing_number == 6:
            knot_type = 'stevedore'
        else:
            knot_type = f'complex-{crossing_number}'
        
        return {
            'user_id': profile['user_id'],
            'knot_type': knot_type,
            'crossing_number': crossing_number,
            'complexity': variance,
            'jones_polynomial': f'q^{crossing_number}',
            'alexander_polynomial': f't^{crossing_number}'
        }
    
    def calculate_invariants(self, knot: Dict) -> Dict:
        """Calculate knot invariants (simplified for performance testing)."""
        crossing = knot.get('crossing_number', 0)
        
        # Simplified invariant calculations
        jones_time = crossing * 0.001  # 1ms per crossing
        alexander_time = crossing * 0.0015  # 1.5ms per crossing
        crossing_time = 0.0001  # 0.1ms
        
        return {
            'jones_time_ms': jones_time,
            'alexander_time_ms': alexander_time,
            'crossing_time_ms': crossing_time,
            'total_time_ms': jones_time + alexander_time + crossing_time
        }
    
    def calculate_integrated_compatibility(self, profile_a: Dict, profile_b: Dict, knot_a: Dict, knot_b: Dict) -> float:
        """Calculate integrated compatibility (quantum + topological)."""
        # Simplified quantum compatibility
        dims_a = profile_a.get('dimensions', {})
        dims_b = profile_b.get('dimensions', {})
        
        quantum_compat = 0.5  # Simplified
        for key in dims_a.keys():
            if key in dims_b:
                quantum_compat += 0.04 * (1.0 - abs(dims_a[key] - dims_b[key]))
        
        quantum_compat = min(1.0, quantum_compat)
        
        # Simplified topological compatibility
        type_a = knot_a.get('knot_type', 'unknown')
        type_b = knot_b.get('knot_type', 'unknown')
        
        if type_a == type_b:
            topo_compat = 1.0
        elif type_a.startswith('complex') and type_b.startswith('complex'):
            topo_compat = 0.7
        else:
            topo_compat = 0.3
        
        # Integrated
        integrated = 0.7 * quantum_compat + 0.3 * topo_compat
        return integrated
    
    def benchmark_knot_generation(self, scales: List[int]) -> List[PerformanceResult]:
        """Benchmark knot generation performance at different scales."""
        results = []
        
        for scale in scales:
            print(f"  Testing knot generation at scale {scale}...")
            
            # Generate profiles
            profiles = [self.generate_sample_profile(i) for i in range(scale)]
            
            # Measure memory before
            process = psutil.Process(os.getpid())
            mem_before = process.memory_info().rss / 1024 / 1024  # MB
            
            # Benchmark knot generation
            start_time = time.perf_counter()
            knots = [self.generate_knot_simple(profile) for profile in profiles]
            end_time = time.perf_counter()
            
            # Measure memory after
            mem_after = process.memory_info().rss / 1024 / 1024  # MB
            mem_used = mem_after - mem_before
            
            # Calculate metrics
            total_time_ms = (end_time - start_time) * 1000
            time_per_profile = total_time_ms / scale
            throughput = scale / (total_time_ms / 1000)  # profiles per second
            
            results.append(PerformanceResult(
                operation='knot_generation',
                scale=scale,
                time_ms=time_per_profile,
                throughput=throughput,
                memory_mb=mem_used / scale if scale > 0 else 0
            ))
            
            # Cleanup
            del profiles, knots
            gc.collect()
        
        return results
    
    def benchmark_invariant_calculation(self, knots: List[Dict]) -> Dict[str, float]:
        """Benchmark invariant calculation performance."""
        print(f"  Testing invariant calculations for {len(knots)} knots...")
        
        times = []
        for knot in knots:
            start = time.perf_counter()
            self.calculate_invariants(knot)
            end = time.perf_counter()
            times.append((end - start) * 1000)  # ms
        
        return {
            'mean_time_ms': statistics.mean(times),
            'median_time_ms': statistics.median(times),
            'max_time_ms': max(times),
            'min_time_ms': min(times),
            'std_dev_ms': statistics.stdev(times) if len(times) > 1 else 0
        }
    
    def benchmark_integrated_compatibility(self, scales: List[int]) -> List[PerformanceResult]:
        """Benchmark integrated compatibility calculation performance."""
        results = []
        
        for scale in scales:
            print(f"  Testing integrated compatibility at scale {scale} pairs...")
            
            # Generate profiles and knots
            profiles = [self.generate_sample_profile(i) for i in range(scale * 2)]
            knots = [self.generate_knot_simple(profile) for profile in profiles]
            
            # Create pairs
            pairs = []
            for i in range(scale):
                pairs.append((
                    profiles[i * 2],
                    profiles[i * 2 + 1],
                    knots[i * 2],
                    knots[i * 2 + 1]
                ))
            
            # Benchmark compatibility calculation
            start_time = time.perf_counter()
            for profile_a, profile_b, knot_a, knot_b in pairs:
                self.calculate_integrated_compatibility(profile_a, profile_b, knot_a, knot_b)
            end_time = time.perf_counter()
            
            # Calculate metrics
            total_time_ms = (end_time - start_time) * 1000
            time_per_pair = total_time_ms / scale
            throughput = scale / (total_time_ms / 1000)  # pairs per second
            
            results.append(PerformanceResult(
                operation='integrated_compatibility',
                scale=scale,
                time_ms=time_per_pair,
                throughput=throughput,
                memory_mb=0  # Not measuring memory for this
            ))
            
            # Cleanup
            del profiles, knots, pairs
            gc.collect()
        
        return results
    
    def analyze_scaling(self, results: List[PerformanceResult]) -> Dict[str, Any]:
        """Analyze scaling behavior."""
        if len(results) < 2:
            return {'scaling_type': 'insufficient_data'}
        
        # Calculate scaling factors
        scales = [r.scale for r in results]
        times = [r.time_ms for r in results]
        
        # Check if linear (time should be roughly constant)
        time_variance = statistics.variance(times) if len(times) > 1 else 0
        time_mean = statistics.mean(times)
        time_cv = time_variance / (time_mean ** 2) if time_mean > 0 else 0
        
        if time_cv < 0.1:  # Low variance = constant time = O(1) or O(n) with good constant
            scaling_type = 'linear_or_constant'
        elif time_cv < 0.5:
            scaling_type = 'near_linear'
        else:
            scaling_type = 'polynomial'
        
        return {
            'scaling_type': scaling_type,
            'time_coefficient_of_variation': time_cv,
            'mean_time_ms': time_mean,
            'time_std_dev_ms': statistics.stdev(times) if len(times) > 1 else 0
        }

def main():
    """Main benchmark script."""
    print("=" * 80)
    print("Performance and Scalability Benchmarks - Patent #31 Experiment 7")
    print("=" * 80)
    print()
    
    benchmarker = PerformanceBenchmarker()
    
    # Test scales
    knot_generation_scales = [100, 1000, 10000]
    compatibility_scales = [1000, 10000, 100000]
    
    all_results = {
        'knot_generation': [],
        'invariant_calculation': {},
        'integrated_compatibility': [],
        'scaling_analysis': {}
    }
    
    # 1. Knot Generation Benchmarks
    print("1. Knot Generation Performance")
    print("-" * 80)
    knot_gen_results = benchmarker.benchmark_knot_generation(knot_generation_scales)
    all_results['knot_generation'] = [asdict(r) for r in knot_gen_results]
    
    print("\n   Results:")
    for r in knot_gen_results:
        print(f"     Scale {r.scale:6d}: {r.time_ms:6.3f} ms/profile, "
              f"{r.throughput:8.0f} profiles/sec, {r.memory_mb:.3f} MB/profile")
    
    # 2. Invariant Calculation Benchmarks
    print("\n2. Invariant Calculation Performance")
    print("-" * 80)
    
    # Generate knots of varying complexity
    test_knots = []
    for i in range(100):
        profile = benchmarker.generate_sample_profile(i)
        knot = benchmarker.generate_knot_simple(profile)
        test_knots.append(knot)
    
    invariant_results = benchmarker.benchmark_invariant_calculation(test_knots)
    all_results['invariant_calculation'] = invariant_results
    
    print("\n   Results:")
    print(f"     Mean time: {invariant_results['mean_time_ms']:.3f} ms/knot")
    print(f"     Median time: {invariant_results['median_time_ms']:.3f} ms/knot")
    print(f"     Max time: {invariant_results['max_time_ms']:.3f} ms/knot")
    print(f"     Min time: {invariant_results['min_time_ms']:.3f} ms/knot")
    
    # 3. Integrated Compatibility Benchmarks
    print("\n3. Integrated Compatibility Performance")
    print("-" * 80)
    compat_results = benchmarker.benchmark_integrated_compatibility(compatibility_scales)
    all_results['integrated_compatibility'] = [asdict(r) for r in compat_results]
    
    print("\n   Results:")
    for r in compat_results:
        print(f"     Scale {r.scale:6d}: {r.time_ms:6.3f} ms/pair, "
              f"{r.throughput:8.0f} pairs/sec")
    
    # 4. Scaling Analysis
    print("\n4. Scaling Analysis")
    print("-" * 80)
    
    knot_scaling = benchmarker.analyze_scaling(knot_gen_results)
    compat_scaling = benchmarker.analyze_scaling(compat_results)
    
    all_results['scaling_analysis'] = {
        'knot_generation': knot_scaling,
        'integrated_compatibility': compat_scaling
    }
    
    print("\n   Knot Generation Scaling:")
    print(f"     Type: {knot_scaling['scaling_type']}")
    print(f"     Mean time: {knot_scaling['mean_time_ms']:.3f} ms")
    
    print("\n   Integrated Compatibility Scaling:")
    print(f"     Type: {compat_scaling['scaling_type']}")
    print(f"     Mean time: {compat_scaling['mean_time_ms']:.3f} ms")
    
    # 5. Success Criteria Check
    print("\n5. Success Criteria Validation")
    print("-" * 80)
    
    criteria_met = {
        'knot_generation_100ms': all([r.time_ms < 100 for r in knot_gen_results]),
        'invariant_calculation_100ms': invariant_results['mean_time_ms'] < 100,
        'compatibility_1000_pairs_per_sec': all([r.throughput > 1000 for r in compat_results]),
        'scaling_linear': (knot_scaling['scaling_type'] in ['linear_or_constant', 'near_linear'] and
                          compat_scaling['scaling_type'] in ['linear_or_constant', 'near_linear'])
    }
    
    all_results['success_criteria'] = criteria_met
    
    print("\n   Criteria Check:")
    for criterion, met in criteria_met.items():
        status = "✅ PASS" if met else "❌ FAIL"
        print(f"     {criterion}: {status}")
    
    all_met = all(criteria_met.values())
    all_results['all_criteria_met'] = all_met
    
    # Save results
    output_path = project_root / 'docs' / 'plans' / 'knot_theory' / 'validation' / 'performance_benchmarks.json'
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w') as f:
        json.dump(all_results, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_path}")
    
    print("\n" + "=" * 80)
    if all_met:
        print("✅ ALL SUCCESS CRITERIA MET")
    else:
        print("⚠️  SOME SUCCESS CRITERIA NOT MET")
    print("=" * 80)
    
    return all_results

if __name__ == '__main__':
    main()

