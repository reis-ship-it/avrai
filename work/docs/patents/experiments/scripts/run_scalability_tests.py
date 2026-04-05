#!/usr/bin/env python3
"""
Scalability Tests - Large Agent Counts

Runs all patent experiments with large agent counts:
- 10,000 agents
- 100,000 agents
- 500,000 agents
- 1,000,000 agents

Date: December 19, 2025
"""

import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime

# Configuration
SCRIPTS_DIR = Path(__file__).parent
RESULTS_DIR = Path(__file__).parent.parent / 'results' / 'scalability'
RESULTS_DIR.mkdir(parents=True, exist_ok=True)
LOGS_DIR = Path(__file__).parent.parent / 'logs'
LOGS_DIR.mkdir(parents=True, exist_ok=True)

# Agent counts to test
AGENT_COUNTS = [10000, 100000, 500000, 1000000]


def run_experiments_for_agent_count(num_agents):
    """Run all experiments for a specific agent count."""
    print("=" * 70)
    print(f"SCALABILITY TEST: {num_agents:,} AGENTS")
    print("=" * 70)
    print()
    
    start_time = time.time()
    results = {}
    
    # Step 1: Generate data
    print(f"📊 Step 1: Generating data for {num_agents:,} agents...")
    print("-" * 70)
    try:
        data_start = time.time()
        result = subprocess.run(
            ['python3', str(SCRIPTS_DIR / 'generate_synthetic_data.py'), str(num_agents)],
            cwd=str(SCRIPTS_DIR.parent),
            capture_output=True,
            text=True,
            timeout=3600  # 1 hour timeout
        )
        data_duration = time.time() - data_start
        
        if result.returncode == 0:
            print(f"✅ Data generation completed in {data_duration:.2f} seconds")
            results['data_generation'] = {'duration': data_duration, 'status': 'success'}
        else:
            print(f"❌ Data generation failed: {result.stderr}")
            results['data_generation'] = {'duration': data_duration, 'status': 'failed', 'error': result.stderr}
            return results
    except subprocess.TimeoutExpired:
        print(f"❌ Data generation timed out after 1 hour")
        results['data_generation'] = {'status': 'timeout'}
        return results
    except Exception as e:
        print(f"❌ Data generation error: {e}")
        results['data_generation'] = {'status': 'error', 'error': str(e)}
        return results
    
    print()
    
    # Step 2: Run Patent #1 experiments (sample pairs for large N)
    print(f"🔬 Step 2: Running Patent #1 experiments...")
    print("-" * 70)
    try:
        exp_start = time.time()
        result = subprocess.run(
            ['python3', str(SCRIPTS_DIR / 'run_patent_1_experiments.py')],
            cwd=str(SCRIPTS_DIR.parent),
            capture_output=True,
            text=True,
            timeout=3600
        )
        exp_duration = time.time() - exp_start
        
        if result.returncode == 0:
            print(f"✅ Patent #1 completed in {exp_duration:.2f} seconds")
            results['patent_1'] = {'duration': exp_duration, 'status': 'success'}
        else:
            print(f"⚠️  Patent #1 had issues: {result.stderr[:200]}")
            results['patent_1'] = {'duration': exp_duration, 'status': 'partial'}
    except Exception as e:
        print(f"❌ Patent #1 error: {e}")
        results['patent_1'] = {'status': 'error', 'error': str(e)}
    
    print()
    
    # Step 3: Run Patent #3 experiments (most time-consuming, may need to skip for very large N)
    if num_agents <= 100000:
        print(f"🔬 Step 3: Running Patent #3 experiments (6 months)...")
        print("-" * 70)
        try:
            exp_start = time.time()
            result = subprocess.run(
                ['python3', str(SCRIPTS_DIR / 'run_patent_3_experiments.py'), '6'],
                cwd=str(SCRIPTS_DIR.parent),
                capture_output=True,
                text=True,
                timeout=7200  # 2 hour timeout
            )
            exp_duration = time.time() - exp_start
            
            if result.returncode == 0:
                print(f"✅ Patent #3 completed in {exp_duration:.2f} seconds")
                results['patent_3'] = {'duration': exp_duration, 'status': 'success'}
            else:
                print(f"⚠️  Patent #3 had issues: {result.stderr[:200]}")
                results['patent_3'] = {'duration': exp_duration, 'status': 'partial'}
        except Exception as e:
            print(f"❌ Patent #3 error: {e}")
            results['patent_3'] = {'status': 'error', 'error': str(e)}
    else:
        print(f"⏭️  Step 3: Skipping Patent #3 (too many agents for time-based simulation)")
        results['patent_3'] = {'status': 'skipped', 'reason': 'too_many_agents'}
    
    print()
    
    # Step 4: Run Patent #21 experiments
    print(f"🔬 Step 4: Running Patent #21 experiments...")
    print("-" * 70)
    try:
        exp_start = time.time()
        result = subprocess.run(
            ['python3', str(SCRIPTS_DIR / 'run_patent_21_experiments.py')],
            cwd=str(SCRIPTS_DIR.parent),
            capture_output=True,
            text=True,
            timeout=3600
        )
        exp_duration = time.time() - exp_start
        
        if result.returncode == 0:
            print(f"✅ Patent #21 completed in {exp_duration:.2f} seconds")
            results['patent_21'] = {'duration': exp_duration, 'status': 'success'}
        else:
            print(f"⚠️  Patent #21 had issues: {result.stderr[:200]}")
            results['patent_21'] = {'duration': exp_duration, 'status': 'partial'}
    except Exception as e:
        print(f"❌ Patent #21 error: {e}")
        results['patent_21'] = {'status': 'error', 'error': str(e)}
    
    print()
    
    # Step 5: Run Patent #29 experiments
    print(f"🔬 Step 5: Running Patent #29 experiments...")
    print("-" * 70)
    try:
        exp_start = time.time()
        result = subprocess.run(
            ['python3', str(SCRIPTS_DIR / 'run_patent_29_experiments.py')],
            cwd=str(SCRIPTS_DIR.parent),
            capture_output=True,
            text=True,
            timeout=3600
        )
        exp_duration = time.time() - exp_start
        
        if result.returncode == 0:
            print(f"✅ Patent #29 completed in {exp_duration:.2f} seconds")
            results['patent_29'] = {'duration': exp_duration, 'status': 'success'}
        else:
            print(f"⚠️  Patent #29 had issues: {result.stderr[:200]}")
            results['patent_29'] = {'duration': exp_duration, 'status': 'partial'}
    except Exception as e:
        print(f"❌ Patent #29 error: {e}")
        results['patent_29'] = {'status': 'error', 'error': str(e)}
    
    print()
    
    total_duration = time.time() - start_time
    
    print("=" * 70)
    print(f"✅ {num_agents:,} AGENTS TEST COMPLETE")
    print("=" * 70)
    print(f"Total Duration: {total_duration:.2f} seconds ({total_duration/60:.2f} minutes)")
    print()
    
    results['total_duration'] = total_duration
    results['num_agents'] = num_agents
    
    return results


def main():
    """Run scalability tests for all agent counts."""
    print("=" * 70)
    print("SCALABILITY TESTS - LARGE AGENT COUNTS")
    print("=" * 70)
    print()
    print("Testing with:")
    for count in AGENT_COUNTS:
        print(f"  - {count:,} agents")
    print()
    print("=" * 70)
    print()
    
    all_results = {}
    
    for num_agents in AGENT_COUNTS:
        results = run_experiments_for_agent_count(num_agents)
        all_results[num_agents] = results
        
        # Save results
        import json
        results_file = RESULTS_DIR / f'scalability_{num_agents}_agents.json'
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print()
        print(f"📄 Results saved to: {results_file}")
        print()
    
    # Create summary
    summary_file = RESULTS_DIR / 'scalability_summary.md'
    with open(summary_file, 'w') as f:
        f.write(f"""# Scalability Test Summary

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Purpose:** Test patent experiments with large agent counts

---

## 📊 **Results by Agent Count**

""")
        
        for num_agents in AGENT_COUNTS:
            results = all_results[num_agents]
            f.write(f"""### **{num_agents:,} Agents**

- **Total Duration:** {results.get('total_duration', 0):.2f} seconds ({results.get('total_duration', 0)/60:.2f} minutes)
- **Data Generation:** {results.get('data_generation', {}).get('duration', 0):.2f}s - {results.get('data_generation', {}).get('status', 'unknown')}
- **Patent #1:** {results.get('patent_1', {}).get('duration', 0):.2f}s - {results.get('patent_1', {}).get('status', 'unknown')}
- **Patent #3:** {results.get('patent_3', {}).get('duration', 0):.2f}s - {results.get('patent_3', {}).get('status', 'unknown')}
- **Patent #21:** {results.get('patent_21', {}).get('duration', 0):.2f}s - {results.get('patent_21', {}).get('status', 'unknown')}
- **Patent #29:** {results.get('patent_29', {}).get('duration', 0):.2f}s - {results.get('patent_29', {}).get('status', 'unknown')}

""")
        
        f.write(f"""
---

## 📈 **Performance Analysis**

[Performance analysis will be added after all tests complete]

---

**Completed:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
""")
    
    print("=" * 70)
    print("✅ ALL SCALABILITY TESTS COMPLETE")
    print("=" * 70)
    print(f"📄 Summary saved to: {summary_file}")
    print()


if __name__ == '__main__':
    main()

