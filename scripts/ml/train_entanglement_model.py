#!/usr/bin/env python3
"""
Training script for Quantum Entanglement Detection ML Model
Phase 3: ML Model Training

This script trains a neural network model to detect entanglement patterns
between personality dimensions, replacing hardcoded dimension groups.

Model Architecture:
- Input: 12 features (12 SPOTS dimensions)
- Architecture: MLP (12 → 64 → 32 → 66)
- Output: 66 correlation values (one for each dimension pair: 12*11/2 = 66)

Usage:
    python scripts/ml/train_entanglement_model.py [--data-path DATA_PATH] [--output-path OUTPUT_PATH]
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple

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


class EntanglementDataset(Dataset):
    """Dataset for entanglement detection training data"""
    
    def __init__(self, features: np.ndarray, labels: np.ndarray):
        """
        Args:
            features: Input features (N, 12) - 12 personality dimensions
            labels: Target correlations (N, 66) - one per dimension pair
        """
        self.features = torch.FloatTensor(features)
        self.labels = torch.FloatTensor(labels)
    
    def __len__(self):
        return len(self.features)
    
    def __getitem__(self, idx):
        return self.features[idx], self.labels[idx]


class EntanglementModel(nn.Module):
    """Neural network model for entanglement detection"""
    
    def __init__(self, input_size: int = 12, hidden_sizes: List[int] = [64, 32], 
                 output_size: int = 66, dropout: float = 0.2):
        super(EntanglementModel, self).__init__()
        
        # Build layers
        layers = []
        prev_size = input_size
        
        for hidden_size in hidden_sizes:
            layers.append(nn.Linear(prev_size, hidden_size))
            layers.append(nn.ReLU())
            layers.append(nn.Dropout(dropout))
            prev_size = hidden_size
        
        # Output layer
        layers.append(nn.Linear(prev_size, output_size))
        layers.append(nn.Sigmoid())  # Correlations in [0, 1]
        
        self.model = nn.Sequential(*layers)
    
    def forward(self, x):
        return self.model(x)


def load_training_data(data_path: str) -> Tuple[np.ndarray, np.ndarray]:
    """
    Load training data from JSON file
    
    Expected JSON format:
    {
        "training_data": [
            {
                "personality_dimensions": {...},  # 12 SPOTS dimensions
                "entanglement_correlations": {
                    "exploration_eagerness:location_adventurousness": 0.3,
                    "social_discovery_style:community_orientation": 0.4,
                    ...
                }
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
    labels = []
    
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
    
    for record in training_records:
        # Extract feature vector (12D)
        personality_dims = record.get('personality_dimensions', {})
        feature_vector = [personality_dims.get(dim, 0.5) for dim in dimension_names]
        features.append(feature_vector)
        
        # Extract correlation labels (66D: one per dimension pair)
        correlations = record.get('entanglement_correlations', {})
        correlation_vector = []
        
        # Generate all pairs (i, j) where i < j
        for i in range(len(dimension_names)):
            for j in range(i + 1, len(dimension_names)):
                dim1 = dimension_names[i]
                dim2 = dimension_names[j]
                pair_key = f"{dim1}:{dim2}"
                correlation = correlations.get(pair_key, 0.0)
                correlation_vector.append(correlation)
        
        labels.append(correlation_vector)
    
    return np.array(features), np.array(labels)


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
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    
    train_losses = []
    val_losses = []
    
    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0
    
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        for features, labels in train_loader:
            features, labels = features.to(device), labels.to(device)
            
            optimizer.zero_grad()
            outputs = model(features)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
        
        train_loss /= len(train_loader)
        train_losses.append(train_loss)
        
        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for features, labels in val_loader:
                features, labels = features.to(device), labels.to(device)
                outputs = model(features)
                loss = criterion(outputs, labels)
                val_loss += loss.item()
        
        val_loss /= len(val_loader)
        val_losses.append(val_loss)
        
        # Early stopping
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= patience:
                print(f"Early stopping at epoch {epoch + 1}")
                break
        
        if (epoch + 1) % 10 == 0:
            print(f"Epoch {epoch + 1}/{num_epochs} - Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}")
    
    return {
        'train_losses': train_losses,
        'val_losses': val_losses,
    }


def export_to_onnx(model: nn.Module, output_path: str, input_size: int = 12):
    """Export model to ONNX format"""
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, input_size)
    
    # Try multiple export strategies
    try:
        # Strategy 1: Export directly without tracing (avoids Union type issues)
        torch.onnx.export(
            model,
            dummy_input,
            output_path,
            input_names=['input'],
            output_names=['output'],
            opset_version=11,
            export_params=True,
            do_constant_folding=True,
            verbose=False,
        )
        print(f"✅ Model exported to ONNX: {output_path}")
    except Exception as e1:
        print(f"Direct export failed: {e1}")
        try:
            # Strategy 2: Try with script (avoids tracing issues)
            scripted = torch.jit.script(model)
            torch.onnx.export(
                scripted,
                dummy_input,
                output_path,
                input_names=['input'],
                output_names=['output'],
                opset_version=11,
                export_params=True,
                do_constant_folding=True,
                verbose=False,
            )
            print(f"✅ Model exported to ONNX (scripted): {output_path}")
        except Exception as e2:
            print(f"Scripted export also failed: {e2}")
            try:
                # Strategy 3: Try tracing (last resort)
                traced_model = torch.jit.trace(model, dummy_input)
                traced_model.eval()
                torch.onnx.export(
                    traced_model,
                    dummy_input,
                    output_path,
                    input_names=['input'],
                    output_names=['output'],
                    opset_version=11,
                    export_params=True,
                    do_constant_folding=True,
                    verbose=False,
                )
                print(f"✅ Model exported to ONNX (traced): {output_path}")
            except Exception as e3:
                print(f"❌ All ONNX export strategies failed:")
                print(f"  Direct: {e1}")
                print(f"  Scripted: {e2}")
                print(f"  Traced: {e3}")
                print("Saving model state dict instead - ONNX export can be done later")
                # Save PyTorch model state as fallback
                torch.save(model.state_dict(), output_path.replace('.onnx', '.pth'))
                print(f"Model state saved to: {output_path.replace('.onnx', '.pth')}")
                print("You can convert to ONNX later or use the PyTorch model directly")


def generate_synthetic_training_data(num_samples: int = 10000, output_path: str = 'data/entanglement_training_data.json'):
    """
    Generate synthetic training data for entanglement detection model
    
    This creates training examples with:
    - Random personality dimensions
    - Heuristic-based entanglement correlations (can be improved with real data)
    """
    print(f"Generating {num_samples} synthetic training samples...")
    
    training_data = []
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
    
    # Define hardcoded entanglement groups (matching QuantumVibeEngine)
    exploration_group = ['exploration_eagerness', 'location_adventurousness', 'novelty_seeking']
    social_group = ['social_discovery_style', 'community_orientation', 'trust_network_reliance']
    temporal_group = ['temporal_flexibility']
    
    np.random.seed(42)
    
    for i in range(num_samples):
        # Random personality dimensions
        personality_dims = {dim: float(np.random.uniform(0.0, 1.0)) for dim in dimension_names}
        
        # Generate entanglement correlations based on hardcoded groups
        correlations = {}
        
        # Exploration group correlations
        for dim1 in exploration_group:
            for dim2 in exploration_group:
                if dim1 < dim2:  # Only upper triangle
                    # Base correlation + noise
                    base_corr = 0.3
                    noise = np.random.uniform(-0.1, 0.1)
                    correlations[f"{dim1}:{dim2}"] = max(0.0, min(1.0, base_corr + noise))
        
        # Social group correlations
        for dim1 in social_group:
            for dim2 in social_group:
                if dim1 < dim2:
                    base_corr = 0.3
                    noise = np.random.uniform(-0.1, 0.1)
                    correlations[f"{dim1}:{dim2}"] = max(0.0, min(1.0, base_corr + noise))
        
        # Temporal group (only one dimension, so no correlations)
        
        # Add some random weak correlations for other pairs
        for dim1 in dimension_names:
            for dim2 in dimension_names:
                if dim1 < dim2:
                    pair_key = f"{dim1}:{dim2}"
                    if pair_key not in correlations:
                        # Weak random correlation
                        correlations[pair_key] = np.random.uniform(0.0, 0.15)
        
        training_data.append({
            'personality_dimensions': personality_dims,
            'entanglement_correlations': correlations,
        })
    
    # Save to file
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w') as f:
        json.dump({'training_data': training_data}, f, indent=2)
    
    print(f"✅ Generated {num_samples} samples and saved to {output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(description='Train entanglement detection ML model')
    parser.add_argument(
        '--data-path',
        type=str,
        default=None,
        help='Path to training data JSON file (if not provided, generates synthetic data)',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default='assets/models/entanglement_model.onnx',
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
            output_path='data/entanglement_training_data.json',
        )
    else:
        data_path = args.data_path
    
    # Load data
    print("Loading training data...")
    features, labels = load_training_data(data_path)
    print(f"Loaded {len(features)} training samples")
    print(f"Feature shape: {features.shape}, Label shape: {labels.shape}")
    
    # Normalize features
    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)
    
    # Split data
    X_train, X_temp, y_train, y_temp = train_test_split(
        features_scaled, labels, test_size=0.3, random_state=42
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42
    )
    
    print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")
    
    # Create datasets
    train_dataset = EntanglementDataset(X_train, y_train)
    val_dataset = EntanglementDataset(X_val, y_val)
    test_dataset = EntanglementDataset(X_test, y_test)
    
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False)
    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, shuffle=False)
    
    # Create model
    model = EntanglementModel(
        input_size=12,
        hidden_sizes=[64, 32],
        output_size=66,  # 12*11/2 = 66 pairs
        dropout=0.2,
    )
    print(f"Model created: {sum(p.numel() for p in model.parameters())} parameters")
    print(f"Architecture: 12 → 64 → 32 → 66")
    
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
    test_loss = 0.0
    criterion = nn.MSELoss()
    with torch.no_grad():
        for features, labels in test_loader:
            features, labels = features.to(device), labels.to(device)
            outputs = model(features)
            loss = criterion(outputs, labels)
            test_loss += loss.item()
    
    test_loss /= len(test_loader)
    print(f"\nTest Loss: {test_loss:.4f}")
    
    # Export to ONNX
    print("\nExporting to ONNX...")
    os.makedirs(os.path.dirname(args.output_path), exist_ok=True)
    export_to_onnx(model, args.output_path, input_size=12)
    
    print("\nTraining complete!")
    print(f"Model saved to: {args.output_path}")


if __name__ == '__main__':
    main()
