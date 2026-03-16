import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validator accepts all supported simulated smoke scenario profiles',
      () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_bundle.dart';
    final tempRoot = await Directory.systemTemp.createTemp(
      'validate_simulated_smoke_bundle_profiles_',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    for (final profile in _supportedProfiles) {
      final bundleDir = await Directory(
        '${tempRoot.path}/$profile',
      ).create(recursive: true);
      await _writeSyntheticBundle(bundleDir, profile: profile);
      final summaryFile = File('${bundleDir.path}/summary.json');

      final result = await Process.run(
        'dart',
        <String>[
          'run',
          toolPath,
          bundleDir.path,
          '--summary-path=${summaryFile.path}',
        ],
        workingDirectory: repoRoot.path,
      );

      expect(
        result.exitCode,
        0,
        reason: 'validator failed for profile $profile: ${result.stderr}',
      );
      expect(summaryFile.existsSync(), isTrue);
      final summary =
          jsonDecode(summaryFile.readAsStringSync()) as Map<String, dynamic>;
      expect(summary['is_valid'], isTrue, reason: 'profile $profile failed');
      final summaryPayload = summary['summary'] as Map<String, dynamic>;
      expect(
        summaryPayload['artifact_kind'],
        'simulated_headless_smoke',
      );
      expect(summaryPayload['scenario_profile'], profile);
      expect(summaryPayload['timestamp_utc'], '2026-03-16T01:00:00Z');
      expect(summaryPayload['smoke_response_success'], isTrue);
    }
  });

  test('validator rejects a bundle that is missing proof_run_finished',
      () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_bundle.dart';
    final tempRoot = await Directory.systemTemp.createTemp(
      'validate_simulated_smoke_bundle_negative_',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final bundleDir =
        await Directory('${tempRoot.path}/baseline').create(recursive: true);
    await _writeSyntheticBundle(
      bundleDir,
      profile: 'baseline',
      includeProofRunFinished: false,
    );

    final result = await Process.run(
      'dart',
      <String>['run', toolPath, bundleDir.path],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, isNot(0));
    final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(decoded['is_valid'], isFalse);
    expect(
      (decoded['errors'] as List<dynamic>).cast<String>(),
      contains('ledger_rows.jsonl must contain proof_run_finished'),
    );
  });

  test('validator rejects a bundle with an unsupported scenario profile',
      () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_bundle.dart';
    final tempRoot = await Directory.systemTemp.createTemp(
      'validate_simulated_smoke_bundle_invalid_profile_',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final bundleDir =
        await Directory('${tempRoot.path}/invalid').create(recursive: true);
    await _writeSyntheticBundle(bundleDir, profile: 'baseline');

    final manifestFile = File('${bundleDir.path}/manifest.json');
    final manifest =
        jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
    manifest['scenario_profile'] = 'unsupported_profile';
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );

    final result = await Process.run(
      'dart',
      <String>['run', toolPath, bundleDir.path],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, isNot(0));
    final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(decoded['is_valid'], isFalse);
    expect(
      (decoded['errors'] as List<dynamic>).cast<String>(),
      contains(
        'manifest.json scenario_profile must be one of [baseline, '
        'duplicate_wake_delivery, multi_peer_single_confirmation, '
        'restart_mid_headless_run, trusted_route_unavailable_deferred]',
      ),
    );
  });
}

const List<String> _supportedProfiles = <String>[
  'baseline',
  'duplicate_wake_delivery',
  'restart_mid_headless_run',
  'trusted_route_unavailable_deferred',
  'multi_peer_single_confirmation',
];

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File('${current.path}/melos.yaml').existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Unable to locate repo root from ${Directory.current}');
    }
    current = parent;
  }
}

Future<void> _writeSyntheticBundle(
  Directory bundleDir, {
  required String profile,
  bool includeProofRunFinished = true,
}) async {
  final manifest = <String, Object?>{
    'artifact_kind': 'simulated_headless_smoke',
    'run_id': 'run-$profile',
    'platform': 'ios_simulator',
    'platform_mode': 'ios',
    'scenario_profile': profile,
    'run_status': 'passed',
    'simulated': true,
    'bundle_id': 'com.avrai.app',
    'git_sha': 'deadbeef',
    'timestamp': '2026-03-15_20-00-00',
    'timestamp_utc': '2026-03-16T01:00:00Z',
    'notes':
        'Automated simulated headless smoke artifact. Encounter and wake coverage are simulated only.',
    'smoke_response_success': true,
    'failure_summary': '',
  };

  final backgroundRuns = _buildBackgroundRuns(profile);
  final fieldProofs = _requiredFieldScenarios
      .map(
        (scenario) => <String, Object?>{
          'scenario': scenario,
          'passed': true,
          'summary': 'proof-$scenario',
        },
      )
      .toList(growable: false);
  final ambientDiagnostics = _buildAmbientDiagnostics(profile);
  final ledgerRows = <Map<String, Object?>>[
    <String, Object?>{
      'event_type': 'proof_run_started',
      'occurred_at': '2026-03-16T01:00:00Z',
      'logical_id': 'logical-start-$profile',
      'payload': <String, Object?>{
        'run_id': 'run-$profile',
        'scenario_profile': profile,
      },
    },
    <String, Object?>{
      'event_type': 'proof_simulated_smoke_profile_context',
      'occurred_at': '2026-03-16T01:00:01Z',
      'logical_id': 'logical-context-$profile',
      'payload': <String, Object?>{
        'run_id': 'run-$profile',
        'scenario_profile': profile,
        'expected_wake_reasons': const <String>[
          'ble_encounter',
          'trusted_announce_refresh',
          'significant_location',
          'background_task_window',
        ],
        if (profile == 'restart_mid_headless_run') 'stale_run_recovered': true,
        if (profile == 'trusted_route_unavailable_deferred')
          'expected_blocked_reason': 'trusted_route_unavailable',
      },
    },
    if (includeProofRunFinished)
      <String, Object?>{
        'event_type': 'proof_run_finished',
        'occurred_at': '2026-03-16T01:00:02Z',
        'logical_id': 'logical-finish-$profile',
        'payload': <String, Object?>{
          'run_id': 'run-$profile',
          'scenario_profile': profile,
        },
      },
  ];

  await File('${bundleDir.path}/manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await File('${bundleDir.path}/ledger_rows.csv').writeAsString(
    'occurred_at,event_type,logical_id,row_id,ledger_write_ok\n',
  );
  await File('${bundleDir.path}/ledger_rows.jsonl').writeAsString(
    ledgerRows.map(jsonEncode).join('\n'),
  );
  await File('${bundleDir.path}/background_wake_runs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'exported_at_utc': '2026-03-16T01:00:03Z',
        'runs': backgroundRuns,
      },
    ),
  );
  await File('${bundleDir.path}/field_validation_proofs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'exported_at_utc': '2026-03-16T01:00:04Z',
        'proofs': fieldProofs,
      },
    ),
  );
  await File('${bundleDir.path}/ambient_social_diagnostics.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(ambientDiagnostics),
  );
}

List<Map<String, Object?>> _buildBackgroundRuns(String profile) {
  final reasons = <String>[
    'ble_encounter',
    'trusted_announce_refresh',
    'significant_location',
    'background_task_window',
  ];
  if (profile == 'duplicate_wake_delivery') {
    reasons.insert(1, 'ble_encounter');
    reasons.insert(3, 'trusted_announce_refresh');
  }

  return reasons
      .map(
        (reason) => <String, Object?>{
          'reason': reason,
          'platform_source': 'simulated_smoke:ios:$reason',
          'wake_timestamp_utc': '2026-03-16T01:00:00Z',
          'started_at_utc': '2026-03-16T01:00:00Z',
          'completed_at_utc': '2026-03-16T01:00:01Z',
          'bootstrap_success': true,
          'mesh_due_replay_count': 1,
          'mesh_recovered_replay_count':
              reason == 'trusted_announce_refresh' ? 1 : 0,
          'mesh_discovered_peer_count':
              profile == 'multi_peer_single_confirmation' ? 3 : 2,
          'ai2ai_released_count': reason == 'background_task_window' ? 1 : 0,
          'ai2ai_blocked_count':
              profile == 'trusted_route_unavailable_deferred' &&
                      reason == 'background_task_window'
                  ? 1
                  : 0,
          'ai2ai_trusted_route_unavailable_block_count':
              profile == 'trusted_route_unavailable_deferred' &&
                      reason == 'background_task_window'
                  ? 1
                  : 0,
          'passive_ingested_dwell_event_count':
              reason == 'ble_encounter' ? 1 : 0,
          'ambient_candidate_observation_delta_count':
              reason == 'ble_encounter' ? 1 : 0,
          'ambient_confirmed_promotion_delta_count':
              reason == 'trusted_announce_refresh' ? 1 : 0,
          'segment_refresh_count': reason == 'background_task_window' ? 1 : 0,
        },
      )
      .toList(growable: false);
}

Map<String, Object?> _buildAmbientDiagnostics(String profile) {
  final latestNearbyPeerCount =
      profile == 'multi_peer_single_confirmation' ? 3 : 2;
  final latestConfirmedCount =
      profile == 'multi_peer_single_confirmation' ? 1 : 1;
  final duplicateMergeCount = profile == 'duplicate_wake_delivery' ? 2 : 0;
  final trace = <String, Object?>{
    'locality_stable_key': 'bham-downtown',
    'source_kinds': profile == 'duplicate_wake_delivery'
        ? const <String>['passive_dwell', 'ai2ai_completed_interaction']
        : const <String>['ai2ai_completed_interaction'],
    'discovered_peer_ids': profile == 'multi_peer_single_confirmation'
        ? const <String>['peer-a', 'peer-b', 'peer-c']
        : const <String>['peer-a', 'peer-b'],
    'confirmed_interactive_peer_ids': const <String>['peer-a'],
    'social_context':
        profile == 'multi_peer_single_confirmation' ? 'crowd' : 'small_group',
    'place_vibe_label': profile == 'multi_peer_single_confirmation'
        ? 'crowd_energy'
        : 'social_hub',
    'lineage_refs': const <String>['synthetic:validator'],
    'promoted_at_utc': '2026-03-16T01:00:02Z',
  };

  return <String, Object?>{
    'captured_at_utc': '2026-03-16T01:00:05Z',
    'normalized_observation_count': 4,
    'candidate_copresence_observation_count': 2,
    'confirmed_interaction_promotion_count': 1,
    'duplicate_merge_count': duplicateMergeCount,
    'rejected_interaction_promotion_count': 0,
    'crowd_upgrade_count': 1,
    'what_ingestion_count': 2,
    'locality_vibe_update_count': 1,
    'personal_dna_authorized_count': 1,
    'personal_dna_applied_count': 1,
    'latest_nearby_peer_count': latestNearbyPeerCount,
    'latest_confirmed_interactive_peer_count': latestConfirmedCount,
    'last_promotion_trace': trace,
    'recent_promotion_traces': <Map<String, Object?>>[trace],
  };
}

const List<String> _requiredFieldScenarios = <String>[
  'trustedDirectAnnounceRecovery',
  'untrustedAnnounceRejected',
  'deferredRendezvousBlockedByTrustedRouteUnavailable',
  'trustedHeardForwardRoutable',
  'trustedRelayRefreshRoutable',
  'deferredExchangePeerTruthAfterRelease',
  'ambientPassiveNearbyCandidateOnly',
  'ambientTrustedInteractionPromotesConfirmedPresence',
  'ambientDuplicateEvidenceMerged',
  'ambientUntrustedInteractionNotPromoted',
];
