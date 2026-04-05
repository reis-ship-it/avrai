"""
Base Converter Interface

Defines the interface for all personality data converters.
"""

from abc import ABC, abstractmethod
from typing import Dict, List, Any, Optional


class PersonalityConverter(ABC):
    """
    Base class for personality data converters.
    
    All converters must implement this interface to convert
    personality data from various formats to SPOTS 12-dimension format.
    """
    
    @abstractmethod
    def convert(self, source_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert source personality data to SPOTS format.
        
        Args:
            source_data: Source personality data (format depends on converter)
        
        Returns:
            Dict with SPOTS 12 dimensions (0.0-1.0 scale)
        """
        pass
    
    @abstractmethod
    def validate_source(self, source_data: Dict[str, Any]) -> bool:
        """
        Validate that source data has required fields.
        
        Args:
            source_data: Source personality data to validate
        
        Returns:
            True if valid, False otherwise
        """
        pass
    
    @abstractmethod
    def get_source_format(self) -> str:
        """
        Return source format identifier.
        
        Returns:
            Format name (e.g., 'big_five', 'mbti', 'enneagram')
        """
        pass
    
    @abstractmethod
    def get_required_fields(self) -> List[str]:
        """
        Return list of required field names for source data.
        
        Returns:
            List of required field names
        """
        pass
    
    def normalize_value(self, value: Any, scale: str = 'auto') -> float:
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
