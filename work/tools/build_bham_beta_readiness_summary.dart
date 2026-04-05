import 'dart:convert';
import 'dart:io';

const Map<String, String> _requiredBaselinePlatforms = <String, String>{
  'ios': 'ios_simulator',
  'android': 'android_simulator',
};

const List<String> _requiredSmokeArtifactFiles = <String>[
  'ledger_rows.csv',
  'ledger_rows.jsonl',
  'background_wake_runs.json',
  'field_validation_proofs.json',
  'ambient_social_diagnostics.json',
  'manifest.json',
  'validation_summary.json',
];

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run work/tools/build_bham_beta_readiness_summary.dart '
      '<artifact_root> '
      '[--json-output=/path/to/summary.json] '
      '[--markdown-output=/path/to/summary.md]',
    );
    exitCode = 64;
    return;
  }

  final artifactRoot = Directory(args.first);
  String? jsonOutputPath;
  String? markdownOutputPath;
  for (final arg in args.skip(1)) {
    if (arg.startsWith('--json-output=')) {
      jsonOutputPath = arg.substring('--json-output='.length);
    } else if (arg.startsWith('--markdown-output=')) {
      markdownOutputPath = arg.substring('--markdown-output='.length);
    }
  }

  final result = _buildReadinessSummary(artifactRoot);
  final jsonOutput = const JsonEncoder.withIndent('  ').convert(result);
  if (jsonOutputPath != null && jsonOutputPath.isNotEmpty) {
    final file = File(jsonOutputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonOutput);
  }
  if (markdownOutputPath != null && markdownOutputPath.isNotEmpty) {
    final file = File(markdownOutputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(_buildMarkdown(result));
  }

  stdout.writeln(jsonOutput);
  if (result['is_ready_for_phone_qa'] != true) {
    exitCode = 1;
  }
}

Map<String, Object?> _buildReadinessSummary(Directory artifactRoot) {
  final blockers = <String>[];
  final warnings = <String>[];

  if (!artifactRoot.existsSync()) {
    blockers.add('Artifact root does not exist: ${artifactRoot.path}');
    return <String, Object?>{
      'is_ready_for_phone_qa': false,
      'artifact_root': artifactRoot.path,
      'blockers': blockers,
      'warnings': warnings,
      'required_platforms': _requiredBaselinePlatforms.keys.toList(),
    };
  }

  final smokeIndexJsonFile =
      File('${artifactRoot.path}/simulated_headless_smoke_index.json');
  final smokeIndexMarkdownFile =
      File('${artifactRoot.path}/simulated_headless_smoke_index.md');
  Map<String, dynamic>? smokeIndex;
  List<Map<String, dynamic>> smokeEntries = const <Map<String, dynamic>>[];
  if (!smokeIndexJsonFile.existsSync()) {
    blockers.add('Missing simulated_headless_smoke_index.json');
  }
  if (!smokeIndexMarkdownFile.existsSync()) {
    blockers.add('Missing simulated_headless_smoke_index.md');
  }
  if (smokeIndexJsonFile.existsSync() && smokeIndexMarkdownFile.existsSync()) {
    smokeIndex = _readJsonMap(
      smokeIndexJsonFile,
      blockers,
      label: 'simulated_headless_smoke_index.json',
    );
    smokeEntries = smokeIndex == null
        ? const <Map<String, dynamic>>[]
        : _readList(
            smokeIndex['entries'],
            'simulated_headless_smoke_index.json.entries',
            blockers,
          )
            .map((entry) => _asMap(entry, 'smoke index entry', blockers))
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
  }

  final baselineEvaluations = <String, Map<String, Object?>>{};
  for (final platformEntry in _requiredBaselinePlatforms.entries) {
    baselineEvaluations[platformEntry.key] = _evaluateBaselinePlatform(
      artifactRoot: artifactRoot,
      smokeEntries: smokeEntries,
      platformMode: platformEntry.key,
      platformValue: platformEntry.value,
      blockers: blockers,
    );
  }

  final proofRunIndexJsonFile =
      File('${artifactRoot.path}/proof_run_bundle_index.json');
  final proofRunIndexMarkdownFile =
      File('${artifactRoot.path}/proof_run_bundle_index.md');
  Map<String, Object?>? latestProofRunBundle;
  if (!proofRunIndexJsonFile.existsSync() ||
      !proofRunIndexMarkdownFile.existsSync()) {
    warnings.add(
      'Manual proof run bundle index is missing; readiness summary will treat '
      'manual proof bundles as advisory only.',
    );
  } else {
    latestProofRunBundle = _evaluateLatestProofRunBundle(
      artifactRoot: artifactRoot,
      indexJsonFile: proofRunIndexJsonFile,
      warnings: warnings,
    );
  }

  blockers.sort();
  warnings.sort();

  final smokeRunCount = smokeEntries.length;
  final baselineReadyCount = baselineEvaluations.values
      .where((evaluation) => evaluation['is_ready'] == true)
      .length;
  final summary = <String, Object?>{
    'baseline_ready_count': baselineReadyCount,
    'required_baseline_count': _requiredBaselinePlatforms.length,
    'simulated_smoke_run_count': smokeRunCount,
    'latest_manual_proof_run_id': latestProofRunBundle?['run_id'],
    'latest_manual_proof_run_timestamp_utc':
        latestProofRunBundle?['timestamp_utc'],
  };

  return <String, Object?>{
    'is_ready_for_phone_qa': blockers.isEmpty,
    'artifact_root': artifactRoot.path,
    'required_platforms': _requiredBaselinePlatforms.keys.toList(),
    'blockers': blockers,
    'warnings': warnings,
    'summary': summary,
    'baseline_platforms': baselineEvaluations,
    if (latestProofRunBundle != null)
      'latest_manual_proof_run': latestProofRunBundle,
  };
}

Map<String, Object?> _evaluateBaselinePlatform({
  required Directory artifactRoot,
  required List<Map<String, dynamic>> smokeEntries,
  required String platformMode,
  required String platformValue,
  required List<String> blockers,
}) {
  final matchingEntries = smokeEntries
      .where(
        (entry) =>
            entry['platform']?.toString() == platformValue &&
            entry['scenario_profile']?.toString() == 'baseline',
      )
      .toList(growable: false);

  if (matchingEntries.isEmpty) {
    final message =
        'Missing baseline simulated smoke artifact for $platformMode '
        '($platformValue)';
    blockers.add(message);
    return <String, Object?>{
      'is_ready': false,
      'platform': platformValue,
      'scenario_profile': 'baseline',
      'status': 'missing',
      'blockers': <String>[message],
      'warnings': const <String>[],
    };
  }

  final entry = matchingEntries.first;
  final evaluationBlockers = <String>[];
  final evaluationWarnings = <String>[];
  final artifactDirPath =
      entry['artifact_dir_path']?.toString().isNotEmpty == true
          ? entry['artifact_dir_path']!.toString()
          : '${artifactRoot.path}/${entry['artifact_dir']}';
  final artifactDir = Directory(artifactDirPath);

  if (!artifactDir.existsSync()) {
    evaluationBlockers.add(
      'Artifact directory does not exist for $platformMode baseline: '
      '$artifactDirPath',
    );
  }

  for (final fileName in _requiredSmokeArtifactFiles) {
    final file = File('${artifactDir.path}/$fileName');
    if (!file.existsSync()) {
      evaluationBlockers.add(
        'Missing $fileName for $platformMode baseline artifact '
        '${entry['artifact_dir']}',
      );
    }
  }

  Map<String, dynamic>? manifest;
  Map<String, dynamic>? validationSummary;
  if (evaluationBlockers.isEmpty) {
    manifest = _readJsonMap(
      File('${artifactDir.path}/manifest.json'),
      evaluationBlockers,
      label: '${artifactDir.path}/manifest.json',
    );
    validationSummary = _readJsonMap(
      File('${artifactDir.path}/validation_summary.json'),
      evaluationBlockers,
      label: '${artifactDir.path}/validation_summary.json',
    );
  }

  if (manifest != null) {
    if (manifest['artifact_kind'] != 'simulated_headless_smoke') {
      evaluationBlockers.add(
        'manifest.json artifact_kind must be simulated_headless_smoke for '
        '$platformMode baseline',
      );
    }
    if (manifest['platform'] != platformValue) {
      evaluationBlockers.add(
        'manifest.json platform mismatch for $platformMode baseline: '
        'expected $platformValue, got ${manifest['platform']}',
      );
    }
    if (manifest['scenario_profile'] != 'baseline') {
      evaluationBlockers.add(
        'manifest.json scenario_profile mismatch for $platformMode baseline: '
        'expected baseline, got ${manifest['scenario_profile']}',
      );
    }
    if (manifest['smoke_response_success'] != true) {
      evaluationBlockers.add(
        'manifest.json smoke_response_success must be true for '
        '$platformMode baseline',
      );
    }
  }

  if (validationSummary != null) {
    if (validationSummary['is_valid'] != true) {
      evaluationBlockers.add(
        'validation_summary.json must be valid for $platformMode baseline',
      );
    }
    final validationPayload = _asMap(
      validationSummary['summary'],
      'validation_summary.summary',
      evaluationWarnings,
    );
    if (validationPayload != null) {
      if (validationPayload['scenario_profile'] != 'baseline') {
        evaluationBlockers.add(
          'validation_summary.summary.scenario_profile mismatch for '
          '$platformMode baseline',
        );
      }
      if (validationPayload['platform'] != platformValue) {
        evaluationBlockers.add(
          'validation_summary.summary.platform mismatch for $platformMode '
          'baseline',
        );
      }
    }
  }

  blockers.addAll(evaluationBlockers);
  return <String, Object?>{
    'is_ready': evaluationBlockers.isEmpty,
    'platform': platformValue,
    'scenario_profile': 'baseline',
    'status': evaluationBlockers.isEmpty ? 'ready' : 'blocked',
    'artifact_dir': entry['artifact_dir'],
    'artifact_dir_path': artifactDir.path,
    'run_id': entry['run_id'],
    'timestamp_utc': entry['timestamp_utc'],
    'validation_is_valid': validationSummary?['is_valid'],
    'blockers': evaluationBlockers,
    'warnings': evaluationWarnings,
  };
}

Map<String, Object?>? _evaluateLatestProofRunBundle({
  required Directory artifactRoot,
  required File indexJsonFile,
  required List<String> warnings,
}) {
  final indexErrors = <String>[];
  final indexJson = _readJsonMap(
    indexJsonFile,
    indexErrors,
    label: 'proof_run_bundle_index.json',
  );
  if (indexJson == null) {
    warnings.addAll(indexErrors);
    return null;
  }

  final entries = _readList(
    indexJson['entries'],
    'proof_run_bundle_index.json.entries',
    indexErrors,
  )
      .map(
          (entry) => _asMap(entry, 'proof_run_bundle_index entry', indexErrors))
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  if (entries.isEmpty) {
    warnings.add('Manual proof run bundle index has no entries.');
    return null;
  }

  final entry = entries.first;
  final artifactDirPath =
      entry['artifact_dir_path']?.toString().isNotEmpty == true
          ? entry['artifact_dir_path']!.toString()
          : '${artifactRoot.path}/${entry['artifact_dir']}';
  final artifactDir = Directory(artifactDirPath);
  if (!artifactDir.existsSync()) {
    warnings.add(
      'Latest manual proof run bundle directory is missing: $artifactDirPath',
    );
  }

  final manifestFile = File('${artifactDir.path}/manifest.json');
  if (!manifestFile.existsSync()) {
    warnings.add(
      'Latest manual proof run bundle is missing manifest.json: '
      '${entry['artifact_dir']}',
    );
  }

  warnings.addAll(indexErrors);
  return <String, Object?>{
    'artifact_dir': entry['artifact_dir'],
    'artifact_dir_path': artifactDir.path,
    'run_id': entry['run_id'],
    'timestamp_utc': entry['timestamp_utc'],
    'bundle_id': entry['bundle_id'],
    'zip_path': entry['zip_path'],
  };
}

String _buildMarkdown(Map<String, Object?> result) {
  final buffer = StringBuffer()
    ..writeln('# BHAM Beta Readiness Summary')
    ..writeln()
    ..writeln(
      '- Ready for phone QA: `${result['is_ready_for_phone_qa'] == true}`',
    )
    ..writeln('- Artifact root: `${result['artifact_root']}`')
    ..writeln();

  final baselines =
      (result['baseline_platforms'] as Map?)?.cast<String, Object?>() ??
          const <String, Object?>{};
  buffer
    ..writeln('## Baseline Smoke Gates')
    ..writeln()
    ..writeln('| Platform | Status | Run ID | Timestamp UTC | Artifact Dir |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final platformMode in _requiredBaselinePlatforms.keys) {
    final evaluation =
        (baselines[platformMode] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{};
    buffer.writeln(
      '| $platformMode | ${evaluation['status'] ?? 'missing'} | '
      '${evaluation['run_id'] ?? ''} | ${evaluation['timestamp_utc'] ?? ''} | '
      '${evaluation['artifact_dir'] ?? ''} |',
    );
  }

  final blockers = (result['blockers'] as List?)?.cast<Object?>() ?? const [];
  buffer
    ..writeln()
    ..writeln('## Blocking Reasons')
    ..writeln();
  if (blockers.isEmpty) {
    buffer.writeln('- None');
  } else {
    for (final blocker in blockers) {
      buffer.writeln('- $blocker');
    }
  }

  final warnings = (result['warnings'] as List?)?.cast<Object?>() ?? const [];
  buffer
    ..writeln()
    ..writeln('## Warnings')
    ..writeln();
  if (warnings.isEmpty) {
    buffer.writeln('- None');
  } else {
    for (final warning in warnings) {
      buffer.writeln('- $warning');
    }
  }

  final latestProofRun =
      (result['latest_manual_proof_run'] as Map?)?.cast<String, Object?>();
  if (latestProofRun != null) {
    buffer
      ..writeln()
      ..writeln('## Latest Manual Proof Run Bundle')
      ..writeln()
      ..writeln('- Run ID: `${latestProofRun['run_id']}`')
      ..writeln('- Timestamp UTC: `${latestProofRun['timestamp_utc']}`')
      ..writeln('- Artifact Dir: `${latestProofRun['artifact_dir']}`');
  }

  return buffer.toString();
}

Map<String, dynamic>? _readJsonMap(
  File file,
  List<String> errors, {
  required String label,
}) {
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      errors.add('$label must decode to a JSON object');
      return null;
    }
    return Map<String, dynamic>.from(decoded);
  } catch (error) {
    errors.add('Failed to parse $label: $error');
    return null;
  }
}

List<dynamic> _readList(Object? value, String label, List<String> errors) {
  if (value is List) {
    return value;
  }
  errors.add('$label must be a JSON array');
  return const <dynamic>[];
}

Map<String, dynamic>? _asMap(
  Object? value,
  String label,
  List<String> errors,
) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  errors.add('$label must be a JSON object');
  return null;
}
