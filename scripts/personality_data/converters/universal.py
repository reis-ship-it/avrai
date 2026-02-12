"""
Universal Personality Data Converter

Converts any personality data format to SPOTS 12 dimensions using:
- Auto-detection of known formats
- Heuristic field mapping
- Semantic similarity matching
- Intelligent defaults
"""

from typing import Dict, List, Any, Optional
from scripts.personality_data.converters.base import PersonalityConverter
from difflib import SequenceMatcher

# SPOTS 12 dimensions
SPOTS_DIMENSIONS = [
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

# Known format patterns (for auto-detection)
KNOWN_FORMATS = {
    'big_five': {
        'keywords': ['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism', 'ocean'],
        'required_fields': ['openness', 'conscientiousness', 'extraversion', 'agreeableness', 'neuroticism'],
        'converter': 'big_five_to_spots',
    },
    'mbti': {
        'keywords': ['mbti', 'myers', 'briggs', 'intj', 'enfp', 'personality_type'],
        'required_fields': ['type', 'mbti'],
    },
    'enneagram': {
        'keywords': ['enneagram', 'type', 'wing'],
        'required_fields': ['type', 'enneagram'],
    },
}

# Semantic field mappings (field name → SPOTS dimension)
SEMANTIC_MAPPINGS = {
    # Exploration/Novelty
    'exploration': ['exploration_eagerness', 'novelty_seeking'],
    'adventure': ['exploration_eagerness', 'location_adventurousness'],
    'novelty': ['novelty_seeking'],
    'curiosity': ['exploration_eagerness', 'novelty_seeking'],
    'openness': ['exploration_eagerness', 'novelty_seeking'],
    
    # Social/Community
    'social': ['social_discovery_style', 'community_orientation'],
    'community': ['community_orientation'],
    'extraversion': ['social_discovery_style', 'community_orientation'],
    'sociability': ['social_discovery_style'],
    
    # Authenticity/Values
    'authenticity': ['authenticity_preference'],
    'conscientiousness': ['value_orientation', 'authenticity_preference'],
    'value': ['value_orientation'],
    'quality': ['value_orientation'],
    
    # Trust/Crowd
    'trust': ['trust_network_reliance'],
    'agreeableness': ['trust_network_reliance', 'crowd_tolerance'],
    'tolerance': ['crowd_tolerance'],
    'crowd': ['crowd_tolerance'],
    
    # Energy
    'energy': ['energy_preference'],
    'neuroticism': ['energy_preference'],  # Inverted
    'stability': ['energy_preference'],
    
    # Temporal
    'temporal': ['temporal_flexibility'],
    'flexibility': ['temporal_flexibility'],
    'spontaneity': ['temporal_flexibility'],
    
    # Curation
    'curation': ['curation_tendency'],
    'sharing': ['curation_tendency'],
    
    # Location
    'location': ['location_adventurousness'],
    'adventurousness': ['location_adventurousness'],
    'travel': ['location_adventurousness'],
}


class UniversalPersonalityConverter(PersonalityConverter):
    """
    Universal converter that auto-detects format and converts to SPOTS 12 dimensions.
    
    Features:
    - Auto-detects known formats (Big5, MBTI, Enneagram)
    - Heuristic field mapping for unknown formats
    - Semantic similarity matching
    - Intelligent defaults for missing dimensions
    """
    
    def __init__(self, custom_mappings: Optional[Dict[str, List[str]]] = None, scale: str = 'auto'):
        """
        Initialize universal converter.
        
        Args:
            custom_mappings: Custom field → SPOTS dimension mappings
                           e.g., {'my_field': ['exploration_eagerness', 'novelty_seeking']}
            scale: Scale type for numeric values ('1-5', '0-1', '0-100', 'auto')
        """
        self.custom_mappings = custom_mappings or {}
        self.scale = scale
        self.detected_format = None
        self.field_mappings = {}
    
    def detect_format(self, source_data: Dict[str, Any]) -> Optional[str]:
        """
        Auto-detect personality format from source data.
        
        Args:
            source_data: Source personality data
        
        Returns:
            Format identifier or None if unknown
        """
        source_keys = [k.lower() for k in source_data.keys()]
        source_str = ' '.join(source_keys).lower()
        
        # Check known formats
        for format_id, format_info in KNOWN_FORMATS.items():
            # Check for required fields
            if all(field in source_keys for field in format_info['required_fields']):
                return format_id
            
            # Check for keywords
            if any(keyword in source_str for keyword in format_info['keywords']):
                return format_id
        
        return None
    
    def map_fields_to_spots(self, source_data: Dict[str, Any]) -> Dict[str, List[str]]:
        """
        Map source fields to SPOTS dimensions using heuristics.
        
        Returns:
            Dict mapping source field → list of SPOTS dimensions
        """
        mappings = {}
        source_keys = [k.lower() for k in source_data.keys()]
        
        # 1. Check custom mappings first
        for field, spots_dims in self.custom_mappings.items():
            if field.lower() in source_keys:
                mappings[field.lower()] = spots_dims
        
        # 2. Check semantic mappings
        for semantic_key, spots_dims in SEMANTIC_MAPPINGS.items():
            for source_key in source_keys:
                if semantic_key in source_key or source_key in semantic_key:
                    if source_key not in mappings:
                        mappings[source_key] = spots_dims
        
        # 3. Use similarity matching for remaining fields
        for source_key in source_keys:
            if source_key not in mappings:
                best_match = self._find_semantic_match(source_key)
                if best_match:
                    mappings[source_key] = SEMANTIC_MAPPINGS[best_match]
        
        return mappings
    
    def _find_semantic_match(self, field_name: str) -> Optional[str]:
        """Find best semantic match for a field name."""
        best_match = None
        best_score = 0.0
        
        for semantic_key in SEMANTIC_MAPPINGS.keys():
            score = SequenceMatcher(None, field_name.lower(), semantic_key).ratio()
            if score > 0.6 and score > best_score:  # 60% similarity threshold
                best_score = score
                best_match = semantic_key
        
        return best_match
    
    def convert(self, source_data: Dict[str, Any]) -> Dict[str, float]:
        """
        Convert any personality data to SPOTS 12 dimensions.
        
        Args:
            source_data: Source personality data (any format)
        
        Returns:
            Dict with SPOTS 12 dimensions (0.0-1.0)
        """
        # Auto-detect format
        detected_format = self.detect_format(source_data)
        self.detected_format = detected_format
        
        # If known format, try to use specific converter
        if detected_format and detected_format in KNOWN_FORMATS:
            converter_id = KNOWN_FORMATS[detected_format].get('converter')
            if converter_id:
                try:
                    from scripts.personality_data.registry.converter_registry import get_converter
                    converter_class = get_converter(converter_id)
                    if converter_class:
                        converter = converter_class(scale=self.scale)
                        return converter.convert(source_data)
                except Exception:
                    # Fall back to heuristic conversion if specific converter fails
                    pass
        
        # Otherwise, use heuristic mapping
        return self._convert_with_heuristics(source_data)
    
    def _convert_with_heuristics(self, source_data: Dict[str, Any]) -> Dict[str, float]:
        """Convert using heuristic field mapping."""
        # Map fields to SPOTS dimensions
        field_mappings = self.map_fields_to_spots(source_data)
        self.field_mappings = field_mappings
        
        # Initialize SPOTS dimensions
        spots_dimensions = {dim: 0.0 for dim in SPOTS_DIMENSIONS}
        dimension_counts = {dim: 0 for dim in SPOTS_DIMENSIONS}
        
        # Convert each source field
        for source_field, source_value in source_data.items():
            source_field_lower = source_field.lower()
            
            # Get mapped SPOTS dimensions
            mapped_dims = field_mappings.get(source_field_lower, [])
            
            if mapped_dims:
                # Normalize value
                normalized_value = self.normalize_value(source_value, self.scale)
                
                # Distribute value across mapped dimensions
                for dim in mapped_dims:
                    if dim in spots_dimensions:
                        spots_dimensions[dim] += normalized_value
                        dimension_counts[dim] += 1
            else:
                # Unknown field - try to infer from value type/name
                inferred_dims = self._infer_dimensions_from_field(source_field, source_value)
                if inferred_dims:
                    normalized_value = self.normalize_value(source_value, self.scale)
                    for dim in inferred_dims:
                        if dim in spots_dimensions:
                            spots_dimensions[dim] += normalized_value
                            dimension_counts[dim] += 1
        
        # Average values for dimensions with multiple sources
        for dim in SPOTS_DIMENSIONS:
            if dimension_counts[dim] > 0:
                spots_dimensions[dim] /= dimension_counts[dim]
            else:
                # No data for this dimension - use intelligent default
                spots_dimensions[dim] = self._get_intelligent_default(dim, source_data, spots_dimensions)
        
        # Ensure all values are in [0.0, 1.0]
        for dim in spots_dimensions:
            spots_dimensions[dim] = max(0.0, min(1.0, spots_dimensions[dim]))
        
        return spots_dimensions
    
    def _infer_dimensions_from_field(self, field_name: str, value: Any) -> List[str]:
        """Infer SPOTS dimensions from field name and value."""
        field_lower = field_name.lower()
        
        # Pattern matching
        if 'explor' in field_lower or 'adventur' in field_lower:
            return ['exploration_eagerness', 'location_adventurousness']
        elif 'social' in field_lower or 'community' in field_lower:
            return ['social_discovery_style', 'community_orientation']
        elif 'authentic' in field_lower or 'value' in field_lower:
            return ['authenticity_preference', 'value_orientation']
        elif 'trust' in field_lower:
            return ['trust_network_reliance']
        elif 'energy' in field_lower or 'active' in field_lower:
            return ['energy_preference']
        elif 'novel' in field_lower or 'new' in field_lower:
            return ['novelty_seeking']
        elif 'crowd' in field_lower or 'busy' in field_lower:
            return ['crowd_tolerance']
        elif 'flexible' in field_lower or 'spontan' in field_lower:
            return ['temporal_flexibility']
        elif 'curat' in field_lower or 'share' in field_lower:
            return ['curation_tendency']
        
        return []
    
    def _get_intelligent_default(self, dimension: str, source_data: Dict[str, Any], computed_dimensions: Dict[str, float]) -> float:
        """Get intelligent default value for missing dimension."""
        # Use average of related dimensions if available
        related_dims = {
            'exploration_eagerness': ['novelty_seeking', 'location_adventurousness'],
            'novelty_seeking': ['exploration_eagerness'],
            'community_orientation': ['social_discovery_style'],
            'social_discovery_style': ['community_orientation'],
            'authenticity_preference': ['value_orientation'],
            'value_orientation': ['authenticity_preference'],
            'trust_network_reliance': ['crowd_tolerance'],
            'crowd_tolerance': ['trust_network_reliance'],
        }
        
        if dimension in related_dims:
            related_values = []
            for related_dim in related_dims[dimension]:
                if related_dim in computed_dimensions and computed_dimensions[related_dim] > 0:
                    related_values.append(computed_dimensions[related_dim])
            
            if related_values:
                return sum(related_values) / len(related_values)
        
        # Default: neutral (0.5)
        return 0.5
    
    def validate_source(self, source_data: Dict[str, Any]) -> bool:
        """Validate that source data has at least some personality fields."""
        if not isinstance(source_data, dict):
            return False
        
        if len(source_data) == 0:
            return False
        
        # Check if at least one field looks like personality data
        source_keys = [k.lower() for k in source_data.keys()]
        personality_keywords = [
            'personality', 'trait', 'dimension', 'score', 'value',
            'openness', 'extraversion', 'conscientiousness', 'agreeableness', 'neuroticism',
            'mbti', 'enneagram', 'type', 'preference', 'orientation',
            'exploration', 'social', 'community', 'authenticity', 'energy',
            'novelty', 'value', 'trust', 'crowd', 'curation'
        ]
        
        return any(keyword in ' '.join(source_keys) for keyword in personality_keywords)
    
    def get_source_format(self) -> str:
        """Return 'universal' as format identifier."""
        return 'universal'
    
    def get_required_fields(self) -> List[str]:
        """No required fields - works with any data."""
        return []
