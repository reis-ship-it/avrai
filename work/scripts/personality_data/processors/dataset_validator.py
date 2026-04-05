"""
Dataset Validator

Validates personality datasets for completeness and correctness.
"""

from typing import List, Dict, Any, Tuple


class DatasetValidator:
    """Validates personality datasets."""
    
    @staticmethod
    def validate_spots_profiles(profiles: List[Dict[str, Any]]) -> Tuple[bool, List[str]]:
        """
        Validate SPOTS profiles.
        
        Args:
            profiles: List of SPOTS profiles
        
        Returns:
            Tuple of (is_valid, list_of_errors)
        """
        errors = []
        required_dimensions = [
            'exploration_eagerness', 'community_orientation', 'adventure_seeking',
            'social_preference', 'energy_preference', 'novelty_seeking',
            'value_orientation', 'crowd_tolerance', 'authenticity',
            'archetype', 'trust_level', 'openness'
        ]
        
        if not profiles:
            errors.append("No profiles found")
            return False, errors
        
        for i, profile in enumerate(profiles):
            # Check user_id
            if 'user_id' not in profile:
                errors.append(f"Profile {i}: Missing 'user_id'")
            
            # Check dimensions
            if 'dimensions' not in profile:
                errors.append(f"Profile {i}: Missing 'dimensions'")
                continue
            
            dims = profile['dimensions']
            for dim in required_dimensions:
                if dim not in dims:
                    errors.append(f"Profile {i}: Missing dimension '{dim}'")
                else:
                    value = dims[dim]
                    if not isinstance(value, (int, float)):
                        errors.append(f"Profile {i}: Dimension '{dim}' is not numeric")
                    elif not (0.0 <= value <= 1.0):
                        errors.append(f"Profile {i}: Dimension '{dim}' out of range [0.0, 1.0]: {value}")
        
        return len(errors) == 0, errors
    
    @staticmethod
    def validate_big_five_profiles(profiles: List[Dict[str, Any]]) -> Tuple[bool, List[str]]:
        """
        Validate Big Five profiles.
        
        Args:
            profiles: List of Big Five profiles
        
        Returns:
            Tuple of (is_valid, list_of_errors)
        """
        errors = []
        required_fields = ['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism']
        
        if not profiles:
            errors.append("No profiles found")
            return False, errors
        
        for i, profile in enumerate(profiles):
            for field in required_fields:
                # Check various name variations
                found = False
                variations = [field, field[0].upper(), field.upper(), f"{field}_score"]
                
                for var in variations:
                    if var in profile or var.lower() in profile:
                        found = True
                        break
                
                if not found:
                    errors.append(f"Profile {i}: Missing Big Five dimension '{field}'")
        
        return len(errors) == 0, errors
