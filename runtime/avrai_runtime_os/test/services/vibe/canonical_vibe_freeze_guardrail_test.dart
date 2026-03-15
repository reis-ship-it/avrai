import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readSource(String relativePath) {
  final trimmedRuntimePath = relativePath.startsWith('runtime/avrai_runtime_os/')
      ? relativePath.substring('runtime/avrai_runtime_os/'.length)
      : null;
  final candidates = <String>[
    relativePath,
    if (trimmedRuntimePath != null) trimmedRuntimePath,
    'runtime/avrai_runtime_os/$relativePath',
  ];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  throw FileSystemException(
    'Cannot open source file. Tried ${candidates.join(', ')}',
    relativePath,
  );
}

Iterable<File> _dartFilesIn(String relativeDirectory) sync* {
  final candidates = <String>[
    relativeDirectory,
    'runtime/avrai_runtime_os/$relativeDirectory',
  ];
  for (final candidate in candidates) {
    final directory = Directory(candidate);
    if (directory.existsSync()) {
      yield* directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));
      return;
    }
  }
  throw FileSystemException(
    'Cannot open directory. Tried ${candidates.join(', ')}',
    relativeDirectory,
  );
}

String _normalized(File file) => file.path.replaceAll('\\', '/');

Iterable<String> _kernelContextBundleSnippets(String source) sync* {
  const marker = 'KernelContextBundle(';
  var searchIndex = 0;
  while (true) {
    final start = source.indexOf(marker, searchIndex);
    if (start == -1) {
      return;
    }
    var depth = 0;
    var end = -1;
    for (var i = start; i < source.length; i++) {
      final char = source[i];
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
        if (depth == 0) {
          end = i;
          break;
        }
      }
    }
    if (end == -1) {
      yield source.substring(start);
      return;
    }
    yield source.substring(start, end + 1);
    searchIndex = end + 1;
  }
}

void main() {
  group('Canonical vibe freeze guardrails', () {
    test('production code does not call legacy profile exchange APIs', () {
      const allowedFiles = <String>{
        'runtime/avrai_network/lib/network/ai2ai_protocol.dart',
        'runtime/avrai_runtime_os/lib/services/transport/legacy/legacy_protocol_codec_adapter.dart',
      };
      final offenders = <String>[];

      for (final root in <String>[
        'runtime/avrai_network/lib',
        'runtime/avrai_runtime_os/lib',
        'apps/avrai_app/lib',
        'apps/admin_app/lib',
      ]) {
        final directory = Directory(root);
        if (!directory.existsSync()) {
          continue;
        }
        for (final file
            in directory.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final path = _normalized(file);
          if (allowedFiles.contains(path)) {
            continue;
          }
          final source = file.readAsStringSync();
          if (source.contains('exchangePersonalityProfile(')) {
            offenders.add(path);
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Legacy AI2AI profile exchange must remain decode-only. '
            'Offenders: ${offenders.join(', ')}',
      );
    });

    test('production code does not use reference-only canonical peer exchange',
        () {
      const allowedFiles = <String>{
        'runtime/avrai_network/lib/network/ai2ai_protocol.dart',
        'runtime/avrai_runtime_os/lib/services/transport/legacy/legacy_protocol_codec_adapter.dart',
      };
      final offenders = <String>[];

      for (final root in <String>[
        'runtime/avrai_network/lib',
        'runtime/avrai_runtime_os/lib',
        'apps/avrai_app/lib',
        'apps/admin_app/lib',
      ]) {
        final directory = Directory(root);
        if (!directory.existsSync()) {
          continue;
        }
        for (final file
            in directory.listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) {
            continue;
          }
          final path = _normalized(file);
          if (allowedFiles.contains(path)) {
            continue;
          }
          final source = file.readAsStringSync();
          if (source.contains('exchangeCanonicalVibeReference(')) {
            offenders.add(path);
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Active peer behavior must use canonical peer payload '
            'exchange, not reference-only exchange. Offenders: '
            '${offenders.join(', ')}',
      );
    });

    test('production bootstrap keeps Dart locality fallback test-only', () {
      final appRegistrar = _readSource(
        '../../apps/avrai_app/lib/di/registrars/app_service_registrar.dart',
      );
      final adminRegistrar = _readSource(
        '../../apps/admin_app/lib/di/registrars/app_service_registrar.dart',
      );

      expect(appRegistrar, contains('useDartLocalityFallback = isFlutterTest'));
      expect(
        adminRegistrar,
        contains('useDartLocalityFallback = isFlutterTest'),
      );
      expect(appRegistrar, isNot(contains('enableDartLocalityFallback')));
      expect(adminRegistrar, isNot(contains('enableDartLocalityFallback')));
    });

    test('active KernelContextBundle builders include canonical vibe context',
        () {
      final offenders = <String>[];

      for (final file in _dartFilesIn('lib')) {
        final path = _normalized(file);
        if (path.endsWith('functional_kernel_models.dart')) {
          continue;
        }
        final source = file.readAsStringSync();
        for (final snippet in _kernelContextBundleSnippets(source)) {
          if (!snippet.contains('vibe:') || !snippet.contains('vibeStack:')) {
            offenders.add(path);
            break;
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Every active KernelContextBundle builder must carry canonical '
            'vibe and vibeStack context. Offenders: ${offenders.join(', ')}',
      );
    });

    test('live peer behavior lanes do not depend on remote PersonalityProfile',
        () {
      final offenders = <String>[];
      const livePeerFiles = <String>[
        'runtime/avrai_runtime_os/lib/ai2ai/orchestrator_components.dart',
        'runtime/avrai_runtime_os/lib/ai2ai/connection_orchestrator.dart',
        'runtime/avrai_runtime_os/lib/ai2ai/discovery/discovery_postprocess_lane.dart',
        'runtime/avrai_runtime_os/lib/ai2ai/discovery/node_compatibility_analyzer.dart',
        'runtime/avrai_runtime_os/lib/ai2ai/telemetry/hot_device_processing_lane.dart',
        'runtime/avrai_runtime_os/lib/services/transport/ble/hot_path_orchestration_flow_lane.dart',
        'runtime/avrai_runtime_os/lib/services/transport/ble/connection_worthiness_validation_lane.dart',
      ];

      for (final path in livePeerFiles) {
        final source = _readSource(path);
        if (source.contains('remoteProfile') ||
            source.contains('remotePersonalities') ||
            source.contains('PersonalityProfile remote')) {
          offenders.add(path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Active live peer behavior must use canonical resolved peer '
            'context, not remote PersonalityProfile models. Offenders: '
            '${offenders.join(', ')}',
      );
    });
  });
}
