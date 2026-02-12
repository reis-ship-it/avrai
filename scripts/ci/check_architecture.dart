import 'dart:convert';
import 'dart:io';

/// Enforces repository architecture rules (package dependency boundaries).
///
/// Current rule:
/// - Nothing under `packages/` may import or export `package:avrai/...` (the app).
///
/// To support incremental cleanup, this script supports an allowlist "baseline":
/// - Any current violations present in the baseline are tolerated.
/// - Any NEW violations (not in baseline) fail the check (exit code 1).
///
/// Usage:
/// - `dart run scripts/ci/check_architecture.dart`
/// - `dart run scripts/ci/check_architecture.dart --update-baseline`
/// - `dart run scripts/ci/check_architecture.dart --baseline=path/to/file.json`
Future<void> main(List<String> args) async {
  final baselinePath = _argValue(args, '--baseline=') ??
      'scripts/ci/baselines/spots_app_imports_baseline.json';
  final updateBaseline = args.contains('--update-baseline');

  final root = Directory.current.path;
  final packagesDir = Directory('packages');
  if (!packagesDir.existsSync()) {
    stderr.writeln('ERROR: Expected `packages/` directory at repo root.');
    exitCode = 2;
    return;
  }

  final currentViolations = await _findSpotsImports(rootPath: root);

  if (updateBaseline) {
    await _writeBaseline(baselinePath, currentViolations);
    stdout.writeln(
      'Architecture baseline updated: $baselinePath (${currentViolations.length} entries)',
    );
    return;
  }

  final baseline = await _readBaseline(baselinePath);
  final newViolations = currentViolations.difference(baseline);
  final resolvedViolations = baseline.difference(currentViolations);

  if (newViolations.isNotEmpty) {
    stderr.writeln(
      'ERROR: New architecture violations detected (packages importing app `package:avrai/...`).',
    );
    stderr.writeln('Baseline: $baselinePath');
    stderr.writeln('');
    for (final v in newViolations.toList()..sort()) {
      stderr.writeln('- $v');
    }
    stderr.writeln('');
    stderr.writeln(
      'Fix by removing these imports, or (temporary) update the baseline via:\n'
      '  dart run scripts/ci/check_architecture.dart --update-baseline',
    );
    exitCode = 1;
    return;
  }

  if (resolvedViolations.isNotEmpty) {
    stdout.writeln(
      'NOTE: ${resolvedViolations.length} baseline entries no longer exist. You can prune the baseline:',
    );
    for (final v in resolvedViolations.toList()..sort()) {
      stdout.writeln('- $v');
    }
  }

  stdout.writeln('OK: No new package→app import violations.');
}

String? _argValue(List<String> args, String prefix) {
  for (final arg in args) {
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
  }
  return null;
}

Future<Set<String>> _findSpotsImports({required String rootPath}) async {
  final violations = <String>{};
  final importRe = RegExp(
    r'''^\s*(import|export)\s+(['"])(package:avrai/[^'"]+)\2''',
  );

  await for (final entity in Directory('packages')
      .list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final relPath = _toRepoRelativePath(rootPath, entity.path);

    // Only analyze actual source/tests; ignore build outputs inside packages.
    if (relPath.contains('/build/')) {
      continue;
    }

    List<String> lines;
    try {
      lines = await entity.readAsLines();
    } catch (_) {
      // If a file can't be read, fail fast: architecture checks must be deterministic.
      stderr.writeln('ERROR: Failed reading $relPath');
      exitCode = 2;
      return violations;
    }

    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) continue;
      final match = importRe.firstMatch(trimmed);
      if (match == null) continue;
      final uri = match.group(3)!;
      violations.add('$relPath|$uri');
    }
  }

  return violations;
}

String _toRepoRelativePath(String rootPath, String absolutePath) {
  final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
      ? rootPath
      : '$rootPath${Platform.pathSeparator}';
  if (absolutePath.startsWith(normalizedRoot)) {
    return absolutePath.substring(normalizedRoot.length).replaceAll('\\', '/');
  }
  return absolutePath.replaceAll('\\', '/');
}

Future<Set<String>> _readBaseline(String baselinePath) async {
  final f = File(baselinePath);
  if (!f.existsSync()) return <String>{};
  try {
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};
    return decoded.whereType<String>().toSet();
  } catch (e) {
    stderr.writeln('ERROR: Failed reading baseline $baselinePath: $e');
    exitCode = 2;
    return <String>{};
  }
}

Future<void> _writeBaseline(String baselinePath, Set<String> entries) async {
  final f = File(baselinePath);
  f.parent.createSync(recursive: true);
  final sorted = entries.toList()..sort();
  final content = const JsonEncoder.withIndent('  ').convert(sorted);
  await f.writeAsString('$content\n');
}
