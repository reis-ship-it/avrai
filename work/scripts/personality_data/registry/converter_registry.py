"""
Converter Registry

Registry of personality data converters.
"""

from typing import Dict, Type, Optional, List
from scripts.personality_data.converters.base import PersonalityConverter
from scripts.personality_data.converters.big_five_to_spots import BigFiveToSpotsConverter
from scripts.personality_data.converters.universal import UniversalPersonalityConverter

# Registry of converters
CONVERTERS: Dict[str, Type[PersonalityConverter]] = {
    'big_five_to_spots': BigFiveToSpotsConverter,
    'big_five': BigFiveToSpotsConverter,  # Alias
    'ocean': BigFiveToSpotsConverter,  # Alias
    'universal': UniversalPersonalityConverter,  # Universal converter
    'auto': UniversalPersonalityConverter,  # Alias for auto-detection
}


def get_converter(converter_id: str) -> Optional[Type[PersonalityConverter]]:
    """
    Get converter class by ID.
    
    Args:
        converter_id: Converter identifier
    
    Returns:
        Converter class or None if not found
    """
    return CONVERTERS.get(converter_id)


def list_converters() -> List[str]:
    """
    List all registered converter IDs.
    
    Returns:
        List of converter IDs
    """
    return list(CONVERTERS.keys())


def register_converter(converter_id: str, converter_class: Type[PersonalityConverter]):
    """
    Register a new converter.
    
    Args:
        converter_id: Unique converter identifier
        converter_class: Converter class (must extend PersonalityConverter)
    """
    CONVERTERS[converter_id] = converter_class
