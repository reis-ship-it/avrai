import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validator accepts a deterministic simulated smoke index', () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_artifact_index.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'validate_simulated_smoke_artifact_index_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-a',
      runId: 'run-a',
      platform: 'ios_simulator',
      scenarioProfile: 'baseline',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
      gitSha: 'deadbeef-a',
      success: true,
    );
    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir:
          '2026-03-15_19-00-00_android_duplicate_wake_delivery_simulated_smoke_run-b',
      runId: 'run-b',
      platform: 'android_simulator',
      scenarioProfile: 'duplicate_wake_delivery',
      timestamp: '2026-03-15_19-00-00',
      timestampUtc: '2026-03-16T00:00:00Z',
      gitSha: 'deadbeef-b',
      success: true,
    );
    await _writeRootIndex(artifactRoot);

    final result = await Process.run(
      'dart',
      <String>['run', toolPath, artifactRoot.path],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    final payload = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(payload['is_valid'], isTrue);
    final summary = payload['summary'] as Map<String, dynamic>;
    expect(summary['indexed_run_count'], 2);
    expect(summary['discovered_run_count'], 2);
    expect(
      summary['latest_artifact_dir'],
      '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-a',
    );
  });

  test('validator rejects an out-of-sync root index', () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_simulated_smoke_artifact_index.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'validate_simulated_smoke_artifact_index_negative_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_ios_baseline_simulated_smoke_run-a',
      runId: 'run-a',
      platform: 'ios_simulator',
      scenarioProfile: 'baseline',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
      gitSha: 'deadbeef-a',
      success: true,
    );
    await _writeRootIndex(artifactRoot);

    final indexJsonFile =
        File('${artifactRoot.path}/simulated_headless_smoke_index.json');
    final indexJson =
        jsonDecode(indexJsonFile.readAsStringSync()) as Map<String, dynamic>;
    final entries = (indexJson['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    entries[0]['scenario_profile'] = 'restart_mid_headless_run';
    await indexJsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(indexJson),
    );

    final result = await Process.run(
      'dart',
      <String>['run', toolPath, artifactRoot.path],
      workingDirectory: repoRoot.path,
    );

    expect(result.exitCode, isNot(0));
    final payload = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    expect(payload['is_valid'], isFalse);
    expect(
      (payload['errors'] as List<dynamic>).cast<String>(),
      contains(
        'Index field mismatch for scenario_profile: expected baseline, got '
        'restart_mid_headless_run',
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

Future<void> _writeSyntheticArtifact(
  Directory artifactRoot, {
  required String artifactDir,
  required String runId,
  required String platform,
  required String scenarioProfile,
  required String timestamp,
  required String timestampUtc,
  required String gitSha,
  required bool success,
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
    'git_sha': gitSha,
    'timestamp': timestamp,
    'timestamp_utc': timestampUtc,
    'smoke_response_success': success,
    'failure_summary': '',
    'notes':
        'Automated simulated headless smoke artifact. Encounter and wake coverage are simulated only.',
  };
  final validationSummary = <String, Object?>{
    'is_valid': true,
    'errors': const <Object?>[],
    'warnings': const <Object?>[],
    'summary': <String, Object?>{
      'run_id': runId,
      'scenario_profile': scenarioProfile,
    },
  };

  await File('${dir.path}/manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await File('${dir.path}/validation_summary.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(validationSummary),
  );
  await File('${dir.path}/ARTIFACT_INDEX.md').writeAsString(
    '# Simulated Headless Smoke Artifact Index\n\n'
    '- Run ID: `$runId`\n'
    '- Scenario Profile: `$scenarioProfile`\n',
  );
  await File('${dir.path}.zip').writeAsString('zip placeholder');
}

Future<void> _writeRootIndex(Directory artifactRoot) async {
  final directories = artifactRoot.listSync().whereType<Directory>().toList()
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
