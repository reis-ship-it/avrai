"""
Score Normalizer

Normalizes personality scores across different scales.
"""

from typing import Union, Dict, List, Any


class Normalizer:
    """Normalizes personality scores to 0.0-1.0 range."""
    
    @staticmethod
    def normalize_value(value: Union[int, float, str], scale: str = 'auto') -> float:
        """
        Normalize a personality score to 0.0-1.0 range.
        
        Args:
            value: Raw score value
            scale: Scale type ('1-5', '0-1', '0-100', 'auto' for detection)
        
        Returns:
            Normalized value in [0.0, 1.0]
        """
        try:
            num_value = float(value)
        except (ValueError, TypeError):
            return 0.5  # Default to middle value
        
        # Auto-detect scale if needed
        if scale == 'auto':
            if 0 <= num_value <= 1:
                scale = '0-1'
            elif 1 <= num_value <= 5:
                scale = '1-5'
            elif 0 <= num_value <= 100:
                scale = '0-100'
            else:
                # Assume percentage or normalize to 0-1
                scale = '0-100'
        
        # Normalize based on scale
        if scale == '0-1':
            return max(0.0, min(1.0, num_value))
        elif scale == '1-5':
            return max(0.0, min(1.0, (num_value - 1) / 4.0))
        elif scale == '0-100':
            return max(0.0, min(1.0, num_value / 100.0))
        else:
            # Default: clamp to [0, 1]
            return max(0.0, min(1.0, num_value))
    
    @staticmethod
    def normalize_dict(
        data: Dict[str, Any],
        fields: List[str],
        scale: str = 'auto'
    ) -> Dict[str, float]:
        """
        Normalize multiple fields in a dictionary.
        
        Args:
            data: Dictionary with personality scores
            fields: List of field names to normalize
            scale: Scale type for normalization
        
        Returns:
            Dictionary with normalized values
        """
        normalized = {}
        for field in fields:
            if field in data:
                normalized[field] = Normalizer.normalize_value(data[field], scale)
            else:
                normalized[field] = 0.5  # Default
        
        return normalized
