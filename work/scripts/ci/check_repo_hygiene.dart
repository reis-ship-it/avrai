import 'dart:convert';
import 'dart:io';

const _maxTrackedFileBytes = 25 * 1024 * 1024;
const _largeArtifactBaselinePath =
    'work/scripts/ci/baselines/repo_hygiene_large_artifacts_baseline.json';

/// Paths that are still grandfathered in the repository today.
///
/// This allowlist only applies to the full-repo CI scan. It does not apply to
/// staged changes in pre-commit mode, where new or modified large artifacts are
/// blocked by default.
const _grandfatheredLargeArtifactJsonKey = 'grandfatheredTrackedLargeArtifacts';

/// Explicit, narrow exceptions for staged large-artifact commits.
///
/// Keep this empty unless there is a deliberate policy exception.
const _stagedLargeArtifactAllowlist = <String>{};

/// Known manifest-first artifact lanes. These should store provenance and small
/// summaries in git, while the heavy payload lives outside normal source
/// control.
const _manifestFirstArtifactPrefixes = <String>[
  'work/docs/plans/beta_launch/',
  'data/training/',
  'runtime/avrai_runtime_os/data/training/',
];

const _forbiddenDirectorySegments = <String>{
  '.dart_tool',
  '.git',
  '.gradle',
  'Pods',
  'build',
  'logs',
  'target',
  'temp',
  'tmp',
  'tmp_ios_build',
};

const _forbiddenFileNames = <String>{'.DS_Store'};

/// Fails local hooks and CI if obviously-generated / non-source artifacts are
/// tracked by git, or if large generated artifacts are introduced as normal git
/// files.
///
/// Usage:
/// - `dart run work/scripts/ci/check_repo_hygiene.dart`
/// - `dart run work/scripts/ci/check_repo_hygiene.dart --staged-only`
/// - `dart run work/scripts/ci/check_repo_hygiene.dart --diff-base origin/develop`
/// - `dart run work/scripts/ci/check_repo_hygiene.dart --update-large-artifact-baseline`
Future<void> main(List<String> args) async {
  final stagedOnly = args.contains('--staged-only');
  final updateBaseline =
      args.contains('--update-large-artifact-baseline') ||
      args.contains('--update-baseline');
  final diffBase = _extractOptionValue(args, '--diff-base');

  if (_countSelectedModes(
        stagedOnly: stagedOnly,
        updateBaseline: updateBaseline,
        diffBase: diffBase,
      ) >
      1) {
    stderr.writeln(
      'ERROR: `--staged-only`, `--diff-base`, and `--update-large-artifact-baseline` are mutually exclusive.',
    );
    exitCode = 2;
    return;
  }

  final candidatePaths = stagedOnly
      ? await _loadStagedPaths()
      : diffBase != null
      ? await _loadPathsDiffingFromRef(diffBase)
      : await _loadTrackedPaths();
  final forbiddenDirectoryOffenders = <String>[];
  final largeTrackedFiles = <_LargeTrackedFile>[];

  for (final path in candidatePaths) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    if (_isUnderForbiddenDirectory(path)) {
      forbiddenDirectoryOffenders.add(path);
      continue;
    }

    final sizeBytes = file.lengthSync();
    if (sizeBytes >= _maxTrackedFileBytes) {
      largeTrackedFiles.add(
        _LargeTrackedFile(path: path, sizeBytes: sizeBytes),
      );
    }
  }

  if (updateBaseline) {
    await _writeLargeArtifactBaseline(largeTrackedFiles);
    return;
  }

  if (forbiddenDirectoryOffenders.isNotEmpty) {
    stderr.writeln(
      'ERROR: Repo hygiene violation: generated artifacts are tracked.',
    );
    stderr.writeln(
      'Found ${forbiddenDirectoryOffenders.length} tracked file(s) under forbidden directories:',
    );
    for (final offender in forbiddenDirectoryOffenders..sort()) {
      stderr.writeln('- $offender');
    }
    stderr.writeln('');
    stderr.writeln(
      'Fix: remove these from git and ensure .gitignore covers them.',
    );
    exitCode = 1;
    return;
  }

  final baseline = await _loadLargeArtifactBaseline();
  final oversizedOffenders = (stagedOnly || diffBase != null)
      ? largeTrackedFiles
            .where(
              (entry) => !_stagedLargeArtifactAllowlist.contains(entry.path),
            )
            .toList()
      : largeTrackedFiles
            .where((entry) => !baseline.contains(entry.path))
            .toList();

  if (oversizedOffenders.isNotEmpty) {
    final modeLabel = stagedOnly
        ? 'staged large tracked files'
        : diffBase != null
        ? 'large tracked files changed since `$diffBase`'
        : 'tracked large files';
    stderr.writeln(
      'ERROR: Repo hygiene violation: $modeLabel exceed the ${_formatBytes(_maxTrackedFileBytes)} policy threshold.',
    );
    stderr.writeln('');
    for (final offender in oversizedOffenders..sort()) {
      final advisory = _isManifestFirstArtifactLane(offender.path)
          ? ' [manifest-first artifact lane]'
          : '';
      stderr.writeln(
        '- ${offender.path} (${_formatBytes(offender.sizeBytes)})$advisory',
      );
    }
    stderr.writeln('');
    stderr.writeln(
      'Policy: large generated artifacts do not belong in normal git history.',
    );
    stderr.writeln(
      'Use a manifest + summary + digest in git, and store the heavy payload in artifact storage or an explicitly governed exception lane.',
    );
    if (!stagedOnly) {
      stderr.writeln(
        'If an oversized tracked file is already part of repository history, it must be listed in $_largeArtifactBaselinePath until it is migrated out of normal git.',
      );
    }
    exitCode = 1;
    return;
  }

  if (!stagedOnly && diffBase == null) {
    final staleBaselineEntries = baseline.difference(
      largeTrackedFiles.map((entry) => entry.path).toSet(),
    );
    if (staleBaselineEntries.isNotEmpty) {
      stdout.writeln(
        'WARN: ${staleBaselineEntries.length} stale repo-hygiene baseline entr${staleBaselineEntries.length == 1 ? 'y' : 'ies'} can be removed from $_largeArtifactBaselinePath.',
      );
    }
  }

  stdout.writeln(
    stagedOnly
        ? 'OK: No staged repo hygiene violations found.'
        : diffBase != null
        ? 'OK: No repo hygiene violations found in changes since `$diffBase`.'
        : 'OK: No repo hygiene violations found.',
  );
}

Future<Set<String>> _loadTrackedPaths() async {
  final result = await Process.run('git', const [
    'ls-files',
    '-z',
  ], runInShell: true);
  return _parseGitPathResult(
    result: result,
    commandDescription: '`git ls-files`',
  );
}

Future<Set<String>> _loadStagedPaths() async {
  final result = await Process.run('git', const [
    'diff',
    '--cached',
    '--name-only',
    '--diff-filter=ACMRTUXB',
    '-z',
  ], runInShell: true);
  return _parseGitPathResult(
    result: result,
    commandDescription: '`git diff --cached --name-only`',
  );
}

Future<Set<String>> _loadPathsDiffingFromRef(String baseRef) async {
  final result = await Process.run('git', [
    'diff',
    '--name-only',
    '--diff-filter=ACMRTUXB',
    '-z',
    '$baseRef...HEAD',
  ], runInShell: true);
  return _parseGitPathResult(
    result: result,
    commandDescription: '`git diff --name-only $baseRef...HEAD`',
  );
}

Set<String> _parseGitPathResult({
  required ProcessResult result,
  required String commandDescription,
}) {
  if (result.exitCode != 0) {
    stderr.writeln('ERROR: Failed to run $commandDescription.');
    stderr.writeln(result.stderr);
    exit(2);
  }

  final stdoutValue = result.stdout;
  if (stdoutValue is! String) {
    stderr.writeln(
      'ERROR: Unexpected stdout type while running $commandDescription.',
    );
    exit(2);
  }

  return stdoutValue
      .split('\u0000')
      .where((path) => path.trim().isNotEmpty)
      .toSet();
}

bool _isUnderForbiddenDirectory(String path) {
  final segments = path
      .replaceAll('\\', '/')
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();

  if (segments.isEmpty) {
    return false;
  }

  if (_forbiddenFileNames.contains(segments.last)) {
    return true;
  }

  for (final segment in segments.take(segments.length - 1)) {
    if (_forbiddenDirectorySegments.contains(segment)) {
      return true;
    }
  }
  return false;
}

bool _isManifestFirstArtifactLane(String path) {
  for (final prefix in _manifestFirstArtifactPrefixes) {
    if (path.startsWith(prefix)) {
      return true;
    }
  }
  return false;
}

String? _extractOptionValue(List<String> args, String optionName) {
  for (var index = 0; index < args.length; index += 1) {
    if (args[index] == optionName) {
      if (index + 1 >= args.length) {
        stderr.writeln('ERROR: $optionName requires a value.');
        exit(2);
      }
      return args[index + 1];
    }
  }
  return null;
}

int _countSelectedModes({
  required bool stagedOnly,
  required bool updateBaseline,
  required String? diffBase,
}) {
  var count = 0;
  if (stagedOnly) {
    count += 1;
  }
  if (updateBaseline) {
    count += 1;
  }
  if (diffBase != null) {
    count += 1;
  }
  return count;
}

Future<Set<String>> _loadLargeArtifactBaseline() async {
  final file = File(_largeArtifactBaselinePath);
  if (!file.existsSync()) {
    return const <String>{};
  }

  final raw = jsonDecode(await file.readAsString());
  if (raw is! Map<String, dynamic>) {
    stderr.writeln(
      'ERROR: Repo hygiene baseline at $_largeArtifactBaselinePath is not a JSON object.',
    );
    exit(2);
  }

  final entries = raw[_grandfatheredLargeArtifactJsonKey];
  if (entries is! List) {
    stderr.writeln(
      'ERROR: Repo hygiene baseline at $_largeArtifactBaselinePath is missing `$_grandfatheredLargeArtifactJsonKey`.',
    );
    exit(2);
  }

  return entries.map((entry) => entry.toString()).toSet();
}

Future<void> _writeLargeArtifactBaseline(
  List<_LargeTrackedFile> largeTrackedFiles,
) async {
  final file = File(_largeArtifactBaselinePath);
  file.parent.createSync(recursive: true);

  final sortedPaths = largeTrackedFiles.map((entry) => entry.path).toList()
    ..sort();
  final payload = <String, dynamic>{
    'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
    'maxTrackedFileBytes': _maxTrackedFileBytes,
    _grandfatheredLargeArtifactJsonKey: sortedPaths,
  };
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(payload)}\n');
  stdout.writeln(
    'OK: Updated $_largeArtifactBaselinePath with ${sortedPaths.length} grandfathered tracked large artifact entr${sortedPaths.length == 1 ? 'y' : 'ies'}.',
  );
}

String _formatBytes(int bytes) {
  const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }
  final rounded = value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded ${units[unitIndex]}';
}

final class _LargeTrackedFile implements Comparable<_LargeTrackedFile> {
  const _LargeTrackedFile({required this.path, required this.sizeBytes});

  final String path;
  final int sizeBytes;

  @override
  int compareTo(_LargeTrackedFile other) => path.compareTo(other.path);
}
