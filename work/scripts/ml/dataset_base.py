#!/usr/bin/env python3
"""
Base Dataset Architecture for SPOTS ML Training

Provides shared data structures and utilities for all ML training datasets.
This ensures consistency across synthetic, hybrid, and real data generators.

Phase 12 Section 2: Neural Network Implementation
"""

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from pathlib import Path
import json
from datetime import datetime
import numpy as np


@dataclass
class TrainingRecord:
    """
    Single training record for calling score model.
    
    Represents one user-opportunity interaction with all features and outcomes.
    """
    # User features
    user_vibe_dimensions: Dict[str, float] = field(default_factory=dict)
    
    # Opportunity features
    spot_vibe_dimensions: Dict[str, float] = field(default_factory=dict)
    context_features: Dict[str, float] = field(default_factory=dict)
    timing_features: Dict[str, float] = field(default_factory=dict)
    
    # Labels
    formula_calling_score: float = 0.0
    is_called: bool = False
    outcome_type: str = 'neutral'  # 'positive', 'negative', 'neutral'
    outcome_score: float = 0.0
    
    # Metadata
    user_id: Optional[str] = None
    opportunity_id: Optional[str] = None
    timestamp: Optional[str] = None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            'user_vibe_dimensions': self.user_vibe_dimensions,
            'spot_vibe_dimensions': self.spot_vibe_dimensions,
            'context_features': self.context_features,
            'timing_features': self.timing_features,
            'formula_calling_score': self.formula_calling_score,
            'is_called': self.is_called,
            'outcome_type': self.outcome_type,
            'outcome_score': self.outcome_score,
            **({} if self.user_id is None else {'user_id': self.user_id}),
            **({} if self.opportunity_id is None else {'opportunity_id': self.opportunity_id}),
            **({} if self.timestamp is None else {'timestamp': self.timestamp}),
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'TrainingRecord':
        """Create from dictionary"""
        return cls(
            user_vibe_dimensions=data.get('user_vibe_dimensions', {}),
            spot_vibe_dimensions=data.get('spot_vibe_dimensions', {}),
            context_features=data.get('context_features', {}),
            timing_features=data.get('timing_features', {}),
            formula_calling_score=data.get('formula_calling_score', 0.0),
            is_called=data.get('is_called', False),
            outcome_type=data.get('outcome_type', 'neutral'),
            outcome_score=data.get('outcome_score', 0.0),
            user_id=data.get('user_id'),
            opportunity_id=data.get('opportunity_id'),
            timestamp=data.get('timestamp'),
        )


@dataclass
class DatasetMetadata:
    """
    Metadata for a training dataset.
    
    Tracks dataset provenance, statistics, and generation parameters.
    """
    num_samples: int
    source: str  # 'synthetic', 'hybrid_big_five', 'real_data'
    description: str = ""
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())
    
    # Source information
    user_profiles_source: Optional[str] = None
    records_per_profile: Optional[int] = None
    
    # Statistics
    statistics: Dict[str, Any] = field(default_factory=dict)
    
    # Generation parameters
    generation_params: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        result = {
            'num_samples': self.num_samples,
            'source': self.source,
            'description': self.description,
            'created_at': self.created_at,
        }
        
        if self.user_profiles_source is not None:
            result['user_profiles_source'] = self.user_profiles_source
        if self.records_per_profile is not None:
            result['records_per_profile'] = self.records_per_profile
        if self.statistics:
            result['statistics'] = self.statistics
        if self.generation_params:
            result['generation_params'] = self.generation_params
        
        return result
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'DatasetMetadata':
        """Create from dictionary"""
        return cls(
            num_samples=data.get('num_samples', 0),
            source=data.get('source', 'unknown'),
            description=data.get('description', ''),
            created_at=data.get('created_at', datetime.now().isoformat()),
            user_profiles_source=data.get('user_profiles_source'),
            records_per_profile=data.get('records_per_profile'),
            statistics=data.get('statistics', {}),
            generation_params=data.get('generation_params', {}),
        )


@dataclass
class TrainingDataset:
    """
    Complete training dataset with metadata and records.
    
    This is the standard format for all training data in SPOTS ML pipeline.
    """
    metadata: DatasetMetadata
    records: List[TrainingRecord] = field(default_factory=list)
    
    def __len__(self) -> int:
        """Number of records in dataset"""
        return len(self.records)
    
    def add_record(self, record: TrainingRecord):
        """Add a record to the dataset"""
        self.records.append(record)
        self.metadata.num_samples = len(self.records)
    
    def calculate_statistics(self):
        """Calculate and update dataset statistics"""
        if not self.records:
            return
        
        called_count = sum(1 for r in self.records if r.is_called)
        positive_outcomes = sum(1 for r in self.records if r.outcome_type == 'positive')
        avg_calling_score = np.mean([r.formula_calling_score for r in self.records])
        avg_outcome_score = np.mean([r.outcome_score for r in self.records])
        
        self.metadata.statistics = {
            'called_percentage': round(called_count / len(self.records) * 100, 2),
            'positive_outcome_percentage': round(positive_outcomes / len(self.records) * 100, 2),
            'average_calling_score': round(avg_calling_score, 4),
            'average_outcome_score': round(avg_outcome_score, 4),
            'total_records': len(self.records),
        }
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization"""
        return {
            'metadata': self.metadata.to_dict(),
            'training_data': [record.to_dict() for record in self.records],
        }
    
    def save(self, output_path: Path):
        """Save dataset to JSON file"""
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(self.to_dict(), f, indent=2)
    
    @classmethod
    def load(cls, input_path: Path) -> 'TrainingDataset':
        """Load dataset from JSON file"""
        with open(input_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        metadata = DatasetMetadata.from_dict(data.get('metadata', {}))
        records = [
            TrainingRecord.from_dict(record)
            for record in data.get('training_data', [])
        ]
        
        dataset = cls(metadata=metadata, records=records)
        return dataset
    
    def validate(self) -> List[str]:
        """
        Validate dataset structure and return list of issues.
        
        Returns:
            List of validation error messages (empty if valid)
        """
        issues = []
        
        # Check required dimensions
        required_dimensions = [
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
        
        for i, record in enumerate(self.records):
            # Check user vibe dimensions
            for dim in required_dimensions:
                if dim not in record.user_vibe_dimensions:
                    issues.append(f"Record {i}: Missing user dimension '{dim}'")
                elif not (0.0 <= record.user_vibe_dimensions[dim] <= 1.0):
                    issues.append(f"Record {i}: User dimension '{dim}' out of range [0.0, 1.0]")
            
            # Check spot vibe dimensions
            for dim in required_dimensions:
                if dim not in record.spot_vibe_dimensions:
                    issues.append(f"Record {i}: Missing spot dimension '{dim}'")
                elif not (0.0 <= record.spot_vibe_dimensions[dim] <= 1.0):
                    issues.append(f"Record {i}: Spot dimension '{dim}' out of range [0.0, 1.0]")
            
            # Check calling score range
            if not (0.0 <= record.formula_calling_score <= 1.0):
                issues.append(f"Record {i}: formula_calling_score out of range [0.0, 1.0]")
            
            # Check outcome score range
            if not (0.0 <= record.outcome_score <= 1.0):
                issues.append(f"Record {i}: outcome_score out of range [0.0, 1.0]")
        
        return issues
