#!/usr/bin/env python3
"""
Time-Interval Experiment Runner - All Patents

Runs all experiments for multiple time intervals:
- 6 months
- 1 year (12 months)
- 2 years (24 months)
- 5 years (60 months)
- 10 years (120 months)

Date: December 19, 2025
"""

import sys
import time
from pathlib import Path
from datetime import datetime
import json

# Add scripts directory to path
SCRIPTS_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPTS_DIR))

# Import individual experiment modules
try:
    from run_patent_1_experiments import run_patent_1_experiments
    from run_patent_3_experiments import run_patent_3_experiments
    from run_patent_21_experiments import run_patent_21_experiments
    from run_patent_29_experiments import run_patent_29_experiments
except ImportError as e:
    print(f"⚠️  Warning: Some experiment modules not found: {e}")
    sys.exit(1)

# Time intervals in months
TIME_INTERVALS = {
    '6_months': 6,
    '1_year': 12,
    '2_years': 24,
    '5_years': 60,
    '10_years': 120
}

# Logging directory
LOGS_DIR = Path(__file__).parent.parent / 'logs'
LOGS_DIR.mkdir(parents=True, exist_ok=True)


def create_time_interval_log(interval_name, num_months):
    """Create a log file for a specific time interval."""
    log_file = LOGS_DIR / f'time_interval_{interval_name}.md'
    
    log_content = f"""# Time Interval Experiment Log: {interval_name.replace('_', ' ').title()}

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Time Interval:** {num_months} months ({interval_name.replace('_', ' ').title()})  
**Status:** In Progress

---

## 📊 **Experiment Summary**

**Time Period:** {num_months} months  
**Start Time:** [Will be filled]  
**End Time:** [Will be filled]  
**Total Duration:** [Will be filled]

---

## 🔬 **Patent Experiments**

### **Patent #1: Quantum Compatibility Calculation**
- **Time-Dependent:** No (runs once)
- **Status:** [Will be filled]
- **Duration:** [Will be filled]
- **Results:** [Will be filled]

### **Patent #3: Contextual Personality System**
- **Time-Dependent:** Yes (uses {num_months} months)
- **Status:** [Will be filled]
- **Duration:** [Will be filled]
- **Results:** [Will be filled]

### **Patent #21: Offline Quantum Matching**
- **Time-Dependent:** No (runs once)
- **Status:** [Will be filled]
- **Duration:** [Will be filled]
- **Results:** [Will be filled]

### **Patent #29: Multi-Entity Quantum Entanglement Matching**
- **Time-Dependent:** No (runs once)
- **Status:** [Will be filled]
- **Duration:** [Will be filled]
- **Results:** [Will be filled]

---

## 📈 **Results Summary**

### **Key Metrics by Patent**

**Patent #1:**
- [Results will be filled]

**Patent #3 ({num_months} months):**
- [Results will be filled]

**Patent #21:**
- [Results will be filled]

**Patent #29:**
- [Results will be filled]

---

## ✅ **Completion Status**

- [ ] Patent #1 experiments complete
- [ ] Patent #3 experiments complete ({num_months} months)
- [ ] Patent #21 experiments complete
- [ ] Patent #29 experiments complete
- [ ] All results logged
- [ ] Summary generated

---

**Last Updated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
    
    with open(log_file, 'w') as f:
        f.write(log_content)
    
    return log_file


def update_time_interval_log(log_file, patent_num, status, duration, results_summary):
    """Update the time interval log with results."""
    with open(log_file, 'r') as f:
        content = f.read()
    
    # Update patent section
    patent_section = f"### **Patent #{patent_num}:"
    if patent_section in content:
        # Find and update the status, duration, and results
        lines = content.split('\n')
        updated_lines = []
        in_patent_section = False
        
        for i, line in enumerate(lines):
            if f"### **Patent #{patent_num}:" in line:
                in_patent_section = True
                updated_lines.append(line)
            elif in_patent_section and line.startswith('### **Patent #'):
                in_patent_section = False
                updated_lines.append(line)
            elif in_patent_section and '- **Status:**' in line:
                updated_lines.append(f"- **Status:** {status}")
            elif in_patent_section and '- **Duration:**' in line:
                updated_lines.append(f"- **Duration:** {duration:.2f} seconds")
            elif in_patent_section and '- **Results:**' in line:
                updated_lines.append(f"- **Results:** {results_summary}")
            else:
                updated_lines.append(line)
        
        content = '\n'.join(updated_lines)
    
    # Update last updated timestamp
    content = content.replace(
        f"**Last Updated:** {content.split('**Last Updated:**')[-1].split('\\n')[0] if '**Last Updated:**' in content else ''}",
        f"**Last Updated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    )
    
    with open(log_file, 'w') as f:
        f.write(content)


def run_experiments_for_interval(interval_name, num_months):
    """Run all experiments for a specific time interval."""
    print("=" * 70)
    print(f"TIME INTERVAL: {interval_name.replace('_', ' ').title()} ({num_months} months)")
    print("=" * 70)
    print()
    
    # Create log file
    log_file = create_time_interval_log(interval_name, num_months)
    
    overall_start = time.time()
    results_summary = {}
    
    # Run Patent #1 (not time-dependent, but run for consistency)
    print("🔬 Running Patent #1 Experiments...")
    print("-" * 70)
    try:
        start_time = time.time()
        run_patent_1_experiments()
        duration = time.time() - start_time
        status = "✅ Complete"
        results_summary['patent_1'] = f"Complete in {duration:.2f}s"
        update_time_interval_log(log_file, 1, status, duration, f"Complete - {duration:.2f}s")
        print(f"✅ Patent #1 completed in {duration:.2f} seconds")
    except Exception as e:
        status = f"❌ Failed: {e}"
        results_summary['patent_1'] = f"Failed: {str(e)}"
        print(f"❌ Patent #1 failed: {e}")
    print()
    
    # Run Patent #3 (time-dependent)
    print(f"🔬 Running Patent #3 Experiments ({num_months} months)...")
    print("-" * 70)
    try:
        start_time = time.time()
        run_patent_3_experiments(num_months=num_months)
        duration = time.time() - start_time
        status = "✅ Complete"
        results_summary['patent_3'] = f"Complete in {duration:.2f}s ({num_months} months)"
        update_time_interval_log(log_file, 3, status, duration, f"Complete - {duration:.2f}s ({num_months} months)")
        print(f"✅ Patent #3 ({num_months} months) completed in {duration:.2f} seconds")
    except Exception as e:
        status = f"❌ Failed: {e}"
        results_summary['patent_3'] = f"Failed: {str(e)}"
        print(f"❌ Patent #3 failed: {e}")
    print()
    
    # Run Patent #21 (not time-dependent)
    print("🔬 Running Patent #21 Experiments...")
    print("-" * 70)
    try:
        start_time = time.time()
        run_patent_21_experiments()
        duration = time.time() - start_time
        status = "✅ Complete"
        results_summary['patent_21'] = f"Complete in {duration:.2f}s"
        update_time_interval_log(log_file, 21, status, duration, f"Complete - {duration:.2f}s")
        print(f"✅ Patent #21 completed in {duration:.2f} seconds")
    except Exception as e:
        status = f"❌ Failed: {e}"
        results_summary['patent_21'] = f"Failed: {str(e)}"
        print(f"❌ Patent #21 failed: {e}")
    print()
    
    # Run Patent #29 (not time-dependent)
    print("🔬 Running Patent #29 Experiments...")
    print("-" * 70)
    try:
        start_time = time.time()
        run_patent_29_experiments()
        duration = time.time() - start_time
        status = "✅ Complete"
        results_summary['patent_29'] = f"Complete in {duration:.2f}s"
        update_time_interval_log(log_file, 29, status, duration, f"Complete - {duration:.2f}s")
        print(f"✅ Patent #29 completed in {duration:.2f} seconds")
    except Exception as e:
        status = f"❌ Failed: {e}"
        results_summary['patent_29'] = f"Failed: {str(e)}"
        print(f"❌ Patent #29 failed: {e}")
    print()
    
    overall_duration = time.time() - overall_start
    
    print("=" * 70)
    print(f"✅ {interval_name.replace('_', ' ').title()} ({num_months} months) COMPLETE")
    print("=" * 70)
    print(f"Total Duration: {overall_duration:.2f} seconds ({overall_duration/60:.2f} minutes)")
    print()
    
    return results_summary, overall_duration


def main():
    """Run all experiments for all time intervals."""
    print("=" * 70)
    print("TIME-INTERVAL EXPERIMENT RUNNER")
    print("=" * 70)
    print()
    print("Running all experiments for:")
    for name, months in TIME_INTERVALS.items():
        print(f"  - {name.replace('_', ' ').title()}: {months} months")
    print()
    print("=" * 70)
    print()
    
    master_start = time.time()
    all_results = {}
    
    # Run for each time interval
    for interval_name, num_months in TIME_INTERVALS.items():
        results, duration = run_experiments_for_interval(interval_name, num_months)
        all_results[interval_name] = {
            'months': num_months,
            'duration': duration,
            'results': results
        }
        print()
    
    master_duration = time.time() - master_start
    
    # Create master summary
    summary_file = LOGS_DIR / 'time_interval_master_summary.md'
    with open(summary_file, 'w') as f:
        f.write(f"""# Time Interval Experiments - Master Summary

**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}  
**Total Duration:** {master_duration:.2f} seconds ({master_duration/60:.2f} minutes)  
**Status:** ✅ Complete

---

## 📊 **Summary by Time Interval**

""")
        
        for interval_name, data in all_results.items():
            f.write(f"""### **{interval_name.replace('_', ' ').title()} ({data['months']} months)**
- **Duration:** {data['duration']:.2f} seconds ({data['duration']/60:.2f} minutes)
- **Patent #1:** {data['results'].get('patent_1', 'N/A')}
- **Patent #3:** {data['results'].get('patent_3', 'N/A')}
- **Patent #21:** {data['results'].get('patent_21', 'N/A')}
- **Patent #29:** {data['results'].get('patent_29', 'N/A')}

""")
        
        f.write(f"""
---

## 📈 **Results Location**

All detailed results saved to:
- `docs/patents/experiments/results/patent_1/`
- `docs/patents/experiments/results/patent_3/` (with time interval suffixes)
- `docs/patents/experiments/results/patent_21/`
- `docs/patents/experiments/results/patent_29/`

Individual time interval logs:
- `docs/patents/experiments/logs/time_interval_6_months.md`
- `docs/patents/experiments/logs/time_interval_1_year.md`
- `docs/patents/experiments/logs/time_interval_2_years.md`
- `docs/patents/experiments/logs/time_interval_5_years.md`
- `docs/patents/experiments/logs/time_interval_10_years.md`

---

**Completed:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
""")
    
    print("=" * 70)
    print("✅ ALL TIME INTERVALS COMPLETE")
    print("=" * 70)
    print(f"Total Time: {master_duration:.2f} seconds ({master_duration/60:.2f} minutes)")
    print()
    print(f"📄 Master summary saved to: {summary_file}")
    print()


if __name__ == '__main__':
    main()

