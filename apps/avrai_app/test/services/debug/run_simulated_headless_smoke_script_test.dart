import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shell wrapper refreshes deterministic simulated smoke index', () async {
    final repoRoot = _findRepoRoot();
    final scriptPath =
        '${repoRoot.path}/work/scripts/proof_run/run_simulated_headless_smoke.sh';
    final indexToolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_artifact_index.dart';
    final tempRoot = await Directory.systemTemp.createTemp(
      'run_simulated_headless_smoke_script_',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final artifactRoot =
        await Directory('${tempRoot.path}/artifacts').create(recursive: true);

    final olderBundle = await Directory('${tempRoot.path}/bundle_older')
        .create(recursive: true);
    final newerBundle = await Directory('${tempRoot.path}/bundle_newer')
        .create(recursive: true);
    await _writeSyntheticBundle(
      olderBundle,
      profile: 'duplicate_wake_delivery',
    );
    await _writeSyntheticBundle(
      newerBundle,
      profile: 'baseline',
    );

    final olderResponse = File('${tempRoot.path}/response_older.json');
    final newerResponse = File('${tempRoot.path}/response_newer.json');
    await olderResponse.writeAsString(
      jsonEncode(
        <String, Object?>{
          'success': true,
          'run_id': 'run-older',
          'scenario_profile': 'duplicate_wake_delivery',
          'export_directory_path': olderBundle.path,
          'failure_summary': '',
        },
      ),
    );
    await newerResponse.writeAsString(
      jsonEncode(
        <String, Object?>{
          'success': true,
          'run_id': 'run-newer',
          'scenario_profile': 'baseline',
          'export_directory_path': newerBundle.path,
          'failure_summary': '',
        },
      ),
    );

    final olderResult = await Process.run(
      'bash',
      <String>[scriptPath, 'ios', 'duplicate_wake_delivery'],
      workingDirectory: repoRoot.path,
      environment: <String, String>{
        'SIMULATED_SMOKE_ARTIFACT_ROOT': artifactRoot.path,
        'SIMULATED_SMOKE_STUB_RESPONSE_PATH': olderResponse.path,
        'SIMULATED_SMOKE_STUB_BUNDLE_DIR': olderBundle.path,
        'SIMULATED_SMOKE_TIMESTAMP': '2026-03-15_19-00-00',
        'SIMULATED_SMOKE_TIMESTAMP_UTC': '2026-03-16T00:00:00Z',
      },
    );
    expect(
      olderResult.exitCode,
      0,
      reason: '${olderResult.stdout}\n${olderResult.stderr}',
    );

    final newerResult = await Process.run(
      'bash',
      <String>[scriptPath, 'ios', 'baseline'],
      workingDirectory: repoRoot.path,
      environment: <String, String>{
        'SIMULATED_SMOKE_ARTIFACT_ROOT': artifactRoot.path,
        'SIMULATED_SMOKE_STUB_RESPONSE_PATH': newerResponse.path,
        'SIMULATED_SMOKE_STUB_BUNDLE_DIR': newerBundle.path,
        'SIMULATED_SMOKE_TIMESTAMP': '2026-03-15_20-00-00',
        'SIMULATED_SMOKE_TIMESTAMP_UTC': '2026-03-16T01:00:00Z',
      },
    );
    expect(
      newerResult.exitCode,
      0,
      reason: '${newerResult.stdout}\n${newerResult.stderr}',
    );

    final indexValidation = await Process.run(
      'dart',
      <String>['run', indexToolPath, artifactRoot.path],
      workingDirectory: repoRoot.path,
    );
    expect(
      indexValidation.exitCode,
      0,
      reason: '${indexValidation.stdout}\n${indexValidation.stderr}',
    );

    final indexJson = jsonDecode(
      File('${artifactRoot.path}/simulated_headless_smoke_index.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = (indexJson['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    expect(entries, hasLength(2));
    expect(entries.first['run_id'], 'run-newer');
    expect(entries.first['scenario_profile'], 'baseline');
    expect(entries.last['run_id'], 'run-older');
    expect(entries.last['scenario_profile'], 'duplicate_wake_delivery');

    final artifactDirs = artifactRoot
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.path.split(Platform.pathSeparator).last)
        .where((entry) => !entry.contains('_PENDING'))
        .toList(growable: false);
    expect(
      artifactDirs,
      containsAll(<String>[
        '2026-03-15_19-00-00_ios_duplicate_wake_delivery_simulated_smoke_run-older',
        '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-newer',
      ]),
    );

    final readinessJson = jsonDecode(
      File('${artifactRoot.path}/bham_beta_readiness_summary.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(readinessJson['is_ready_for_phone_qa'], isFalse);
    expect(
      (readinessJson['blockers'] as List<dynamic>).cast<String>(),
      contains(
        'Missing baseline simulated smoke artifact for android '
        '(android_simulator)',
      ),
    );
  });
}

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
}) async {
  await File('${bundleDir.path}/ledger_rows.csv').writeAsString(
    'occurred_at,event_type,logical_id,row_id,ledger_write_ok\n',
  );
  await File('${bundleDir.path}/ledger_rows.jsonl').writeAsString(
    <Map<String, Object?>>[
      <String, Object?>{
        'event_type': 'proof_run_started',
        'occurred_at': '2026-03-16T01:00:00Z',
      },
      <String, Object?>{
        'event_type': 'proof_run_finished',
        'occurred_at': '2026-03-16T01:00:02Z',
      },
    ].map(jsonEncode).join('\n'),
  );
  await File('${bundleDir.path}/background_wake_runs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'runs': <Map<String, Object?>>[
          _backgroundRun('ble_encounter'),
          _backgroundRun('trusted_announce_refresh'),
          _backgroundRun('significant_location'),
          _backgroundRun('background_task_window'),
        ],
      },
    ),
  );
  await File('${bundleDir.path}/field_validation_proofs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'proofs': _requiredFieldScenarios
            .map(
              (scenario) => <String, Object?>{
                'scenario': scenario,
                'passed': true,
              },
            )
            .toList(growable: false),
      },
    ),
  );

  final trace = <String, Object?>{
    'locality_stable_key': 'bham-downtown',
    'source_kinds': profile == 'duplicate_wake_delivery'
        ? const <String>['passive_dwell', 'ai2ai_completed_interaction']
        : const <String>['ai2ai_completed_interaction'],
    'discovered_peer_ids': const <String>['peer-a', 'peer-b'],
    'confirmed_interactive_peer_ids': const <String>['peer-a'],
    'social_context': 'small_group',
    'place_vibe_label': 'social_hub',
    'lineage_refs': const <String>['synthetic:shell-test'],
    'promoted_at_utc': '2026-03-16T01:00:02Z',
  };
  await File('${bundleDir.path}/ambient_social_diagnostics.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'captured_at_utc': '2026-03-16T01:00:05Z',
        'normalized_observation_count': 4,
        'candidate_copresence_observation_count': 2,
        'confirmed_interaction_promotion_count': 1,
        'duplicate_merge_count': profile == 'duplicate_wake_delivery' ? 1 : 0,
        'rejected_interaction_promotion_count': 0,
        'crowd_upgrade_count': 0,
        'what_ingestion_count': 2,
        'locality_vibe_update_count': 1,
        'personal_dna_authorized_count': 1,
        'personal_dna_applied_count': 1,
        'latest_nearby_peer_count': 2,
        'latest_confirmed_interactive_peer_count': 1,
        'last_promotion_trace': trace,
        'recent_promotion_traces': <Map<String, Object?>>[trace],
      },
    ),
  );
}

Map<String, Object?> _backgroundRun(String reason) {
  return <String, Object?>{
    'reason': reason,
    'platform_source': 'simulated_smoke:test:$reason',
    'wake_timestamp_utc': '2026-03-16T01:00:00Z',
    'started_at_utc': '2026-03-16T01:00:00Z',
    'completed_at_utc': '2026-03-16T01:00:01Z',
    'bootstrap_success': true,
    'mesh_due_replay_count': 1,
    'ai2ai_released_count': reason == 'background_task_window' ? 1 : 0,
    'passive_ingested_dwell_event_count': reason == 'ble_encounter' ? 1 : 0,
    'ambient_candidate_observation_delta_count':
        reason == 'ble_encounter' ? 1 : 0,
    'ambient_confirmed_promotion_delta_count':
        reason == 'trusted_announce_refresh' ? 1 : 0,
    'segment_refresh_count': reason == 'background_task_window' ? 1 : 0,
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
