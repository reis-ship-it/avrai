"""
Big Five Extractor

Extracts Big Five scores from profile dictionaries with flexible column names.
"""

from typing import Dict, Any, Optional, List


class BigFiveExtractor:
    """Extracts Big Five scores from profile data."""
    
    # Column name variations for each Big Five dimension
    COLUMN_VARIATIONS = {
        'openness': ['openness', 'o', 'opn', 'openness_score', 'open'],
        'conscientiousness': ['conscientiousness', 'c', 'con', 'conscientiousness_score', 'conscientious'],
        'extraversion': ['extraversion', 'e', 'ext', 'extraversion_score', 'extravert'],
        'agreeableness': ['agreeableness', 'a', 'agr', 'agreeableness_score', 'agreeable'],
        'neuroticism': ['neuroticism', 'n', 'neu', 'neuroticism_score', 'neurotic'],
    }
    
    @classmethod
    def extract(cls, profile: Dict[str, Any], custom_mappings: Optional[Dict[str, List[str]]] = None) -> Optional[Dict[str, float]]:
        """
        Extract Big Five scores from a profile dict.
        
        Args:
            profile: Profile dictionary
            custom_mappings: Optional custom column name mappings
        
        Returns:
            Dict with Big Five scores or None if not all dimensions found
        """
        mappings = custom_mappings or cls.COLUMN_VARIATIONS
        big_five = {}
        
        for big_five_dim, variations in mappings.items():
            found = False
            for var in variations:
                # Try exact match
                if var in profile:
                    try:
                        value = float(profile[var])
                        big_five[big_five_dim] = value
                        found = True
                        break
                    except (ValueError, TypeError):
                        continue
                
                # Try case-insensitive match
                var_lower = var.lower()
                for key in profile.keys():
                    if key.lower() == var_lower:
                        try:
                            value = float(profile[key])
                            big_five[big_five_dim] = value
                            found = True
                            break
                        except (ValueError, TypeError):
                            continue
                
                if found:
                    break
            
            if not found:
                return None  # Missing required dimension
        
        return big_five if len(big_five) == 5 else None
