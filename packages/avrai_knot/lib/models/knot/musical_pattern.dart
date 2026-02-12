// Musical Pattern Model
// 
// Represents a musical pattern generated from knot topology
// Part of Patent #31: Topological Knot Theory for Personality Representation
// Phase 7: Audio & Privacy

/// Musical note representation
class MusicalNote {
  /// Frequency in Hz
  final double frequency;
  
  /// Duration in seconds
  final double duration;
  
  /// Volume (0.0 to 1.0)
  final double volume;

  const MusicalNote({
    required this.frequency,
    required this.duration,
    this.volume = 0.7,
  });
}

/// Musical pattern generated from knot
class MusicalPattern {
  /// Sequence of notes
  final List<MusicalNote> notes;
  
  /// Rhythm pattern (beats per minute)
  final double rhythm;
  
  /// Harmony (chord progression)
  final List<double> harmony;
  
  /// Total duration in seconds
  final double duration;
  
  /// Whether to loop
  final bool loop;

  const MusicalPattern({
    required this.notes,
    required this.rhythm,
    required this.harmony,
    required this.duration,
    this.loop = false,
  });
}

/// Audio sequence for playback
class AudioSequence {
  /// Sequence of notes
  final List<MusicalNote> notes;
  
  /// Rhythm (beats per minute)
  final double rhythm;
  
  /// Harmony (chord progression)
  final List<double> harmony;
  
  /// Total duration in seconds
  final double duration;
  
  /// Whether to loop
  final bool loop;

  const AudioSequence({
    required this.notes,
    required this.rhythm,
    required this.harmony,
    required this.duration,
    this.loop = false,
  });
}
