// ignore_for_file: depend_on_referenced_packages

import 'package:avrai_core/models/expertise/multi_path_expertise.dart';
import 'package:avrai_core/models/vibe/vibe_models.dart';
import 'package:avrai_runtime_os/services/geographic/locality_personality_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

void main() {
  group('LocalityPersonalityService canonical freeze', () {
    setUp(() {
      VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
      VibeKernel().importSnapshotEnvelope(
        VibeSnapshotEnvelope(exportedAtUtc: DateTime.utc(2026, 3, 12)),
      );
      TrajectoryKernel().importJournalWindow(
        records: const <TrajectoryMutationRecord>[],
      );
    });

    tearDown(() {
      VibeKernelRuntimeBindings.persistenceBridge = null;
    });

    test('returns canonical locality projection and ignores legacy mutations',
        () async {
      final vibeKernel = VibeKernel();
      vibeKernel.seedSubjectStateFromOnboarding(
        subjectRef: VibeSubjectRef.locality('brooklyn'),
        dimensions: const <String, double>{
          'community_orientation': 0.82,
          'exploration_eagerness': 0.24,
        },
        provenanceTags: const <String>['test:canonical_locality_projection'],
      );

      final service = LocalityPersonalityService();
      final before = await service.getLocalityPersonality('brooklyn');
      final after = await service.updateLocalityPersonality(
        locality: 'brooklyn',
        userBehavior: const <String, dynamic>{
          'communityScore': 0.1,
          'explorationScore': 1.0,
        },
      );
      final influenced = await service.incorporateGoldenExpertInfluence(
        locality: 'brooklyn',
        goldenExpertBehavior: const <String, dynamic>{
          'communityScore': 1.0,
        },
        localExpertise: _goldenExpert(),
      );

      expect(before.agentId, 'agent_locality_brooklyn');
      expect(before.dimensions['community_orientation'], closeTo(0.82, 0.001));
      expect(after.dimensions, before.dimensions);
      expect(influenced.dimensions, before.dimensions);
    });
  });
}

LocalExpertise _goldenExpert() {
  final now = DateTime.utc(2026, 3, 12);
  return LocalExpertise(
    id: 'expertise-brooklyn',
    userId: 'expert-user',
    category: 'community',
    locality: 'brooklyn',
    localVisits: 200,
    uniqueLocalLocations: 48,
    averageLocalRating: 4.7,
    timeInLocation: const Duration(days: 3650),
    firstLocalVisit: now.subtract(const Duration(days: 3650)),
    lastLocalVisit: now,
    continuousResidency: const Duration(days: 3650),
    isGoldenLocalExpert: true,
    score: 0.94,
    createdAt: now,
    updatedAt: now,
  );
}
