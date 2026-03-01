"""
Personality Data Converters

Converters for transforming personality data from various formats
to SPOTS 12-dimension format.
"""

from scripts.personality_data.converters.base import PersonalityConverter
from scripts.personality_data.converters.big_five_to_spots import BigFiveToSpotsConverter
from scripts.personality_data.converters.universal import UniversalPersonalityConverter

__all__ = [
    'PersonalityConverter',
    'BigFiveToSpotsConverter',
    'UniversalPersonalityConverter',
]
