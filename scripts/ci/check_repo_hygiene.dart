import 'dart:io';

/// Fails CI if obviously-generated / non-source artifacts are tracked by git.
///
/// This is intentionally strict on *tracked* files only (uses `git ls-files`),
/// so it doesn't care about your local untracked build outputs.
///
/// Usage:
/// - `dart run scripts/ci/check_repo_hygiene.dart`
Future<void> main(List<String> args) async {
  final result = await Process.run(
    'git',
    const ['ls-files', '-z'],
    runInShell: true,
  );

  if (result.exitCode != 0) {
    stderr.writeln('ERROR: Failed to run `git ls-files`.');
    stderr.writeln(result.stderr);
    exitCode = 2;
    return;
  }

  final stdoutBytes = result.stdout;
  if (stdoutBytes is! String) {
    stderr.writeln('ERROR: Unexpected `git ls-files` stdout type.');
    exitCode = 2;
    return;
  }

  final tracked = stdoutBytes
      .split('\u0000')
      .where((p) => p.trim().isNotEmpty)
      .toList();

  // Keep this list small and unambiguous: folders that should never be tracked.
  const forbiddenPrefixes = <String>[
    'build/',
    'Pods/',
    'ios/Pods/',
    'android/.gradle/',
    'android/app/build/',
    'android/build/',
    'tmp/',
    'temp/',
    'logs/',
  ];

  final offenders = <String>[];
  for (final path in tracked) {
    for (final prefix in forbiddenPrefixes) {
      if (path.startsWith(prefix)) {
        offenders.add(path);
        break;
      }
    }
  }

  if (offenders.isNotEmpty) {
    stderr.writeln('ERROR: Repo hygiene violation: generated artifacts are tracked.');
    stderr.writeln('Found ${offenders.length} tracked file(s) under forbidden directories:');
    for (final p in offenders..sort()) {
      stderr.writeln('- $p');
    }
    stderr.writeln('');
    stderr.writeln('Fix: remove these from git (and ensure .gitignore covers them).');
    exitCode = 1;
    return;
  }

  stdout.writeln('OK: No tracked generated artifacts found.');
}
