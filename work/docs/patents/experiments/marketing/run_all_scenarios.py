#!/usr/bin/env python3
"""
Master Test Runner for All Marketing Scenarios

This script runs all marketing experiment scenarios defined in scenario_config.py
and generates comprehensive results and summaries.

Usage:
    python3 run_all_scenarios.py                    # Run all scenarios
    python3 run_all_scenarios.py --priority         # Run only priority scenarios
    python3 run_all_scenarios.py --scenario price_low_25  # Run specific scenario
    python3 run_all_scenarios.py --type PRICE_VARIATION    # Run all scenarios of a type
"""

import sys
import argparse
import json
import time
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional
import pandas as pd

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))

from scenario_config import (
    get_all_scenarios, get_scenario_by_id, get_scenarios_by_type,
    get_priority_scenarios, ScenarioType, ScenarioConfig
)

# Import the experiment runner
from experiment_runner import run_scenario

# Create results directory structure
MASTER_RESULTS_DIR = Path(__file__).parent / 'results' / 'all_scenarios'
MASTER_RESULTS_DIR.mkdir(parents=True, exist_ok=True)

def run_single_scenario(config: ScenarioConfig) -> Dict:
    """
    Run a single scenario with the given configuration.
    
    Returns a dictionary with:
    - scenario_id: Scenario identifier
    - status: "success" or "error"
    - test1_results: Results from Test 1 (if applicable)
    - test2_results: Results from Test 2 (if applicable)
    - execution_time: Time taken to run
    - error: Error message if status is "error"
    """
    print("=" * 80)
    print(f"Running Scenario: {config.scenario_name}")
    print(f"ID: {config.scenario_id}")
    print(f"Description: {config.description}")
    print("=" * 80)
    print()
    
    start_time = time.time()
    results = {
        'scenario_id': config.scenario_id,
        'scenario_name': config.scenario_name,
        'scenario_type': config.scenario_type.value,
        'status': 'success',
        'execution_time': 0,
        'test1_results': None,
        'test2_results': None,
        'error': None
    }
    
    try:
        # Run the scenario using the experiment runner
        scenario_result = run_scenario(config)
        
        results['status'] = scenario_result['status']
        results['test1_results'] = scenario_result.get('statistics')
        results['results_dir'] = scenario_result.get('results_dir')
        results['execution_time'] = time.time() - start_time
        
        if results['status'] == 'success':
            print(f"✅ Scenario {config.scenario_id} completed successfully")
            stats = scenario_result.get('statistics', {})
            if 'improvements' in stats:
                improvements = stats['improvements']
                if 'net_profit_per_event' in improvements:
                    improvement_x = improvements['net_profit_per_event'].get('improvement_x', 0)
                    print(f"   Net Profit Improvement: {improvement_x:.2f}x")
        print()
        
    except Exception as e:
        results['status'] = 'error'
        results['error'] = str(e)
        results['execution_time'] = time.time() - start_time
        print(f"❌ Error running scenario {config.scenario_id}: {e}")
        print()
    
    return results

def run_scenarios(scenarios: List[ScenarioConfig], parallel: bool = False) -> List[Dict]:
    """
    Run multiple scenarios.
    
    Args:
        scenarios: List of scenario configurations to run
        parallel: If True, run scenarios in parallel (not implemented yet)
    
    Returns:
        List of result dictionaries
    """
    all_results = []
    total_scenarios = len(scenarios)
    
    print(f"🚀 Starting execution of {total_scenarios} scenarios")
    print(f"📁 Results will be saved to: {MASTER_RESULTS_DIR}")
    print()
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"[{i}/{total_scenarios}] ", end="")
        result = run_single_scenario(scenario)
        all_results.append(result)
        
        # Save intermediate results
        save_master_results(all_results)
    
    return all_results

def save_master_results(results: List[Dict], filename: str = "master_results.json"):
    """Save master results to JSON file"""
    results_path = MASTER_RESULTS_DIR / filename
    with open(results_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    print(f"💾 Master results saved to: {results_path}")

def generate_master_summary(results: List[Dict]) -> str:
    """Generate a master summary report of all scenarios"""
    summary_lines = [
        "# Master Summary: All Marketing Scenarios",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Scenarios:** {len(results)}",
        "",
        "---",
        "",
        "## Execution Summary",
        "",
        "| Scenario ID | Name | Type | Status | Time (s) |",
        "|-------------|------|------|--------|----------|"
    ]
    
    successful = 0
    errors = 0
    pending = 0
    total_time = 0
    
    for result in results:
        status = result.get('status', 'unknown')
        if status == 'success':
            successful += 1
        elif status == 'error':
            errors += 1
        elif status == 'pending_refactor':
            pending += 1
        
        total_time += result.get('execution_time', 0)
        
        summary_lines.append(
            f"| {result['scenario_id']} | {result['scenario_name']} | "
            f"{result.get('scenario_type', 'N/A')} | {status} | "
            f"{result.get('execution_time', 0):.2f} |"
        )
    
    summary_lines.extend([
        "",
        f"**Successful:** {successful}",
        f"**Errors:** {errors}",
        f"**Pending Refactor:** {pending}",
        f"**Total Execution Time:** {total_time:.2f} seconds",
        "",
        "---",
        "",
        "## Next Steps",
        "",
        "1. Refactor `run_spots_vs_traditional_marketing.py` to accept `ScenarioConfig`",
        "2. Implement scenario-specific logic for each scenario type",
        "3. Run all scenarios and collect results",
        "4. Generate comparative analysis across all scenarios",
        ""
    ])
    
    return "\n".join(summary_lines)

def main():
    parser = argparse.ArgumentParser(
        description="Run all marketing experiment scenarios"
    )
    parser.add_argument(
        '--priority',
        action='store_true',
        help='Run only priority scenarios'
    )
    parser.add_argument(
        '--scenario',
        type=str,
        help='Run specific scenario by ID'
    )
    parser.add_argument(
        '--type',
        type=str,
        help='Run all scenarios of a specific type (e.g., PRICE_VARIATION)'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available scenarios'
    )
    
    args = parser.parse_args()
    
    # List scenarios
    if args.list:
        scenarios = get_all_scenarios()
        print(f"Available Scenarios ({len(scenarios)}):")
        print()
        for scenario in scenarios:
            print(f"  {scenario.scenario_id:30} - {scenario.scenario_name}")
        return
    
    # Determine which scenarios to run
    if args.scenario:
        scenario = get_scenario_by_id(args.scenario)
        if not scenario:
            print(f"❌ Scenario '{args.scenario}' not found")
            return
        scenarios = [scenario]
    elif args.type:
        try:
            scenario_type = ScenarioType[args.type]
            scenarios = get_scenarios_by_type(scenario_type)
        except KeyError:
            print(f"❌ Invalid scenario type: {args.type}")
            print(f"   Available types: {[t.name for t in ScenarioType]}")
            return
    elif args.priority:
        scenarios = get_priority_scenarios()
        print(f"🎯 Running {len(scenarios)} priority scenarios")
    else:
        scenarios = get_all_scenarios()
        print(f"🚀 Running all {len(scenarios)} scenarios")
    
    if not scenarios:
        print("❌ No scenarios to run")
        return
    
    print()
    
    # Run scenarios
    start_time = time.time()
    results = run_scenarios(scenarios)
    total_time = time.time() - start_time
    
    # Generate summary
    summary = generate_master_summary(results)
    summary_path = MASTER_RESULTS_DIR / "MASTER_SUMMARY.md"
    with open(summary_path, 'w') as f:
        f.write(summary)
    
    print()
    print("=" * 80)
    print("Master Execution Complete")
    print("=" * 80)
    print(f"Total scenarios run: {len(results)}")
    print(f"Total execution time: {total_time:.2f} seconds")
    print(f"Master summary: {summary_path}")
    print(f"Master results: {MASTER_RESULTS_DIR / 'master_results.json'}")
    print()

if __name__ == '__main__':
    main()

