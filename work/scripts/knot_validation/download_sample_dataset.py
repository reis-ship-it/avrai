#!/usr/bin/env python3
"""
Download Sample Personality Dataset

Purpose: Download a sample Big Five personality dataset for validation.
Creates a sample dataset if download fails (for testing).

Part of Phase 0 validation for Patent #31.
"""

import json
import csv
import sys
from pathlib import Path
import random

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


def create_sample_dataset(output_file: Path, num_profiles: int = 100):
    """
    Create a sample Big Five dataset for testing.
    
    Args:
        output_file: Path to save CSV file
        num_profiles: Number of profiles to generate
    """
    print(f"Creating sample dataset with {num_profiles} profiles...")
    
    # Generate random Big Five scores (1-5 scale)
    profiles = []
    
    for i in range(num_profiles):
        profile = {
            'user_id': f'user_{i+1}',
            'openness': round(random.uniform(1.0, 5.0), 2),
            'conscientiousness': round(random.uniform(1.0, 5.0), 2),
            'extraversion': round(random.uniform(1.0, 5.0), 2),
            'agreeableness': round(random.uniform(1.0, 5.0), 2),
            'neuroticism': round(random.uniform(1.0, 5.0), 2),
        }
        profiles.append(profile)
    
    # Save as CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['user_id', 'openness', 'conscientiousness', 
                                               'extraversion', 'agreeableness', 'neuroticism'])
        writer.writeheader()
        writer.writerows(profiles)
    
    print(f"Sample dataset saved to {output_file}")
    return output_file


def download_kaggle_dataset(dataset_name: str, output_dir: Path):
    """
    Download dataset from Kaggle (requires Kaggle API).
    
    Args:
        dataset_name: Kaggle dataset name (e.g., 'tunguz/big-five-personality-test')
        output_dir: Directory to save dataset
    """
    try:
        import kaggle
        from kaggle.api.kaggle_api_extended import KaggleApi
        
        api = KaggleApi()
        api.authenticate()
        
        print(f"Downloading {dataset_name} from Kaggle...")
        api.dataset_download_files(dataset_name, path=str(output_dir), unzip=True)
        
        print(f"Dataset downloaded to {output_dir}")
        return True
    except ImportError:
        print("Kaggle API not installed. Install with: pip install kaggle")
        return False
    except Exception as e:
        print(f"Failed to download from Kaggle: {e}")
        return False


if __name__ == '__main__':
    import argparse
    
    parser = argparse.ArgumentParser(description='Download or create sample personality dataset')
    parser.add_argument('--output', type=Path, default=Path('data/raw/big_five_sample.csv'),
                       help='Output CSV file path')
    parser.add_argument('--num-profiles', type=int, default=100,
                       help='Number of profiles for sample dataset')
    parser.add_argument('--kaggle', type=str,
                       help='Kaggle dataset name (e.g., tunguz/big-five-personality-test)')
    parser.add_argument('--force-sample', action='store_true',
                       help='Force creation of sample dataset even if download succeeds')
    
    args = parser.parse_args()
    
    # Create output directory
    args.output.parent.mkdir(parents=True, exist_ok=True)
    
    # Try to download from Kaggle if specified
    if args.kaggle and not args.force_sample:
        output_dir = args.output.parent
        if download_kaggle_dataset(args.kaggle, output_dir):
            print("Dataset downloaded successfully!")
            sys.exit(0)
    
    # Create sample dataset
    create_sample_dataset(args.output, args.num_profiles)
    print(f"\nSample dataset created at: {args.output}")
    print("You can now convert it to SPOTS format:")
    print(f"  python scripts/knot_validation/data_converter.py {args.output}")
