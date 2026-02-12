import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/mood_state.dart';

/// Represents a personality knot with dynamic properties based on mood/energy/stress
/// Phase 4: Dynamic Knots (Mood/Energy)
class DynamicKnot {
  /// Base personality knot (topological structure)
  final PersonalityKnot baseKnot;
  
  /// Color scheme based on mood
  final Map<String, Color> colorScheme;
  
  /// Animation speed based on energy (0.0 = slow, 1.0 = fast)
  final double animationSpeed;
  
  /// Pulse rate based on stress (0.0 = slow, 1.0 = fast)
  final double pulseRate;
  
  /// Complexity modifier (applied to base knot complexity)
  final double complexityModifier;
  
  /// Current mood state
  final MoodState? mood;
  
  /// Current energy level
  final EnergyLevel? energy;
  
  /// Current stress level
  final StressLevel? stress;
  
  /// Timestamp when dynamic properties were last updated
  final DateTime lastUpdated;
  
  const DynamicKnot({
    required this.baseKnot,
    required this.colorScheme,
    required this.animationSpeed,
    required this.pulseRate,
    required this.complexityModifier,
    this.mood,
    this.energy,
    this.stress,
    required this.lastUpdated,
  });
  
  /// Create from JSON
  factory DynamicKnot.fromJson(Map<String, dynamic> json) {
    final colorSchemeJson = json['colorScheme'] as Map<String, dynamic>? ?? {};
    final colorScheme = <String, Color>{};
    for (final entry in colorSchemeJson.entries) {
      final colorValue = entry.value as int? ?? 0;
      colorScheme[entry.key] = Color(colorValue);
    }
    
    return DynamicKnot(
      baseKnot: PersonalityKnot.fromJson(json['baseKnot'] ?? {}),
      colorScheme: colorScheme,
      animationSpeed: (json['animationSpeed'] ?? 0.5).toDouble(),
      pulseRate: (json['pulseRate'] ?? 0.5).toDouble(),
      complexityModifier: (json['complexityModifier'] ?? 1.0).toDouble(),
      mood: json['mood'] != null ? MoodState.fromJson(json['mood']) : null,
      energy: json['energy'] != null ? EnergyLevel.fromJson(json['energy']) : null,
      stress: json['stress'] != null ? StressLevel.fromJson(json['stress']) : null,
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final colorSchemeJson = <String, int>{};
    for (final entry in colorScheme.entries) {
      colorSchemeJson[entry.key] = entry.value.toARGB32();
    }
    
    return {
      'baseKnot': baseKnot.toJson(),
      'colorScheme': colorSchemeJson,
      'animationSpeed': animationSpeed,
      'pulseRate': pulseRate,
      'complexityModifier': complexityModifier,
      'mood': mood?.toJson(),
      'energy': energy?.toJson(),
      'stress': stress?.toJson(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
  
  /// Create copy with updated fields
  DynamicKnot copyWith({
    PersonalityKnot? baseKnot,
    Map<String, Color>? colorScheme,
    double? animationSpeed,
    double? pulseRate,
    double? complexityModifier,
    MoodState? mood,
    EnergyLevel? energy,
    StressLevel? stress,
    DateTime? lastUpdated,
  }) {
    return DynamicKnot(
      baseKnot: baseKnot ?? this.baseKnot,
      colorScheme: colorScheme ?? this.colorScheme,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      pulseRate: pulseRate ?? this.pulseRate,
      complexityModifier: complexityModifier ?? this.complexityModifier,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      stress: stress ?? this.stress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  String toString() {
    return 'DynamicKnot(agentId: ${baseKnot.agentId.substring(0, 10)}..., '
        'mood: ${mood?.type.name}, energy: ${energy?.value}, stress: ${stress?.value})';
  }
}

/// Represents an animated knot for meditation/breathing features
class AnimatedKnot {
  /// Base knot
  final PersonalityKnot knot;
  
  /// Type of animation
  final AnimationType animationType;
  
  /// Animation speed (0.0 = slow, 1.0 = fast)
  final double animationSpeed;
  
  /// Color transition for stress-based visualization
  final List<Color> colorTransition;
  
  /// Current animation progress (0.0 to 1.0)
  final double progress;
  
  const AnimatedKnot({
    required this.knot,
    required this.animationType,
    required this.animationSpeed,
    required this.colorTransition,
    this.progress = 0.0,
  });
  
  /// Create copy with updated progress
  AnimatedKnot copyWith({
    PersonalityKnot? knot,
    AnimationType? animationType,
    double? animationSpeed,
    List<Color>? colorTransition,
    double? progress,
  }) {
    return AnimatedKnot(
      knot: knot ?? this.knot,
      animationType: animationType ?? this.animationType,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      colorTransition: colorTransition ?? this.colorTransition,
      progress: progress ?? this.progress,
    );
  }
}

/// Types of animations for knots
enum AnimationType {
  breathing,
  pulsing,
  rotating,
  flowing,
}
