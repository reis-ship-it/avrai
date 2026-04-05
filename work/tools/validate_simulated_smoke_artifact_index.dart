import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run work/tools/validate_simulated_smoke_artifact_index.dart '
      '<artifact_root>',
    );
    exitCode = 64;
    return;
  }

  final artifactRoot = Directory(args.first);
  final result = _validateArtifactRoot(artifactRoot);
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(result));
  if (result['is_valid'] != true) {
    exitCode = 1;
  }
}

Map<String, Object?> _validateArtifactRoot(Directory artifactRoot) {
  final errors = <String>[];
  final warnings = <String>[];

  if (!artifactRoot.existsSync()) {
    errors.add('Artifact root does not exist: ${artifactRoot.path}');
    return <String, Object?>{
      'is_valid': false,
      'artifact_root': artifactRoot.path,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final indexJsonFile =
      File('${artifactRoot.path}/simulated_headless_smoke_index.json');
  final indexMarkdownFile =
      File('${artifactRoot.path}/simulated_headless_smoke_index.md');
  if (!indexJsonFile.existsSync()) {
    errors.add('Missing simulated_headless_smoke_index.json');
  }
  if (!indexMarkdownFile.existsSync()) {
    errors.add('Missing simulated_headless_smoke_index.md');
  }
  if (errors.isNotEmpty) {
    return <String, Object?>{
      'is_valid': false,
      'artifact_root': artifactRoot.path,
      'errors': errors,
      'warnings': warnings,
    };
  }

  final indexJson = _readJsonMap(
    indexJsonFile,
    errors,
    label: 'simulated_headless_smoke_index.json',
  );
  final indexMarkdown = indexMarkdownFile.readAsStringSync();

  final discoveredArtifacts =
      _discoverArtifacts(artifactRoot, errors, warnings);
  if (indexJson == null) {
    return <String, Object?>{
      'is_valid': false,
      'artifact_root': artifactRoot.path,
      'errors': errors,
      'warnings': warnings,
    };
  }

  if (indexJson['artifact_kind'] != 'simulated_headless_smoke_index') {
    errors.add(
      'simulated_headless_smoke_index.json artifact_kind must be '
      'simulated_headless_smoke_index',
    );
  }

  final indexEntries = _readList(
    indexJson['entries'],
    'simulated_headless_smoke_index.json.entries',
    errors,
  )
      .map((entry) => _asMap(entry, 'index entry', errors))
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  final discoveredByDir = <String, _DiscoveredArtifact>{
    for (final artifact in discoveredArtifacts) artifact.artifactDir: artifact,
  };
  final indexedDirs = <String>{};
  for (final entry in indexEntries) {
    final artifactDir = entry['artifact_dir']?.toString() ?? '';
    if (artifactDir.isEmpty) {
      errors.add('index entry missing artifact_dir');
      continue;
    }
    indexedDirs.add(artifactDir);
    final discovered = discoveredByDir[artifactDir];
    if (discovered == null) {
      errors.add(
        'index entry references artifact_dir that is not present on disk: '
        '$artifactDir',
      );
      continue;
    }
    _validateIndexEntry(entry, discovered, errors, warnings);
    if (!indexMarkdown.contains('`$artifactDir`')) {
      errors.add(
        'simulated_headless_smoke_index.md is missing artifact dir row for '
        '$artifactDir',
      );
    }
  }

  for (final artifact in discoveredArtifacts) {
    if (!indexedDirs.contains(artifact.artifactDir)) {
      errors.add(
        'simulated_headless_smoke_index.json is missing artifact dir: '
        '${artifact.artifactDir}',
      );
    }
  }

  final expectedOrder =
      discoveredArtifacts.map((artifact) => artifact.artifactDir).toList();
  final actualOrder = indexEntries
      .map((entry) => entry['artifact_dir']?.toString() ?? '')
      .where((artifactDir) => artifactDir.isNotEmpty)
      .toList();
  if (!_listsEqual(expectedOrder, actualOrder)) {
    errors.add(
      'simulated_headless_smoke_index.json entries are not in deterministic '
      'descending order',
    );
  }

  return <String, Object?>{
    'is_valid': errors.isEmpty,
    'artifact_root': artifactRoot.path,
    'errors': errors,
    'warnings': warnings,
    'summary': <String, Object?>{
      'indexed_run_count': indexEntries.length,
      'discovered_run_count': discoveredArtifacts.length,
      'latest_artifact_dir': discoveredArtifacts.isEmpty
          ? null
          : discoveredArtifacts.first.artifactDir,
    },
  };
}

List<_DiscoveredArtifact> _discoverArtifacts(
  Directory artifactRoot,
  List<String> errors,
  List<String> warnings,
) {
  final artifacts = <_DiscoveredArtifact>[];
  final children = artifactRoot.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final child in children) {
    if (child.path.contains('_PENDING')) {
      warnings.add('Ignoring pending artifact directory: ${child.path}');
      continue;
    }
    final manifestFile = File('${child.path}/manifest.json');
    if (!manifestFile.existsSync()) {
      continue;
    }
    final manifest = _readJsonMap(
      manifestFile,
      errors,
      label: '${child.path}/manifest.json',
    );
    if (manifest == null) {
      continue;
    }
    final artifactKind = manifest['artifact_kind']?.toString();
    final isSimulatedSmoke = artifactKind == 'simulated_headless_smoke' ||
        (manifest['simulated'] == true &&
            (manifest['platform']?.toString() ?? '').endsWith('_simulator') &&
            manifest.containsKey('scenario_profile'));
    if (!isSimulatedSmoke) {
      continue;
    }
    artifacts.add(
      _DiscoveredArtifact(
        artifactDir: child.uri.pathSegments.isEmpty
            ? child.path
            : child.uri.pathSegments
                .where((segment) => segment.isNotEmpty)
                .last,
        directory: child,
        manifest: manifest,
      ),
    );
  }

  artifacts.sort((a, b) {
    final timestampCompare = (b.manifest['timestamp']?.toString() ?? '')
        .compareTo(a.manifest['timestamp']?.toString() ?? '');
    if (timestampCompare != 0) {
      return timestampCompare;
    }
    final runIdCompare = (b.manifest['run_id']?.toString() ?? '')
        .compareTo(a.manifest['run_id']?.toString() ?? '');
    if (runIdCompare != 0) {
      return runIdCompare;
    }
    return b.artifactDir.compareTo(a.artifactDir);
  });
  return artifacts;
}

void _validateIndexEntry(
  Map<String, dynamic> entry,
  _DiscoveredArtifact discovered,
  List<String> errors,
  List<String> warnings,
) {
  final manifest = discovered.manifest;
  _expectEqual(
    entry['artifact_dir'],
    discovered.artifactDir,
    'artifact_dir',
    errors,
  );
  _expectEqual(
    entry['artifact_dir_path'],
    discovered.directory.path,
    'artifact_dir_path',
    errors,
  );
  _expectEqual(entry['run_id'], manifest['run_id'], 'run_id', errors);
  _expectEqual(entry['platform'], manifest['platform'], 'platform', errors);
  _expectEqual(
    entry['scenario_profile'],
    manifest['scenario_profile'],
    'scenario_profile',
    errors,
  );
  _expectEqual(entry['timestamp'], manifest['timestamp'], 'timestamp', errors);
  _expectEqual(
    entry['timestamp_utc'],
    manifest['timestamp_utc'],
    'timestamp_utc',
    errors,
  );
  _expectEqual(entry['git_sha'], manifest['git_sha'], 'git_sha', errors);
  _expectEqual(
    entry['success'],
    manifest['smoke_response_success'],
    'success',
    errors,
  );
  _expectEqual(
    entry['failure_summary'],
    manifest['failure_summary'],
    'failure_summary',
    errors,
  );

  final artifactIndexFile =
      File('${discovered.directory.path}/ARTIFACT_INDEX.md');
  if (!artifactIndexFile.existsSync()) {
    errors.add(
      'Missing ARTIFACT_INDEX.md for artifact dir ${discovered.artifactDir}',
    );
  } else {
    final artifactIndex = artifactIndexFile.readAsStringSync();
    if (!artifactIndex.contains('`${manifest['run_id']?.toString() ?? ''}`')) {
      errors.add(
        'ARTIFACT_INDEX.md does not include run id for ${discovered.artifactDir}',
      );
    }
    if (!artifactIndex.contains(
      '`${manifest['scenario_profile']?.toString() ?? ''}`',
    )) {
      errors.add(
        'ARTIFACT_INDEX.md does not include scenario profile for '
        '${discovered.artifactDir}',
      );
    }
  }

  final validationSummaryFile =
      File('${discovered.directory.path}/validation_summary.json');
  if (!validationSummaryFile.existsSync()) {
    errors.add(
      'Missing validation_summary.json for artifact dir ${discovered.artifactDir}',
    );
  } else {
    final validationSummary = _readJsonMap(
      validationSummaryFile,
      errors,
      label: '${discovered.directory.path}/validation_summary.json',
    );
    if (validationSummary != null) {
      if (validationSummary['is_valid'] != true) {
        errors.add(
          'validation_summary.json is not valid for ${discovered.artifactDir}',
        );
      }
      final summary =
          _asMap(validationSummary['summary'], 'validation summary', errors);
      if (summary != null) {
        _expectEqual(
          summary['run_id'],
          manifest['run_id'],
          'validation_summary.summary.run_id',
          errors,
        );
        _expectEqual(
          summary['scenario_profile'],
          manifest['scenario_profile'],
          'validation_summary.summary.scenario_profile',
          errors,
        );
      }
    }
  }

  final zipPath = entry['zip_path']?.toString();
  if (zipPath != null && zipPath.isNotEmpty) {
    final zipFile = File(zipPath);
    if (!zipFile.existsSync()) {
      errors.add(
          'zip_path does not exist for ${discovered.artifactDir}: $zipPath');
    }
  } else {
    warnings.add('zip_path missing for ${discovered.artifactDir}');
  }
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

List<dynamic> _readList(
  Object? value,
  String label,
  List<String> errors,
) {
  if (value is List) {
    return value;
  }
  errors.add('$label must be a JSON list');
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

void _expectEqual(
  Object? actual,
  Object? expected,
  String field,
  List<String> errors,
) {
  if (actual != expected) {
    errors.add(
        'Index field mismatch for $field: expected $expected, got $actual');
  }
}

bool _listsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class _DiscoveredArtifact {
  const _DiscoveredArtifact({
    required this.artifactDir,
    required this.directory,
    required this.manifest,
  });

  final String artifactDir;
  final Directory directory;
  final Map<String, dynamic> manifest;
}
