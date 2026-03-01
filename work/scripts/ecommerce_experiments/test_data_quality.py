"""
E-Commerce Enrichment API - Data Quality Validation
Phase 21: E-Commerce Data Enrichment Integration POC
Validates data quality, privacy, and accuracy
"""

import sys
import os
import time
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ecommerce_experiment_base import ECommerceExperimentBase
import json


class DataQualityValidation(ECommerceExperimentBase):
    """Validate data quality and privacy"""
    
    def __init__(self, api_base_url: str, api_key: str):
        super().__init__(
            experiment_name="data_quality_validation",
            api_base_url=api_base_url,
            api_key=api_key,
            results_dir="results/data_quality"
        )
    
    def validate_privacy(self):
        """Validate that no personal data is exposed"""
        print("Validating privacy (no personal data exposure)...")
        
        test_request = {
            "user_segment": {
                "segment_id": "test_segment_privacy",
                "geographic_region": "san_francisco"
            },
            "product_context": {
                "category": "electronics"
            }
        }
        
        result = self.call_endpoint("real-world-behavior", test_request)
        
        if result.success and result.response_data:
            data = result.response_data.get('data', {})
            
            # Check for forbidden personal data fields
            forbidden_fields = ['email', 'name', 'phone', 'address', 'user_id', 'ssn', 'credit_card']
            found_forbidden = []
            
            def check_dict(d, path=""):
                for key, value in d.items():
                    current_path = f"{path}.{key}" if path else key
                    if any(field in key.lower() for field in forbidden_fields):
                        found_forbidden.append(current_path)
                    if isinstance(value, dict):
                        check_dict(value, current_path)
                    elif isinstance(value, list):
                        for i, item in enumerate(value):
                            if isinstance(item, dict):
                                check_dict(item, f"{current_path}[{i}]")
            
            check_dict(data)
            
            if found_forbidden:
                print(f"  ❌ Found forbidden fields: {found_forbidden}")
                return False
            else:
                print("  ✅ No personal data fields found")
                return True
        else:
            print(f"  ❌ Request failed: {result.error}")
            return False
    
    def validate_aggregation(self):
        """Validate that data is properly aggregated"""
        print("Validating data aggregation...")
        
        test_request = {
            "user_segment": {
                "segment_id": "test_segment_agg",
                "geographic_region": "san_francisco"
            },
            "product_quantum_state": {  # ✅ Required field for quantum-personality endpoint
                "category": "electronics",
                "style": "minimalist",
                "price": "premium",
                "attributes": {
                    "energy_level": 0.7,
                    "novelty": 0.8
                }
            }
        }
        
        result = self.call_endpoint("quantum-personality", test_request)
        
        if result.success and result.response_data:
            data = result.response_data.get('data', {})
            metadata = data.get('market_segment_metadata', {})
            
            # Check sample size
            sample_size = metadata.get('sample_size', 0)
            if sample_size >= 100:
                print(f"  ✅ Sample size sufficient: {sample_size}")
            else:
                print(f"  ⚠️  Sample size low: {sample_size} (minimum 100 recommended)")
            
            # Check that personality dimensions are aggregated (not individual)
            personality = data.get('personality_profile', {})
            dimensions = personality.get('12_dimensions', {})
            
            if dimensions:
                # Check that dimensions have statistical properties (mean, std_dev, percentiles)
                first_dim = list(dimensions.values())[0] if dimensions else {}
                if 'value' in first_dim and 'std_dev' in first_dim:
                    print("  ✅ Dimensions properly aggregated (mean, std_dev, percentiles)")
                    return True
                else:
                    print("  ❌ Dimensions not properly aggregated")
                    return False
            else:
                print("  ⚠️  No dimensions found")
                return False
        else:
            print(f"  ❌ Request failed: {result.error}")
            return False
    
    def validate_confidence_scores(self):
        """Validate confidence scores are reasonable"""
        print("Validating confidence scores...")
        
        test_request = {
            "user_segment": {
                "segment_id": "test_segment_conf",
                "geographic_region": "san_francisco"
            },
            "product_category": "electronics"
        }
        
        result = self.call_endpoint("community-influence", test_request)
        
        if result.success and result.response_data:
            data = result.response_data.get('data', {})
            
            # Collect all confidence scores
            confidence_scores = []
            
            def extract_confidence(d):
                if isinstance(d, dict):
                    if 'confidence' in d:
                        confidence_scores.append(d['confidence'])
                    for value in d.values():
                        extract_confidence(value)
                elif isinstance(d, list):
                    for item in d:
                        extract_confidence(item)
            
            extract_confidence(data)
            
            if confidence_scores:
                avg_confidence = sum(confidence_scores) / len(confidence_scores)
                min_confidence = min(confidence_scores)
                max_confidence = max(confidence_scores)
                
                print(f"  Confidence scores:")
                print(f"    Average: {avg_confidence:.3f}")
                print(f"    Range: {min_confidence:.3f} - {max_confidence:.3f}")
                
                if avg_confidence >= 0.75:
                    print("  ✅ Average confidence meets target (≥0.75)")
                else:
                    print(f"  ⚠️  Average confidence below target: {avg_confidence:.3f} < 0.75")
                
                if min_confidence >= 0.6:
                    print("  ✅ All confidence scores above minimum (≥0.6)")
                else:
                    print(f"  ⚠️  Some confidence scores below minimum: {min_confidence:.3f} < 0.6")
                
                return avg_confidence >= 0.75
            else:
                print("  ⚠️  No confidence scores found")
                return False
        else:
            print(f"  ❌ Request failed: {result.error}")
            return False
    
    def validate_data_freshness(self):
        """Validate data freshness"""
        print("Validating data freshness...")
        
        test_request = {
            "user_segment": {
                "segment_id": "test_segment_fresh",
                "geographic_region": "san_francisco"
            }
        }
        
        result = self.call_endpoint("real-world-behavior", test_request)
        
        if result.success and result.response_data:
            data = result.response_data.get('data', {})
            metadata = data.get('market_segment_metadata', {})
            
            freshness_str = metadata.get('data_freshness')
            if freshness_str:
                from datetime import datetime, timezone
                freshness = datetime.fromisoformat(freshness_str.replace('Z', '+00:00'))
                now = datetime.now(timezone.utc)
                age_hours = (now - freshness).total_seconds() / 3600
                
                print(f"  Data age: {age_hours:.1f} hours")
                
                if age_hours < 24:
                    print("  ✅ Data is fresh (< 24 hours)")
                    return True
                else:
                    print(f"  ⚠️  Data is stale: {age_hours:.1f} hours (target: < 24 hours)")
                    return False
            else:
                print("  ⚠️  No freshness timestamp found")
                return False
        else:
            print(f"  ❌ Request failed: {result.error}")
            return False
    
    def run_all_validations(self):
        """Run all data quality validations"""
        print(f"\n{'='*60}")
        print(f"Data Quality Validation")
        print(f"{'='*60}\n")
        
        results = {
            "privacy": self.validate_privacy(),
            "aggregation": self.validate_aggregation(),
            "confidence": self.validate_confidence_scores(),
            "freshness": self.validate_data_freshness(),
        }
        
        print(f"\n{'='*60}")
        print("Validation Summary")
        print(f"{'='*60}\n")
        
        all_passed = True
        for test_name, passed in results.items():
            status = "✅ PASS" if passed else "❌ FAIL"
            print(f"{test_name.upper()}: {status}")
            if not passed:
                all_passed = False
        
        # Generate report
        report = self._generate_validation_report(results)
        report_path = os.path.join(self.results_dir, "VALIDATION_REPORT.md")
        with open(report_path, 'w') as f:
            f.write(report)
        
        print(f"\nReport saved to: {report_path}")
        print(f"\n{report}")
        
        return all_passed
    
    def _generate_validation_report(self, results: dict) -> str:
        """Generate validation report"""
        report = "# Data Quality Validation Report\n\n"
        report += f"**Date:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        report += "## Validation Results\n\n"
        report += "| Test | Status |\n"
        report += "|------|--------|\n"
        
        for test_name, passed in results.items():
            status = "✅ PASS" if passed else "❌ FAIL"
            report += f"| {test_name} | {status} |\n"
        
        report += "\n## Requirements\n\n"
        report += "- ✅ **Privacy:** No personal data fields exposed\n"
        report += "- ✅ **Aggregation:** Data properly aggregated (not individual)\n"
        report += "- ✅ **Confidence:** Average confidence ≥ 0.75\n"
        report += "- ✅ **Freshness:** Data age < 24 hours\n"
        
        all_passed = all(results.values())
        if all_passed:
            report += "\n## ✅ All Validations Passed\n"
        else:
            report += "\n## ⚠️ Some Validations Failed\n"
        
        return report


if __name__ == "__main__":
    import argparse
    import time
    
    parser = argparse.ArgumentParser(description="Validate e-commerce enrichment API data quality")
    parser.add_argument("--api-url", required=True, help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key")
    
    args = parser.parse_args()
    
    validator = DataQualityValidation(args.api_url, args.api_key)
    validator.run_all_validations()
