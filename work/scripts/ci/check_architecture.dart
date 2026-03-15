import 'dart:io';

/// Enforces the AVRAI 3-Prong Isolation Strategy boundaries.
///
/// Rules:
/// 1. `apps/` CAN ONLY depend on `runtime/` and `shared/`. MUST NOT depend on `engine/`.
/// 2. `runtime/` CAN ONLY depend on `engine/` and `shared/`. MUST NOT depend on `apps/`.
/// 3. `engine/` CAN ONLY depend on `shared/`. MUST NOT depend on `apps/` or `runtime/`.
/// 4. `shared/` MUST NOT depend on `apps/`, `runtime/`, or `engine/`.
/// 5. `engine/` and `shared/` MUST NOT depend on the `flutter` SDK.
Future<void> main() async {
  bool hasViolations = false;
  final rootDir = Directory.current;
  const flutterSdkEngineAllowlist = <String>{
    // BHAM beta transitional exception: avrai_knot remains the native math /
    // FRB-backed knot substrate until post-beta package reclassification.
    'avrai_knot',
  };

  // Map of directory prefix to allowed dependency prefixes
  final rules = {
    'apps/': ['runtime/', 'shared/'],
    'runtime/': ['engine/', 'shared/'],
    'engine/': ['shared/'],
    'shared/': <String>[],
  };

  // Discover all packages
  final packageDirs = <String, String>{}; // package name -> relative path
  await for (final entity
      in rootDir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('pubspec.yaml')) {
      final relPath = entity.parent.path
          .replaceFirst(rootDir.path + Platform.pathSeparator, '');
      if (relPath.contains('ios/.symlinks') || relPath.contains('.dart_tool')) {
        continue;
      }

      final content = await entity.readAsString();
      final nameMatch = RegExp(r'^name:\s*([a-zA-Z0-9_]+)', multiLine: true)
          .firstMatch(content);
      if (nameMatch != null) {
        packageDirs[nameMatch.group(1)!] = '$relPath/';
      }
    }
  }

  for (final entry in packageDirs.entries) {
    final pkgName = entry.key;
    final pkgPath = entry.value;

    String currentLayer = '';
    for (final layer in rules.keys) {
      if (pkgPath.startsWith(layer)) {
        currentLayer = layer;
        break;
      }
    }

    if (currentLayer.isEmpty) continue; // Not in a tracked layer

    final allowedLayers = rules[currentLayer]!;
    final disallowedLayers = rules.keys
        .where((l) => l != currentLayer && !allowedLayers.contains(l))
        .toList();

    // Check pubspec for flutter dependency if in engine/ or shared/
    final pubspecFile = File('${pkgPath}pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      if ((currentLayer == 'engine/' || currentLayer == 'shared/')) {
        if (content.contains('sdk: flutter') || content.contains('flutter:')) {
          final flutterAllowed = currentLayer == 'engine/' &&
              flutterSdkEngineAllowlist.contains(pkgName);
          if (!flutterAllowed) {
            stderr.writeln(
                'ERROR: $pkgName ($pkgPath) is in $currentLayer but depends on the Flutter SDK.');
            hasViolations = true;
          }
        }
      }

      // Check pubspec dependencies against disallowed layers
      for (final targetPkg in packageDirs.entries) {
        if (targetPkg.key == pkgName) continue;
        final targetLayer = '${targetPkg.value.split('/').first}/';

        if (disallowedLayers.contains(targetLayer)) {
          final depRegex = RegExp('^\\s+${targetPkg.key}:', multiLine: true);
          if (depRegex.hasMatch(content)) {
            stderr.writeln(
                'ERROR: $pkgName ($pkgPath) depends on ${targetPkg.key} (${targetPkg.value}) violating layer rules ($currentLayer cannot depend on $targetLayer).');
            hasViolations = true;
          }
        }
      }
    }

    // Check Dart file imports
    final libDir = Directory('${pkgPath}lib');
    if (libDir.existsSync()) {
      await for (final entity in libDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final lines = await entity.readAsLines();
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i].trim();
            if (line.startsWith('import ') || line.startsWith('export ')) {
              if ((currentLayer == 'engine/' || currentLayer == 'shared/')) {
                if (line.contains("'package:flutter/") ||
                    line.contains('"package:flutter/')) {
                  stderr.writeln(
                      'ERROR: ${entity.path}:${i + 1} imports Flutter SDK in $currentLayer layer.');
                  hasViolations = true;
                }
              }

              for (final targetPkg in packageDirs.entries) {
                if (targetPkg.key == pkgName) continue;
                final targetLayer = '${targetPkg.value.split('/').first}/';

                if (disallowedLayers.contains(targetLayer)) {
                  if (line.contains("'package:${targetPkg.key}/") ||
                      line.contains('"package:${targetPkg.key}/')) {
                    stderr.writeln(
                        'ERROR: ${entity.path}:${i + 1} imports package:${targetPkg.key} violating layer rules ($currentLayer cannot depend on $targetLayer).');
                    hasViolations = true;
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  if (hasViolations) {
    stderr.writeln('\nFAILED: 3-Prong Architecture violations found.');
    exit(1);
  } else {
    stdout.writeln('OK: Architecture boundaries are clean.');
  }
}
