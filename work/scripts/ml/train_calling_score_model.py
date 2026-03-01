#!/usr/bin/env python3
"""
Training script for Calling Score Neural Network Model
Phase 12 Section 2: Neural Network Implementation

This script trains a neural network model to predict calling scores
based on user vibe, spot vibe, context, and timing factors.

Model Architecture:
- Input: 39 features (12D user + 12D spot + 10 context + 5 timing)
- Architecture: MLP (39 → 128 → 64 → 1)
- Output: Calling score (0.0-1.0)

Usage:
    python scripts/ml/train_calling_score_model.py [--data-path DATA_PATH] [--output-path OUTPUT_PATH]
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


class CallingScoreDataset(Dataset):
    """Dataset for calling score training data"""
    
    def __init__(self, features: np.ndarray, labels: np.ndarray):
        """
        Args:
            features: Input features (N, 39)
            labels: Target calling scores (N,)
        """
        self.features = torch.FloatTensor(features)
        self.labels = torch.FloatTensor(labels)
    
    def __len__(self):
        return len(self.features)
    
    def __getitem__(self, idx):
        return self.features[idx], self.labels[idx]


class CallingScoreModel(nn.Module):
    """Neural network model for calling score prediction"""
    
    def __init__(self, input_size: int = 39, hidden_sizes: List[int] = [128, 64], output_size: int = 1, dropout: float = 0.2):
        super(CallingScoreModel, self).__init__()
        
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
        layers.append(nn.Sigmoid())  # Ensure output is in [0, 1]
        
        self.model = nn.Sequential(*layers)
    
    def forward(self, x):
        return self.model(x).squeeze()


def load_training_data(data_path: str) -> Tuple[np.ndarray, np.ndarray]:
    """
    Load training data from JSON file or Supabase
    
    Expected JSON format:
    {
        "training_data": [
            {
                "user_vibe_dimensions": {...},
                "spot_vibe_dimensions": {...},
                "context_features": {...},
                "timing_features": {...},
                "formula_calling_score": 0.75,
                "is_called": true,
                "outcome_score": 0.8
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
    
    for record in training_records:
        # Extract feature vector (39D)
        feature_vector = extract_features(record)
        features.append(feature_vector)
        
        # Use outcome_score as label if available, otherwise use formula_calling_score
        label = record.get('outcome_score', record.get('formula_calling_score', 0.5))
        labels.append(float(label))
    
    return np.array(features), np.array(labels)


def extract_features(record: Dict) -> List[float]:
    """
    Extract 39D feature vector from training record
    
    Feature order:
    - [0-11]: User vibe dimensions (12D)
    - [12-23]: Spot vibe dimensions (12D)
    - [24-33]: Context features (10 features)
    - [34-38]: Timing features (5 features)
    """
    features = []
    
    # User vibe dimensions (12D)
    user_vibe = record.get('user_vibe_dimensions', {})
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
        features.append(float(user_vibe.get(dim, 0.5)))
    
    # Spot vibe dimensions (12D)
    spot_vibe = record.get('spot_vibe_dimensions', {})
    for dim in dimension_names:
        features.append(float(spot_vibe.get(dim, 0.5)))
    
    # Context features (10 features)
    context = record.get('context_features', {})
    context_features = [
        'location_proximity',
        'journey_alignment',
        'user_receptivity',
        'opportunity_availability',
        'network_effects',
        'community_patterns',
        # Former placeholders (now supported if present in training records)
        'vibe_compatibility',
        'energy_match',
        'community_match',
        'novelty_match',
    ]
    for feat in context_features:
        features.append(float(context.get(feat, 0.5)))
    
    # Timing features (5 features)
    timing = record.get('timing_features', {})
    timing_features = [
        'optimal_time_of_day',
        'optimal_day_of_week',
        'user_patterns',
        'opportunity_timing',
        # Former placeholder (now supported if present in training records)
        'timing_alignment',
    ]
    for feat in timing_features:
        features.append(float(timing.get(feat, 0.5)))
    
    # Ensure exactly 39 features
    features = features[:39]
    while len(features) < 39:
        features.append(0.5)
    
    return features


def train_model(
    model: nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    num_epochs: int = 100,
    learning_rate: float = 0.001,
    device: str = 'cpu'
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
            print(f"Epoch [{epoch + 1}/{num_epochs}], Train Loss: {train_loss:.4f}, Val Loss: {val_loss:.4f}")
    
    return {
        'train_losses': train_losses,
        'val_losses': val_losses,
        'best_val_loss': best_val_loss,
    }


def export_to_onnx(model: nn.Module, output_path: str, input_size: int = 39):
    """Export PyTorch model to ONNX format"""
    
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, input_size)
    
    # Export to ONNX
    # Using opset 18 (latest stable) to avoid version conversion warnings
    torch.onnx.export(
        model,
        dummy_input,
        output_path,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={
            'input': {0: 'batch_size'},
            'output': {0: 'batch_size'},
        },
        opset_version=18,
    )
    
    print(f"Model exported to ONNX: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Train calling score neural network model')
    parser.add_argument(
        '--data-path',
        type=str,
        default='data/calling_score_training_data.json',
        help='Path to training data JSON file',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default='assets/models/calling_score_model.onnx',
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
        '--hidden-sizes',
        type=str,
        default=None,
        help='Hidden layer sizes (comma-separated, e.g., "128,64" or "256,128,64")',
    )
    parser.add_argument(
        '--dropout',
        type=float,
        default=None,
        help='Dropout rate (default: 0.2)',
    )
    
    args = parser.parse_args()
    
    # Load data
    print("Loading training data...")
    features, labels = load_training_data(args.data_path)
    print(f"Loaded {len(features)} training samples")
    
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
    train_dataset = CallingScoreDataset(X_train, y_train)
    val_dataset = CallingScoreDataset(X_val, y_val)
    test_dataset = CallingScoreDataset(X_test, y_test)
    
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False)
    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, shuffle=False)
    
    # Parse architecture from args if provided
    hidden_sizes = [128, 64]  # Default
    if args.hidden_sizes:
        hidden_sizes = [int(x) for x in args.hidden_sizes.split(',')]
    
    dropout = 0.2  # Default
    if args.dropout is not None:
        dropout = args.dropout
    
    # Create model
    model = CallingScoreModel(
        input_size=features.shape[1],
        hidden_sizes=hidden_sizes,
        output_size=1,
        dropout=dropout,
    )
    print(f"Model created: {sum(p.numel() for p in model.parameters())} parameters")
    print(f"Architecture: {features.shape[1]} → {' → '.join(map(str, hidden_sizes))} → 1")
    print(f"Dropout: {dropout}")
    
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
    print(f"Test Loss: {test_loss:.4f}")
    
    # Export to ONNX
    print("Exporting to ONNX...")
    os.makedirs(os.path.dirname(args.output_path), exist_ok=True)
    export_to_onnx(model, args.output_path)
    
    print("Training complete!")
    print(f"Model saved to: {args.output_path}")


if __name__ == '__main__':
    main()
