import 'dart:convert';
import 'dart:io';

import 'package:avrai_core/avra_core.dart';
import 'package:avrai_core/models/temporal/replay_simulation_artifacts.dart';
import 'package:avrai_runtime_os/services/admin/replay_simulation_admin_service.dart';
import 'package:avrai_runtime_os/services/intake/universal_intake_repository.dart';
import 'package:avrai_runtime_os/services/reality_model/default_reality_model_port.dart';
import 'package:avrai_runtime_os/services/reality_model/governed_upward_learning_intake_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'default service exposes the BHAM replay environment and snapshot',
    () async {
      final service = ReplaySimulationAdminService(
        nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      );

      final environments = service.listEnvironments();
      expect(environments, hasLength(1));
      expect(environments.single.environmentId, 'bham-replay-world-2023');
      expect(environments.single.cityCode, 'bham');
      expect(environments.single.replayYear, 2023);

      final snapshot = await service.getSnapshot();
      expect(snapshot.environmentId, 'bham-replay-world-2023');
      expect(snapshot.cityCode, 'bham');
      expect(snapshot.replayYear, 2023);
      expect(snapshot.generatedAt, DateTime.utc(2026, 3, 31, 20));
      expect(snapshot.scenarios, isNotEmpty);
      expect(snapshot.receipts, hasLength(snapshot.scenarios.length));
      expect(snapshot.comparisons, hasLength(snapshot.scenarios.length));
    },
  );

  test('selects explicit environment adapters when requested', () async {
    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-a',
            displayName: 'Environment A',
            cityCode: 'bham',
            replayYear: 2023,
          ),
        ),
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-b',
            displayName: 'Environment B',
            cityCode: 'bham',
            replayYear: 2024,
          ),
        ),
      ],
      defaultEnvironmentId: 'env-a',
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
    );

    final snapshot = await service.getSnapshot(environmentId: 'env-b');
    expect(snapshot.environmentId, 'env-b');
    expect(snapshot.replayYear, 2024);

    final streamed = await service
        .watchSnapshot(
          environmentId: 'env-b',
          refreshInterval: const Duration(minutes: 5),
        )
        .first;
    expect(streamed.environmentId, 'env-b');
    expect(streamed.replayYear, 2024);
  });

  test('fails closed on unknown environments', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_unknown_env_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'env-a',
            displayName: 'Environment A',
            cityCode: 'bham',
            replayYear: 2023,
          ),
        ),
      ],
      documentsDirectoryProvider: () async => tempDir,
    );

    await expectLater(
      service.getSnapshot(environmentId: 'missing-env'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Unknown simulation environment'),
        ),
      ),
    );
  });

  test('rejects duplicate environment ids at construction time', () {
    expect(
      () => ReplaySimulationAdminService(
        environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
          _FakeReplaySimulationAdminEnvironmentAdapter(
            descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
              environmentId: 'dup-env',
              displayName: 'Environment A',
              cityCode: 'bham',
              replayYear: 2023,
            ),
          ),
          _FakeReplaySimulationAdminEnvironmentAdapter(
            descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
              environmentId: 'dup-env',
              displayName: 'Environment B',
              cityCode: 'bham',
              replayYear: 2024,
            ),
          ),
        ],
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('Duplicate simulation environment id'),
        ),
      ),
    );
  });

  test(
    'synthetic environment adapter builds a non-BHAM simulation snapshot with locality display names',
    () async {
      const adapter = SyntheticReplaySimulationAdminEnvironmentAdapter(
        descriptor: ReplaySimulationAdminEnvironmentDescriptor(
          environmentId: 'atx-replay-world-2024',
          displayName: 'Austin Simulation Environment 2024',
          cityCode: 'atx',
          replayYear: 2024,
          description:
              'Austin simulation environment for stage-2 parity checks.',
          cityPackManifestRef: 'city_packs/atx/2024_manifest.json',
          cityPackStructuralRef: 'city_pack:austin_core_2024',
          campaignDefaultsRef: 'city_packs/atx/campaign_defaults.json',
          localityExpectationProfileRef:
              'city_packs/atx/locality_expectations.json',
          worldHealthProfileRef: 'city_packs/atx/world_health.json',
        ),
        localityDisplayNames: <String, String>{
          'atx_downtown': 'Downtown Austin',
          'atx_east_side': 'East Side',
          'atx_south_congress': 'South Congress',
        },
      );
      final service = ReplaySimulationAdminService(
        environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[
          adapter,
        ],
        defaultEnvironmentId: 'atx-replay-world-2024',
        nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      );

      final snapshot = await service.getSnapshot();
      expect(snapshot.environmentId, 'atx-replay-world-2024');
      expect(snapshot.cityCode, 'atx');
      expect(snapshot.replayYear, 2024);
      expect(snapshot.scenarios, isNotEmpty);
      expect(
        snapshot.scenarios.every((scenario) => scenario.cityCode == 'atx'),
        isTrue,
      );
      expect(
        snapshot.scenarios.every((scenario) => scenario.baseReplayYear == 2024),
        isTrue,
      );
      expect(snapshot.localityOverlays, isNotEmpty);
      expect(
        snapshot.localityOverlays
            .map((overlay) => overlay.displayName)
            .contains('Downtown Austin'),
        isTrue,
      );
      expect(snapshot.contradictions, isNotEmpty);
      expect(snapshot.receipts, hasLength(snapshot.scenarios.length));
      expect(
        snapshot.foundation.intakeFlowRefs,
        contains('source_intake_orchestrator'),
      );
      expect(
        snapshot.foundation.sidecarRefs,
        contains('city_packs/atx/2024_manifest.json'),
      );
      expect(
        snapshot.foundation.metadata['cityPackStructuralRef'],
        'city_pack:austin_core_2024',
      );
      expect(
        snapshot.foundation.metadata['supportedPlaceRef'],
        'place:atx',
      );
      expect(
        snapshot.foundation.metadata['cityPackRefreshMode'],
        'versioned_living_city_pack',
      );
      expect(
        snapshot.foundation.metadata['currentBasisStatus'],
        'replay_grounded_seed_basis',
      );
      expect(
        snapshot.foundation.metadata['latestStateHydrationStatus'],
        'awaiting_latest_avrai_evidence_refresh',
      );
      expect(
        snapshot.foundation.metadata['hydrationFreshnessPosture'],
        'refresh_receipts_required_before_served_basis_change',
      );
      expect(
        snapshot.foundation.metadata['hydrationEvidenceFamilies'],
        contains('governed_reality_model_outputs'),
      );
      expect(snapshot.learningReadiness.trainingGrade, isNotEmpty);
      expect(snapshot.learningReadiness.requestPreviews, isNotEmpty);
      final domains = snapshot.learningReadiness.requestPreviews
          .map((entry) => entry.request.domain)
          .toSet();
      expect(domains, contains(RealityModelDomain.locality));
      expect(domains, contains(RealityModelDomain.place));
      expect(domains, contains(RealityModelDomain.event));
      expect(domains, contains(RealityModelDomain.community));
      expect(domains, contains(RealityModelDomain.business));
      expect(domains, contains(RealityModelDomain.list));
      expect(snapshot.syntheticHumanKernelExplorer.entries, isNotEmpty);
      expect(
        snapshot.syntheticHumanKernelExplorer.entries.first.traceSummary,
        isNotEmpty,
      );
      expect(snapshot.localityHierarchyHealth.nodes, isNotEmpty);
      expect(snapshot.localityHierarchyHealth.nodes.first.traceSummary,
          isNotEmpty);
      expect(snapshot.higherAgentHandoffView.items, isNotEmpty);
      expect(
          snapshot.higherAgentHandoffView.items.first.traceSummary, isNotEmpty);
      expect(
        snapshot.realismProvenance.sidecarRefs,
        contains('city_packs/atx/2024_manifest.json'),
      );
      expect(snapshot.weakSpots, isNotEmpty);
    },
  );

  test('registers a local world-simulation environment and builds snapshots',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_registration_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 1, 15),
    );

    final registration = await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
        'sav_midtown': 'Savannah Midtown',
      },
    );

    expect(registration.environmentId, 'sav-replay-world-2024');
    expect(registration.cityPackStructuralRef, 'city_pack:sav_core_2024');

    final environments = await service.listAvailableEnvironments();
    expect(
      environments.map((entry) => entry.environmentId),
      contains('sav-replay-world-2024'),
    );

    final snapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(snapshot.environmentId, 'sav-replay-world-2024');
    expect(snapshot.cityCode, 'sav');
    expect(snapshot.replayYear, 2024);
    expect(snapshot.scenarios, isNotEmpty);
    expect(
      snapshot.foundation.metadata['cityPackStructuralRef'],
      'city_pack:sav_core_2024',
    );
    expect(
      snapshot.foundation.metadata['supportedPlaceRef'],
      'place:sav',
    );
    expect(
      snapshot.foundation.metadata['cityPackRefreshMode'],
      'versioned_living_city_pack',
    );
    expect(
      snapshot.foundation.metadata['latestStateHydrationStatus'],
      'awaiting_latest_avrai_evidence_refresh',
    );
    expect(
      snapshot.foundation.metadata['latestStatePromotionReadiness'],
      'blocked_pending_latest_state_evidence',
    );
    expect(
      snapshot.foundation.metadata['latestStatePromotionBlockedReasons'],
      contains('app observations is still using seed placeholder evidence.'),
    );
    expect(
      snapshot.foundation.metadata['latestStateRefreshCadenceHours'],
      18,
    );
    expect(
      snapshot.foundation.metadata['latestStateRefreshCadenceStatus'],
      'awaiting_first_refresh_receipts',
    );
    expect(
      snapshot.foundation.metadata['latestStateRefreshPolicySummaries'],
      contains(
        'runtime/OS locality state <= 10h, >= 78% strength for place:sav',
      ),
    );
    expect(
      snapshot.foundation.metadata['servedBasisRef'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/served_city_pack_basis.seed.json',
    );
    expect(
      snapshot.foundation.metadata['latestStateEvidenceRefs'],
      contains(
        'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.seed.json',
      ),
    );
    expect(
      snapshot.foundation.metadata['latestStateEvidenceAgingSummaries'],
      contains(
        'app observations: seed placeholder still active against the 12h policy window for place:sav.',
      ),
    );
    expect(
      snapshot.localityOverlays
          .map((overlay) => overlay.displayName)
          .contains('Savannah Waterfront'),
      isTrue,
    );

    final registrationFile = File(
      '${tempDir.path}/AVRAI/world_simulation_lab/registered_environments/sav-replay-world-2024/environment_registration.json',
    );
    expect(registrationFile.existsSync(), isTrue);
    expect(
      registrationFile.readAsStringSync(),
      contains('"cityPackStructuralRef": "city_pack:sav_core_2024"'),
    );
  });

  test('stages latest-state basis refresh and preserves prior served lineage',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_refresh_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    var now = DateTime.utc(2026, 4, 3, 18, 30);
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => now,
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final firstStage = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(firstStage.currentBasisStatus, 'staged_latest_state_basis');
    expect(
      firstStage.latestStateHydrationStatus,
      'staged_latest_avrai_evidence_refresh_blocked',
    );
    expect(
      firstStage.latestStatePromotionReadiness,
      'blocked_pending_latest_state_evidence',
    );
    expect(
      firstStage.latestStateRefreshReceiptRef,
      'world_simulation_lab/registered_environments/sav-replay-world-2024/basis_refreshes/basis_refresh_1775241000000/basis_refresh_receipts.refresh.json',
    );
    expect(firstStage.latestStateDecisionStatus, 'not_reviewed');
    expect(
      firstStage.priorServedBasisRef,
      'world_simulation_lab/registered_environments/sav-replay-world-2024/served_city_pack_basis.seed.json',
    );
    expect(
      firstStage.latestStateEvidenceRefsByFamily['app_observations'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.seed.json',
    );

    final stagedSnapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      stagedSnapshot.foundation.metadata['servedBasisRef'],
      firstStage.servedBasisRef,
    );
    expect(
      stagedSnapshot.foundation.metadata['priorServedBasisRef'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/served_city_pack_basis.seed.json',
    );
    expect(
      stagedSnapshot.foundation.metadata['latestStatePromotionBlockedReasons'],
      contains(
          'governed reality-model outputs is still using seed placeholder evidence.'),
    );

    now = now.add(const Duration(minutes: 5));
    final secondStage = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(secondStage.priorServedBasisRef, firstStage.servedBasisRef);
  });

  test(
      'stages current latest-state evidence as promotable when fresh and receipt-backed',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_selection_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 19, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence(
      String filename,
      String family,
      double freshnessHours,
      double strengthScore,
    ) async {
      final file = File(path.join(latestStateRoot.path, filename));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'environmentId': 'sav-replay-world-2024',
          'supportedPlaceRef': 'place:sav',
          'evidenceFamily': family,
          'selectionStatus': 'selected_current_evidence',
          'freshnessHours': freshnessHours,
          'strengthScore': strengthScore,
          'receiptBacked': true,
        }),
      );
    }

    await writeCurrentEvidence(
      'app_observations.current.json',
      'app_observations',
      2,
      0.91,
    );
    await writeCurrentEvidence(
      'runtime_os_locality_state.current.json',
      'runtime_os_locality_state',
      4,
      0.88,
    );
    await writeCurrentEvidence(
      'governed_reality_model_outputs.current.json',
      'governed_reality_model_outputs',
      6,
      0.93,
    );

    final staged = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );

    expect(
      staged.latestStateEvidenceRefsByFamily['app_observations'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
    );
    expect(
      staged.latestStateHydrationStatus,
      'staged_latest_avrai_evidence_refresh_ready_for_review',
    );
    expect(
      staged.latestStatePromotionReadiness,
      'ready_for_bounded_basis_review',
    );
    expect(staged.latestStatePromotionBlockedReasons, isEmpty);
    expect(
      staged.latestStateDecisionStatus,
      'awaiting_basis_review_decision',
    );
    expect(
      staged.hydrationFreshnessPosture,
      'ready_for_served_basis_review_with_receipts',
    );
    expect(staged.latestStateRefreshCadenceHours, 18);
    expect(staged.latestStateRefreshCadenceStatus, 'within_refresh_window');
    expect(
      staged.latestStateRefreshPolicySummaries,
      contains(
        'app observations <= 12h, >= 72% strength for place:sav',
      ),
    );

    final snapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      snapshot.foundation.metadata['latestStatePromotionReadiness'],
      'ready_for_bounded_basis_review',
    );
    expect(
      snapshot.foundation.metadata['latestStateEvidenceSelectionSummaries'],
      contains(
        contains(
          'app observations -> world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
        ),
      ),
    );
    expect(
      snapshot.foundation.metadata['latestStateEvidenceAgingSummaries'],
      contains(
        'app observations: within policy window at 2.0h of 12h and receipt-backed.',
      ),
    );
  });

  test(
      'tracks per-family evidence aging posture against supported-place policy',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_aging_policy_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 19, 15),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence(
      String filename,
      String family, {
      required double freshnessHours,
      required double strengthScore,
      required bool receiptBacked,
    }) async {
      final file = File(path.join(latestStateRoot.path, filename));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'environmentId': 'sav-replay-world-2024',
          'supportedPlaceRef': 'place:sav',
          'selectionStatus': 'selected_current_evidence',
          'selectionPolicy': 'governed_supported_place_refresh',
          'evidenceFamily': family,
          'freshnessHours': freshnessHours,
          'strengthScore': strengthScore,
          'receiptBacked': receiptBacked,
        }),
      );
    }

    await writeCurrentEvidence(
      'app_observations.current.json',
      'app_observations',
      freshnessHours: 2,
      strengthScore: 0.91,
      receiptBacked: true,
    );
    await writeCurrentEvidence(
      'runtime_os_locality_state.current.json',
      'runtime_os_locality_state',
      freshnessHours: 9,
      strengthScore: 0.88,
      receiptBacked: false,
    );
    await writeCurrentEvidence(
      'governed_reality_model_outputs.current.json',
      'governed_reality_model_outputs',
      freshnessHours: 30,
      strengthScore: 0.93,
      receiptBacked: true,
    );

    final staged = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );

    expect(
      staged.latestStateEvidenceAgingStatusesByFamily['app_observations'],
      'within_policy_window',
    );
    expect(
      staged.latestStateEvidenceAgingStatusesByFamily[
          'runtime_os_locality_state'],
      'approaching_policy_edge_not_receipt_backed',
    );
    expect(
      staged.latestStateEvidenceAgingStatusesByFamily[
          'governed_reality_model_outputs'],
      'past_policy_window_receipt_backed',
    );
    expect(
      staged.latestStateEvidenceAgingSummariesByFamily[
          'runtime_os_locality_state'],
      'runtime/OS locality state: approaching the 10h policy edge at 9.0h and not receipt-backed.',
    );
    expect(
      staged.latestStateEvidenceAgingSummariesByFamily[
          'governed_reality_model_outputs'],
      'governed reality-model outputs: past the 24h policy window at 30.0h, but still receipt-backed.',
    );
  });

  test(
      'blocks staging when current evidence violates supported-place freshness policy',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_policy_gate_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 19, 30),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence(
      String filename,
      String family,
      double freshnessHours,
      double strengthScore,
    ) async {
      final file = File(path.join(latestStateRoot.path, filename));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'environmentId': 'sav-replay-world-2024',
          'supportedPlaceRef': 'place:sav',
          'evidenceFamily': family,
          'selectionStatus': 'selected_current_evidence',
          'freshnessHours': freshnessHours,
          'strengthScore': strengthScore,
          'receiptBacked': true,
        }),
      );
    }

    await writeCurrentEvidence(
      'app_observations.current.json',
      'app_observations',
      2,
      0.91,
    );
    await writeCurrentEvidence(
      'runtime_os_locality_state.current.json',
      'runtime_os_locality_state',
      14,
      0.88,
    );
    await writeCurrentEvidence(
      'governed_reality_model_outputs.current.json',
      'governed_reality_model_outputs',
      6,
      0.93,
    );

    final staged = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );

    expect(
      staged.latestStatePromotionReadiness,
      'blocked_pending_latest_state_evidence',
    );
    expect(
      staged.latestStatePromotionBlockedReasons,
      contains(
        'runtime/OS locality state freshness exceeds the 10h policy for place:sav.',
      ),
    );
  });

  test('promotes and rejects staged latest-state basis with decision lineage',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_decision_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    var now = DateTime.utc(2026, 4, 3, 20, 0);
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => now,
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );
    Future<void> writeCurrentEvidence(String filename, String family) async {
      final file = File(path.join(latestStateRoot.path, filename));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'environmentId': 'sav-replay-world-2024',
          'supportedPlaceRef': 'place:sav',
          'evidenceFamily': family,
          'selectionStatus': 'selected_current_evidence',
          'freshnessHours': 3,
          'strengthScore': 0.92,
          'receiptBacked': true,
        }),
      );
    }

    await writeCurrentEvidence(
      'app_observations.current.json',
      'app_observations',
    );
    await writeCurrentEvidence(
      'runtime_os_locality_state.current.json',
      'runtime_os_locality_state',
    );
    await writeCurrentEvidence(
      'governed_reality_model_outputs.current.json',
      'governed_reality_model_outputs',
    );

    final staged = await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(staged.latestStateDecisionStatus, 'awaiting_basis_review_decision');

    now = now.add(const Duration(minutes: 10));
    final promoted = await service.promoteStagedLatestStateBasis(
      environmentId: 'sav-replay-world-2024',
      rationale: 'Fresh evidence is strong enough to serve.',
    );
    expect(promoted.currentBasisStatus, 'latest_state_served_basis');
    expect(promoted.latestStateHydrationStatus, 'latest_state_basis_served');
    expect(promoted.latestStatePromotionReadiness, 'promoted_to_served_basis');
    expect(promoted.latestStateDecisionStatus, 'promoted');
    expect(promoted.latestStateDecisionArtifactRef, contains('.promoted.json'));
    expect(
      promoted.latestStatePromotionReceiptRef,
      contains('basis_promotion_receipts.promoted.json'),
    );
    expect(
      promoted.latestStateDeploymentReceiptRef,
      contains('served_basis_deployment_receipts.promoted.json'),
    );

    final promotedSnapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      promotedSnapshot.foundation.metadata['latestStateDecisionStatus'],
      'promoted',
    );
    expect(
      promotedSnapshot.foundation.metadata['latestStatePromotionReceiptRef'],
      promoted.latestStatePromotionReceiptRef,
    );
    expect(
      promotedSnapshot.foundation.metadata['latestStateDeploymentReceiptRef'],
      promoted.latestStateDeploymentReceiptRef,
    );

    now = now.add(const Duration(minutes: 10));
    await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    final rejected = await service.rejectStagedLatestStateBasis(
      environmentId: 'sav-replay-world-2024',
      rationale: 'Roll back after bounded review discrepancy.',
    );
    expect(rejected.latestStateDecisionStatus, 'rejected');
    expect(rejected.latestStateDecisionArtifactRef, contains('.rejected.json'));
    expect(
      rejected.latestStatePromotionReceiptRef,
      contains('basis_promotion_receipts.rejected.json'),
    );
    expect(
      rejected.hydrationFreshnessPosture,
      'prior_served_basis_restored_after_rejection',
    );
    expect(
      rejected.latestStatePromotionBlockedReasons,
      contains(
        'The previously staged latest-state basis was rejected during bounded review.',
      ),
    );
  });

  test('refreshes latest-state evidence refs and writes a refresh receipt',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_refresh_receipts_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 4, 9, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final refreshed = await service.refreshLatestStateEvidenceBundle(
      environmentId: 'sav-replay-world-2024',
    );

    expect(
      refreshed.latestStateRefreshReceiptRef,
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh.current.json',
    );
    expect(
      refreshed.latestStateHydrationStatus,
      'latest_avrai_evidence_refreshed_ready_for_staging',
    );
    expect(
      refreshed.latestStatePromotionReadiness,
      'ready_for_bounded_basis_review',
    );
    expect(
      refreshed.latestStateEvidenceRefsByFamily['app_observations'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/app_observations.current.json',
    );
    expect(
      refreshed
          .latestStateEvidenceSelectionSummariesByFamily['app_observations'],
      contains('selected current evidence'),
    );
    expect(
      refreshed.latestStateEvidenceAgingTransitionsByFamily['app_observations'],
      'refreshed_with_newer_evidence',
    );
    expect(
      refreshed.latestStateEvidenceAgingTrendsByFamily['app_observations'],
      'stable_with_recent_refresh',
    );
    expect(
      refreshed
          .latestStateEvidenceAgingTrendSummariesByFamily['app_observations'],
      'app observations: recent cadence checks refreshed this family and it remains within policy window.',
    );
    expect(
      refreshed.latestStateEvidencePolicyActionsByFamily['app_observations'],
      'no_action_family_stable',
    );
    expect(
      refreshed
          .latestStateEvidencePolicyActionSummariesByFamily['app_observations'],
      'app observations: no policy action required because this family is stable with recent refresh and remains within policy window.',
    );
    expect(refreshed.latestStateRefreshCadenceStatus, 'within_refresh_window');

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );
    final appEvidenceFile = File(
      path.join(latestStateRoot.path, 'app_observations.current.json'),
    );
    final refreshReceiptFile = File(
      path.join(latestStateRoot.path, 'latest_state_refresh.current.json'),
    );
    expect(appEvidenceFile.existsSync(), isTrue);
    expect(refreshReceiptFile.existsSync(), isTrue);

    final appEvidencePayload = Map<String, dynamic>.from(
      jsonDecode(appEvidenceFile.readAsStringSync()) as Map<String, dynamic>,
    );
    expect(appEvidencePayload['selectionPolicy'],
        'governed_supported_place_refresh');
    expect(appEvidencePayload['receiptBacked'], isTrue);
    expect(appEvidencePayload['agingTransition'], isNotEmpty);

    final refreshedSnapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      refreshedSnapshot.foundation.metadata['latestStateHydrationStatus'],
      'latest_avrai_evidence_refreshed_ready_for_staging',
    );
    expect(
      refreshedSnapshot.foundation.metadata['latestStateRefreshReceiptRef'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh.current.json',
    );
    expect(
      refreshedSnapshot.foundation.metadata['latestStateEvidenceRefs'],
      contains(
        'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/runtime_os_locality_state.current.json',
      ),
    );
    expect(
      refreshedSnapshot
          .foundation.metadata['latestStateEvidenceAgingTrendSummaries'],
      contains(
        'app observations: recent cadence checks refreshed this family and it remains within policy window.',
      ),
    );
    expect(
      refreshedSnapshot
          .foundation.metadata['latestStateEvidencePolicyActionSummaries'],
      contains(
        'app observations: no policy action required because this family is stable with recent refresh and remains within policy window.',
      ),
    );
  });

  test(
      'refresh recovers an evidence family after a degrading trend once newer evidence arrives',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_aging_recovery_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    var now = DateTime.utc(2026, 4, 4, 9, 0);
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => now,
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    await service.refreshLatestStateEvidenceBundle(
      environmentId: 'sav-replay-world-2024',
    );

    final servedBasisFile = File(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'served_city_pack_basis.current.json',
      ),
    );
    final servedBasisPayload = Map<String, dynamic>.from(
      jsonDecode(servedBasisFile.readAsStringSync()) as Map<String, dynamic>,
    )
      ..['latestStateEvidenceAgingTrendsByFamily'] = <String, dynamic>{
        'app_observations': 'degrading_without_newer_evidence',
        'runtime_os_locality_state': 'stable_with_recent_refresh',
        'governed_reality_model_outputs': 'stable_with_recent_refresh',
      }
      ..['latestStateEvidenceAgingTrendSummariesByFamily'] = <String, dynamic>{
        'app_observations':
            'app observations: this family is drifting under cadence checks because it last aged beyond policy window and is now approaching policy edge.',
      };
    servedBasisFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(servedBasisPayload),
    );
    final appEvidenceFile = File(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
        'app_observations.current.json',
      ),
    );
    final appEvidencePayload = Map<String, dynamic>.from(
      jsonDecode(appEvidenceFile.readAsStringSync()) as Map<String, dynamic>,
    )..['freshnessHours'] = 13;
    appEvidenceFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(appEvidencePayload),
    );

    now = now.add(const Duration(hours: 20));
    final refreshed = await service.refreshLatestStateEvidenceBundle(
      environmentId: 'sav-replay-world-2024',
    );

    expect(
      refreshed.latestStateEvidenceAgingTransitionsByFamily['app_observations'],
      'refreshed_with_newer_evidence',
    );
    expect(
      refreshed.latestStateEvidenceAgingTrendsByFamily['app_observations'],
      'recovered_after_degradation',
    );
    expect(
      refreshed
          .latestStateEvidenceAgingTrendSummariesByFamily['app_observations'],
      'app observations: this family recovered after degradation because newer evidence arrived and it is now within policy window.',
    );
    expect(
      refreshed.latestStateEvidencePolicyActionsByFamily['app_observations'],
      'watch_family_closely',
    );
    expect(
      refreshed
          .latestStateEvidencePolicyActionSummariesByFamily['app_observations'],
      'app observations: watch this family closely because it is recovered after degradation and is now within policy window.',
    );
  });

  test('runs scheduled refresh cadence checks and records execution receipts',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_cadence_refresh_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    var now = DateTime.utc(2026, 4, 4, 9, 0);
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => now,
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final initialExecution = await service.runScheduledLatestStateRefreshCheck(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      initialExecution.latestStateRefreshExecutionStatus,
      'executed_initial_refresh',
    );
    expect(
      initialExecution.latestStateRefreshExecutionReceiptRef,
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh_cadence.current.json',
    );

    now = now.add(const Duration(hours: 6));
    final skipped = await service.runScheduledLatestStateRefreshCheck(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      skipped.latestStateRefreshExecutionStatus,
      'skipped_within_refresh_window',
    );
    expect(skipped.latestStateRefreshCadenceStatus, 'within_refresh_window');

    now = now.add(const Duration(hours: 20));
    final due = await service.runScheduledLatestStateRefreshCheck(
      environmentId: 'sav-replay-world-2024',
    );
    expect(due.latestStateRefreshExecutionStatus, 'executed_due_refresh');
    expect(due.latestStateRefreshCadenceStatus, 'within_refresh_window');

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );
    final cadenceReceiptFile = File(
      path.join(
          latestStateRoot.path, 'latest_state_refresh_cadence.current.json'),
    );
    expect(cadenceReceiptFile.existsSync(), isTrue);
    final cadenceReceiptPayload = Map<String, dynamic>.from(
      jsonDecode(cadenceReceiptFile.readAsStringSync()) as Map<String, dynamic>,
    );
    expect(cadenceReceiptPayload['executionStatus'], 'executed_due_refresh');
    expect(cadenceReceiptPayload['cadenceStatusBefore'], 'due_for_refresh');

    final snapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      snapshot.foundation.metadata['latestStateRefreshExecutionStatus'],
      'executed_due_refresh',
    );
    expect(
      snapshot.foundation.metadata['latestStateRefreshExecutionReceiptRef'],
      'world_simulation_lab/registered_environments/sav-replay-world-2024/latest_state/latest_state_refresh_cadence.current.json',
    );
  });

  test(
      'revalidates promoted served basis, requires explicit restage, and restores after bounded review',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_revalidation_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final intakeRepository = UniversalIntakeRepository();
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      intakeRepository: intakeRepository,
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 21, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence({
      required double freshnessHours,
      required double strengthScore,
      required bool receiptBacked,
    }) async {
      Future<void> writeFamily(String filename, String family) async {
        final file = File(path.join(latestStateRoot.path, filename));
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': family,
            'selectionStatus': 'selected_current_evidence',
            'freshnessHours': freshnessHours,
            'strengthScore': strengthScore,
            'receiptBacked': receiptBacked,
          }),
        );
      }

      await writeFamily(
        'app_observations.current.json',
        'app_observations',
      );
      await writeFamily(
        'runtime_os_locality_state.current.json',
        'runtime_os_locality_state',
      );
      await writeFamily(
        'governed_reality_model_outputs.current.json',
        'governed_reality_model_outputs',
      );
    }

    await writeCurrentEvidence(
      freshnessHours: 3,
      strengthScore: 0.92,
      receiptBacked: true,
    );

    await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    await service.promoteStagedLatestStateBasis(
      environmentId: 'sav-replay-world-2024',
    );

    final revalidated = await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(revalidated.currentBasisStatus, 'latest_state_served_basis');
    expect(
      revalidated.latestStateHydrationStatus,
      'latest_state_basis_served_revalidated',
    );
    expect(
      revalidated.latestStatePromotionReadiness,
      'served_basis_revalidated_current',
    );
    expect(revalidated.latestStateRevalidationStatus, 'current');
    expect(
      revalidated.hydrationFreshnessPosture,
      'served_basis_still_supported_by_current_receipts',
    );
    expect(
      revalidated.latestStateRevalidationReceiptRef,
      contains('basis_revalidation_receipts.revalidation.json'),
    );
    expect(
      revalidated.latestStatePromotionReceiptRef,
      contains('basis_promotion_receipts.promoted.json'),
    );
    expect(
      revalidated.latestStateRevalidationArtifactRef,
      contains('basis_revalidation.current.json'),
    );

    await writeCurrentEvidence(
      freshnessHours: 72,
      strengthScore: 0.42,
      receiptBacked: false,
    );

    final expired = await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(expired.currentBasisStatus, 'expired_latest_state_served_basis');
    expect(
      expired.latestStateHydrationStatus,
      'latest_state_basis_served_expired',
    );
    expect(
      expired.latestStatePromotionReadiness,
      'restage_required_before_served_basis_reuse',
    );
    expect(expired.latestStateRevalidationStatus, 'expired');
    expect(
      expired.hydrationFreshnessPosture,
      'promoted_served_basis_expired_pending_restage',
    );
    expect(
      expired.latestStatePromotionBlockedReasons,
      contains(
        'The promoted served basis no longer satisfies latest-state evidence freshness and must be restaged before reuse.',
      ),
    );
    expect(
      expired.latestStateRevalidationArtifactRef,
      contains('basis_revalidation.expired.json'),
    );
    expect(expired.latestStateRecoveryDecisionStatus, 'not_reviewed');

    final expiredSnapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      expiredSnapshot.foundation.metadata['latestStateRevalidationStatus'],
      'expired',
    );
    expect(
      expiredSnapshot.foundation.metadata['currentBasisStatus'],
      'expired_latest_state_served_basis',
    );

    final restageRequired =
        await service.confirmExpiredServedBasisRestageRequired(
      environmentId: 'sav-replay-world-2024',
      rationale:
          'Keep the basis out of service until a new staged refresh exists.',
    );
    expect(
      restageRequired.latestStateRecoveryDecisionStatus,
      'restage_required_confirmed',
    );
    expect(
      restageRequired.latestStateHydrationStatus,
      'expired_basis_restage_required_confirmed',
    );
    expect(
      restageRequired.latestStateRecoveryDecisionArtifactRef,
      contains('basis_restore_decision.restage_required.json'),
    );

    await writeCurrentEvidence(
      freshnessHours: 2,
      strengthScore: 0.95,
      receiptBacked: true,
    );

    final readyForRestore = await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      readyForRestore.currentBasisStatus,
      'expired_latest_state_served_basis',
    );
    expect(
      readyForRestore.latestStateHydrationStatus,
      'expired_basis_ready_for_restore_review',
    );
    expect(
      readyForRestore.latestStatePromotionReadiness,
      'ready_for_bounded_served_basis_restore',
    );
    expect(readyForRestore.latestStateRevalidationStatus, 'current');
    expect(readyForRestore.latestStateRecoveryDecisionStatus, 'not_reviewed');

    final restored = await service.restoreExpiredServedBasis(
      environmentId: 'sav-replay-world-2024',
      rationale:
          'Current evidence is strong enough to restore the served basis.',
    );
    expect(restored.currentBasisStatus, 'latest_state_served_basis');
    expect(
      restored.latestStateHydrationStatus,
      'latest_state_basis_restored_after_review',
    );
    expect(
      restored.latestStatePromotionReadiness,
      'restored_to_served_basis_after_review',
    );
    expect(restored.latestStateRecoveryDecisionStatus, 'restored_after_review');
    expect(
      restored.hydrationFreshnessPosture,
      'served_basis_restored_from_revalidated_receipts',
    );
    expect(
      restored.latestStateDeploymentReceiptRef,
      contains('served_basis_deployment_receipts.restored.json'),
    );
    expect(
      restored.latestStateRecoveryDecisionArtifactRef,
      contains('basis_restore_decision.restored.json'),
    );
  });

  test('fails closed when promotion receipt lineage is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_missing_promotion_receipt_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 21, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    for (final family in const <String>[
      'app_observations',
      'runtime_os_locality_state',
      'governed_reality_model_outputs',
    ]) {
      final file =
          File(path.join(latestStateRoot.path, '$family.current.json'));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
          'environmentId': 'sav-replay-world-2024',
          'supportedPlaceRef': 'place:sav',
          'evidenceFamily': family,
          'selectionStatus': 'selected_current_evidence',
          'freshnessHours': 2,
          'strengthScore': 0.95,
          'receiptBacked': true,
        }),
      );
    }

    await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );

    final servedBasisFile = File(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'served_city_pack_basis.current.json',
      ),
    );
    final servedBasisPayload = Map<String, dynamic>.from(
      jsonDecode(servedBasisFile.readAsStringSync()) as Map<String, dynamic>,
    )..remove('latestStateRefreshReceiptRef');
    servedBasisFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(servedBasisPayload),
    );

    expect(
      () => service.promoteStagedLatestStateBasis(
        environmentId: 'sav-replay-world-2024',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('refresh-bound receipt lineage'),
        ),
      ),
    );
  });

  test('fails closed when restore receipt lineage is missing', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_missing_restore_receipt_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final intakeRepository = UniversalIntakeRepository();
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      intakeRepository: intakeRepository,
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 21, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence({
      required double freshnessHours,
      required double strengthScore,
      required bool receiptBacked,
    }) async {
      for (final family in const <String>[
        'app_observations',
        'runtime_os_locality_state',
        'governed_reality_model_outputs',
      ]) {
        final file =
            File(path.join(latestStateRoot.path, '$family.current.json'));
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': family,
            'selectionStatus': 'selected_current_evidence',
            'freshnessHours': freshnessHours,
            'strengthScore': strengthScore,
            'receiptBacked': receiptBacked,
          }),
        );
      }
    }

    await writeCurrentEvidence(
      freshnessHours: 3,
      strengthScore: 0.92,
      receiptBacked: true,
    );
    await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    await service.promoteStagedLatestStateBasis(
      environmentId: 'sav-replay-world-2024',
    );

    await writeCurrentEvidence(
      freshnessHours: 72,
      strengthScore: 0.42,
      receiptBacked: false,
    );
    await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );

    await writeCurrentEvidence(
      freshnessHours: 2,
      strengthScore: 0.95,
      receiptBacked: true,
    );
    await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );

    final servedBasisFile = File(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'served_city_pack_basis.current.json',
      ),
    );
    final servedBasisPayload = Map<String, dynamic>.from(
      jsonDecode(servedBasisFile.readAsStringSync()) as Map<String, dynamic>,
    )..remove('latestStateRevalidationReceiptRef');
    servedBasisFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(servedBasisPayload),
    );

    expect(
      () => service.restoreExpiredServedBasis(
        environmentId: 'sav-replay-world-2024',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('revalidation/promotion receipt lineage'),
        ),
      ),
    );
  });

  test(
      'revalidation keeps an expired served basis blocked when family policy action forbids recovery',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_basis_revalidation_policy_block_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final intakeRepository = UniversalIntakeRepository();
    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      intakeRepository: intakeRepository,
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 3, 21, 0),
    );

    await service.registerLabEnvironment(
      displayName: 'Savannah Simulation Environment 2024',
      cityCode: 'sav',
      replayYear: 2024,
      description: 'Registered from the world simulation lab.',
      localityDisplayNames: const <String, String>{
        'sav_waterfront': 'Savannah Waterfront',
      },
    );

    final latestStateRoot = Directory(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'latest_state',
      ),
    );

    Future<void> writeCurrentEvidence({
      required double freshnessHours,
      required double strengthScore,
      required bool receiptBacked,
    }) async {
      Future<void> writeFamily(String filename, String family) async {
        final file = File(path.join(latestStateRoot.path, filename));
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
            'environmentId': 'sav-replay-world-2024',
            'supportedPlaceRef': 'place:sav',
            'evidenceFamily': family,
            'selectionStatus': 'selected_current_evidence',
            'freshnessHours': freshnessHours,
            'strengthScore': strengthScore,
            'receiptBacked': receiptBacked,
          }),
        );
      }

      await writeFamily(
        'app_observations.current.json',
        'app_observations',
      );
      await writeFamily(
        'runtime_os_locality_state.current.json',
        'runtime_os_locality_state',
      );
      await writeFamily(
        'governed_reality_model_outputs.current.json',
        'governed_reality_model_outputs',
      );
    }

    await writeCurrentEvidence(
      freshnessHours: 3,
      strengthScore: 0.92,
      receiptBacked: true,
    );

    await service.stageLatestStateHydrationBasis(
      environmentId: 'sav-replay-world-2024',
    );
    await service.promoteStagedLatestStateBasis(
      environmentId: 'sav-replay-world-2024',
    );

    await writeCurrentEvidence(
      freshnessHours: 72,
      strengthScore: 0.42,
      receiptBacked: false,
    );
    await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );

    final servedBasisFile = File(
      path.join(
        tempDir.path,
        'AVRAI',
        'world_simulation_lab',
        'registered_environments',
        'sav-replay-world-2024',
        'served_city_pack_basis.current.json',
      ),
    );
    final servedBasisPayload = Map<String, dynamic>.from(
      jsonDecode(servedBasisFile.readAsStringSync()) as Map<String, dynamic>,
    )
      ..['latestStateEvidencePolicyActionsByFamily'] = <String, dynamic>{
        'app_observations': 'block_served_basis_recovery_for_family',
        'runtime_os_locality_state': 'no_action_family_stable',
        'governed_reality_model_outputs': 'no_action_family_stable',
      }
      ..['latestStateEvidencePolicyActionSummariesByFamily'] =
          <String, dynamic>{
        'app_observations':
            'app observations: block served-basis recovery until this family is restaged because it is repeatedly degrading and now approaching policy edge.',
      };
    servedBasisFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(servedBasisPayload),
    );

    await writeCurrentEvidence(
      freshnessHours: 2,
      strengthScore: 0.95,
      receiptBacked: true,
    );

    final blocked = await service.revalidatePromotedServedBasis(
      environmentId: 'sav-replay-world-2024',
    );
    expect(blocked.currentBasisStatus, 'expired_latest_state_served_basis');
    expect(
      blocked.latestStatePromotionReadiness,
      'restage_required_before_served_basis_reuse',
    );
    expect(
      blocked.hydrationFreshnessPosture,
      'family_policy_action_blocks_served_basis_recovery',
    );
    expect(
      blocked.latestStatePromotionBlockedReasons,
      contains(
        'app observations is repeatedly degrading and blocks served-basis recovery until fresher family inputs are restaged.',
      ),
    );
    expect(
      blocked.latestStateEvidenceRestageTargetsByFamily['app_observations'],
      'restage_input_family:app_observations',
    );
    expect(
      blocked.latestStateEvidenceRestageTargetSummariesByFamily[
          'app_observations'],
      'app observations: route to restage input family `app observations` because this family is awaiting first refresh transition and blocks served-basis recovery until fresher inputs are staged.',
    );
    final restageQueueItems = await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    );
    expect(restageQueueItems, hasLength(1));
    expect(restageQueueItems.single.evidenceFamily, 'app_observations');
    expect(
      restageQueueItems.single.restageTarget,
      'restage_input_family:app_observations',
    );
    expect(
      restageQueueItems.single.queueStatus,
      'queued_for_family_restage_review',
    );
    expect(File(restageQueueItems.single.itemJsonPath).existsSync(), isTrue);
    final hydratedSnapshot = await service.getSnapshot(
      environmentId: 'sav-replay-world-2024',
    );
    expect(
      hydratedSnapshot
          .foundation.metadata['latestStateEvidenceRestageReviewQueueCount'],
      1,
    );
    expect(
      hydratedSnapshot.foundation
          .metadata['latestStateEvidenceRestageReviewQueueSummaries'],
      contains(
        'app observations: queued for family restage review. app observations: route to restage input family `app observations` because this family is awaiting first refresh transition and blocks served-basis recovery until fresher inputs are staged.',
      ),
    );
    final requested = await service.requestLabFamilyRestageIntake(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
    );
    expect(requested.queueStatus, 'restage_intake_requested');
    expect(
      requested.queueDecisionArtifactRef,
      contains(
        'family_restage_review_decision.restage_intake_requested.json',
      ),
    );
    expect(
      requested.restageIntakeQueueJsonPath,
      contains('family_restage_intake_review.current.json'),
    );
    expect(requested.restageIntakeReviewItemId, isNotNull);
    expect(File(requested.restageIntakeQueueJsonPath!).existsSync(), isTrue);
    final intakeSources = await intakeRepository.getAllSources();
    final intakeReviews = await intakeRepository.getAllReviewItems();
    expect(intakeSources, hasLength(1));
    expect(intakeReviews, hasLength(1));
    expect(
      intakeReviews.single.payload['evidenceFamily'],
      'app_observations',
    );
    expect(File(requested.itemJsonPath).existsSync(), isTrue);
    final deferred = await service.deferLabFamilyRestageReview(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
    );
    expect(deferred.queueStatus, 'watch_family_before_restage');
    expect(
      deferred.queueDecisionArtifactRef,
      contains(
        'family_restage_review_decision.watch_family_before_restage.json',
      ),
    );
    expect(
      deferred.restageIntakeReviewItemId,
      requested.restageIntakeReviewItemId,
    );
    final resolved = await service.recordLabFamilyRestageIntakeReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_intake_resolution.approved.json',
    );
    expect(resolved.queueStatus, 'restage_intake_review_approved');
    expect(resolved.restageIntakeResolutionStatus, 'approved');
    expect(
      resolved.restageIntakeResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_intake_resolution.approved.json',
    );
    expect(
      resolved.restageIntakeResolutionRationale,
      'Approved bounded family restage intake review for this evidence family.',
    );
    final persistedResolved = (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
        .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(persistedResolved.queueStatus, 'restage_intake_review_approved');
    expect(persistedResolved.restageIntakeResolutionStatus, 'approved');
    expect(
      persistedResolved.followUpQueueStatus,
      'queued_for_family_restage_follow_up_review',
    );
    expect(
      persistedResolved.followUpReviewItemId,
      contains('family_restage_follow_up_review_sav-replay-world-2024'),
    );
    expect(
      persistedResolved.followUpQueueJsonPath,
      contains('family_restage_follow_up_review.current.json'),
    );
    final followUpSources = await intakeRepository.getAllSources();
    final followUpReviews = await intakeRepository.getAllReviewItems();
    expect(followUpSources, hasLength(2));
    expect(followUpReviews, hasLength(2));
    expect(
      followUpReviews.map((entry) => entry.payload['status']).toSet(),
      contains('queued_for_family_restage_follow_up_review'),
    );
    final followUpResolved =
        await service.recordLabFamilyRestageFollowUpReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_follow_up_resolution.approved.json',
    );
    expect(followUpResolved.followUpResolutionStatus, 'approved');
    expect(
      followUpResolved.followUpResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_follow_up_resolution.approved.json',
    );
    final persistedFollowUpResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(persistedFollowUpResolved.followUpResolutionStatus, 'approved');
    expect(
      persistedFollowUpResolved.followUpResolutionArtifactRef,
      contains('family_restage_follow_up_resolution.approved.json'),
    );
    expect(
      persistedFollowUpResolved.restageResolutionQueueStatus,
      'queued_for_family_restage_resolution_review',
    );
    expect(
      persistedFollowUpResolved.restageResolutionReviewItemId,
      contains('family_restage_resolution_review_sav-replay-world-2024'),
    );
    expect(
      persistedFollowUpResolved.restageResolutionQueueJsonPath,
      contains('family_restage_resolution_review.current.json'),
    );
    final resolutionResolved =
        await service.recordLabFamilyRestageResolutionReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_resolution.approved.json',
    );
    expect(
      resolutionResolved.restageResolutionResolutionStatus,
      'approved_for_bounded_family_restage_execution',
    );
    expect(
      resolutionResolved.restageResolutionResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_resolution.approved.json',
    );
    final persistedResolutionResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(
      persistedResolutionResolved.restageResolutionResolutionStatus,
      'approved_for_bounded_family_restage_execution',
    );
    expect(
      persistedResolutionResolved.restageResolutionResolutionArtifactRef,
      contains('family_restage_resolution.approved.json'),
    );
    expect(
      persistedResolutionResolved.restageExecutionQueueStatus,
      'queued_for_family_restage_execution_review',
    );
    expect(
      persistedResolutionResolved.restageExecutionReviewItemId,
      contains('family_restage_execution_review_sav-replay-world-2024'),
    );
    expect(
      persistedResolutionResolved.restageExecutionQueueJsonPath,
      contains('family_restage_execution_review.current.json'),
    );
    final executionResolved =
        await service.recordLabFamilyRestageExecutionReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_execution.approved.json',
    );
    expect(
      executionResolved.restageExecutionResolutionStatus,
      'approved_for_bounded_family_restage_application',
    );
    expect(
      executionResolved.restageExecutionResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_execution.approved.json',
    );
    final persistedExecutionResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(
      persistedExecutionResolved.restageExecutionResolutionStatus,
      'approved_for_bounded_family_restage_application',
    );
    expect(
      persistedExecutionResolved.restageExecutionResolutionArtifactRef,
      contains('family_restage_execution.approved.json'),
    );
    expect(
      persistedExecutionResolved.restageApplicationQueueStatus,
      'queued_for_family_restage_application_review',
    );
    expect(
      persistedExecutionResolved.restageApplicationReviewItemId,
      contains('family_restage_application_review_sav-replay-world-2024'),
    );
    expect(
      persistedExecutionResolved.restageApplicationQueueJsonPath,
      contains('family_restage_application_review.current.json'),
    );
    final applicationResolved =
        await service.recordLabFamilyRestageApplicationReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_application.approved.json',
    );
    expect(
      applicationResolved.restageApplicationResolutionStatus,
      'approved_for_bounded_family_restage_apply_to_served_basis',
    );
    expect(
      applicationResolved.restageApplicationResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_application.approved.json',
    );
    final persistedApplicationResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(
      persistedApplicationResolved.restageApplicationResolutionStatus,
      'approved_for_bounded_family_restage_apply_to_served_basis',
    );
    expect(
      persistedApplicationResolved.restageApplicationResolutionArtifactRef,
      contains('family_restage_application.approved.json'),
    );
    expect(
      persistedApplicationResolved.restageApplyQueueStatus,
      'queued_for_family_restage_apply_review',
    );
    expect(
      persistedApplicationResolved.restageApplyReviewItemId,
      contains('family_restage_apply_review_sav-replay-world-2024'),
    );
    expect(
      persistedApplicationResolved.restageApplyQueueJsonPath,
      contains('family_restage_apply_review.current.json'),
    );
    final applyResolved =
        await service.recordLabFamilyRestageApplyReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_apply.approved.json',
    );
    expect(
      applyResolved.restageApplyResolutionStatus,
      'approved_for_bounded_family_restage_served_basis_update',
    );
    expect(
      applyResolved.restageApplyResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_apply.approved.json',
    );
    final persistedApplyResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(
      persistedApplyResolved.restageApplyResolutionStatus,
      'approved_for_bounded_family_restage_served_basis_update',
    );
    expect(
      persistedApplyResolved.restageApplyResolutionArtifactRef,
      contains('family_restage_apply.approved.json'),
    );
    expect(
      persistedApplyResolved.restageServedBasisUpdateQueueStatus,
      'queued_for_family_restage_served_basis_update_review',
    );
    expect(
      persistedApplyResolved.restageServedBasisUpdateReviewItemId,
      contains(
        'family_restage_served_basis_update_review_sav-replay-world-2024',
      ),
    );
    expect(
      persistedApplyResolved.restageServedBasisUpdateQueueJsonPath,
      contains('family_restage_served_basis_update_review.current.json'),
    );
    final servedBasisUpdateResolved =
        await service.recordLabFamilyRestageServedBasisUpdateReviewResolution(
      environmentId: 'sav-replay-world-2024',
      evidenceFamily: 'app_observations',
      resolutionStatus: 'approved',
      resolutionArtifactRef:
          '${requested.itemRoot}/family_restage_served_basis_update.approved.json',
    );
    expect(
      servedBasisUpdateResolved.restageServedBasisUpdateResolutionStatus,
      'approved_for_bounded_family_restage_served_basis_mutation',
    );
    expect(
      servedBasisUpdateResolved.restageServedBasisUpdateResolutionArtifactRef,
      '${requested.itemRoot}/family_restage_served_basis_update.approved.json',
    );
    final persistedServedBasisUpdateResolved =
        (await service.listLabFamilyRestageReviewItems(
      environmentId: 'sav-replay-world-2024',
      limit: 0,
    ))
            .singleWhere((entry) => entry.evidenceFamily == 'app_observations');
    expect(
      persistedServedBasisUpdateResolved
          .restageServedBasisUpdateResolutionStatus,
      'approved_for_bounded_family_restage_served_basis_mutation',
    );
    expect(
      persistedServedBasisUpdateResolved
          .restageServedBasisUpdateResolutionArtifactRef,
      contains('family_restage_served_basis_update.approved.json'),
    );
    expect(blocked.latestStateRevalidationStatus, 'expired');
  });

  test('exports a local learning bundle with request previews', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_bundle_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[
        SyntheticReplaySimulationAdminEnvironmentAdapter(
          descriptor: ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'atx-replay-world-2024',
            displayName: 'Austin Simulation Environment 2024',
            cityCode: 'atx',
            replayYear: 2024,
            cityPackManifestRef: 'city_packs/atx/2024_manifest.json',
          ),
          localityDisplayNames: <String, String>{
            'atx_downtown': 'Downtown Austin',
            'atx_east_side': 'East Side',
          },
        ),
      ],
      defaultEnvironmentId: 'atx-replay-world-2024',
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      documentsDirectoryProvider: () async => tempDir,
    );

    final export = await service.exportLearningBundle();
    expect(export.environmentId, 'atx-replay-world-2024');
    expect(File(export.snapshotJsonPath).existsSync(), isTrue);
    expect(File(export.learningBundleJsonPath).existsSync(), isTrue);
    expect(File(export.realityModelRequestJsonPath).existsSync(), isTrue);
    expect(File(export.readmePath).existsSync(), isTrue);
    final readmeContents = File(export.readmePath).readAsStringSync();
    expect(
      readmeContents,
      contains('Refresh mode: `versioned living city-pack`'),
    );
    expect(
      readmeContents,
      contains('Hydration status: `awaiting latest AVRAI evidence refresh`'),
    );
    expect(
      readmeContents,
      contains(
        'Latest-state evidence families: app observations, runtime/OS locality state, governed reality-model outputs',
      ),
    );
  });

  test('records accepted and denied world simulation lab outcomes locally',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_lab_outcome_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final strongSnapshot = ReplaySimulationAdminSnapshot(
      generatedAt: DateTime.utc(2026, 4, 1, 12),
      environmentId: 'sav-replay-world-2024',
      cityCode: 'sav',
      replayYear: 2024,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
      foundation: const ReplaySimulationAdminFoundationSummary(
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
        metadata: <String, dynamic>{
          'cityPackStructuralRef': 'city_pack:sav_core_2024',
        },
      ),
      learningReadiness: const ReplaySimulationLearningReadiness(
        trainingGrade: 'review',
        shareWithRealityModelAllowed: false,
        suggestedTrainingUse: 'simulation_debug_only',
      ),
      syntheticHumanKernelExplorer:
          ReplaySimulationSyntheticHumanKernelExplorer(
        entries: <ReplaySimulationSyntheticHumanKernelEntry>[
          ReplaySimulationSyntheticHumanKernelEntry(
            actorId: 'synthetic:sav:waterfront:lane:1',
            displayName: 'Savannah Waterfront Representative Lane',
            localityAnchor: 'waterfront',
            attachedKernelIds: const <String>[
              'kernel.mobility.routing',
              'kernel.event.pressure',
            ],
            readyKernelIds: const <String>['kernel.event.pressure'],
            missingKernelIds: const <String>['kernel.mobility.routing'],
            notReadyKernelIds: const <String>['kernel.mobility.routing'],
            activationCountByKernel: const <String, int>{
              'kernel.mobility.routing': 2,
              'kernel.event.pressure': 6,
            },
            higherAgentGuidanceCount: 2,
          ),
        ],
      ),
      localityHierarchyHealth: const ReplaySimulationLocalityHierarchyHealth(
        nodes: <ReplaySimulationLocalityHierarchyNodeSummary>[
          ReplaySimulationLocalityHierarchyNodeSummary(
            localityCode: 'sav_waterfront',
            displayName: 'Savannah Waterfront',
            pressureBand: 'high',
            attentionBand: 'escalate',
            primarySignals: <String>['freight detour'],
            branchSensitivity: 0.47,
            contradictionCount: 2,
            effectiveness: 'stressed',
            risk: 'high',
            summary:
                'Savannah Waterfront remains stressed and should stay in bounded review.',
          ),
        ],
      ),
      higherAgentHandoffView: const ReplaySimulationHigherAgentHandoffView(
        items: <ReplaySimulationHigherAgentHandoffItem>[
          ReplaySimulationHigherAgentHandoffItem(
            scope: 'locality',
            targetLabel: 'Savannah Waterfront',
            status: 'review_only',
            summary:
                'Keep Savannah Waterfront inside bounded review until contradiction pressure falls.',
          ),
        ],
      ),
      realismProvenance: const ReplaySimulationRealismProvenanceSummary(
        simulationMode: 'generic_city_pack',
        cityPackStructuralRef: 'city_pack:sav_core_2024',
        populationModelKind: 'scenario_seeded_synthetic_city',
        modeledUserLayerKind: 'representative_synthetic_human_lanes',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>['city_packs/sav/2024_manifest.json'],
        trainingArtifactFamilies: <String>[
          'simulation_snapshot',
          'learning_bundle',
        ],
      ),
    );

    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
          snapshot: strongSnapshot,
        ),
      ],
      defaultEnvironmentId: 'sav-replay-world-2024',
      nowProvider: () => DateTime.utc(2026, 4, 1, 12),
      documentsDirectoryProvider: () async => tempDir,
    );

    final denied = await service.recordLabOutcome(
      disposition: ReplaySimulationLabDisposition.denied,
      operatorRationale: 'Storm corridor setup produced contradiction churn.',
      operatorNotes: const <String>[
        'Reduce coupled route-block intensity.',
        'Split weather and staffing shocks into separate runs.',
      ],
    );

    expect(denied.disposition, ReplaySimulationLabDisposition.denied);
    expect(denied.cityPackStructuralRef, 'city_pack:sav_core_2024');
    expect(File(denied.outcomeJsonPath).existsSync(), isTrue);
    expect(File(denied.readmePath).existsSync(), isTrue);

    final acceptedService = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
          snapshot: strongSnapshot,
        ),
      ],
      defaultEnvironmentId: 'sav-replay-world-2024',
      nowProvider: () => DateTime.utc(2026, 4, 1, 13),
      documentsDirectoryProvider: () async => tempDir,
    );

    final accepted = await acceptedService.recordLabOutcome(
      disposition: ReplaySimulationLabDisposition.accepted,
      operatorRationale:
          'Updated intervention mix is stable enough for learning review.',
    );

    expect(accepted.disposition, ReplaySimulationLabDisposition.accepted);
    expect(accepted.cityPackStructuralRef, 'city_pack:sav_core_2024');
    expect(accepted.syntheticHumanKernelEntries, isNotEmpty);
    expect(
      accepted.syntheticHumanKernelEntries.first.activationCountByKernel,
      isNotEmpty,
    );
    expect(accepted.localityHierarchyNodes, isNotEmpty);
    expect(accepted.higherAgentHandoffItems, isNotEmpty);
    expect(accepted.realismProvenance.sidecarRefs, isNotEmpty);
    expect(File(accepted.outcomeJsonPath).existsSync(), isTrue);

    final history = await acceptedService.listLabOutcomes(
      environmentId: 'sav-replay-world-2024',
      limit: 8,
    );
    expect(history, hasLength(2));
    expect(history.first.cityPackStructuralRef, 'city_pack:sav_core_2024');
    expect(history.first.disposition, ReplaySimulationLabDisposition.accepted);
    expect(history.first.syntheticHumanKernelEntries, isNotEmpty);
    expect(history.first.localityHierarchyNodes, isNotEmpty);
    expect(history.first.higherAgentHandoffItems, isNotEmpty);
    expect(history.first.realismProvenance.sidecarRefs, isNotEmpty);
    expect(history.last.disposition, ReplaySimulationLabDisposition.denied);
  });

  test(
      'stages bounded supervisor observations from replay lab outcomes and target-action decisions',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_supervisor_observation_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final snapshot = ReplaySimulationAdminSnapshot(
      generatedAt: DateTime.utc(2026, 4, 1, 12),
      environmentId: 'sav-replay-world-2024',
      cityCode: 'sav',
      replayYear: 2024,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: <ReplayLocalityOverlaySnapshot>[
        ReplayLocalityOverlaySnapshot(
          localityCode: 'sav_waterfront',
          displayName: 'Savannah Waterfront',
          pressureBand: 'high',
          attentionBand: 'watch',
          primarySignals: <String>['stable intervention mix'],
          contradictionCount: 0,
          branchSensitivity: 0.2,
          updatedAt: DateTime.utc(2026, 4, 1, 12),
        ),
      ],
      foundation: const ReplaySimulationAdminFoundationSummary(
        simulationMode: 'generic_city_pack',
      ),
      learningReadiness: const ReplaySimulationLearningReadiness(
        trainingGrade: 'strong',
        shareWithRealityModelAllowed: true,
        suggestedTrainingUse: 'candidate_deeper_reality_model_training',
      ),
    );

    final upwardRepository = UniversalIntakeRepository();
    final governedUpwardLearningIntakeService =
        GovernedUpwardLearningIntakeService(
      intakeRepository: upwardRepository,
      atomicClockService: AtomicClockService(),
    );

    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'sav-replay-world-2024',
            displayName: 'Savannah Simulation Environment 2024',
            cityCode: 'sav',
            replayYear: 2024,
          ),
          snapshot: snapshot,
        ),
      ],
      defaultEnvironmentId: 'sav-replay-world-2024',
      governedUpwardLearningIntakeService: governedUpwardLearningIntakeService,
      nowProvider: () => DateTime.utc(2026, 4, 1, 12),
      documentsDirectoryProvider: () async => tempDir,
    );

    await service.recordLabOutcome(
      disposition: ReplaySimulationLabDisposition.accepted,
      operatorRationale: 'Stable enough for learning review.',
    );

    await service.recordLabTargetActionDecision(
      environmentId: 'sav-replay-world-2024',
      suggestedAction: 'candidate_for_bounded_review',
      suggestedReason: 'Simulation looks stable and explainable.',
      selectedAction: 'watch_closely',
    );

    final reviews = await upwardRepository.getAllReviewItems();
    expect(reviews, hasLength(2));
    final channels = reviews
        .map((item) => item.payload['channel']?.toString())
        .whereType<String>()
        .toSet();
    expect(channels.contains('replay_simulation_lab_outcome'), isTrue);
    expect(
      channels.contains('replay_simulation_lab_target_action_decision'),
      isTrue,
    );
    for (final review in reviews) {
      expect(
        review.payload['sourceKind'],
        'supervisor_bounded_observation_intake',
      );
      expect(review.payload['airGapArtifact'], isA<Map<String, dynamic>>());
    }

    final sources = await upwardRepository.getAllSources();
    expect(sources, hasLength(2));
    expect(
      sources.every(
        (source) =>
            source.sourceProvider == 'supervisor_bounded_observation_intake',
      ),
      isTrue,
    );
  });

  test('saves variant drafts and carries variant lineage into lab outcomes',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_variant_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 1, 16),
    );

    await service.registerLabEnvironment(
      displayName: 'Austin Simulation Environment 2024',
      cityCode: 'atx',
      replayYear: 2024,
      localityDisplayNames: const <String, String>{
        'atx_downtown': 'Downtown Austin',
        'atx_east': 'East Austin',
      },
    );

    final variant = await service.saveLabVariant(
      environmentId: 'atx-replay-world-2024',
      label: 'Waterfront detour',
      hypothesis: 'Shift route pressure away from the lead locality.',
      localityCodes: const <String>['atx_downtown'],
      operatorNotes: const <String>['Retest with heavier attendance surge.'],
    );
    final variants = await service.listLabVariants(
      environmentId: 'atx-replay-world-2024',
    );
    expect(variants, hasLength(1));
    expect(variants.single.label, 'Waterfront detour');

    final outcome = await service.recordLabOutcome(
      environmentId: 'atx-replay-world-2024',
      disposition: ReplaySimulationLabDisposition.accepted,
      operatorRationale: 'This variant is stable enough for learning review.',
      variantId: variant.variantId,
      variantLabel: variant.label,
    );

    expect(outcome.variantId, variant.variantId);
    expect(outcome.variantLabel, 'Waterfront detour');
    expect(outcome.cityPackStructuralRef, 'city_pack:atx_core_2024');

    final history = await service.listLabOutcomes(
      environmentId: 'atx-replay-world-2024',
    );
    expect(history, hasLength(1));
    expect(history.single.cityPackStructuralRef, 'city_pack:atx_core_2024');
    expect(history.single.variantLabel, 'Waterfront detour');
  });

  test('queues rerun requests with persisted target lineage', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_rerun_request_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 1, 17),
    );

    await service.registerLabEnvironment(
      displayName: 'Austin Simulation Environment 2024',
      cityCode: 'atx',
      replayYear: 2024,
      localityDisplayNames: const <String, String>{
        'atx_downtown': 'Downtown Austin',
        'atx_east': 'East Austin',
      },
    );

    final variant = await service.saveLabVariant(
      environmentId: 'atx-replay-world-2024',
      label: 'Waterfront detour',
      hypothesis: 'Shift route pressure away from the lead locality.',
      localityCodes: const <String>['atx_downtown'],
      operatorNotes: const <String>['Retest with heavier attendance surge.'],
    );
    await service.setActiveLabVariantTarget(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
    );

    final outcome = await service.recordLabOutcome(
      environmentId: 'atx-replay-world-2024',
      disposition: ReplaySimulationLabDisposition.denied,
      operatorRationale: 'This variant still produces contradiction churn.',
    );
    await service.recordLabTargetActionDecision(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      suggestedAction: 'candidate_for_bounded_review',
      suggestedReason:
          'Runtime drift is bounded and the latest labeled outcome is no longer blocked by denial memory.',
      selectedAction: 'watch_closely',
    );

    final request = await service.createLabRerunRequest(
      environmentId: 'atx-replay-world-2024',
      requestNotes: const <String>[
        'Retest with reduced pressure.',
        'Compare latest denial against prior run.',
      ],
    );

    expect(request.variantId, variant.variantId);
    expect(request.variantLabel, variant.label);
    expect(request.lineageDisposition, 'denied');
    expect(request.lineageOutcomeJsonPath, outcome.outcomeJsonPath);
    expect(request.targetActionSuggested, 'candidate_for_bounded_review');
    expect(request.targetActionSelected, 'watch_closely');
    expect(request.targetActionAcceptedSuggestion, isFalse);
    expect(File(request.requestJsonPath).existsSync(), isTrue);
    expect(File(request.readmePath).existsSync(), isTrue);
    expect(
      File(request.readmePath).readAsStringSync(),
      contains('## Target Action Routing'),
    );
    expect(
      File(request.readmePath).readAsStringSync(),
      contains('`watch_closely`'),
    );

    final requests = await service.listLabRerunRequests(
      environmentId: 'atx-replay-world-2024',
    );
    expect(requests, hasLength(1));
    expect(requests.single.cityPackStructuralRef, 'city_pack:atx_core_2024');
    expect(requests.single.requestStatus, 'queued');

    final job = await service.executeLabRerunRequest(
      environmentId: 'atx-replay-world-2024',
      requestId: request.requestId,
    );
    expect(job.jobStatus, 'completed');
    expect(job.startedAt, isNotNull);
    expect(job.completedAt, isNotNull);
    expect(job.snapshotJsonPath, isNotNull);
    expect(job.learningBundleJsonPath, isNotNull);
    expect(job.syntheticHumanKernelEntries, isNotEmpty);
    expect(job.localityHierarchyNodes, isNotEmpty);
    expect(job.higherAgentHandoffItems, isNotEmpty);
    expect(job.realismProvenance.sidecarRefs, isNotEmpty);
    expect(File(job.jobJsonPath).existsSync(), isTrue);
    expect(File(job.readmePath).existsSync(), isTrue);
    expect(File(job.snapshotJsonPath!).existsSync(), isTrue);

    final persisted = await service.listLabRerunRequests(
      environmentId: 'atx-replay-world-2024',
    );
    expect(persisted.single.requestStatus, 'completed');
    expect(persisted.single.startedAt, isNotNull);
    expect(persisted.single.completedAt, isNotNull);
    expect(persisted.single.latestJobId, job.jobId);
    expect(persisted.single.latestJobStatus, 'completed');
    expect(persisted.single.latestJobSnapshotJsonPath, job.snapshotJsonPath);

    final jobs = await service.listLabRerunJobs(
      environmentId: 'atx-replay-world-2024',
      requestId: request.requestId,
    );
    expect(jobs, hasLength(1));
    expect(jobs.single.jobId, job.jobId);
    expect(jobs.single.jobStatus, 'completed');
    expect(jobs.single.syntheticHumanKernelEntries, isNotEmpty);
    expect(jobs.single.localityHierarchyNodes, isNotEmpty);
    expect(jobs.single.higherAgentHandoffItems, isNotEmpty);
    expect(jobs.single.realismProvenance.sidecarRefs, isNotEmpty);
  });

  test('acknowledges bounded alerts without changing target routing posture',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_alert_ack_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 2, 11, 30),
    );

    await service.registerLabEnvironment(
      displayName: 'Austin Simulation Environment 2024',
      cityCode: 'atx',
      replayYear: 2024,
      localityDisplayNames: const <String, String>{
        'atx_downtown': 'Downtown Austin',
      },
    );

    final variant = await service.saveLabVariant(
      environmentId: 'atx-replay-world-2024',
      label: 'Downtown calibration lane',
      hypothesis: 'Reduce realism-pack churn before bounded review.',
      localityCodes: const <String>['atx_downtown'],
      operatorNotes: const <String>['Track provenance churn carefully.'],
    );

    await service.recordLabTargetActionDecision(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      suggestedAction: 'candidate_for_bounded_review',
      suggestedReason:
          'Runtime instability is bounded but still needs one more watched pass.',
      selectedAction: 'watch_closely',
    );

    final updatedState = await service.acknowledgeLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      alertSeverityCode: 'watch',
    );

    final decision = updatedState.targetActionDecisions.single;
    expect(decision.variantId, variant.variantId);
    expect(decision.selectedAction, 'watch_closely');
    expect(decision.acceptedSuggestion, isFalse);
    expect(decision.alertAcknowledgedAt, DateTime.utc(2026, 4, 2, 11, 30));
    expect(decision.alertAcknowledgedSeverityCode, 'watch');

    final persisted = await service.getLabRuntimeState(
      environmentId: 'atx-replay-world-2024',
    );
    final persistedDecision = persisted.targetActionDecisions.single;
    expect(persistedDecision.variantId, variant.variantId);
    expect(persistedDecision.selectedAction, 'watch_closely');
    expect(persistedDecision.acceptedSuggestion, isFalse);
    expect(
      persistedDecision.alertAcknowledgedAt,
      DateTime.utc(2026, 4, 2, 11, 30),
    );
    expect(persistedDecision.alertAcknowledgedSeverityCode, 'watch');
  });

  test(
      'persists and clears escalated or snoozed alert state without changing routing posture',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_alert_state_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final service = ReplaySimulationAdminService(
      environmentAdapters: const <ReplaySimulationAdminEnvironmentAdapter>[],
      documentsDirectoryProvider: () async => tempDir,
      nowProvider: () => DateTime.utc(2026, 4, 2, 12),
    );

    await service.registerLabEnvironment(
      displayName: 'Austin Simulation Environment 2024',
      cityCode: 'atx',
      replayYear: 2024,
      localityDisplayNames: const <String, String>{
        'atx_downtown': 'Downtown Austin',
      },
    );

    final variant = await service.saveLabVariant(
      environmentId: 'atx-replay-world-2024',
      label: 'Downtown calibration lane',
      hypothesis: 'Watch realism-pack churn before bounded review.',
      localityCodes: const <String>['atx_downtown'],
      operatorNotes: const <String>['Escalate if instability persists.'],
    );

    await service.recordLabTargetActionDecision(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      suggestedAction: 'candidate_for_bounded_review',
      suggestedReason: 'Still within watch posture.',
      selectedAction: 'watch_closely',
    );

    final escalatedState = await service.escalateLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      alertSeverityCode: 'watch',
    );
    final escalatedDecision = escalatedState.targetActionDecisions.single;
    expect(escalatedDecision.selectedAction, 'watch_closely');
    expect(escalatedDecision.alertEscalatedAt, DateTime.utc(2026, 4, 2, 12));
    expect(escalatedDecision.alertEscalatedSeverityCode, 'watch');
    expect(escalatedDecision.alertSnoozedUntil, isNull);
    expect(escalatedDecision.alertSnoozedSeverityCode, isNull);

    final snoozedState = await service.snoozeLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      alertSeverityCode: 'watch',
      snoozedUntilUtc: DateTime.utc(2026, 4, 3, 12),
    );
    final snoozedDecision = snoozedState.targetActionDecisions.single;
    expect(snoozedDecision.selectedAction, 'watch_closely');
    expect(snoozedDecision.alertEscalatedAt, isNull);
    expect(snoozedDecision.alertEscalatedSeverityCode, isNull);
    expect(snoozedDecision.alertSnoozedUntil, DateTime.utc(2026, 4, 3, 12));
    expect(snoozedDecision.alertSnoozedSeverityCode, 'watch');

    final unsnoozedState = await service.unsnoozeLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
    );
    final unsnoozedDecision = unsnoozedState.targetActionDecisions.single;
    expect(unsnoozedDecision.selectedAction, 'watch_closely');
    expect(unsnoozedDecision.alertEscalatedAt, isNull);
    expect(unsnoozedDecision.alertEscalatedSeverityCode, isNull);
    expect(unsnoozedDecision.alertSnoozedUntil, isNull);
    expect(unsnoozedDecision.alertSnoozedSeverityCode, isNull);

    final reEscalatedState = await service.escalateLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
      alertSeverityCode: 'watch',
    );
    expect(
      reEscalatedState.targetActionDecisions.single.alertEscalatedAt,
      DateTime.utc(2026, 4, 2, 12),
    );

    final clearedEscalationState = await service.clearEscalatedLabTargetAlert(
      environmentId: 'atx-replay-world-2024',
      variantId: variant.variantId,
    );
    final clearedEscalationDecision =
        clearedEscalationState.targetActionDecisions.single;
    expect(clearedEscalationDecision.selectedAction, 'watch_closely');
    expect(clearedEscalationDecision.alertEscalatedAt, isNull);
    expect(clearedEscalationDecision.alertEscalatedSeverityCode, isNull);
    expect(clearedEscalationDecision.alertSnoozedUntil, isNull);
    expect(clearedEscalationDecision.alertSnoozedSeverityCode, isNull);

    final persisted = await service.getLabRuntimeState(
      environmentId: 'atx-replay-world-2024',
    );
    final persistedDecision = persisted.targetActionDecisions.single;
    expect(persistedDecision.selectedAction, 'watch_closely');
    expect(persistedDecision.alertEscalatedAt, isNull);
    expect(persistedDecision.alertEscalatedSeverityCode, isNull);
    expect(persistedDecision.alertSnoozedUntil, isNull);
    expect(persistedDecision.alertSnoozedSeverityCode, isNull);
  });

  test('shares a strong simulation bundle with the reality model locally',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_share_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final strongSnapshot = ReplaySimulationAdminSnapshot(
      generatedAt: DateTime.utc(2026, 3, 31, 20),
      environmentId: 'generic-strong-env',
      cityCode: 'atx',
      replayYear: 2024,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
      foundation: const ReplaySimulationAdminFoundationSummary(
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
      ),
      learningReadiness: ReplaySimulationLearningReadiness(
        trainingGrade: 'strong',
        shareWithRealityModelAllowed: true,
        reasons: const <String>['Simulation is bounded and ready.'],
        suggestedTrainingUse: 'candidate_deeper_reality_model_training',
        requestPreviews: <ReplaySimulationRealityModelRequestPreview>[
          ReplaySimulationRealityModelRequestPreview(
            request: RealityModelEvaluationRequest(
              requestId: 'share-1',
              subjectId: 'simulation:atx_downtown',
              domain: RealityModelDomain.locality,
              candidateRef: 'locality:atx_downtown',
              localityCode: 'atx_downtown',
              cityCode: 'atx',
              signalTags: const <String>[
                'simulation_bundle',
                'locality_overlay'
              ],
              evidenceRefs: const <String>[
                'simulation_snapshot.json#overlay:atx_downtown',
              ],
              requestedAtUtc: DateTime.utc(2026, 3, 31, 20),
            ),
            rationale: 'Review the lead locality as bounded evidence.',
          ),
        ],
      ),
    );

    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'generic-strong-env',
            displayName: 'Generic Strong Env',
            cityCode: 'atx',
            replayYear: 2024,
          ),
          snapshot: strongSnapshot,
        ),
      ],
      defaultEnvironmentId: 'generic-strong-env',
      realityModelPort: DefaultRealityModelPort(),
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      documentsDirectoryProvider: () async => tempDir,
    );

    final report = await service.shareLearningBundleWithRealityModel();
    expect(report.environmentId, 'generic-strong-env');
    expect(report.requestCount, 1);
    expect(File(report.reviewJsonPath).existsSync(), isTrue);
  });

  test('fails closed when a simulation is not ready for reality-model sharing',
      () async {
    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'generic-review-env',
            displayName: 'Generic Review Env',
            cityCode: 'atx',
            replayYear: 2024,
          ),
          snapshot: ReplaySimulationAdminSnapshot(
            generatedAt: DateTime.utc(2026, 3, 31, 20),
            environmentId: 'generic-review-env',
            cityCode: 'atx',
            replayYear: 2024,
            scenarios: const <ReplayScenarioPacket>[],
            comparisons: const <ReplayScenarioComparison>[],
            receipts: const <SimulationTruthReceipt>[],
            contradictions: const <ReplayContradictionSnapshot>[],
            localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
            learningReadiness: const ReplaySimulationLearningReadiness(
              trainingGrade: 'review',
              shareWithRealityModelAllowed: false,
            ),
          ),
        ),
      ],
      defaultEnvironmentId: 'generic-review-env',
    );

    await expectLater(
      service.shareLearningBundleWithRealityModel(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('not ready for reality-model sharing'),
        ),
      ),
    );
  });

  test('stages a deeper training candidate manifest locally', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_training_candidate_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final strongSnapshot = ReplaySimulationAdminSnapshot(
      generatedAt: DateTime.utc(2026, 3, 31, 20),
      environmentId: 'generic-training-env',
      cityCode: 'atx',
      replayYear: 2024,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
      foundation: const ReplaySimulationAdminFoundationSummary(
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
      ),
      learningReadiness: ReplaySimulationLearningReadiness(
        trainingGrade: 'strong',
        shareWithRealityModelAllowed: true,
        reasons: const <String>['Simulation is bounded and ready.'],
        suggestedTrainingUse: 'candidate_deeper_reality_model_training',
        requestPreviews: <ReplaySimulationRealityModelRequestPreview>[
          ReplaySimulationRealityModelRequestPreview(
            request: RealityModelEvaluationRequest(
              requestId: 'training-share-1',
              subjectId: 'simulation:atx_downtown',
              domain: RealityModelDomain.locality,
              candidateRef: 'locality:atx_downtown',
              localityCode: 'atx_downtown',
              cityCode: 'atx',
              signalTags: const <String>[
                'simulation_bundle',
                'locality_overlay'
              ],
              evidenceRefs: const <String>[
                'simulation_snapshot.json#overlay:atx_downtown',
              ],
              requestedAtUtc: DateTime.utc(2026, 3, 31, 20),
            ),
            rationale: 'Review the lead locality as bounded evidence.',
          ),
        ],
      ),
    );

    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'generic-training-env',
            displayName: 'Generic Training Env',
            cityCode: 'atx',
            replayYear: 2024,
          ),
          snapshot: strongSnapshot,
        ),
      ],
      defaultEnvironmentId: 'generic-training-env',
      realityModelPort: DefaultRealityModelPort(),
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      documentsDirectoryProvider: () async => tempDir,
    );

    final export = await service.stageDeeperTrainingCandidate();
    expect(export.environmentId, 'generic-training-env');
    expect(File(export.trainingManifestJsonPath).existsSync(), isTrue);
    expect(File(export.readmePath).existsSync(), isTrue);
  });

  test('queues a deeper training intake locally and mirrors into intake review',
      () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'replay_sim_training_intake_test_',
    );
    addTearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    final strongSnapshot = ReplaySimulationAdminSnapshot(
      generatedAt: DateTime.utc(2026, 3, 31, 20),
      environmentId: 'generic-intake-env',
      cityCode: 'atx',
      replayYear: 2024,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
      foundation: const ReplaySimulationAdminFoundationSummary(
        simulationMode: 'generic_city_pack',
        intakeFlowRefs: <String>['source_intake_orchestrator'],
        sidecarRefs: <String>['city_packs/atx/2024_manifest.json'],
        trainingArtifactFamilies: <String>['replay_learning_bundle'],
        metadata: <String, dynamic>{
          'cityPackStructuralRef': 'city_pack:atx_core_2024',
        },
        kernelStates: <ReplaySimulationKernelState>[
          ReplaySimulationKernelState(
            kernelId: 'temporal_kernel',
            status: 'active',
            reason: 'Replay timeline was synthesized successfully.',
          ),
        ],
      ),
      learningReadiness: ReplaySimulationLearningReadiness(
        trainingGrade: 'strong',
        shareWithRealityModelAllowed: true,
        reasons: const <String>['Simulation is bounded and ready.'],
        suggestedTrainingUse: 'candidate_deeper_reality_model_training',
        requestPreviews: <ReplaySimulationRealityModelRequestPreview>[
          ReplaySimulationRealityModelRequestPreview(
            request: RealityModelEvaluationRequest(
              requestId: 'intake-share-1',
              subjectId: 'simulation:atx_downtown',
              domain: RealityModelDomain.locality,
              candidateRef: 'locality:atx_downtown',
              localityCode: 'atx_downtown',
              cityCode: 'atx',
              signalTags: const <String>[
                'simulation_bundle',
                'locality_overlay'
              ],
              evidenceRefs: const <String>[
                'simulation_snapshot.json#overlay:atx_downtown',
              ],
              requestedAtUtc: DateTime.utc(2026, 3, 31, 20),
            ),
            rationale: 'Review the lead locality as bounded evidence.',
          ),
        ],
      ),
    );

    final intakeRepository = UniversalIntakeRepository();
    final service = ReplaySimulationAdminService(
      environmentAdapters: <ReplaySimulationAdminEnvironmentAdapter>[
        _FakeReplaySimulationAdminEnvironmentAdapter(
          descriptor: const ReplaySimulationAdminEnvironmentDescriptor(
            environmentId: 'generic-intake-env',
            displayName: 'Generic Intake Env',
            cityCode: 'atx',
            replayYear: 2024,
          ),
          snapshot: strongSnapshot,
        ),
      ],
      defaultEnvironmentId: 'generic-intake-env',
      realityModelPort: DefaultRealityModelPort(),
      intakeRepository: intakeRepository,
      nowProvider: () => DateTime.utc(2026, 3, 31, 20),
      documentsDirectoryProvider: () async => tempDir,
    );

    final export = await service.queueDeeperTrainingIntake();
    expect(export.environmentId, 'generic-intake-env');
    expect(File(export.queueJsonPath).existsSync(), isTrue);
    expect(File(export.readmePath).existsSync(), isTrue);
    expect(export.sourceId, isNotNull);
    expect(export.reviewItemId, isNotNull);

    final sources = await intakeRepository.getAllSources();
    final reviews = await intakeRepository.getAllReviewItems();
    expect(sources, hasLength(1));
    expect(reviews, hasLength(1));
    expect(
      sources.single.metadata['cityPackStructuralRef'],
      'city_pack:atx_core_2024',
    );
    expect(
      reviews.single.payload['cityPackStructuralRef'],
      'city_pack:atx_core_2024',
    );
    expect(
      reviews.single.payload['trainingManifestJsonPath'],
      export.trainingManifestJsonPath,
    );
  });
}

class _FakeReplaySimulationAdminEnvironmentAdapter
    implements ReplaySimulationAdminEnvironmentAdapter {
  const _FakeReplaySimulationAdminEnvironmentAdapter({
    required this.descriptor,
    this.snapshot,
  });

  @override
  final ReplaySimulationAdminEnvironmentDescriptor descriptor;
  final ReplaySimulationAdminSnapshot? snapshot;

  @override
  Future<ReplaySimulationAdminSnapshot> buildSnapshot({
    required DateTime generatedAt,
  }) async {
    if (snapshot != null) {
      return snapshot!;
    }
    return ReplaySimulationAdminSnapshot(
      generatedAt: generatedAt,
      environmentId: descriptor.environmentId,
      cityCode: descriptor.cityCode,
      replayYear: descriptor.replayYear,
      scenarios: const <ReplayScenarioPacket>[],
      comparisons: const <ReplayScenarioComparison>[],
      receipts: const <SimulationTruthReceipt>[],
      contradictions: const <ReplayContradictionSnapshot>[],
      localityOverlays: const <ReplayLocalityOverlaySnapshot>[],
    );
  }
}
