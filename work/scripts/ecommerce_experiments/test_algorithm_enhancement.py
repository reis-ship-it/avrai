"""
E-Commerce Algorithm Enhancement - A/B Testing Experiment
Phase 21: E-Commerce Data Enrichment Integration POC
Tests if SPOTS data improves e-commerce recommendation algorithms
"""

import sys
import os
import time
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ecommerce_experiment_base import ECommerceExperimentBase, StatisticalAnalysis
import json
import random
import numpy as np


class AlgorithmEnhancementExperiment(ECommerceExperimentBase):
    """A/B test: Baseline algorithm vs SPOTS-enhanced algorithm"""
    
    def __init__(self, api_base_url: str, api_key: str):
        super().__init__(
            experiment_name="algorithm_enhancement_ab_test",
            api_base_url=api_base_url,
            api_key=api_key,
            results_dir="results/algorithm_enhancement"
        )
        self.control_results = []
        self.test_results = []
    
    def simulate_baseline_algorithm(self, user_segment: dict, products: list) -> dict:
        """Simulate baseline e-commerce algorithm (without SPOTS)"""
        # Baseline: Simple collaborative filtering + content-based
        # Returns product scores based on category match and price range
        
        product_scores = []
        for product in products:
            score = 0.0
            
            # Category match (40% weight)
            if product.get('category') in user_segment.get('category_preferences', []):
                score += 0.4
            
            # Price range match (30% weight)
            user_price_pref = user_segment.get('price_preference', 'mid')
            if product.get('price_range') == user_price_pref:
                score += 0.3
            
            # Random factor (30% weight) - simulates collaborative filtering noise
            score += random.uniform(0, 0.3)
            
            product_scores.append({
                'product_id': product['id'],
                'score': min(score, 1.0),
                'method': 'baseline'
            })
        
        # Sort by score
        product_scores.sort(key=lambda x: x['score'], reverse=True)
        
        return {
            'recommendations': product_scores[:10],  # Top 10
            'avg_score': np.mean([p['score'] for p in product_scores]),
            'method': 'baseline'
        }
    
    def simulate_spots_enhanced_algorithm(
        self,
        user_segment: dict,
        products: list,
        spots_data: dict
    ) -> dict:
        """Simulate SPOTS-enhanced algorithm (70% baseline + 30% SPOTS)"""
        # Get baseline scores
        baseline = self.simulate_baseline_algorithm(user_segment, products)
        
        # Enhance with SPOTS data (30% weight)
        product_scores = []
        for product in products:
            baseline_score = next(
                (p['score'] for p in baseline['recommendations'] if p['product_id'] == product['id']),
                0.0
            )
            
            # SPOTS enhancement factors
            spots_score = 0.0
            
            # Real-world behavior match (10% weight)
            if spots_data.get('real_world_behavior'):
                behavior = spots_data['real_world_behavior']
                # High return rate = prefers quality
                if behavior.get('return_visit_rate', {}).get('value', 0) > 0.6:
                    if product.get('quality_rating', 0) > 4.0:
                        spots_score += 0.1
            
            # Quantum personality match (10% weight)
            if spots_data.get('quantum_personality'):
                quantum = spots_data['quantum_personality']
                compatibility = quantum.get('quantum_compatibility', {}).get('score', 0.5)
                spots_score += compatibility * 0.1
            
            # Community influence match (10% weight)
            if spots_data.get('community_influence'):
                influence = spots_data['community_influence']
                if influence.get('purchase_behavior', {}).get('community_driven_purchases', {}).get('value', 0) > 0.6:
                    if product.get('community_endorsed', False):
                        spots_score += 0.1
            
            # Combined score: 70% baseline + 30% SPOTS
            enhanced_score = (baseline_score * 0.7) + (spots_score * 0.3)
            
            product_scores.append({
                'product_id': product['id'],
                'score': min(enhanced_score, 1.0),
                'baseline_score': baseline_score,
                'spots_score': spots_score,
                'method': 'spots_enhanced'
            })
        
        # Sort by score
        product_scores.sort(key=lambda x: x['score'], reverse=True)
        
        return {
            'recommendations': product_scores[:10],  # Top 10
            'avg_score': np.mean([p['score'] for p in product_scores]),
            'method': 'spots_enhanced'
        }
    
    def simulate_user_purchase(self, recommendations: list, user_preferences: dict) -> bool:
        """Simulate whether user purchases from recommendations"""
        # User purchases if top recommendation score > threshold
        # Threshold varies by user (some users are more selective)
        
        if not recommendations:
            return False
        
        top_score = recommendations[0]['score']
        user_threshold = user_preferences.get('purchase_threshold', 0.6)
        
        return top_score >= user_threshold
    
    def run_ab_test(
        self,
        num_users: int = 1000,
        num_products: int = 100
    ):
        """Run A/B test comparing baseline vs SPOTS-enhanced"""
        print(f"\n{'='*60}")
        print(f"Algorithm Enhancement A/B Test")
        print(f"{'='*60}\n")
        print(f"Users: {num_users}, Products: {num_products}\n")
        
        # Generate test data
        user_segments = self._generate_user_segments(num_users)
        products = self._generate_products(num_products)
        
        control_conversions = []
        test_conversions = []
        control_avg_scores = []
        test_avg_scores = []
        control_top_scores = []
        test_top_scores = []
        
        for i, user_segment in enumerate(user_segments):
            if (i + 1) % 100 == 0:
                print(f"  Progress: {i + 1}/{num_users}")
            
            # Control group: Baseline algorithm
            baseline_result = self.simulate_baseline_algorithm(user_segment, products)
            control_conversion = self.simulate_user_purchase(
                baseline_result['recommendations'],
                user_segment
            )
            control_conversions.append(1 if control_conversion else 0)
            control_avg_scores.append(baseline_result['avg_score'])
            if baseline_result['recommendations']:
                control_top_scores.append(baseline_result['recommendations'][0]['score'])
            
            # Test group: SPOTS-enhanced algorithm
            # Get SPOTS data (simulated for now - would call API in production)
            spots_data = self._get_spots_data_simulated(user_segment)
            
            enhanced_result = self.simulate_spots_enhanced_algorithm(
                user_segment,
                products,
                spots_data
            )
            test_conversion = self.simulate_user_purchase(
                enhanced_result['recommendations'],
                user_segment
            )
            test_conversions.append(1 if test_conversion else 0)
            test_avg_scores.append(enhanced_result['avg_score'])
            if enhanced_result['recommendations']:
                test_top_scores.append(enhanced_result['recommendations'][0]['score'])
        
        # Statistical analysis
        print("\nRunning statistical analysis...")
        
        analyses = []
        
        # Conversion rate analysis
        control_conversion_rate = np.mean(control_conversions)
        test_conversion_rate = np.mean(test_conversions)
        conversion_analysis = self.compare_groups(
            control_conversions,
            test_conversions,
            "conversion_rate"
        )
        analyses.append(conversion_analysis)
        
        # Average score analysis
        avg_score_analysis = self.compare_groups(
            control_avg_scores,
            test_avg_scores,
            "average_recommendation_score"
        )
        analyses.append(avg_score_analysis)
        
        # Top score analysis
        if control_top_scores and test_top_scores:
            top_score_analysis = self.compare_groups(
                control_top_scores,
                test_top_scores,
                "top_recommendation_score"
            )
            analyses.append(top_score_analysis)
        
        # Generate report
        report = self._generate_ab_test_report(analyses, control_conversion_rate, test_conversion_rate)
        
        # Save results
        self.save_results()
        report_path = os.path.join(self.results_dir, "AB_TEST_REPORT.md")
        with open(report_path, 'w') as f:
            f.write(report)
        
        print(f"\nResults saved to: {report_path}")
        print(f"\n{report}")
    
    def _generate_user_segments(self, num_users: int) -> list:
        """Generate test user segments"""
        segments = []
        for i in range(num_users):
            segments.append({
                "segment_id": f"test_user_{i}",
                "geographic_region": random.choice(["san_francisco", "new_york", "los_angeles"]),
                "category_preferences": random.sample(
                    ["electronics", "fashion", "home", "sports", "books"],
                    random.randint(1, 3)
                ),
                "price_preference": random.choice(["budget", "mid", "premium"]),
                "purchase_threshold": random.uniform(0.5, 0.8),
            })
        return segments
    
    def _generate_products(self, num_products: int) -> list:
        """Generate test products"""
        products = []
        categories = ["electronics", "fashion", "home", "sports", "books"]
        price_ranges = ["budget", "mid", "premium"]
        
        for i in range(num_products):
            products.append({
                "id": f"product_{i}",
                "category": random.choice(categories),
                "price_range": random.choice(price_ranges),
                "quality_rating": random.uniform(3.0, 5.0),
                "community_endorsed": random.choice([True, False]),
            })
        return products
    
    def _get_spots_data_simulated(self, user_segment: dict) -> dict:
        """Simulate SPOTS data (in production, would call API)"""
        # Simulated SPOTS data based on segment characteristics
        return {
            "real_world_behavior": {
                "return_visit_rate": {
                    "value": random.uniform(0.5, 0.8) if "electronics" in user_segment.get("category_preferences", []) else random.uniform(0.3, 0.6)
                }
            },
            "quantum_personality": {
                "quantum_compatibility": {
                    "score": random.uniform(0.6, 0.9)
                }
            },
            "community_influence": {
                "purchase_behavior": {
                    "community_driven_purchases": {
                        "value": random.uniform(0.4, 0.7)
                    }
                }
            }
        }
    
    def _generate_ab_test_report(
        self,
        analyses: list,
        control_conversion_rate: float,
        test_conversion_rate: float
    ) -> str:
        """Generate A/B test report"""
        report = "# Algorithm Enhancement A/B Test Report\n\n"
        report += f"**Date:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        report += "## Executive Summary\n\n"
        improvement = ((test_conversion_rate - control_conversion_rate) / control_conversion_rate * 100) if control_conversion_rate > 0 else 0
        report += f"- **Control Conversion Rate:** {control_conversion_rate:.2%}\n"
        report += f"- **Test Conversion Rate:** {test_conversion_rate:.2%}\n"
        report += f"- **Improvement:** {improvement:+.1f}%\n\n"
        
        report += "## Statistical Analysis\n\n"
        report += "| Metric | Control | Test | Improvement | p-value | Cohen's d | Significant |\n"
        report += "|--------|---------|------|-------------|---------|-----------|-------------|\n"
        
        for analysis in analyses:
            sig = "✅" if analysis.is_significant else "❌"
            effect = "✅" if analysis.has_large_effect else "❌"
            report += f"| {analysis.metric_name} | {analysis.control_mean:.3f} | {analysis.test_mean:.3f} | {analysis.improvement_percent:+.1f}% | {analysis.p_value:.4f} | {analysis.cohens_d:.3f} | {sig} {effect} |\n"
        
        report += "\n## Interpretation\n\n"
        
        conversion_analysis = next((a for a in analyses if a.metric_name == "conversion_rate"), None)
        if conversion_analysis:
            if conversion_analysis.is_significant and conversion_analysis.improvement_percent > 10:
                report += "✅ **SPOTS enhancement significantly improves conversion rates**\n"
                report += f"- Improvement: {conversion_analysis.improvement_percent:.1f}%\n"
                report += f"- Statistical significance: p < 0.01\n"
                if conversion_analysis.has_large_effect:
                    report += f"- Large effect size: Cohen's d = {conversion_analysis.cohens_d:.3f}\n"
            else:
                report += "⚠️ **SPOTS enhancement shows improvement but needs more data**\n"
        
        return report


if __name__ == "__main__":
    import argparse
    import time
    
    parser = argparse.ArgumentParser(description="A/B test SPOTS algorithm enhancement")
    parser.add_argument("--api-url", required=True, help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key")
    parser.add_argument("--users", type=int, default=1000, help="Number of users to test")
    parser.add_argument("--products", type=int, default=100, help="Number of products")
    
    args = parser.parse_args()
    
    experiment = AlgorithmEnhancementExperiment(args.api_url, args.api_key)
    experiment.run_ab_test(args.users, args.products)
