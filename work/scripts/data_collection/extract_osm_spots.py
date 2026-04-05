#!/usr/bin/env python3
"""
OSM Bulk Spot Extractor for AVRAI Training Data
Phase: ML Reality and Quantum Readiness - Phase 1.1

Downloads real venue/spot data from OpenStreetMap via the Overpass API
for target US cities. Free, no API key required.

Usage:
    python scripts/data_collection/extract_osm_spots.py
    python scripts/data_collection/extract_osm_spots.py --cities nyc la chicago
    python scripts/data_collection/extract_osm_spots.py --output data/raw/osm_spots.json --limit 10000
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError

# City bounding boxes (south, west, north, east)
CITY_BBOXES: Dict[str, Dict] = {
    'nyc': {
        'name': 'New York City',
        'bbox': (40.4774, -74.2591, 40.9176, -73.7004),
    },
    'la': {
        'name': 'Los Angeles',
        'bbox': (33.7037, -118.6682, 34.3373, -118.1553),
    },
    'chicago': {
        'name': 'Chicago',
        'bbox': (41.6445, -87.9401, 42.0230, -87.5237),
    },
    'miami': {
        'name': 'Miami',
        'bbox': (25.7090, -80.3174, 25.8560, -80.1300),
    },
    'austin': {
        'name': 'Austin',
        'bbox': (30.1135, -97.9383, 30.5168, -97.5614),
    },
    'sf': {
        'name': 'San Francisco',
        'bbox': (37.7080, -122.5148, 37.8120, -122.3570),
    },
    'seattle': {
        'name': 'Seattle',
        'bbox': (47.4810, -122.4596, 47.7341, -122.2244),
    },
    'denver': {
        'name': 'Denver',
        'bbox': (39.6143, -105.1100, 39.7980, -104.6002),
    },
    'nashville': {
        'name': 'Nashville',
        'bbox': (35.9788, -86.9200, 36.2780, -86.5600),
    },
    'portland': {
        'name': 'Portland',
        'bbox': (45.4321, -122.8365, 45.6532, -122.4720),
    },
}

# OSM amenity/tourism/leisure/shop types we care about
VENUE_QUERIES = [
    # Food & Drink
    'node["amenity"~"restaurant|cafe|bar|pub|fast_food|ice_cream|food_court|biergarten"]',
    # Nightlife
    'node["amenity"~"nightclub|cinema|theatre|casino"]',
    # Culture & Attractions
    'node["tourism"~"museum|gallery|attraction|viewpoint|artwork|zoo|aquarium|theme_park"]',
    # Shopping
    'node["shop"~"clothes|boutique|books|gift|art|jewelry|antiques|music|vintage|department_store|mall"]',
    # Leisure & Activities
    'node["leisure"~"park|fitness_centre|sports_centre|swimming_pool|bowling_alley|garden|nature_reserve|playground|stadium"]',
    # Community
    'node["amenity"~"library|community_centre|place_of_worship|arts_centre|social_facility|coworking_space"]',
    # Accommodation
    'node["tourism"~"hotel|hostel|guest_house|motel"]',
]

# Map OSM tags to AVRAI categories
OSM_TO_AVRAI_CATEGORY = {
    # Food & Drink
    'restaurant': 'Food',
    'cafe': 'Food',
    'fast_food': 'Food',
    'ice_cream': 'Food',
    'food_court': 'Food',
    'biergarten': 'Food',
    # Nightlife
    'bar': 'Nightlife',
    'pub': 'Nightlife',
    'nightclub': 'Nightlife',
    'cinema': 'Nightlife',
    'theatre': 'Nightlife',
    'casino': 'Nightlife',
    # Attractions
    'museum': 'Attractions',
    'gallery': 'Attractions',
    'attraction': 'Attractions',
    'viewpoint': 'Attractions',
    'artwork': 'Attractions',
    'zoo': 'Attractions',
    'aquarium': 'Attractions',
    'theme_park': 'Attractions',
    # Shopping
    'clothes': 'Shopping',
    'boutique': 'Shopping',
    'books': 'Shopping',
    'gift': 'Shopping',
    'art': 'Shopping',
    'jewelry': 'Shopping',
    'antiques': 'Shopping',
    'music': 'Shopping',
    'vintage': 'Shopping',
    'department_store': 'Shopping',
    'mall': 'Shopping',
    # Activities
    'park': 'Activities',
    'fitness_centre': 'Activities',
    'sports_centre': 'Activities',
    'swimming_pool': 'Activities',
    'bowling_alley': 'Activities',
    'garden': 'Activities',
    'nature_reserve': 'Activities',
    'playground': 'Activities',
    'stadium': 'Activities',
    # Community
    'library': 'Community',
    'community_centre': 'Community',
    'place_of_worship': 'Community',
    'arts_centre': 'Community',
    'social_facility': 'Community',
    'coworking_space': 'Community',
    # Stay
    'hotel': 'Stay',
    'hostel': 'Stay',
    'guest_house': 'Stay',
    'motel': 'Stay',
}

OVERPASS_URL = 'https://overpass-api.de/api/interpreter'


def build_overpass_query(bbox: tuple, venue_queries: List[str]) -> str:
    """Build an Overpass QL query for a city bounding box."""
    south, west, north, east = bbox
    bbox_str = f'{south},{west},{north},{east}'

    query_parts = []
    for vq in venue_queries:
        # Replace node with the bbox-constrained version
        query_parts.append(f'  {vq}({bbox_str});')

    query = f"""[out:json][timeout:120];
(
{chr(10).join(query_parts)}
);
out body;"""
    return query


def fetch_overpass(query: str, retries: int = 3) -> Optional[Dict]:
    """Send query to Overpass API with retry logic."""
    for attempt in range(retries):
        try:
            data = f'data={query}'.encode('utf-8')
            req = Request(
                OVERPASS_URL,
                data=data,
                headers={'Content-Type': 'application/x-www-form-urlencoded'},
            )
            with urlopen(req, timeout=180) as response:
                return json.loads(response.read().decode('utf-8'))
        except HTTPError as e:
            if e.code == 429:
                wait_time = 30 * (attempt + 1)
                print(f'  Rate limited (429). Waiting {wait_time}s before retry {attempt + 1}/{retries}...')
                time.sleep(wait_time)
            else:
                print(f'  HTTP error {e.code}: {e.reason}. Retry {attempt + 1}/{retries}...')
                time.sleep(10)
        except (URLError, TimeoutError) as e:
            print(f'  Network error: {e}. Retry {attempt + 1}/{retries}...')
            time.sleep(10)
    return None


def determine_category(tags: Dict[str, str]) -> str:
    """Determine AVRAI category from OSM tags."""
    for key in ['amenity', 'tourism', 'leisure', 'shop']:
        value = tags.get(key, '')
        if value in OSM_TO_AVRAI_CATEGORY:
            return OSM_TO_AVRAI_CATEGORY[value]
    return 'Other'


def extract_osm_tags(tags: Dict[str, str]) -> List[str]:
    """Extract relevant tags as a flat list for vibe inference."""
    relevant_keys = [
        'amenity', 'tourism', 'leisure', 'shop', 'cuisine', 'sport',
        'building', 'historic', 'heritage', 'brand', 'operator',
    ]
    extracted = []
    for key in relevant_keys:
        if key in tags:
            extracted.append(tags[key])
    # Add boolean tags
    for tag in ['outdoor_seating', 'takeaway', 'delivery', 'wheelchair',
                'internet_access', 'smoking', 'dog', 'live_music']:
        if tags.get(tag) in ('yes', 'true'):
            extracted.append(tag)
    return extracted


def parse_opening_hours(hours_str: Optional[str]) -> Optional[Dict]:
    """Parse OSM opening_hours into a simplified structure."""
    if not hours_str:
        return None
    result = {
        'raw': hours_str,
        'is_24h': '24/7' in hours_str,
        'has_late_hours': any(h in hours_str for h in ['22:', '23:', '00:', '01:', '02:', '03:']),
        'has_early_hours': any(h in hours_str for h in ['05:', '06:', '07:']),
    }
    return result


def process_osm_element(element: Dict, city_name: str) -> Optional[Dict]:
    """Convert an OSM element to an AVRAI spot record."""
    if element.get('type') != 'node':
        return None

    tags = element.get('tags', {})
    name = tags.get('name')

    if not name:
        return None

    lat = element.get('lat')
    lon = element.get('lon')
    if lat is None or lon is None:
        return None

    category = determine_category(tags)
    osm_tags = extract_osm_tags(tags)
    opening_hours = parse_opening_hours(tags.get('opening_hours'))

    # Detect if it's a chain (has brand or operator tag)
    is_chain = 'brand' in tags or 'brand:wikidata' in tags

    spot = {
        'osm_id': element.get('id'),
        'name': name,
        'latitude': lat,
        'longitude': lon,
        'category': category,
        'tags': osm_tags,
        'description': tags.get('description', ''),
        'city': city_name,
        # Enrichment fields (filled later by Google Places or defaults)
        'rating': None,
        'price_level': None,
        'review_count': None,
        # OSM-specific metadata useful for vibe inference
        'osm_metadata': {
            'cuisine': tags.get('cuisine'),
            'opening_hours': opening_hours,
            'is_chain': is_chain,
            'brand': tags.get('brand'),
            'wheelchair': tags.get('wheelchair'),
            'outdoor_seating': tags.get('outdoor_seating') == 'yes',
            'internet_access': tags.get('internet_access'),
            'amenity': tags.get('amenity'),
            'tourism': tags.get('tourism'),
            'leisure': tags.get('leisure'),
            'shop': tags.get('shop'),
            'sport': tags.get('sport'),
            'historic': tags.get('historic'),
            'addr_city': tags.get('addr:city'),
            'addr_street': tags.get('addr:street'),
        },
    }
    return spot


def extract_city(city_key: str, city_info: Dict, limit_per_city: Optional[int] = None) -> List[Dict]:
    """Extract spots for a single city."""
    city_name = city_info['name']
    bbox = city_info['bbox']

    print(f'\nExtracting spots for {city_name}...')
    query = build_overpass_query(bbox, VENUE_QUERIES)

    result = fetch_overpass(query)
    if result is None:
        print(f'  Failed to fetch data for {city_name}')
        return []

    elements = result.get('elements', [])
    print(f'  Received {len(elements)} raw elements')

    spots = []
    seen_names = set()
    for element in elements:
        spot = process_osm_element(element, city_name)
        if spot is None:
            continue
        # Deduplicate by name + approximate location
        dedup_key = f"{spot['name'].lower()}_{round(spot['latitude'], 3)}_{round(spot['longitude'], 3)}"
        if dedup_key in seen_names:
            continue
        seen_names.add(dedup_key)
        spots.append(spot)

    if limit_per_city and len(spots) > limit_per_city:
        spots = spots[:limit_per_city]

    # Category breakdown
    categories = {}
    for s in spots:
        cat = s['category']
        categories[cat] = categories.get(cat, 0) + 1

    print(f'  Extracted {len(spots)} unique spots')
    for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
        print(f'    {cat}: {count}')

    return spots


def main():
    parser = argparse.ArgumentParser(
        description='Extract real spot data from OpenStreetMap for AVRAI training',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/data_collection/extract_osm_spots.py
  python scripts/data_collection/extract_osm_spots.py --cities nyc la chicago miami austin
  python scripts/data_collection/extract_osm_spots.py --limit 5000 --output data/raw/osm_spots.json
""",
    )
    parser.add_argument(
        '--cities',
        nargs='+',
        default=list(CITY_BBOXES.keys()),
        choices=list(CITY_BBOXES.keys()),
        help=f'Cities to extract (default: all). Available: {", ".join(CITY_BBOXES.keys())}',
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/raw/osm_spots.json'),
        help='Output JSON path (default: data/raw/osm_spots.json)',
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=None,
        help='Max spots per city (default: no limit)',
    )
    parser.add_argument(
        '--delay',
        type=float,
        default=5.0,
        help='Delay in seconds between city queries (default: 5.0)',
    )

    args = parser.parse_args()

    all_spots = []
    for i, city_key in enumerate(args.cities):
        city_info = CITY_BBOXES[city_key]
        spots = extract_city(city_key, city_info, limit_per_city=args.limit)
        all_spots.extend(spots)

        # Delay between requests to be polite to Overpass API
        if i < len(args.cities) - 1:
            print(f'  Waiting {args.delay}s before next city...')
            time.sleep(args.delay)

    # Summary
    print(f'\n{"=" * 60}')
    print(f'Total spots extracted: {len(all_spots)}')
    city_counts = {}
    category_counts = {}
    for s in all_spots:
        city_counts[s['city']] = city_counts.get(s['city'], 0) + 1
        category_counts[s['category']] = category_counts.get(s['category'], 0) + 1

    print('\nBy city:')
    for city, count in sorted(city_counts.items(), key=lambda x: -x[1]):
        print(f'  {city}: {count}')
    print('\nBy category:')
    for cat, count in sorted(category_counts.items(), key=lambda x: -x[1]):
        print(f'  {cat}: {count}')

    # Save output
    output_data = {
        'metadata': {
            'source': 'OpenStreetMap Overpass API',
            'cities': args.cities,
            'total_spots': len(all_spots),
            'extraction_date': time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime()),
        },
        'spots': all_spots,
    }

    os.makedirs(args.output.parent, exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f'\nSaved to: {args.output}')
    print(f'File size: {os.path.getsize(args.output) / 1024 / 1024:.1f} MB')


if __name__ == '__main__':
    main()
