import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Directory _runtimeLibDirectory() {
  final candidates = <String>[
    'lib',
    'runtime/avrai_runtime_os/lib',
  ];
  for (final candidate in candidates) {
    final directory = Directory(candidate);
    if (directory.existsSync()) {
      return directory;
    }
  }
  throw FileSystemException(
    'Cannot locate runtime lib directory.',
    candidates.join(', '),
  );
}

String _relativeRuntimePath(File file, Directory root) {
  final normalizedRoot = root.path.replaceAll('\\', '/');
  final normalizedFile = file.path.replaceAll('\\', '/');
  if (normalizedFile.startsWith('$normalizedRoot/')) {
    return normalizedFile.substring(normalizedRoot.length + 1);
  }
  return normalizedFile;
}

void main() {
  group('Language runtime usage guardrails', () {
    test('product surfaces do not call LanguageRuntimeService.chat directly',
        () {
      final root = _runtimeLibDirectory();
      const allowlist = <String>{
        'services/admin/reality_model_checkin_service.dart',
      };
      final offenders = <String>[];

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final relativePath = _relativeRuntimePath(entity, root);
        if (relativePath.startsWith('services/ai_infrastructure/')) {
          continue;
        }
        if (relativePath.startsWith('services/bert_squad/')) {
          continue;
        }
        if (relativePath == 'services/language/language_runtime_service.dart') {
          continue;
        }
        if (allowlist.contains(relativePath)) {
          continue;
        }

        final source = entity.readAsStringSync();
        if (RegExp(r'(?:_?languageRuntimeService)\.chat\(').hasMatch(source)) {
          offenders.add(relativePath);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Only backend-only allowlisted files may call '
            'LanguageRuntimeService.chat directly. Offenders: '
            '${offenders.join(', ')}',
      );
    });
  });
}
