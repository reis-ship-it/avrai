import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai_core/models/personality_knot.dart';
import 'package:avrai_core/models/mood_state.dart';
import 'package:avrai_knot/models/dynamic_knot.dart';

/// Service for creating dynamic knots based on mood/energy/stress
/// Phase 4: Dynamic Knots (Mood/Energy)
class DynamicKnotService {
  /// Update knot based on current mood/energy/stress
  DynamicKnot updateKnotWithCurrentState({
    required PersonalityKnot baseKnot,
    required MoodState mood,
    required EnergyLevel energy,
    required StressLevel stress,
  }) {
    developer.log(
      'Updating knot with mood: ${mood.type.name}, energy: ${energy.value}, stress: ${stress.value}',
      name: 'DynamicKnotService',
    );
    
    // Modify knot colors based on mood
    final colorScheme = _mapMoodToColors(mood);
    
    // Adjust knot complexity based on energy/stress
    final complexityModifier = _calculateComplexityModifier(energy, stress);
    
    // Map energy to animation speed
    final animationSpeed = _mapEnergyToAnimationSpeed(energy);
    
    // Map stress to pulse rate
    final pulseRate = _mapStressToPulseRate(stress);
    
    return DynamicKnot(
      baseKnot: baseKnot,
      colorScheme: colorScheme,
      animationSpeed: animationSpeed,
      pulseRate: pulseRate,
      complexityModifier: complexityModifier,
      mood: mood,
      energy: energy,
      stress: stress,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Create "breathing" knot that changes with stress
  /// Knot "breathes" slower when relaxed, faster when stressed
  AnimatedKnot createBreathingKnot({
    required PersonalityKnot baseKnot,
    required double currentStressLevel,
  }) {
    developer.log(
      'Creating breathing knot with stress level: $currentStressLevel',
      name: 'DynamicKnotService',
    );
    
    // Knot "breathes" slower when relaxed, faster when stressed
    // Breathing rate: 1.0 (relaxed) to 0.3 (stressed)
    final breathingRate = 1.0 - (currentStressLevel * 0.7);
    
    // Create color transition based on stress
    final colorTransition = _createStressColorTransition(currentStressLevel);
    
    return AnimatedKnot(
      knot: baseKnot,
      animationType: AnimationType.breathing,
      animationSpeed: breathingRate.clamp(0.3, 1.0),
      colorTransition: colorTransition,
      progress: 0.0,
    );
  }
  
  /// Map mood to color scheme
  Map<String, Color> _mapMoodToColors(MoodState mood) {
    switch (mood.type) {
      case MoodType.happy:
        return {
          'primary': Colors.yellow,
          'secondary': Colors.orange,
        };
      case MoodType.calm:
        return {
          'primary': Colors.blue,
          'secondary': Colors.teal,
        };
      case MoodType.energetic:
        return {
          'primary': Colors.red,
          'secondary': Colors.pink,
        };
      case MoodType.stressed:
        return {
          'primary': Colors.grey,
          'secondary': Colors.grey.shade700,
        };
      case MoodType.anxious:
        return {
          'primary': Colors.deepPurple,
          'secondary': Colors.purple,
        };
      case MoodType.relaxed:
        return {
          'primary': Colors.green,
          'secondary': Colors.lightGreen,
        };
      case MoodType.excited:
        return {
          'primary': Colors.orange,
          'secondary': Colors.deepOrange,
        };
      case MoodType.tired:
        return {
          'primary': Colors.blueGrey,
          'secondary': Colors.grey,
        };
      case MoodType.focused:
        return {
          'primary': Colors.indigo,
          'secondary': Colors.blue,
        };
      case MoodType.creative:
        return {
          'primary': Colors.purple,
          'secondary': Colors.deepPurple,
        };
      case MoodType.social:
        return {
          'primary': Colors.pink,
          'secondary': Colors.red,
        };
      case MoodType.introspective:
        return {
          'primary': Colors.deepPurple,
          'secondary': Colors.indigo,
        };
    }
  }
  
  /// Calculate complexity modifier from energy/stress
  /// High energy + low stress = more complex
  /// Low energy + high stress = simpler
  double _calculateComplexityModifier(EnergyLevel energy, StressLevel stress) {
    // Weighted combination: 60% energy, 40% inverse stress
    final modifier = (energy.value * 0.6) + ((1.0 - stress.value) * 0.4);
    
    // Clamp to reasonable range (0.5 to 1.5)
    return modifier.clamp(0.5, 1.5);
  }
  
  /// Map energy level to animation speed
  /// High energy = faster animation
  double _mapEnergyToAnimationSpeed(EnergyLevel energy) {
    // Map 0.0-1.0 energy to 0.3-1.0 animation speed
    return 0.3 + (energy.value * 0.7);
  }
  
  /// Map stress level to pulse rate
  /// High stress = faster pulse
  double _mapStressToPulseRate(StressLevel stress) {
    // Map 0.0-1.0 stress to 0.3-1.0 pulse rate
    return 0.3 + (stress.value * 0.7);
  }
  
  /// Create color transition based on stress level
  /// Low stress = calm colors (blue/green)
  /// High stress = intense colors (red/orange)
  List<Color> _createStressColorTransition(double stressLevel) {
    if (stressLevel < 0.3) {
      // Low stress: calm colors
      return [
        Colors.blue.shade300,
        Colors.teal.shade300,
        Colors.green.shade300,
      ];
    } else if (stressLevel < 0.7) {
      // Medium stress: balanced colors
      return [
        Colors.blue.shade400,
        Colors.purple.shade400,
        Colors.pink.shade400,
      ];
    } else {
      // High stress: intense colors
      return [
        Colors.orange.shade600,
        Colors.red.shade600,
        Colors.deepOrange.shade600,
      ];
    }
  }
  
  /// Get default mood state (neutral)
  MoodState getDefaultMood() {
    return MoodState(
      type: MoodType.calm,
      intensity: 0.5,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get default energy level (moderate)
  EnergyLevel getDefaultEnergy() {
    return EnergyLevel(
      value: 0.5,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get default stress level (low)
  StressLevel getDefaultStress() {
    return StressLevel(
      value: 0.0,
      timestamp: DateTime.now(),
    );
  }
}
