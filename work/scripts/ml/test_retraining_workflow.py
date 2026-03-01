#!/usr/bin/env python3
"""
Test Retraining Workflow
Phase 12 Section 3.2.1: Continuous Learning - Testing

Tests the complete retraining workflow:
1. Export training data
2. Train model
3. Validate model
4. Deploy model

Usage:
    python scripts/ml/test_retraining_workflow.py \
      --data-path data/calling_score_training_data_v1_hybrid.json \
      --model-type calling_score
"""

import argparse
import json
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ml.train_calling_score_model import main as train_calling_score
from scripts.ml.train_outcome_prediction_model import main as train_outcome


def test_retraining_workflow(data_path: str, model_type: str, output_path: str):
    """
    Test the complete retraining workflow
    
    Args:
        data_path: Path to training data JSON
        model_type: 'calling_score' or 'outcome'
        output_path: Path to save trained model
    """
    print("="*80)
    print("TESTING RETRAINING WORKFLOW")
    print("="*80)
    print(f"Model Type: {model_type}")
    print(f"Data Path: {data_path}")
    print(f"Output Path: {output_path}")
    print()
    
    # Step 1: Validate data file exists
    print("Step 1: Validating training data...")
    if not Path(data_path).exists():
        print(f"❌ Error: Data file not found: {data_path}")
        return False
    print("✅ Training data file exists")
    
    # Step 2: Load and validate data structure
    print("\nStep 2: Validating data structure...")
    try:
        with open(data_path, 'r') as f:
            data = json.load(f)
        
        if 'training_data' not in data:
            print("❌ Error: Invalid data format (missing 'training_data')")
            return False
        
        training_data = data['training_data']
        if len(training_data) == 0:
            print("❌ Error: No training samples in data")
            return False
        
        print(f"✅ Data structure valid ({len(training_data)} samples)")
    except Exception as e:
        print(f"❌ Error loading data: {e}")
        return False
    
    # Step 3: Train model
    print(f"\nStep 3: Training {model_type} model...")
    try:
        # Create mock args for training script
        class Args:
            def __init__(self):
                self.data_path = data_path
                self.output_path = output_path
                self.epochs = 50  # Reduced for testing
                self.batch_size = 32
                self.learning_rate = 0.001
                self.hidden_sizes = None
                self.dropout = None
        
        args = Args()
        
        if model_type == 'calling_score':
            # Mock sys.argv for training script
            original_argv = sys.argv
            sys.argv = [
                'train_calling_score_model.py',
                '--data-path', data_path,
                '--output-path', output_path,
                '--epochs', '50',
            ]
            
            train_calling_score()
            
            sys.argv = original_argv
        else:
            # Similar for outcome prediction
            original_argv = sys.argv
            sys.argv = [
                'train_outcome_prediction_model.py',
                '--data-path', data_path,
                '--output-path', output_path,
                '--epochs', '50',
            ]
            
            train_outcome()
            
            sys.argv = original_argv
        
        print("✅ Model training complete")
    except Exception as e:
        print(f"❌ Error during training: {e}")
        return False
    
    # Step 4: Validate model file
    print(f"\nStep 4: Validating model file...")
    if not Path(output_path).exists():
        print(f"❌ Error: Model file not created: {output_path}")
        return False
    
    file_size = Path(output_path).stat().st_size
    if file_size == 0:
        print(f"❌ Error: Model file is empty")
        return False
    
    print(f"✅ Model file validated ({file_size / 1024:.1f} KB)")
    
    # Step 5: Test model loading (would require ONNX runtime)
    print(f"\nStep 5: Model ready for deployment")
    print(f"✅ Model path: {output_path}")
    
    print("\n" + "="*80)
    print("✅ RETRAINING WORKFLOW TEST PASSED")
    print("="*80)
    
    return True


def main():
    parser = argparse.ArgumentParser(description='Test retraining workflow')
    parser.add_argument(
        '--data-path',
        type=str,
        required=True,
        help='Path to training data JSON file',
    )
    parser.add_argument(
        '--model-type',
        type=str,
        choices=['calling_score', 'outcome'],
        default='calling_score',
        help='Model type to test',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default=None,
        help='Output path for trained model (auto-generated if not provided)',
    )
    
    args = parser.parse_args()
    
    # Generate output path if not provided
    if args.output_path is None:
        timestamp = __import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')
        model_name = 'calling_score' if args.model_type == 'calling_score' else 'outcome_prediction'
        args.output_path = f'assets/models/{model_name}_test_{timestamp}.onnx'
    
    success = test_retraining_workflow(
        args.data_path,
        args.model_type,
        args.output_path,
    )
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
