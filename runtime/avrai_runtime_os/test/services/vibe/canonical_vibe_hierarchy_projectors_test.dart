import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/services/vibe/canonical_vibe_projection_service.dart';
import 'package:avrai_runtime_os/services/vibe/hierarchical_locality_vibe_projector.dart';
import 'package:avrai_runtime_os/services/vibe/scoped_context_vibe_projector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../../support/fake_kernel_governance.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

void main() {
  late VibeKernel vibeKernel;

  setUp(() {
    VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
    VibeKernel.resetFallbackStateForTesting();
    TrajectoryKernel.resetFallbackStateForTesting();
    TrajectoryKernel().importJournalWindow(
      records: const <TrajectoryMutationRecord>[],
    );
    vibeKernel = VibeKernel();
  });

  tearDown(() {
    VibeKernelRuntimeBindings.persistenceBridge = null;
  });

  test('canonical projection service returns a personality projection', () {
    final agentId = 'agent_projection_${DateTime.now().microsecondsSinceEpoch}';
    vibeKernel.seedUserStateFromOnboarding(
      subjectId: agentId,
      dimensions: _dimensions(0.82),
      dimensionConfidence: _confidence(0.74),
      provenanceTags: const <String>['test:projection'],
    );

    final service = CanonicalVibeProjectionService(vibeKernel: vibeKernel);
    final profile = service.projectProfileForAgent(agentId, userId: 'user_123');

    expect(profile, isNotNull);
    expect(profile!.agentId, equals(agentId));
    expect(profile.dimensions['exploration_eagerness'], closeTo(0.82, 0.0001));
    expect(
      profile.dimensionConfidence['exploration_eagerness'],
      closeTo(0.74, 0.0001),
    );
    expect(profile.authenticity, inInclusiveRange(0.0, 1.0));
  });

  test(
    'hierarchical projector writes geographic rollups only for live levels',
    () {
      final stableKey = 'loc-${DateTime.now().microsecondsSinceEpoch}';
      final projector = HierarchicalLocalityVibeProjector(
        vibeKernel: vibeKernel,
        governanceKernel: buildTestGovernanceKernelService(),
      );

      final receipts = projector.projectObservation(
        binding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality(stableKey),
          stableKey: stableKey,
          cityCode: 'bham',
          regionCode: 'al',
          globalCode: 'earth',
        ),
        source: 'test:geo',
        dimensions: _dimensions(0.77),
        provenanceTags: const <String>['test:geo'],
      );

      expect(
        receipts.map((entry) => entry.subjectId),
        containsAll(<String>[
          'locality-agent:$stableKey',
          'city-agent:bham',
          'region-agent:al',
          'global-agent:earth',
        ]),
      );
      expect(
        receipts.map((entry) => entry.subjectId),
        isNot(contains('district-agent:southside')),
      );
      expect(
        receipts.map((entry) => entry.subjectId),
        isNot(contains('country-agent:us')),
      );

      final localitySnapshot = vibeKernel.getSnapshot(
        VibeSubjectRef.locality(stableKey),
      );
      final globalSnapshot = vibeKernel.getSnapshot(
        VibeSubjectRef.global('earth'),
      );
      expect(localitySnapshot.coreDna.dimensions, isNotEmpty);
      expect(globalSnapshot.coreDna.dimensions, isNotEmpty);
    },
  );

  test(
    'hierarchical projector includes district and country only when present',
    () {
      final stableKey = 'loc-${DateTime.now().microsecondsSinceEpoch}';
      final projector = HierarchicalLocalityVibeProjector(
        vibeKernel: vibeKernel,
        governanceKernel: buildTestGovernanceKernelService(),
      );

      final receipts = projector.projectObservation(
        binding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality(stableKey),
          stableKey: stableKey,
          districtCode: 'southside',
          cityCode: 'bham',
          regionCode: 'al',
          countryCode: 'us',
          globalCode: 'earth',
        ),
        source: 'test:geo',
        dimensions: _dimensions(0.73),
        provenanceTags: const <String>['test:geo'],
      );

      expect(
        receipts.map((entry) => entry.subjectId),
        containsAll(<String>['district-agent:southside', 'country-agent:us']),
      );
    },
  );

  test(
    'scoped projector requires repeated multi-family evidence for scenes',
    () {
      final projector = ScopedContextVibeProjector(
        vibeKernel: vibeKernel,
        governanceKernel: buildTestGovernanceKernelService(),
      );
      final geographicBinding = GeographicVibeBinding(
        localityRef: VibeSubjectRef.locality('loc-scope'),
        stableKey: 'loc-scope',
        cityCode: 'bham',
        globalCode: 'earth',
      );

      final singleFamily = projector.buildBindings(
        geographicBinding: geographicBinding,
        metadata: const <String, dynamic>{
          'scene_label': 'Indie Music',
          'scene_language_score': 1.0,
        },
      );
      expect(
        singleFamily.where(
          (entry) => entry.scopedKind == ScopedAgentKind.scene,
        ),
        isEmpty,
      );

      final repeatedEvidence = projector.buildBindings(
        geographicBinding: geographicBinding,
        metadata: const <String, dynamic>{
          'university_id': 'uab',
          'university_name': 'University of Alabama at Birmingham',
          'campus_id': 'uab-main',
          'organization_id': 'org-founders',
          'organization_name': 'Founders Circle',
          'scene_label': 'Indie Music',
          'categories': <String>['music'],
          'venue_ids': <String>['saturn'],
        },
      );

      expect(
        repeatedEvidence.map((entry) => entry.scopedKind),
        containsAll(<ScopedAgentKind>[
          ScopedAgentKind.university,
          ScopedAgentKind.campus,
          ScopedAgentKind.organization,
          ScopedAgentKind.scene,
        ]),
      );
    },
  );
}

Map<String, double> _dimensions(double value) => <String, double>{
  for (final dimension in VibeConstants.coreDimensions) dimension: value,
};

Map<String, double> _confidence(double value) => <String, double>{
  for (final dimension in VibeConstants.coreDimensions) dimension: value,
};
