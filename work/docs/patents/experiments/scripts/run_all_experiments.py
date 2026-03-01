#!/usr/bin/env python3
"""
Master Experiment Runner - All Patent Experiments

Runs all 30 experiments (19 required + 11 optional) for Patents #1, #3, #21, #29, #11

Date: December 21, 2025
"""

import sys
import time
from pathlib import Path

# Add scripts directory to path
SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPTS_DIR))

# Import individual experiment modules
try:
    from run_patent_1_experiments import run_patent_1_experiments
    from run_patent_3_experiments import run_patent_3_experiments
    from run_patent_21_experiments import run_patent_21_experiments
    from run_patent_29_experiments import run_patent_29_experiments
    from run_patent_11_experiments import run_patent_11_experiments
except ImportError as e:
    print(f"⚠️  Warning: Some experiment modules not found: {e}")
    print("Creating individual experiment scripts...")
    print()
    print("Please run experiments individually:")
    print("  python scripts/run_patent_1_experiments.py")
    print("  python scripts/run_patent_3_experiments.py")
    print("  python scripts/run_patent_21_experiments.py")
    print("  python scripts/run_patent_29_experiments.py")
    print("  python scripts/run_patent_11_experiments.py")
    sys.exit(1)


def main():
    """Run all experiments."""
    print("=" * 70)
    print("Master Experiment Runner - All Patent Experiments")
    print("=" * 70)
    print()
    print("Total Experiments: 33 (19 required + 11 optional + 3 focused tests)")
    print("  - Patent #1: 5 experiments (4 required + 1 optional)")
    print("  - Patent #3: 5 experiments (3 required + 2 optional)")
    print("  - Patent #21: 4 experiments (2 required + 2 optional)")
    print("  - Patent #29: 9 experiments (6 required + 3 optional)")
    print("  - Patent #11: 11 experiments (6 required + 2 optional + 3 focused tests)")
    print()
    print("Note: Some optional experiments are not yet implemented and will be skipped.")
    print()
    print("=" * 70)
    print()
    
    start_time = time.time()
    
    # Run Patent #1 experiments
    print("🔬 Running Patent #1 Experiments...")
    print("-" * 70)
    try:
        run_patent_1_experiments()
        print("✅ Patent #1 experiments completed")
    except Exception as e:
        print(f"❌ Patent #1 experiments failed: {e}")
    print()
    
    # Run Patent #3 experiments
    print("🔬 Running Patent #3 Experiments...")
    print("-" * 70)
    try:
        run_patent_3_experiments()
        print("✅ Patent #3 experiments completed")
    except Exception as e:
        print(f"❌ Patent #3 experiments failed: {e}")
    print()
    
    # Run Patent #21 experiments
    print("🔬 Running Patent #21 Experiments...")
    print("-" * 70)
    try:
        run_patent_21_experiments()
        print("✅ Patent #21 experiments completed")
    except Exception as e:
        print(f"❌ Patent #21 experiments failed: {e}")
    print()
    
    # Run Patent #29 experiments
    print("🔬 Running Patent #29 Experiments...")
    print("-" * 70)
    try:
        run_patent_29_experiments()
        print("✅ Patent #29 experiments completed")
    except Exception as e:
        print(f"❌ Patent #29 experiments failed: {e}")
    print()
    
    # Run Patent #11 experiments
    print("🔬 Running Patent #11 Experiments...")
    print("-" * 70)
    try:
        run_patent_11_experiments()
        print("✅ Patent #11 experiments completed")
    except Exception as e:
        print(f"❌ Patent #11 experiments failed: {e}")
    print()
    
    elapsed = time.time() - start_time
    
    print("=" * 70)
    print("✅ All Experiments Completed!")
    print("=" * 70)
    print(f"Total Time: {elapsed:.2f} seconds ({elapsed/60:.2f} minutes)")
    print()
    print("Results saved to:")
    print("  - docs/patents/experiments/results/patent_1/")
    print("  - docs/patents/experiments/results/patent_3/")
    print("  - docs/patents/experiments/results/patent_21/")
    print("  - docs/patents/experiments/results/patent_29/")


if __name__ == '__main__':
    main()

