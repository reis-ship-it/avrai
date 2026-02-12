#!/usr/bin/env python3
"""
Run Enterprise-Scale Marketing Test

Tests SPOTS vs Traditional marketing at enterprise scale:
- Millions of dollars in marketing budget
- 100,000+ users
- Large-scale event marketing

Usage:
    python3 run_enterprise_test.py                    # Run all enterprise scenarios
    python3 run_enterprise_test.py --scenario enterprise_millions_100k  # Run specific
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

from scenario_config_enterprise import (
    get_enterprise_scenarios, get_scenario_by_id, ScenarioType, ScenarioConfig
)

# Import the experiment runner
from experiment_runner import run_scenario

# Create results directory structure
ENTERPRISE_RESULTS_DIR = Path(__file__).parent / 'results' / 'enterprise_scale'
ENTERPRISE_RESULTS_DIR.mkdir(parents=True, exist_ok=True)

def run_enterprise_scenario(config: ScenarioConfig) -> Dict:
    """Run a single enterprise-scale scenario"""
    print("=" * 80)
    print(f"Running Enterprise Scenario: {config.scenario_name}")
    print(f"ID: {config.scenario_id}")
    print(f"Description: {config.description}")
    print("=" * 80)
    print()
    print(f"📊 Test Parameters:")
    print(f"   - Marketing Budget: ${config.marketing_budget:,.0f} per event")
    print(f"   - Users per Group: {config.num_users_per_group:,}")
    print(f"   - Events per Group: {config.num_events_per_group:,}")
    print(f"   - Ticket Price: ${config.ticket_price:.2f}")
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
        # Run the scenario
        scenario_result = run_scenario(config)
        
        results['status'] = scenario_result['status']
        results['test1_results'] = scenario_result.get('statistics')
        results['results_dir'] = scenario_result.get('results_dir')
        results['execution_time'] = time.time() - start_time
        
        if results['status'] == 'success':
            print(f"✅ Enterprise scenario {config.scenario_id} completed successfully")
            stats = scenario_result.get('statistics', {})
            if 'improvements' in stats:
                improvements = stats['improvements']
                control = stats.get('control', {})
                test = stats.get('test', {})
                
                if 'net_profit_per_event' in improvements:
                    improvement_x = improvements['net_profit_per_event'].get('improvement_x', 0)
                    control_roi = control.get('roi', 0)
                    test_roi = test.get('roi', 0)
                    control_profit = control.get('net_profit_per_event', 0)
                    test_profit = test.get('net_profit_per_event', 0)
                    
                    print(f"   Net Profit per Event:")
                    print(f"     Traditional: ${control_profit:,.2f}")
                    print(f"     SPOTS: ${test_profit:,.2f}")
                    print(f"     Improvement: {improvement_x:.2f}x")
                    print(f"   ROI:")
                    print(f"     Traditional: {control_roi:.2f}")
                    print(f"     SPOTS: {test_roi:.2f}")
                    print(f"     Improvement: {test_roi / control_roi if control_roi > 0 else 'N/A':.2f}x")
                    
                    # Total numbers
                    control_total = control.get('total_net_profit', 0)
                    test_total = test.get('total_net_profit', 0)
                    print(f"   Total Net Profit ({config.num_events_per_group:,} events):")
                    print(f"     Traditional: ${control_total:,.2f}")
                    print(f"     SPOTS: ${test_total:,.2f}")
                    print(f"     Improvement: {test_total / control_total if control_total > 0 else 'N/A':.2f}x")
                    
                    # Highlight winner
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
        print(f"❌ Error running enterprise scenario {config.scenario_id}: {e}")
        import traceback
        traceback.print_exc()
        print()
    
    return results

def run_all_enterprise_scenarios() -> List[Dict]:
    """Run all enterprise-scale scenarios"""
    scenarios = get_enterprise_scenarios()
    all_results = []
    total_scenarios = len(scenarios)
    
    print(f"🚀 Starting execution of {total_scenarios} enterprise-scale scenarios")
    print(f"📁 Results will be saved to: {ENTERPRISE_RESULTS_DIR}")
    print(f"💰 Testing with MILLIONS in marketing budget and 100,000+ users")
    print()
    
    for i, scenario in enumerate(scenarios, 1):
        print(f"[{i}/{total_scenarios}] ", end="")
        result = run_enterprise_scenario(scenario)
        all_results.append(result)
        
        # Save intermediate results
        save_enterprise_results(all_results)
    
    return all_results

def save_enterprise_results(results: List[Dict], filename: str = "enterprise_results.json"):
    """Save enterprise scenario results to JSON file"""
    results_path = ENTERPRISE_RESULTS_DIR / filename
    with open(results_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)

def generate_enterprise_summary(results: List[Dict]) -> str:
    """Generate a summary report of all enterprise scenarios"""
    summary_lines = [
        "# Enterprise-Scale Marketing Scenarios - Results Summary",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Total Scenarios:** {len(results)}",
        f"**Purpose:** Test SPOTS vs Traditional marketing at enterprise scale (millions in budget, 100k+ users)",
        "",
        "---",
        "",
        "## Execution Summary",
        "",
        "| Scenario ID | Name | Budget | Users | Events | Status | Time (s) | SPOTS Advantage |",
        "|-------------|------|--------|-------|--------|--------|----------|-----------------|"
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
        
        # Get scenario details
        scenario_id = result.get('scenario_id', 'unknown')
        scenario_name = result.get('scenario_name', 'Unknown')
        
        # Extract budget from scenario name or config
        budget_str = "N/A"
        if '2M' in scenario_name or '$2M' in scenario_name:
            budget_str = "$2M"
        elif '5M' in scenario_name or '$5M' in scenario_name:
            budget_str = "$5M"
        elif '10M' in scenario_name or '$10M' in scenario_name:
            budget_str = "$10M"
        
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
            f"| {scenario_id} | {scenario_name} | {budget_str} | 100k | 1k | {status} | "
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
        "These scenarios test SPOTS at enterprise scale:",
        "- Millions of dollars in marketing budget per event",
        "- 100,000+ users in the market",
        "- 1,000+ events to market",
        "",
        "**Question:** Can SPOTS maintain its advantage even at enterprise scale with massive budgets?",
        ""
    ])
    
    return "\n".join(summary_lines)

def main():
    parser = argparse.ArgumentParser(
        description="Run enterprise-scale marketing scenarios"
    )
    parser.add_argument(
        '--scenario',
        type=str,
        help='Run specific scenario by ID'
    )
    parser.add_argument(
        '--list',
        action='store_true',
        help='List all available enterprise scenarios'
    )
    
    args = parser.parse_args()
    
    # List scenarios
    if args.list:
        scenarios = get_enterprise_scenarios()
        print(f"Available Enterprise Scenarios ({len(scenarios)}):")
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
        scenarios = get_enterprise_scenarios()
        print(f"🚀 Running all {len(scenarios)} enterprise-scale scenarios")
    
    if not scenarios:
        print("❌ No scenarios to run")
        return
    
    print()
    
    # Run scenarios
    start_time = time.time()
    results = run_all_enterprise_scenarios()
    total_time = time.time() - start_time
    
    # Generate summary
    summary = generate_enterprise_summary(results)
    summary_path = ENTERPRISE_RESULTS_DIR / "ENTERPRISE_SCENARIOS_SUMMARY.md"
    with open(summary_path, 'w') as f:
        f.write(summary)
    
    print()
    print("=" * 80)
    print("Enterprise-Scale Scenarios Execution Complete")
    print("=" * 80)
    print(f"Total scenarios run: {len(results)}")
    print(f"Total execution time: {total_time:.2f} seconds ({total_time/60:.1f} minutes)")
    print(f"Summary: {summary_path}")
    print(f"Results: {ENTERPRISE_RESULTS_DIR / 'enterprise_results.json'}")
    print()

if __name__ == '__main__':
    main()

