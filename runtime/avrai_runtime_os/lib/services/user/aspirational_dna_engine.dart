import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai_core/utils/vibe_constants.dart';
import 'dart:developer' as developer;

/// Service responsible for applying aspirational DNA shifts to a user's personality profile.
/// This acts as the bridge between natural language goals (parsed by AspirationalIntentParser)
/// and the actual mathematical quantum state of the user.
class AspirationalDNAEngine {
  static const String _logName = 'AspirationalDNAEngine';

  /// Applies a vector shift to the user's personality profile, returning the evolved profile.
  PersonalityProfile applyAspirationalShift(
    PersonalityProfile currentProfile,
    Map<String, double> vectorShift,
  ) {
    if (vectorShift.isEmpty) {
      return currentProfile;
    }

    final newDimensions = Map<String, double>.from(currentProfile.dimensions);
    final additionalLearning = <String, dynamic>{
      'aspirational_shifts_applied': 1,
    };

    developer.log('Applying Aspirational DNA Shift:', name: _logName);

    vectorShift.forEach((dimension, shiftAmount) {
      if (newDimensions.containsKey(dimension)) {
        final currentValue = newDimensions[dimension]!;
        // Apply shift and clamp to bounds
        final newValue = (currentValue + shiftAmount).clamp(
          VibeConstants.minDimensionValue,
          VibeConstants.maxDimensionValue,
        );
        newDimensions[dimension] = newValue;

        developer.log(
          '  - $dimension: ${currentValue.toStringAsFixed(2)} -> ${newValue.toStringAsFixed(2)} (shift: ${shiftAmount >= 0 ? '+' : ''}${shiftAmount.toStringAsFixed(2)})',
          name: _logName,
        );
      }
    });

    // We use the built-in evolve method which enforces the 30% drift limit (Patent #3)
    // to ensure the user doesn't completely lose their core identity in one chat message.
    return currentProfile.evolve(
      newDimensions: newDimensions,
      additionalLearning: additionalLearning,
    );
  }
}
