"""
E-Commerce Enrichment API - Base Experiment Class
Phase 21: E-Commerce Data Enrichment Integration POC
Provides common functionality for all e-commerce experiments
"""

import json
import time
import csv
import os
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
import statistics
from scipy import stats
import numpy as np


@dataclass
class ExperimentResult:
    """Single experiment result"""
    test_id: str
    endpoint: str
    request_data: Dict[str, Any]
    response_data: Optional[Dict[str, Any]]
    success: bool
    processing_time_ms: float
    error: Optional[str] = None
    timestamp: str = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now().isoformat()


@dataclass
class StatisticalAnalysis:
    """Statistical analysis results"""
    metric_name: str
    control_mean: float
    test_mean: float
    control_std: float
    test_std: float
    improvement_percent: float
    p_value: float
    cohens_d: float
    is_significant: bool
    has_large_effect: bool
    confidence_interval_95: tuple


class ECommerceExperimentBase:
    """Base class for e-commerce enrichment experiments"""
    
    def __init__(
        self,
        experiment_name: str,
        api_base_url: str,
        api_key: str,
        results_dir: str = "results"
    ):
        self.experiment_name = experiment_name
        self.api_base_url = api_base_url.rstrip('/')
        self.api_key = api_key
        self.results_dir = results_dir
        self.results: List[ExperimentResult] = []
        
        # Create results directory
        os.makedirs(self.results_dir, exist_ok=True)
        
    def call_endpoint(
        self,
        endpoint: str,
        request_data: Dict[str, Any]
    ) -> ExperimentResult:
        """Call an API endpoint and return result"""
        import urllib.request
        import urllib.parse
        
        # Ensure URL is properly formatted
        base_url = self.api_base_url.rstrip('/')
        endpoint_clean = endpoint.lstrip('/')
        url = f"{base_url}/{endpoint_clean}"
        
        # Debug: print URL for troubleshooting
        # print(f"DEBUG: Calling URL: {url}")
        
        data = json.dumps(request_data).encode('utf-8')
        
        start_time = time.time()
        
        try:
            req = urllib.request.Request(
                url,
                data=data,
                headers={
                    'Authorization': f'Bearer {self.api_key}',
                    'Content-Type': 'application/json',
                },
                method='POST'
            )
            
            with urllib.request.urlopen(req, timeout=30) as response:
                response_data = json.loads(response.read().decode('utf-8'))
                processing_time = (time.time() - start_time) * 1000
                
                result = ExperimentResult(
                    test_id=f"{endpoint}_{len(self.results)}",
                    endpoint=endpoint,
                    request_data=request_data,
                    response_data=response_data,
                    success=response_data.get('success', False),
                    processing_time_ms=processing_time,
                )
                
                self.results.append(result)
                return result
                
        except Exception as e:
            processing_time = (time.time() - start_time) * 1000
            result = ExperimentResult(
                test_id=f"{endpoint}_{len(self.results)}",
                endpoint=endpoint,
                request_data=request_data,
                response_data=None,
                success=False,
                processing_time_ms=processing_time,
                error=str(e),
            )
            self.results.append(result)
            return result
    
    def compare_groups(
        self,
        control_results: List[float],
        test_results: List[float],
        metric_name: str
    ) -> StatisticalAnalysis:
        """Compare control and test groups statistically"""
        if len(control_results) == 0 or len(test_results) == 0:
            raise ValueError("Both groups must have results")
        
        control_mean = statistics.mean(control_results)
        test_mean = statistics.mean(test_results)
        control_std = statistics.stdev(control_results) if len(control_results) > 1 else 0
        test_std = statistics.stdev(test_results) if len(test_results) > 1 else 0
        
        improvement = ((test_mean - control_mean) / control_mean * 100) if control_mean > 0 else 0
        
        # T-test
        t_stat, p_value = stats.ttest_ind(test_results, control_results)
        
        # Cohen's d (effect size)
        pooled_std = np.sqrt(((len(control_results) - 1) * control_std**2 + 
                              (len(test_results) - 1) * test_std**2) / 
                             (len(control_results) + len(test_results) - 2))
        cohens_d = (test_mean - control_mean) / pooled_std if pooled_std > 0 else 0
        
        # Confidence interval (95%)
        se = pooled_std * np.sqrt(1/len(control_results) + 1/len(test_results))
        margin = 1.96 * se
        ci_lower = (test_mean - control_mean) - margin
        ci_upper = (test_mean - control_mean) + margin
        
        return StatisticalAnalysis(
            metric_name=metric_name,
            control_mean=control_mean,
            test_mean=test_mean,
            control_std=control_std,
            test_std=test_std,
            improvement_percent=improvement,
            p_value=p_value,
            cohens_d=cohens_d,
            is_significant=p_value < 0.01,
            has_large_effect=abs(cohens_d) > 1.0,
            confidence_interval_95=(ci_lower, ci_upper),
        )
    
    def save_results(self, filename: str = None):
        """Save results to CSV and JSON"""
        if filename is None:
            filename = f"{self.experiment_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        
        # Save CSV
        csv_path = os.path.join(self.results_dir, f"{filename}.csv")
        with open(csv_path, 'w', newline='') as f:
            if self.results:
                writer = csv.DictWriter(f, fieldnames=self.results[0].__dict__.keys())
                writer.writeheader()
                for result in self.results:
                    writer.writerow(asdict(result))
        
        # Save JSON
        json_path = os.path.join(self.results_dir, f"{filename}.json")
        with open(json_path, 'w') as f:
            json.dump([asdict(r) for r in self.results], f, indent=2)
        
        return csv_path, json_path
    
    def generate_summary(self, analyses: List[StatisticalAnalysis]) -> str:
        """Generate markdown summary report"""
        summary = f"# {self.experiment_name} - Experiment Summary\n\n"
        summary += f"**Date:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        summary += f"**Total Tests:** {len(self.results)}\n"
        summary += f"**Successful:** {sum(1 for r in self.results if r.success)}\n"
        summary += f"**Failed:** {sum(1 for r in self.results if not r.success)}\n\n"
        
        if analyses:
            summary += "## Statistical Analysis\n\n"
            summary += "| Metric | Control Mean | Test Mean | Improvement | p-value | Cohen's d | Significant |\n"
            summary += "|--------|--------------|-----------|-------------|---------|-----------|-------------|\n"
            
            for analysis in analyses:
                significance = "✅" if analysis.is_significant else "❌"
                summary += f"| {analysis.metric_name} | {analysis.control_mean:.3f} | {analysis.test_mean:.3f} | {analysis.improvement_percent:.1f}% | {analysis.p_value:.4f} | {analysis.cohens_d:.3f} | {significance} |\n"
        
        # Performance metrics
        if self.results:
            avg_processing_time = statistics.mean([r.processing_time_ms for r in self.results])
            summary += f"\n## Performance\n\n"
            summary += f"- **Average Processing Time:** {avg_processing_time:.2f}ms\n"
            summary += f"- **P95 Processing Time:** {np.percentile([r.processing_time_ms for r in self.results], 95):.2f}ms\n"
        
        return summary
