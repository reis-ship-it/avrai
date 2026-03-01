#!/usr/bin/env python3
"""
Google Places Enrichment for AVRAI Training Data
Phase: ML Reality and Quantum Readiness - Phase 1.2

Enriches a subset of OSM spots with Google Places data:
rating, price_level, review count, types.

Requires a Google Places API key set via GOOGLE_PLACES_API_KEY env var.
Cost: ~$17 per 1,000 requests (Place Details).

Usage:
    export GOOGLE_PLACES_API_KEY=your_key
    python scripts/data_collection/enrich_with_google_places.py
    python scripts/data_collection/enrich_with_google_places.py --limit 5000
"""

import argparse
import json
import math
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from urllib.parse import quote_plus


PLACES_SEARCH_URL = 'https://maps.googleapis.com/maps/api/place/findplacefromtext/json'
PLACES_DETAILS_URL = 'https://maps.googleapis.com/maps/api/place/details/json'
NEW_PLACES_URL = 'https://places.googleapis.com/v1/places:searchText'


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points in km."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def find_place(name: str, lat: float, lon: float, api_key: str) -> Optional[str]:
    """Find a Google Place ID by name and location using Find Place API."""
    location_bias = f'point:{lat},{lon}'
    encoded_name = quote_plus(name)
    url = (
        f'{PLACES_SEARCH_URL}'
        f'?input={encoded_name}'
        f'&inputtype=textquery'
        f'&locationbias={location_bias}'
        f'&fields=place_id,name,geometry'
        f'&key={api_key}'
    )

    try:
        with urlopen(url, timeout=15) as response:
            data = json.loads(response.read().decode('utf-8'))
    except (URLError, HTTPError, TimeoutError):
        return None

    candidates = data.get('candidates', [])
    if not candidates:
        return None

    # Check if the first result is reasonably close (within 1km)
    candidate = candidates[0]
    geo = candidate.get('geometry', {}).get('location', {})
    if geo:
        dist = haversine_distance(lat, lon, geo.get('lat', 0), geo.get('lng', 0))
        if dist > 1.0:
            return None

    return candidate.get('place_id')


def get_place_details(place_id: str, api_key: str) -> Optional[Dict]:
    """Fetch details for a Google Place ID."""
    fields = 'name,rating,user_ratings_total,price_level,types,opening_hours'
    url = (
        f'{PLACES_DETAILS_URL}'
        f'?place_id={place_id}'
        f'&fields={fields}'
        f'&key={api_key}'
    )

    try:
        with urlopen(url, timeout=15) as response:
            data = json.loads(response.read().decode('utf-8'))
    except (URLError, HTTPError, TimeoutError):
        return None

    if data.get('status') != 'OK':
        return None

    result = data.get('result', {})
    return {
        'google_place_id': place_id,
        'google_name': result.get('name'),
        'rating': result.get('rating'),
        'review_count': result.get('user_ratings_total'),
        'price_level': result.get('price_level'),
        'google_types': result.get('types', []),
        'has_opening_hours': 'opening_hours' in result,
    }


def enrich_spots(
    spots: List[Dict],
    api_key: str,
    limit: int = 5000,
    delay: float = 0.1,
    checkpoint_every: int = 100,
    checkpoint_path: Optional[Path] = None,
) -> List[Dict]:
    """Enrich a list of OSM spots with Google Places data."""
    enriched = []
    skipped = 0
    failed = 0

    # Load checkpoint if exists
    start_index = 0
    if checkpoint_path and checkpoint_path.exists():
        with open(checkpoint_path, 'r') as f:
            checkpoint = json.load(f)
        enriched = checkpoint.get('enriched', [])
        start_index = checkpoint.get('next_index', 0)
        print(f'Resuming from checkpoint at index {start_index} ({len(enriched)} already enriched)')

    spots_to_process = spots[start_index:start_index + limit - len(enriched)]
    total = len(spots_to_process)

    for i, spot in enumerate(spots_to_process):
        idx = start_index + i
        if len(enriched) >= limit:
            break

        name = spot.get('name', '')
        lat = spot.get('latitude', 0)
        lon = spot.get('longitude', 0)

        if not name or lat == 0 or lon == 0:
            skipped += 1
            continue

        # Find place ID
        place_id = find_place(name, lat, lon, api_key)
        if not place_id:
            # Still include the spot, just without Google enrichment
            spot['google_enrichment'] = None
            enriched.append(spot)
            skipped += 1
            if (i + 1) % 50 == 0:
                print(f'  [{i + 1}/{total}] No match for "{name}" (skipped: {skipped})')
            time.sleep(delay)
            continue

        # Get details
        details = get_place_details(place_id, api_key)
        if details:
            spot['rating'] = details.get('rating')
            spot['review_count'] = details.get('review_count')
            spot['price_level'] = details.get('price_level')
            spot['google_enrichment'] = details
            enriched.append(spot)
        else:
            spot['google_enrichment'] = None
            enriched.append(spot)
            failed += 1

        if (i + 1) % 10 == 0:
            print(f'  [{i + 1}/{total}] Enriched: {len([s for s in enriched if s.get("google_enrichment")])} | '
                  f'No match: {skipped} | Failed: {failed}')

        # Save checkpoint periodically
        if checkpoint_path and (i + 1) % checkpoint_every == 0:
            with open(checkpoint_path, 'w') as f:
                json.dump({'enriched': enriched, 'next_index': idx + 1}, f)

        time.sleep(delay)

    return enriched


def main():
    parser = argparse.ArgumentParser(
        description='Enrich OSM spots with Google Places data for AVRAI training',
    )
    parser.add_argument(
        '--input',
        type=Path,
        default=Path('data/raw/osm_spots.json'),
        help='Input OSM spots JSON (default: data/raw/osm_spots.json)',
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('data/raw/google_enriched_spots.json'),
        help='Output enriched JSON (default: data/raw/google_enriched_spots.json)',
    )
    parser.add_argument(
        '--limit',
        type=int,
        default=5000,
        help='Max number of spots to enrich (default: 5000)',
    )
    parser.add_argument(
        '--delay',
        type=float,
        default=0.1,
        help='Delay between API calls in seconds (default: 0.1)',
    )
    parser.add_argument(
        '--api-key',
        type=str,
        default=None,
        help='Google Places API key (default: GOOGLE_PLACES_API_KEY env var)',
    )

    args = parser.parse_args()

    api_key = args.api_key or os.environ.get('GOOGLE_PLACES_API_KEY')
    if not api_key:
        print('Error: Google Places API key required.')
        print('Set GOOGLE_PLACES_API_KEY env var or use --api-key flag.')
        sys.exit(1)

    if not args.input.exists():
        print(f'Error: Input file not found: {args.input}')
        print('Run extract_osm_spots.py first to generate OSM data.')
        sys.exit(1)

    # Load OSM spots
    print(f'Loading spots from {args.input}...')
    with open(args.input, 'r', encoding='utf-8') as f:
        data = json.load(f)

    spots = data.get('spots', [])
    print(f'Loaded {len(spots)} spots')

    # Prioritize spots with descriptions and diverse categories
    # Shuffle to get a good mix of cities and categories
    import random
    random.seed(42)
    random.shuffle(spots)

    # Enrich
    checkpoint_path = args.output.parent / '.enrichment_checkpoint.json'
    print(f'\nEnriching up to {args.limit} spots with Google Places data...')
    print(f'Estimated cost: ~${args.limit * 0.017:.2f} (Find Place + Details)')

    enriched = enrich_spots(
        spots,
        api_key,
        limit=args.limit,
        delay=args.delay,
        checkpoint_path=checkpoint_path,
    )

    # Statistics
    with_rating = sum(1 for s in enriched if s.get('rating') is not None)
    with_price = sum(1 for s in enriched if s.get('price_level') is not None)
    with_reviews = sum(1 for s in enriched if s.get('review_count') is not None)

    print(f'\nEnrichment complete:')
    print(f'  Total spots: {len(enriched)}')
    print(f'  With rating: {with_rating} ({with_rating / max(len(enriched), 1) * 100:.1f}%)')
    print(f'  With price level: {with_price} ({with_price / max(len(enriched), 1) * 100:.1f}%)')
    print(f'  With review count: {with_reviews} ({with_reviews / max(len(enriched), 1) * 100:.1f}%)')

    # Save output
    output_data = {
        'metadata': {
            'source': 'OpenStreetMap + Google Places API',
            'total_spots': len(enriched),
            'enrichment_date': time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime()),
            'with_rating': with_rating,
            'with_price_level': with_price,
            'with_review_count': with_reviews,
        },
        'spots': enriched,
    }

    os.makedirs(args.output.parent, exist_ok=True)
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, indent=2, ensure_ascii=False)

    print(f'\nSaved to: {args.output}')

    # Clean up checkpoint
    if checkpoint_path.exists():
        os.remove(checkpoint_path)


if __name__ == '__main__':
    main()
