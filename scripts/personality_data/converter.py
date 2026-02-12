"""
Main Conversion Orchestrator

Orchestrates the conversion of personality datasets to SPOTS format.
"""

import sys
from pathlib import Path
from typing import List, Dict, Any, Optional

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.personality_data.loaders.csv_loader import CSVLoader
from scripts.personality_data.loaders.json_loader import JSONLoader
from scripts.personality_data.registry.converter_registry import get_converter
from scripts.personality_data.registry.dataset_registry import get_dataset_info, get_column_mappings
from scripts.personality_data.processors.dataset_validator import DatasetValidator
from scripts.personality_data.utils.big_five_extractor import BigFiveExtractor


def convert_dataset(
    input_file: Path,
    output_file: Path,
    source_format: str = 'big_five',
    dataset_id: Optional[str] = None,
    input_file_format: str = 'auto',
    user_id_prefix: str = 'user_',
    validate: bool = True
) -> List[Dict[str, Any]]:
    """
    Convert a personality dataset to SPOTS format.
    
    Args:
        input_file: Path to input dataset (CSV or JSON)
        output_file: Path to output SPOTS profiles (JSON)
        source_format: Source format ('big_five', 'mbti', etc.) or converter ID
        dataset_id: Optional dataset ID (for column mappings)
        input_file_format: 'csv', 'json', or 'auto' (detect from extension)
        user_id_prefix: Prefix for generated user IDs
        validate: Whether to validate output profiles
    
    Returns:
        List of converted SPOTS profiles
    """
    # Get converter
    converter_class = get_converter(source_format)
    if converter_class is None:
        raise ValueError(f"Unknown converter: {source_format}. Available: {get_converter.__module__}")
    
    converter = converter_class()
    
    # Get dataset info if provided
    dataset_info = None
    if dataset_id:
        dataset_info = get_dataset_info(dataset_id)
    
    # Detect file format if auto
    if input_file_format == 'auto':
        if input_file.suffix.lower() == '.csv':
            input_file_format = 'csv'
        elif input_file.suffix.lower() == '.json':
            input_file_format = 'json'
        else:
            raise ValueError(f"Unknown file format: {input_file.suffix}")
    
    # Load dataset
    if input_file_format == 'csv':
        raw_profiles = CSVLoader.load(input_file)
    else:
        raw_profiles = JSONLoader.load(input_file)
    
    print(f"Loaded {len(raw_profiles)} profiles from {input_file}")
    
    # Get column mappings if dataset info available
    column_mappings = None
    if dataset_info:
        column_mappings = get_column_mappings(dataset_id)
        # Set converter scale from dataset info
        if hasattr(converter, 'scale'):
            converter.scale = dataset_info.get('scale', 'auto')
    
    # Convert to SPOTS format
    spots_profiles = []
    skipped = 0
    
    for i, raw_profile in enumerate(raw_profiles):
        # Extract source personality data
        if source_format in ['big_five', 'big_five_to_spots', 'ocean']:
            source_data = BigFiveExtractor.extract(raw_profile, column_mappings)
            if source_data is None:
                skipped += 1
                if i < 10:  # Only print first 10 warnings
                    print(f"Warning: Profile {i} missing Big Five data, skipping")
                continue
        else:
            # For other formats, use raw profile as source data
            source_data = raw_profile
        
        # Validate source data
        if not converter.validate_source(source_data):
            skipped += 1
            if i < 10:
                print(f"Warning: Profile {i} failed validation, skipping")
            continue
        
        # Convert to SPOTS dimensions
        try:
            spots_dimensions = converter.convert(source_data)
        except Exception as e:
            skipped += 1
            if i < 10:
                print(f"Warning: Profile {i} conversion failed: {e}, skipping")
            continue
        
        # Create SPOTS profile
        user_id = raw_profile.get('user_id') or raw_profile.get('id') or f"{user_id_prefix}{i}"
        
        spots_profile = {
            'user_id': str(user_id),
            'dimensions': spots_dimensions,
            'created_at': raw_profile.get('created_at') or raw_profile.get('timestamp'),
            'source': f'{source_format}_conversion',
            'original_data': {
                'source_format': source_format,
                'raw_profile': {k: v for k, v in raw_profile.items() 
                              if k not in ['user_id', 'id']}
            }
        }
        
        spots_profiles.append(spots_profile)
    
    if skipped > 0:
        print(f"Skipped {skipped} profiles due to missing/invalid data")
    
    # Validate output if requested
    if validate:
        is_valid, errors = DatasetValidator.validate_spots_profiles(spots_profiles)
        if not is_valid:
            print(f"Validation warnings ({len(errors)} errors):")
            for error in errors[:10]:  # Show first 10 errors
                print(f"  - {error}")
            if len(errors) > 10:
                print(f"  ... and {len(errors) - 10} more errors")
    
    # Save converted profiles
    JSONLoader.save(spots_profiles, output_file)
    print(f"Converted {len(spots_profiles)} profiles to {output_file}")
    
    return spots_profiles
