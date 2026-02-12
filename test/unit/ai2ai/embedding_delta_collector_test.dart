/// SPOTS EmbeddingDeltaCollector Tests
/// Date: January 2, 2026
/// Purpose: Ensure federated deltas align with canonical 12-dimension contract.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';

void main() {
  group('EmbeddingDeltaCollector', () {
    test('uses VibeConstants.coreDimensions ordering and length (12D contract)',
        () async {
      final collector = EmbeddingDeltaCollector();

      final local = PersonalityProfile.initial('local');
      final remote = PersonalityProfile.initial('remote').evolve(
        newDimensions: const {
          'energy_preference': 1.0,
        },
      );

      final delta = await collector.calculateDelta(
        localPersonality: local,
        remotePersonality: remote,
      );

      expect(delta, isNotNull);
      expect(delta!.delta, hasLength(VibeConstants.coreDimensions.length));

      final idxEnergy =
          VibeConstants.coreDimensions.indexOf('energy_preference');
      expect(idxEnergy, isNonNegative);
      // Drift resistance limits per-dimension change to +/- 0.30 from core (0.5).
      // So 1.0 is clamped to 0.8, giving a delta of 0.3.
      expect(delta.delta[idxEnergy], closeTo(0.3, 1e-9));

      // Unchanged dimensions should be ~0.0 (exact for this construction).
      for (var i = 0; i < delta.delta.length; i++) {
        if (i == idxEnergy) continue;
        expect(delta.delta[i], equals(0.0));
      }
    });
  });
}

