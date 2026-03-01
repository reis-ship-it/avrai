#!/usr/bin/env python3
"""
Knot Validation Script: Generate Knots from Personality Profiles

Purpose: Generate topological knots from existing personality profiles
to validate knot generation and analyze knot distributions.

Part of Phase 0 validation for Patent #31.
"""

import json
import sys
import os
from pathlib import Path
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from collections import defaultdict
import statistics

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

@dataclass
class PersonalityProfile:
    """Represents a personality profile with 12 dimensions."""
    user_id: str
    dimensions: Dict[str, float]  # 12 dimension values
    created_at: Optional[str] = None
    
@dataclass
class KnotCrossing:
    """Represents a braid crossing."""
    strand1: int
    strand2: int
    is_over: bool  # True = over-crossing, False = under-crossing
    position: int
    correlation_strength: float

@dataclass
class BraidSequence:
    """Represents a braid sequence."""
    number_of_strands: int
    crossings: List[KnotCrossing]
    
@dataclass
class KnotInvariant:
    """Represents knot invariants."""
    jones_polynomial: str  # Simplified representation
    alexander_polynomial: str  # Simplified representation
    crossing_number: int
    unknotting_number: int
    
@dataclass
class PersonalityKnot:
    """Represents a personality knot."""
    user_id: str
    knot_type: str  # e.g., "unknot", "trefoil", "figure-eight", "conway-like"
    crossings: List[KnotCrossing]
    braid_sequence: BraidSequence
    invariants: KnotInvariant
    complexity: float  # 0.0 to 1.0
    dimension_to_strand: Dict[str, int]
    created_at: str

class KnotGenerator:
    """Generates knots from personality profiles."""
    
    def __init__(self, correlation_threshold: float = 0.3):
        self.correlation_threshold = correlation_threshold
        self.dimension_names = [
            'exploration_eagerness', 'community_orientation', 'adventure_seeking',
            'social_preference', 'energy_preference', 'novelty_seeking',
            'value_orientation', 'crowd_tolerance', 'authenticity',
            'archetype', 'trust_level', 'openness'
        ]
    
    def calculate_correlations(self, profile: PersonalityProfile) -> Dict[tuple, float]:
        """Calculate correlations between all dimension pairs."""
        correlations = {}
        dims = profile.dimensions
        
        for i, dim1 in enumerate(self.dimension_names):
            for j, dim2 in enumerate(self.dimension_names):
                if i < j:  # Only calculate upper triangle
                    # Simplified correlation: use dimension values directly
                    # In real implementation, would use actual correlation calculation
                    val1 = dims.get(dim1, 0.5)
                    val2 = dims.get(dim2, 0.5)
                    
                    # Simple correlation approximation
                    correlation = (val1 - 0.5) * (val2 - 0.5) * 4  # Normalize to [-1, 1]
                    correlations[(i, j)] = correlation
        
        return correlations
    
    def create_braid_crossings(self, correlations: Dict[tuple, float]) -> List[KnotCrossing]:
        """Create braid crossings from dimension correlations."""
        crossings = []
        position = 0
        
        for (i, j), correlation in correlations.items():
            if abs(correlation) > self.correlation_threshold:
                crossing = KnotCrossing(
                    strand1=i,
                    strand2=j,
                    is_over=(correlation > 0),
                    position=position,
                    correlation_strength=abs(correlation)
                )
                crossings.append(crossing)
                position += 1
        
        return crossings
    
    def generate_braid_sequence(self, crossings: List[KnotCrossing]) -> BraidSequence:
        """Generate braid sequence from crossings."""
        return BraidSequence(
            number_of_strands=12,
            crossings=crossings
        )
    
    def calculate_knot_invariants(self, braid: BraidSequence) -> KnotInvariant:
        """Calculate knot invariants (simplified version)."""
        crossing_count = len(braid.crossings)
        
        # Simplified invariant calculation
        # In real implementation, would use actual Jones/Alexander polynomial algorithms
        jones_poly = f"q^{crossing_count}" if crossing_count > 0 else "1"
        alexander_poly = f"t^{crossing_count}" if crossing_count > 0 else "1"
        
        return KnotInvariant(
            jones_polynomial=jones_poly,
            alexander_polynomial=alexander_poly,
            crossing_number=crossing_count,
            unknotting_number=max(0, crossing_count - 3)  # Simplified
        )
    
    def identify_knot_type(self, invariants: KnotInvariant) -> str:
        """Identify knot type from invariants (simplified classification)."""
        crossing_num = invariants.crossing_number
        
        if crossing_num == 0:
            return "unknot"
        elif crossing_num == 3:
            return "trefoil"
        elif crossing_num == 4:
            return "figure-eight"
        elif crossing_num == 5:
            return "cinquefoil"
        elif crossing_num == 6:
            return "stevedore"
        elif crossing_num == 11:
            # Could be Conway-like if invariants match unknot
            if invariants.jones_polynomial == "1":
                return "conway-like"
            return "complex-11"
        else:
            return f"complex-{crossing_num}"
    
    def calculate_complexity(self, braid: BraidSequence) -> float:
        """Calculate knot complexity (0.0 to 1.0)."""
        crossing_count = len(braid.crossings)
        max_crossings = 12 * 11 / 2  # Maximum possible crossings
        
        complexity = min(1.0, crossing_count / max_crossings)
        return complexity
    
    def generate_knot(self, profile: PersonalityProfile) -> PersonalityKnot:
        """Generate knot from personality profile."""
        # Step 1: Calculate correlations
        correlations = self.calculate_correlations(profile)
        
        # Step 2: Create braid crossings
        crossings = self.create_braid_crossings(correlations)
        
        # Step 3: Generate braid sequence
        braid = self.generate_braid_sequence(crossings)
        
        # Step 4: Calculate invariants
        invariants = self.calculate_knot_invariants(braid)
        
        # Step 5: Identify knot type
        knot_type = self.identify_knot_type(invariants)
        
        # Step 6: Calculate complexity
        complexity = self.calculate_complexity(braid)
        
        # Step 7: Map dimensions to strands
        dimension_to_strand = {
            dim: i for i, dim in enumerate(self.dimension_names)
        }
        
        return PersonalityKnot(
            user_id=profile.user_id,
            knot_type=knot_type,
            crossings=crossings,
            braid_sequence=braid,
            invariants=invariants,
            complexity=complexity,
            dimension_to_strand=dimension_to_strand,
            created_at=profile.created_at or "unknown"
        )

def load_personality_profiles(data_path: str) -> List[PersonalityProfile]:
    """Load personality profiles from data file."""
    profiles = []
    
    # In real implementation, would load from actual data source
    # For now, create sample profiles for testing
    if not os.path.exists(data_path):
        print(f"Warning: Data file not found: {data_path}")
        print("Creating sample profiles for testing...")
        return create_sample_profiles()
    
    with open(data_path, 'r') as f:
        data = json.load(f)
        
        for item in data:
            profile = PersonalityProfile(
                user_id=item.get('user_id', 'unknown'),
                dimensions=item.get('dimensions', {}),
                created_at=item.get('created_at')
            )
            profiles.append(profile)
    
    return profiles

def create_sample_profiles() -> List[PersonalityProfile]:
    """Create realistic personality profiles based on archetypes."""
    import random
    
    # Define personality archetypes with realistic dimension patterns
    archetypes = [
        {
            'name': 'Explorer',
            'dimensions': {
                'exploration_eagerness': 0.9,
                'adventure_seeking': 0.85,
                'novelty_seeking': 0.8,
                'community_orientation': 0.5,
                'social_preference': 0.6,
                'energy_preference': 0.7,
                'value_orientation': 0.6,
                'crowd_tolerance': 0.7,
                'authenticity': 0.8,
                'archetype': 0.3,
                'trust_level': 0.6,
                'openness': 0.9,
            }
        },
        {
            'name': 'Community Builder',
            'dimensions': {
                'exploration_eagerness': 0.4,
                'adventure_seeking': 0.3,
                'novelty_seeking': 0.4,
                'community_orientation': 0.9,
                'social_preference': 0.85,
                'energy_preference': 0.6,
                'value_orientation': 0.8,
                'crowd_tolerance': 0.9,
                'authenticity': 0.7,
                'archetype': 0.7,
                'trust_level': 0.8,
                'openness': 0.6,
            }
        },
        {
            'name': 'Solo Seeker',
            'dimensions': {
                'exploration_eagerness': 0.7,
                'adventure_seeking': 0.6,
                'novelty_seeking': 0.7,
                'community_orientation': 0.3,
                'social_preference': 0.2,
                'energy_preference': 0.5,
                'value_orientation': 0.7,
                'crowd_tolerance': 0.2,
                'authenticity': 0.9,
                'archetype': 0.5,
                'trust_level': 0.4,
                'openness': 0.5,
            }
        },
        {
            'name': 'Social Butterfly',
            'dimensions': {
                'exploration_eagerness': 0.6,
                'adventure_seeking': 0.5,
                'novelty_seeking': 0.6,
                'community_orientation': 0.8,
                'social_preference': 0.9,
                'energy_preference': 0.8,
                'value_orientation': 0.6,
                'crowd_tolerance': 0.9,
                'authenticity': 0.5,
                'archetype': 0.6,
                'trust_level': 0.7,
                'openness': 0.7,
            }
        },
        {
            'name': 'Deep Thinker',
            'dimensions': {
                'exploration_eagerness': 0.5,
                'adventure_seeking': 0.4,
                'novelty_seeking': 0.6,
                'community_orientation': 0.4,
                'social_preference': 0.3,
                'energy_preference': 0.4,
                'value_orientation': 0.9,
                'crowd_tolerance': 0.3,
                'authenticity': 0.9,
                'archetype': 0.8,
                'trust_level': 0.5,
                'openness': 0.7,
            }
        },
        {
            'name': 'Balanced',
            'dimensions': {
                'exploration_eagerness': 0.5,
                'adventure_seeking': 0.5,
                'novelty_seeking': 0.5,
                'community_orientation': 0.5,
                'social_preference': 0.5,
                'energy_preference': 0.5,
                'value_orientation': 0.5,
                'crowd_tolerance': 0.5,
                'authenticity': 0.5,
                'archetype': 0.5,
                'trust_level': 0.5,
                'openness': 0.5,
            }
        },
    ]
    
    profiles = []
    for i in range(100):
        # Select archetype (weighted distribution)
        archetype = random.choices(
            archetypes,
            weights=[20, 20, 15, 15, 15, 15],  # More explorers and community builders
            k=1
        )[0]
        
        # Add realistic variation (Gaussian noise)
        dimensions = {}
        for dim, base_value in archetype['dimensions'].items():
            variation = random.gauss(0, 0.1)  # 10% standard deviation
            dimensions[dim] = max(0.0, min(1.0, base_value + variation))
        
        profile = PersonalityProfile(
            user_id=f"user_{i}",
            dimensions=dimensions,
            created_at="2025-01-01"
        )
        profiles.append(profile)
    
    return profiles

def analyze_knot_distribution(knots: List[PersonalityKnot]) -> Dict[str, Any]:
    """Analyze distribution of knot types."""
    distribution = defaultdict(int)
    complexities = []
    
    for knot in knots:
        distribution[knot.knot_type] += 1
        complexities.append(knot.complexity)
    
    return {
        'knot_type_distribution': dict(distribution),
        'total_knots': len(knots),
        'complexity_stats': {
            'mean': statistics.mean(complexities) if complexities else 0,
            'median': statistics.median(complexities) if complexities else 0,
            'std_dev': statistics.stdev(complexities) if len(complexities) > 1 else 0,
            'min': min(complexities) if complexities else 0,
            'max': max(complexities) if complexities else 0,
        }
    }

def main():
    """Main validation script."""
    print("=" * 80)
    print("Knot Generation Validation Script")
    print("Phase 0: Patent #31 Validation")
    print("=" * 80)
    
    # Configuration
    data_path = "test/fixtures/personality_profiles.json"
    output_path = "docs/plans/knot_theory/validation/knot_generation_results.json"
    
    # Load profiles
    print("\n1. Loading personality profiles...")
    profiles = load_profiles(input_path)
    print(f"   Loaded {len(profiles)} profiles")
    
    # Generate knots
    print("\n2. Generating knots from profiles...")
    generator = KnotGenerator(correlation_threshold=0.3)
    knots = []
    
    for i, profile in enumerate(profiles):
        if i % 10 == 0:
            print(f"   Processing profile {i+1}/{len(profiles)}...")
        
        try:
            knot = generator.generate_knot(profile)
            knots.append(knot)
        except Exception as e:
            print(f"   Error generating knot for {profile.user_id}: {e}")
            continue
    
    print(f"   Generated {len(knots)} knots successfully")
    
    # Analyze distribution
    print("\n3. Analyzing knot distribution...")
    analysis = analyze_knot_distribution(knots)
    
    print("\n   Knot Type Distribution:")
    for knot_type, count in sorted(analysis['knot_type_distribution'].items()):
        percentage = (count / len(knots)) * 100
        print(f"     {knot_type}: {count} ({percentage:.1f}%)")
    
    print("\n   Complexity Statistics:")
    stats = analysis['complexity_stats']
    print(f"     Mean: {stats['mean']:.3f}")
    print(f"     Median: {stats['median']:.3f}")
    print(f"     Std Dev: {stats['std_dev']:.3f}")
    print(f"     Range: [{stats['min']:.3f}, {stats['max']:.3f}]")
    
    # Save results
    print("\n4. Saving results...")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    results = {
        'total_profiles': len(profiles),
        'total_knots_generated': len(knots),
        'success_rate': len(knots) / len(profiles) if profiles else 0,
        'analysis': analysis,
        'knots': [
            {
                'user_id': knot.user_id,
                'knot_type': knot.knot_type,
                'crossing_number': knot.invariants.crossing_number,
                'complexity': knot.complexity,
                'jones_polynomial': knot.invariants.jones_polynomial,
                'alexander_polynomial': knot.invariants.alexander_polynomial,
            }
            for knot in knots
        ]
    }
    
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"   Results saved to: {output_path}")
    
    # Validation summary
    print("\n" + "=" * 80)
    print("VALIDATION SUMMARY")
    print("=" * 80)
    print(f"✓ Generated {len(knots)} knots from {len(profiles)} profiles")
    print(f"✓ Success rate: {results['success_rate']*100:.1f}%")
    print(f"✓ Knot types identified: {len(analysis['knot_type_distribution'])}")
    print(f"✓ Results saved to: {output_path}")
    print("\nNext Steps:")
    print("  1. Review knot type distribution")
    print("  2. Validate knot types match personality archetypes")
    print("  3. Run matching accuracy comparison script")
    print("=" * 80)

def main():
    """Main validation script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate knots from personality profiles')
    parser.add_argument('--input', type=str,
                       default="test/fixtures/personality_profiles.json",
                       help='Path to personality profiles JSON file')
    parser.add_argument('--output', type=str,
                       default="docs/plans/knot_theory/validation/knot_generation_results.json",
                       help='Output JSON file path')
    
    args = parser.parse_args()
    
    input_path = args.input
    output_path = args.output
    
    print("=" * 80)
    print("Knot Generation from Personality Profiles")
    print("Phase 0: Patent #31 Validation")
    print("=" * 80)
    
    # Load profiles
    print("\n1. Loading profiles...")
    profiles = load_profiles(input_path)
    print(f"   Loaded {len(profiles)} profiles")
    
    # Generate knots
    print("\n2. Generating knots from profiles...")
    generator = KnotGenerator(correlation_threshold=0.3)
    knots = []
    
    for i, profile in enumerate(profiles):
        if i % 10 == 0:
            print(f"   Processing profile {i+1}/{len(profiles)}...")
        
        try:
            knot = generator.generate_knot(profile)
            knots.append(knot)
        except Exception as e:
            print(f"   Error generating knot for {profile.user_id}: {e}")
            continue
    
    print(f"   Generated {len(knots)} knots successfully")
    
    # Analyze distribution
    print("\n3. Analyzing knot distribution...")
    analysis = analyze_knot_distribution(knots)
    
    print("\n   Knot Type Distribution:")
    for knot_type, count in sorted(analysis['knot_type_distribution'].items()):
        percentage = (count / len(knots)) * 100
        print(f"     {knot_type}: {count} ({percentage:.1f}%)")
    
    print("\n   Complexity Statistics:")
    stats = analysis['complexity_stats']
    print(f"     Mean: {stats['mean']:.3f}")
    print(f"     Median: {stats['median']:.3f}")
    print(f"     Std Dev: {stats['std_dev']:.3f}")
    print(f"     Range: [{stats['min']:.3f}, {stats['max']:.3f}]")
    
    # Save results
    print("\n4. Saving results...")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    results = {
        'total_profiles': len(profiles),
        'total_knots_generated': len(knots),
        'success_rate': len(knots) / len(profiles) if profiles else 0,
        'analysis': analysis,
        'knots': [
            {
                'user_id': knot.user_id,
                'knot_type': knot.knot_type,
                'crossing_number': knot.invariants.crossing_number,
                'complexity': knot.complexity,
                'jones_polynomial': knot.invariants.jones_polynomial,
                'alexander_polynomial': knot.invariants.alexander_polynomial,
            }
            for knot in knots
        ]
    }
    
    with open(output_path, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"   Results saved to: {output_path}")
    
    # Validation summary
    print("\n" + "=" * 80)
    print("VALIDATION SUMMARY")
    print("=" * 80)
    print(f"✓ Generated {len(knots)} knots from {len(profiles)} profiles")
    print(f"✓ Success rate: {results['success_rate']*100:.1f}%")
    print(f"✓ Knot types identified: {len(analysis['knot_type_distribution'])}")
    print(f"✓ Results saved to: {output_path}")
    print("\nNext Steps:")
    print("  1. Review knot type distribution")
    print("  2. Validate knot types match personality archetypes")
    print("  3. Run matching accuracy comparison script")
    print("=" * 80)

if __name__ == "__main__":
    main()

