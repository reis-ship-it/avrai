"""
Personality Data Conversion System

A modular system for converting personality datasets from various formats
(e.g., Big Five, MBTI, Enneagram) to SPOTS 12-dimension format.

Usage:
    from scripts.personality_data import convert_dataset, load_dataset
    
    # Convert a dataset
    profiles = convert_dataset('big_five', 'data/raw/dataset.csv')
    
    # Load a processed dataset
    profiles = load_dataset('data/processed/spots_profiles.json')
"""

__version__ = '1.0.0'

from scripts.personality_data.converters.big_five_to_spots import BigFiveToSpotsConverter
from scripts.personality_data.loaders.csv_loader import CSVLoader
from scripts.personality_data.loaders.json_loader import JSONLoader
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator
from scripts.personality_data.registry.converter_registry import get_converter
from scripts.personality_data.registry.dataset_registry import get_dataset_info

__all__ = [
    'BigFiveToSpotsConverter',
    'CSVLoader',
    'JSONLoader',
    'GroundTruthGenerator',
    'get_converter',
    'get_dataset_info',
]
