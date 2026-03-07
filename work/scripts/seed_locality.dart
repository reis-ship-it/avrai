import 'dart:io';
import 'dart:convert';

/// Locality Agent Seeding Script (v0.4.1 Polish)
///
/// This script demonstrates how AVRAI achieves "Zero User Reliability" and
/// instant expansion to new cities (e.g., Birmingham, AL).
/// Instead of requiring users to manually label places or training a monolithic
/// model on Birmingham, we just dump OpenStreetMap/Event data into this script.
///
/// It runs the raw POIs through the TupleExtractionEngine (Air Gap) to extract
/// baseline "Vibe Vectors", and saves a pre-seeded LocalityAgent state.

void main(List<String> args) {
  print('=============================================');
  print('AVRAI Locality Agent Seeder');
  print('=============================================');

  String targetCity = args.isNotEmpty ? args.first : 'Birmingham, AL';

  print('Target City: $targetCity');
  print(
      'Step 1: Mock fetching OpenStreetMap (OSM) POI dump for bounding box...');

  // Simulated OSM Data
  final rawOSMData = [
    {
      'name': 'Saturn Birmingham',
      'type': 'music_venue',
      'tags': ['indie', 'coffee', 'games', 'bars']
    },
    {
      'name': 'Good Dog Cafe',
      'type': 'cafe',
      'tags': ['dog_friendly', 'chill', 'studying']
    },
    {
      'name': 'Railroad Park',
      'type': 'park',
      'tags': ['outdoor', 'fitness', 'events', 'community']
    },
    {
      'name': 'Atomic Lounge',
      'type': 'bar',
      'tags': ['cocktails', 'vintage', 'costumes']
    },
  ];

  print('  -> Retrieved ${rawOSMData.length} POIs.');

  print(
      '\nStep 2: Pushing raw POIs through TupleExtractionEngine (Air Gap)...');

  // The Air Gap converts literal tags into 12D Vibe Vectors
  final seededSpots = <Map<String, dynamic>>[];

  for (final poi in rawOSMData) {
    print('  -> Processing: ${poi['name']}');

    // Simple mock of 12D mapping
    final Map<String, double> vibeVector = {
      'energy_preference':
          poi['tags'].contains('indie') || poi['tags'].contains('cocktails')
              ? 0.8
              : 0.4,
      'community_orientation':
          poi['tags'].contains('community') || poi['tags'].contains('bars')
              ? 0.9
              : 0.5,
      'authenticity_preference':
          poi['tags'].contains('vintage') || poi['tags'].contains('indie')
              ? 0.9
              : 0.6,
      'crowd_tolerance': poi['tags'].contains('music_venue') ? 0.8 : 0.4,
    };

    seededSpots.add({
      'id': 'spot_${poi['name'].toString().replaceAll(' ', '_').toLowerCase()}',
      'name': poi['name'],
      'baselineVibe': vibeVector,
      'confidence':
          0.3, // Initial confidence is low until real humans visit and validate
    });
  }

  print('\nStep 3: Generating LocalityAgentGlobalState file...');

  final globalState = {
    'locality_id': targetCity.toLowerCase().replaceAll(', ', '_'),
    'last_updated': DateTime.now().toIso8601String(),
    'seeded_spots': seededSpots,
    'federated_routes': [], // Empty until users generate routes
    'latent_communities': [],
  };

  final outputDir = Directory('work/docs/experiments/data/locality_seeds');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile =
      File('${outputDir.path}/${globalState['locality_id']}_seed.json');
  outputFile.writeAsStringSync(jsonEncode(globalState));

  print('  -> Seed file written to: ${outputFile.path}');
  print('\nLocality Agent for $targetCity successfully pre-seeded!');
  print('=============================================');
}
