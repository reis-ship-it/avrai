#!/usr/bin/env python3
"""
Run All Knot Integration Experiments

This script runs all three knot integration experiments:
1. Knot-Enhanced Recommendation Experiment (EventRecommendationService)
2. Knot-Enhanced Matching Experiment (EventMatchingService)
3. Knot-Enhanced Spot Matching Experiment (SpotVibeMatchingService)

Date: December 28, 2025
"""

import sys
from pathlib import Path
from datetime import datetime

# Add current directory to path
sys.path.append(str(Path(__file__).parent))

print("=" * 80)
print("KNOT INTEGRATION EXPERIMENTS - COMPLETE SUITE")
print("=" * 80)
print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print()

# Import experiment scripts
from run_knot_recommendation_experiment import run_experiment as run_recommendation_experiment
from run_knot_matching_experiment import run_experiment as run_matching_experiment
from run_knot_spot_matching_experiment import run_experiment as run_spot_matching_experiment

experiments = [
    ("Knot-Enhanced Recommendation", run_recommendation_experiment),
    ("Knot-Enhanced Matching", run_matching_experiment),
    ("Knot-Enhanced Spot Matching", run_spot_matching_experiment),
]

results = {}

for name, experiment_func in experiments:
    print()
    print("=" * 80)
    print(f"Running: {name}")
    print("=" * 80)
    print()
    
    try:
        experiment_func()
        results[name] = "✅ SUCCESS"
        print()
        print(f"✅ {name} completed successfully!")
    except Exception as e:
        results[name] = f"❌ FAILED: {str(e)}"
        print()
        print(f"❌ {name} failed: {e}")
        import traceback
        traceback.print_exc()
    
    print()

# Final summary
print("=" * 80)
print("EXPERIMENT SUITE SUMMARY")
print("=" * 80)
print()

for name, status in results.items():
    print(f"  {name}: {status}")

print()
print("=" * 80)
print("All experiments complete!")
print("=" * 80)
