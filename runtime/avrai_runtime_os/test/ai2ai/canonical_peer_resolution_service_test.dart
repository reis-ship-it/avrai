import 'package:avrai_core/avra_core.dart';
import 'package:avrai_runtime_os/ai2ai/canonical_peer_resolution_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reality_engine/reality_engine.dart';

import '../support/fake_kernel_governance.dart';

class _FakePersistenceBridge implements VibeKernelPersistenceBridge {
  @override
  Future<void> persistCanonicalState({
    required VibeSnapshotEnvelope envelope,
    required List<TrajectoryMutationRecord> journalWindow,
  }) async {}
}

void main() {
  setUp(() {
    VibeKernelRuntimeBindings.persistenceBridge = _FakePersistenceBridge();
    VibeKernel().importSnapshotEnvelope(
      VibeSnapshotEnvelope(exportedAtUtc: DateTime.utc(2026, 3, 12)),
    );
  });

  tearDown(() {
    VibeKernelRuntimeBindings.persistenceBridge = null;
  });

  group('CanonicalPeerResolutionService', () {
    test('builds bounded local canonical peer payload from canonical state',
        () {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'exploration_eagerness': 0.74,
          'community_orientation': 0.63,
          'authenticity_preference': 0.68,
          'energy_preference': 0.58,
        },
        provenanceTags: const <String>['test:canonical_peer'],
      );

      final service = CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      );
      final payload = service.buildLocalPayload(
        localPersonality:
            PersonalityProfile.initial('agent-local', userId: 'user-local'),
      );

      expect(
          payload.reference.subjectRef, VibeSubjectRef.personal('agent-local'));
      expect(payload.reference.scope, 'personal');
      expect(payload.personalSurface.dimensionWindow, isNotEmpty);
      expect(
        payload.scopedBindings.any(
          (binding) => binding.scopedKind == ScopedAgentKind.communityNetwork,
        ),
        isFalse,
      );
    });

    test('rejects stale canonical peer payloads on receive', () {
      final service = CanonicalPeerResolutionService(
        governanceKernelService: buildTestGovernanceKernelService(),
      );
      final stalePayload = Ai2AiCanonicalPeerPayload(
        reference: Ai2AiVibeReference(
          subjectRef: VibeSubjectRef.personal('agent-remote'),
          scope: 'personal',
          confidence: 0.8,
          snapshotUpdatedAtUtc:
              DateTime.now().toUtc().subtract(const Duration(days: 10)),
        ),
        personalSurface: const CanonicalPeerCompatibilitySurface(
          signatureHash: 'remote-stale',
          archetype: 'balanced_explorer',
          dimensionWindow: <String, double>{
            'exploration_eagerness': 0.6,
            'community_orientation': 0.6,
            'authenticity_preference': 0.6,
            'temporal_flexibility': 0.6,
            'energy_preference': 0.6,
            'novelty_seeking': 0.6,
            'value_orientation': 0.6,
            'crowd_tolerance': 0.6,
          },
          energy: 0.6,
          socialCadence: 0.6,
          directness: 0.6,
          confidence: 0.8,
        ),
        freshnessHours: 240,
        confidence: 0.8,
        generatedAtUtc:
            DateTime.now().toUtc().subtract(const Duration(days: 10)),
      );

      final resolved = service.resolveInboundPayload(
        localAgentId: 'agent-local',
        remotePayload: stalePayload,
      );

      expect(resolved, isNull);
    });

    test('resolves canonical peer payload and computes governed compatibility',
        () {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'exploration_eagerness': 0.72,
          'community_orientation': 0.66,
          'authenticity_preference': 0.64,
          'temporal_flexibility': 0.61,
          'energy_preference': 0.63,
          'novelty_seeking': 0.71,
          'value_orientation': 0.52,
          'crowd_tolerance': 0.58,
        },
        provenanceTags: const <String>['test:canonical_peer'],
      );

      final service = CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      );
      final localPayload = service.buildLocalPayload(
        localPersonality:
            PersonalityProfile.initial('agent-local', userId: 'user-local'),
      );
      final remotePayload = Ai2AiCanonicalPeerPayload(
        reference: Ai2AiVibeReference(
          subjectRef: VibeSubjectRef.personal('agent-remote'),
          scope: 'personal',
          confidence: 0.83,
          geographicBinding: GeographicVibeBinding(
            localityRef: VibeSubjectRef.locality('bham-downtown'),
            stableKey: 'bham-downtown',
            higherGeographicRefs: <VibeSubjectRef>[
              VibeSubjectRef.city('bham'),
              VibeSubjectRef.region('al'),
              VibeSubjectRef.global('earth'),
            ],
            cityCode: 'bham',
            regionCode: 'al',
            globalCode: 'earth',
          ),
          scopedBindings: <ScopedVibeBinding>[
            ScopedVibeBinding(
              contextRef: VibeSubjectRef.scoped(
                scopedId: 'scene:locality-agent:bham-downtown:indie-music',
                scopedKind: ScopedAgentKind.scene,
              ),
              scopedKind: ScopedAgentKind.scene,
              anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
            ),
          ],
          snapshotUpdatedAtUtc: DateTime.now().toUtc(),
        ),
        personalSurface: const CanonicalPeerCompatibilitySurface(
          signatureHash: 'remote-signature',
          archetype: 'social_connector',
          dimensionWindow: <String, double>{
            'exploration_eagerness': 0.7,
            'community_orientation': 0.69,
            'authenticity_preference': 0.63,
            'temporal_flexibility': 0.64,
            'energy_preference': 0.61,
            'novelty_seeking': 0.68,
            'value_orientation': 0.5,
            'crowd_tolerance': 0.57,
          },
          energy: 0.61,
          socialCadence: 0.71,
          directness: 0.56,
          confidence: 0.83,
        ),
        geographicBinding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality('bham-downtown'),
          stableKey: 'bham-downtown',
          higherGeographicRefs: <VibeSubjectRef>[
            VibeSubjectRef.city('bham'),
            VibeSubjectRef.region('al'),
            VibeSubjectRef.global('earth'),
          ],
          cityCode: 'bham',
          regionCode: 'al',
          globalCode: 'earth',
        ),
        scopedBindings: <ScopedVibeBinding>[
          ScopedVibeBinding(
            contextRef: VibeSubjectRef.scoped(
              scopedId: 'scene:locality-agent:bham-downtown:indie-music',
              scopedKind: ScopedAgentKind.scene,
            ),
            scopedKind: ScopedAgentKind.scene,
            anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
          ),
        ],
        freshnessHours: 1.5,
        confidence: 0.83,
        generatedAtUtc: DateTime.now().toUtc(),
      );

      final resolved = service.resolveInboundPayload(
        localAgentId: 'agent-local',
        remotePayload: remotePayload,
      );

      expect(resolved, isNotNull);
      final compatibility = service.computeCompatibility(
        localPayload: localPayload,
        remoteContext: resolved!,
      );
      final legacy = service.toLegacyCompatibilityResult(
        compatibility,
        localPayload: localPayload,
        remoteContext: resolved,
      );

      expect(compatibility.basicCompatibility, greaterThan(0.2));
      expect(compatibility.reasonCodes, contains('personal_surface_alignment'));
      expect(legacy.learningOpportunities, isNotEmpty);
      expect(legacy.aiPleasurePotential, greaterThan(0.2));
    });

    test('degrades legacy profile exchange into bounded canonical peer context',
        () {
      final service = CanonicalPeerResolutionService(
        governanceKernelService: buildTestGovernanceKernelService(),
      );
      final legacyProfile = PersonalityProfile.initial(
        'agent-legacy-remote',
        userId: 'legacy-user',
      ).evolve(
        newArchetype: 'legacy_social_connector',
        newDimensions: const <String, double>{
          'exploration_eagerness': 0.69,
          'community_orientation': 0.66,
          'authenticity_preference': 0.61,
          'energy_preference': 0.58,
        },
      );

      final resolved = service.resolveLegacyPersonalityProfile(
        localAgentId: 'agent-local',
        remoteProfile: legacyProfile,
      );

      expect(resolved, isNotNull);
      expect(
        resolved!.metadata['legacy_personality_exchange'],
        isTrue,
      );
      expect(
        resolved.reference.metadata['compatibility_only'],
        isTrue,
      );
      expect(resolved.personalSurface.metadata['legacy_profile_compatibility_only'],
          isTrue);
    });

    test('builds peer why snapshot from canonical personal geographic and scoped causes',
        () {
      final vibeKernel = VibeKernel();
      vibeKernel.seedUserStateFromOnboarding(
        subjectId: 'agent-local',
        dimensions: const <String, double>{
          'exploration_eagerness': 0.72,
          'community_orientation': 0.66,
          'authenticity_preference': 0.64,
          'temporal_flexibility': 0.61,
          'energy_preference': 0.63,
          'novelty_seeking': 0.71,
        },
        provenanceTags: const <String>['test:canonical_peer_why'],
      );
      final service = CanonicalPeerResolutionService(
        vibeKernel: vibeKernel,
        governanceKernelService: buildTestGovernanceKernelService(),
      );
      final localPayload = service.buildLocalPayload(
        localPersonality:
            PersonalityProfile.initial('agent-local', userId: 'user-local'),
      );
      final resolved = service.resolveInboundPayload(
        localAgentId: 'agent-local',
        remotePayload: Ai2AiCanonicalPeerPayload(
          reference: Ai2AiVibeReference(
            subjectRef: VibeSubjectRef.personal('agent-remote'),
            scope: 'personal',
            confidence: 0.82,
            geographicBinding: GeographicVibeBinding(
              localityRef: VibeSubjectRef.locality('bham-downtown'),
              stableKey: 'bham-downtown',
              higherGeographicRefs: <VibeSubjectRef>[
                VibeSubjectRef.city('bham'),
                VibeSubjectRef.region('al'),
                VibeSubjectRef.global('earth'),
              ],
              cityCode: 'bham',
              regionCode: 'al',
              globalCode: 'earth',
            ),
            scopedBindings: <ScopedVibeBinding>[
              ScopedVibeBinding(
                contextRef: VibeSubjectRef.scoped(
                  scopedId: 'scene:locality-agent:bham-downtown:indie-music',
                  scopedKind: ScopedAgentKind.scene,
                ),
                scopedKind: ScopedAgentKind.scene,
                anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
              ),
            ],
            snapshotUpdatedAtUtc: DateTime.now().toUtc(),
          ),
          personalSurface: const CanonicalPeerCompatibilitySurface(
            signatureHash: 'remote-signature',
            archetype: 'social_connector',
            dimensionWindow: <String, double>{
              'exploration_eagerness': 0.71,
              'community_orientation': 0.68,
              'authenticity_preference': 0.63,
              'temporal_flexibility': 0.62,
              'energy_preference': 0.61,
              'novelty_seeking': 0.69,
              'value_orientation': 0.51,
              'crowd_tolerance': 0.58,
            },
            energy: 0.61,
            socialCadence: 0.71,
            directness: 0.56,
            confidence: 0.82,
          ),
          geographicBinding: GeographicVibeBinding(
            localityRef: VibeSubjectRef.locality('bham-downtown'),
            stableKey: 'bham-downtown',
            higherGeographicRefs: <VibeSubjectRef>[
              VibeSubjectRef.city('bham'),
              VibeSubjectRef.region('al'),
              VibeSubjectRef.global('earth'),
            ],
            cityCode: 'bham',
            regionCode: 'al',
            globalCode: 'earth',
          ),
          scopedBindings: <ScopedVibeBinding>[
            ScopedVibeBinding(
              contextRef: VibeSubjectRef.scoped(
                scopedId: 'scene:locality-agent:bham-downtown:indie-music',
                scopedKind: ScopedAgentKind.scene,
              ),
              scopedKind: ScopedAgentKind.scene,
              anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
            ),
          ],
          freshnessHours: 1.0,
          confidence: 0.82,
          generatedAtUtc: DateTime.now().toUtc(),
        ),
      );

      final localPayloadWithGeography = Ai2AiCanonicalPeerPayload(
        reference: Ai2AiVibeReference(
          subjectRef: localPayload.reference.subjectRef,
          scope: localPayload.reference.scope,
          confidence: localPayload.reference.confidence,
          geographicBinding: GeographicVibeBinding(
            localityRef: VibeSubjectRef.locality('bham-downtown'),
            stableKey: 'bham-downtown',
            higherGeographicRefs: <VibeSubjectRef>[
              VibeSubjectRef.city('bham'),
              VibeSubjectRef.region('al'),
              VibeSubjectRef.global('earth'),
            ],
            cityCode: 'bham',
            regionCode: 'al',
            globalCode: 'earth',
          ),
          scopedBindings: <ScopedVibeBinding>[
            ScopedVibeBinding(
              contextRef: VibeSubjectRef.scoped(
                scopedId: 'scene:locality-agent:bham-downtown:indie-music',
                scopedKind: ScopedAgentKind.scene,
              ),
              scopedKind: ScopedAgentKind.scene,
              anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
            ),
          ],
          snapshotUpdatedAtUtc: localPayload.reference.snapshotUpdatedAtUtc,
          metadata: localPayload.reference.metadata,
        ),
        personalSurface: localPayload.personalSurface,
        geographicBinding: GeographicVibeBinding(
          localityRef: VibeSubjectRef.locality('bham-downtown'),
          stableKey: 'bham-downtown',
          higherGeographicRefs: <VibeSubjectRef>[
            VibeSubjectRef.city('bham'),
            VibeSubjectRef.region('al'),
            VibeSubjectRef.global('earth'),
          ],
          cityCode: 'bham',
          regionCode: 'al',
          globalCode: 'earth',
        ),
        scopedBindings: <ScopedVibeBinding>[
          ScopedVibeBinding(
            contextRef: VibeSubjectRef.scoped(
              scopedId: 'scene:locality-agent:bham-downtown:indie-music',
              scopedKind: ScopedAgentKind.scene,
            ),
            scopedKind: ScopedAgentKind.scene,
            anchorGeographicRef: VibeSubjectRef.locality('bham-downtown'),
          ),
        ],
        freshnessHours: localPayload.freshnessHours,
        confidence: localPayload.confidence,
        generatedAtUtc: localPayload.generatedAtUtc,
        metadata: localPayload.metadata,
      );

      final compatibility = service.computeCompatibility(
        localPayload: localPayloadWithGeography,
        remoteContext: resolved!,
      );
      final why = service.buildPeerCompatibilityWhySnapshot(
        localPayload: localPayloadWithGeography,
        remoteContext: resolved,
        result: compatibility,
      );

      expect(why.summary, isNotEmpty);
      expect(why.drivers.map((entry) => entry.label), contains('personal_surface_alignment'));
      expect(
        why.drivers.any((entry) => entry.label.startsWith('shared_geography:')),
        isTrue,
      );
    });
  });
}
