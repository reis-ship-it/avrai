import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validator accepts a deterministic proof run bundle index', () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_proof_run_bundle_artifact_index.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'validate_proof_run_bundle_artifact_index_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_proof_run_run-a',
      runId: 'run-a',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
      gitSha: 'deadbeef-a',
    );
    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_19-00-00_proof_run_run-b',
      runId: 'run-b',
      timestamp: '2026-03-15_19-00-00',
      timestampUtc: '2026-03-16T00:00:00Z',
      gitSha: 'deadbeef-b',
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
        summary['latest_artifact_dir'], '2026-03-15_20-00-00_proof_run_run-a');
  });

  test('validator rejects an out-of-sync proof run root index', () async {
    final repoRoot = _findRepoRoot();
    final toolPath =
        '${repoRoot.path}/work/tools/validate_proof_run_bundle_artifact_index.dart';
    final artifactRoot = await Directory.systemTemp.createTemp(
      'validate_proof_run_bundle_artifact_index_negative_',
    );
    addTearDown(() async {
      if (artifactRoot.existsSync()) {
        await artifactRoot.delete(recursive: true);
      }
    });

    await _writeSyntheticArtifact(
      artifactRoot,
      artifactDir: '2026-03-15_20-00-00_proof_run_run-a',
      runId: 'run-a',
      timestamp: '2026-03-15_20-00-00',
      timestampUtc: '2026-03-16T01:00:00Z',
      gitSha: 'deadbeef-a',
    );
    await _writeRootIndex(artifactRoot);

    final indexJsonFile =
        File('${artifactRoot.path}/proof_run_bundle_index.json');
    final indexJson =
        jsonDecode(indexJsonFile.readAsStringSync()) as Map<String, dynamic>;
    final entries = (indexJson['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);
    entries[0]['run_id'] = 'run-corrupted';
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
          'Index field mismatch for run_id: expected run-a, got run-corrupted'),
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
  required String timestamp,
  required String timestampUtc,
  required String gitSha,
}) async {
  final dir = await Directory('${artifactRoot.path}/$artifactDir')
      .create(recursive: true);
  final manifest = <String, Object?>{
    'artifact_kind': 'proof_run_bundle',
    'run_id': runId,
    'timestamp': timestamp,
    'timestamp_utc': timestampUtc,
    'bundle_id': 'com.avrai.app',
    'git_sha': gitSha,
  };

  await File('${dir.path}/manifest.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );
  await File('${dir.path}/ARTIFACT_INDEX.md').writeAsString(
    '# Proof Run Bundle Artifact Index\n\n'
    '- Run ID: `$runId`\n',
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
