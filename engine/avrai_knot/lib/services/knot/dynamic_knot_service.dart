import 'dart:developer' as developer;
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
  Map<String, int> _mapMoodToColors(MoodState mood) {
    switch (mood.type) {
      case MoodType.happy:
        return {'primary': 0xFFFFEB3B, 'secondary': 0xFFFF9800};
      case MoodType.calm:
        return {'primary': 0xFF2196F3, 'secondary': 0xFF009688};
      case MoodType.energetic:
        return {'primary': 0xFFF44336, 'secondary': 0xFFE91E63};
      case MoodType.stressed:
        return {'primary': 0xFF9E9E9E, 'secondary': 0xFF616161};
      case MoodType.anxious:
        return {'primary': 0xFF673AB7, 'secondary': 0xFF9C27B0};
      case MoodType.relaxed:
        return {'primary': 0xFF4CAF50, 'secondary': 0xFF8BC34A};
      case MoodType.excited:
        return {'primary': 0xFFFF9800, 'secondary': 0xFFFF5722};
      case MoodType.tired:
        return {'primary': 0xFF607D8B, 'secondary': 0xFF9E9E9E};
      case MoodType.focused:
        return {'primary': 0xFF3F51B5, 'secondary': 0xFF2196F3};
      case MoodType.creative:
        return {'primary': 0xFF9C27B0, 'secondary': 0xFF673AB7};
      case MoodType.social:
        return {'primary': 0xFFE91E63, 'secondary': 0xFFF44336};
      case MoodType.introspective:
        return {'primary': 0xFF673AB7, 'secondary': 0xFF3F51B5};
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
  List<int> _createStressColorTransition(double stressLevel) {
    if (stressLevel < 0.3) {
      // Low stress: calm colors
      return [0xFF64B5F6, 0xFF4DB6AC, 0xFF81C784];
    } else if (stressLevel < 0.7) {
      // Medium stress: balanced colors
      return [0xFF42A5F5, 0xFFAB47BC, 0xFFEC407A];
    } else {
      // High stress: intense colors
      return [0xFFFB8C00, 0xFFE53935, 0xFFF4511E];
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
    return EnergyLevel(value: 0.5, timestamp: DateTime.now());
  }

  /// Get default stress level (low)
  StressLevel getDefaultStress() {
    return StressLevel(value: 0.0, timestamp: DateTime.now());
  }
}
