"""
Ground Truth Generator

Generates ground truth compatibility pairs from personality profiles.
"""

import json
import random
from pathlib import Path
from typing import List, Dict, Any, Optional
import statistics

# Import compatibility calculator (from validation scripts)
try:
    import sys
    from pathlib import Path as PathLib
    project_root = PathLib(__file__).parent.parent.parent.parent
    sys.path.insert(0, str(project_root))
    from scripts.knot_validation.compare_matching_accuracy import MatchingAccuracyComparator
    COMPATIBILITY_AVAILABLE = True
except ImportError:
    COMPATIBILITY_AVAILABLE = False


class GroundTruthGenerator:
    """Generates ground truth compatibility pairs from personality profiles."""
    
    def __init__(
        self,
        compatibility_threshold: float = 0.6,
        noise_level: float = 0.05,
        use_compatibility_calculator: bool = True
    ):
        """
        Initialize ground truth generator.
        
        Args:
            compatibility_threshold: Threshold for compatible pairs (0.0-1.0)
            noise_level: Standard deviation of noise to add (for realism)
            use_compatibility_calculator: Use MatchingAccuracyComparator if available
        """
        self.compatibility_threshold = compatibility_threshold
        self.noise_level = noise_level
        self.use_compatibility_calculator = use_compatibility_calculator and COMPATIBILITY_AVAILABLE
        
        if self.use_compatibility_calculator:
            self.comparator = MatchingAccuracyComparator()
        else:
            self.comparator = None
    
    def generate(
        self,
        profiles: List[Dict[str, Any]],
        output_file: Optional[Path] = None
    ) -> List[Dict[str, Any]]:
        """
        Generate ground truth compatibility pairs.
        
        Args:
            profiles: List of SPOTS personality profiles
            output_file: Optional path to save ground truth JSON
        
        Returns:
            List of ground truth pairs
        """
        ground_truth = []
        
        print(f"Generating ground truth from {len(profiles)} profiles...")
        
        for i, profile_a in enumerate(profiles):
            for j, profile_b in enumerate(profiles):
                if i >= j:
                    continue
                
                # Calculate compatibility
                if self.use_compatibility_calculator:
                    compatibility = self.comparator.calculate_quantum_compatibility(
                        profile_a, profile_b
                    )
                else:
                    # Fallback: simple dimension similarity
                    compatibility = self._calculate_simple_compatibility(
                        profile_a, profile_b
                    )
                
                # Add noise for realism
                noisy_compatibility = compatibility + random.gauss(0, self.noise_level)
                noisy_compatibility = max(0.0, min(1.0, noisy_compatibility))
                
                # Determine if compatible
                is_compatible = noisy_compatibility >= self.compatibility_threshold
                
                ground_truth.append({
                    'user_a': profile_a['user_id'],
                    'user_b': profile_b['user_id'],
                    'is_compatible': is_compatible,
                    'compatibility_score': noisy_compatibility,
                    'true_compatibility': compatibility
                })
        
        # Save if output file provided
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(ground_truth, f, indent=2)
            print(f"Ground truth saved to {output_file}")
        
        compatible_count = sum(1 for gt in ground_truth if gt['is_compatible'])
        print(f"Generated {len(ground_truth)} pairs ({compatible_count} compatible, "
              f"{len(ground_truth) - compatible_count} incompatible)")
        
        return ground_truth
    
    def _calculate_simple_compatibility(
        self,
        profile_a: Dict[str, Any],
        profile_b: Dict[str, Any]
    ) -> float:
        """
        Calculate simple compatibility using dimension similarity.
        
        Fallback method when MatchingAccuracyComparator is not available.
        """
        dims_a = profile_a.get('dimensions', {})
        dims_b = profile_b.get('dimensions', {})
        
        similarities = []
        for dim in dims_a.keys():
            if dim in dims_b:
                similarity = 1.0 - abs(dims_a[dim] - dims_b[dim])
                similarities.append(similarity)
        
        if not similarities:
            return 0.5
        
        return statistics.mean(similarities)
