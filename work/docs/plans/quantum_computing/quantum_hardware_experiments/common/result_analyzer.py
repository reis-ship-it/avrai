"""
Result Analyzer for AVRAI Quantum Experiments

Analyzes and compares quantum hardware results with classical calculations.
Generates reports and visualizations for validation.

Purpose:
- Compare quantum vs classical results
- Calculate correlation and error metrics
- Generate reports for documentation
- Create visualizations for presentations
"""

import json
import numpy as np
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def analyze_results(results: Dict) -> Dict:
    """
    Analyze experiment results and generate metrics.
    
    Args:
        results: Dict with experiment results
    
    Returns:
        Analysis metrics including correlation, errors, pass/fail status
    """
    analysis = {
        'timestamp': datetime.now().isoformat(),
        'experiments': {},
        'summary': {},
    }
    
    passed = 0
    total = 0
    correlations = []
    differences = []
    
    for exp_id, exp_result in results.items():
        if exp_id in ['summary', 'metadata']:
            continue
        
        total += 1
        exp_analysis = _analyze_single_experiment(exp_id, exp_result)
        analysis['experiments'][exp_id] = exp_analysis
        
        if exp_analysis.get('passed', False):
            passed += 1
        
        if 'correlation' in exp_analysis:
            correlations.append(exp_analysis['correlation'])
        if 'difference' in exp_analysis:
            differences.append(exp_analysis['difference'])
    
    # Summary metrics
    analysis['summary'] = {
        'total_experiments': total,
        'passed': passed,
        'failed': total - passed,
        'pass_rate': passed / total if total > 0 else 0,
        'avg_correlation': np.mean(correlations) if correlations else None,
        'avg_difference': np.mean(differences) if differences else None,
        'max_difference': max(differences) if differences else None,
    }
    
    return analysis


def _analyze_single_experiment(exp_id: str, result: Dict) -> Dict:
    """Analyze a single experiment result."""
    analysis = {
        'experiment_id': exp_id,
        'has_quantum_result': 'quantum_result' in result or 'quantum_fidelity' in result,
        'has_classical_result': 'classical_result' in result or 'classical_fidelity' in result,
    }
    
    # Extract quantum and classical values
    quantum_val = (
        result.get('quantum_result') or 
        result.get('quantum_fidelity') or
        result.get('quantum_similarity') or
        result.get('quantum_jones_real')
    )
    
    classical_val = (
        result.get('classical_result') or 
        result.get('classical_fidelity') or
        result.get('classical_similarity') or
        result.get('classical_jones')
    )
    
    if quantum_val is not None and classical_val is not None:
        if isinstance(classical_val, list):
            classical_val = classical_val[0] if classical_val else 0
        
        analysis['quantum_value'] = float(quantum_val)
        analysis['classical_value'] = float(classical_val)
        analysis['difference'] = abs(float(quantum_val) - float(classical_val))
        analysis['relative_error'] = (
            analysis['difference'] / abs(float(classical_val)) 
            if classical_val != 0 else 0
        )
    
    # Determine pass/fail based on experiment type
    analysis['passed'] = _check_pass_criteria(exp_id, result, analysis)
    
    return analysis


def _check_pass_criteria(exp_id: str, result: Dict, analysis: Dict) -> bool:
    """Check if experiment passed based on success criteria."""
    
    # SWAP test: difference < 0.05
    if 'swap_test' in exp_id:
        diff = analysis.get('difference', 1.0)
        return diff < 0.05
    
    # Entanglement: entropy indicates entanglement
    if 'entanglement' in exp_id:
        return result.get('is_entangled', False)
    
    # Grover: found correct match
    if 'grover' in exp_id:
        return result.get('found_match', False)
    
    # Polynomial: quantum matches classical sign
    if 'polynomial' in exp_id or 'jones' in exp_id:
        q = analysis.get('quantum_value', 0)
        c = analysis.get('classical_value', 0)
        if isinstance(c, list):
            c = c[0] if c else 0
        # Same sign or both near zero
        return (q * c >= 0) or (abs(q) < 0.1 and abs(c) < 0.1)
    
    # Default: difference < 0.1
    return analysis.get('difference', 1.0) < 0.1


def compare_quantum_classical(
    quantum_results: List[float],
    classical_results: List[float]
) -> Dict:
    """
    Compare lists of quantum and classical results.
    
    Args:
        quantum_results: List of quantum measurement values
        classical_results: List of corresponding classical values
    
    Returns:
        Comparison metrics
    """
    if len(quantum_results) != len(classical_results):
        raise ValueError("Result lists must have same length")
    
    n = len(quantum_results)
    if n == 0:
        return {'error': 'No results to compare'}
    
    q = np.array(quantum_results)
    c = np.array(classical_results)
    
    # Correlation coefficient
    if np.std(q) > 0 and np.std(c) > 0:
        correlation = np.corrcoef(q, c)[0, 1]
    else:
        correlation = 1.0 if np.allclose(q, c) else 0.0
    
    # Error metrics
    differences = np.abs(q - c)
    relative_errors = np.abs((q - c) / np.where(c != 0, c, 1))
    
    return {
        'n_samples': n,
        'correlation': float(correlation),
        'mean_difference': float(np.mean(differences)),
        'std_difference': float(np.std(differences)),
        'max_difference': float(np.max(differences)),
        'mean_relative_error': float(np.mean(relative_errors)),
        'rmse': float(np.sqrt(np.mean(differences ** 2))),
    }


def generate_report(analysis: Dict, output_path: Optional[str] = None) -> str:
    """
    Generate markdown report from analysis.
    
    Args:
        analysis: Analysis dict from analyze_results()
        output_path: Optional path to save report
    
    Returns:
        Markdown report string
    """
    report = []
    report.append("# AVRAI Quantum Hardware Validation Report")
    report.append(f"\n**Generated:** {analysis['timestamp']}")
    report.append("")
    
    # Summary
    summary = analysis.get('summary', {})
    report.append("## Summary")
    report.append("")
    report.append(f"- **Total Experiments:** {summary.get('total_experiments', 0)}")
    report.append(f"- **Passed:** {summary.get('passed', 0)}")
    report.append(f"- **Failed:** {summary.get('failed', 0)}")
    report.append(f"- **Pass Rate:** {summary.get('pass_rate', 0):.1%}")
    report.append("")
    
    if summary.get('avg_correlation'):
        report.append(f"- **Average Correlation:** {summary['avg_correlation']:.4f}")
    if summary.get('avg_difference'):
        report.append(f"- **Average Difference:** {summary['avg_difference']:.4f}")
    report.append("")
    
    # Individual experiments
    report.append("## Experiment Results")
    report.append("")
    
    for exp_id, exp_result in analysis.get('experiments', {}).items():
        status = "✅ PASSED" if exp_result.get('passed') else "❌ FAILED"
        report.append(f"### {exp_id}")
        report.append(f"**Status:** {status}")
        report.append("")
        
        if 'quantum_value' in exp_result:
            report.append(f"- Quantum: {exp_result['quantum_value']:.4f}")
        if 'classical_value' in exp_result:
            report.append(f"- Classical: {exp_result['classical_value']:.4f}")
        if 'difference' in exp_result:
            report.append(f"- Difference: {exp_result['difference']:.4f}")
        report.append("")
    
    # Conclusion
    report.append("## Conclusion")
    report.append("")
    
    pass_rate = summary.get('pass_rate', 0)
    if pass_rate >= 0.8:
        report.append("**VALIDATION SUCCESSFUL:** AVRAI's quantum-inspired algorithms are validated on real quantum hardware.")
    elif pass_rate >= 0.5:
        report.append("**PARTIAL VALIDATION:** Some experiments passed. Further investigation needed for failed experiments.")
    else:
        report.append("**VALIDATION INCOMPLETE:** Most experiments did not meet success criteria. Review quantum circuit implementations.")
    
    report_str = "\n".join(report)
    
    if output_path:
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            f.write(report_str)
    
    return report_str


def plot_comparison(
    results: Dict,
    output_path: Optional[str] = None,
    show: bool = False
) -> None:
    """
    Create visualization comparing quantum vs classical results.
    
    Args:
        results: Results dict from experiments
        output_path: Optional path to save figure
        show: Whether to display figure
    """
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not installed. Run: pip install matplotlib")
        return
    
    # Extract quantum and classical values
    experiments = []
    quantum_vals = []
    classical_vals = []
    
    for exp_id, exp_result in results.items():
        if exp_id in ['summary', 'metadata']:
            continue
        
        q = (
            exp_result.get('quantum_result') or 
            exp_result.get('quantum_fidelity') or
            exp_result.get('quantum_similarity')
        )
        c = (
            exp_result.get('classical_result') or 
            exp_result.get('classical_fidelity') or
            exp_result.get('classical_similarity')
        )
        
        if q is not None and c is not None:
            experiments.append(exp_id.replace('_', '\n'))
            quantum_vals.append(float(q))
            if isinstance(c, list):
                c = c[0] if c else 0
            classical_vals.append(float(c))
    
    if not experiments:
        print("No comparable results to plot")
        return
    
    # Create figure
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    
    # Bar chart comparison
    x = np.arange(len(experiments))
    width = 0.35
    
    axes[0].bar(x - width/2, quantum_vals, width, label='Quantum', color='#1f77b4')
    axes[0].bar(x + width/2, classical_vals, width, label='Classical', color='#ff7f0e')
    axes[0].set_xlabel('Experiment')
    axes[0].set_ylabel('Value')
    axes[0].set_title('Quantum vs Classical Results')
    axes[0].set_xticks(x)
    axes[0].set_xticklabels(experiments, fontsize=8)
    axes[0].legend()
    axes[0].grid(axis='y', alpha=0.3)
    
    # Scatter plot with ideal line
    axes[1].scatter(classical_vals, quantum_vals, s=100, alpha=0.7, c='#2ca02c')
    
    # Add ideal line (y = x)
    min_val = min(min(quantum_vals), min(classical_vals))
    max_val = max(max(quantum_vals), max(classical_vals))
    axes[1].plot([min_val, max_val], [min_val, max_val], 'r--', label='Ideal (y=x)')
    
    # Calculate and display correlation
    if len(quantum_vals) > 1:
        corr = np.corrcoef(quantum_vals, classical_vals)[0, 1]
        axes[1].text(0.05, 0.95, f'Correlation: {corr:.3f}', 
                    transform=axes[1].transAxes, fontsize=12,
                    verticalalignment='top', bbox=dict(boxstyle='round', facecolor='wheat'))
    
    axes[1].set_xlabel('Classical Value')
    axes[1].set_ylabel('Quantum Value')
    axes[1].set_title('Quantum vs Classical Correlation')
    axes[1].legend()
    axes[1].grid(alpha=0.3)
    
    plt.tight_layout()
    
    if output_path:
        Path(output_path).parent.mkdir(parents=True, exist_ok=True)
        plt.savefig(output_path, dpi=150, bbox_inches='tight')
        print(f"Figure saved to {output_path}")
    
    if show:
        plt.show()
    
    plt.close()


def save_results(results: Dict, output_path: str) -> None:
    """Save results to JSON file."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2, default=str)
    
    print(f"Results saved to {output_path}")


def load_results(input_path: str) -> Dict:
    """Load results from JSON file."""
    with open(input_path, 'r') as f:
        return json.load(f)
