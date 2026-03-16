import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readiness summary passes with baseline smoke on both platforms',
      () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/build_bham_beta_readiness_summary.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'build_bham_beta_readiness_summary_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticSmokeArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-ios',
      runId: 'run-ios',
      platform: 'ios_simulator',
      scenarioProfile: 'baseline',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
    );
    await _writeSyntheticSmokeArtifact(
      artifactRoot,
      artifactDir:
          '2026-03-15_20-30-00_android_baseline_simulated_smoke_run-android',
      runId: 'run-android',
      platform: 'android_simulator',
      scenarioProfile: 'baseline',
      timestamp: '2026-03-15_20-30-00',
      timestampUtc: '2026-03-16T01:30:00Z',
    );
    await _writeSyntheticSmokeIndex(artifactRoot);

    await _writeSyntheticProofRunArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_21-00-00_proof_run_run-proof',
      runId: 'run-proof',
      timestamp: '2026-03-15_21-00-00',
      timestampUtc: '2026-03-16T02:00:00Z',
    );
    await _writeSyntheticProofRunIndex(artifactRoot);

    final jsonOutput =
        File('${artifactRoot.path}/bham_beta_readiness_summary.json');
    final markdownOutput =
        File('${artifactRoot.path}/bham_beta_readiness_summary.md');
    final result = await Process.run(
      'dart',
      <String>[
        'run',
        toolPath,
        artifactRoot.path,
        '--json-output=${jsonOutput.path}',
        '--markdown-output=${markdownOutput.path}',
      ],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    expect(jsonOutput.existsSync(), isTrue);
    expect(markdownOutput.existsSync(), isTrue);

    final payload = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(payload['is_ready_for_phone_qa'], isTrue);
    expect(payload['blockers'], isEmpty);
    final summary = payload['summary'] as Map<String, dynamic>;
    expect(summary['baseline_ready_count'], 2);
    expect(summary['required_baseline_count'], 2);
    expect(summary['latest_manual_proof_run_id'], 'run-proof');

    final baselines = payload['baseline_platforms'] as Map<String, dynamic>;
    expect((baselines['ios'] as Map<String, dynamic>)['is_ready'], isTrue);
    expect(
      (baselines['android'] as Map<String, dynamic>)['is_ready'],
      isTrue,
    );

    final markdown = markdownOutput.readAsStringSync();
    expect(markdown, contains('Ready for phone QA: `true`'));
    expect(markdown, contains('| ios | ready | run-ios |'));
    expect(markdown, contains('| android | ready | run-android |'));
  });

  test('readiness summary blocks when android baseline is missing', () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/build_bham_beta_readiness_summary.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'build_bham_beta_readiness_summary_negative_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticSmokeArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-ios',
      runId: 'run-ios',
      platform: 'ios_simulator',
      scenarioProfile: 'baseline',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
    );
    await _writeSyntheticSmokeIndex(artifactRoot);

    final result = await Process.run(
      'dart',
      <String>['run', toolPath, artifactRoot.path],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, isNot(0));
    final payload = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(payload['is_ready_for_phone_qa'], isFalse);
    expect(
      (payload['blockers'] as List<dynamic>).cast<String>(),
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

Future<void> _writeSyntheticSmokeArtifact(
  Directory artifactRoot, {
  required String artifactDir,
  required String runId,
  required String platform,
  required String scenarioProfile,
  required String timestamp,
  required String timestampUtc,
}) async {
  final dir = await Directory('${artifactRoot.path}/$artifactDir')
      .create(recursive: true);
  final manifest = <String, Object?>{
    'artifact_kind': 'simulated_headless_smoke',
    'run_id': runId,
    'platform': platform,
    'scenario_profile': scenarioProfile,
    'simulated': true,
    'bundle_id': 'com.avrai.app',
    'git_sha': 'deadbeef-$runId',
    'timestamp': timestamp,
    'timestamp_utc': timestampUtc,
    'smoke_response_success': true,
    'failure_summary': '',
    'notes':
        'Automated simulated headless smoke artifact. Encounter and wake coverage are simulated only.',
  };
  final validationSummary = <String, Object?>{
    'is_valid': true,
    'errors': const <Object?>[],
    'warnings': const <Object?>[],
    'summary': <String, Object?>{
      'artifact_kind': 'simulated_headless_smoke',
      'run_id': runId,
      'platform': platform,
      'scenario_profile': scenarioProfile,
      'timestamp_utc': timestampUtc,
      'smoke_response_success': true,
    },
  };

  await File('${dir.path}/manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await File('${dir.path}/validation_summary.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(validationSummary),
  );
  await File('${dir.path}/ledger_rows.csv').writeAsString(
    'occurred_at,event_type,logical_id,row_id,ledger_write_ok\n',
  );
  await File('${dir.path}/ledger_rows.jsonl').writeAsString(
    [
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
  await File('${dir.path}/background_wake_runs.json').writeAsString(
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
  await File('${dir.path}/field_validation_proofs.json').writeAsString(
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
  await File('${dir.path}/ambient_social_diagnostics.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'captured_at_utc': '2026-03-16T01:00:05Z',
        'normalized_observation_count': 4,
        'candidate_copresence_observation_count': 2,
        'confirmed_interaction_promotion_count': 1,
        'duplicate_merge_count': 0,
        'rejected_interaction_promotion_count': 0,
        'crowd_upgrade_count': 0,
        'what_ingestion_count': 2,
        'locality_vibe_update_count': 1,
        'personal_dna_authorized_count': 1,
        'personal_dna_applied_count': 1,
        'latest_nearby_peer_count': 2,
        'latest_confirmed_interactive_peer_count': 1,
        'last_promotion_trace': <String, Object?>{
          'locality_stable_key': 'bham-downtown',
          'source_kinds': const <String>['ai2ai_completed_interaction'],
          'discovered_peer_ids': const <String>['peer-a'],
          'confirmed_interactive_peer_ids': const <String>['peer-a'],
          'social_context': 'small_group',
          'place_vibe_label': 'social_hub',
          'lineage_refs': const <String>['synthetic:test'],
          'promoted_at_utc': '2026-03-16T01:00:02Z',
        },
        'recent_promotion_traces': <Map<String, Object?>>[
          <String, Object?>{
            'locality_stable_key': 'bham-downtown',
            'source_kinds': const <String>['ai2ai_completed_interaction'],
            'discovered_peer_ids': const <String>['peer-a'],
            'confirmed_interactive_peer_ids': const <String>['peer-a'],
            'social_context': 'small_group',
            'place_vibe_label': 'social_hub',
            'lineage_refs': const <String>['synthetic:test'],
            'promoted_at_utc': '2026-03-16T01:00:02Z',
          },
        ],
      },
    ),
  );
}

Future<void> _writeSyntheticSmokeIndex(Directory artifactRoot) async {
  final directories = artifactRoot
      .listSync()
      .whereType<Directory>()
      .where(
        (directory) => directory.path.contains('simulated_smoke'),
      )
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));
  final entries = directories.map((directory) {
    final manifest = jsonDecode(
      File('${directory.path}/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    return <String, Object?>{
      'artifact_dir': directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last,
      'artifact_dir_path': directory.path,
      'zip_path': '${directory.path}.zip',
      'run_id': manifest['run_id'],
      'platform': manifest['platform'],
      'scenario_profile': manifest['scenario_profile'],
      'timestamp': manifest['timestamp'],
      'timestamp_utc': manifest['timestamp_utc'],
      'git_sha': manifest['git_sha'],
      'success': manifest['smoke_response_success'],
      'failure_summary': manifest['failure_summary'],
    };
  }).toList(growable: false);

  await File('${artifactRoot.path}/simulated_headless_smoke_index.json')
      .writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'artifact_kind': 'simulated_headless_smoke_index',
        'entries': entries,
      },
    ),
  );

  final rows = entries
      .map(
        (entry) => '| ${entry['timestamp_utc']} | ${entry['platform']} | '
            '${entry['scenario_profile']} | ${entry['run_id']} | '
            '${entry['success']} | `${entry['artifact_dir']}` |',
      )
      .join('\n');
  await File('${artifactRoot.path}/simulated_headless_smoke_index.md')
      .writeAsString(
    '# Simulated Headless Smoke Index\n\n'
    '| Timestamp | Platform | Scenario | Run ID | Success | Artifact Dir |\n'
    '| --- | --- | --- | --- | --- | --- |\n'
    '$rows\n',
  );
}

Future<void> _writeSyntheticProofRunArtifact(
  Directory artifactRoot, {
  required String artifactDir,
  required String runId,
  required String timestamp,
  required String timestampUtc,
}) async {
  final dir = await Directory('${artifactRoot.path}/$artifactDir')
      .create(recursive: true);
  final manifest = <String, Object?>{
    'artifact_kind': 'proof_run_bundle',
    'run_id': runId,
    'bundle_id': 'com.avrai.app',
    'git_sha': 'deadbeef-proof',
    'timestamp': timestamp,
    'timestamp_utc': timestampUtc,
  };
  await File('${dir.path}/manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await File('${dir.path}/ARTIFACT_INDEX.md').writeAsString(
    '# Proof Run Artifact Index\n\n- Run ID: `$runId`\n',
  );
  await File('${dir.path}.zip').writeAsString('zip placeholder');
}

Future<void> _writeSyntheticProofRunIndex(Directory artifactRoot) async {
  final directories = artifactRoot
      .listSync()
      .whereType<Directory>()
      .where(
        (directory) => directory.path.contains('proof_run'),
      )
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));
  final entries = directories.map((directory) {
    final manifest = jsonDecode(
      File('${directory.path}/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    return <String, Object?>{
      'artifact_dir': directory.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .last,
      'artifact_dir_path': directory.path,
      'zip_path': '${directory.path}.zip',
      'run_id': manifest['run_id'],
      'bundle_id': manifest['bundle_id'],
      'timestamp': manifest['timestamp'],
      'timestamp_utc': manifest['timestamp_utc'],
      'git_sha': manifest['git_sha'],
    };
  }).toList(growable: false);

  await File('${artifactRoot.path}/proof_run_bundle_index.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'artifact_kind': 'proof_run_bundle_index',
        'entries': entries,
      },
    ),
  );

  final rows = entries
      .map(
        (entry) => '| ${entry['timestamp_utc']} | ${entry['run_id']} | '
            '${entry['bundle_id']} | `${entry['artifact_dir']}` |',
      )
      .join('\n');
  await File('${artifactRoot.path}/proof_run_bundle_index.md').writeAsString(
    '# Proof Run Bundle Index\n\n'
    '| Timestamp | Run ID | Bundle ID | Artifact Dir |\n'
    '| --- | --- | --- | --- |\n'
    '$rows\n',
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
    'ai2ai_released_count': 1,
    'passive_ingested_dwell_event_count': 1,
    'ambient_candidate_observation_delta_count': 1,
    'ambient_confirmed_promotion_delta_count': 1,
    'segment_refresh_count': 1,
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
