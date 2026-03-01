#!/usr/bin/env python3
"""
Data Converter: Convert Open Datasets to SPOTS Format

Purpose: Convert Big Five (OCEAN) and other personality datasets
to SPOTS 12-dimension personality profiles.

Part of Phase 0 validation for Patent #31.
"""

import json
import csv
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional
import statistics
import random

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# SPOTS 12 dimensions (matching validation script format)
# Note: Some dimensions may be named differently in validation vs production
SPOTS_DIMENSIONS = [
    'exploration_eagerness',
    'community_orientation',
    'adventure_seeking',
    'social_preference',  # Maps to social_discovery_style
    'energy_preference',
    'novelty_seeking',
    'value_orientation',
    'crowd_tolerance',
    'authenticity',  # Maps to authenticity_preference
    'archetype',  # Derived, not a direct dimension
    'trust_level',  # Maps to trust_network_reliance
    'openness'  # Additional dimension for compatibility
]

# Big Five (OCEAN) dimensions
BIG_FIVE_DIMENSIONS = ['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism']


class BigFiveToSpotsConverter:
    """Converts Big Five (OCEAN) personality scores to SPOTS 12 dimensions."""
    
    def __init__(self):
        """Initialize converter with mapping rules."""
        pass
    
    def convert(self, big_five_scores: Dict[str, float]) -> Dict[str, float]:
        """
        Convert Big Five scores to SPOTS 12 dimensions.
        
        Mapping Strategy:
        - Openness → exploration_eagerness, novelty_seeking, openness
        - Conscientiousness → value_orientation, authenticity
        - Extraversion → social_preference, community_orientation, adventure_seeking
        - Agreeableness → trust_level, crowd_tolerance
        - Neuroticism → energy_preference (inverted)
        
        Args:
            big_five_scores: Dict with keys 'openness', 'conscientiousness', 
                           'extraversion', 'agreeableness', 'neuroticism'
                           Values should be 0.0-1.0 or 1-5 (will be normalized)
        
        Returns:
            Dict with SPOTS 12 dimensions (0.0-1.0)
        """
        # Normalize Big Five scores to 0.0-1.0 if needed
        normalized = {}
        for dim, value in big_five_scores.items():
            if dim.lower() in BIG_FIVE_DIMENSIONS:
                # If value is 1-5 scale, normalize to 0-1
                if 1 <= value <= 5:
                    normalized[dim.lower()] = (value - 1) / 4.0
                # If value is already 0-1, use as-is
                elif 0 <= value <= 1:
                    normalized[dim.lower()] = value
                else:
                    # Assume it's a percentage or other scale, clamp to 0-1
                    normalized[dim.lower()] = max(0.0, min(1.0, value / 100.0))
        
        # Get Big Five values (default to 0.5 if missing)
        openness = normalized.get('openness', 0.5)
        conscientiousness = normalized.get('conscientiousness', 0.5)
        extraversion = normalized.get('extraversion', 0.5)
        agreeableness = normalized.get('agreeableness', 0.5)
        neuroticism = normalized.get('neuroticism', 0.5)
        
        # Map to SPOTS dimensions
        spots_dimensions = {
            # Openness → Exploration and Novelty
            'exploration_eagerness': openness * 0.7 + extraversion * 0.3,
            'novelty_seeking': openness * 0.8 + conscientiousness * 0.2,  # Low conscientiousness = more novelty seeking
            'openness': openness,  # Direct mapping
            
            # Conscientiousness → Values and Authenticity
            'value_orientation': conscientiousness * 0.6 + agreeableness * 0.4,
            'authenticity': conscientiousness * 0.7 + openness * 0.3,
            
            # Extraversion → Social and Community
            'social_preference': extraversion * 0.8 + agreeableness * 0.2,
            'community_orientation': extraversion * 0.7 + agreeableness * 0.3,
            'adventure_seeking': extraversion * 0.5 + openness * 0.5,
            
            # Agreeableness → Trust and Crowd Tolerance
            'trust_level': agreeableness * 0.8 + conscientiousness * 0.2,
            'crowd_tolerance': agreeableness * 0.6 + extraversion * 0.4,
            
            # Neuroticism → Energy (inverted: low neuroticism = high energy preference)
            'energy_preference': (1.0 - neuroticism) * 0.7 + extraversion * 0.3,
            
            # Archetype: Infer from combination (simplified)
            # This will be calculated separately
            'archetype': 0.5,  # Placeholder, will be inferred
        }
        
        # Infer archetype from Big Five combination
        spots_dimensions['archetype'] = self._infer_archetype(
            openness, conscientiousness, extraversion, agreeableness, neuroticism
        )
        
        # Ensure all values are in [0.0, 1.0]
        for dim in spots_dimensions:
            spots_dimensions[dim] = max(0.0, min(1.0, spots_dimensions[dim]))
        
        return spots_dimensions
    
    def _infer_archetype(self, o: float, c: float, e: float, a: float, n: float) -> float:
        """
        Infer archetype value from Big Five scores.
        
        Archetype mapping (simplified):
        - High Openness + High Extraversion → Explorer (0.8-1.0)
        - High Conscientiousness + High Agreeableness → Community Builder (0.6-0.8)
        - Low Extraversion + High Openness → Solo Seeker (0.4-0.6)
        - High Neuroticism + Low Extraversion → Cautious Explorer (0.2-0.4)
        - Balanced → Developing (0.0-0.2)
        """
        # Calculate archetype score based on dominant traits
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


class DatasetLoader:
    """Loads personality datasets from various formats."""
    
    @staticmethod
    def load_csv(file_path: Path) -> List[Dict[str, Any]]:
        """Load CSV file with personality data."""
        profiles = []
        
        with open(file_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                profiles.append(dict(row))
        
        return profiles
    
    @staticmethod
    def load_json(file_path: Path) -> List[Dict[str, Any]]:
        """Load JSON file with personality data."""
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Handle different JSON structures
        if isinstance(data, list):
            return data
        elif isinstance(data, dict) and 'profiles' in data:
            return data['profiles']
        elif isinstance(data, dict) and 'data' in data:
            return data['data']
        else:
            # Assume it's a single profile
            return [data]
    
    @staticmethod
    def extract_big_five(profile: Dict[str, Any]) -> Optional[Dict[str, float]]:
        """
        Extract Big Five scores from a profile dict.
        
        Handles various column name formats:
        - 'openness', 'O', 'OPN', 'openness_score'
        - 'conscientiousness', 'C', 'CON', 'conscientiousness_score'
        - 'extraversion', 'E', 'EXT', 'extraversion_score'
        - 'agreeableness', 'A', 'AGR', 'agreeableness_score'
        - 'neuroticism', 'N', 'NEU', 'neuroticism_score'
        """
        big_five = {}
        
        # Common column name variations
        name_mappings = {
            'openness': ['openness', 'o', 'opn', 'openness_score', 'open'],
            'conscientiousness': ['conscientiousness', 'c', 'con', 'conscientiousness_score', 'conscientious'],
            'extraversion': ['extraversion', 'e', 'ext', 'extraversion_score', 'extravert'],
            'agreeableness': ['agreeableness', 'a', 'agr', 'agreeableness_score', 'agreeable'],
            'neuroticism': ['neuroticism', 'n', 'neu', 'neuroticism_score', 'neurotic'],
        }
        
        for big_five_dim, variations in name_mappings.items():
            for var in variations:
                if var in profile:
                    try:
                        value = float(profile[var])
                        big_five[big_five_dim] = value
                        break
                    except (ValueError, TypeError):
                        continue
        
        # Return None if we don't have all 5 dimensions
        if len(big_five) < 5:
            return None
        
        return big_five


def convert_dataset_to_spots(
    input_file: Path,
    output_file: Path,
    input_format: str = 'auto',
    user_id_prefix: str = 'user_'
) -> List[Dict[str, Any]]:
    """
    Convert a personality dataset to SPOTS format.
    
    Args:
        input_file: Path to input dataset (CSV or JSON)
        output_file: Path to output SPOTS profiles (JSON)
        input_format: 'csv', 'json', or 'auto' (detect from extension)
        user_id_prefix: Prefix for generated user IDs
    
    Returns:
        List of converted SPOTS profiles
    """
    # Detect format if auto
    if input_format == 'auto':
        if input_file.suffix.lower() == '.csv':
            input_format = 'csv'
        elif input_file.suffix.lower() == '.json':
            input_format = 'json'
        else:
            raise ValueError(f"Unknown file format: {input_file.suffix}")
    
    # Load dataset
    if input_format == 'csv':
        raw_profiles = DatasetLoader.load_csv(input_file)
    else:
        raw_profiles = DatasetLoader.load_json(input_file)
    
    # Convert to SPOTS format
    converter = BigFiveToSpotsConverter()
    spots_profiles = []
    
    for i, raw_profile in enumerate(raw_profiles):
        # Extract Big Five scores
        big_five = DatasetLoader.extract_big_five(raw_profile)
        
        if big_five is None:
            print(f"Warning: Profile {i} missing Big Five data, skipping")
            continue
        
        # Convert to SPOTS dimensions
        spots_dimensions = converter.convert(big_five)
        
        # Create SPOTS profile
        user_id = raw_profile.get('user_id') or raw_profile.get('id') or f"{user_id_prefix}{i}"
        
        spots_profile = {
            'user_id': str(user_id),
            'dimensions': spots_dimensions,
            'created_at': raw_profile.get('created_at') or raw_profile.get('timestamp'),
            'source': 'big_five_conversion',
            'original_data': {
                'big_five': big_five,
                'raw_profile': {k: v for k, v in raw_profile.items() if k not in ['user_id', 'id']}
            }
        }
        
        spots_profiles.append(spots_profile)
    
    # Save converted profiles
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(spots_profiles, f, indent=2)
    
    print(f"Converted {len(spots_profiles)} profiles from {input_file} to {output_file}")
    
    return spots_profiles


def create_ground_truth_from_dataset(
    profiles: List[Dict[str, Any]],
    output_file: Path,
    compatibility_threshold: float = 0.6,
    noise_level: float = 0.05
) -> List[Dict[str, Any]]:
    """
    Create ground truth compatibility pairs from converted profiles.
    
    Uses the same compatibility calculation as the matching system
    to create realistic ground truth.
    
    Args:
        profiles: List of SPOTS profiles
        output_file: Path to save ground truth JSON
        compatibility_threshold: Threshold for compatible pairs
        noise_level: Standard deviation of noise to add (for realism)
    
    Returns:
        List of ground truth pairs
    """
    from scripts.knot_validation.compare_matching_accuracy import MatchingAccuracyComparator
    
    comparator = MatchingAccuracyComparator()
    ground_truth = []
    
    print(f"Creating ground truth from {len(profiles)} profiles...")
    
    for i, profile_a in enumerate(profiles):
        for j, profile_b in enumerate(profiles):
            if i >= j:
                continue
            
            # Calculate compatibility
            compatibility = comparator.calculate_quantum_compatibility(profile_a, profile_b)
            
            # Add noise for realism
            import random
            noisy_compatibility = compatibility + random.gauss(0, noise_level)
            noisy_compatibility = max(0.0, min(1.0, noisy_compatibility))
            
            # Determine if compatible
            is_compatible = noisy_compatibility >= compatibility_threshold
            
            ground_truth.append({
                'user_a': profile_a['user_id'],
                'user_b': profile_b['user_id'],
                'is_compatible': is_compatible,
                'compatibility_score': noisy_compatibility,
                'true_compatibility': compatibility
            })
    
    # Save ground truth
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(ground_truth, f, indent=2)
    
    compatible_count = sum(1 for gt in ground_truth if gt['is_compatible'])
    print(f"Created {len(ground_truth)} ground truth pairs ({compatible_count} compatible, {len(ground_truth) - compatible_count} incompatible)")
    
    return ground_truth


if __name__ == '__main__':
    # Backward compatibility: Use new system
    import sys
    from pathlib import Path
    
    # Redirect to new CLI
    sys.argv.insert(0, 'convert')
    sys.path.insert(0, str(Path(__file__).parent.parent / 'personality_data' / 'cli'))
    
    try:
        from scripts.personality_data.cli.convert import main
        main()
    except ImportError:
        # Fallback to old implementation if new system not available
        import argparse
        
        parser = argparse.ArgumentParser(description='Convert personality datasets to SPOTS format')
        parser.add_argument('input_file', type=Path, help='Input dataset file (CSV or JSON)')
        parser.add_argument('--output', type=Path, help='Output SPOTS profiles file (default: input_file_spots.json)')
        parser.add_argument('--format', choices=['csv', 'json', 'auto'], default='auto', help='Input file format')
        parser.add_argument('--ground-truth', type=Path, help='Output ground truth file (optional)')
        parser.add_argument('--threshold', type=float, default=0.6, help='Compatibility threshold for ground truth')
        parser.add_argument('--noise', type=float, default=0.05, help='Noise level for ground truth')
        
        args = parser.parse_args()
        
        # Determine output file
        if args.output is None:
            args.output = args.input_file.parent / f"{args.input_file.stem}_spots.json"
        
        # Convert dataset
        spots_profiles = convert_dataset_to_spots(
            args.input_file,
            args.output,
            args.format
        )
        
        # Create ground truth if requested
        if args.ground_truth:
            create_ground_truth_from_dataset(
                spots_profiles,
                args.ground_truth,
                args.threshold,
                args.noise
            )
