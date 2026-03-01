#!/usr/bin/env python3
"""
Personality Data Converter CLI

Main command-line interface for converting personality datasets.
"""

import sys
import argparse
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.personality_data.converter import convert_dataset
from scripts.personality_data.processors.ground_truth_generator import GroundTruthGenerator
from scripts.personality_data.registry.dataset_registry import list_datasets, get_dataset_info
from scripts.personality_data.registry.converter_registry import list_converters


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description='Convert personality datasets to SPOTS format',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Convert Big Five dataset
  python -m scripts.personality_data.cli.convert \\
      data/raw/big_five.csv \\
      --output data/processed/spots_profiles.json \\
      --source big_five

  # Convert with dataset registry
  python -m scripts.personality_data.cli.convert \\
      data/raw/big_five.csv \\
      --output data/processed/spots_profiles.json \\
      --dataset big_five_kaggle

  # Convert and generate ground truth
  python -m scripts.personality_data.cli.convert \\
      data/raw/big_five.csv \\
      --output data/processed/spots_profiles.json \\
      --ground-truth data/processed/ground_truth.json \\
      --source big_five
        """
    )
    
    parser.add_argument('input_file', type=Path, nargs='?', help='Input dataset file (CSV or JSON)')
    parser.add_argument('--output', type=Path, help='Output SPOTS profiles file (default: input_file_spots.json)')
    parser.add_argument('--source', type=str, default='big_five',
                       help='Source format or converter ID (default: big_five)')
    parser.add_argument('--dataset', type=str,
                       help='Dataset ID from registry (overrides --source if provided)')
    parser.add_argument('--format', choices=['csv', 'json', 'auto'], default='auto',
                       help='Input file format (default: auto-detect)')
    parser.add_argument('--ground-truth', type=Path,
                       help='Output ground truth file (optional)')
    parser.add_argument('--threshold', type=float, default=0.6,
                       help='Compatibility threshold for ground truth (default: 0.6)')
    parser.add_argument('--noise', type=float, default=0.05,
                       help='Noise level for ground truth (default: 0.05)')
    parser.add_argument('--no-validate', action='store_true',
                       help='Skip output validation')
    parser.add_argument('--list-datasets', action='store_true',
                       help='List available datasets and exit')
    parser.add_argument('--list-converters', action='store_true',
                       help='List available converters and exit')
    
    args = parser.parse_args()
    
    # List datasets/converters if requested
    if args.list_datasets:
        print("Available datasets:")
        for dataset_id in list_datasets():
            info = get_dataset_info(dataset_id)
            print(f"  {dataset_id}: {info.get('name', 'Unknown')}")
            print(f"    URL: {info.get('url', 'N/A')}")
        return
    
    if args.list_converters:
        print("Available converters:")
        for converter_id in list_converters():
            print(f"  {converter_id}")
        return
    
    # Require input_file if not listing
    if args.input_file is None:
        parser.error("input_file is required (unless using --list-datasets or --list-converters)")
    
    # Determine source format from dataset if provided
    source_format = args.source
    dataset_id = args.dataset
    if dataset_id:
        dataset_info = get_dataset_info(dataset_id)
        if dataset_info:
            source_format = dataset_info.get('converter', args.source)
        else:
            print(f"Warning: Dataset '{dataset_id}' not found, using --source format")
    
    # Determine output file
    if args.output is None:
        args.output = args.input_file.parent / f"{args.input_file.stem}_spots.json"
    
    # Convert dataset
    try:
        spots_profiles = convert_dataset(
            args.input_file,
            args.output,
            source_format=source_format,
            dataset_id=dataset_id,
            input_file_format=args.format,
            validate=not args.no_validate
        )
        
        # Generate ground truth if requested
        if args.ground_truth:
            generator = GroundTruthGenerator(
                compatibility_threshold=args.threshold,
                noise_level=args.noise
            )
            generator.generate(spots_profiles, args.ground_truth)
        
        print(f"\n✅ Conversion complete!")
        print(f"   Output: {args.output}")
        if args.ground_truth:
            print(f"   Ground truth: {args.ground_truth}")
    
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
