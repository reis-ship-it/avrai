#!/usr/bin/env python3
"""
Dataset Download CLI

Download personality datasets from various sources.
"""

import sys
import argparse
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.personality_data.registry.dataset_registry import get_dataset_info, list_datasets
from scripts.knot_validation.download_sample_dataset import create_sample_dataset, download_kaggle_dataset


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description='Download personality datasets',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--output', type=Path, default=Path('data/raw/big_five_sample.csv'),
                       help='Output CSV file path')
    parser.add_argument('--num-profiles', type=int, default=100,
                       help='Number of profiles for sample dataset')
    parser.add_argument('--dataset', type=str,
                       help='Dataset ID from registry to download')
    parser.add_argument('--kaggle', type=str,
                       help='Kaggle dataset name (e.g., tunguz/big-five-personality-test)')
    parser.add_argument('--force-sample', action='store_true',
                       help='Force creation of sample dataset even if download succeeds')
    parser.add_argument('--list', action='store_true',
                       help='List available datasets')
    
    args = parser.parse_args()
    
    # List datasets if requested
    if args.list:
        print("Available datasets:")
        for dataset_id in list_datasets():
            info = get_dataset_info(dataset_id)
            print(f"  {dataset_id}: {info.get('name', 'Unknown')}")
            print(f"    URL: {info.get('url', 'N/A')}")
        return
    
    # Create output directory
    args.output.parent.mkdir(parents=True, exist_ok=True)
    
    # Download from Kaggle if specified
    if args.kaggle and not args.force_sample:
        output_dir = args.output.parent
        if download_kaggle_dataset(args.kaggle, output_dir):
            print("✅ Dataset downloaded successfully!")
            return
    
    # Download from registry if specified
    if args.dataset:
        dataset_info = get_dataset_info(args.dataset)
        if dataset_info:
            url = dataset_info.get('url')
            if url and 'kaggle.com' in url:
                # Extract Kaggle dataset name from URL
                # Format: https://www.kaggle.com/datasets/username/dataset-name
                parts = url.split('/')
                if len(parts) >= 5:
                    kaggle_name = f"{parts[-2]}/{parts[-1]}"
                    if download_kaggle_dataset(kaggle_name, args.output.parent):
                        print("✅ Dataset downloaded successfully!")
                        return
    
    # Create sample dataset
    create_sample_dataset(args.output, args.num_profiles)
    print(f"\n✅ Sample dataset created at: {args.output}")
    print("You can now convert it to SPOTS format:")
    print(f"  python -m scripts.personality_data.cli.convert {args.output}")


if __name__ == '__main__':
    main()
