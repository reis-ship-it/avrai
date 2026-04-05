#!/usr/bin/env python3
"""
ONNX Export Script for Quantum Models
Phase 3: ML Model Training - ONNX Export

This script exports PyTorch models to ONNX format.
It uses a workaround for PyTorch 2.10.0 compatibility issues.

Usage:
    # Export quantum optimization model
    python scripts/ml/export_quantum_models_to_onnx.py --model optimization --pth-path assets/models/quantum_optimization_model.pth --onnx-path assets/models/quantum_optimization_model.onnx
    
    # Export entanglement model
    python scripts/ml/export_quantum_models_to_onnx.py --model entanglement --pth-path assets/models/entanglement_model.pth --onnx-path assets/models/entanglement_model.onnx

Note: If ONNX export fails with PyTorch 2.10.0, you can:
1. Use PyTorch 2.0.0: pip install torch==2.0.0 onnx onnxruntime
2. Or use this script which attempts multiple export strategies
"""

import argparse
import sys
from pathlib import Path

import torch
import torch.nn as nn

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from scripts.ml.train_quantum_optimization_model import QuantumOptimizationModel
from scripts.ml.train_entanglement_model import EntanglementModel


def export_optimization_model(pth_path: str, onnx_path: str):
    """Export quantum optimization model to ONNX"""
    print(f"Loading model from {pth_path}...")
    
    # Create model instance
    model = QuantumOptimizationModel(
        input_size=13,
        hidden_sizes=[64, 32],
        weight_output_size=5,
        threshold_output_size=1,
        basis_output_size=12,
        dropout=0.2,
    )
    
    # Load state dict
    model.load_state_dict(torch.load(pth_path, map_location='cpu'))
    model.eval()
    
    # Create export model (no conditionals to avoid Union types)
    class MultiTaskExportModel(nn.Module):
        def __init__(self, encoder, weight_head, threshold_head, basis_head):
            super().__init__()
            self.encoder = encoder
            self.weight_head = weight_head
            self.threshold_head = threshold_head
            self.basis_head = basis_head
        
        def forward(self, x):
            encoded = self.encoder(x)
            weights = self.weight_head(encoded)
            threshold = self.threshold_head(encoded)
            basis = self.basis_head(encoded)
            return torch.cat([weights, threshold, basis], dim=1)
    
    export_model = MultiTaskExportModel(
        encoder=model.encoder,
        weight_head=model.weight_head,
        threshold_head=model.threshold_head,
        basis_head=model.basis_head,
    )
    export_model.eval()
    
    dummy_input = torch.randn(1, 13)
    
    print("Attempting ONNX export with multiple strategies...")
    
    # Strategy 1: Try torch.jit.trace first, then export
    try:
        print("  Strategy 1: Using torch.jit.trace...")
        traced_model = torch.jit.trace(export_model, dummy_input)
        traced_model.eval()
        
        torch.onnx.export(
            traced_model,
            dummy_input,
            onnx_path,
            input_names=['input'],
            output_names=['output'],
            opset_version=11,  # Lower opset for compatibility
            export_params=True,
            do_constant_folding=True,
            verbose=False,
        )
        print(f"✅ Model exported to ONNX using torch.jit.trace: {onnx_path}")
        print("Output format: [weights(5), threshold(1), basis(12)] = 18 values")
        return True
    except Exception as e1:
        print(f"  Strategy 1 failed: {e1}")
        
        # Strategy 2: Try direct export with opset 11
        try:
            print("  Strategy 2: Direct export with opset 11...")
            torch.onnx.export(
                export_model,
                dummy_input,
                onnx_path,
                input_names=['input'],
                output_names=['output'],
                opset_version=11,
                export_params=True,
                do_constant_folding=True,
                verbose=False,
                dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}},
            )
            print(f"✅ Model exported to ONNX with opset 11: {onnx_path}")
            print("Output format: [weights(5), threshold(1), basis(12)] = 18 values")
            return True
        except Exception as e2:
            print(f"  Strategy 2 failed: {e2}")
            
            # Strategy 3: Try with opset 12
            try:
                print("  Strategy 3: Direct export with opset 12...")
                torch.onnx.export(
                    export_model,
                    dummy_input,
                    onnx_path,
                    input_names=['input'],
                    output_names=['output'],
                    opset_version=12,
                    export_params=True,
                    do_constant_folding=True,
                    verbose=False,
                )
                print(f"✅ Model exported to ONNX with opset 12: {onnx_path}")
                print("Output format: [weights(5), threshold(1), basis(12)] = 18 values")
                return True
            except Exception as e3:
                print(f"  Strategy 3 failed: {e3}")
                print(f"\n❌ All ONNX export strategies failed")
                print("\nWorkaround options:")
                print("1. Use an older Python version (3.9-3.11) with PyTorch 2.0.0")
                print("2. Export will be done when PyTorch/onnxscript compatibility is fixed")
                print("3. Use PyTorch models directly in Python backend")
                return False


def export_entanglement_model(pth_path: str, onnx_path: str):
    """Export entanglement model to ONNX"""
    print(f"Loading model from {pth_path}...")
    
    # Create model instance
    model = EntanglementModel(
        input_size=12,
        hidden_sizes=[64, 32],
        output_size=66,
        dropout=0.2,
    )
    
    # Load state dict
    model.load_state_dict(torch.load(pth_path, map_location='cpu'))
    model.eval()
    
    dummy_input = torch.randn(1, 12)
    
    print("Attempting ONNX export with multiple strategies...")
    
    # Strategy 1: Try torch.jit.trace first, then export
    try:
        print("  Strategy 1: Using torch.jit.trace...")
        traced_model = torch.jit.trace(model, dummy_input)
        traced_model.eval()
        
        torch.onnx.export(
            traced_model,
            dummy_input,
            onnx_path,
            input_names=['input'],
            output_names=['output'],
            opset_version=11,  # Lower opset for compatibility
            export_params=True,
            do_constant_folding=True,
            verbose=False,
        )
        print(f"✅ Model exported to ONNX using torch.jit.trace: {onnx_path}")
        print("Output format: 66 correlation values (one per dimension pair)")
        return True
    except Exception as e1:
        print(f"  Strategy 1 failed: {e1}")
        
        # Strategy 2: Try direct export with opset 11
        try:
            print("  Strategy 2: Direct export with opset 11...")
            torch.onnx.export(
                model,
                dummy_input,
                onnx_path,
                input_names=['input'],
                output_names=['output'],
                opset_version=11,
                export_params=True,
                do_constant_folding=True,
                verbose=False,
                dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}},
            )
            print(f"✅ Model exported to ONNX with opset 11: {onnx_path}")
            print("Output format: 66 correlation values (one per dimension pair)")
            return True
        except Exception as e2:
            print(f"  Strategy 2 failed: {e2}")
            
            # Strategy 3: Try with opset 12
            try:
                print("  Strategy 3: Direct export with opset 12...")
                torch.onnx.export(
                    model,
                    dummy_input,
                    onnx_path,
                    input_names=['input'],
                    output_names=['output'],
                    opset_version=12,
                    export_params=True,
                    do_constant_folding=True,
                    verbose=False,
                )
                print(f"✅ Model exported to ONNX with opset 12: {onnx_path}")
                print("Output format: 66 correlation values (one per dimension pair)")
                return True
            except Exception as e3:
                print(f"  Strategy 3 failed: {e3}")
                print(f"\n❌ All ONNX export strategies failed")
                print("\nWorkaround options:")
                print("1. Use an older Python version (3.9-3.11) with PyTorch 2.0.0")
                print("2. Export will be done when PyTorch/onnxscript compatibility is fixed")
                print("3. Use PyTorch models directly in Python backend")
                return False


def main():
    parser = argparse.ArgumentParser(description='Export quantum models to ONNX')
    parser.add_argument(
        '--model',
        type=str,
        required=True,
        choices=['optimization', 'entanglement'],
        help='Model type to export',
    )
    parser.add_argument(
        '--pth-path',
        type=str,
        required=True,
        help='Path to PyTorch .pth model file',
    )
    parser.add_argument(
        '--onnx-path',
        type=str,
        required=True,
        help='Path to output ONNX model file',
    )
    
    args = parser.parse_args()
    
    if args.model == 'optimization':
        success = export_optimization_model(args.pth_path, args.onnx_path)
    else:
        success = export_entanglement_model(args.pth_path, args.onnx_path)
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
