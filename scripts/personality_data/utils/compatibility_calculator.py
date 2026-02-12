"""
Compatibility Calculator

Calculates compatibility between personality profiles.
"""

from typing import Dict
import statistics


def calculate_compatibility(
    profile_a: Dict,
    profile_b: Dict,
    method: str = 'dimension_similarity'
) -> float:
    """
    Calculate compatibility between two profiles.
    
    Args:
        profile_a: First personality profile
        profile_b: Second personality profile
        method: Calculation method ('dimension_similarity', 'quantum', etc.)
    
    Returns:
        Compatibility score (0.0-1.0)
    """
    if method == 'dimension_similarity':
        return _calculate_dimension_similarity(profile_a, profile_b)
    else:
        # Default to dimension similarity
        return _calculate_dimension_similarity(profile_a, profile_b)


def _calculate_dimension_similarity(profile_a: Dict, profile_b: Dict) -> float:
    """Calculate compatibility using dimension similarity."""
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
