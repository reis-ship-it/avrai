#!/usr/bin/env python3
"""
Training script for Quantum Optimization ML Model
Phase 3: ML Model Training

This script trains a neural network model to optimize:
- Superposition weights for data source combination
- Compatibility thresholds for context-specific matching
- Measurement basis for optimal state measurement

Model Architecture:
- Input: 13 features (12 SPOTS dimensions + 1 use case encoding)
- Architecture: MLP (13 → 64 → 32 → output_size)
- Output: 
  - Weight optimization: 5 weights (one per data source)
  - Threshold optimization: 1 threshold value
  - Basis prediction: 12 dimension importance scores

Usage:
    python scripts/ml/train_quantum_optimization_model.py [--data-path DATA_PATH] [--output-path OUTPUT_PATH]
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# Add project root to path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


class QuantumOptimizationDataset(Dataset):
    """Dataset for quantum optimization training data"""
    
    def __init__(self, features: np.ndarray, weight_labels: Optional[np.ndarray] = None, 
                 threshold_labels: Optional[np.ndarray] = None, basis_labels: Optional[np.ndarray] = None):
        """
        Args:
            features: Input features (N, 13) - 12 dimensions + use case
            weight_labels: Target weights (N, 5) - one per data source
            threshold_labels: Target thresholds (N, 1)
            basis_labels: Target basis importance (N, 12)
        """
        self.features = torch.FloatTensor(features)
        self.weight_labels = torch.FloatTensor(weight_labels) if weight_labels is not None else None
        self.threshold_labels = torch.FloatTensor(threshold_labels) if threshold_labels is not None else None
        self.basis_labels = torch.FloatTensor(basis_labels) if basis_labels is not None else None
    
    def __len__(self):
        return len(self.features)
    
    def __getitem__(self, idx):
        result = {'features': self.features[idx]}
        if self.weight_labels is not None:
            result['weights'] = self.weight_labels[idx]
        if self.threshold_labels is not None:
            result['threshold'] = self.threshold_labels[idx]
        if self.basis_labels is not None:
            result['basis'] = self.basis_labels[idx]
        return result


class QuantumOptimizationModel(nn.Module):
    """Neural network model for quantum optimization"""
    
    def __init__(self, input_size: int = 13, hidden_sizes: List[int] = [64, 32], 
                 weight_output_size: int = 5, threshold_output_size: int = 1, 
                 basis_output_size: int = 12, dropout: float = 0.2):
        super(QuantumOptimizationModel, self).__init__()
        
        # Shared encoder
        encoder_layers = []
        prev_size = input_size
        for hidden_size in hidden_sizes:
            encoder_layers.append(nn.Linear(prev_size, hidden_size))
            encoder_layers.append(nn.ReLU())
            encoder_layers.append(nn.Dropout(dropout))
            prev_size = hidden_size
        
        self.encoder = nn.Sequential(*encoder_layers)
        
        # Task-specific heads
        self.weight_head = nn.Sequential(
            nn.Linear(prev_size, weight_output_size),
            nn.Softmax(dim=1)  # Normalize weights to sum to 1.0
        )
        
        self.threshold_head = nn.Sequential(
            nn.Linear(prev_size, threshold_output_size),
            nn.Sigmoid()  # Threshold in [0, 1]
        )
        
        self.basis_head = nn.Sequential(
            nn.Linear(prev_size, basis_output_size),
            nn.Softmax(dim=1)  # Importance scores sum to 1.0
        )
    
    def forward(self, x, task: str = 'weights'):
        """
        Forward pass
        
        Args:
            x: Input features (batch_size, 13)
            task: 'weights', 'threshold', or 'basis'
        """
        encoded = self.encoder(x)
        
        if task == 'weights':
            return self.weight_head(encoded)
        elif task == 'threshold':
            return self.threshold_head(encoded)
        elif task == 'basis':
            return self.basis_head(encoded)
        else:
            raise ValueError(f"Unknown task: {task}")


def load_training_data(data_path: str) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
    """
    Load training data from JSON file
    
    Expected JSON format:
    {
        "training_data": [
            {
                "personality_dimensions": {...},  # 12 SPOTS dimensions
                "use_case": "matching",  # or "recommendation", "compatibility", etc.
                "optimal_weights": {...},  # Map of data source to weight
                "optimal_threshold": 0.65,
                "optimal_basis": [0.1, 0.2, ...]  # 12 dimension importance scores
            },
            ...
        ]
    }
    """
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"Data file not found: {data_path}")
    
    with open(data_path, 'r') as f:
        data = json.load(f)
    
    training_records = data.get('training_data', [])
    
    if len(training_records) == 0:
        raise ValueError("No training data found in file")
    
    # Extract features and labels
    features = []
    weight_labels = []
    threshold_labels = []
    basis_labels = []
    
    # Use case encoding
    use_cases = ['matching', 'recommendation', 'compatibility', 'prediction', 'analysis']
    
    for record in training_records:
        # Extract feature vector (13D: 12 dimensions + use case)
        feature_vector = extract_features(record, use_cases)
        features.append(feature_vector)
        
        # Extract labels
        optimal_weights = record.get('optimal_weights', {})
        weight_vector = [
            optimal_weights.get('personality', 0.4),
            optimal_weights.get('behavioral', 0.3),
            optimal_weights.get('relationship', 0.2),
            optimal_weights.get('temporal', 0.05),
            optimal_weights.get('contextual', 0.05),
        ]
        # Normalize to sum to 1.0
        weight_sum = sum(weight_vector)
        if weight_sum > 0:
            weight_vector = [w / weight_sum for w in weight_vector]
        weight_labels.append(weight_vector)
        
        threshold_labels.append([record.get('optimal_threshold', 0.5)])
        
        basis_importance = record.get('optimal_basis', [0.083] * 12)  # Equal importance default
        if len(basis_importance) != 12:
            basis_importance = [0.083] * 12
        # Normalize to sum to 1.0
        basis_sum = sum(basis_importance)
        if basis_sum > 0:
            basis_importance = [b / basis_sum for b in basis_importance]
        basis_labels.append(basis_importance)
    
    return np.array(features), {
        'weights': np.array(weight_labels),
        'threshold': np.array(threshold_labels),
        'basis': np.array(basis_labels),
    }


def extract_features(record: Dict, use_cases: List[str]) -> List[float]:
    """
    Extract 13D feature vector from training record
    
    Feature order:
    - [0-11]: Personality dimensions (12D)
    - [12]: Use case encoding (0.0-1.0)
    """
    features = []
    
    # Personality dimensions (12D)
    personality_dims = record.get('personality_dimensions', {})
    dimension_names = [
        'exploration_eagerness',
        'community_orientation',
        'authenticity_preference',
        'social_discovery_style',
        'temporal_flexibility',
        'location_adventurousness',
        'curation_tendency',
        'trust_network_reliance',
        'energy_preference',
        'novelty_seeking',
        'value_orientation',
        'crowd_tolerance',
    ]
    
    for dim in dimension_names:
        features.append(personality_dims.get(dim, 0.5))
    
    # Use case encoding (0.0-1.0)
    use_case = record.get('use_case', 'matching')
    use_case_index = use_cases.index(use_case) if use_case in use_cases else 0
    use_case_encoding = use_case_index / len(use_cases)
    features.append(use_case_encoding)
    
    return features


def train_model(
    model: nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    num_epochs: int = 100,
    learning_rate: float = 0.001,
    device: str = 'cpu',
) -> Dict:
    """Train the model and return training history"""
    
    model = model.to(device)
    criterion_weights = nn.MSELoss()
    criterion_threshold = nn.MSELoss()
    criterion_basis = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    
    train_losses = {'weights': [], 'threshold': [], 'basis': []}
    val_losses = {'weights': [], 'threshold': [], 'basis': []}
    
    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0
    
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss_weights = 0.0
        train_loss_threshold = 0.0
        train_loss_basis = 0.0
        
        for batch in train_loader:
            features = batch['features'].to(device)
            
            optimizer.zero_grad()
            
            # Train all three tasks
            total_loss = 0.0
            
            if 'weights' in batch:
                weights_pred = model(features, task='weights')
                weights_true = batch['weights'].to(device)
                loss_weights = criterion_weights(weights_pred, weights_true)
                total_loss += loss_weights
            
            if 'threshold' in batch:
                threshold_pred = model(features, task='threshold')
                threshold_true = batch['threshold'].to(device)
                loss_threshold = criterion_threshold(threshold_pred, threshold_true)
                total_loss += loss_threshold
            
            if 'basis' in batch:
                basis_pred = model(features, task='basis')
                basis_true = batch['basis'].to(device)
                loss_basis = criterion_basis(basis_pred, basis_true)
                total_loss += loss_basis
            
            total_loss.backward()
            optimizer.step()
            
            train_loss_weights += loss_weights.item() if 'weights' in batch else 0.0
            train_loss_threshold += loss_threshold.item() if 'threshold' in batch else 0.0
            train_loss_basis += loss_basis.item() if 'basis' in batch else 0.0
        
        train_loss_weights /= len(train_loader)
        train_loss_threshold /= len(train_loader)
        train_loss_basis /= len(train_loader)
        
        train_losses['weights'].append(train_loss_weights)
        train_losses['threshold'].append(train_loss_threshold)
        train_losses['basis'].append(train_loss_basis)
        
        # Validation
        model.eval()
        val_loss_weights = 0.0
        val_loss_threshold = 0.0
        val_loss_basis = 0.0
        
        with torch.no_grad():
            for batch in val_loader:
                features = batch['features'].to(device)
                
                if 'weights' in batch:
                    weights_pred = model(features, task='weights')
                    weights_true = batch['weights'].to(device)
                    val_loss_weights += criterion_weights(weights_pred, weights_true).item()
                
                if 'threshold' in batch:
                    threshold_pred = model(features, task='threshold')
                    threshold_true = batch['threshold'].to(device)
                    val_loss_threshold += criterion_threshold(threshold_pred, threshold_true).item()
                
                if 'basis' in batch:
                    basis_pred = model(features, task='basis')
                    basis_true = batch['basis'].to(device)
                    val_loss_basis += criterion_basis(basis_pred, basis_true).item()
        
        val_loss_weights /= len(val_loader)
        val_loss_threshold /= len(val_loader)
        val_loss_basis /= len(val_loader)
        
        val_losses['weights'].append(val_loss_weights)
        val_losses['threshold'].append(val_loss_threshold)
        val_losses['basis'].append(val_loss_basis)
        
        total_val_loss = val_loss_weights + val_loss_threshold + val_loss_basis
        
        # Early stopping
        if total_val_loss < best_val_loss:
            best_val_loss = total_val_loss
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch + 1}")
                break
        
        if (epoch + 1) % 10 == 0:
            print(f"Epoch {epoch + 1}/{num_epochs}")
            print(f"  Train - Weights: {train_loss_weights:.4f}, Threshold: {train_loss_threshold:.4f}, Basis: {train_loss_basis:.4f}")
            print(f"  Val   - Weights: {val_loss_weights:.4f}, Threshold: {val_loss_threshold:.4f}, Basis: {val_loss_basis:.4f}")
    
    return {
        'train_losses': train_losses,
        'val_losses': val_losses,
    }


def export_to_onnx(model: nn.Module, output_path: str, input_size: int = 13):
    """Export model to ONNX format
    
    Note: Since the model has multiple task heads, we export a wrapper
    that outputs all three tasks (weights, threshold, basis) simultaneously.
    
    The issue is that the base model's forward() method uses conditional logic
    which creates Union types that ONNX can't handle. We work around this by
    creating a completely new model class that directly concatenates all outputs
    without any conditional logic.
    """
    model.eval()
    
    # Create a completely new model class (not a wrapper) to avoid Union types
    # This model directly outputs all three tasks without any conditionals
    class MultiTaskExportModel(nn.Module):
        def __init__(self, encoder, weight_head, threshold_head, basis_head):
            super().__init__()
            self.encoder = encoder
            self.weight_head = weight_head
            self.threshold_head = threshold_head
            self.basis_head = basis_head
        
        def forward(self, x):
            # No conditionals - always outputs all three tasks
            encoded = self.encoder(x)
            weights = self.weight_head(encoded)
            threshold = self.threshold_head(encoded)
            basis = self.basis_head(encoded)
            # Concatenate all outputs: [weights(5), threshold(1), basis(12)] = 18 values
            return torch.cat([weights, threshold, basis], dim=1)
    
    # Create new model instance with copied submodules
    export_model = MultiTaskExportModel(
        encoder=model.encoder,
        weight_head=model.weight_head,
        threshold_head=model.threshold_head,
        basis_head=model.basis_head,
    )
    export_model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, input_size)
    
    # Try exporting with multiple strategies
    try:
        # Strategy 1: Direct export with opset 18
        torch.onnx.export(
            export_model,
            dummy_input,
            output_path,
            input_names=['input'],
            output_names=['output'],  # Combined output: [weights(5), threshold(1), basis(12)] = 18 values
            opset_version=18,
            export_params=True,
            do_constant_folding=True,
            verbose=False,
        )
        print(f"✅ Model exported to ONNX: {output_path}")
        print("Note: Output format is [weights(5), threshold(1), basis(12)] = 18 values total")
    except Exception as e1:
        print(f"torch.export failed: {e1}")
        try:
            # Fallback: Try with opset 18
            torch.onnx.export(
                export_model,
                dummy_input,
                output_path,
                input_names=['input'],
                output_names=['output'],  # Combined output: [weights(5), threshold(1), basis(12)] = 18 values
                opset_version=18,
                export_params=True,
                do_constant_folding=True,
                verbose=False,
            )
            print(f"✅ Model exported to ONNX (opset 18): {output_path}")
            print("Note: Output format is [weights(5), threshold(1), basis(12)] = 18 values total")
        except Exception as e2:
            print(f"Export with opset 18 failed: {e2}")
            try:
                # Try with opset 11
                torch.onnx.export(
                    export_model,
                    dummy_input,
                    output_path,
                    input_names=['input'],
                    output_names=['output'],
                    opset_version=11,
                    export_params=True,
                    do_constant_folding=True,
                    verbose=False,
                )
                print(f"✅ Model exported to ONNX (opset 11): {output_path}")
                print("Note: Output format is [weights(5), threshold(1), basis(12)] = 18 values total")
            except Exception as e3:
                print(f"❌ All ONNX export strategies failed:")
                print(f"  torch.export: {e1}")
                print(f"  Opset 18: {e2}")
                print(f"  Opset 11: {e3}")
                print("\nWorkaround: Use PyTorch 2.0.0 for ONNX export:")
                print("  pip install torch==2.0.0 onnx onnxruntime")
                print("  Then run: python scripts/ml/export_quantum_models_to_onnx.py")
                print("Saving model state dict instead - ONNX export can be done later")
                # Save PyTorch model state as fallback
                torch.save(model.state_dict(), output_path.replace('.onnx', '.pth'))
                print(f"Model state saved to: {output_path.replace('.onnx', '.pth')}")
                print("You can convert to ONNX later or use the PyTorch model directly")


def generate_synthetic_training_data(num_samples: int = 10000, output_path: str = 'data/quantum_optimization_training_data.json'):
    """
    Generate synthetic training data for quantum optimization model
    
    This creates training examples with:
    - Random personality dimensions
    - Random use cases
    - Optimal weights/thresholds/basis based on heuristics
    """
    print(f"Generating {num_samples} synthetic training samples...")
    
    training_data = []
    use_cases = ['matching', 'recommendation', 'compatibility', 'prediction', 'analysis']
    dimension_names = [
        'exploration_eagerness',
        'community_orientation',
        'authenticity_preference',
        'social_discovery_style',
        'temporal_flexibility',
        'location_adventurousness',
        'curation_tendency',
        'trust_network_reliance',
        'energy_preference',
        'novelty_seeking',
        'value_orientation',
        'crowd_tolerance',
    ]
    
    np.random.seed(42)
    
    for i in range(num_samples):
        # Random personality dimensions
        personality_dims = {dim: float(np.random.uniform(0.0, 1.0)) for dim in dimension_names}
        
        # Random use case
        use_case = np.random.choice(use_cases)
        
        # Heuristic-based optimal weights (can be improved with real data)
        # Higher personality weight for matching, higher behavioral for prediction
        if use_case == 'matching':
            optimal_weights = {
                'personality': 0.5,
                'behavioral': 0.3,
                'relationship': 0.15,
                'temporal': 0.03,
                'contextual': 0.02,
            }
        elif use_case == 'prediction':
            optimal_weights = {
                'personality': 0.3,
                'behavioral': 0.5,
                'relationship': 0.1,
                'temporal': 0.05,
                'contextual': 0.05,
            }
        else:
            optimal_weights = {
                'personality': 0.4,
                'behavioral': 0.3,
                'relationship': 0.2,
                'temporal': 0.05,
                'contextual': 0.05,
            }
        
        # Optimal threshold based on use case
        optimal_threshold = {
            'matching': 0.6,
            'recommendation': 0.5,
            'compatibility': 0.7,
            'prediction': 0.55,
            'analysis': 0.4,
        }.get(use_case, 0.5)
        
        # Optimal basis: higher importance for dimensions with higher values
        dim_values = [personality_dims[dim] for dim in dimension_names]
        basis_importance = [v / sum(dim_values) if sum(dim_values) > 0 else 1.0/12 for v in dim_values]
        
        training_data.append({
            'personality_dimensions': personality_dims,
            'use_case': use_case,
            'optimal_weights': optimal_weights,
            'optimal_threshold': optimal_threshold,
            'optimal_basis': basis_importance,
        })
    
    # Save to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump({'training_data': training_data}, f, indent=2)
    
    print(f"✅ Generated {num_samples} samples and saved to {output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(description='Train quantum optimization ML model')
    parser.add_argument(
        '--data-path',
        type=str,
        default=None,
        help='Path to training data JSON file (if not provided, generates synthetic data)',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default='assets/models/quantum_optimization_model.onnx',
        help='Path to output ONNX model file',
    )
    parser.add_argument(
        '--epochs',
        type=int,
        default=100,
        help='Number of training epochs',
    )
    parser.add_argument(
        '--batch-size',
        type=int,
        default=32,
        help='Batch size for training',
    )
    parser.add_argument(
        '--learning-rate',
        type=float,
        default=0.001,
        help='Learning rate',
    )
    parser.add_argument(
        '--generate-data',
        action='store_true',
        help='Generate synthetic training data',
    )
    parser.add_argument(
        '--num-samples',
        type=int,
        default=10000,
        help='Number of synthetic samples to generate',
    )
    
    args = parser.parse_args()
    
    # Generate data if requested or if data path not provided
    if args.generate_data or args.data_path is None:
        data_path = generate_synthetic_training_data(
            num_samples=args.num_samples,
            output_path='data/quantum_optimization_training_data.json',
        )
    else:
        data_path = args.data_path
    
    # Load data
    print("Loading training data...")
    features, labels = load_training_data(data_path)
    print(f"Loaded {len(features)} training samples")
    
    # Normalize features
    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)
    
    # Split data
    X_train, X_temp, y_train_weights, y_temp_weights = train_test_split(
        features_scaled, labels['weights'], test_size=0.3, random_state=42
    )
    X_val, X_test, y_val_weights, y_test_weights = train_test_split(
        X_temp, y_temp_weights, test_size=0.5, random_state=42
    )
    
    # Split other labels similarly
    _, _, y_train_threshold, y_temp_threshold = train_test_split(
        features_scaled, labels['threshold'], test_size=0.3, random_state=42
    )
    _, _, y_val_threshold, y_test_threshold = train_test_split(
        X_temp, y_temp_threshold, test_size=0.5, random_state=42
    )
    
    _, _, y_train_basis, y_temp_basis = train_test_split(
        features_scaled, labels['basis'], test_size=0.3, random_state=42
    )
    _, _, y_val_basis, y_test_basis = train_test_split(
        X_temp, y_temp_basis, test_size=0.5, random_state=42
    )
    
    print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")
    
    # Create datasets
    train_dataset = QuantumOptimizationDataset(
        X_train,
        weight_labels=y_train_weights,
        threshold_labels=y_train_threshold,
        basis_labels=y_train_basis,
    )
    val_dataset = QuantumOptimizationDataset(
        X_val,
        weight_labels=y_val_weights,
        threshold_labels=y_val_threshold,
        basis_labels=y_val_basis,
    )
    test_dataset = QuantumOptimizationDataset(
        X_test,
        weight_labels=y_test_weights,
        threshold_labels=y_test_threshold,
        basis_labels=y_test_basis,
    )
    
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False)
    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, shuffle=False)
    
    # Create model
    model = QuantumOptimizationModel(
        input_size=13,
        hidden_sizes=[64, 32],
        weight_output_size=5,
        threshold_output_size=1,
        basis_output_size=12,
        dropout=0.2,
    )
    print(f"Model created: {sum(p.numel() for p in model.parameters())} parameters")
    
    # Train model
    print("Training model...")
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    print(f"Using device: {device}")
    
    history = train_model(
        model,
        train_loader,
        val_loader,
        num_epochs=args.epochs,
        learning_rate=args.learning_rate,
        device=device,
    )
    
    # Evaluate on test set
    model.eval()
    test_loss_weights = 0.0
    test_loss_threshold = 0.0
    test_loss_basis = 0.0
    criterion_weights = nn.MSELoss()
    criterion_threshold = nn.MSELoss()
    criterion_basis = nn.MSELoss()
    
    with torch.no_grad():
        for batch in test_loader:
            features = batch['features'].to(device)
            
            if 'weights' in batch:
                weights_pred = model(features, task='weights')
                weights_true = batch['weights'].to(device)
                test_loss_weights += criterion_weights(weights_pred, weights_true).item()
            
            if 'threshold' in batch:
                threshold_pred = model(features, task='threshold')
                threshold_true = batch['threshold'].to(device)
                test_loss_threshold += criterion_threshold(threshold_pred, threshold_true).item()
            
            if 'basis' in batch:
                basis_pred = model(features, task='basis')
                basis_true = batch['basis'].to(device)
                test_loss_basis += criterion_basis(basis_pred, basis_true).item()
    
    test_loss_weights /= len(test_loader)
    test_loss_threshold /= len(test_loader)
    test_loss_basis /= len(test_loader)
    
    print(f"\nTest Loss:")
    print(f"  Weights: {test_loss_weights:.4f}")
    print(f"  Threshold: {test_loss_threshold:.4f}")
    print(f"  Basis: {test_loss_basis:.4f}")
    
    # Export to ONNX
    print("\nExporting to ONNX...")
    os.makedirs(os.path.dirname(args.output_path), exist_ok=True)
    export_to_onnx(model, args.output_path, input_size=13)
    
    print("\nTraining complete!")
    print(f"Model saved to: {args.output_path}")
    print("\nNote: The ONNX model exports all three tasks. In production, you may want")
    print("to train separate models for each task for better performance.")


if __name__ == '__main__':
    main()
