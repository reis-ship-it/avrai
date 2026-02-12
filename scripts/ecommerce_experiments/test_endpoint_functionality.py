"""
E-Commerce Enrichment API - Endpoint Functionality Tests
Phase 21 Section 2: Core Endpoints
Tests all 3 endpoints for functionality and correctness
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from ecommerce_experiment_base import ECommerceExperimentBase, StatisticalAnalysis
import json
from datetime import datetime


class EndpointFunctionalityTest(ECommerceExperimentBase):
    """Test endpoint functionality and response correctness"""
    
    def __init__(self, api_base_url: str, api_key: str):
        super().__init__(
            experiment_name="endpoint_functionality_test",
            api_base_url=api_base_url,
            api_key=api_key,
            results_dir="results/endpoint_functionality"
        )
    
    def test_real_world_behavior_endpoint(self):
        """Test real-world behavior endpoint"""
        print("Testing real-world behavior endpoint...")
        
        test_cases = [
            {
                "name": "Basic segment request",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_1",
                        "geographic_region": "san_francisco",
                        "category_preferences": ["electronics"]
                    },
                    "product_context": {
                        "category": "electronics",
                        "price_range": "premium"
                    }
                }
            },
            {
                "name": "Full insights request",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_2",
                        "geographic_region": "new_york",
                        "category_preferences": ["fashion", "accessories"],
                        "demographics": {
                            "age_range": [25, 35],
                            "interests": ["technology", "fashion"]
                        }
                    },
                    "product_context": {
                        "category": "fashion",
                        "subcategory": "accessories",
                        "price_range": "mid"
                    },
                    "requested_insights": [
                        "dwell_time_patterns",
                        "return_visit_frequency",
                        "real_world_journey_mapping",
                        "community_engagement_levels"
                    ]
                }
            },
        ]
        
        for test_case in test_cases:
            print(f"  Running: {test_case['name']}")
            result = self.call_endpoint("real-world-behavior", test_case["request"])
            
            if result.success:
                print(f"    ✅ Success - {result.processing_time_ms:.2f}ms")
                # Validate response structure
                self._validate_real_world_behavior_response(result.response_data)
            else:
                print(f"    ❌ Failed: {result.error}")
    
    def test_quantum_personality_endpoint(self):
        """Test quantum personality endpoint"""
        print("Testing quantum personality endpoint...")
        
        test_cases = [
            {
                "name": "Basic quantum compatibility",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_1",
                        "geographic_region": "san_francisco"
                    },
                    "product_quantum_state": {
                        "category": "electronics",
                        "style": "minimalist",
                        "price": "premium",
                        "features": ["quality", "sustainability"],
                        "attributes": {
                            "energy_level": 0.7,
                            "novelty": 0.8,
                            "community_oriented": 0.6
                        }
                    }
                }
            },
            {
                "name": "Full quantum analysis",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_2",
                        "geographic_region": "new_york"
                    },
                    "product_quantum_state": {
                        "category": "fashion",
                        "style": "bold",
                        "price": "mid",
                        "features": ["trendy", "affordable"],
                        "attributes": {
                            "energy_level": 0.9,
                            "novelty": 0.7,
                            "community_oriented": 0.8
                        }
                    },
                    "requested_insights": [
                        "quantum_compatibility",
                        "personality_profile",
                        "knot_compatibility",
                        "dimension_breakdown"
                    ]
                }
            },
        ]
        
        for test_case in test_cases:
            print(f"  Running: {test_case['name']}")
            result = self.call_endpoint("quantum-personality", test_case["request"])
            
            if result.success:
                print(f"    ✅ Success - {result.processing_time_ms:.2f}ms")
                # Validate response structure
                self._validate_quantum_personality_response(result.response_data)
            else:
                print(f"    ❌ Failed: {result.error}")
    
    def test_community_influence_endpoint(self):
        """Test community influence endpoint"""
        print("Testing community influence endpoint...")
        
        test_cases = [
            {
                "name": "Basic influence analysis",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_1",
                        "geographic_region": "san_francisco"
                    },
                    "product_category": "electronics"
                }
            },
            {
                "name": "Full influence insights",
                "request": {
                    "user_segment": {
                        "segment_id": "test_segment_2",
                        "geographic_region": "new_york"
                    },
                    "product_category": "fashion",
                    "requested_insights": [
                        "influence_patterns",
                        "purchase_behavior",
                        "marketing_implications",
                        "viral_potential"
                    ]
                }
            },
        ]
        
        for test_case in test_cases:
            print(f"  Running: {test_case['name']}")
            result = self.call_endpoint("community-influence", test_case["request"])
            
            if result.success:
                print(f"    ✅ Success - {result.processing_time_ms:.2f}ms")
                # Validate response structure
                self._validate_community_influence_response(result.response_data)
            else:
                print(f"    ❌ Failed: {result.error}")
    
    def _validate_real_world_behavior_response(self, response: dict):
        """Validate real-world behavior response structure"""
        assert response.get('success') == True, "Response should be successful"
        assert 'data' in response, "Response should have data"
        
        data = response['data']
        assert 'real_world_behavior' in data, "Should have real_world_behavior"
        assert 'product_implications' in data, "Should have product_implications"
        assert 'market_segment_metadata' in data, "Should have market_segment_metadata"
        
        behavior = data['real_world_behavior']
        assert 'average_dwell_time' in behavior, "Should have average_dwell_time"
        assert 'return_visit_rate' in behavior, "Should have return_visit_rate"
        assert 'exploration_tendency' in behavior, "Should have exploration_tendency"
        
        print("    ✅ Response structure valid")
    
    def _validate_quantum_personality_response(self, response: dict):
        """Validate quantum personality response structure"""
        assert response.get('success') == True, "Response should be successful"
        assert 'data' in response, "Response should have data"
        
        data = response['data']
        assert 'quantum_compatibility' in data, "Should have quantum_compatibility"
        assert 'personality_profile' in data, "Should have personality_profile"
        assert 'knot_compatibility' in data, "Should have knot_compatibility"
        assert 'product_recommendations' in data, "Should have product_recommendations"
        
        compatibility = data['quantum_compatibility']
        assert 'score' in compatibility, "Should have compatibility score"
        assert 0 <= compatibility['score'] <= 1, "Score should be 0-1"
        
        print("    ✅ Response structure valid")
    
    def _validate_community_influence_response(self, response: dict):
        """Validate community influence response structure"""
        assert response.get('success') == True, "Response should be successful"
        assert 'data' in response, "Response should have data"
        
        data = response['data']
        assert 'community_influence_patterns' in data, "Should have influence_patterns"
        assert 'purchase_behavior' in data, "Should have purchase_behavior"
        assert 'marketing_implications' in data, "Should have marketing_implications"
        
        patterns = data['community_influence_patterns']
        assert 'influence_score' in patterns, "Should have influence_score"
        
        print("    ✅ Response structure valid")
    
    def run_all_tests(self):
        """Run all endpoint tests"""
        print(f"\n{'='*60}")
        print(f"Endpoint Functionality Tests")
        print(f"{'='*60}\n")
        
        self.test_real_world_behavior_endpoint()
        print()
        self.test_quantum_personality_endpoint()
        print()
        self.test_community_influence_endpoint()
        print()
        
        # Save results
        csv_path, json_path = self.save_results()
        print(f"\nResults saved:")
        print(f"  CSV: {csv_path}")
        print(f"  JSON: {json_path}")
        
        # Generate summary
        summary = self.generate_summary([])
        summary_path = os.path.join(self.results_dir, "SUMMARY.md")
        with open(summary_path, 'w') as f:
            f.write(summary)
        print(f"  Summary: {summary_path}")
        
        # Print summary
        print(f"\n{summary}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Test e-commerce enrichment API endpoints")
    parser.add_argument("--api-url", required=True, help="API base URL")
    parser.add_argument("--api-key", required=True, help="API key")
    
    args = parser.parse_args()
    
    tester = EndpointFunctionalityTest(args.api_url, args.api_key)
    tester.run_all_tests()
