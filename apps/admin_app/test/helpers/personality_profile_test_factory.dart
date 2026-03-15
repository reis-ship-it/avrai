// PersonalityProfile Test Factory
//
// Creates minimal valid PersonalityProfile instances for unit tests.
// Avoids duplicating construction boilerplate across test files.

import 'package:avrai_core/models/personality_profile.dart';

class PersonalityProfileTestFactory {
  static final DateTime _fixedDate = DateTime(2026, 1, 1);

  /// Minimal profile with no learning history signals (new user).
  static PersonalityProfile minimal({String agentId = 'test-agent-001'}) {
    return PersonalityProfile(
      agentId: agentId,
      dimensions: const {},
      dimensionConfidence: const {},
      archetype: 'Explorer',
      authenticity: 0.5,
      createdAt: _fixedDate,
      lastUpdated: _fixedDate,
      evolutionGeneration: 1,
      learningHistory: const {},
    );
  }

  /// Profile with specific average dimension confidence (affects embedding gate).
  static PersonalityProfile withConfidence(
    double confidence, {
    String agentId = 'test-agent-001',
  }) {
    return PersonalityProfile(
      agentId: agentId,
      dimensions: const {},
      dimensionConfidence: {
        'openness': confidence,
        'conscientiousness': confidence,
        'extraversion': confidence,
      },
      archetype: 'Explorer',
      authenticity: 0.5,
      createdAt: _fixedDate,
      lastUpdated: _fixedDate,
      evolutionGeneration: 10,
      learningHistory: const {},
    );
  }

  /// Profile with pre-populated learningHistory fields.
  static PersonalityProfile withLearningHistory(
    Map<String, dynamic> history, {
    String agentId = 'test-agent-001',
  }) {
    return PersonalityProfile(
      agentId: agentId,
      dimensions: const {},
      dimensionConfidence: const {},
      archetype: 'Explorer',
      authenticity: 0.5,
      createdAt: _fixedDate,
      lastUpdated: _fixedDate,
      evolutionGeneration: 1,
      learningHistory: history,
    );
  }
}
