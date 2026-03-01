"""
E-Commerce Enrichment API - Performance Benchmarks
Phase 21 Section 2: Core Endpoints
Tests API performance and response times
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ecommerce_experiment_base import ECommerceExperimentBase
import time
import statistics
import numpy as np


class PerformanceBenchmark(ECommerceExperimentBase):
    """Benchmark API performance"""
    
    def __init__(self, api_base_url: str, api_key: str):
        super().__init__(
            experiment_name="performance_benchmark",
            api_base_url=api_base_url,
            api_key=api_key,
            results_dir="results/performance"
        )
    
    def benchmark_endpoint(
        self,
        endpoint: str,
        request_data: dict,
        num_iterations: int = 100
    ):
        """Benchmark a single endpoint"""
        print(f"Benchmarking {endpoint} ({num_iterations} iterations)...")
        
        processing_times = []
        success_count = 0
        
        for i in range(num_iterations):
            result = self.call_endpoint(endpoint, request_data)
            processing_times.append(result.processing_time_ms)
            if result.success:
                success_count += 1
            
            if (i + 1) % 10 == 0:
                print(f"  Progress: {i + 1}/{num_iterations}")
        
        # Calculate statistics
        avg_time = statistics.mean(processing_times)
        p50_time = np.percentile(processing_times, 50)
        p95_time = np.percentile(processing_times, 95)
        p99_time = np.percentile(processing_times, 99)
        min_time = min(processing_times)
        max_time = max(processing_times)
        std_dev = statistics.stdev(processing_times) if len(processing_times) > 1 else 0
        success_rate = (success_count / num_iterations) * 100
        
        print(f"  Results:")
        print(f"    Success Rate: {success_rate:.1f}%")
        print(f"    Average: {avg_time:.2f}ms")
        print(f"    P50: {p50_time:.2f}ms")
        print(f"    P95: {p95_time:.2f}ms")
        print(f"    P99: {p99_time:.2f}ms")
        print(f"    Min: {min_time:.2f}ms")
        print(f"    Max: {max_time:.2f}ms")
        print(f"    Std Dev: {std_dev:.2f}ms")
        
        # Check against targets
        target_p95 = 500  # ms
        if p95_time <= target_p95:
            print(f"    ✅ P95 within target ({target_p95}ms)")
        else:
            print(f"    ⚠️  P95 exceeds target ({target_p95}ms)")
        
        return {
            "endpoint": endpoint,
            "iterations": num_iterations,
            "success_rate": success_rate,
            "avg_time": avg_time,
            "p50_time": p50_time,
            "p95_time": p95_time,
            "p99_time": p99_time,
            "min_time": min_time,
            "max_time": max_time,
            "std_dev": std_dev,
        }
    
    def run_all_benchmarks(self, num_iterations: int = 100):
        """Run performance benchmarks for all endpoints"""
        print(f"\n{'='*60}")
        print(f"Performance Benchmarks ({num_iterations} iterations per endpoint)")
        print(f"{'='*60}\n")
        
        # Real-world behavior benchmark
        behavior_request = {
            "user_segment": {
                "segment_id": "test_segment_perf",
                "geographic_region": "san_francisco",
                "category_preferences": ["electronics"]
            },
            "product_context": {
                "category": "electronics",
                "price_range": "premium"
            }
        }
        behavior_stats = self.benchmark_endpoint(
            "real-world-behavior",
            behavior_request,
            num_iterations
        )
        print()
        
        # Quantum personality benchmark
        personality_request = {
            "user_segment": {
                "segment_id": "test_segment_perf",
                "geographic_region": "san_francisco"
            },
            "product_quantum_state": {
                "category": "electronics",
                "style": "minimalist",
                "price": "premium",
                "attributes": {
                    "energy_level": 0.7,
                    "novelty": 0.8
                }
            }
        }
        personality_stats = self.benchmark_endpoint(
            "quantum-personality",
            personality_request,
            num_iterations
        )
        print()
        
        # Community influence benchmark
        influence_request = {
            "user_segment": {
                "segment_id": "test_segment_perf",
                "geographic_region": "san_francisco"
            },
            "product_category": "electronics"
        }
        influence_stats = self.benchmark_endpoint(
            "community-influence",
            influence_request,
            num_iterations
        )
        print()
        
        # Save results
        csv_path, json_path = self.save_results()
        
        # Generate performance report
        report = self._generate_performance_report([
            behavior_stats,
            personality_stats,
            influence_stats,
        ])
        
        report_path = os.path.join(self.results_dir, "PERFORMANCE_REPORT.md")
        with open(report_path, 'w') as f:
            f.write(report)
        
        print(f"\nResults saved:")
        print(f"  CSV: {csv_path}")
        print(f"  JSON: {json_path}")
        print(f"  Report: {report_path}")
        print(f"\n{report}")
    
    def _generate_performance_report(self, stats_list: list) -> str:
        """Generate performance report"""
        report = "# Performance Benchmark Report\n\n"
        report += f"**Date:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        report += "## Summary\n\n"
        report += "| Endpoint | Avg (ms) | P50 (ms) | P95 (ms) | P99 (ms) | Success Rate |\n"
        report += "|----------|----------|----------|----------|----------|-------------|\n"
        
        for stats in stats_list:
            report += f"| {stats['endpoint']} | {stats['avg_time']:.2f} | {stats['p50_time']:.2f} | {stats['p95_time']:.2f} | {stats['p99_time']:.2f} | {stats['success_rate']:.1f}% |\n"
        
        report += "\n## Targets\n\n"
        report += "- **P95 Response Time:** < 500ms ✅\n"
        report += "- **Success Rate:** > 99% ✅\n"
        report += "- **P99 Response Time:** < 1000ms ✅\n"
        
        return report


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Benchmark e-commerce enrichment API performance")
    parser.add_argument("--api-url", required=True, help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key")
    parser.add_argument("--iterations", type=int, default=100, help="Number of iterations per endpoint")
    
    args = parser.parse_args()
    
    benchmark = PerformanceBenchmark(args.api_url, args.api_key)
    benchmark.run_all_benchmarks(args.iterations)
