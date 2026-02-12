"""
Archetype Inference

Infers personality archetypes from dimension values.
"""

from typing import Dict


def infer_archetype(dimensions: Dict[str, float]) -> str:
    """
    Infer archetype from SPOTS dimensions.
    
    Args:
        dimensions: Dict of SPOTS 12 dimensions
    
    Returns:
        Archetype name (e.g., 'Explorer', 'Community Builder')
    """
    exploration = dimensions.get('exploration_eagerness', 0.5)
    community = dimensions.get('community_orientation', 0.5)
    social = dimensions.get('social_preference', 0.5)
    value_orientation = dimensions.get('value_orientation', 0.5)
    
    if exploration > 0.7 and community < 0.5:
        return 'Explorer'
    elif community > 0.7 and social > 0.7:
        return 'Community Builder'
    elif social < 0.4 and exploration > 0.6:
        return 'Solo Seeker'
    elif social > 0.8:
        return 'Social Butterfly'
    elif value_orientation > 0.8:
        return 'Deep Thinker'
    else:
        return 'Balanced'


def infer_archetype_score(dimensions: Dict[str, float]) -> float:
    """
    Infer archetype score (0.0-1.0) from dimensions.
    
    Args:
        dimensions: Dict of SPOTS 12 dimensions
    
    Returns:
        Archetype score (0.0-1.0)
    """
    exploration = dimensions.get('exploration_eagerness', 0.5)
    community = dimensions.get('community_orientation', 0.5)
    social = dimensions.get('social_preference', 0.5)
    value_orientation = dimensions.get('value_orientation', 0.5)
    
    if exploration > 0.7 and community < 0.5:
        return 0.9  # Explorer
    elif community > 0.7 and social > 0.7:
        return 0.7  # Community Builder
    elif social < 0.4 and exploration > 0.6:
        return 0.5  # Solo Seeker
    elif social > 0.8:
        return 0.6  # Social Butterfly
    elif value_orientation > 0.8:
        return 0.8  # Deep Thinker
    else:
        return 0.5  # Balanced
