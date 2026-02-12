import 'package:equatable/equatable.dart';

/// Represents a user's mood state at a point in time.
///
/// Used for dynamic knot visualization and temporal overlays.
class MoodState extends Equatable {
  /// Type of mood.
  final MoodType type;

  /// Intensity of mood (0.0 to 1.0).
  final double intensity;

  /// Timestamp when mood was recorded.
  final DateTime timestamp;

  const MoodState({
    required this.type,
    required this.intensity,
    required this.timestamp,
  });

  factory MoodState.fromJson(Map<String, dynamic> json) {
    return MoodState(
      type: MoodType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MoodType.calm,
      ),
      intensity: (json['intensity'] ?? 0.5).toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'intensity': intensity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [type, intensity, timestamp];
}

/// Types of moods that can affect knot visualization.
enum MoodType {
  happy,
  calm,
  energetic,
  stressed,
  anxious,
  relaxed,
  excited,
  tired,
  focused,
  creative,
  social,
  introspective,
}

/// Represents a user's energy level at a point in time.
class EnergyLevel extends Equatable {
  /// Energy value (0.0 = low, 1.0 = high).
  final double value;

  /// Timestamp when energy was recorded.
  final DateTime timestamp;

  const EnergyLevel({
    required this.value,
    required this.timestamp,
  });

  factory EnergyLevel.fromJson(Map<String, dynamic> json) {
    return EnergyLevel(
      value: (json['value'] ?? 0.5).toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [value, timestamp];
}

/// Represents a user's stress level at a point in time.
class StressLevel extends Equatable {
  /// Stress value (0.0 = low, 1.0 = high).
  final double value;

  /// Timestamp when stress was recorded.
  final DateTime timestamp;

  const StressLevel({
    required this.value,
    required this.timestamp,
  });

  factory StressLevel.fromJson(Map<String, dynamic> json) {
    return StressLevel(
      value: (json['value'] ?? 0.0).toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object> get props => [value, timestamp];
}

