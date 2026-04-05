#!/usr/bin/env python3
"""
Run Aggressive/Untraditional Marketing Scenarios

This script runs scenarios testing SPOTS against aggressive, privacy-invasive,
and manipulative marketing techniques.

Usage:
    python3 run_aggressive_scenarios.py                    # Run all aggressive scenarios
    python3 run_aggressive_scenarios.py --scenario aggressive_data_harvesting  # Run specific
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

from scenario_config_aggressive_marketing import (
    get_aggressive_scenarios, get_scenario_by_id, ScenarioType, ScenarioConfig
)

# Import the experiment runner
from experiment_runner import run_scenario

# Create results directory structure
AGGRESSIVE_RESULTS_DIR = Path(__file__).parent / 'results' / 'aggressive_marketing'
AGGRESSIVE_RESULTS_DIR.mkdir(parents=True, exist_ok=True)

def run_aggressive_scenario(config: ScenarioConfig) -> Dict:
    """Run a single aggressive marketing scenario"""
    print("=" * 80)
    print(f"Running Aggressive Scenario: {config.scenario_name}")
    print(f"ID: {config.scenario_id}")
    print(f"Description: {config.description}")
    print("=" * 80)
    
    # List aggressive techniques being used
    techniques = []
    if config.aggressive_data_collection:
        techniques.append("Aggressive Data Collection")
    if config.privacy_invasive_tracking:
        techniques.append("Privacy-Invasive Tracking")
    if config.behavioral_manipulation:
        techniques.append("Behavioral Manipulation")
    if config.micro_targeting_enabled:
        techniques.append("Micro-Targeting")
    if config.cross_platform_tracking:
        techniques.append("Cross-Platform Tracking")
    if config.psychological_manipulation:
        techniques.append("Psychological Manipulation")
    if config.dark_patterns_enabled:
        techniques.append("Dark Patterns")
    
    if techniques:
        print(f"⚠️  Aggressive Techniques: {', '.join(techniques)}")
    print()
    
    start_time = time.time()
    results = {
        'scenario_id': config.scenario_id,
        'scenario_name': config.scenario_name,
        'scenario_type': config.scenario_type.value,
        'status': 'success',
        'execution_time': 0,
        'test1_results': None,
        'error': None,
        'aggressive_techniques': techniques
    }
    
    try:
        # Run the scenario
        scenario_result = run_scenario(config)
        
        results['status'] = scenario_result['status']
        results['test1_results'] = scenario_result.get('statistics')
        results['results_dir'] = scenario_result.get('results_dir')
        results['execution_time'] = time.time() - start_time
        
        if results['status'] == 'success':
            print(f"✅ Aggressive scenario {config.scenario_id} completed successfully")
            stats = scenario_result.get('statistics', {})
            if 'improvements' in stats:
                improvements = stats['improvements']
                if 'net_profit_per_event' in improvements:
                    improvement_x = improvements['net_profit_per_event'].get('improvement_x', 0)
                    control_roi = stats['control'].get('roi', 0)
                    test_roi = stats['test'].get('roi', 0)
                    print(f"   Net Profit Improvement: {improvement_x:.2f}x")
                    print(f"   ROI: Aggressive {control_roi:.2f} vs SPOTS {test_roi:.2f}")
                    
                    # Highlight results
                    if improvement_x < 1.0:
                        print(f"   ⚠️  AGGRESSIVE WINS: {1/improvement_x:.2f}x better")
                    elif improvement_x < 1.5:
                        print(f"   ⚠️  CLOSE: SPOTS only {improvement_x:.2f}x better")
                    else:
                        print(f"   ✅ SPOTS WINS: {improvement_x:.2f}x better (even against aggressive techniques)")
        print()
        
    except Exception as e:
        results['status'] = 'error'
        results['error'] = str(e)
        results['execution_time'] = time.time() - start_time
        print(f"❌ Error running aggressive scenario {config.scenario_id}: {e}")
        print()
    
    return results

def run_all_aggressive_scenarios() -> List[Dict]:
    """Run all aggressive marketing scenarios"""
    scenarios = get_aggressive_scenarios()
    all_results = []
    total_scenarios = len(scenarios)
    
    print(f"🚀 Starting execution of {total_scenarios} aggressive marketing scenarios")
    print(f"📁 Results will be saved to: {AGGRESSIVE_RESULTS_DIR}")
    print(f"⚠️  These scenarios test SPOTS against AGGRESSIVE/UNTRADITIONAL marketing techniques")
    print()
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"[{i}/{total_scenarios}] ", end="")
        result = run_aggressive_scenario(scenario)
        all_results.append(result)
        
        # Save intermediate results
        save_aggressive_results(all_results)
    
    return all_results

def save_aggressive_results(results: List[Dict], filename: str = "aggressive_results.json"):
    """Save aggressive scenario results to JSON file"""
    results_path = AGGRESSIVE_RESULTS_DIR / filename
    with open(results_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)

def generate_aggressive_summary(results: List[Dict]) -> str:
    """Generate a summary report of all aggressive scenarios"""
    summary_lines = [
        "# Aggressive/Untraditional Marketing Scenarios - Results Summary",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Scenarios:** {len(results)}",
        f"**Purpose:** Test SPOTS performance against aggressive, privacy-invasive, and manipulative marketing",
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
    aggressive_wins = 0
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
                    advantage = f"❌ Aggressive {1/improvement_x:.2f}x"
                    aggressive_wins += 1
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
        f"- **Aggressive Marketing Wins:** {aggressive_wins} scenarios",
        f"- **Close Calls (<1.5x):** {close_calls} scenarios",
        "",
        "---",
        "",
        "## Key Insights",
        "",
        "These scenarios test SPOTS against aggressive marketing techniques:",
        "- Data harvesting and extensive user profiling",
        "- Privacy-invasive tracking (cookies, fingerprinting, cross-platform)",
        "- Behavioral manipulation (dark patterns, FOMO, scarcity)",
        "- Micro-targeting with extensive user data",
        "- Psychological manipulation (social proof, price anchoring)",
        "",
        "**Question:** Can SPOTS still outperform even when competitors use aggressive, privacy-invasive, or manipulative techniques?",
        ""
    ])
    
    return "\n".join(summary_lines)

def main():
    parser = argparse.ArgumentParser(
        description="Run aggressive/untraditional marketing scenarios"
    )
    parser.add_argument(
        '--scenario',
        type=str,
        help='Run specific scenario by ID'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available aggressive scenarios'
    )
    
    args = parser.parse_args()
    
    # List scenarios
    if args.list:
        scenarios = get_aggressive_scenarios()
        print(f"Available Aggressive Marketing Scenarios ({len(scenarios)}):")
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
        scenarios = get_aggressive_scenarios()
        print(f"🚀 Running all {len(scenarios)} aggressive marketing scenarios")
    
    if not scenarios:
        print("❌ No scenarios to run")
        return
    
    print()
    
    # Run scenarios
    start_time = time.time()
    results = run_all_aggressive_scenarios()
    total_time = time.time() - start_time
    
    # Generate summary
    summary = generate_aggressive_summary(results)
    summary_path = AGGRESSIVE_RESULTS_DIR / "AGGRESSIVE_SCENARIOS_SUMMARY.md"
    with open(summary_path, 'w') as f:
        f.write(summary)
    
    print()
    print("=" * 80)
    print("Aggressive Marketing Scenarios Execution Complete")
    print("=" * 80)
    print(f"Total scenarios run: {len(results)}")
    print(f"Total execution time: {total_time:.2f} seconds")
    print(f"Summary: {summary_path}")
    print(f"Results: {AGGRESSIVE_RESULTS_DIR / 'aggressive_results.json'}")
    print()

if __name__ == '__main__':
    main()

