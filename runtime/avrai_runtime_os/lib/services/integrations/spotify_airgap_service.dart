import 'dart:convert';
import 'dart:developer' as developer;
import 'package:avrai_core/contracts/air_gap_contract.dart';
import 'package:avrai_core/schemas/semantic_tuple.dart';
import 'package:reality_engine/memory/air_gap/tuple_extraction_engine.dart';
import 'package:reality_engine/memory/semantic_knowledge_store.dart';

/// Raw radioactive payload containing a user's Spotify listening history.
/// This includes sensitive track names, timestamps, and audio features.
/// Must never be persisted to permanent storage.
class RawSpotifyPayload extends RawDataPayload {
  final Map<String, dynamic> _spotifyData;

  const RawSpotifyPayload({
    required super.capturedAt,
    required Map<String, dynamic> spotifyData,
  })  : _spotifyData = spotifyData,
        super(sourceId: 'spotify_integration');

  @override
  String get rawContent => jsonEncode(_spotifyData);
}

/// SpotifyAirgapIntegrationService
///
/// Blueprint for how all 3rd-party App integrations (Social Media, Music, Health)
/// should interact with the AVRAI ecosystem.
///
/// 1. Connects to the external service (Spotify).
/// 2. Fetches raw, highly personal user data (listening history).
/// 3. Wraps the data in a [RawDataPayload].
/// 4. Slams it through the [AirGapContract] (TupleExtractionEngine).
/// 5. Saves the resulting pure mathematical [SemanticTuple]s to the Knowledge Store.
/// 6. The original raw data is destroyed.
class SpotifyAirgapIntegrationService {
  static const String _logName = 'SpotifyAirgapIntegrationService';

  final TupleExtractionEngine _airGapEngine;
  final SemanticKnowledgeStore _knowledgeStore;

  SpotifyAirgapIntegrationService({
    required TupleExtractionEngine airGapEngine,
    required SemanticKnowledgeStore knowledgeStore,
  })  : _airGapEngine = airGapEngine,
        _knowledgeStore = knowledgeStore;

  /// Triggered by the user connecting their Spotify account or via a background job.
  Future<void> syncRecentListeningHistory(String userId) async {
    developer.log('Starting Spotify sync for user $userId', name: _logName);

    try {
      // 1. Fetch raw data from Spotify (Simulated OAuth and API call)
      final rawData = await _fetchSimulatedSpotifyData();

      // 2. Wrap in radioactive payload
      final payload = RawSpotifyPayload(
        capturedAt: DateTime.now(),
        spotifyData: rawData,
      );

      // 3. Pass through the Air Gap to extract abstract topological meaning
      developer.log('Sending raw Spotify data through the Air Gap...',
          name: _logName);
      final semanticTuples = await _airGapEngine.scrubAndExtract(payload);

      // 4. Save the pure mathematical abstract concepts to the local knowledge store.
      // At this point, "Nirvana" or "Smells Like Teen Spirit" is gone.
      // All that remains is `[Subject: User] -> [Predicate: exhibits_trait] -> [Object: High Grunge/Rebellion Topology]`
      developer.log(
          'Extraction complete. Saving ${semanticTuples.length} semantic tuples.',
          name: _logName);
      await _knowledgeStore.saveTuples(semanticTuples);

      developer.log('Spotify sync and Air Gap digestion successful.',
          name: _logName);
    } catch (e, st) {
      developer.log('Failed to sync Spotify data: $e',
          name: _logName, error: e, stackTrace: st);
    }
  }

  /// Simulates fetching data from the Spotify Web API.
  Future<Map<String, dynamic>> _fetchSimulatedSpotifyData() async {
    // In reality, this would use an access token to call api.spotify.com/v1/me/player/recently-played
    // and then fetch audio features for those tracks.
    await Future.delayed(
        const Duration(seconds: 1)); // Simulate network latency

    return {
      'recently_played': [
        {
          'track': 'Smells Like Teen Spirit',
          'artist': 'Nirvana',
          'audio_features': {
            'danceability': 0.502,
            'energy': 0.912,
            'valence':
                0.85, // Translated internally to grunge/rebellion or counter-culture
            'acousticness': 0.0,
            'instrumentalness': 0.0,
          },
          'played_at': DateTime.now()
              .subtract(const Duration(minutes: 30))
              .toIso8601String(),
        },
        {
          'track': 'Come As You Are',
          'artist': 'Nirvana',
          'audio_features': {
            'danceability': 0.5,
            'energy': 0.82,
            'valence': 0.54,
            'acousticness': 0.0,
            'instrumentalness': 0.0,
          },
          'played_at': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        }
      ]
    };
  }
}
