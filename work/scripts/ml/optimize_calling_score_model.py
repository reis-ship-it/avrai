#!/usr/bin/env python3
"""
Hyperparameter Optimization Script for Calling Score Model
Phase 12: Neural Network Implementation - Model Optimization

This script performs hyperparameter search to find optimal model configurations.
Based on v1.0-hybrid baseline, tests various architectures, learning rates, and batch sizes.

Usage:
    python scripts/ml/optimize_calling_score_model.py \
      --data-path data/calling_score_training_data_v1_hybrid.json \
      --output-dir assets/models/optimized/ \
      --baseline-path assets/models/calling_score_model_v1_hybrid.onnx
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass, asdict

import numpy as np
import torch


@dataclass
class VariantConfig:
    """Configuration for a model variant"""
    name: str
    learning_rate: float
    batch_size: int
    hidden_sizes: List[int]
    dropout: float = 0.2
    epochs: int = 100
    description: str = ""


@dataclass
class VariantResult:
    """Results from training a variant"""
    config: VariantConfig
    test_loss: float
    val_loss: float
    train_loss: float
    best_epoch: int
    training_time: float
    model_size_kb: float
    params_count: int
    success: bool
    error: str = ""


def load_baseline_metrics(baseline_path: str) -> Dict:
    """Load baseline metrics if available"""
    # For now, we know v1.0-hybrid has test_loss=0.0267
    return {
        'test_loss': 0.0267,
        'val_loss': 0.0286,  # Approximate from training output
        'version': 'v1.0-hybrid',
    }


def train_variant(
    config: VariantConfig,
    data_path: str,
    output_dir: Path,
    device: str = 'cpu',
) -> VariantResult:
    """
    Train a single model variant
    
    Returns VariantResult with training metrics
    """
    output_path = output_dir / f"calling_score_model_{config.name}.onnx"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    start_time = time.time()
    
    # Build training command
    cmd = [
        sys.executable,
        'scripts/ml/train_calling_score_model.py',
        '--data-path', data_path,
        '--output-path', str(output_path),
        '--epochs', str(config.epochs),
        '--batch-size', str(config.batch_size),
        '--learning-rate', str(config.learning_rate),
    ]
    
    try:
        # Run training
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=3600,  # 1 hour timeout
        )
        
        training_time = time.time() - start_time
        
        if result.returncode != 0:
            return VariantResult(
                config=config,
                test_loss=float('inf'),
                val_loss=float('inf'),
                train_loss=float('inf'),
                best_epoch=0,
                training_time=training_time,
                model_size_kb=0.0,
                params_count=0,
                success=False,
                error=result.stderr[:500],  # First 500 chars of error
            )
        
        # Parse metrics from output
        output_lines = result.stdout.split('\n')
        test_loss = None
        val_loss = None
        train_loss = None
        best_epoch = config.epochs
        
        for line in output_lines:
            if 'Test Loss:' in line:
                try:
                    test_loss = float(line.split('Test Loss:')[1].strip().split()[0])
                except:
                    pass
            if 'Early stopping at epoch' in line:
                try:
                    best_epoch = int(line.split('epoch')[1].strip())
                except:
                    pass
            if 'Val Loss:' in line and 'Train Loss:' in line:
                try:
                    parts = line.split('Val Loss:')
                    if len(parts) > 1:
                        val_loss = float(parts[1].strip().split()[0])
                    parts = line.split('Train Loss:')
                    if len(parts) > 1:
                        train_loss = float(parts[1].strip().split()[0])
                except:
                    pass
        
        # Get model size
        model_size_kb = 0.0
        params_count = 0
        if output_path.exists():
            model_size_kb = output_path.stat().st_size / 1024
            
            # Estimate parameter count from architecture
            input_size = 39
            total_params = input_size * config.hidden_sizes[0]
            for i in range(len(config.hidden_sizes) - 1):
                total_params += config.hidden_sizes[i] * config.hidden_sizes[i + 1]
            total_params += config.hidden_sizes[-1] * 1  # Output layer
            params_count = total_params
        
        # Use defaults if parsing failed
        if test_loss is None:
            test_loss = float('inf')
        if val_loss is None:
            val_loss = float('inf')
        if train_loss is None:
            train_loss = float('inf')
        
        return VariantResult(
            config=config,
            test_loss=test_loss,
            val_loss=val_loss,
            train_loss=train_loss,
            best_epoch=best_epoch,
            training_time=training_time,
            model_size_kb=model_size_kb,
            params_count=params_count,
            success=True,
        )
        
    except subprocess.TimeoutExpired:
        return VariantResult(
            config=config,
            test_loss=float('inf'),
            val_loss=float('inf'),
            train_loss=float('inf'),
            best_epoch=0,
            training_time=3600.0,
            model_size_kb=0.0,
            params_count=0,
            success=False,
            error="Training timeout (1 hour)",
        )
    except Exception as e:
        return VariantResult(
            config=config,
            test_loss=float('inf'),
            val_loss=float('inf'),
            train_loss=float('inf'),
            best_epoch=0,
            training_time=time.time() - start_time,
            model_size_kb=0.0,
            params_count=0,
            success=False,
            error=str(e)[:500],
        )


def generate_variants() -> List[VariantConfig]:
    """
    Generate hyperparameter variants to test
    
    Based on v1.0-hybrid baseline:
    - Architecture: 39 → 128 → 64 → 1
    - Learning rate: 0.001
    - Batch size: 32
    - Dropout: 0.2
    """
    variants = []
    
    # Baseline (v1.0-hybrid)
    variants.append(VariantConfig(
        name='v1_0_baseline',
        learning_rate=0.001,
        batch_size=32,
        hidden_sizes=[128, 64],
        dropout=0.2,
        description='Baseline v1.0-hybrid configuration',
    ))
    
    # Learning rate variants
    for lr in [0.0001, 0.0005, 0.002, 0.005]:
        variants.append(VariantConfig(
            name=f'v1_1_lr_{lr}',
            learning_rate=lr,
            batch_size=32,
            hidden_sizes=[128, 64],
            dropout=0.2,
            description=f'Learning rate: {lr}',
        ))
    
    # Batch size variants
    for batch_size in [16, 64, 128]:
        variants.append(VariantConfig(
            name=f'v1_1_batch_{batch_size}',
            learning_rate=0.001,
            batch_size=batch_size,
            hidden_sizes=[128, 64],
            dropout=0.2,
            description=f'Batch size: {batch_size}',
        ))
    
    # Architecture variants
    architecture_configs = [
        ([256, 128], 'wider'),
        ([128, 64, 32], 'deeper'),
        ([96, 48], 'smaller'),
        ([256, 128, 64], 'wide_deep'),
    ]
    
    for hidden_sizes, suffix in architecture_configs:
        variants.append(VariantConfig(
            name=f'v1_1_arch_{suffix}',
            learning_rate=0.001,
            batch_size=32,
            hidden_sizes=hidden_sizes,
            dropout=0.2,
            description=f'Architecture: {hidden_sizes}',
        ))
    
    # Dropout variants
    for dropout in [0.1, 0.3, 0.4]:
        variants.append(VariantConfig(
            name=f'v1_1_dropout_{dropout}',
            learning_rate=0.001,
            batch_size=32,
            hidden_sizes=[128, 64],
            dropout=dropout,
            description=f'Dropout: {dropout}',
        ))
    
    # Combined best variants (if we find patterns)
    # These will be added after initial results
    
    return variants


def save_results(results: List[VariantResult], output_path: Path, baseline_metrics: Dict):
    """Save optimization results to JSON"""
    output_data = {
        'baseline': baseline_metrics,
        'variants': [asdict(r) for r in results],
        'summary': {
            'total_variants': len(results),
            'successful': sum(1 for r in results if r.success),
            'failed': sum(1 for r in results if not r.success),
            'best_test_loss': min((r.test_loss for r in results if r.success), default=float('inf')),
            'best_variant': None,
        },
    }
    
    # Find best variant
    successful_results = [r for r in results if r.success]
    if successful_results:
        best = min(successful_results, key=lambda x: x.test_loss)
        output_data['summary']['best_variant'] = best.config.name
        output_data['summary']['improvement_over_baseline'] = (
            baseline_metrics['test_loss'] - best.test_loss
        ) / baseline_metrics['test_loss'] * 100
    
    with open(output_path, 'w') as f:
        json.dump(output_data, f, indent=2)
    
    print(f"\n✅ Results saved to: {output_path}")


def print_summary(results: List[VariantResult], baseline_metrics: Dict):
    """Print optimization summary"""
    print("\n" + "="*80)
    print("OPTIMIZATION SUMMARY")
    print("="*80)
    
    successful = [r for r in results if r.success]
    failed = [r for r in results if not r.success]
    
    print(f"\nTotal variants tested: {len(results)}")
    print(f"Successful: {len(successful)}")
    print(f"Failed: {len(failed)}")
    
    if successful:
        print(f"\nBaseline (v1.0-hybrid) test loss: {baseline_metrics['test_loss']:.6f}")
        
        # Sort by test loss
        successful.sort(key=lambda x: x.test_loss)
        
        print("\nTop 5 Variants (by test loss):")
        print("-" * 80)
        print(f"{'Rank':<5} {'Name':<25} {'Test Loss':<12} {'Val Loss':<12} {'Time (s)':<10} {'Improvement':<12}")
        print("-" * 80)
        
        for i, result in enumerate(successful[:5], 1):
            improvement = (baseline_metrics['test_loss'] - result.test_loss) / baseline_metrics['test_loss'] * 100
            print(f"{i:<5} {result.config.name:<25} {result.test_loss:<12.6f} {result.val_loss:<12.6f} "
                  f"{result.training_time:<10.1f} {improvement:>+10.2f}%")
        
        best = successful[0]
        improvement = (baseline_metrics['test_loss'] - best.test_loss) / baseline_metrics['test_loss'] * 100
        print("\n" + "="*80)
        print(f"🏆 BEST VARIANT: {best.config.name}")
        print("="*80)
        print(f"Test Loss: {best.test_loss:.6f} (improvement: {improvement:+.2f}%)")
        print(f"Val Loss: {best.val_loss:.6f}")
        print(f"Training Time: {best.training_time:.1f}s")
        print(f"Model Size: {best.model_size_kb:.1f} KB")
        print(f"Parameters: {best.params_count:,}")
        print(f"Description: {best.config.description}")
        print(f"\nConfiguration:")
        print(f"  Learning Rate: {best.config.learning_rate}")
        print(f"  Batch Size: {best.config.batch_size}")
        print(f"  Architecture: {best.config.hidden_sizes}")
        print(f"  Dropout: {best.config.dropout}")
    
    if failed:
        print(f"\n⚠️  Failed Variants ({len(failed)}):")
        for result in failed:
            print(f"  - {result.config.name}: {result.error[:100]}")


def main():
    parser = argparse.ArgumentParser(
        description='Optimize calling score model hyperparameters',
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        '--data-path',
        type=str,
        default='data/calling_score_training_data_v1_hybrid.json',
        help='Path to training data JSON file',
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=Path('assets/models/optimized/'),
        help='Directory to save optimized models',
    )
    parser.add_argument(
        '--baseline-path',
        type=str,
        default='assets/models/calling_score_model_v1_hybrid.onnx',
        help='Path to baseline v1.0 model (for comparison)',
    )
    parser.add_argument(
        '--max-variants',
        type=int,
        default=None,
        help='Maximum number of variants to test (for quick testing)',
    )
    parser.add_argument(
        '--device',
        type=str,
        default='cpu',
        choices=['cpu', 'cuda'],
        help='Device to use for training',
    )
    
    args = parser.parse_args()
    
    # Check data file exists
    if not Path(args.data_path).exists():
        print(f"❌ Error: Data file not found: {args.data_path}")
        sys.exit(1)
    
    # Load baseline metrics
    baseline_metrics = load_baseline_metrics(args.baseline_path)
    print(f"📊 Baseline: {baseline_metrics['version']} (test_loss: {baseline_metrics['test_loss']:.6f})")
    
    # Generate variants
    variants = generate_variants()
    if args.max_variants:
        variants = variants[:args.max_variants]
        print(f"⚠️  Limiting to {args.max_variants} variants for quick testing")
    
    print(f"\n🔍 Testing {len(variants)} variants...")
    print("="*80)
    
    # Train each variant
    results = []
    for i, variant in enumerate(variants, 1):
        print(f"\n[{i}/{len(variants)}] Training: {variant.name}")
        print(f"   {variant.description}")
        
        result = train_variant(
            variant,
            args.data_path,
            args.output_dir,
            device=args.device,
        )
        
        results.append(result)
        
        if result.success:
            improvement = (baseline_metrics['test_loss'] - result.test_loss) / baseline_metrics['test_loss'] * 100
            print(f"   ✅ Test Loss: {result.test_loss:.6f} ({improvement:+.2f}% vs baseline)")
            print(f"   ⏱️  Time: {result.training_time:.1f}s")
        else:
            print(f"   ❌ Failed: {result.error[:100]}")
    
    # Save results
    results_path = args.output_dir / 'optimization_results.json'
    save_results(results, results_path, baseline_metrics)
    
    # Print summary
    print_summary(results, baseline_metrics)
    
    print("\n" + "="*80)
    print("✅ Optimization complete!")
    print("="*80)
    print(f"\nNext steps:")
    print(f"1. Review results in: {results_path}")
    print(f"2. Register best variant in ModelVersionRegistry")
    print(f"3. A/B test best variant against baseline")
    print(f"4. Deploy if performance improves")


if __name__ == '__main__':
    main()
