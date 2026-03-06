import 'package:spotify/spotify.dart';
import 'dart:developer' as developer;
import 'package:avrai_runtime_os/ai/personality_learning.dart';

/// Integrates the user's Spotify ecosystem into their AVRAI Quantum state.
/// Retrieves listening history/top tracks, gets their audio features
/// (valence, energy, danceability, acousticness), and translates those
/// signals into shifts on the user's 12D DNA profile.
class SpotifyEcosystemIntegrationService {
  static const String _logName = 'SpotifyEcosystemIntegrationService';

  // These should be configured securely via environment variables or backend
  // For the sake of this prototype/spike, we're using placeholders
  static const String _clientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String _redirectUri = 'avrai://spotify-auth-callback';

  final PersonalityLearning _personalityLearning;

  SpotifyEcosystemIntegrationService(this._personalityLearning);

  /// Initiates the OAuth flow
  Future<void> authenticate() async {
    // In a real app, you would use flutter_web_auth or url_launcher with a deep link
    // For this prototype, we'll simulate an auth flow
    developer.log('Initiating Spotify OAuth flow...', name: _logName);

    final uri = Uri.parse(
        'https://accounts.spotify.com/authorize?client_id=$_clientId&response_type=code&redirect_uri=$_redirectUri&scope=user-top-read');

    // Runtime layer does not launch URLs directly.
    developer.log(
      'Open this URL from app layer launcher: $uri',
      name: _logName,
    );
  }

  /// Processes the auth token (in reality, called via deep link callback)
  /// and runs the audio-feature ingestion pipeline.
  Future<void> ingestListeningHistory(String userId, String accessToken) async {
    developer.log('Ingesting Spotify listening history for user: $userId',
        name: _logName);

    try {
      final spotify = SpotifyApi.withAccessToken(accessToken);

      // Get top tracks
      final topTracks = await spotify.me.topTracks().getPage(10);

      if (topTracks.items == null || topTracks.items!.isEmpty) {
        developer.log('No top tracks found.', name: _logName);
        return;
      }

      // Get audio features for those tracks
      final trackIds =
          topTracks.items!.map((t) => t.id).whereType<String>().toList();
      final featuresList = <AudioFeature?>[];
      for (final trackId in trackIds) {
        featuresList.add(await spotify.audioFeatures.get(trackId));
      }

      // Average the features
      double avgValence = 0;
      double avgEnergy = 0;
      double avgDanceability = 0;
      double avgAcousticness = 0;
      int count = 0;

      for (final f in featuresList) {
        if (f != null) {
          avgValence += f.valence ?? 0.5;
          avgEnergy += f.energy ?? 0.5;
          avgDanceability += f.danceability ?? 0.5;
          avgAcousticness += f.acousticness ?? 0.5;
          count++;
        }
      }

      if (count > 0) {
        avgValence /= count;
        avgEnergy /= count;
        avgDanceability /= count;
        avgAcousticness /= count;
      }

      developer.log(
          'Aggregated Audio Features -> Valence: $avgValence, Energy: $avgEnergy, Dance: $avgDanceability, Acoustic: $avgAcousticness',
          name: _logName);

      // Map to AVRAI 12D shifts
      final dnaShifts = _mapAudioFeaturesToDNA(
        valence: avgValence,
        energy: avgEnergy,
        danceability: avgDanceability,
        acousticness: avgAcousticness,
      );

      developer.log('Mapped DNA Shifts: $dnaShifts', name: _logName);

      // Apply the shifts to the user's personality
      final profile = await _personalityLearning.getCurrentPersonality(userId);
      if (profile != null) {
        final updatedDims = Map<String, double>.from(profile.dimensions);
        dnaShifts.forEach((dim, shift) {
          if (updatedDims.containsKey(dim)) {
            updatedDims[dim] = (updatedDims[dim]! + shift).clamp(0.0, 1.0);
          }
        });

        await _personalityLearning.updatePersonality(userId, updatedDims,
            isAccelerated: true);
        developer.log(
            'Successfully infused Spotify DNA into user profile. Learning accelerated to Day 1.',
            name: _logName);
      }
    } catch (e) {
      developer.log('Error ingesting Spotify data: $e', name: _logName);
    }
  }

  /// Translates raw Spotify audio features into AVRAI 12D latent space shifts
  Map<String, double> _mapAudioFeaturesToDNA({
    required double valence, // Positivity/Happiness
    required double energy, // Intensity/Activity
    required double danceability, // Groove/Rhythm
    required double acousticness, // Organic/Unplugged
  }) {
    final shifts = <String, double>{};

    // Scale features from [0.0, 1.0] center to [-0.1, 0.1] shift range
    // meaning a completely neutral feature (0.5) applies 0 shift.

    double normalize(double val) => (val - 0.5) * 0.2;

    // High energy -> higher energy_preference, higher temporal_flexibility (more spontaneous)
    shifts['energy_preference'] = normalize(energy);
    shifts['temporal_flexibility'] = normalize(energy) * 0.5;

    // High valence (happy) -> higher community_orientation
    // Low valence (sad/grungy) -> higher authenticity_preference
    shifts['community_orientation'] = normalize(valence);
    shifts['authenticity_preference'] = -normalize(valence) * 0.8;

    // High danceability -> social discovery, crowds
    shifts['social_discovery_style'] = normalize(danceability);
    shifts['crowd_tolerance'] = normalize(danceability);

    // High acousticness -> chill, curated, authentic
    shifts['curation_tendency'] = normalize(acousticness);
    if (acousticness > 0.6) {
      shifts['energy_preference'] = (shifts['energy_preference'] ?? 0) - 0.1;
    }

    return shifts;
  }
}
