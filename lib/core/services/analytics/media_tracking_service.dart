import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:nowplaying/nowplaying.dart';
import 'package:nowplaying/nowplaying_track.dart';

/// Service for tracking currently playing music/media for AI learning
///
/// Collects media data for the AI to learn:
/// - Music preferences (genres, artists, moods)
/// - Listening patterns (time of day, activity context)
/// - Vibe preferences (energetic, calm, focused)
///
/// Platform limitations:
/// - iOS: Only Apple Music/iTunes and Spotify (with auth)
/// - Android: Any app via NotificationListenerService
///
/// All data is processed locally on-device per avrai privacy philosophy.
class MediaTrackingService {
  static const String _logName = 'MediaTrackingService';

  bool _isInitialized = false;
  bool _hasPermission = false;
  StreamSubscription<NowPlayingTrack>? _trackSubscription;

  // Track history for pattern analysis (last 50 tracks)
  final List<Map<String, dynamic>> _trackHistory = [];
  static const int _maxHistorySize = 50;

  // Current track cache
  NowPlayingTrack? _currentTrack;
  DateTime? _currentTrackStartTime;

  MediaTrackingService();

  /// Initialize the media tracking service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if platform is supported
      if (!Platform.isAndroid && !Platform.isIOS) {
        developer.log(
          'MediaTrackingService not supported on this platform',
          name: _logName,
        );
        _isInitialized = true;
        _hasPermission = false;
        return;
      }

      // Start the NowPlaying service
      await NowPlaying.instance.start();

      // Check for permission (mainly for Android NotificationListenerService)
      _hasPermission = await NowPlaying.instance.isEnabled();

      if (!_hasPermission) {
        developer.log(
          'Media notification access not granted',
          name: _logName,
        );
      }

      // Subscribe to track changes
      _trackSubscription = NowPlaying.instance.stream.listen(
        _onTrackChanged,
        onError: (e) {
          developer.log('Error in media stream: $e', name: _logName);
        },
      );

      _isInitialized = true;

      developer.log(
        'MediaTrackingService initialized. Permission: $_hasPermission',
        name: _logName,
      );
    } catch (e, st) {
      developer.log(
        'Error initializing MediaTrackingService',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      _isInitialized = true;
      _hasPermission = false;
    }
  }

  /// Check if media tracking is available
  bool get isAvailable => _isInitialized && _hasPermission;

  /// Handle track changes
  void _onTrackChanged(NowPlayingTrack track) {
    // Save previous track to history if it was playing
    if (_currentTrack != null && _currentTrackStartTime != null) {
      final duration = DateTime.now().difference(_currentTrackStartTime!);
      if (duration.inSeconds > 10) {
        // Only save if played for >10 seconds
        _addToHistory(_currentTrack!, duration);
      }
    }

    // Update current track
    _currentTrack = track;
    _currentTrackStartTime = DateTime.now();

    developer.log(
      'Now playing: ${track.title} by ${track.artist}',
      name: _logName,
    );
  }

  /// Add a track to history
  void _addToHistory(NowPlayingTrack track, Duration duration) {
    final trackData = {
      'title': track.title,
      'artist': track.artist,
      'album': track.album,
      'source': track.source,
      'duration_seconds': duration.inSeconds,
      'timestamp': DateTime.now().toIso8601String(),
      'hour_of_day': DateTime.now().hour,
      'day_of_week': DateTime.now().weekday,
      'inferred_genre': _inferGenreFromMetadata(track),
      'inferred_mood': _inferMoodFromMetadata(track),
    };

    _trackHistory.insert(0, trackData);

    // Trim history if too large
    while (_trackHistory.length > _maxHistorySize) {
      _trackHistory.removeLast();
    }
  }

  /// Collect media data for AI learning
  Future<Map<String, dynamic>> collectMediaData() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_hasPermission) {
      return {'has_data': false};
    }

    try {
      // Get current track if playing
      final currentTrackData = _getCurrentTrackData();

      // Analyze listening patterns
      final patterns = _analyzeListeningPatterns();

      return {
        'has_data': true,
        'current_track': currentTrackData,
        'is_playing': _currentTrack?.state == NowPlayingState.playing,
        'track_history_count': _trackHistory.length,
        'patterns': patterns,
        'learning_signals': _deriveLearningSignals(currentTrackData, patterns),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e, st) {
      developer.log(
        'Error collecting media data',
        error: e,
        stackTrace: st,
        name: _logName,
      );
      return {'has_data': false};
    }
  }

  /// Get current track data
  Map<String, dynamic>? _getCurrentTrackData() {
    if (_currentTrack == null) return null;

    final track = _currentTrack!;
    return {
      'title': track.title,
      'artist': track.artist,
      'album': track.album,
      'source': track.source,
      'is_playing': track.state == NowPlayingState.playing,
      'inferred_genre': _inferGenreFromMetadata(track),
      'inferred_mood': _inferMoodFromMetadata(track),
    };
  }

  /// Analyze listening patterns from history
  Map<String, dynamic> _analyzeListeningPatterns() {
    if (_trackHistory.isEmpty) {
      return {'has_patterns': false};
    }

    // Genre distribution
    final genreDistribution = <String, int>{};
    final moodDistribution = <String, int>{};
    final hourDistribution = <int, int>{};
    final artistCounts = <String, int>{};
    int totalDuration = 0;

    for (final track in _trackHistory) {
      final genre = track['inferred_genre'] as String?;
      if (genre != null) {
        genreDistribution[genre] = (genreDistribution[genre] ?? 0) + 1;
      }

      final mood = track['inferred_mood'] as String?;
      if (mood != null) {
        moodDistribution[mood] = (moodDistribution[mood] ?? 0) + 1;
      }

      final hour = track['hour_of_day'] as int?;
      if (hour != null) {
        hourDistribution[hour] = (hourDistribution[hour] ?? 0) + 1;
      }

      final artist = track['artist'] as String?;
      if (artist != null && artist.isNotEmpty) {
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }

      totalDuration += (track['duration_seconds'] as int?) ?? 0;
    }

    // Find top genre
    String? topGenre;
    int maxGenreCount = 0;
    for (final entry in genreDistribution.entries) {
      if (entry.value > maxGenreCount) {
        maxGenreCount = entry.value;
        topGenre = entry.key;
      }
    }

    // Find top mood
    String? topMood;
    int maxMoodCount = 0;
    for (final entry in moodDistribution.entries) {
      if (entry.value > maxMoodCount) {
        maxMoodCount = entry.value;
        topMood = entry.key;
      }
    }

    // Find top artists
    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists.take(5).map((e) => e.key).toList();

    // Find peak listening hours
    final sortedHours = hourDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = sortedHours.take(3).map((e) => e.key).toList();

    return {
      'has_patterns': true,
      'genre_distribution': genreDistribution,
      'mood_distribution': moodDistribution,
      'top_genre': topGenre,
      'top_mood': topMood,
      'top_artists': topArtists,
      'peak_listening_hours': peakHours,
      'total_listening_minutes': totalDuration ~/ 60,
      'tracks_analyzed': _trackHistory.length,
    };
  }

  /// Derive learning signals from media data
  Map<String, dynamic> _deriveLearningSignals(
    Map<String, dynamic>? currentTrack,
    Map<String, dynamic> patterns,
  ) {
    final currentMood = currentTrack?['inferred_mood'] as String?;
    final currentGenre = currentTrack?['inferred_genre'] as String?;
    final topMood = patterns['top_mood'] as String?;
    final topGenre = patterns['top_genre'] as String?;

    return {
      // Current state signals
      'current_listening_mood': currentMood,
      'current_genre': currentGenre,
      'is_listening_now': currentTrack != null,

      // Vibe matching signals
      'prefers_energetic_spots': topMood == 'energetic' || topMood == 'upbeat',
      'prefers_calm_spots': topMood == 'calm' || topMood == 'chill',
      'prefers_focused_spots': topMood == 'focus' || topMood == 'ambient',

      // Genre-based venue suggestions
      'suggest_jazz_venue': topGenre == 'jazz' || currentGenre == 'jazz',
      'suggest_rock_venue': topGenre == 'rock' || currentGenre == 'rock',
      'suggest_electronic_venue': topGenre == 'electronic' ||
          topGenre == 'edm' ||
          currentGenre == 'electronic',
      'suggest_hiphop_venue': topGenre == 'hiphop' || currentGenre == 'hiphop',
      'suggest_indie_venue': topGenre == 'indie' || currentGenre == 'indie',

      // Mood-based venue suggestions
      'match_venue_to_music_mood': currentMood != null,
      'current_vibe': currentMood ?? topMood ?? 'neutral',
    };
  }

  /// Infer genre from track metadata
  ///
  /// Uses title, artist, and album keywords to guess genre.
  /// This is a heuristic approach since full genre data isn't always available.
  String _inferGenreFromMetadata(NowPlayingTrack track) {
    final title = (track.title ?? '').toLowerCase();
    final artist = (track.artist ?? '').toLowerCase();
    final album = (track.album ?? '').toLowerCase();
    final combined = '$title $artist $album';

    // Genre keyword matching (simple heuristic)
    if (_containsAny(combined, ['jazz', 'bebop', 'swing', 'blues'])) {
      return 'jazz';
    }
    if (_containsAny(combined, ['rock', 'metal', 'punk', 'grunge'])) {
      return 'rock';
    }
    if (_containsAny(combined, ['electronic', 'edm', 'techno', 'house', 'trance', 'dubstep'])) {
      return 'electronic';
    }
    if (_containsAny(combined, ['hip hop', 'hiphop', 'rap', 'trap'])) {
      return 'hiphop';
    }
    if (_containsAny(combined, ['indie', 'alternative', 'folk'])) {
      return 'indie';
    }
    if (_containsAny(combined, ['classical', 'orchestra', 'symphony', 'piano sonata'])) {
      return 'classical';
    }
    if (_containsAny(combined, ['country', 'western', 'bluegrass'])) {
      return 'country';
    }
    if (_containsAny(combined, ['r&b', 'rnb', 'soul', 'funk'])) {
      return 'rnb';
    }
    if (_containsAny(combined, ['pop', 'dance'])) {
      return 'pop';
    }
    if (_containsAny(combined, ['podcast', 'episode', 'show'])) {
      return 'podcast';
    }
    if (_containsAny(combined, ['ambient', 'meditation', 'relax', 'sleep'])) {
      return 'ambient';
    }

    return 'unknown';
  }

  /// Infer mood from track metadata
  String _inferMoodFromMetadata(NowPlayingTrack track) {
    final title = (track.title ?? '').toLowerCase();
    final album = (track.album ?? '').toLowerCase();
    final combined = '$title $album';

    // Mood keyword matching
    if (_containsAny(combined, ['chill', 'relax', 'calm', 'peaceful', 'serene', 'quiet'])) {
      return 'calm';
    }
    if (_containsAny(combined, ['party', 'dance', 'club', 'energy', 'pump', 'workout'])) {
      return 'energetic';
    }
    if (_containsAny(combined, ['focus', 'study', 'concentrate', 'work', 'productive'])) {
      return 'focus';
    }
    if (_containsAny(combined, ['happy', 'joy', 'fun', 'upbeat', 'positive'])) {
      return 'upbeat';
    }
    if (_containsAny(combined, ['sad', 'melancholy', 'heartbreak', 'emotional'])) {
      return 'melancholy';
    }
    if (_containsAny(combined, ['sleep', 'ambient', 'meditation', 'zen'])) {
      return 'ambient';
    }
    if (_containsAny(combined, ['acoustic', 'unplugged', 'live'])) {
      return 'intimate';
    }

    // Default to neutral
    return 'neutral';
  }

  /// Check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  /// Get the current track if playing
  NowPlayingTrack? get currentTrack => _currentTrack;

  /// Get recent track history
  List<Map<String, dynamic>> get trackHistory => List.unmodifiable(_trackHistory);

  /// Clean up resources
  void dispose() {
    _trackSubscription?.cancel();
  }
}
