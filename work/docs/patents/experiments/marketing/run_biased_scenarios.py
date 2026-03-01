#!/usr/bin/env python3
"""
Run Biased Traditional Marketing Scenarios

This script runs scenarios that are biased towards traditional marketing
to test SPOTS' performance under adverse conditions.

Usage:
    python3 run_biased_scenarios.py                    # Run all biased scenarios
    python3 run_biased_scenarios.py --scenario biased_high_budget_10k  # Run specific
"""

import sys
import argparse
import json
import time
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent))

from scenario_config_biased_traditional import (
    get_biased_scenarios, get_scenario_by_id, ScenarioType, ScenarioConfig
)

# Import the experiment runner
from experiment_runner import ExperimentRunner, run_scenario

# Create results directory structure
BIASED_RESULTS_DIR = Path(__file__).parent / 'results' / 'biased_traditional'
BIASED_RESULTS_DIR.mkdir(parents=True, exist_ok=True)

def run_biased_scenario(config: ScenarioConfig) -> Dict:
    """
    Run a single biased scenario with modifications to favor traditional marketing.
    
    For outspend scenarios, we need to give traditional more budget.
    """
    print("=" * 80)
    print(f"Running Biased Scenario: {config.scenario_name}")
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
        'error': None
    }
    
    try:
        # For outspend scenarios, we need to modify the experiment runner
        # to give traditional more budget. For now, we'll use the config as-is
        # and note that traditional gets the full budget while SPOTS uses its normal budget
        
        # Create a modified config for outspend scenarios
        if 'outspend' in config.scenario_id:
            print(f"⚠️  Note: Traditional marketing gets ${config.marketing_budget:,.0f} budget")
            print(f"   SPOTS uses standard budget (will be handled in experiment runner)")
            print()
        
        # Run the scenario
        scenario_result = run_scenario(config)
        
        results['status'] = scenario_result['status']
        results['test1_results'] = scenario_result.get('statistics')
        results['results_dir'] = scenario_result.get('results_dir')
        results['execution_time'] = time.time() - start_time
        
        if results['status'] == 'success':
            print(f"✅ Biased scenario {config.scenario_id} completed successfully")
            stats = scenario_result.get('statistics', {})
            if 'improvements' in stats:
                improvements = stats['improvements']
                if 'net_profit_per_event' in improvements:
                    improvement_x = improvements['net_profit_per_event'].get('improvement_x', 0)
                    control_roi = stats['control'].get('roi', 0)
                    test_roi = stats['test'].get('roi', 0)
                    print(f"   Net Profit Improvement: {improvement_x:.2f}x")
                    print(f"   ROI: Traditional {control_roi:.2f} vs SPOTS {test_roi:.2f}")
                    
                    # Highlight if traditional wins
                    if improvement_x < 1.0:
                        print(f"   ⚠️  TRADITIONAL WINS: {1/improvement_x:.2f}x better")
                    elif improvement_x < 1.5:
                        print(f"   ⚠️  CLOSE: SPOTS only {improvement_x:.2f}x better")
                    else:
                        print(f"   ✅ SPOTS WINS: {improvement_x:.2f}x better")
        print()
        
    except Exception as e:
        results['status'] = 'error'
        results['error'] = str(e)
        results['execution_time'] = time.time() - start_time
        print(f"❌ Error running biased scenario {config.scenario_id}: {e}")
        print()
    
    return results

def run_all_biased_scenarios() -> List[Dict]:
    """Run all biased scenarios"""
    scenarios = get_biased_scenarios()
    all_results = []
    total_scenarios = len(scenarios)
    
    print(f"🚀 Starting execution of {total_scenarios} biased scenarios")
    print(f"📁 Results will be saved to: {BIASED_RESULTS_DIR}")
    print(f"⚠️  These scenarios are BIASED TOWARDS TRADITIONAL MARKETING")
    print()
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"[{i}/{total_scenarios}] ", end="")
        result = run_biased_scenario(scenario)
        all_results.append(result)
        
        # Save intermediate results
        save_biased_results(all_results)
    
    return all_results

def save_biased_results(results: List[Dict], filename: str = "biased_results.json"):
    """Save biased scenario results to JSON file"""
    results_path = BIASED_RESULTS_DIR / filename
    with open(results_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)

def generate_biased_summary(results: List[Dict]) -> str:
    """Generate a summary report of all biased scenarios"""
    summary_lines = [
        "# Biased Traditional Marketing Scenarios - Results Summary",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Scenarios:** {len(results)}",
        f"**Purpose:** Test SPOTS performance when conditions favor traditional marketing",
        "",
        "---",
        "",
        "## Execution Summary",
        "",
        "| Scenario ID | Name | Type | Status | Time (s) | SPOTS Advantage |",
        "|-------------|------|------|--------|----------|-----------------|"
    ]
    
    successful = 0
    errors = 0
    total_time = 0
    spots_wins = 0
    traditional_wins = 0
    close_calls = 0
    
    for result in results:
        status = result.get('status', 'unknown')
        if status == 'success':
            successful += 1
        elif status == 'error':
            errors += 1
        
        total_time += result.get('execution_time', 0)
        
        # Determine winner
        advantage = "N/A"
        if result.get('test1_results') and 'improvements' in result['test1_results']:
            improvements = result['test1_results']['improvements']
            if 'net_profit_per_event' in improvements:
                improvement_x = improvements['net_profit_per_event'].get('improvement_x', 1.0)
                if improvement_x < 1.0:
                    advantage = f"❌ Traditional {1/improvement_x:.2f}x"
                    traditional_wins += 1
                elif improvement_x < 1.5:
                    advantage = f"⚠️  SPOTS {improvement_x:.2f}x (close)"
                    close_calls += 1
                else:
                    advantage = f"✅ SPOTS {improvement_x:.2f}x"
                    spots_wins += 1
        
        summary_lines.append(
            f"| {result['scenario_id']} | {result['scenario_name']} | "
            f"{result.get('scenario_type', 'N/A')} | {status} | "
            f"{result.get('execution_time', 0):.2f} | {advantage} |"
        )
    
    summary_lines.extend([
        "",
        f"**Successful:** {successful}",
        f"**Errors:** {errors}",
        f"**Total Execution Time:** {total_time:.2f} seconds",
        "",
        "## Results Summary",
        "",
        f"- **SPOTS Wins:** {spots_wins} scenarios",
        f"- **Traditional Wins:** {traditional_wins} scenarios",
        f"- **Close Calls (<1.5x):** {close_calls} scenarios",
        "",
        "---",
        "",
        "## Key Insights",
        "",
        "These scenarios test SPOTS under conditions that favor traditional marketing:",
        "- High budgets (traditional can outspend)",
        "- Mainstream events (broad reach works)",
        "- Established hosts (reputation matters)",
        "- Long lead times (traditional needs time)",
        "- Large markets (traditional can reach more)",
        "- Simple demographics (traditional targeting works)",
        "",
        "**Question:** Can SPOTS still compete or outperform when traditional has advantages?",
        ""
    ])
    
    return "\n".join(summary_lines)

def main():
    parser = argparse.ArgumentParser(
        description="Run biased traditional marketing scenarios"
    )
    parser.add_argument(
        '--scenario',
        type=str,
        help='Run specific scenario by ID'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available biased scenarios'
    )
    
    args = parser.parse_args()
    
    # List scenarios
    if args.list:
        scenarios = get_biased_scenarios()
        print(f"Available Biased Scenarios ({len(scenarios)}):")
        print()
        for scenario in scenarios:
            print(f"  {scenario.scenario_id:40} - {scenario.scenario_name}")
        return
    
    # Determine which scenarios to run
    if args.scenario:
        scenario = get_scenario_by_id(args.scenario)
        if not scenario:
            print(f"❌ Scenario '{args.scenario}' not found")
            return
        scenarios = [scenario]
    else:
        scenarios = get_biased_scenarios()
        print(f"🚀 Running all {len(scenarios)} biased scenarios")
    
    if not scenarios:
        print("❌ No scenarios to run")
        return
    
    print()
    
    # Run scenarios
    start_time = time.time()
    results = run_all_biased_scenarios()
    total_time = time.time() - start_time
    
    # Generate summary
    summary = generate_biased_summary(results)
    summary_path = BIASED_RESULTS_DIR / "BIASED_SCENARIOS_SUMMARY.md"
    with open(summary_path, 'w') as f:
        f.write(summary)
    
    print()
    print("=" * 80)
    print("Biased Scenarios Execution Complete")
    print("=" * 80)
    print(f"Total scenarios run: {len(results)}")
    print(f"Total execution time: {total_time:.2f} seconds")
    print(f"Summary: {summary_path}")
    print(f"Results: {BIASED_RESULTS_DIR / 'biased_results.json'}")
    print()

if __name__ == '__main__':
    main()

