#!/usr/bin/env python3
"""
Spot Vibe Converter for AVRAI Training Data
Phase: ML Reality and Quantum Readiness - Phase 1.3

Converts raw spot data (from OSM + optional Google Places enrichment)
into 12-dimensional vibe profiles using improved inference logic.

All 12 dimensions are inferred from real characteristics instead of
defaulting 8 to 0.5. This logic MUST match the Dart implementation
in lib/core/models/spot_vibe.dart _inferDimensionsFromCharacteristics().

Usage:
    python scripts/data_collection/spot_vibe_converter.py
    python scripts/data_collection/spot_vibe_converter.py --input data/raw/google_enriched_spots.json
"""

import argparse
import json
import math
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional


# ============================================================================
# Dimension inference logic
# IMPORTANT: This must match lib/core/models/spot_vibe.dart
# ============================================================================

# Categories that indicate high energy
HIGH_ENERGY_CATEGORIES = {'Nightlife'}
HIGH_ENERGY_AMENITIES = {'nightclub', 'bar', 'pub', 'biergarten', 'casino'}
LOW_ENERGY_AMENITIES = {'library', 'place_of_worship', 'community_centre'}
LOW_ENERGY_LEISURE = {'park', 'garden', 'nature_reserve'}

# Categories that indicate high social
HIGH_SOCIAL_AMENITIES = {'nightclub', 'bar', 'pub', 'community_centre', 'social_facility', 'biergarten'}
LOW_SOCIAL_AMENITIES = {'library'}

# Categories that indicate high exploration
HIGH_EXPLORATION_TOURISM = {'museum', 'gallery', 'attraction', 'viewpoint', 'artwork', 'zoo', 'aquarium', 'theme_park'}
HIGH_EXPLORATION_LEISURE = {'nature_reserve', 'garden'}

# Categories that indicate authenticity
AUTHENTIC_TAGS = {'artisan', 'craft', 'vintage', 'antiques', 'local', 'independent'}
CHAIN_INDICATORS = {'brand', 'brand:wikidata'}

# Categories for curation/upscale
CURATED_SHOPS = {'boutique', 'art', 'jewelry', 'antiques', 'vintage'}
CURATED_AMENITIES = {'arts_centre'}

# Known chain brands (partial list for detection)
KNOWN_CHAINS = {
    'starbucks', 'mcdonalds', "mcdonald's", 'subway', 'dunkin', 'chipotle',
    'taco bell', 'burger king', 'wendy', 'chick-fil-a', "chick fil a",
    'panera', 'domino', 'pizza hut', 'kfc', 'popeyes', 'five guys',
    'shake shack', 'sweetgreen', 'walmart', 'target', 'costco',
    'whole foods', 'trader joe', "trader joe's", 'cvs', 'walgreens',
    'rite aid', 'home depot', 'lowes', "lowe's", 'best buy',
    'barnes & noble', 'apple store', 'nike', 'adidas', 'gap',
    'old navy', 'h&m', 'zara', 'uniqlo', 'forever 21',
    'marriott', 'hilton', 'hyatt', 'holiday inn', 'hampton inn',
    'courtyard', 'residence inn', 'la quinta', 'best western',
}


def _is_chain(spot: Dict) -> bool:
    """Detect if a spot is a chain establishment."""
    meta = spot.get('osm_metadata', {})
    if meta.get('is_chain', False):
        return True
    brand = (meta.get('brand') or '').lower()
    name = spot.get('name', '').lower()
    for chain in KNOWN_CHAINS:
        if chain in name or chain in brand:
            return True
    return False


def _has_late_hours(spot: Dict) -> bool:
    """Check if spot has late-night hours."""
    meta = spot.get('osm_metadata', {})
    hours = meta.get('opening_hours')
    if isinstance(hours, dict):
        return hours.get('has_late_hours', False)
    return False


def _is_24h(spot: Dict) -> bool:
    """Check if spot is open 24/7."""
    meta = spot.get('osm_metadata', {})
    hours = meta.get('opening_hours')
    if isinstance(hours, dict):
        return hours.get('is_24h', False)
    return False


def _has_early_hours(spot: Dict) -> bool:
    """Check if spot opens early."""
    meta = spot.get('osm_metadata', {})
    hours = meta.get('opening_hours')
    if isinstance(hours, dict):
        return hours.get('has_early_hours', False)
    return False


def _get_amenity(spot: Dict) -> Optional[str]:
    """Get the primary OSM amenity type."""
    return spot.get('osm_metadata', {}).get('amenity')


def _get_tourism(spot: Dict) -> Optional[str]:
    """Get the primary OSM tourism type."""
    return spot.get('osm_metadata', {}).get('tourism')


def _get_leisure(spot: Dict) -> Optional[str]:
    """Get the primary OSM leisure type."""
    return spot.get('osm_metadata', {}).get('leisure')


def _get_shop(spot: Dict) -> Optional[str]:
    """Get the primary OSM shop type."""
    return spot.get('osm_metadata', {}).get('shop')


def infer_spot_vibe_dimensions(spot: Dict) -> Dict[str, float]:
    """
    Infer all 12 AVRAI vibe dimensions from spot characteristics.
    
    This is the core inference logic. It MUST match the Dart implementation
    in lib/core/models/spot_vibe.dart _inferDimensionsFromCharacteristics().
    
    Returns:
        Dict mapping dimension name to value (0.0-1.0)
    """
    category = spot.get('category', 'Other')
    tags = spot.get('tags', [])
    description = spot.get('description', '')
    rating = spot.get('rating')
    price_level = spot.get('price_level')
    review_count = spot.get('review_count')
    
    amenity = _get_amenity(spot)
    tourism = _get_tourism(spot)
    leisure = _get_leisure(spot)
    shop = _get_shop(spot)
    is_chain = _is_chain(spot)
    has_late = _has_late_hours(spot)
    is_open_24h = _is_24h(spot)
    has_early = _has_early_hours(spot)
    has_outdoor = spot.get('osm_metadata', {}).get('outdoor_seating', False)
    
    combined_text = f'{category} {" ".join(tags)} {description}'.lower()
    
    dims: Dict[str, float] = {}
    
    # ---- exploration_eagerness ----
    # High for unique/hidden/tourist attractions, low for chains/routine spots
    if tourism in HIGH_EXPLORATION_TOURISM:
        dims['exploration_eagerness'] = 0.85
    elif leisure in HIGH_EXPLORATION_LEISURE:
        dims['exploration_eagerness'] = 0.75
    elif any(kw in combined_text for kw in ['new', 'unique', 'hidden', 'gem', 'secret', 'discover']):
        dims['exploration_eagerness'] = 0.80
    elif is_chain:
        dims['exploration_eagerness'] = 0.25
    else:
        dims['exploration_eagerness'] = 0.50
    
    # ---- community_orientation ----
    # High for community centers, social spots; low for solo-oriented
    if amenity in HIGH_SOCIAL_AMENITIES or amenity in {'community_centre', 'social_facility'}:
        dims['community_orientation'] = 0.85
    elif any(kw in combined_text for kw in ['community', 'group', 'social', 'meetup', 'gathering']):
        dims['community_orientation'] = 0.80
    elif amenity == 'library' or leisure in {'nature_reserve'}:
        dims['community_orientation'] = 0.30
    elif review_count is not None and review_count > 500:
        # Popular places tend to have community around them
        dims['community_orientation'] = 0.65
    else:
        dims['community_orientation'] = 0.50
    
    # ---- authenticity_preference ----
    # High for local/artisan/craft, low for chains/trendy
    if is_chain:
        dims['authenticity_preference'] = 0.20
    elif any(kw in combined_text for kw in ['authentic', 'artisan', 'craft', 'heritage', 'traditional', 'vintage', 'independent']):
        dims['authenticity_preference'] = 0.85
    elif any(kw in combined_text for kw in ['art', 'culture', 'museum', 'gallery', 'sophisticated', 'refined']):
        dims['authenticity_preference'] = 0.90
    elif shop in {'antiques', 'vintage'}:
        dims['authenticity_preference'] = 0.85
    elif any(kw in combined_text for kw in ['popular', 'trendy', 'mainstream']):
        dims['authenticity_preference'] = 0.35
    else:
        dims['authenticity_preference'] = 0.55
    
    # ---- energy_preference ----
    # High for bars/clubs/nightlife, low for libraries/parks/spas
    if amenity in HIGH_ENERGY_AMENITIES or category == 'Nightlife':
        base = 0.80
        if has_late:
            base = 0.90
        dims['energy_preference'] = base
    elif amenity in LOW_ENERGY_AMENITIES or leisure in LOW_ENERGY_LEISURE:
        dims['energy_preference'] = 0.20
    elif any(kw in combined_text for kw in ['energetic', 'lively', 'vibrant', 'bustling', 'exciting']):
        dims['energy_preference'] = 0.80
    elif any(kw in combined_text for kw in ['chill', 'relaxed', 'quiet', 'calm', 'peaceful', 'zen', 'spa']):
        dims['energy_preference'] = 0.20
    elif amenity in {'cafe'}:
        dims['energy_preference'] = 0.35
    else:
        dims['energy_preference'] = 0.50
    
    # ---- social_discovery_style ----
    # High capacity / group-friendly = high, intimate/solo = low
    if amenity in HIGH_SOCIAL_AMENITIES:
        dims['social_discovery_style'] = 0.80
    elif has_outdoor:
        dims['social_discovery_style'] = 0.65
    elif leisure in {'stadium', 'sports_centre'}:
        dims['social_discovery_style'] = 0.85
    elif amenity in {'library'}:
        dims['social_discovery_style'] = 0.25
    elif category == 'Nightlife':
        dims['social_discovery_style'] = 0.75
    elif review_count is not None and review_count > 200:
        dims['social_discovery_style'] = 0.60
    else:
        dims['social_discovery_style'] = 0.50
    
    # ---- temporal_flexibility ----
    # 24h = very flexible, appointment-only = low, normal hours = medium
    if is_open_24h:
        dims['temporal_flexibility'] = 0.90
    elif has_late and has_early:
        dims['temporal_flexibility'] = 0.80
    elif has_late:
        dims['temporal_flexibility'] = 0.70
    elif leisure in {'park', 'garden', 'nature_reserve', 'playground'}:
        # Parks are generally always accessible
        dims['temporal_flexibility'] = 0.85
    elif amenity in {'restaurant', 'fast_food'}:
        dims['temporal_flexibility'] = 0.55
    else:
        dims['temporal_flexibility'] = 0.50
    
    # ---- location_adventurousness ----
    # Tourist attractions/viewpoints = high, routine errands = low
    if tourism in {'viewpoint', 'attraction', 'artwork'}:
        dims['location_adventurousness'] = 0.85
    elif tourism in HIGH_EXPLORATION_TOURISM:
        dims['location_adventurousness'] = 0.75
    elif leisure in {'nature_reserve'}:
        dims['location_adventurousness'] = 0.80
    elif is_chain:
        dims['location_adventurousness'] = 0.25
    elif any(kw in combined_text for kw in ['adventure', 'explore', 'hidden', 'offbeat']):
        dims['location_adventurousness'] = 0.80
    else:
        dims['location_adventurousness'] = 0.45
    
    # ---- curation_tendency ----
    # Upscale/boutique/specialty = high, generic/mass-market = low
    if shop in CURATED_SHOPS or amenity in CURATED_AMENITIES:
        dims['curation_tendency'] = 0.80
    elif price_level is not None and price_level >= 3:
        dims['curation_tendency'] = 0.80
    elif price_level is not None and price_level <= 1:
        dims['curation_tendency'] = 0.30
    elif any(kw in combined_text for kw in ['boutique', 'curated', 'specialty', 'artisan', 'select', 'premium']):
        dims['curation_tendency'] = 0.80
    elif is_chain:
        dims['curation_tendency'] = 0.25
    else:
        dims['curation_tendency'] = 0.50
    
    # ---- trust_network_reliance ----
    # High reviews + high rating = low trust needed (strangers trust it)
    # Low reviews = need personal recommendation (high trust reliance)
    if review_count is not None and rating is not None:
        if review_count > 500 and rating >= 4.0:
            dims['trust_network_reliance'] = 0.25  # Very well-known, low trust needed
        elif review_count > 100 and rating >= 3.5:
            dims['trust_network_reliance'] = 0.40
        elif review_count < 10:
            dims['trust_network_reliance'] = 0.80  # Undiscovered, need personal trust
        else:
            dims['trust_network_reliance'] = 0.55
    elif is_chain:
        dims['trust_network_reliance'] = 0.20  # Chains are known entities
    else:
        dims['trust_network_reliance'] = 0.55
    
    # ---- novelty_seeking ----
    # New/unique places = high, established chains = low
    if any(kw in combined_text for kw in ['new', 'novel', 'unique', 'innovative', 'experimental', 'popup', 'pop-up']):
        dims['novelty_seeking'] = 0.80
    elif tourism in HIGH_EXPLORATION_TOURISM:
        dims['novelty_seeking'] = 0.70
    elif is_chain:
        dims['novelty_seeking'] = 0.20
    elif shop in {'vintage', 'antiques'}:
        dims['novelty_seeking'] = 0.65  # Old things but novel experience
    else:
        dims['novelty_seeking'] = 0.50
    
    # ---- value_orientation ----
    # Price level mapping: free/cheap = low value orientation, expensive = high
    if price_level is not None:
        # Google price levels: 0=free, 1=inexpensive, 2=moderate, 3=expensive, 4=very expensive
        price_map = {0: 0.10, 1: 0.30, 2: 0.50, 3: 0.75, 4: 0.90}
        dims['value_orientation'] = price_map.get(price_level, 0.50)
    elif leisure in {'park', 'garden', 'playground', 'nature_reserve'}:
        dims['value_orientation'] = 0.10  # Free
    elif amenity == 'library':
        dims['value_orientation'] = 0.10  # Free
    elif category == 'Nightlife':
        dims['value_orientation'] = 0.65
    elif shop in CURATED_SHOPS:
        dims['value_orientation'] = 0.70
    else:
        dims['value_orientation'] = 0.45
    
    # ---- crowd_tolerance ----
    # Large venues/outdoor = high tolerance for crowds, intimate = low
    if leisure in {'stadium', 'theme_park'}:
        dims['crowd_tolerance'] = 0.90
    elif leisure in {'park', 'garden', 'nature_reserve'}:
        dims['crowd_tolerance'] = 0.75  # Outdoor, crowd disperses
    elif has_outdoor:
        dims['crowd_tolerance'] = 0.65
    elif amenity in {'nightclub'}:
        dims['crowd_tolerance'] = 0.85
    elif amenity in {'cafe', 'library'}:
        dims['crowd_tolerance'] = 0.30
    elif review_count is not None and review_count > 1000:
        dims['crowd_tolerance'] = 0.70  # Very popular = crowded
    else:
        dims['crowd_tolerance'] = 0.50
    
    # Clamp all values
    for key in dims:
        dims[key] = max(0.0, min(1.0, dims[key]))
    
    return dims


def convert_spot(spot: Dict) -> Dict:
    """Convert a raw spot to a training-ready spot with 12D vibe dimensions."""
    dims = infer_spot_vibe_dimensions(spot)
    
    return {
        'spot_id': spot.get('osm_id') or spot.get('name', 'unknown'),
        'name': spot.get('name', ''),
        'latitude': spot.get('latitude', 0),
        'longitude': spot.get('longitude', 0),
        'category': spot.get('category', 'Other'),
        'city': spot.get('city', ''),
        'tags': spot.get('tags', []),
        'description': spot.get('description', ''),
        'rating': spot.get('rating'),
        'price_level': spot.get('price_level'),
        'review_count': spot.get('review_count'),
        'vibe_dimensions': dims,
        'metadata': {
            'is_chain': _is_chain(spot),
            'has_late_hours': _has_late_hours(spot),
            'has_outdoor_seating': spot.get('osm_metadata', {}).get('outdoor_seating', False),
            'cuisine': spot.get('osm_metadata', {}).get('cuisine'),
        },
    }


def main():
    parser = argparse.ArgumentParser(
        description='Convert raw spot data to 12D vibe dimensions for AVRAI training',
    )
    parser.add_argument(
        '--input',
        type=Path,
        default=None,
        help='Input spots JSON (tries google_enriched_spots.json then osm_spots.json)',
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/processed/real_spot_vibes_12d.json'),
        help='Output 12D vibes JSON (default: data/processed/real_spot_vibes_12d.json)',
    )

    args = parser.parse_args()

    # Determine input file
    input_path = args.input
    if input_path is None:
        enriched = Path('data/raw/google_enriched_spots.json')
        osm_only = Path('data/raw/osm_spots.json')
        if enriched.exists():
            input_path = enriched
            print(f'Using enriched data: {enriched}')
        elif osm_only.exists():
            input_path = osm_only
            print(f'Using OSM-only data: {osm_only}')
        else:
            print('Error: No input data found.')
            print('Run extract_osm_spots.py first.')
            sys.exit(1)

    # Load spots
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    spots = data.get('spots', [])
    print(f'Loaded {len(spots)} spots')

    # Convert
    converted = []
    for spot in spots:
        converted.append(convert_spot(spot))

    # Statistics
    print(f'\nConverted {len(converted)} spots to 12D vibe profiles')

    # Dimension distribution summary
    dim_names = [
        'exploration_eagerness', 'community_orientation', 'authenticity_preference',
        'energy_preference', 'social_discovery_style', 'temporal_flexibility',
        'location_adventurousness', 'curation_tendency', 'trust_network_reliance',
        'novelty_seeking', 'value_orientation', 'crowd_tolerance',
    ]
    print('\nDimension distributions (mean +/- std):')
    for dim in dim_names:
        values = [s['vibe_dimensions'].get(dim, 0.5) for s in converted]
        if values:
            import statistics
            mean = statistics.mean(values)
            std = statistics.stdev(values) if len(values) > 1 else 0.0
            at_default = sum(1 for v in values if abs(v - 0.5) < 0.01)
            pct_default = at_default / len(values) * 100
            print(f'  {dim:30s}: {mean:.3f} +/- {std:.3f}  (at 0.5 default: {pct_default:.1f}%)')

    # Category breakdown
    print('\nBy category:')
    cat_counts = {}
    for s in converted:
        cat = s['category']
        cat_counts[cat] = cat_counts.get(cat, 0) + 1
    for cat, count in sorted(cat_counts.items(), key=lambda x: -x[1]):
        print(f'  {cat}: {count}')

    # Save output
    output_data = {
        'metadata': {
            'source': str(input_path),
            'total_spots': len(converted),
            'conversion_date': time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime()),
            'dimensions': dim_names,
        },
        'spots': converted,
    }

    os.makedirs(args.output.parent, exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f'\nSaved to: {args.output}')
    print(f'File size: {os.path.getsize(args.output) / 1024 / 1024:.1f} MB')


if __name__ == '__main__':
    main()
