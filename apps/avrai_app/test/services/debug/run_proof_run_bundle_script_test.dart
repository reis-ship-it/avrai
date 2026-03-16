import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual proof run shell wrapper refreshes deterministic bundle index',
      () async {
    final repoRoot = _findRepoRoot();
    final scriptPath =
        '${repoRoot.path}/work/scripts/proof_run/run_proof_run_bundle.sh';
    final indexToolPath =
        '${repoRoot.path}/work/tools/validate_proof_run_bundle_artifact_index.dart';
    final tempRoot = await Directory.systemTemp.createTemp(
      'run_proof_run_bundle_script_',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final artifactRoot =
        await Directory('${tempRoot.path}/artifacts').create(recursive: true);
    final olderExport =
        await Directory('${tempRoot.path}/run-older').create(recursive: true);
    final newerExport =
        await Directory('${tempRoot.path}/run-newer').create(recursive: true);
    await _writeSyntheticLedgerExport(olderExport);
    await _writeSyntheticLedgerExport(newerExport);

    final olderResult = await Process.run(
      'bash',
      <String>[scriptPath],
      workingDirectory: repoRoot.path,
      environment: <String, String>{
        'PROOF_RUN_ARTIFACT_ROOT': artifactRoot.path,
        'PROOF_RUN_TIMESTAMP': '2026-03-15_19-00-00',
        'PROOF_RUN_TIMESTAMP_UTC': '2026-03-16T00:00:00Z',
        'PROOF_RUN_STUB_EXPORT_DIR': olderExport.path,
        'RUN_ID': 'run-older',
      },
    );
    expect(
      olderResult.exitCode,
      0,
      reason: '${olderResult.stdout}\n${olderResult.stderr}',
    );

    final newerResult = await Process.run(
      'bash',
      <String>[scriptPath],
      workingDirectory: repoRoot.path,
      environment: <String, String>{
        'PROOF_RUN_ARTIFACT_ROOT': artifactRoot.path,
        'PROOF_RUN_TIMESTAMP': '2026-03-15_20-00-00',
        'PROOF_RUN_TIMESTAMP_UTC': '2026-03-16T01:00:00Z',
        'PROOF_RUN_STUB_EXPORT_DIR': newerExport.path,
        'RUN_ID': 'run-newer',
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
      File('${artifactRoot.path}/proof_run_bundle_index.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = (indexJson['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    expect(entries, hasLength(2));
    expect(entries.first['run_id'], 'run-newer');
    expect(entries.last['run_id'], 'run-older');

    final artifactDirs = artifactRoot
        .listSync()
        .whereType<Directory>()
        .map((entry) => entry.path.split(Platform.pathSeparator).last)
        .where((entry) => !entry.contains('_PENDING'))
        .toList(growable: false);
    expect(
      artifactDirs,
      containsAll(<String>[
        '2026-03-15_19-00-00_proof_run_run-older',
        '2026-03-15_20-00-00_proof_run_run-newer',
      ]),
    );

    final readinessJson = jsonDecode(
      File('${artifactRoot.path}/bham_beta_readiness_summary.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(readinessJson['is_ready_for_phone_qa'], isFalse);
    expect(
      (readinessJson['blockers'] as List<dynamic>).cast<String>(),
      contains('Missing simulated_headless_smoke_index.json'),
    );
    final latestProofRun =
        readinessJson['latest_manual_proof_run'] as Map<String, dynamic>;
    expect(latestProofRun['run_id'], 'run-newer');
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

Future<void> _writeSyntheticLedgerExport(Directory exportDir) async {
  await File('${exportDir.path}/ledger_rows.csv').writeAsString(
    'occurred_at,event_type,logical_id,row_id,ledger_write_ok\n',
  );
  await File('${exportDir.path}/ledger_rows.jsonl').writeAsString(
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
  await File('${exportDir.path}/background_wake_runs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{'runs': []}),
  );
  await File('${exportDir.path}/field_validation_proofs.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{'proofs': []}),
  );
  await File('${exportDir.path}/ambient_social_diagnostics.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'captured_at_utc': '2026-03-16T01:00:05Z',
      },
    ),
  );
}
