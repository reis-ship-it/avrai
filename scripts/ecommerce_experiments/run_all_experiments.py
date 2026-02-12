#!/usr/bin/env python3
"""
E-Commerce Enrichment API - Run All Experiments
Phase 21: E-Commerce Data Enrichment Integration POC
Runs all experiments and generates comprehensive report
"""

import sys
import os
import argparse
import time
from datetime import datetime

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from test_endpoint_functionality import EndpointFunctionalityTest
from test_performance import PerformanceBenchmark
from test_algorithm_enhancement import AlgorithmEnhancementExperiment
from test_data_quality import DataQualityValidation


def run_all_experiments(api_url: str, api_key: str, options: dict = None):
    """Run all e-commerce enrichment experiments"""
    if options is None:
        options = {}
    
    print("="*80)
    print("E-Commerce Enrichment API - Comprehensive Experiment Suite")
    print("="*80)
    print(f"API URL: {api_url}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    results = {}
    
    # 1. Endpoint Functionality Tests
    if options.get('run_functionality', True):
        print("\n" + "="*80)
        print("1. Endpoint Functionality Tests")
        print("="*80)
        try:
            functionality_test = EndpointFunctionalityTest(api_url, api_key)
            functionality_test.run_all_tests()
            results['functionality'] = 'PASS'
        except Exception as e:
            print(f"❌ Functionality tests failed: {e}")
            results['functionality'] = f'FAIL: {e}'
    
    # 2. Performance Benchmarks
    if options.get('run_performance', True):
        print("\n" + "="*80)
        print("2. Performance Benchmarks")
        print("="*80)
        try:
            iterations = options.get('performance_iterations', 100)
            performance_test = PerformanceBenchmark(api_url, api_key)
            performance_test.run_all_benchmarks(iterations)
            results['performance'] = 'PASS'
        except Exception as e:
            print(f"❌ Performance benchmarks failed: {e}")
            results['performance'] = f'FAIL: {e}'
    
    # 3. Algorithm Enhancement A/B Test
    if options.get('run_ab_test', True):
        print("\n" + "="*80)
        print("3. Algorithm Enhancement A/B Test")
        print("="*80)
        try:
            num_users = options.get('ab_test_users', 1000)
            num_products = options.get('ab_test_products', 100)
            ab_test = AlgorithmEnhancementExperiment(api_url, api_key)
            ab_test.run_ab_test(num_users, num_products)
            results['ab_test'] = 'PASS'
        except Exception as e:
            print(f"❌ A/B test failed: {e}")
            results['ab_test'] = f'FAIL: {e}'
    
    # 4. Data Quality Validation
    if options.get('run_validation', True):
        print("\n" + "="*80)
        print("4. Data Quality Validation")
        print("="*80)
        try:
            validation = DataQualityValidation(api_url, api_key)
            all_passed = validation.run_all_validations()
            results['validation'] = 'PASS' if all_passed else 'FAIL'
        except Exception as e:
            print(f"❌ Data quality validation failed: {e}")
            results['validation'] = f'FAIL: {e}'
    
    # Generate master summary
    print("\n" + "="*80)
    print("Master Summary")
    print("="*80)
    print(f"\nCompleted: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    print("Experiment Results:")
    for experiment, result in results.items():
        status = "✅" if result == "PASS" else "❌"
        print(f"  {status} {experiment}: {result}")
    
    # Save master summary
    summary_path = "results/MASTER_SUMMARY.md"
    os.makedirs("results", exist_ok=True)
    with open(summary_path, 'w') as f:
        f.write("# E-Commerce Enrichment API - Master Experiment Summary\n\n")
        f.write(f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write("## Experiment Results\n\n")
        f.write("| Experiment | Status |\n")
        f.write("|------------|--------|\n")
        for experiment, result in results.items():
            f.write(f"| {experiment} | {result} |\n")
    
    print(f"\nMaster summary saved to: {summary_path}")
    print("\n" + "="*80)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Run all e-commerce enrichment API experiments"
    )
    parser.add_argument("--api-url", required=True, help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key")
    parser.add_argument("--skip-functionality", action="store_true", help="Skip functionality tests")
    parser.add_argument("--skip-performance", action="store_true", help="Skip performance benchmarks")
    parser.add_argument("--skip-ab-test", action="store_true", help="Skip A/B test")
    parser.add_argument("--skip-validation", action="store_true", help="Skip data quality validation")
    parser.add_argument("--performance-iterations", type=int, default=100, help="Performance test iterations")
    parser.add_argument("--ab-test-users", type=int, default=1000, help="A/B test number of users")
    parser.add_argument("--ab-test-products", type=int, default=100, help="A/B test number of products")
    
    args = parser.parse_args()
    
    options = {
        'run_functionality': not args.skip_functionality,
        'run_performance': not args.skip_performance,
        'run_ab_test': not args.skip_ab_test,
        'run_validation': not args.skip_validation,
        'performance_iterations': args.performance_iterations,
        'ab_test_users': args.ab_test_users,
        'ab_test_products': args.ab_test_products,
    }
    
    run_all_experiments(args.api_url, args.api_key, options)
