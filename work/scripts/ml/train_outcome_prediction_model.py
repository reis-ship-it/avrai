#!/usr/bin/env python3
"""
Training script for Outcome Prediction Neural Network Model
Phase 12 Section 3: Outcome Prediction Model

This script trains a binary classifier to predict the probability of a positive outcome
before calling a user. This helps filter out low-quality recommendations.

Model Architecture:
- Input: ~45 features (39 base + ~6 history features)
- Architecture: MLP (45 → 128 → 64 → 32 → 1)
- Output: Probability of positive outcome (0.0-1.0)

Usage:
    python scripts/ml/train_outcome_prediction_model.py [--data-path DATA_PATH] [--output-path OUTPUT_PATH]
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
from sklearn.utils.class_weight import compute_class_weight

# Add project root to path for imports
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))


class OutcomePredictionDataset(Dataset):
    """Dataset for outcome prediction training data"""
    
    def __init__(self, features: np.ndarray, labels: np.ndarray):
        """
        Args:
            features: Input features (N, ~45)
            labels: Target outcome labels (N,) - 1.0 for positive, 0.0 for negative/neutral
        """
        self.features = torch.FloatTensor(features)
        self.labels = torch.FloatTensor(labels)
    
    def __len__(self):
        return len(self.features)
    
    def __getitem__(self, idx):
        return self.features[idx], self.labels[idx]


class OutcomePredictionModel(nn.Module):
    """Neural network model for outcome prediction (binary classifier)"""
    
    def __init__(self, input_size: int = 45, hidden_sizes: List[int] = [128, 64, 32], output_size: int = 1):
        super(OutcomePredictionModel, self).__init__()
        
        # Build layers
        layers = []
        prev_size = input_size
        
        for hidden_size in hidden_sizes:
            layers.append(nn.Linear(prev_size, hidden_size))
            layers.append(nn.ReLU())
            layers.append(nn.Dropout(0.2))
            prev_size = hidden_size
        
        # Output layer
        layers.append(nn.Linear(prev_size, output_size))
        layers.append(nn.Sigmoid())  # Binary classification output
        
        self.model = nn.Sequential(*layers)
    
    def forward(self, x):
        return self.model(x).squeeze()


def load_training_data(data_path: str) -> Tuple[np.ndarray, np.ndarray]:
    """
    Load training data from JSON file
    
    Expected JSON format:
    {
        "training_data": [
            {
                "user_vibe_dimensions": {...},
                "spot_vibe_dimensions": {...},
                "context_features": {...},
                "timing_features": {...},
                "outcome_type": "positive" | "negative" | "neutral",
                "outcome_score": 0.0-1.0
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
        # Extract feature vector (~45D)
        feature_vector = extract_features(record)
        features.append(feature_vector)
        
        # Extract label: 1.0 for positive outcome, 0.0 for negative/neutral
        outcome_type = record.get('outcome_type', 'neutral')
        outcome_score = record.get('outcome_score', 0.5)
        
        # Label: 1.0 if positive outcome, 0.0 otherwise
        # Can also use outcome_score directly (0.0-1.0)
        if outcome_type == 'positive' or outcome_score >= 0.7:
            labels.append(1.0)
        else:
            labels.append(0.0)
    
    return np.array(features), np.array(labels)


def extract_features(record: Dict) -> List[float]:
    """
    Extract ~45D feature vector from training record
    
    Feature order:
    - [0-38]: Base features (39D) - same as calling score model
    - [39-44]: History features (6D)
    """
    features = []
    
    # Base features (39D) - same as calling score model
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
    ]
    for feat in context_features:
        features.append(float(context.get(feat, 0.5)))
    # Add 4 placeholder context features
    while len(features) < 34:
        features.append(0.5)
    
    # Timing features (5 features)
    timing = record.get('timing_features', {})
    timing_features = [
        'optimal_time_of_day',
        'optimal_day_of_week',
        'user_patterns',
        'opportunity_timing',
    ]
    for feat in timing_features:
        features.append(float(timing.get(feat, 0.5)))
    # Add 1 placeholder timing feature
    if len(features) < 39:
        features.append(0.5)
    
    # History features (6D) - placeholder for now
    # In production, these would come from user's historical data
    # For training, we can use synthetic or aggregated data
    history_features = record.get('history_features', {})
    features.append(float(history_features.get('past_positive_rate', 0.5)))
    features.append(float(history_features.get('past_negative_rate', 0.5)))
    features.append(float(history_features.get('average_engagement', 0.5)))
    features.append(float(history_features.get('interaction_count', 0.0)))
    features.append(float(history_features.get('time_since_last_positive', 0.5)))
    features.append(float(history_features.get('activity_level', 0.5)))
    
    # Ensure exactly 45 features
    features = features[:45]
    while len(features) < 45:
        features.append(0.5)
    
    return features


def train_model(
    model: nn.Module,
    train_loader: DataLoader,
    val_loader: DataLoader,
    num_epochs: int = 100,
    learning_rate: float = 0.001,
    device: str = 'cpu',
    pos_weight: torch.Tensor = None,
) -> Dict:
    """Train the model and return training history"""
    
    model = model.to(device)
    # Use weighted BCELoss for imbalanced data
    # pos_weight is applied manually in loss calculation
    criterion = nn.BCELoss(reduction='none')  # Get per-sample losses
    optimizer = optim.Adam(model.parameters(), lr=learning_rate)
    
    train_losses = []
    val_losses = []
    train_accuracies = []
    val_accuracies = []
    
    best_val_loss = float('inf')
    patience = 10
    patience_counter = 0
    
    for epoch in range(num_epochs):
        # Training
        model.train()
        train_loss = 0.0
        train_correct = 0
        train_total = 0
        for features, labels in train_loader:
            features, labels = features.to(device), labels.to(device)
            
            optimizer.zero_grad()
            outputs = model(features)
            per_sample_loss = criterion(outputs, labels)
            # Apply pos_weight to positive samples
            if pos_weight is not None:
                weights = torch.where(labels == 1.0, pos_weight.item(), 1.0)
                loss = (per_sample_loss * weights).mean()
            else:
                loss = per_sample_loss.mean()
            loss.backward()
            optimizer.step()
            
            train_loss += loss.item()
            
            # Calculate accuracy
            predicted = (outputs > 0.5).float()
            train_total += labels.size(0)
            train_correct += (predicted == labels).sum().item()
        
        train_loss /= len(train_loader)
        train_accuracy = train_correct / train_total if train_total > 0 else 0.0
        train_losses.append(train_loss)
        train_accuracies.append(train_accuracy)
        
        # Validation
        model.eval()
        val_loss = 0.0
        val_correct = 0
        val_total = 0
        with torch.no_grad():
            for features, labels in val_loader:
                features, labels = features.to(device), labels.to(device)
                outputs = model(features)
                per_sample_loss = criterion(outputs, labels)
                # Apply pos_weight to positive samples
                if pos_weight is not None:
                    weights = torch.where(labels == 1.0, pos_weight.item(), 1.0)
                    loss = (per_sample_loss * weights).mean()
                else:
                    loss = per_sample_loss.mean()
                val_loss += loss.item()
                
                # Calculate accuracy
                predicted = (outputs > 0.5).float()
                val_total += labels.size(0)
                val_correct += (predicted == labels).sum().item()
        
        val_loss /= len(val_loader)
        val_accuracy = val_correct / val_total if val_total > 0 else 0.0
        val_losses.append(val_loss)
        val_accuracies.append(val_accuracy)
        
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
            print(f"Epoch [{epoch + 1}/{num_epochs}], "
                  f"Train Loss: {train_loss:.4f}, Train Acc: {train_accuracy:.4f}, "
                  f"Val Loss: {val_loss:.4f}, Val Acc: {val_accuracy:.4f}")
    
    return {
        'train_losses': train_losses,
        'val_losses': val_losses,
        'train_accuracies': train_accuracies,
        'val_accuracies': val_accuracies,
        'best_val_loss': best_val_loss,
        'best_val_accuracy': max(val_accuracies) if val_accuracies else 0.0,
    }


def export_to_onnx(model: nn.Module, output_path: str, input_size: int = 45):
    """Export PyTorch model to ONNX format"""
    
    model.eval()
    
    # Create dummy input
    dummy_input = torch.randn(1, input_size)
    
    # Export to ONNX
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
        opset_version=18,  # Using opset 18 (latest stable) to avoid version conversion warnings
    )
    
    print(f"Model exported to ONNX: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Train outcome prediction neural network model')
    parser.add_argument(
        '--data-path',
        type=str,
        default='data/calling_score_training_data.json',
        help='Path to training data JSON file',
    )
    parser.add_argument(
        '--output-path',
        type=str,
        default='assets/models/outcome_prediction_model.onnx',
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
    
    args = parser.parse_args()
    
    # Load data
    print("Loading training data...")
    features, labels = load_training_data(args.data_path)
    print(f"Loaded {len(features)} training samples")
    print(f"Positive outcomes: {np.sum(labels == 1.0)} ({np.sum(labels == 1.0) / len(labels) * 100:.1f}%)")
    print(f"Negative/Neutral outcomes: {np.sum(labels == 0.0)} ({np.sum(labels == 0.0) / len(labels) * 100:.1f}%)")
    
    # Normalize features
    scaler = StandardScaler()
    features_scaled = scaler.fit_transform(features)
    
    # Split data
    X_train, X_temp, y_train, y_temp = train_test_split(
        features_scaled, labels, test_size=0.3, random_state=42, stratify=labels
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42, stratify=y_temp
    )
    
    print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")
    
    # Calculate pos_weight for imbalanced data (weight for positive class)
    # pos_weight = (num_negative / num_positive) for balanced loss
    num_positive = np.sum(y_train == 1.0)
    num_negative = np.sum(y_train == 0.0)
    pos_weight_value = num_negative / num_positive if num_positive > 0 else 1.0
    pos_weight_tensor = torch.FloatTensor([pos_weight_value]).to('cpu')
    
    print(f"Class distribution: Positive={num_positive}, Negative={num_negative}")
    print(f"Pos weight: {pos_weight_value:.4f}")
    
    # Create datasets
    train_dataset = OutcomePredictionDataset(X_train, y_train)
    val_dataset = OutcomePredictionDataset(X_val, y_val)
    test_dataset = OutcomePredictionDataset(X_test, y_test)
    
    train_loader = DataLoader(train_dataset, batch_size=args.batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=args.batch_size, shuffle=False)
    test_loader = DataLoader(test_dataset, batch_size=args.batch_size, shuffle=False)
    
    # Create model
    model = OutcomePredictionModel(input_size=features.shape[1], hidden_sizes=[128, 64, 32], output_size=1)
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
        pos_weight=pos_weight_tensor,
    )
    
    # Evaluate on test set
    model.eval()
    test_loss = 0.0
    test_correct = 0
    test_total = 0
    criterion = nn.BCELoss(reduction='none')
    with torch.no_grad():
        for features, labels in test_loader:
            features, labels = features.to(device), labels.to(device)
            outputs = model(features)
            per_sample_loss = criterion(outputs, labels)
            # Apply pos_weight to positive samples for consistency
            if pos_weight_tensor is not None:
                weights = torch.where(labels == 1.0, pos_weight_tensor.item(), 1.0)
                loss = (per_sample_loss * weights).mean()
            else:
                loss = per_sample_loss.mean()
            test_loss += loss.item()
            
            # Calculate accuracy
            predicted = (outputs > 0.5).float()
            test_total += labels.size(0)
            test_correct += (predicted == labels).sum().item()
    
    test_loss /= len(test_loader)
    test_accuracy = test_correct / test_total if test_total > 0 else 0.0
    print(f"Test Loss: {test_loss:.4f}, Test Accuracy: {test_accuracy:.4f}")
    
    # Export to ONNX
    print("Exporting to ONNX...")
    os.makedirs(os.path.dirname(args.output_path), exist_ok=True)
    export_to_onnx(model, args.output_path, input_size=features.shape[1])
    
    print("Training complete!")
    print(f"Model saved to: {args.output_path}")
    print(f"Best validation accuracy: {history['best_val_accuracy']:.4f}")


if __name__ == '__main__':
    main()
