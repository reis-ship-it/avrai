"""
Big Five to SPOTS Converter

Converts Big Five (OCEAN) personality scores to SPOTS 12-dimension format.
"""

from typing import Dict, List, Any
from scripts.personality_data.converters.base import PersonalityConverter

# Big Five (OCEAN) dimensions
BIG_FIVE_DIMENSIONS = ['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism']


class BigFiveToSpotsConverter(PersonalityConverter):
    """
    Converts Big Five (OCEAN) personality scores to SPOTS 12 dimensions.
    
    Mapping Strategy:
    - Openness → exploration_eagerness, novelty_seeking, openness
    - Conscientiousness → value_orientation, authenticity
    - Extraversion → social_preference, community_orientation, adventure_seeking
    - Agreeableness → trust_level, crowd_tolerance
    - Neuroticism → energy_preference (inverted)
    """
    
    def __init__(self, scale: str = 'auto'):
        """
        Initialize converter.
        
        Args:
            scale: Scale type for Big Five scores ('1-5', '0-1', '0-100', 'auto')
        """
        self.scale = scale
    
    def convert(self, source_data: Dict[str, Any]) -> Dict[str, float]:
        """
        Convert Big Five scores to SPOTS 12 dimensions.
        
        Args:
            source_data: Dict with Big Five scores (keys: openness, conscientiousness,
                       extraversion, agreeableness, neuroticism)
        
        Returns:
            Dict with SPOTS 12 dimensions (0.0-1.0)
        """
        # Normalize Big Five scores to 0.0-1.0
        normalized = {}
        for dim in BIG_FIVE_DIMENSIONS:
            if dim in source_data:
                normalized[dim] = self.normalize_value(source_data[dim], self.scale)
            else:
                normalized[dim] = 0.5  # Default to middle value
        
        # Get Big Five values
        o = normalized['openness']
        c = normalized['conscientiousness']
        e = normalized['extraversion']
        a = normalized['agreeableness']
        n = normalized['neuroticism']
        
        # Map to SPOTS dimensions
        spots_dimensions = {
            # Openness → Exploration and Novelty
            'exploration_eagerness': o * 0.7 + e * 0.3,
            'novelty_seeking': o * 0.8 + (1.0 - c) * 0.2,  # Low conscientiousness = more novelty seeking
            'openness': o,  # Direct mapping
            
            # Conscientiousness → Values and Authenticity
            'value_orientation': c * 0.6 + a * 0.4,
            'authenticity': c * 0.7 + o * 0.3,
            
            # Extraversion → Social and Community
            'social_preference': e * 0.8 + a * 0.2,
            'community_orientation': e * 0.7 + a * 0.3,
            'adventure_seeking': e * 0.5 + o * 0.5,
            
            # Agreeableness → Trust and Crowd Tolerance
            'trust_level': a * 0.8 + c * 0.2,
            'crowd_tolerance': a * 0.6 + e * 0.4,
            
            # Neuroticism → Energy (inverted: low neuroticism = high energy preference)
            'energy_preference': (1.0 - n) * 0.7 + e * 0.3,
            
            # Archetype: Infer from combination
            'archetype': self._infer_archetype(o, c, e, a, n),
        }
        
        # Ensure all values are in [0.0, 1.0]
        for dim in spots_dimensions:
            spots_dimensions[dim] = max(0.0, min(1.0, spots_dimensions[dim]))
        
        return spots_dimensions
    
    def validate_source(self, source_data: Dict[str, Any]) -> bool:
        """Validate that source data has all Big Five dimensions."""
        required = self.get_required_fields()
        return all(field in source_data for field in required)
    
    def get_source_format(self) -> str:
        """Return source format identifier."""
        return 'big_five'
    
    def get_required_fields(self) -> List[str]:
        """Return list of required Big Five dimensions."""
        return BIG_FIVE_DIMENSIONS
    
    def _infer_archetype(self, o: float, c: float, e: float, a: float, n: float) -> float:
        """
        Infer archetype value from Big Five scores.
        
        Archetype mapping:
        - High Openness + High Extraversion → Explorer (0.8-1.0)
        - High Conscientiousness + High Agreeableness → Community Builder (0.6-0.8)
        - Low Extraversion + High Openness → Solo Seeker (0.4-0.6)
        - High Neuroticism + Low Extraversion → Cautious Explorer (0.2-0.4)
        - Balanced → Developing (0.0-0.2)
        """
        if o > 0.7 and e > 0.7:
            return 0.9  # Explorer
        elif c > 0.7 and a > 0.7:
            return 0.7  # Community Builder
        elif e < 0.3 and o > 0.6:
            return 0.5  # Solo Seeker
        elif n > 0.7 and e < 0.4:
            return 0.3  # Cautious Explorer
        else:
            return 0.5  # Balanced/Developing
